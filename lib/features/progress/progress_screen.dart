// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/services/share.dart';
import '../../core/theme/ritmo_theme.dart';
import '../../core/utils/local_date.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/tab_scaffold.dart';
import '../exercises/domain/exercise.dart';
import '../profile/data/profile_repository.dart';
import '../profile/domain/athlete_profile.dart';
import '../workout/data/today_plan.dart';
import '../workout/data/workout_repository.dart';
import 'domain/progress_stats.dart';

/// Serie salvate, nel formato delle statistiche.
final setRecordsProvider = Provider<List<SetRecord>>((ref) {
  final sets = ref.watch(loggedSetsProvider).value ?? const [];
  return [
    for (final s in sets)
      (date: s.date, exerciseId: s.exerciseId, chain: s.chain, value: s.value),
  ];
});

final _periodProvider = NotifierProvider<_PeriodNotifier, ProgressPeriod>(
  _PeriodNotifier.new,
);

class _PeriodNotifier extends Notifier<ProgressPeriod> {
  @override
  ProgressPeriod build() => ProgressPeriod.week;

  void select(ProgressPeriod p) => state = p;
}

const _weekdayShort = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

String _when(LocalDate date, LocalDate today) {
  final days = today.daysSince(date);
  if (days == 0) return 'Oggi';
  if (days == 1) return 'Ieri';
  if (days < 7) return _weekdayShort[date.weekday - 1];
  return '${date.day}/${date.month}';
}

/// Scheda "Progressi": grafici, record e abilità sbloccate.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final period = ref.watch(_periodProvider);
    final sets = ref.watch(setRecordsProvider);
    final today = ref.watch(todayProvider);
    final profile = ref.watch(athleteProfileProvider).value;
    final chains = ref.watch(chainProgressProvider).value ?? const {};
    final schedule = ref.watch(scheduleProvider).value ?? const [];
    final streak = ref.watch(streakProvider);

    final bars = repsChart(sets, period, today);
    final trend = repsTrend(bars);
    final pushUps = pushUpsInMonth(sets, today);
    final pulls = maxPullUps(sets, fromTest: profile?.test.maxPullUps ?? 0);
    final plank = maxPlankSeconds(
      sets,
      fromTest: profile?.test.plankSeconds ?? 0,
    );
    final skills = schedule.isEmpty
        ? const <UnlockedSkill>[]
        : unlockedSkills(chains, sets, schedule.first.from);

    return TabScaffold(
      header: ScreenHeader(
        title: 'Progressi',
        actions: [
          IconButton(
            tooltip: 'Condividi',
            color: scheme.onSurfaceVariant,
            icon: const Icon(Icons.share_outlined),
            onPressed: () => ref
                .read(shareTextProvider)
                .call(
                  _shareText(
                    profile: profile,
                    streak: streak.current,
                    best: streak.best,
                    pushUps: pushUps,
                    pulls: pulls,
                  ),
                ),
          ),
        ],
      ),
      children: [
        SegmentedButton<ProgressPeriod>(
          showSelectedIcon: false,
          segments: [
            for (final p in ProgressPeriod.values)
              ButtonSegment(value: p, label: Text(p.label)),
          ],
          selected: {period},
          onSelectionChanged: (s) =>
              ref.read(_periodProvider.notifier).select(s.first),
        ),
        RitmoCard(
          padding: const EdgeInsets.all(20),
          semanticsLabel: 'Ripetizioni per sessione',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ripetizioni, ${period.lastLabel}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            text: '${lastCompleteValue(bars)}',
                            children: [
                              TextSpan(
                                text: ' rip.',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          style: const TextStyle(
                            fontSize: 34,
                            height: 40 / 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trend != null)
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: scheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 4,
                        children: [
                          Icon(
                            trend.percent >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: 16,
                            color: scheme.onTertiaryContainer,
                          ),
                          Text(
                            '${trend.percent >= 0 ? '+' : ''}${trend.percent}% '
                            'dal ${trend.since}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: scheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              _BarChart(bars: bars),
            ],
          ),
        ),
        _StatGrid(
          tiles: [
            _StatTile(
              label: 'Push-up nel mese',
              value: _thousands(pushUps),
              color: scheme.primaryContainer,
              onColor: scheme.onPrimaryContainer,
            ),
            _StatTile(
              label: 'Trazioni di fila',
              value: '$pulls',
              unit: ' max',
              color: scheme.tertiaryContainer,
              onColor: scheme.onTertiaryContainer,
            ),
            _StatTile(
              label: 'Plank',
              value: formatDuration(plank),
              unit: ' min',
              color: scheme.surfaceContainerHigh,
              onColor: scheme.onSurface,
            ),
            _StatTile(
              label: 'Streak record',
              value: '${streak.best}',
              unit: streak.best == 1 ? ' allenamento' : ' allenamenti',
              color: scheme.surfaceContainerHigh,
              onColor: scheme.onSurface,
            ),
          ],
        ),
        SectionTitle(
          'Abilità sbloccate',
          trailing: Text(
            '${variantsReached(chains)} varianti',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (skills.isEmpty)
          Text(
            'Chiudi tutte le serie al massimo per 2 sessioni di fila e '
            'sbloccherai la variante successiva.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        for (final (i, skill) in skills.indexed)
          RitmoCard(
            color: scheme.surfaceContainerLow,
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              spacing: 12,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: scheme.onPrimary,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i == 0 && today.daysSince(skill.since) < 7
                            ? 'Nuova abilità sbloccata'
                            : skill.exercise.chain.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        skill.best > 0
                            ? '${skill.exercise.name} · ${skill.best} '
                                  '${skill.exercise.measure == Measure.seconds ? 's' : 'di fila'}'
                            : skill.exercise.name,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  _when(skill.since, today),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _thousands(int n) {
  final s = '$n';
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

String _shareText({
  required AthleteProfile? profile,
  required int streak,
  required int best,
  required int pushUps,
  required int pulls,
}) => [
  'I miei progressi su Ritmo 💪',
  if (streak > 0) '🔥 $streak allenamenti di fila (record: $best)',
  '• $pushUps push-up questo mese',
  if (pulls > 0) '• $pulls trazioni di fila',
  'Ritmo è gratis e open source: github.com/owaismounir206-art/Discipline',
].join('\n');

class _BarChart extends StatelessWidget {
  const _BarChart({required this.bars});

  final List<ChartBar> bars;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (bars.every((b) => b.value == 0)) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'Ancora nessuna ripetizione in questo periodo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final max = bars.fold(1, (m, b) => b.value > m ? b.value : m);
    final light = Color.lerp(scheme.primaryContainer, scheme.primary, 0.25)!;
    final description = bars.map((b) => '${b.label} ${b.value}').join(', ');

    return Semantics(
      label: 'Ripetizioni: $description',
      excludeSemantics: true,
      child: SizedBox(
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: bars.length > 8 ? 4 : 6,
          children: [
            for (final b in bars)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 6,
                  children: [
                    Container(
                      height: b.value == 0 ? 4 : 4 + 126 * b.value / max,
                      decoration: BoxDecoration(
                        color: b.current ? light : scheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Text(
                      b.label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: b.current
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: b.current
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.onColor,
    this.unit,
  });

  final String label;
  final String value;
  final String? unit;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return RitmoCard(
      color: color,
      radius: RitmoRadii.card,
      padding: const EdgeInsets.all(16),
      semanticsLabel: '$label: $value${unit ?? ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: onColor.withValues(alpha: 0.8),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text.rich(
              TextSpan(
                text: value,
                children: [
                  if (unit != null)
                    TextSpan(
                      text: unit,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: onColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Griglia 2 × 2 ad altezza libera (regge testi grandi e accessibilità).
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) => Column(
    spacing: 12,
    children: [
      for (var i = 0; i < tiles.length; i += 2)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Expanded(child: tiles[i]),
              Expanded(
                child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox(),
              ),
            ],
          ),
        ),
    ],
  );
}
