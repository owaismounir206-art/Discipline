// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/data/providers.dart';
import '../../../core/router/routes.dart';
import '../../workout/data/today_plan.dart';
import '../data/food_state.dart';
import '../data/food_repository.dart';
import '../data/open_food_facts.dart';
import '../domain/foods.dart';
import '../domain/homemade.dart';
import '../domain/nutrition.dart';
import '../food_screen.dart';
import 'custom_food_sheet.dart';
import 'food_amount_sheet.dart';
import 'scanner_screen.dart';

/// Cerca un alimento: preferiti, piatti italiani e Open Food Facts.
class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({
    super.key,
    required this.meal,
    this.pickOnly = false,
  });

  final Meal meal;

  /// Solo scelta (ingrediente di una ricetta): restituisce l'alimento senza
  /// aggiungerlo al diario.
  final bool pickOnly;

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<FoodItem> _online = const [];
  bool _loading = false;
  String? _error;
  int _request = 0;
  bool _repeating = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    setState(() {});
    _debounce?.cancel();
    if (text.trim().length < 3) {
      // Una risposta ancora in arrivo non deve riempire la lista vuota.
      _request++;
      setState(() {
        _online = const [];
        _error = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 700), () => _search(text));
  }

  Future<void> _search(String text) async {
    _debounce?.cancel();
    if (text.trim().length < 3) return;
    final id = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref.read(foodCatalogProvider).search(text);
      if (!mounted || id != _request) return;
      setState(() {
        _online = results;
        _loading = false;
      });
    } on FoodCatalogException catch (e) {
      if (!mounted || id != _request) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || id != _request) return;
      setState(() {
        _error = 'Non riesco a cercare: riprova.';
        _loading = false;
      });
    }
  }

  Future<void> _pick(FoodItem food) async {
    if (widget.pickOnly) {
      context.pop(food);
      return;
    }
    final added = await showFoodAmountSheet(context, food, meal: widget.meal);
    if (added && mounted) context.pop();
  }

  /// Scanner in modalità scelta: il prodotto torna all'ingrediente, senza
  /// entrare nel diario.
  Future<void> _scanPick() async {
    final result = await context.push<Object?>(Routes.foodScanner);
    if (result is ScannedFood && mounted) context.pop(result.item);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final query = _query.text;
    final favorites = searchLocalFoods(
      query,
      ref.watch(favoritesProvider).value ?? const [],
    );
    final local = searchLocalFoods(query);
    final homemade = <HomemadeRecipe>[
      for (final r in ref.watch(homemadeProvider).value ?? <HomemadeRecipe>[])
        if (query.trim().isEmpty ||
            r.name.toLowerCase().contains(query.trim().toLowerCase()))
          r,
    ];
    final isToday = ref.watch(foodDayProvider) == ref.watch(todayProvider);
    final before = isToday ? 'di ieri' : 'del giorno prima';

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary),
        ),
      ),
    );

    Widget tile(FoodItem f) => ListTile(
      title: Text(f.displayName),
      subtitle: Text(
        '${f.per100.kcal.round()} kcal · P ${f.per100.protein.round()} g '
        'per 100 g',
      ),
      trailing: const Icon(Icons.add_circle_outline),
      onTap: () => _pick(f),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pickOnly
              ? 'Scegli un ingrediente'
              : 'Aggiungi ${widget.meal.toMeal}',
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: _search,
                decoration: InputDecoration(
                  hintText: 'Cerca un alimento (es. yogurt, pasta)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Scansiona',
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: widget.pickOnly
                        ? _scanPick
                        : () => scanAndAdd(context, widget.meal),
                  ),
                ),
              ),
            ),
            if (query.isEmpty && !widget.pickOnly)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.replay),
                  label: Text('Ripeti ${widget.meal.withArticle} $before'),
                  onPressed: _repeating
                      ? null
                      : () async {
                          setState(() => _repeating = true);
                          final int count;
                          try {
                            count = await ref
                                .read(foodRepositoryProvider)
                                .repeatYesterday(
                                  widget.meal,
                                  ref.read(foodDayProvider),
                                  ref.read(clockProvider)(),
                                );
                          } catch (_) {
                            if (!context.mounted) return;
                            setState(() => _repeating = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Non riesco a copiare '
                                  '${widget.meal.withArticle}: riprova.',
                                ),
                              ),
                            );
                            return;
                          }
                          if (!context.mounted) return;
                          setState(() => _repeating = false);
                          if (count == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isToday
                                      ? 'Ieri non hai registrato ${widget.meal.withArticle}'
                                      : 'Il giorno prima non hai registrato '
                                            '${widget.meal.withArticle}',
                                ),
                              ),
                            );
                          } else {
                            context.pop();
                          }
                        },
                ),
              ),
            if (favorites.isNotEmpty) ...[
              header('Preferiti'),
              for (final f in favorites) tile(f),
            ],
            if (query.trim().length >= 3) ...[
              header('Open Food Facts'),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                ListTile(
                  leading: const Icon(Icons.cloud_off),
                  title: Text(_error!),
                )
              else if (_online.isEmpty)
                const ListTile(title: Text('Nessun prodotto trovato'))
              else
                for (final f in _online.take(15)) tile(f),
            ],
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Crea un alimento'),
              subtitle: const Text(
                'Non lo trovi? Inserisci i valori dell\'etichetta',
              ),
              onTap: () async {
                final food = await showCustomFoodSheet(
                  context,
                  name: query.trim(),
                );
                if (food == null || !context.mounted) return;
                await ref.read(foodRepositoryProvider).addFavorite(food, 100);
                if (context.mounted) await _pick(food);
              },
            ),
            if (!widget.pickOnly) ...[
              ListTile(
                leading: const Icon(Icons.soup_kitchen_outlined),
                title: const Text('Ricetta fatta in casa'),
                subtitle: const Text(
                  'Metti gli ingredienti: calcolo io calorie e porzioni',
                ),
                onTap: () => context.push(Routes.homemade),
              ),
              if (homemade.isNotEmpty) ...[
                header('Le tue ricette'),
                for (final r in homemade)
                  ListTile(
                    title: Text(r.name),
                    subtitle: Text(
                      '${r.perPortion.kcal.round()} kcal a porzione · '
                      '${r.portionGrams.round()} g',
                    ),
                    leading: IconButton(
                      tooltip: 'Modifica ${r.name}',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push(Routes.homemade, extra: r),
                    ),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () => _pick(r.toFood()),
                  ),
              ],
            ],
            header('Piatti e alimenti italiani'),
            if (local.isEmpty)
              const ListTile(title: Text('Nessun alimento con questo nome'))
            else
              for (final f in local) tile(f),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Valori medi per 100 g: sono stime. I prodotti confezionati '
                'arrivano da Open Food Facts, un database libero.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
