// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/router/routes.dart';
import '../../core/theme/motion.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/tab_scaffold.dart';
import '../exercises/domain/catalog.dart';
import '../exercises/domain/exercise.dart';
import '../exercises/domain/progression.dart';
import '../exercises/presentation/exercise_figure.dart';
import '../food/data/ai_food.dart';
import '../profile/data/profile_repository.dart';
import '../profile/domain/athlete_profile.dart';
import 'data/today_plan.dart';
import 'domain/workout_plan.dart';

/// Scheda "Allenati": la settimana, timer, coach e percorsi.
class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(athleteProfileProvider).value;
    final chains = ref.watch(chainProgressProvider).value ?? const {};
    final positions = ref.watch(positionsProvider);
    final today = ref.watch(todayProvider);

    return TabScaffold(
      header: const ScreenHeader(
        title: 'Allenati',
        subtitle: 'Corpo libero, al tuo livello',
      ),
      children: [
        if (profile != null && positions.isNotEmpty) ...[
          _WeekCard(
            profile: profile,
            positions: positions,
            weekday: today.weekday,
          ),
        ],
        const _TimerCard(),
        const _CoachCard(),
        // Una sola sezione per le varianti: ogni percorso mostra quella
        // attuale (prima c'era anche un elenco che ripeteva le stesse cose).
        const SectionTitle('I tuoi percorsi'),
        _PathGrid(chains: chains),
      ],
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.profile,
    required this.positions,
    required this.weekday,
  });

  final AthleteProfile profile;
  final Map<ChainId, int> positions;
  final int weekday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final schedule = weeklySchedule(profile.trainingDays);

    return DisciplineCard(
      color: scheme.tertiaryContainer,
      semanticsLabel: 'La tua settimana',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          Text(
            'La tua settimana',
            style: theme.textTheme.titleLarge?.copyWith(
              color: scheme.onTertiaryContainer,
            ),
          ),
          Text(
            '${schedule.length} sessioni da ${profile.difficulty.sessionMinutes} '
            'min · ${profile.difficulty.label}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onTertiaryContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          for (final MapEntry(key: day, value: template) in schedule.entries)
            _TemplateRow(
              day: day,
              template: template,
              plan: buildWorkout(
                template: template,
                positions: positions,
                difficulty: profile.difficulty,
                place: profile.place,
              ),
              isToday: day == weekday,
            ),
        ],
      ),
    );
  }
}

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({
    required this.day,
    required this.template,
    required this.plan,
    required this.isToday,
  });

  final int day;
  final WorkoutTemplate template;
  final WorkoutPlan plan;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = scheme.onTertiaryContainer;
    return Material(
      color: isToday
          ? scheme.surface.withValues(alpha: 0.6)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(Routes.session, extra: template),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            spacing: 12,
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  weekdayNames[day - 1].substring(0, 3),
                  style: theme.textTheme.titleMedium?.copyWith(color: fg),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${template.label}${isToday ? ' · oggi' : ''}',
                      style: theme.textTheme.titleMedium?.copyWith(color: fg),
                    ),
                    Text(
                      plan.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: fg.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle_fill_rounded,
                color: scheme.tertiary,
                semanticLabel: 'Inizia ${template.label}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Accesso al timer a intervalli e alle routine guidate.
class _TimerCard extends StatelessWidget {
  const _TimerCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PressScale(
      child: DisciplineCard(
        color: scheme.tertiaryContainer,
        onTap: () => context.push(Routes.timer),
        child: Row(
          spacing: 14,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 36,
              color: scheme.onTertiaryContainer,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tabata, EMOM, AMRAP',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                  Text(
                    'Riscaldamento, defaticamento e allenamento rapido da 10 '
                    'minuti',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onTertiaryContainer),
          ],
        ),
      ),
    );
  }
}

/// Il coach AI; senza chiave porta alle impostazioni che spiegano come averla.
class _CoachCard extends ConsumerWidget {
  const _CoachCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ready = ref.watch(aiSettingsProvider).value?.provider != null;
    return PressScale(
      child: DisciplineCard(
        color: scheme.secondaryContainer,
        onTap: () => context.push(ready ? Routes.coach : Routes.aiSettings),
        child: Row(
          spacing: 14,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 36,
              color: scheme.onSecondaryContainer,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chiedi al coach AI',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    ready
                        ? 'Tecnica, dolori, recupero, cosa mangiare: conosce '
                              'il tuo livello'
                        : 'Serve una chiave gratuita Groq o Google AI Studio',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onSecondaryContainer),
          ],
        ),
      ),
    );
  }
}

/// Griglia dei percorsi: ogni scheda apre la strada a tappe.
class _PathGrid extends StatelessWidget {
  const _PathGrid({required this.chains});

  final Map<ChainId, ChainProgress> chains;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: [
        for (final chain in ChainId.values)
          Builder(
            builder: (context) {
              final list = Catalog.chain(chain);
              final position = chains[chain]?.position;
              final shown = list[(position ?? 0).clamp(0, list.length - 1)];
              // Riga 1: la variante attuale; riga 2: a che punto sei.
              final (current, step) = !chain.isProgression
                  ? ('${list.length} esercizi', 'Per variare')
                  : position == null
                  ? (
                      chain == ChainId.skills
                          ? 'Da Avanzato in su'
                          : 'Da iniziare',
                      '${list.length} tappe',
                    )
                  : (shown.name, 'Tappa ${position + 1} di ${list.length}');
              return PressScale(
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  color: chain.isProgression
                      ? scheme.surfaceContainer
                      : scheme.secondaryContainer,
                  child: InkWell(
                    onTap: () => context.push(Routes.path(chain.name)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Center(
                              child: ExerciseFigure(
                                motion: motionFor(shown),
                                size: const Size(96, 64),
                                animate: false,
                              ),
                            ),
                          ),
                          Text(
                            chain.label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            current,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            step,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          if (chain.isProgression) ...[
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(
                                  begin: 0,
                                  end: position == null
                                      ? 0
                                      : (position + 1) / list.length,
                                ),
                                duration: DisciplineMotion.of(
                                  context,
                                  DisciplineMotion.long,
                                ),
                                curve: DisciplineMotion.decelerate,
                                builder: (context, v, _) =>
                                    LinearProgressIndicator(
                                      value: v,
                                      minHeight: 6,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
