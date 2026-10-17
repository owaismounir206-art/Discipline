// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'foods.dart';
import 'nutrition.dart';

/// Un ingrediente di una ricetta fatta in casa.
@immutable
class Ingredient {
  const Ingredient(this.food, this.grams);

  final FoodItem food;
  final double grams;

  Nutrients get nutrients => food.per100.forGrams(grams);

  Ingredient withGrams(double g) => Ingredient(food, g);
}

/// Una ricetta fatta in casa: ingredienti, peso finale e porzioni. Diventa
/// un alimento con i valori per 100 g, da usare come gli altri.
@immutable
class HomemadeRecipe {
  const HomemadeRecipe({
    required this.name,
    required this.ingredients,
    this.cookedGrams,
    this.portions = 1,
  });

  final String name;
  final List<Ingredient> ingredients;

  /// Peso a fine cottura (la pasta cotta pesa di più, il sugo ristretto di
  /// meno). Se manca, la somma degli ingredienti.
  final double? cookedGrams;
  final int portions;

  double get rawGrams => ingredients.fold(0, (s, i) => s + i.grams);

  double get totalGrams {
    final cooked = cookedGrams;
    return cooked != null && cooked > 0 ? cooked : rawGrams;
  }

  Nutrients get total =>
      ingredients.fold(Nutrients.zero, (s, i) => s + i.nutrients);

  Nutrients get per100 =>
      totalGrams <= 0 ? Nutrients.zero : total * (100 / totalGrams);

  double get portionGrams => totalGrams / math.max(1, portions);

  Nutrients get perPortion => total * (1 / math.max(1, portions));

  bool get isValid => name.trim().isNotEmpty && rawGrams > 0;

  /// L'alimento da mettere nel diario (una porzione proposta).
  FoodItem toFood() => FoodItem(
    name: name.trim(),
    per100: per100,
    source: FoodSource.homemade,
    defaultGrams: portionGrams.roundToDouble(),
    allergens: {for (final i in ingredients) ...i.food.allergens},
    // Vegana solo se lo sono tutti gli ingredienti, e così via.
    diet: ingredients.isEmpty
        ? Diet.vegan
        : Diet.values[ingredients
              .map((i) => i.food.diet.index)
              .reduce(math.min)],
  );

  HomemadeRecipe copyWith({
    String? name,
    List<Ingredient>? ingredients,
    double? cookedGrams,
    bool clearCooked = false,
    int? portions,
  }) => HomemadeRecipe(
    name: name ?? this.name,
    ingredients: ingredients ?? this.ingredients,
    cookedGrams: clearCooked ? null : cookedGrams ?? this.cookedGrams,
    portions: portions ?? this.portions,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'cooked': cookedGrams,
    'portions': portions,
    'ingredients': [
      for (final i in ingredients) {'food': foodToJson(i.food), 'g': i.grams},
    ],
  };

  static HomemadeRecipe fromJson(Map<String, Object?> j) => HomemadeRecipe(
    name: j['name']! as String,
    cookedGrams: (j['cooked'] as num?)?.toDouble(),
    portions: (j['portions'] as num?)?.toInt() ?? 1,
    ingredients: [
      for (final i in (j['ingredients'] as List?) ?? const [])
        Ingredient(
          foodFromJson(((i as Map)['food'] as Map).cast<String, Object?>()),
          (i['g'] as num).toDouble(),
        ),
    ],
  );
}

/// Bozza di una ricetta nuova (es. da "Cosa cucino?"): l'editor si apre
/// precompilato e non tocca le ricette già salvate.
@immutable
class HomemadeDraft {
  const HomemadeDraft({required this.recipe});

  final HomemadeRecipe recipe;
}

Map<String, Object?> foodToJson(FoodItem f) => {
  'name': f.name,
  'kcal': f.per100.kcal,
  'p': f.per100.protein,
  'c': f.per100.carbs,
  'f': f.per100.fat,
  's': f.per100.sugar,
  'source': f.source.name,
  'grams': f.defaultGrams,
  'brand': f.brand,
  'barcode': f.barcode,
  'allergens': [for (final a in f.allergens) a.name],
  'diet': f.diet.name,
};

FoodItem foodFromJson(Map<String, Object?> j) {
  double n(String k) => (j[k] as num?)?.toDouble() ?? 0;
  return FoodItem(
    name: j['name']! as String,
    per100: Nutrients(
      kcal: n('kcal'),
      protein: n('p'),
      carbs: n('c'),
      fat: n('f'),
      sugar: n('s'),
    ),
    source: FoodSource.values.asNameMap()[j['source']] ?? FoodSource.custom,
    defaultGrams: (j['grams'] as num?)?.toDouble() ?? 100,
    brand: j['brand'] as String?,
    barcode: j['barcode'] as String?,
    allergens: {
      for (final a in (j['allergens'] as List?) ?? const [])
        ?Allergen.values.asNameMap()[a],
    },
    diet: Diet.values.asNameMap()[j['diet']] ?? Diet.omnivore,
  );
}
