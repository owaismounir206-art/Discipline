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
import '../../../core/services/share.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/ritmo_theme.dart';
import '../../../core/utils/local_date.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../camera/presentation/rep_camera.dart';
import '../../profile/data/profile_repository.dart';
import '../../rewards/data/rewards_repository.dart';
import '../../rewards/data/rewards_state.dart';
import '../../rewards/domain/rewards.dart';
import '../../workout/data/session_feedback.dart';
import '../domain/friend_code.dart';
import '../domain/timed.dart';

/// Sfida a tempo (design "SfidaLive"), sempre a tema scuro: contro il
/// cronometro, il tuo record o il codice di un amico.
class TimedChallengeScreen extends ConsumerStatefulWidget {
  const TimedChallengeScreen({super.key, required this.mode, this.friendCode});

  final TimedMode mode;
  final String? friendCode;

  @override
  ConsumerState<TimedChallengeScreen> createState() =>
      _TimedChallengeScreenState();
}

class _TimedChallengeScreenState extends ConsumerState<TimedChallengeScreen> {
  late final DateTime Function() _clock;
  late final SessionFeedback _feedback;
  late TimedRun _run;
  FriendChallenge? _friend;
  Timer? _ticker;
  var _cameraOn = false;
  TimedPhase? _lastPhase;
  TimedResult? _result;
  var _points = 0;
  int? _previousBest;

  @override
  void initState() {
    super.initState();
    _clock = ref.read(clockProvider);
    _feedback = ref.read(sessionFeedbackProvider);
    final code = widget.friendCode;
    _friend = code == null ? null : decodeFriendChallenge(code);
    _run = TimedRun(mode: _friend?.mode ?? widget.mode);
    _previousBest = ref.read(bestTimedProvider)[_run.mode];
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_feedback.keepScreenOn(false));
    super.dispose();
  }

  TimedMode get _mode => _run.mode;

  /// Punteggio da battere: quello dell'amico, altrimenti il record.
  int? get _target => _friend?.score ?? _previousBest;

  void _start() {
    unawaited(_feedback.keepScreenOn(true));
    setState(() {
      _run = _run.start(_clock());
      _lastPhase = TimedPhase.countdown;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final phase = _run.phaseAt(_clock());
    if (phase != _lastPhase) {
      _lastPhase = phase;
      if (phase == TimedPhase.running) unawaited(_feedback.restFinished());
      if (phase == TimedPhase.finished) {
        unawaited(_finish());
        return;
      }
    }
    setState(() {});
  }

  void _addRep({required bool manual}) {
    final now = _clock();
    final next = _run.addRep(now, manual: manual);
    if (identical(next, _run)) return;
    if (manual) unawaited(HapticFeedback.lightImpact());
    setState(() => _run = next);
    if (_run.phaseAt(now) == TimedPhase.finished) _tick();
  }

  Future<void> _finish() async {
    _ticker?.cancel();
    final now = _clock();
    final result = _run.resultAt(now);
    unawaited(_feedback.setDone());
    unawaited(_feedback.keepScreenOn(false));
    final score = result.score;
    final target = _target;
    final beat =
        score != null && target != null && isBetterScore(_mode, score, target);
    final repo = ref.read(rewardsRepositoryProvider);
    final id = await repo.saveTimed(
      result,
      at: now,
      friendName: _friend?.name,
      friendScore: _friend?.score,
    );
    final points = timedPoints(
      manual: result.manual,
      verified: result.verified,
      beatTarget: beat,
    );
    final awarded = await repo.award(
      PointKind.timed,
      points,
      at: now,
      ref: 'tempo-$id',
      note: _mode.label,
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _points = awarded ? points : 0;
    });
  }

  Future<void> _close() async {
    final phase = _run.phaseAt(_clock());
    if (phase == TimedPhase.running || phase == TimedPhase.countdown) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Fermare la sfida?'),
          content: const Text('Il risultato non verrà salvato.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continua'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ferma'),
            ),
          ],
        ),
      );
      if (leave != true) return;
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final dark = RitmoTheme.dark;
    final invalidCode = widget.friendCode != null && _friend == null;
    return Theme(
      data: dark,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: PopScope(
          canPop: _result != null || _run.startAt == null,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(_close());
          },
          child: Scaffold(
            backgroundColor: dark.colorScheme.surface,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: invalidCode
                    ? _InvalidCode(onClose: () => context.pop())
                    : _result != null
                    ? _ResultView(
                        result: _result!,
                        friend: _friend,
                        previousBest: _previousBest,
                        points: _points,
                      )
                    : _buildRun(context, dark.colorScheme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRun(BuildContext context, ColorScheme scheme) {
    final now = _clock();
    final phase = _run.phaseAt(now);
    final target = _target;
    final friendName = _friend?.name;
    final vsLabel = _friend != null
        ? (friendName!.isEmpty ? 'Il tuo amico' : friendName)
        : 'Il tuo record';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
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
                        _mode.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      _mode.description,
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
            ],
          ),
        ),
        if (phase == TimedPhase.ready)
          Expanded(
            child: _ReadyView(
              mode: _mode,
              vsLabel: target == null ? null : vsLabel,
              target: target,
              onStart: _start,
            ),
          )
        else ...[
          _TimerView(run: _run, now: now, phase: phase),
          SizedBox(
            height: 250,
            child: Row(
              spacing: 10,
              children: [
                Expanded(
                  child: _CountTile(
                    caption: _cameraOn
                        ? 'La tua fotocamera'
                        : 'Tocca +1 a ogni push-up',
                    name: 'Tu',
                    value: '${_run.reps}',
                    color: scheme.primary,
                    highlighted: true,
                    media: _cameraOn
                        ? RepCameraView(
                            compact: true,
                            onRep: () => _addRep(manual: false),
                          )
                        : null,
                  ),
                ),
                if (target != null)
                  Expanded(
                    child: _CountTile(
                      caption: 'Da battere',
                      name: vsLabel,
                      value: _mode == TimedMode.minute
                          ? '$target'
                          : formatTenths(target),
                      color: scheme.tertiary,
                      highlighted: false,
                    ),
                  ),
              ],
            ),
          ),
          if (_mode.goal != null) _GoalBar(reps: _run.reps, goal: _mode.goal!),
          _RepButton(
            enabled: phase == TimedPhase.running,
            camera: _cameraOn,
            countdown: phase == TimedPhase.countdown
                ? _run.countdownLeft(now)
                : null,
            onTap: () => _addRep(manual: true),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
            children: [
              IconButton(
                tooltip: _cameraOn
                    ? 'Spegni la fotocamera'
                    : 'Conta con la fotocamera',
                isSelected: _cameraOn,
                style: IconButton.styleFrom(
                  fixedSize: const Size(56, 56),
                  backgroundColor: _cameraOn
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  foregroundColor: _cameraOn
                      ? scheme.onPrimaryContainer
                      : scheme.onSurface,
                ),
                icon: Icon(_cameraOn ? Icons.videocam : Icons.videocam_off),
                onPressed: () => setState(() => _cameraOn = !_cameraOn),
              ),
              if (phase == TimedPhase.running)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 56),
                  ),
                  icon: const Icon(Icons.stop),
                  label: const Text('Ho finito'),
                  onPressed: () {
                    setState(() => _run = _run.stop(_clock()));
                    _tick();
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InvalidCode extends StatelessWidget {
  const _InvalidCode({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      const Icon(Icons.error_outline, size: 56),
      const Text(
        'Questo codice non è valido. Controlla di averlo copiato tutto.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      FilledButton(onPressed: onClose, child: const Text('Chiudi')),
    ],
  );
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({
    required this.mode,
    required this.vsLabel,
    required this.target,
    required this.onStart,
  });

  final TimedMode mode;
  final String? vsLabel;
  final int? target;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        Icon(Icons.sports_score, size: 64, color: scheme.primary),
        Text(
          target == null
              ? 'Mettiti in posizione: al via hai '
                    '${mode == TimedMode.minute ? '60 secondi' : '5 minuti'}.'
              : '$vsLabel: ${scoreText(mode, target!)}. Riesci a fare meglio?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        Text(
          'Con la fotocamera ogni push-up vale 1,5 punti invece di 1. '
          'Appoggia il telefono a terra, di lato.',
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
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

class _TimerView extends StatelessWidget {
  const _TimerView({required this.run, required this.now, required this.phase});

  final TimedRun run;
  final DateTime now;
  final TimedPhase phase;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final limit = run.mode.limit;
    final remaining = run.remainingAt(now);
    final progress = 1 - remaining.inMilliseconds / limit.inMilliseconds;
    // Nel minuto si guarda il tempo che resta, nella gara quello passato.
    final shown = run.mode == TimedMode.minute
        ? (phase == TimedPhase.countdown
              ? limit.inSeconds
              : (remaining.inMilliseconds / 1000).ceil())
        : run.elapsedAt(now).inSeconds;
    final text = formatDuration(shown);
    return Column(
      spacing: 8,
      children: [
        Semantics(
          label: run.mode == TimedMode.minute
              ? 'Tempo rimasto $text'
              : 'Tempo $text',
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

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.caption,
    required this.name,
    required this.value,
    required this.color,
    required this.highlighted,
    this.media,
  });

  final String caption;
  final String name;
  final String value;
  final Color color;
  final bool highlighted;
  final Widget? media;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$name: $value',
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
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
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedSwitcher(
                          duration: RitmoMotion.short,
                          switchInCurve: RitmoMotion.decelerate,
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(
                                scale: Tween(
                                  begin: 0.8,
                                  end: 1.0,
                                ).animate(animation),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              ),
                          child: Text(
                            value,
                            key: ValueKey(value),
                            style: const TextStyle(
                              fontSize: 54,
                              height: 56 / 54,
                              fontWeight: FontWeight.w800,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
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

class _GoalBar extends StatelessWidget {
  const _GoalBar({required this.reps, required this.goal});

  final int reps;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      spacing: 6,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: (reps / goal).clamp(0, 1)),
            duration: RitmoMotion.medium,
            curve: RitmoMotion.decelerate,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 12,
              color: scheme.primary,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ),
        Text(
          reps >= goal ? 'Arrivato!' : 'Ne mancano ${goal - reps}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: scheme.onPrimaryContainer,
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
      child: PressScale(
        scale: 0.96,
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
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
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
      ),
    );
  }
}

class _ResultView extends ConsumerWidget {
  const _ResultView({
    required this.result,
    required this.friend,
    required this.previousBest,
    required this.points,
  });

  final TimedResult result;
  final FriendChallenge? friend;
  final int? previousBest;
  final int points;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final score = result.score;
    final mode = result.mode;
    final f = friend;
    final String title;
    final String subtitle;
    var good = false;
    if (f != null) {
      final who = f.name.isEmpty ? 'il tuo amico' : f.name;
      if (score != null && isBetterScore(mode, score, f.score)) {
        title = 'Hai battuto $who!';
        good = true;
      } else if (score == f.score) {
        title = 'Pareggio con $who';
      } else {
        title = 'Ha vinto $who';
      }
      subtitle =
          'Tu ${result.scoreLabel} · ${f.name.isEmpty ? 'amico' : f.name} ${f.scoreLabel}';
    } else if (score != null &&
        (previousBest == null || isBetterScore(mode, score, previousBest!))) {
      title = previousBest == null ? 'Primo record!' : 'Nuovo record!';
      subtitle = result.scoreLabel;
      good = true;
    } else {
      title = 'Fatto!';
      subtitle = previousBest == null
          ? result.scoreLabel
          : '${result.scoreLabel} · record ${scoreText(mode, previousBest!)}';
    }
    final name = ref.read(athleteProfileProvider).value?.name ?? '';
    final share = ref.read(shareTextProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 14,
      children: [
        Icon(
          good ? Icons.emoji_events : Icons.fitness_center,
          size: 72,
          color: good ? scheme.tertiary : scheme.primary,
        ),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
        Text(
          result.manual == 0
              ? 'Tutti contati con la fotocamera'
              : result.manual == result.reps
              ? 'Contati a mano'
              : 'Di cui ${result.manual} contati a mano',
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        if (points > 0)
          Text(
            '+$points punti',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: scheme.tertiary,
            ),
          ),
        const SizedBox(height: 8),
        if (f != null)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.reply),
            label: Text(
              'Rispondi a ${f.name.isEmpty ? 'chi ti ha sfidato' : f.name}',
            ),
            onPressed: () => share(friendReplyMessage(f, result, name)),
          )
        else if (score != null)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.send),
            label: const Text('Sfida un amico a batterti'),
            onPressed: () => share(
              friendChallengeMessage(
                FriendChallenge(
                  mode: mode,
                  score: score,
                  name: name,
                  date: LocalDate.fromDateTime(ref.read(clockProvider)()),
                ),
              ),
            ),
          ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
          ),
          onPressed: () => context.pushReplacement(Routes.timed(mode.name)),
          child: const Text('Ancora una volta'),
        ),
        TextButton(onPressed: () => context.pop(), child: const Text('Chiudi')),
      ],
    );
  }
}
