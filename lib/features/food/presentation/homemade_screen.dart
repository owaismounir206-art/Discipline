// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/common.dart';
import '../data/food_repository.dart';
import '../domain/foods.dart';
import '../domain/homemade.dart';

/// Ricetta fatta in casa: ingredienti con i grammi, peso finale e porzioni.
/// Diventa un alimento tra i preferiti, con le calorie per porzione.
class HomemadeScreen extends ConsumerStatefulWidget {
  const HomemadeScreen({super.key, this.recipe, this.prefill});

  /// Ricetta da modificare (null = nuova).
  final HomemadeRecipe? recipe;

  /// Bozza di una ricetta nuova (es. da "Cosa cucino?"): si rivede e si salva
  /// come nuova, senza elimina.
  final HomemadeRecipe? prefill;

  @override
  ConsumerState<HomemadeScreen> createState() => _HomemadeScreenState();
}

String _g(double v) => '${v.round()} g';

String _n(double v) => v >= 10
    ? '${v.round()}'
    : v.toStringAsFixed(1).replaceAll('.', ',').replaceFirst(',0', '');

class _HomemadeScreenState extends ConsumerState<HomemadeScreen> {
  /// Da dove si parte: la ricetta da modificare o la bozza.
  HomemadeRecipe? get _start => widget.recipe ?? widget.prefill;

  late final _name = TextEditingController(text: _start?.name ?? '');
  late final _cooked = TextEditingController(
    text: _start?.cookedGrams?.round().toString() ?? '',
  );
  late var _ingredients = [...?_start?.ingredients];
  late var _portions = _start?.portions ?? 1;
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _cooked.dispose();
    super.dispose();
  }

  HomemadeRecipe get _recipe => HomemadeRecipe(
    name: _name.text.trim(),
    ingredients: _ingredients,
    cookedGrams: double.tryParse(_cooked.text.trim().replaceAll(',', '.')),
    portions: _portions,
  );

  Future<double?> _askGrams(FoodItem food, double initial) =>
      showDialog<double>(
        context: context,
        builder: (_) => _GramsDialog(title: food.displayName, initial: initial),
      );

  Future<void> _addIngredient() async {
    final food = await context.push<FoodItem>(Routes.foodPick);
    if (food == null || !mounted) return;
    final grams = await _askGrams(food, food.defaultGrams);
    if (grams == null || grams <= 0 || !mounted) return;
    setState(() => _ingredients = [..._ingredients, Ingredient(food, grams)]);
  }

  Future<void> _editIngredient(int i) async {
    final current = _ingredients[i];
    final grams = await _askGrams(current.food, current.grams);
    if (grams == null || !mounted) return;
    setState(() {
      _ingredients = [..._ingredients];
      if (grams <= 0) {
        _ingredients.removeAt(i);
      } else {
        _ingredients[i] = current.withGrams(grams);
      }
    });
  }

  Future<void> _save() async {
    final recipe = _recipe;
    if (!recipe.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            recipe.name.trim().isEmpty
                ? 'Dai un nome alla ricetta.'
                : 'Aggiungi almeno un ingrediente.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(foodRepositoryProvider)
        .saveHomemade(recipe, previousName: widget.recipe?.name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${recipe.name.trim()} salvata: la trovi tra i preferiti e in '
          '"Le tue ricette".',
        ),
      ),
    );
    context.pop();
  }

  Future<void> _delete() async {
    final name = widget.recipe?.name;
    if (name == null) return;
    await ref.read(foodRepositoryProvider).deleteHomemade(name);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final recipe = _recipe;
    final portion = recipe.perPortion;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.recipe == null ? 'Ricetta fatta in casa' : 'Modifica ricetta',
        ),
        actions: [
          if (widget.recipe != null)
            IconButton(
              tooltip: 'Elimina ricetta',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Es. Lasagne della nonna',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SectionTitle('Ingredienti'),
            if (_ingredients.isEmpty)
              Text(
                'Aggiungi gli ingredienti crudi con i loro grammi: li cerchi '
                'come nel diario (anche con lo scanner o creandoli).',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            for (final (i, ing) in _ingredients.indexed)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(ing.food.displayName),
                  subtitle: Text(
                    '${_g(ing.grams)} · ${ing.nutrients.kcal.round()} kcal',
                  ),
                  onTap: () => _editIngredient(i),
                  trailing: IconButton(
                    tooltip: 'Togli ${ing.food.name}',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(
                      () => _ingredients = [..._ingredients]..removeAt(i),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi ingrediente'),
              onPressed: _addIngredient,
            ),
            const SectionTitle('Peso e porzioni'),
            TextField(
              controller: _cooked,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Peso a fine cottura (facoltativo)',
                suffixText: 'g',
                helperText:
                    'Pesa la pentola piena meno la pentola vuota. Se lo lasci '
                    'vuoto: ${_g(recipe.rawGrams)}, la somma degli ingredienti.',
                helperMaxLines: 3,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            ValueStepper(
              label: 'Porzioni',
              value: _portions,
              min: 1,
              max: 30,
              onChanged: (v) => setState(() => _portions = v),
            ),
            const SizedBox(height: 16),
            DisciplineCard(
              color: scheme.secondaryContainer,
              semanticsLabel:
                  'Una porzione: ${portion.kcal.round()} kcal, '
                  '${_g(recipe.portionGrams)}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    'Una porzione · ${_g(recipe.portionGrams)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    '${portion.kcal.round()} kcal',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Proteine ${_n(portion.protein)} g · carboidrati '
                    '${_n(portion.carbs)} g · grassi ${_n(portion.fat)} g',
                    style: TextStyle(color: scheme.onSecondaryContainer),
                  ),
                  Text(
                    'Per 100 g: ${recipe.per100.kcal.round()} kcal · tutta la '
                    'ricetta ${recipe.total.kcal.round()} kcal',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Salva ricetta'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chiede i grammi di un ingrediente.
class _GramsDialog extends StatefulWidget {
  const _GramsDialog({required this.title, required this.initial});

  final String title;
  final double initial;

  @override
  State<_GramsDialog> createState() => _GramsDialogState();
}

class _GramsDialogState extends State<_GramsDialog> {
  late final _controller = TextEditingController(
    text: '${widget.initial.round()}',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _done() => Navigator.pop(
    context,
    double.tryParse(_controller.text.trim().replaceAll(',', '.')),
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))],
      decoration: const InputDecoration(
        labelText: 'Quanti grammi?',
        suffixText: 'g',
      ),
      onSubmitted: (_) => _done(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annulla'),
      ),
      FilledButton(onPressed: _done, child: const Text('Ok')),
    ],
  );
}
