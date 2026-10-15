// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/router/routes.dart';
import '../../core/theme/motion.dart';
import '../../core/utils/local_date.dart';
import '../../core/utils/italian_date.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/tab_scaffold.dart';
import '../workout/data/today_plan.dart';
import 'data/food_repository.dart';
import 'data/food_state.dart';
import 'domain/nutrition.dart';
import 'presentation/ai_food_screen.dart';
import 'presentation/food_amount_sheet.dart';
import 'presentation/scanner_screen.dart';
import 'presentation/week_and_water.dart';

/// Formatta 1530 come "1.530".
String thousands(num value) {
  final s = '${value.round()}';
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0 && s[i - 1] != '-') b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

/// "Oggi, martedì 13 ottobre", "Ieri, lunedì 12 ottobre", "Domenica 11 ottobre".
String dayLabel(LocalDate day, LocalDate today) {
  final date = formatItalianDate(day.dateTime);
  if (day == today) return 'Oggi, $date';
  if (day == today.addDays(-1)) return 'Ieri, $date';
  return formatItalianDate(day.dateTime, capitalize: true);
}

/// Apre lo scanner e poi la scelta dei grammi.
Future<void> scanAndAdd(BuildContext context, Meal meal) async {
  final food = await context.push<Object?>(Routes.foodScanner);
  if (food is ScannedFood && context.mounted) {
    await showFoodAmountSheet(context, food.item, meal: meal);
  }
}

/// Scheda "Cibo": diario del giorno con calorie e macronutrienti.
class FoodScreen extends ConsumerWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final day = ref.watch(foodDayProvider);
    final isToday = day == today;
    final entries = ref.watch(dayDiaryProvider).value ?? const [];
    final logged = {for (final e in entries) e.meal};
    final next = isToday
        ? ref.watch(nextMealProvider)
        : Meal.values.firstWhere(
            (m) => !logged.contains(m),
            orElse: () => Meal.snack,
          );
    final targets = ref.watch(targetsProvider);
    final totals = ref.watch(dayTotalsProvider);

    return TabScaffold(
      header: ScreenHeader(
        title: 'Cibo',
        subtitle: 'Diario, acqua e settimana',
        actions: [
          HeaderPillButton(
            icon: Icons.qr_code_scanner,
            label: 'Scansiona',
            onPressed: () => scanAndAdd(context, next),
          ),
        ],
      ),
      children: [
        const DayBar(),
        AiWriteCard(meal: next),
        if (targets == null)
          _SetupCard(totals: totals)
        else
          _SummaryCard(
            targets: targets,
            totals: totals,
            goal: ref.watch(bodyProfileProvider).value?.goal ?? Goal.maintain,
          ),
        _MealsSection(entries: entries, next: next, isToday: isToday),
        if (targets != null && isToday)
          _AdviceLink(targets: targets, totals: totals, meal: next),
        const WaterCard(),
        if (targets != null) WeekCard(target: targets),
      ],
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.totals});

  final Nutrients totals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DisciplineCard(
      color: scheme.primaryContainer,
      onTap: () => context.push(Routes.bodyData),
      child: Row(
        spacing: 14,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  'Mangiate: ${thousands(totals.kcal)} kcal',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Inserisci peso, altezza, età e obiettivo per sapere quante '
                  'calorie e proteine ti servono.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.targets,
    required this.totals,
    required this.goal,
  });

  final NutritionTargets targets;
  final Nutrients totals;
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final left = targets.kcal - totals.kcal;
    final muted = scheme.onSurfaceVariant;
    Widget label(String text) => Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: muted,
      ),
    );
    const big = TextStyle(fontSize: 20, fontWeight: FontWeight.w800);

    Widget macro(
      String name,
      double value,
      double target,
      Color color,
      Color track, {
      bool max = false,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        // Va a capo se il testo è grande (accessibilità).
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 4,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            Text(
              '${value.round()} / ${max ? 'max ' : ''}${target.round()} g',
              style: TextStyle(fontSize: 13, color: muted),
            ),
          ],
        ),
        SegmentBar(
          value: target == 0 ? 0 : value / target,
          color: value > target && max ? scheme.error : color,
          track: track,
          semanticsLabel: name,
        ),
      ],
    );

    return DisciplineCard(
      semanticsLabel: 'Calorie e macronutrienti',
      child: Column(
        spacing: 16,
        children: [
          Row(
            spacing: 18,
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: Semantics(
                  label:
                      '${thousands(totals.kcal)} kcal su '
                      '${thousands(targets.kcal)}',
                  excludeSemantics: true,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: totals.kcal / targets.kcal),
                    duration: DisciplineMotion.of(
                      context,
                      DisciplineMotion.long,
                    ),
                    curve: DisciplineMotion.decelerate,
                    builder: (context, fraction, child) => CustomPaint(
                      painter: CalorieRingPainter(
                        fraction: fraction,
                        color: scheme.primary,
                        track: Color.lerp(
                          scheme.primaryContainer,
                          scheme.primary,
                          0.25,
                        )!,
                      ),
                      child: child,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(end: left.abs()),
                            duration: DisciplineMotion.of(
                              context,
                              DisciplineMotion.long,
                            ),
                            curve: DisciplineMotion.decelerate,
                            builder: (context, v, _) => Text(
                              thousands(v),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            left >= 0 ? 'rimanenti' : 'in più',
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label('Mangiate'),
                        Text('${thousands(totals.kcal)} kcal', style: big),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label('Obiettivo · ${_goalShort(targets)}'),
                        Text('${thousands(targets.kcal)} kcal', style: big),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          _TwoColumns(
            children: [
              macro(
                'Proteine',
                totals.protein,
                targets.protein,
                scheme.primary,
                Color.lerp(scheme.primaryContainer, scheme.primary, 0.25)!,
              ),
              macro(
                'Carboidrati',
                totals.carbs,
                targets.carbs,
                scheme.tertiary,
                Color.lerp(scheme.tertiaryContainer, scheme.tertiary, 0.15)!,
              ),
              macro(
                'Grassi',
                totals.fat,
                targets.fat,
                scheme.secondary,
                Color.lerp(scheme.secondaryContainer, scheme.secondary, 0.2)!,
              ),
              macro(
                'Zuccheri',
                totals.sugar,
                targets.sugarMax,
                scheme.onSurfaceVariant,
                scheme.outlineVariant,
                max: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _goalShort(NutritionTargets t) =>
      t.raisedToBmr ? 'basale' : goal.short;
}

class _TwoColumns extends StatelessWidget {
  const _TwoColumns({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    spacing: 14,
    children: [
      for (var i = 0; i < children.length; i += 2)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Expanded(child: children[i]),
            Expanded(
              child: i + 1 < children.length
                  ? children[i + 1]
                  : const SizedBox(),
            ),
          ],
        ),
    ],
  );
}

class CalorieRingPainter extends CustomPainter {
  CalorieRingPainter({
    required this.fraction,
    required this.color,
    required this.track,
  });

  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = (Offset.zero & size).deflate(stroke / 2 + 4);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = track);
    final f = fraction.clamp(0.0, 1.0);
    if (f > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * f,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(CalorieRingPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}

class _MealsSection extends ConsumerWidget {
  const _MealsSection({
    required this.entries,
    required this.next,
    required this.isToday,
  });

  final List<DiaryEntry> entries;
  final Meal next;
  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final logged = [
      for (final meal in Meal.values)
        if (entries.any((e) => e.meal == meal)) meal,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 2,
      children: [
        const SectionTitle('Pasti'),
        if (logged.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              isToday
                  ? 'Ancora niente oggi. Cerca un alimento, scansiona un '
                        'codice a barre o scegli un piatto italiano.'
                  : 'Niente registrato in questo giorno. Puoi aggiungere '
                        'adesso quello che hai mangiato.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final meal in logged)
          _MealRow(
            meal: meal,
            entries: [
              for (final e in entries)
                if (e.meal == meal) e,
            ],
          ),
        const SizedBox(height: 10),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => context.push(Routes.foodSearch, extra: next),
                icon: const Icon(Icons.add),
                label: Text(
                  'Aggiungi ${next.withArticle}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MealRow extends ConsumerWidget {
  const _MealRow({required this.meal, required this.entries});

  final Meal meal;
  final List<DiaryEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = entries.fold(Nutrients.zero, (s, e) => s + e.nutrients);
    return InkWell(
      onTap: () => _showMeal(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: scheme.surfaceContainerHigh),
          ),
        ),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                  Text(
                    entries.map((e) => e.food.name).join(', '),
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    total.macrosLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${thousands(total.kcal)} kcal',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMeal(BuildContext context, WidgetRef ref) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => _MealSheet(meal: meal),
      );
}

class _MealSheet extends ConsumerWidget {
  const _MealSheet({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entries = [
      for (final e in ref.watch(dayDiaryProvider).value ?? const <DiaryEntry>[])
        if (e.meal == meal) e,
    ];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.label, style: theme.textTheme.titleLarge),
                Text(
                  'Tocca un alimento per cambiare i grammi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (final e in entries)
            ListTile(
              onTap: () =>
                  showFoodAmountSheet(context, e.food, meal: e.meal, entry: e),
              title: Text(e.food.name),
              subtitle: Text(
                '${e.grams.round()} g · ${e.nutrients.macrosLabel}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${e.nutrients.kcal.round()} kcal'),
                  IconButton(
                    tooltip: 'Aggiungi ai preferiti',
                    icon: const Icon(Icons.star_outline),
                    onPressed: () async {
                      await ref
                          .read(foodRepositoryProvider)
                          .addFavorite(e.food, e.grams);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('«${e.food.name}» nei preferiti'),
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Elimina ${e.food.name}',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        ref.read(foodRepositoryProvider).deleteEntry(e.id),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.tonalIcon(
              onPressed: () {
                Navigator.pop(context);
                context.push(Routes.foodSearch, extra: meal);
              },
              icon: const Icon(Icons.add),
              label: Text('Aggiungi ${meal.toMeal}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdviceLink extends StatelessWidget {
  const _AdviceLink({
    required this.targets,
    required this.totals,
    required this.meal,
  });

  final NutritionTargets targets;
  final Nutrients totals;
  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final protein = (targets.protein - totals.protein).round();
    return DisciplineCard(
      color: scheme.tertiaryContainer,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      onTap: () => context.push(Routes.nutrition),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cosa mangio ${meal.when}?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
                ),
                Text(
                  protein > 0
                      ? 'Ti mancano $protein g di proteine: vedi i consigli'
                      : 'Proteine raggiunte: vedi i consigli',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.tertiary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward,
              color: scheme.onTertiary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
