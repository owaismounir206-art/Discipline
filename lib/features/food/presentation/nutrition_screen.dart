// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/data/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/common.dart';
import '../../profile/data/profile_repository.dart';
import '../../workout/data/today_plan.dart';
import '../data/food_repository.dart';
import '../data/food_state.dart';
import '../domain/foods.dart';
import '../food_screen.dart';

const disclaimer =
    'Valori stimati da peso, altezza, età e attività. Non sostituiscono il '
    'parere di un nutrizionista.';

/// Consigli alimentari (design "Nutrizione").
class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final body = ref.watch(bodyProfileProvider).value;
    final targets = ref.watch(targetsProvider);
    final totals = ref.watch(todayTotalsProvider);
    final meal = ref.watch(nextMealProvider);
    final suggestions = ref.watch(recommendationsProvider);
    final days = ref.watch(athleteProfileProvider).value?.trainingDays.length;

    if (body == null || targets == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Consigli per te')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                const Text(
                  'Per i consigli servono i tuoi dati: peso, altezza, età e '
                  'obiettivo.',
                  textAlign: TextAlign.center,
                ),
                FilledButton(
                  onPressed: () => context.push(Routes.bodyData),
                  child: const Text('Inserisci i tuoi dati'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final proteinLeft = (targets.protein - totals.protein).round();
    final kcalLeft = (targets.kcal - totals.kcal).round();
    final onBody = scheme.onPrimaryContainer;

    Widget bodyValue(String label, String value) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: onBody)),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: onBody,
              ),
            ),
          ],
        ),
      ),
    );

    Widget need(String label, String value, String sub) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              sub,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Consigli per te')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            RitmoCard(
              color: scheme.primaryContainer,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              semanticsLabel: 'Il tuo corpo',
              child: Column(
                spacing: 12,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Obiettivo',
                              style: TextStyle(fontSize: 13, color: onBody),
                            ),
                            Text(
                              body.goal.label,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: onBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.surface,
                          foregroundColor: scheme.primary,
                          minimumSize: const Size(0, 40),
                        ),
                        onPressed: () => context.push(Routes.bodyData),
                        child: const Text('Modifica'),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      bodyValue('Peso', '${_n(body.weightKg)} kg'),
                      bodyValue('Altezza', '${body.heightCm.round()} cm'),
                      bodyValue('Età', '${body.age}'),
                      bodyValue('Allenam.', '${days ?? 0}/sett.'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle('Il tuo fabbisogno giornaliero'),
            const SizedBox(height: 10),
            Row(
              spacing: 8,
              children: [
                need('Calorie', thousands(targets.kcal), 'kcal'),
                need(
                  'Proteine',
                  '${targets.protein.round()} g',
                  '${_n(body.proteinPerKg)} g/kg',
                ),
                need(
                  'Carbo',
                  '${targets.carbs.round()} g',
                  '${targets.carbsPercent}%',
                ),
                need(
                  'Grassi',
                  '${targets.fat.round()} g',
                  '${targets.fatPercent}%',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Basale ${thousands(targets.bmr)} kcal × '
              '${_n(targets.activity.factor, 3)} '
              '(${targets.activity.label.toLowerCase()}) '
              '${body.goal.kcalDelta >= 0 ? '+' : '−'} '
              '${body.goal.kcalDelta.abs()} kcal · zuccheri aggiunti al '
              'massimo ${targets.sugarMax.round()} g.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (targets.raisedToBmr) ...[
              const SizedBox(height: 8),
              RitmoCard(
                color: scheme.tertiaryContainer,
                radius: 16,
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Non scendiamo mai sotto il tuo metabolismo basale: '
                  'l\'obiettivo è stato alzato a ${thousands(targets.bmr)} kcal.',
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
              ),
            ],
            const SizedBox(height: 18),
            SectionTitle('Per ${meal.label.toLowerCase()}'),
            const SizedBox(height: 4),
            Text(
              kcalLeft <= 0
                  ? 'Hai raggiunto le calorie di oggi.'
                  : proteinLeft > 0
                  ? 'Ti mancano $proteinLeft g di proteine e '
                        '${thousands(kcalLeft)} kcal'
                  : 'Proteine raggiunte · restano ${thousands(kcalLeft)} kcal',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            if (suggestions.isEmpty)
              Text(
                'Nessun piatto della lista rientra nelle calorie rimaste o '
                'nelle tue preferenze.',
                style: theme.textTheme.bodyMedium,
              ),
            for (final r in suggestions) ...[
              _RecipeCard(recipe: r),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            Text(
              disclaimer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _n(double v, [int digits = 1]) {
  final text = v == v.roundToDouble()
      ? v.round().toString()
      : v.toStringAsFixed(digits).replaceFirst(RegExp(r'0+$'), '');
  return text.replaceAll('.', ',');
}

class _RecipeCard extends ConsumerStatefulWidget {
  const _RecipeCard({required this.recipe});

  final Recipe recipe;

  @override
  ConsumerState<_RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends ConsumerState<_RecipeCard> {
  int? _entryId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = widget.recipe;
    final added = _entryId != null;
    return RitmoCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  r.tags.first,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                Text(r.name, style: theme.textTheme.titleMedium),
                Text(
                  r.summary,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          added
              ? FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: () async {
                    await ref
                        .read(foodRepositoryProvider)
                        .deleteEntry(_entryId!);
                    setState(() => _entryId = null);
                  },
                  child: const Text('Aggiunto'),
                )
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: () async {
                    final repo = ref.read(foodRepositoryProvider);
                    final meal = ref.read(nextMealProvider);
                    await repo.addEntry(
                      date: ref.read(todayProvider),
                      meal: meal,
                      food: r.toFoodItem(),
                      grams: r.grams,
                      now: ref.read(clockProvider)(),
                    );
                    final entries = await repo.entriesOf(
                      ref.read(todayProvider),
                      meal,
                    );
                    setState(() => _entryId = entries.last.id);
                  },
                  child: const Text('Aggiungi'),
                ),
        ],
      ),
    );
  }
}
