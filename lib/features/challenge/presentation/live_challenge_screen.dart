// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/data/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/ritmo_theme.dart';
import '../../../core/widgets/common.dart';
import '../../account/data/account_providers.dart';
import '../../account/domain/backend.dart';
import '../../workout/data/session_feedback.dart';
import '../data/challenge_repository.dart';
import '../data/live_challenge.dart';
import '../domain/challenge.dart';
import 'live_media.dart';

/// Sfida in diretta (design "SfidaLive"): sempre a tema scuro.
class LiveChallengeScreen extends ConsumerStatefulWidget {
  const LiveChallengeScreen({
    super.key,
    required this.roomId,
    this.solo = false,
  });

  final String roomId;

  /// Allenamento da solo, tutto sul telefono.
  final bool solo;

  @override
  ConsumerState<LiveChallengeScreen> createState() =>
      _LiveChallengeScreenState();
}

class _LiveChallengeScreenState extends ConsumerState<LiveChallengeScreen> {
  late final RitmoBackend _backend;
  late final LiveChallenge _live;
  late final SessionFeedback _feedback;
  late final PresenceReporter _presence;
  ChallengeResult? _result;
  String? _shownCheer;
  var _cameraOn = false;
  var _micOn = false;
  RoomPhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    _backend = widget.solo
        ? ref.read(practiceBackendProvider)
        : ref.read(backendProvider);
    _feedback = ref.read(sessionFeedbackProvider);
    _presence = ref.read(presenceProvider);
    _live = LiveChallenge(
      backend: _backend,
      roomId: widget.roomId,
      me: _backend.currentAccount?.id ?? 'io',
      clock: ref.read(clockProvider),
      onFinished: _finished,
    )..addListener(_changed);
    unawaited(_live.start());
    unawaited(_feedback.keepScreenOn(true));
    _presence.training = true;
  }

  @override
  void dispose() {
    _live
      ..removeListener(_changed)
      ..dispose();
    unawaited(_feedback.keepScreenOn(false));
    _presence.training = false;
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    final phase = _live.phase;
    if (phase != _lastPhase) {
      _lastPhase = phase;
      if (phase == RoomPhase.running) unawaited(_feedback.restFinished());
    }
    final cheer = _live.lastCheer;
    if (cheer != null && cheer != _shownCheer) {
      _shownCheer = cheer;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$cheer ti incita! 💪')));
    }
    setState(() {});
  }

  void _finished(ChallengeResult result) {
    unawaited(_feedback.setDone());
    if (!widget.solo && result.friendId != null) {
      unawaited(
        ref
            .read(challengeRepositoryProvider)
            .save(result, ref.read(clockProvider)()),
      );
    }
    if (mounted) setState(() => _result = result);
  }

  Future<void> _close() async {
    final phase = _live.phase;
    if (phase == RoomPhase.running && !_live.isSolo) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lasciare la sfida?'),
          content: const Text('Il tuo conteggio resta quello di adesso.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Resta'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Esci'),
            ),
          ],
        ),
      );
      if (leave != true) return;
    }
    if (phase == RoomPhase.waiting || phase == RoomPhase.countdown) {
      unawaited(_live.leave().catchError((Object _) {}));
    }
    if (mounted) context.pop();
  }

  Future<void> _rematch() async {
    final room = _live.room;
    if (room == null) return;
    try {
      final id = await _backend.createRoom(
        room.mode,
        friendId: widget.solo ? null : _live.opponentId,
      );
      if (mounted) {
        context.pushReplacement(
          widget.solo ? '${Routes.live(id)}?solo=1' : Routes.live(id),
        );
      }
    } on BackendException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = RitmoTheme.dark;
    return Theme(
      data: dark,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(_close());
          },
          child: Scaffold(
            backgroundColor: dark.colorScheme.surface,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: _result != null
                    ? _ResultView(
                        result: _result!,
                        solo: widget.solo,
                        onRematch: _rematch,
                        onClose: () => context.pop(),
                      )
                    : _buildLive(context, dark.colorScheme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLive(BuildContext context, ColorScheme scheme) {
    final room = _live.room;
    final mode = room?.mode ?? ChallengeMode.headToHead;
    final phase = _live.phase;
    final now = _live.serverNow;
    final solo = widget.solo;
    final mine = _live.myCount;
    final theirs = _live.opponentCount;
    final friend = _live.opponentName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        // Intestazione.
        SizedBox(
          height: 64,
          child: Row(
            spacing: 8,
            children: [
              IconButton(
                tooltip: 'Chiudi la sfida',
                icon: const Icon(Icons.close),
                onPressed: _close,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        mode.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      mode.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _ConnectionChip(connected: _live.connected || widget.solo),
            ],
          ),
        ),
        if (room == null)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (phase == RoomPhase.waiting)
          Expanded(
            child: _WaitingView(
              friend: _live.isHost ? (solo ? null : friend) : null,
              isHost: _live.isHost,
              solo: solo,
              canStart: _live.isHost && (widget.solo || !_live.isSolo),
              onStart: () => _live.begin(),
              room: room,
            ),
          )
        else ...[
          _Timer(room: room, now: now, phase: phase),
          SizedBox(
            height: 250,
            child: Row(
              spacing: 10,
              children: [
                Expanded(
                  child: _PlayerTile(
                    caption: 'La tua fotocamera',
                    name: 'Tu',
                    count: mine,
                    color: scheme.primary,
                    highlighted: solo || mine >= theirs,
                    media: _cameraOn
                        ? LocalCameraView(
                            onRep: () => _live.addRep(manual: false),
                          )
                        : null,
                  ),
                ),
                if (!solo)
                  Expanded(
                    child: _PlayerTile(
                      caption: 'Fotocamera di $friend',
                      name: friend,
                      count: theirs,
                      color: scheme.tertiary,
                      highlighted: theirs > mine,
                      media: RemoteVideoView(participantId: _live.opponentId),
                    ),
                  ),
              ],
            ),
          ),
          if (!solo) _LeadBar(mine: mine, theirs: theirs, friend: friend),
          if (solo && mode.goal != null)
            Text(
              'Obiettivo: ${mode.goal} push-up',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          _RepButton(
            enabled: phase == RoomPhase.running,
            camera: _cameraOn,
            countdown: phase == RoomPhase.countdown
                ? room.countdownLeft(now)
                : null,
            onTap: () {
              unawaited(HapticFeedback.lightImpact());
              _live.addRep();
            },
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
            children: [
              _RoundButton(
                icon: _micOn ? Icons.mic : Icons.mic_off,
                tooltip: _micOn
                    ? 'Spegni il microfono'
                    : 'Accendi il microfono',
                selected: _micOn,
                onPressed: solo ? null : () => setState(() => _micOn = !_micOn),
              ),
              _RoundButton(
                icon: _cameraOn ? Icons.videocam : Icons.videocam_off,
                tooltip: _cameraOn
                    ? 'Spegni la fotocamera'
                    : 'Conta con la fotocamera',
                selected: _cameraOn,
                onPressed: () => setState(() => _cameraOn = !_cameraOn),
              ),
              if (!solo)
                Flexible(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.tertiaryContainer,
                      foregroundColor: scheme.onTertiaryContainer,
                      minimumSize: const Size(0, 56),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      textStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    icon: const Icon(Icons.thumb_up_outlined),
                    label: Text(
                      'Incita $friend',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () =>
                        unawaited(_live.cheer().catchError((Object _) {})),
                  ),
                ),
            ],
          ),
          if (_micOn) LiveAudio(roomId: widget.roomId),
        ],
      ],
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  const _ConnectionChip({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: connected
                    ? const Color(0xFF81C784)
                    : const Color(0xFFFFB74D),
              ),
            ),
            Text(
              connected ? 'Connesso' : 'Riconnessione…',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingView extends StatelessWidget {
  const _WaitingView({
    required this.friend,
    required this.isHost,
    required this.solo,
    required this.canStart,
    required this.onStart,
    required this.room,
  });

  final String? friend;
  final bool isHost;
  final bool solo;
  final bool canStart;
  final VoidCallback onStart;
  final ChallengeRoom room;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final others = room.players.values.skip(1).join(', ');
    final message = !isHost
        ? 'Sei dentro! Aspetta il via di ${room.players[room.hostId]}.'
        : solo
        ? 'Mettiti in posizione: al via hai '
              '${room.mode.timeLimit.inMinutes > 0 ? '${room.mode.timeLimit.inMinutes} minuti' : '${room.mode.timeLimit.inSeconds} secondi'}.'
        : canStart
        ? '$others è pronto. Quando vuoi, dai il via!'
        : 'Invito inviato. Aspettiamo che entri…';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        Icon(
          canStart ? Icons.sports_score : Icons.hourglass_top,
          size: 64,
          color: scheme.primary,
        ),
        Semantics(
          liveRegion: true,
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        if (!canStart && isHost && !solo) const LinearProgressIndicator(),
        if (canStart)
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(72),
              textStyle: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RitmoRadii.cardLarge),
              ),
            ),
            onPressed: onStart,
            child: const Text('Via!'),
          ),
      ],
    );
  }
}

class _Timer extends StatelessWidget {
  const _Timer({required this.room, required this.now, required this.phase});

  final ChallengeRoom room;
  final DateTime now;
  final RoomPhase phase;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final limit = room.mode.timeLimit;
    final remaining = room.remaining(now);
    final progress = 1 - remaining.inMilliseconds / limit.inMilliseconds;
    final text = phase == RoomPhase.countdown
        ? formatDuration(limit.inSeconds)
        : formatDuration((remaining.inMilliseconds / 1000).ceil());
    return Column(
      spacing: 8,
      children: [
        Semantics(
          label: 'Tempo rimasto $text',
          excludeSemantics: true,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 56,
              height: 60 / 56,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 6,
            color: scheme.primary,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.caption,
    required this.name,
    required this.count,
    required this.color,
    required this.highlighted,
    this.media,
  });

  final String caption;
  final String name;
  final int count;
  final Color color;
  final bool highlighted;
  final Widget? media;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$name: $count push-up',
      liveRegion: true,
      excludeSemantics: true,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(RitmoRadii.cardLarge),
          border: Border.all(
            color: highlighted ? color : Colors.transparent,
            width: 3,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ?media,
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (media == null)
                    Center(
                      child: Icon(
                        Icons.person_outline,
                        size: 56,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 54,
                          height: 56 / 54,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadBar extends StatelessWidget {
  const _LeadBar({
    required this.mine,
    required this.theirs,
    required this.friend,
  });

  final int mine;
  final int theirs;
  final String friend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final diff = mine - theirs;
    final text = diff > 0
        ? 'Sei avanti di $diff!'
        : diff < 0
        ? '$friend è avanti di ${-diff}'
        : 'Pareggio!';
    return Column(
      spacing: 8,
      children: [
        SizedBox(
          height: 12,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              Expanded(
                flex: mine + 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              Expanded(
                flex: theirs + 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.tertiary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
        Semantics(
          liveRegion: true,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

class _RepButton extends StatelessWidget {
  const _RepButton({
    required this.enabled,
    required this.camera,
    required this.countdown,
    required this.onTap,
  });

  final bool enabled;
  final bool camera;
  final int? countdown;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = countdown != null
        ? (countdown == 0 ? 'Via!' : '$countdown')
        : '+1 push-up';
    return Semantics(
      liveRegion: countdown != null,
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(88),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(
            alpha: countdown != null ? 1 : 0.4,
          ),
          disabledForegroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RitmoRadii.cardLarge),
          ),
        ),
        onPressed: enabled ? onTap : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            Text(
              countdown != null
                  ? 'Preparati…'
                  : camera
                  ? 'Conteggio automatico con la fotocamera attivo'
                  : 'Tocca a ogni push-up',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.primaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      style: IconButton.styleFrom(
        fixedSize: const Size(56, 56),
        backgroundColor: selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        foregroundColor: selected
            ? scheme.onPrimaryContainer
            : scheme.onSurface,
      ),
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.result,
    required this.solo,
    required this.onRematch,
    required this.onClose,
  });

  final ChallengeResult result;
  final bool solo;
  final VoidCallback onRematch;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final won =
        result.outcome == ChallengeOutcome.win ||
        result.outcome == ChallengeOutcome.teamSuccess;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 16,
      children: [
        Icon(
          won ? Icons.emoji_events : Icons.fitness_center,
          size: 72,
          color: won ? scheme.tertiary : scheme.primary,
        ),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            solo ? 'Fatto!' : result.outcome.label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          solo ? '${result.mine} push-up' : result.summary,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
        Text(
          result.manualNote,
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: onRematch,
          child: Text(solo ? 'Ancora una volta' : 'Rivincita'),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
          ),
          onPressed: onClose,
          child: const Text('Chiudi'),
        ),
      ],
    );
  }
}
