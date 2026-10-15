// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/data/providers.dart';
import '../../../core/theme/discipline_theme.dart';
import '../../../core/theme/motion.dart';
import '../../../core/utils/local_date.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../exercises/presentation/exercise_figure.dart';
import '../../rewards/data/rewards_repository.dart';
import '../../rewards/domain/rewards.dart';
import '../../workout/data/session_feedback.dart';
import '../domain/interval.dart';

/// Il timer in corso: sfondo scuro, anello che si svuota, colori per fase e
/// bip negli ultimi 3 secondi.
class IntervalRunScreen extends ConsumerStatefulWidget {
  const IntervalRunScreen({super.key, required this.config});

  final IntervalConfig config;

  @override
  ConsumerState<IntervalRunScreen> createState() => _IntervalRunScreenState();
}

class _IntervalRunScreenState extends ConsumerState<IntervalRunScreen>
    with SingleTickerProviderStateMixin {
  late final List<IntervalStep> _steps = buildSteps(widget.config);
  late final Ticker _ticker = createTicker(_onTick);
  late final SessionFeedback _feedback = ref.read(sessionFeedbackProvider);

  /// Tempo accumulato prima dell'ultima pausa.
  var _before = Duration.zero;
  var _elapsed = Duration.zero;
  var _paused = false;
  var _lastIndex = 0;
  var _lastBeep = -1;
  bool? _awarded;

  @override
  void initState() {
    super.initState();
    _feedback.keepScreenOn(true);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _feedback.keepScreenOn(false);
    super.dispose();
  }

  TimerPosition get _pos => positionAt(_steps, _elapsed);

  void _onTick(Duration sinceStart) {
    setState(() => _elapsed = _before + sinceStart);
    final pos = _pos;
    if (pos.done) {
      _ticker.stop();
      _feedback.restFinished();
      _finish();
      return;
    }
    if (pos.index != _lastIndex) {
      _lastIndex = pos.index;
      _lastBeep = -1;
      _feedback.restFinished();
    } else if (pos.remaining <= 3 && pos.remaining != _lastBeep) {
      _lastBeep = pos.remaining;
      _feedback.tick();
    }
  }

  Future<void> _finish() async {
    final now = ref.read(clockProvider)();
    final ok = await ref
        .read(rewardsRepositoryProvider)
        .award(
          PointKind.timer,
          pointsTimer,
          at: now,
          ref: 'timer-${LocalDate.fromDateTime(now).key}',
          note: widget.config.kind.label,
        );
    if (mounted) setState(() => _awarded = ok);
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _before = _elapsed;
        _ticker.stop();
      } else {
        _ticker.start();
      }
    });
  }

  /// Salta all'inizio del passo [index].
  void _jump(int index) {
    final target = Duration(
      seconds: startOf(_steps, index.clamp(0, _steps.length)),
    );
    _ticker.stop();
    setState(() {
      _before = target;
      _elapsed = target;
      _lastIndex = index;
      _lastBeep = -1;
    });
    if (!_paused) _ticker.start();
    if (index >= _steps.length) _onTick(Duration.zero);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DisciplineTheme.dark,
      child: Builder(builder: _build),
    );
  }

  Widget _build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pos = _pos;
    final done = pos.done;
    final step = _steps[pos.index];
    final next = pos.index + 1 < _steps.length ? _steps[pos.index + 1] : null;
    final color = switch (step.phase) {
      Phase.prepare => scheme.tertiary,
      Phase.work => scheme.primary,
      Phase.rest => scheme.secondary,
    };
    final (round, rounds) = roundOf(_steps, pos.index);
    final total = totalSeconds(_steps);
    final left = (total - _elapsed.inMilliseconds / 1000).ceil().clamp(
      0,
      total,
    );
    final duration = DisciplineMotion.of(context, DisciplineMotion.medium);
    final exercise = step.exercise;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        leading: IconButton(
          tooltip: 'Chiudi',
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.config.kind.label),
      ),
      body: SafeArea(
        top: false,
        child: done
            ? _Done(awarded: _awarded, kind: widget.config.kind)
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: duration,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            switch (step.phase) {
                              Phase.prepare => 'Pronti',
                              Phase.work => 'Lavoro',
                              Phase.rest => 'Recupero',
                            },
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          step.phase == Phase.prepare
                              ? '$rounds giri'
                              : 'Giro $round di $rounds',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Center(
                        child: LayoutBuilder(
                          builder: (context, box) {
                            final side = math.min(
                              math.min(box.maxWidth, box.maxHeight),
                              320.0,
                            );
                            return TweenAnimationBuilder<Color?>(
                              tween: ColorTween(end: color),
                              duration: duration,
                              builder: (context, c, _) => CustomPaint(
                                painter: _RingPainter(
                                  progress: pos.progress,
                                  color: c ?? color,
                                  track: scheme.surfaceContainerHighest,
                                ),
                                child: SizedBox.square(
                                  dimension: side,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (exercise != null)
                                        ExerciseFigure(
                                          key: ValueKey(exercise.id),
                                          motion: motionFor(exercise),
                                          size: Size(side * .34, side * .24),
                                          color: c ?? color,
                                        ),
                                      Semantics(
                                        liveRegion: pos.remaining <= 3,
                                        label:
                                            '${step.label}, mancano '
                                            '${pos.remaining} secondi',
                                        child: ExcludeSemantics(
                                          child: Text(
                                            clock(pos.remaining),
                                            style: theme.textTheme.displayLarge
                                                ?.copyWith(
                                                  fontSize: side * .24,
                                                  fontWeight: FontWeight.w800,
                                                  fontFeatures: const [
                                                    FontFeature.tabularFigures(),
                                                  ],
                                                ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 28,
                                        ),
                                        child: AnimatedSwitcher(
                                          duration: duration,
                                          child: Text(
                                            step.label,
                                            key: ValueKey(pos.index),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            style: theme.textTheme.titleLarge,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: duration,
                      child: Text(
                        next == null
                            ? 'Ultimo sforzo!'
                            : 'Poi: ${next.label} · ${clock(next.seconds)}',
                        key: ValueKey(pos.index),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _elapsed.inMilliseconds / (total * 1000),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mancano ${clock(left)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 20,
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Passo precedente',
                          iconSize: 28,
                          style: IconButton.styleFrom(
                            fixedSize: const Size(60, 60),
                          ),
                          onPressed: pos.index == 0
                              ? null
                              : () => _jump(
                                  pos.progress > 0.15
                                      ? pos.index
                                      : pos.index - 1,
                                ),
                          icon: const Icon(Icons.skip_previous),
                        ),
                        PressScale(
                          child: IconButton.filled(
                            tooltip: _paused ? 'Riprendi' : 'Pausa',
                            iconSize: 40,
                            style: IconButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: scheme.surface,
                              fixedSize: const Size(88, 88),
                            ),
                            onPressed: _togglePause,
                            icon: AnimatedSwitcher(
                              duration: duration,
                              child: Icon(
                                _paused ? Icons.play_arrow : Icons.pause,
                                key: ValueKey(_paused),
                              ),
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Passo successivo',
                          iconSize: 28,
                          style: IconButton.styleFrom(
                            fixedSize: const Size(60, 60),
                          ),
                          onPressed: () => _jump(pos.index + 1),
                          icon: const Icon(Icons.skip_next),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * .05;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    // L'anello si svuota man mano che il tempo passa.
    final sweep = math.pi * 2 * (1 - progress);
    if (sweep > 0.001) {
      canvas.drawArc(rect, -math.pi / 2, sweep, false, paint..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

class _Done extends StatelessWidget {
  const _Done({required this.awarded, required this.kind});

  final bool? awarded;
  final IntervalKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Entrance(
            index: 0,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 64,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Fatto!', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            switch (awarded) {
              true => '${kind.label} completato · +$pointsTimer punti',
              false =>
                '${kind.label} completato. I punti del timer li hai già '
                    'presi oggi.',
              null => '${kind.label} completato',
            },
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Chiudi'),
            ),
          ),
        ],
      ),
    );
  }
}
