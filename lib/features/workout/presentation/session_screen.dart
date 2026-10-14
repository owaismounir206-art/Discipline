// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/common.dart';
import '../../exercises/domain/catalog.dart';
import '../../exercises/domain/exercise.dart';
import '../../exercises/domain/progression.dart';
import '../domain/workout_plan.dart';
import '../data/session_controller.dart';
import 'suggestions_card.dart';

/// Allenamento in corso (design "Allenamento").
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, required this.template});

  final WorkoutTemplate template;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(sessionControllerProvider.notifier).start(widget.template),
    );
  }

  /// Indietro: senza serie fatte esce subito, altrimenti chiede conferma e
  /// chiude la sessione mostrando il riepilogo.
  Future<void> _handleBack() async {
    final s = ref.read(sessionControllerProvider);
    final controller = ref.read(sessionControllerProvider.notifier);
    if (s == null || s.completedSets == 0) {
      await controller.finish();
      if (mounted) context.pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminare l\'allenamento?'),
        content: Text(
          'Hai fatto ${s.completedSets} serie su ${s.plannedSets}. '
          'Le serie fatte restano salvate; per la streak serve almeno '
          'l\'80% della sessione.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continua'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Termina'),
          ),
        ],
      ),
    );
    if (leave ?? false) await controller.finish();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionControllerProvider);
    if (s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (s.finished) return _SummaryView(state: s);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: _RunningView(state: s, onBack: _handleBack),
    );
  }
}

class _RunningView extends ConsumerWidget {
  const _RunningView({required this.state, required this.onBack});

  final SessionState state;
  final Future<void> Function() onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final controller = ref.read(sessionControllerProvider.notifier);
    final current = state.current;
    final exercise = current.exercise;
    final chain = Catalog.chain(exercise.chain);
    final isHold = exercise.measure == Measure.seconds;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Indietro',
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${state.template.label} · ${state.difficulty.label}',
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
            Text(
              'Esercizio ${state.index + 1} di ${state.exercises.length} · '
              '${formatDuration(state.elapsed)} trascorsi',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Altre opzioni',
            onSelected: (v) async {
              switch (v) {
                case 'how':
                  await context.push(Routes.exercise(exercise.id));
                case 'camera':
                  final reps = await context.push<int>(
                    Routes.cameraCounter,
                    extra: exercise.id,
                  );
                  if (reps != null) controller.setValue(reps);
                case 'skip':
                  await controller.skipExercise();
                case 'end':
                  await onBack();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'how', child: Text('Come si esegue')),
              if (exercise.chain == ChainId.push &&
                  exercise.measure == Measure.reps)
                const PopupMenuItem(
                  value: 'camera',
                  child: Text('Conta con la fotocamera'),
                ),
              const PopupMenuItem(
                value: 'skip',
                child: Text('Salta esercizio'),
              ),
              const PopupMenuItem(
                value: 'end',
                child: Text('Termina allenamento'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            SegmentBar(
              value: state.progress,
              color: scheme.primary,
              track: Color.lerp(scheme.primaryContainer, scheme.primary, 0.25)!,
              height: 6,
              semanticsLabel: 'Avanzamento allenamento',
            ),
            const SizedBox(height: 12),
            _TimerCard(state: state),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(
                exercise.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${exercise.targetLabel}${current.planned.isVolume ? ' · volume' : ''}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < current.planned.sets; i++)
                  _SetChip(
                    number: i + 1,
                    done: i < current.setsDone,
                    current: i == current.setsDone,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ValueStepper(
              label: isHold ? 'Secondi' : 'Ripetizioni',
              value: state.value,
              step: isHold ? 5 : 1,
              onChanged: controller.setValue,
            ),
            const SizedBox(height: 12),
            RitmoCard(
              radius: 24,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              semanticsLabel: 'Progressione',
              child: Column(
                spacing: 10,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Progressione',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      ChainDots(
                        length: chain.length,
                        position: exercise.position,
                        track: Color.lerp(
                          scheme.outlineVariant,
                          scheme.primary,
                          0.15,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: exercise.position > 0
                              ? () => controller.changeVariant(-1)
                              : null,
                          child: const Text('Più facile'),
                        ),
                      ),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed:
                              exercise.position <
                                  Catalog.lastPosition(exercise.chain)
                              ? () => controller.changeVariant(1)
                              : null,
                          child: const Text('Più difficile'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: theme.textTheme.titleMedium?.copyWith(fontSize: 17),
              ),
              onPressed: state.mode == TimerMode.hold
                  ? null
                  : controller.completeSet,
              icon: const Icon(Icons.check),
              label: const Text('Serie completata'),
            ),
            if (state.next != null) ...[
              const SizedBox(height: 12),
              RitmoCard(
                color: scheme.surfaceContainerLow,
                radius: 20,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  spacing: 12,
                  children: [
                    IconBadge(
                      icon: Icons.skip_next_rounded,
                      background: scheme.tertiaryContainer,
                      foreground: scheme.onTertiaryContainer,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prossimo',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${state.next!.exercise.name} · '
                            '${state.next!.planned.sets} × '
                            '${state.next!.exercise.range}',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SetChip extends StatelessWidget {
  const _SetChip({
    required this.number,
    required this.done,
    required this.current,
  });

  final int number;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg, border) = done
        ? (scheme.primary, scheme.onPrimary, null)
        : current
        ? (Colors.transparent, scheme.primary, scheme.primary)
        : (scheme.surfaceContainerHigh, scheme.onSurfaceVariant, null);
    return Semantics(
      label:
          'Serie $number: ${done
              ? 'fatta'
              : current
              ? 'in corso'
              : 'da fare'}',
      excludeSemantics: true,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: border == null ? null : Border.all(color: border, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (done) Icon(Icons.check, size: 16, color: fg),
            Text(
              'Serie $number',
              style: TextStyle(
                fontSize: 13,
                fontWeight: done || current ? FontWeight.w700 : FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerCard extends ConsumerWidget {
  const _TimerCard({required this.state});

  final SessionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final controller = ref.read(sessionControllerProvider.notifier);
    final exercise = state.current.exercise;
    final isHold = exercise.measure == Measure.seconds;
    final accent = Color.lerp(scheme.primary, scheme.onPrimaryContainer, 0.4)!;
    final track = Color.lerp(scheme.primaryContainer, scheme.primary, 0.25)!;

    final (
      String top,
      String big,
      String bottom,
      double fraction,
    ) = switch (state.mode) {
      TimerMode.rest => (
        'Recupero',
        formatDuration(state.timerSeconds),
        'di ${formatDuration(state.timerTotal)}',
        state.timerTotal == 0 ? 0 : state.timerSeconds / state.timerTotal,
      ),
      TimerMode.hold => (
        'Tieni la posizione',
        formatDuration(state.timerSeconds),
        'obiettivo ${exercise.range} s',
        (state.timerSeconds / exercise.range.max).clamp(0.0, 1.0),
      ),
      TimerMode.ready => (
        'Serie ${state.current.setsDone + 1}',
        isHold ? '0:00' : 'Vai!',
        exercise.targetLabel,
        1.0,
      ),
    };

    final buttonStyle = TextButton.styleFrom(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.primary,
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 14),
    );

    return Semantics(
      label: 'Timer di recupero',
      liveRegion: state.mode == TimerMode.ready,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          spacing: 8,
          children: [
            SizedBox(
              width: 176,
              height: 176,
              child: CustomPaint(
                painter: _RingPainter(
                  fraction: fraction,
                  color: scheme.primary,
                  track: track,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        top,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                      Text(
                        big,
                        style: TextStyle(
                          fontSize: 46,
                          height: 52 / 46,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: scheme.onPrimaryContainer,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        bottom,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (state.mode == TimerMode.rest) ...[
                  TextButton(
                    style: buttonStyle,
                    onPressed: () => controller.adjustRest(-15),
                    child: const Text('−15 s'),
                  ),
                  TextButton(
                    style: buttonStyle,
                    onPressed: () => controller.adjustRest(15),
                    child: const Text('+15 s'),
                  ),
                  TextButton(
                    style: buttonStyle,
                    onPressed: controller.skipRest,
                    child: const Text('Salta'),
                  ),
                ] else if (isHold)
                  TextButton.icon(
                    style: buttonStyle,
                    onPressed: controller.toggleHold,
                    icon: Icon(
                      state.mode == TimerMode.hold
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      state.mode == TimerMode.hold ? 'Stop' : 'Avvia tenuta',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.color,
    required this.track,
  });

  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14 * 176 / 200;
    final rect = (Offset.zero & size).deflate(stroke / 2 + 1);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = track);
    if (fraction > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * fraction.clamp(0.0, 1.0),
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}

class _SummaryView extends ConsumerWidget {
  const _SummaryView({required this.state});

  final SessionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ratio = state.progress;
    final counts = ratio >= 0.8 - 1e-9;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(state.template.label),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            RitmoCard(
              color: counts ? scheme.primary : scheme.surfaceContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Icon(
                    counts ? Icons.local_fire_department : Icons.timelapse,
                    size: 36,
                    color: counts ? scheme.onPrimary : scheme.primary,
                  ),
                  Text(
                    counts ? 'Allenamento completato!' : 'Allenamento salvato',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: counts ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                  Text(
                    counts
                        ? 'Questo giorno conta per la tua streak.'
                        : 'Hai completato il ${(ratio * 100).round()}%: per la '
                              'streak serve almeno l\'80%.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: counts
                          ? scheme.primaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              spacing: 10,
              children: [
                _Stat(label: 'Serie', value: '${state.completedSets}'),
                _Stat(label: 'Ripetizioni', value: '${state.totalReps}'),
                _Stat(label: 'Tempo', value: formatDuration(state.elapsed)),
              ],
            ),
            if (state.pointsEarned > 0) ...[
              const SizedBox(height: 14),
              RitmoCard(
                color: scheme.tertiaryContainer,
                radius: 20,
                padding: const EdgeInsets.all(16),
                child: Row(
                  spacing: 12,
                  children: [
                    Icon(Icons.stars, color: scheme.onTertiaryContainer),
                    Expanded(
                      child: Text(
                        '+${state.pointsEarned} punti',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: scheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            for (final s in state.suggestions) ...[
              const SizedBox(height: 14),
              _SummarySuggestion(suggestion: s),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go(Routes.today),
              child: const Text('Fine'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: RitmoCard(
        radius: 20,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(value, style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _SummarySuggestion extends ConsumerStatefulWidget {
  const _SummarySuggestion({required this.suggestion});

  final ProgressionSuggestion suggestion;

  @override
  ConsumerState<_SummarySuggestion> createState() => _SummarySuggestionState();
}

class _SummarySuggestionState extends ConsumerState<_SummarySuggestion> {
  bool? _answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = widget.suggestion;
    return RitmoCard(
      color: scheme.secondaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(
            s.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSecondaryContainer,
            ),
          ),
          if (_answer == null)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () async {
                    await answerSuggestion(ref, s, accept: false);
                    setState(() => _answer = false);
                  },
                  child: const Text('Non ora'),
                ),
                FilledButton(
                  onPressed: () async {
                    await answerSuggestion(ref, s, accept: true);
                    setState(() => _answer = true);
                  },
                  child: Text(
                    s.direction == ChangeDirection.harder ? 'Proviamo' : 'Ok',
                  ),
                ),
              ],
            )
          else
            Text(
              _answer!
                  ? 'Fatto: dalla prossima volta «${s.to.name}».'
                  : 'Va bene, restiamo su «${s.from.name}».',
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
        ],
      ),
    );
  }
}
