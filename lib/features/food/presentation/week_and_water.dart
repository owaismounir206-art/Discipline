// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/motion.dart';
import '../../../core/widgets/common.dart';
import '../../profile/domain/athlete_profile.dart';
import '../../workout/data/today_plan.dart';
import '../data/food_repository.dart';
import '../data/food_state.dart';
import '../food_screen.dart';
import '../domain/nutrition.dart';
import '../../../core/feedback/ui_feedback.dart';

/// Frecce per passare al giorno prima o dopo (mai oltre oggi).
class DayBar extends ConsumerWidget {
  const DayBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final today = ref.watch(todayProvider);
    final day = ref.watch(foodDayProvider);
    final notifier = ref.read(foodDayNotifierProvider.notifier);
    final isToday = day == today;

    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: 'Giorno prima',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => notifier.show(day.addDays(-1), today),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: DisciplineMotion.of(context, DisciplineMotion.medium),
            switchInCurve: DisciplineMotion.decelerate,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(day),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayLabel(day, today),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (!isToday)
                  TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(0, 36)),
                    onPressed: () => notifier.show(today, today),
                    child: const Text('Torna a oggi'),
                  ),
              ],
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Giorno dopo',
          icon: const Icon(Icons.chevron_right),
          onPressed: isToday
              ? null
              : () => notifier.show(day.addDays(1), today),
          style: IconButton.styleFrom(
            disabledBackgroundColor: scheme.surfaceContainer,
          ),
        ),
      ],
    );
  }
}

/// Bicchieri d'acqua: si riempiono uno alla volta.
class WaterCard extends ConsumerWidget {
  const WaterCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final day = ref.watch(foodDayProvider);
    final ml = ref.watch(waterProvider).value?[day] ?? 0;
    final target = waterTargetMl(ref.watch(bodyProfileProvider).value);
    final glasses = target ~/ glassMl;
    final drunk = ml ~/ glassMl;
    final repo = ref.read(foodRepositoryProvider);

    Future<void> set(int value) async {
      UiFeedback.instance.play(
        value > drunk ? UiSound.success : UiSound.toggleOff,
      );
      await repo.setWater(day, value);
    }

    String liters(int v) => '${litersText(v)} l';

    return DisciplineCard(
      radius: 24,
      semanticsLabel: 'Acqua: ${liters(ml)} su ${liters(target)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            spacing: 12,
            children: [
              IconBadge(
                icon: Icons.water_drop_outlined,
                background: scheme.secondaryContainer,
                foreground: scheme.onSecondaryContainer,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Acqua', style: theme.textTheme.titleMedium),
                    Text(
                      '${liters(ml)} di ${liters(target)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.outlined(
                tooltip: 'Togli un bicchiere ($glassMl ml)',
                icon: const Icon(Icons.remove),
                onPressed: ml == 0 ? null : () => set(ml - glassMl),
              ),
              IconButton.filled(
                tooltip: 'Aggiungi un bicchiere ($glassMl ml)',
                icon: const Icon(Icons.add),
                onPressed: () => set(ml + glassMl),
              ),
            ],
          ),
          ExcludeSemantics(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < (drunk > glasses ? drunk : glasses); i++)
                  _Glass(full: i < drunk, extra: i >= glasses),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.full, required this.extra});

  final bool full;
  final bool extra;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = DisciplineMotion.of(context, DisciplineMotion.medium);
    // Blu acqua, accordato ai colori del tema.
    final water = Color.lerp(scheme.primary, const Color(0xFF2F7FC1), 0.7)!;
    final color = extra ? scheme.tertiary : water;
    return Container(
      width: 26,
      height: 34,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(4),
          bottom: Radius.circular(8),
        ),
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.bottomCenter,
      child: AnimatedFractionallySizedBox(
        duration: duration,
        curve: DisciplineMotion.decelerate,
        heightFactor: full ? 1 : 0,
        widthFactor: 1,
        child: ColoredBox(color: color),
      ),
    );
  }
}

/// La settimana del giorno scelto: calorie di ogni giorno rispetto
/// all'obiettivo. Tocca una colonna per aprire quel giorno.
class WeekCard extends ConsumerWidget {
  const WeekCard({super.key, required this.target});

  final NutritionTargets target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = ref.watch(todayProvider);
    final day = ref.watch(foodDayProvider);
    final monday = day.startOfWeek;
    final totals = ref.watch(weekTotalsProvider).value ?? const {};
    final logged = [
      for (final e in totals.entries)
        if (e.value.kcal > 0) e.value,
    ];
    final avgKcal = logged.isEmpty
        ? 0
        : logged.fold(0.0, (s, n) => s + n.kcal) / logged.length;
    final proteinDays = logged
        .where((n) => n.protein >= target.protein * 0.9)
        .length;
    final notifier = ref.read(foodDayNotifierProvider.notifier);
    const barMax = 90.0;

    return DisciplineCard(
      radius: 24,
      semanticsLabel: 'Questa settimana',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Text(
            monday == today.startOfWeek ? 'Questa settimana' : 'Settimana',
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(
            height: barMax + 34,
            child: Stack(
              children: [
                // Linea dell'obiettivo (100%).
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 26 + 4 + barMax / 1.3,
                  child: Container(height: 1.5, color: scheme.outline),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 8,
                  children: [
                    for (var i = 0; i < 7; i++)
                      () {
                        final d = monday.addDays(i);
                        final kcal = totals[d]?.kcal ?? 0;
                        final ratio = (kcal / target.kcal).clamp(0.0, 1.3);
                        final future = d.isAfter(today);
                        final selected = d == day;
                        final over = kcal > target.kcal * 1.1;
                        return Expanded(
                          child: Semantics(
                            button: !future,
                            selected: selected,
                            label:
                                '${weekdayNames[d.weekday - 1]}: '
                                '${kcal.round()} kcal',
                            excludeSemantics: true,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: future
                                  ? null
                                  : () => notifier.show(d, today),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                spacing: 6,
                                children: [
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(end: ratio),
                                    duration: DisciplineMotion.of(
                                      context,
                                      DisciplineMotion.long,
                                    ),
                                    curve: DisciplineMotion.decelerate,
                                    builder: (context, r, _) => Container(
                                      height: 4 + r / 1.3 * barMax,
                                      decoration: BoxDecoration(
                                        color: kcal == 0
                                            ? scheme.surfaceContainerHighest
                                            : over
                                            ? scheme.tertiary
                                            : selected
                                            ? scheme.primary
                                            : Color.lerp(
                                                scheme.primaryContainer,
                                                scheme.primary,
                                                0.45,
                                              ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    weekdayLetters[d.weekday - 1],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: selected
                                          ? scheme.primary
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }(),
                  ],
                ),
              ],
            ),
          ),
          Text(
            logged.isEmpty
                ? 'Nessun pasto registrato questa settimana.'
                : 'Media ${thousands(avgKcal)} kcal su ${thousands(target.kcal)} · '
                      'proteine raggiunte $proteinDays '
                      '${proteinDays == 1 ? 'giorno' : 'giorni'} '
                      'su ${logged.length}',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Millilitri in litri: 2000 → "2", 2500 → "2,5", 10000 → "10".
String litersText(int ml) {
  if (ml % 1000 == 0) return '${ml ~/ 1000}';
  return (ml / 1000)
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceAll('.', ',');
}
