// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/router/routes.dart';
import '../../core/theme/discipline_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/tab_scaffold.dart';
import '../exercises/domain/catalog.dart';
import '../exercises/domain/exercise.dart';
import '../profile/data/profile_repository.dart';
import '../profile/domain/athlete_profile.dart';
import 'data/today_plan.dart';
import 'domain/workout_plan.dart';

/// Scheda "Allenati": la settimana, le tue varianti e il catalogo.
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
          const SectionTitle('Le tue varianti'),
          for (final chain in ChainId.values)
            if (chains[chain] != null)
              _ChainTile(chain: chain, position: chains[chain]!.position),
          if (chains[ChainId.skills] == null) const _LockedSkills(),
        ],
        const SectionTitle('Catalogo esercizi'),
        for (final chain in ChainId.values)
          _CatalogChain(chain: chain, position: chains[chain]?.position),
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

class _ChainTile extends StatelessWidget {
  const _ChainTile({required this.chain, required this.position});

  final ChainId chain;
  final int position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final exercise = Catalog.at(chain, position);
    return DisciplineCard(
      radius: DisciplineRadii.card,
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      onTap: () => context.push(Routes.exercise(exercise.id)),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  chain.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(exercise.name, style: theme.textTheme.titleMedium),
                Text(
                  exercise.targetLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ChainDots(length: Catalog.chain(chain).length, position: position),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _LockedSkills extends StatelessWidget {
  const _LockedSkills();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DisciplineCard(
      radius: DisciplineRadii.card,
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.all(16),
      child: Row(
        spacing: 12,
        children: [
          IconBadge(
            icon: Icons.lock_outline,
            background: scheme.surfaceContainerHigh,
            foreground: scheme.onSurfaceVariant,
          ),
          Expanded(
            child: Text(
              'Skill (handstand, planche, front lever, muscle-up): si '
              'sbloccano con i push-up diamante e le trazioni, nei livelli '
              'Avanzato ed Élite.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogChain extends StatelessWidget {
  const _CatalogChain({required this.chain, this.position});

  final ChainId chain;
  final int? position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final list = Catalog.chain(chain);
    return Card(
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(),
        title: Text(chain.label, style: theme.textTheme.titleMedium),
        subtitle: Text(
          '${list.length} varianti · ${list.first.muscleGroup.label}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        children: [
          for (final e in list)
            ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: position != null && e.position <= position!
                    ? scheme.primary
                    : scheme.surfaceContainerHigh,
                foregroundColor: position != null && e.position <= position!
                    ? scheme.onPrimary
                    : scheme.onSurfaceVariant,
                child: Text(
                  '${e.position + 1}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(e.name),
              subtitle: Text(e.targetLabel),
              trailing: e.position == position
                  ? Chip(
                      label: const Text('Attuale'),
                      backgroundColor: scheme.primaryContainer,
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    )
                  : null,
              onTap: () => context.push(Routes.exercise(e.id)),
            ),
        ],
      ),
    );
  }
}
