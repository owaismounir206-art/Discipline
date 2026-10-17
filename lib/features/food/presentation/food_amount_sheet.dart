// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/data/providers.dart';
import '../../../core/widgets/common.dart';
import '../data/food_state.dart';
import '../data/food_repository.dart';
import '../domain/foods.dart';
import '../domain/nutrition.dart';
import '../../../core/feedback/ui_feedback.dart';

/// Chiede i grammi e il pasto, poi aggiunge l'alimento al diario.
/// Restituisce true se è stato aggiunto.
///
/// Con [entry] corregge una voce già nel diario (grammi e pasto).
Future<bool> showFoodAmountSheet(
  BuildContext context,
  FoodItem food, {
  required Meal meal,
  DiaryEntry? entry,
}) async {
  final added = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FoodAmountSheet(food: food, meal: meal, entry: entry),
  );
  return added ?? false;
}

class FoodAmountSheet extends ConsumerStatefulWidget {
  const FoodAmountSheet({
    super.key,
    required this.food,
    required this.meal,
    this.entry,
  });

  final FoodItem food;
  final Meal meal;
  final DiaryEntry? entry;

  @override
  ConsumerState<FoodAmountSheet> createState() => _FoodAmountSheetState();
}

class _FoodAmountSheetState extends ConsumerState<FoodAmountSheet> {
  /// Salvataggio in corso: un doppio tocco non aggiunge due volte.
  var _saving = false;

  // Una voce del diario tiene i grammi che aveva, finché non tocchi lo stepper.
  late int _grams =
      widget.entry?.grams.round() ??
      widget.food.defaultGrams.round().clamp(1, 3000);
  late Meal _meal = widget.meal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final food = widget.food;
    final n = food.per100.forGrams(_grams.toDouble());
    final allergies =
        ref.watch(bodyProfileProvider).value?.allergies ?? const <Allergen>{};
    final warning = food.allergens.intersection(allergies);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(food.displayName, style: theme.textTheme.titleLarge),
            Text(
              'Per 100 g: ${food.per100.kcal.round()} kcal · '
              '${food.per100.macrosLabel}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (warning.isNotEmpty)
              DisciplineCard(
                color: scheme.errorContainer,
                radius: 16,
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Attenzione: contiene ${warning.map((a) => a.label.toLowerCase()).join(', ')}.',
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            ValueStepper(
              label: 'Grammi',
              value: _grams,
              min: 5,
              max: 3000,
              step: 10,
              suffix: ' g',
              onChanged: (v) => setState(() => _grams = v),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final g in {food.defaultGrams.round(), 50, 100, 150, 200})
                  ActionChip(
                    label: Text('$g g'),
                    onPressed: () => setState(() => _grams = g),
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in Meal.values)
                  ChoiceChip(
                    label: Text(m.label),
                    selected: m == _meal,
                    onSelected: (_) => setState(() => _meal = m),
                  ),
              ],
            ),
            DisciplineCard(
              radius: 20,
              padding: const EdgeInsets.all(14),
              semanticsLabel: 'Valori per $_grams grammi',
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      n.macrosLabel,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${n.kcal.round()} kcal',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Row(
              spacing: 8,
              children: [
                IconButton.outlined(
                  tooltip: 'Aggiungi ai preferiti',
                  icon: const Icon(Icons.star_outline),
                  onPressed: () async {
                    await ref
                        .read(foodRepositoryProvider)
                        .addFavorite(food, _grams.toDouble());
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('«${food.name}» nei preferiti')),
                      );
                    }
                  },
                ),
                if (widget.entry != null)
                  IconButton.outlined(
                    tooltip: 'Elimina',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ref
                          .read(foodRepositoryProvider)
                          .deleteEntry(widget.entry!.id);
                      if (context.mounted) Navigator.pop(context, true);
                    },
                  ),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            final repo = ref.read(foodRepositoryProvider);
                            final entry = widget.entry;
                            if (entry != null) {
                              await repo.updateEntry(
                                entry.id,
                                grams: _grams.toDouble(),
                                meal: _meal,
                              );
                            } else {
                              await repo.addEntry(
                                date: ref.read(foodDayProvider),
                                meal: _meal,
                                food: food,
                                grams: _grams.toDouble(),
                                now: ref.read(clockProvider)(),
                              );
                            }
                            UiFeedback.instance.play(UiSound.success);
                            if (context.mounted) Navigator.pop(context, true);
                          },
                    child: Text(
                      widget.entry != null
                          ? 'Salva'
                          : 'Aggiungi ${_meal.toMeal}',
                    ),
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
