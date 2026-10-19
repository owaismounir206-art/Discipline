// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' hide Focus;

import '../../../core/router/routes.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../exercises/domain/exercise.dart';
import '../../exercises/presentation/exercise_figure.dart';
import '../../profile/data/profile_repository.dart';
import '../../timer/domain/interval.dart';
import '../data/today_plan.dart';
import '../domain/focus_workout.dart';

/// Icona di ogni zona.
IconData focusIcon(Focus f) => switch (f) {
  Focus.chest => Icons.shield_outlined,
  Focus.back => Icons.accessibility_new,
  Focus.shoulders => Icons.accessibility,
  Focus.biceps => Icons.fitness_center,
  Focus.triceps => Icons.sports_martial_arts,
  Focus.forearms => Icons.front_hand_outlined,
  Focus.core => Icons.center_focus_strong_outlined,
  Focus.obliques => Icons.rotate_right,
  Focus.legs => Icons.directions_walk,
  Focus.glutes => Icons.airline_seat_recline_normal,
  Focus.calves => Icons.directions_run,
  Focus.cardio => Icons.favorite_outline,
  Focus.mobility => Icons.self_improvement,
  Focus.skills => Icons.sports_gymnastics,
};

/// Un circuito per una zona.
typedef FocusCircuit = ({Focus focus, List<Exercise> exercises});

/// Gli allenamenti specifici di oggi: tre zone che completano la scheda.
final todayFocusProvider = Provider<List<FocusCircuit>>((ref) {
  final profile = ref.watch(athleteProfileProvider).value;
  final today = ref.watch(todayWorkoutProvider);
  if (profile == null || today == null) return const [];
  final seed = daySeed(ref.watch(todayProvider));
  return [
    for (final f in focusForTemplate(today.plan.template))
      (
        focus: f,
        exercises: pickFocus(
          f,
          maxLevel: maxLevelFor(profile.difficulty),
          place: profile.place,
          seed: seed,
        ),
      ),
  ].where((c) => c.exercises.isNotEmpty).toList();
});

/// Minuti di un circuito: 2 giri da 40" di lavoro e 20" di recupero.
int circuitMinutes(int exercises) {
  const c = IntervalConfig.circuit([], title: '');
  final round = exercises * c.work + (exercises - 1) * c.rest;
  return ((prepareSeconds + c.rounds * round + (c.rounds - 1) * 30) / 60)
      .round();
}

IntervalConfig _config(String title, List<String> ids) =>
    IntervalConfig.circuit(ids, title: title);

/// Avvia il circuito di una zona nel timer.
void startCircuit(BuildContext context, String title, List<Exercise> list) =>
    context.push(
      Routes.timerRun(_config(title, [for (final e in list) e.id]).toQuery()),
    );

/// Card di "Oggi": gli allenamenti specifici da fare dopo la scheda.
class TodayFocusCard extends ConsumerWidget {
  const TodayFocusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circuits = ref.watch(todayFocusProvider);
    if (circuits.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        const SectionTitle('Allenamenti specifici'),
        Text(
          'Dopo l\'allenamento principale, o in un altro momento della '
          'giornata: circuiti da ${circuitMinutes(5)} minuti per una zona.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        for (final c in circuits) FocusTile(circuit: c),
      ],
    );
  }
}

/// Una riga con la zona, gli esercizi e il pulsante per partire.
class FocusTile extends StatelessWidget {
  const FocusTile({super.key, required this.circuit});

  final FocusCircuit circuit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = circuit.focus.label;
    final minutes = circuitMinutes(circuit.exercises.length);
    return PressScale(
      child: DisciplineCard(
        onTap: () => context.push(Routes.focus(circuit.focus.name)),
        semanticsLabel: 'Allenamento specifico: $label',
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          spacing: 14,
          children: [
            IconBadge(icon: focusIcon(circuit.focus)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(label, style: theme.textTheme.titleMedium),
                  Text(
                    '$minutes min · '
                    '${circuit.exercises.map((e) => e.name).join(', ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Inizia $label',
              icon: const Icon(Icons.play_arrow),
              onPressed: () => startCircuit(context, label, circuit.exercises),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card di "Allenati": tutte le zone da scegliere.
class FocusChooserCard extends StatelessWidget {
  const FocusChooserCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DisciplineCard(
      semanticsLabel: 'Allenamenti specifici',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text('Allenamenti specifici', style: theme.textTheme.titleMedium),
          Text(
            'Un circuito di 5 esercizi per una sola zona, al tuo livello.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in focusChoices)
                ActionChip(
                  avatar: Icon(focusIcon(f), size: 18),
                  label: Text(f.label),
                  onPressed: () => context.push(Routes.focus(f.name)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Schermata di una zona: gli esercizi del circuito, da cambiare o avviare.
class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key, required this.focus});

  final Focus focus;

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  int? _seed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final profile = ref.watch(athleteProfileProvider).value;
    final seed = _seed ?? daySeed(ref.watch(todayProvider));
    final exercises = profile == null
        ? const <Exercise>[]
        : pickFocus(
            widget.focus,
            maxLevel: maxLevelFor(profile.difficulty),
            place: profile.place,
            seed: seed,
          );
    final label = widget.focus.label;

    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              exercises.isEmpty
                  ? 'Nessun esercizio adatto a questa zona con il tuo livello '
                        'e il posto dove ti alleni.'
                  : '2 giri: 40 secondi per esercizio e 20 di recupero. '
                        'Fai le ripetizioni bene, senza fretta.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (final e in exercises)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PressScale(
                  child: DisciplineCard(
                    onTap: () => context.push(Routes.exercise(e.id)),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      spacing: 12,
                      children: [
                        ExerciseFigure(
                          motion: motionFor(e),
                          size: const Size(72, 54),
                          animate: false,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.name, style: theme.textTheme.titleSmall),
                              Text(
                                e.targetLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (exercises.isNotEmpty) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: Text('Inizia · ${circuitMinutes(exercises.length)} min'),
                onPressed: () => startCircuit(context, label, exercises),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.shuffle),
                label: const Text('Altri esercizi'),
                onPressed: () => setState(() => _seed = seed + 1),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
