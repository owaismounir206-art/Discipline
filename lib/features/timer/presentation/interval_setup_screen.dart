// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/data/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/motion.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../domain/interval.dart';

/// Scelta del timer: Tabata, EMOM, AMRAP o libero, più le routine guidate.
class IntervalSetupScreen extends ConsumerStatefulWidget {
  const IntervalSetupScreen({super.key});

  @override
  ConsumerState<IntervalSetupScreen> createState() =>
      _IntervalSetupScreenState();
}

class _IntervalSetupScreenState extends ConsumerState<IntervalSetupScreen> {
  var _config = const IntervalConfig.of(IntervalKind.tabata);

  void _start(IntervalConfig config) =>
      context.push(Routes.timerRun(config.toQuery()));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = totalSeconds(buildSteps(_config)) - prepareSeconds;
    final duration = DisciplineMotion.of(context, DisciplineMotion.medium);
    final today = ref.read(clockProvider)();
    final seed = today.year * 400 + today.month * 32 + today.day;

    final steppers = switch (_config.kind) {
      IntervalKind.tabata => [
        Text(
          '20 secondi al massimo, 10 di recupero, per 8 giri: 4 minuti '
          'intensi. Scegli un esercizio e dai tutto.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
      IntervalKind.emom => [
        Text(
          'All\'inizio di ogni minuto fai le ripetizioni scelte; il tempo '
          'che avanza è recupero.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        ValueStepper(
          label: 'Minuti',
          value: _config.minutes,
          min: 1,
          max: 60,
          onChanged: (v) =>
              setState(() => _config = _config.copyWith(minutes: v)),
        ),
      ],
      IntervalKind.amrap => [
        Text(
          'Più giri possibili del tuo circuito nel tempo scelto. Annota i giri '
          'e prova a batterti la prossima volta.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        ValueStepper(
          label: 'Minuti',
          value: _config.minutes,
          min: 1,
          max: 60,
          onChanged: (v) =>
              setState(() => _config = _config.copyWith(minutes: v)),
        ),
      ],
      _ => [
        ValueStepper(
          label: 'Lavoro',
          value: _config.work,
          min: 5,
          max: 300,
          step: 5,
          suffix: 's',
          onChanged: (v) => setState(() => _config = _config.copyWith(work: v)),
        ),
        ValueStepper(
          label: 'Recupero',
          value: _config.rest,
          min: 0,
          max: 300,
          step: 5,
          suffix: 's',
          onChanged: (v) => setState(() => _config = _config.copyWith(rest: v)),
        ),
        ValueStepper(
          label: 'Giri',
          value: _config.rounds,
          min: 1,
          max: 50,
          onChanged: (v) =>
              setState(() => _config = _config.copyWith(rounds: v)),
        ),
      ],
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Timer e routine')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            SlidingSegmented<IntervalKind>(
              semanticsLabel: 'Tipo di timer',
              segments: [
                for (final k in [
                  IntervalKind.tabata,
                  IntervalKind.emom,
                  IntervalKind.amrap,
                  IntervalKind.custom,
                ])
                  (value: k, label: k.label),
              ],
              selected: _config.kind,
              onChanged: (k) => setState(() => _config = IntervalConfig.of(k)),
            ),
            const SizedBox(height: 16),
            AnimatedSize(
              duration: duration == Duration.zero
                  ? const Duration(milliseconds: 1)
                  : duration,
              curve: DisciplineMotion.decelerate,
              alignment: Alignment.topCenter,
              child: Column(
                key: ValueKey(_config.kind),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: steppers,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Durata totale',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  clock(total),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Avvia'),
              onPressed: () => _start(_config),
            ),
            const SectionTitle('Routine guidate'),
            for (final (kind, icon, text) in [
              (
                IntervalKind.warmUp,
                Icons.wb_sunny_outlined,
                '7 movimenti da 40" per scaldare spalle, anche e polsi',
              ),
              (
                IntervalKind.coolDown,
                Icons.self_improvement,
                '6 allungamenti da 45" per finire con calma',
              ),
              (
                IntervalKind.quick,
                Icons.bolt,
                '10 esercizi, 40" + 20": cambia ogni giorno',
              ),
            ]) ...[
              _RoutineCard(
                kind: kind,
                icon: icon,
                text: text,
                minutes:
                    ((totalSeconds(
                                  buildSteps(
                                    IntervalConfig.of(kind, seed: seed),
                                  ),
                                ) -
                                prepareSeconds) /
                            60)
                        .round(),
                onTap: () => _start(IntervalConfig.of(kind, seed: seed)),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.kind,
    required this.icon,
    required this.text,
    required this.minutes,
    required this.onTap,
  });

  final IntervalKind kind;
  final IconData icon;
  final String text;
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PressScale(
      child: DisciplineCard(
        radius: 24,
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        child: Row(
          spacing: 14,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: scheme.onSecondaryContainer),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${kind.label} · $minutes min',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    text,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.play_circle_outline, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}
