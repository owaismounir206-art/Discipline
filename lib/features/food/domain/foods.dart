// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:meta/meta.dart';

import 'nutrition.dart';

/// Da dove viene un alimento.
enum FoodSource { local, openFoodFacts, recipe, custom, homemade, ai }

/// Un alimento con i valori per 100 g.
@immutable
class FoodItem {
  const FoodItem({
    required this.name,
    required this.per100,
    this.source = FoodSource.local,
    this.defaultGrams = 100,
    this.barcode,
    this.brand,
    this.allergens = const {},
    this.diet = Diet.omnivore,
  });

  final String name;
  final Nutrients per100;
  final FoodSource source;

  /// Porzione proposta quando lo aggiungi.
  final double defaultGrams;
  final String? barcode;
  final String? brand;
  final Set<Allergen> allergens;

  /// La dieta più restrittiva compatibile (vegano va bene per tutti).
  final Diet diet;

  String get displayName =>
      brand == null || brand!.isEmpty ? name : '$name · $brand';
}

/// Valori medi per 100 g di alimenti comuni in Italia (fonti: tabelle
/// CREA e USDA, arrotondati). Sono stime.
const localFoods = <FoodItem>[
  FoodItem(
    name: 'Pasta di semola (cruda)',
    per100: Nutrients(kcal: 353, protein: 13, carbs: 72, fat: 1.5, sugar: 3.5),
    defaultGrams: 80,
    allergens: {Allergen.gluten},
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Pasta integrale (cruda)',
    per100: Nutrients(kcal: 340, protein: 13.4, carbs: 64, fat: 2.5, sugar: 3),
    defaultGrams: 80,
    allergens: {Allergen.gluten},
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Riso (crudo)',
    per100: Nutrients(kcal: 360, protein: 7, carbs: 80, fat: 0.6, sugar: 0.2),
    defaultGrams: 80,
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Pane comune',
    per100: Nutrients(kcal: 270, protein: 8.5, carbs: 56, fat: 1, sugar: 2.5),
    defaultGrams: 50,
    allergens: {Allergen.gluten},
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Pane integrale',
    per100: Nutrients(kcal: 240, protein: 9, carbs: 46, fat: 2, sugar: 3),
    defaultGrams: 50,
    allergens: {Allergen.gluten},
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Fette biscottate',
    per100: Nutrients(kcal: 410, protein: 11, carbs: 76, fat: 6, sugar: 8),
    defaultGrams: 30,
    allergens: {Allergen.gluten},
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Fiocchi d\'avena',
    per100: Nutrients(kcal: 370, protein: 13, carbs: 60, fat: 7, sugar: 1),
    defaultGrams: 40,
    allergens: {Allergen.gluten},
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Biscotti secchi',
    per100: Nutrients(kcal: 430, protein: 7, carbs: 75, fat: 12, sugar: 22),
    defaultGrams: 30,
    allergens: {Allergen.gluten},
    diet: Diet.vegetarian,
  ),
  FoodItem(
    name: 'Cornetto',
    per100: Nutrients(kcal: 410, protein: 7, carbs: 45, fat: 22, sugar: 15),
    defaultGrams: 60,
    allergens: {Allergen.gluten, Allergen.lactose, Allergen.eggs},
    diet: Diet.vegetarian,
  ),
  FoodItem(
    name: 'Pizza margherita',
    per100: Nutrients(kcal: 270, protein: 11, carbs: 33, fat: 10, sugar: 2),
    defaultGrams: 300,
    allergens: {Allergen.gluten, Allergen.lactose},
    diet: Diet.vegetarian,
  ),
  FoodItem(
    name: 'Petto di pollo',
    per100: Nutrients(kcal: 110, protein: 23, carbs: 0, fat: 1.5),
    defaultGrams: 150,
  ),
  FoodItem(
    name: 'Petto di tacchino',
    per100: Nutrients(kcal: 107, protein: 24, carbs: 0, fat: 1),
    defaultGrams: 150,
  ),
  FoodItem(
    name: 'Manzo magro',
    per100: Nutrients(kcal: 130, protein: 21, carbs: 0, fat: 5),
    defaultGrams: 150,
  ),
  FoodItem(
    name: 'Bresaola',
    per100: Nutrients(kcal: 151, protein: 32, carbs: 0, fat: 2.6),
    defaultGrams: 50,
  ),
  FoodItem(
    name: 'Prosciutto crudo',
    per100: Nutrients(kcal: 270, protein: 26, carbs: 0, fat: 18),
    defaultGrams: 50,
  ),
  FoodItem(
    name: 'Prosciutto cotto',
    per100: Nutrients(kcal: 215, protein: 20, carbs: 1, fat: 15, sugar: 1),
    defaultGrams: 50,
  ),
  FoodItem(
    name: 'Salmone',
    per100: Nutrients(kcal: 185, protein: 20, carbs: 0, fat: 12),
    defaultGrams: 150,
    allergens: {Allergen.fish},
  ),
  FoodItem(
    name: 'Tonno al naturale',
    per100: Nutrients(kcal: 103, protein: 25, carbs: 0, fat: 0.5),
    defaultGrams: 80,
    allergens: {Allergen.fish},
  ),
  FoodItem(
    name: 'Merluzzo',
    per100: Nutrients(kcal: 80, protein: 17, carbs: 0, fat: 0.7),
    defaultGrams: 200,
    allergens: {Allergen.fish},
  ),
  FoodItem(
    name: 'Uovo',
    per100: Nutrients(
      kcal: 140,
      protein: 12.5,
      carbs: 0.5,
      fat: 10,
      sugar: 0.5,
    ),
    defaultGrams: 60,
    allergens: {Allergen.eggs},
    diet: Diet.vegetarian,
  ),
  FoodItem(
    name: 'Albume',
    per100: Nutrients(kcal: 45, protein: 11, carbs: 0.7, fat: 0.2, sugar: 0.7),
    defaultGrams: 100,
    allergens: {Allergen.eggs},
    diet: Diet.vegetarian,
  ),
  FoodItem(
    name: 'Latte parzialmente scremato',
    per100: Nutrients(kcal: 46, protein: 3.3, carbs: 5, fat: 1.6, sugar: 5),
    defaultGrams: 200,
    allergens: {Allergen.lactose},
    diet: Diet.vegetarian,
  ),
  FoodItem(
    name: 'Yogurt greco 0%',
    per100: Nutrients(kcal: 57, protein: 10, carbs: 4, fat: 0.4, sugar: 4),
    defaultGrams: 170,
    allergens: {Allergen.lactose},
    diet: Diet.vegetarian,
  ),
  FoodItem(
    name: 'Yogurt bianco intero',
    per100: Nutrients(kcal: 66, protein: 3.8, carbs: 4.3, fat: 3.9, sugar: 4.3),
    defaultGrams: 125,
    allergens: {Allergen.lactose},
    diet: Diet.vegetarian,
  ),
  FoodItem(
    name: 'Parmigiano Reggiano',
    per100: Nutrients(kcal: 392, protein: 33, carbs: 0, fat: 28),
    defaultGrams: 20,
    allergens: {Allergen.lactose},
    diet: Diet.vegetarian,
  ),
  FoodItem(
    name: 'Mozzarella',
    per100: Nutrients(
      kcal: 253,
      protein: 18.7,
      carbs: 0.7,
      fat: 19.5,
      sugar: 0.7,
    ),
    defaultGrams: 100,
    allergens: {Allergen.lactose},
    diet: Diet.vegetarian,
  ),
  FoodItem(
    name: 'Ricotta',
    per100: Nutrients(
      kcal: 146,
      protein: 8.8,
      carbs: 3.5,
      fat: 10.9,
      sugar: 3.5,
    ),
    defaultGrams: 100,
    allergens: {Allergen.lactose},
    diet: Diet.vegetarian,
  ),
  FoodItem(
    name: 'Fiocchi di latte',
    per100: Nutrients(kcal: 100, protein: 12, carbs: 3, fat: 4.5, sugar: 3),
    defaultGrams: 150,
    allergens: {Allergen.lactose},
    diet: Diet.vegetarian,
  ),
  FoodItem(
    name: 'Ceci (cotti)',
    per100: Nutrients(kcal: 120, protein: 7, carbs: 18, fat: 2.5, sugar: 1),
    defaultGrams: 150,
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Lenticchie (cotte)',
    per100: Nutrients(kcal: 116, protein: 9, carbs: 17, fat: 0.4, sugar: 1.8),
    defaultGrams: 150,
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Fagioli borlotti (cotti)',
    per100: Nutrients(kcal: 120, protein: 8, carbs: 20, fat: 0.6, sugar: 0.5),
    defaultGrams: 150,
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Tofu',
    per100: Nutrients(kcal: 120, protein: 13, carbs: 2, fat: 7, sugar: 0.5),
    defaultGrams: 150,
    allergens: {Allergen.soy},
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Hummus',
    per100: Nutrients(kcal: 170, protein: 8, carbs: 14, fat: 10, sugar: 0.3),
    defaultGrams: 50,
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Patate',
    per100: Nutrients(kcal: 77, protein: 2, carbs: 17, fat: 0.1, sugar: 0.8),
    defaultGrams: 200,
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Banana',
    per100: Nutrients(kcal: 89, protein: 1.1, carbs: 23, fat: 0.3, sugar: 12),
    defaultGrams: 120,
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Mela',
    per100: Nutrients(kcal: 52, protein: 0.3, carbs: 14, fat: 0.2, sugar: 10),
    defaultGrams: 150,
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Arancia',
    per100: Nutrients(kcal: 47, protein: 0.9, carbs: 12, fat: 0.1, sugar: 9),
    defaultGrams: 150,
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Mirtilli',
    per100: Nutrients(kcal: 57, protein: 0.7, carbs: 14, fat: 0.3, sugar: 10),
    defaultGrams: 80,
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Insalata',
    per100: Nutrients(kcal: 15, protein: 1.4, carbs: 2.9, fat: 0.2, sugar: 1.2),
    defaultGrams: 80,
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Pomodori',
    per100: Nutrients(kcal: 18, protein: 0.9, carbs: 3.9, fat: 0.2, sugar: 2.6),
    defaultGrams: 150,
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Zucchine',
    per100: Nutrients(kcal: 17, protein: 1.2, carbs: 3.1, fat: 0.3, sugar: 2.5),
    defaultGrams: 200,
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Spinaci',
    per100: Nutrients(kcal: 23, protein: 2.9, carbs: 3.6, fat: 0.4, sugar: 0.4),
    defaultGrams: 150,
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Broccoli',
    per100: Nutrients(kcal: 34, protein: 2.8, carbs: 7, fat: 0.4, sugar: 1.7),
    defaultGrams: 200,
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Avocado',
    per100: Nutrients(kcal: 160, protein: 2, carbs: 9, fat: 15, sugar: 0.7),
    defaultGrams: 70,
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Olio extravergine d\'oliva',
    per100: Nutrients(kcal: 884, fat: 100),
    defaultGrams: 10,
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Burro di arachidi',
    per100: Nutrients(kcal: 590, protein: 25, carbs: 20, fat: 50, sugar: 9),
    defaultGrams: 20,
    allergens: {Allergen.peanuts},
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Mandorle',
    per100: Nutrients(kcal: 600, protein: 22, carbs: 9, fat: 53, sugar: 4),
    defaultGrams: 30,
    allergens: {Allergen.nuts},
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Noci',
    per100: Nutrients(kcal: 654, protein: 15, carbs: 14, fat: 65, sugar: 2.6),
    defaultGrams: 30,
    allergens: {Allergen.nuts},
    diet: Diet.vegan,
  ),
  FoodItem(
    name: 'Miele',
    per100: Nutrients(kcal: 304, protein: 0.3, carbs: 82, sugar: 82),
    defaultGrams: 15,
    diet: Diet.vegetarian,
  ),
  FoodItem(
    name: 'Cioccolato fondente 70%',
    per100: Nutrients(kcal: 600, protein: 8, carbs: 46, fat: 43, sugar: 24),
    defaultGrams: 20,
    diet: Diet.vegan,
  ),
];

/// Cerca tra gli alimenti locali (senza accenti né maiuscole).
List<FoodItem> searchLocalFoods(
  String query, [
  List<FoodItem> foods = localFoods,
]) {
  final q = normalizeText(query);
  if (q.isEmpty) return foods;
  final words = q.split(' ').where((w) => w.isNotEmpty);
  return [
    for (final f in foods)
      if (words.every(normalizeText(f.name).contains)) f,
  ];
}

String normalizeText(String s) {
  const from = 'àáâäèéêëìíîïòóôöùúûü';
  const to = 'aaaaeeeeiiiioooouuuu';
  final lower = s.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    buffer.write(i >= 0 ? to[i] : ch);
  }
  return buffer.toString();
}

bool dietAllows(Diet person, Diet food) => switch (person) {
  Diet.omnivore => true,
  Diet.vegetarian => food != Diet.omnivore,
  Diet.vegan => food == Diet.vegan,
};

/// Un piatto pronto da consigliare (valori per porzione).
@immutable
class Recipe {
  const Recipe({
    required this.name,
    required this.grams,
    required this.portion,
    required this.tags,
    required this.meals,
    this.allergens = const {},
    this.diet = Diet.omnivore,
  });

  final String name;

  /// Peso della porzione.
  final double grams;
  final Nutrients portion;

  /// Etichette, la prima è quella principale ("Ricco di proteine"...).
  final List<String> tags;
  final Set<Meal> meals;
  final Set<Allergen> allergens;
  final Diet diet;

  /// Come alimento del diario (valori riportati a 100 g).
  FoodItem toFoodItem() => FoodItem(
    name: name,
    per100: portion * (100 / grams),
    source: FoodSource.recipe,
    defaultGrams: grams,
    allergens: allergens,
    diet: diet,
  );

  /// "650 kcal · P 42 g · C 70 g · G 20 g".
  String get summary =>
      '${portion.kcal.round()} kcal · P ${portion.protein.round()} g · '
      'C ${portion.carbs.round()} g · G ${portion.fat.round()} g';
}

const tagProtein = 'Ricco di proteine';
const tagPostWorkout = 'Post-allenamento';
const tagVegetarian = 'Vegetariano';
const tagVegan = 'Vegano';
const tagLight = 'Leggero';

const _mains = {Meal.lunch, Meal.dinner};
const _light = {Meal.breakfast, Meal.snack};

/// Ricette locali per i consigli.
const recipes = <Recipe>[
  Recipe(
    name: 'Salmone, riso basmati e zucchine',
    grams: 450,
    portion: Nutrients(kcal: 650, protein: 42, carbs: 70, fat: 20, sugar: 4),
    tags: [tagProtein],
    meals: _mains,
    allergens: {Allergen.fish},
  ),
  Recipe(
    name: 'Pollo, patate al forno e insalata',
    grams: 480,
    portion: Nutrients(kcal: 600, protein: 48, carbs: 55, fat: 18, sugar: 4),
    tags: [tagPostWorkout, tagProtein],
    meals: _mains,
  ),
  Recipe(
    name: 'Frittata di 3 uova con ceci e spinaci',
    grams: 400,
    portion: Nutrients(kcal: 540, protein: 36, carbs: 35, fat: 26, sugar: 4),
    tags: [tagVegetarian, tagProtein],
    meals: _mains,
    allergens: {Allergen.eggs},
    diet: Diet.vegetarian,
  ),
  Recipe(
    name: 'Pasta al tonno e pomodoro',
    grams: 400,
    portion: Nutrients(kcal: 620, protein: 38, carbs: 82, fat: 14, sugar: 8),
    tags: [tagPostWorkout],
    meals: _mains,
    allergens: {Allergen.fish, Allergen.gluten},
  ),
  Recipe(
    name: 'Petto di pollo, riso e broccoli',
    grams: 450,
    portion: Nutrients(kcal: 550, protein: 50, carbs: 62, fat: 9, sugar: 3),
    tags: [tagPostWorkout, tagProtein],
    meals: _mains,
  ),
  Recipe(
    name: 'Tacchino ai ferri con farro e verdure',
    grams: 450,
    portion: Nutrients(kcal: 560, protein: 46, carbs: 58, fat: 12, sugar: 4),
    tags: [tagProtein],
    meals: _mains,
    allergens: {Allergen.gluten},
  ),
  Recipe(
    name: 'Merluzzo al forno con patate',
    grams: 450,
    portion: Nutrients(kcal: 480, protein: 38, carbs: 50, fat: 12, sugar: 3),
    tags: [tagLight, tagProtein],
    meals: _mains,
    allergens: {Allergen.fish},
  ),
  Recipe(
    name: 'Bresaola, rucola, grana e pane integrale',
    grams: 220,
    portion: Nutrients(kcal: 450, protein: 42, carbs: 38, fat: 14, sugar: 3),
    tags: [tagProtein, tagLight],
    meals: _mains,
    allergens: {Allergen.lactose, Allergen.gluten},
  ),
  Recipe(
    name: 'Lenticchie in umido con riso',
    grams: 450,
    portion: Nutrients(kcal: 520, protein: 26, carbs: 88, fat: 8, sugar: 5),
    tags: [tagVegan],
    meals: _mains,
    diet: Diet.vegan,
  ),
  Recipe(
    name: 'Pasta e fagioli',
    grams: 450,
    portion: Nutrients(kcal: 560, protein: 24, carbs: 90, fat: 10, sugar: 5),
    tags: [tagVegan],
    meals: _mains,
    allergens: {Allergen.gluten},
    diet: Diet.vegan,
  ),
  Recipe(
    name: 'Tofu saltato con verdure e riso',
    grams: 450,
    portion: Nutrients(kcal: 500, protein: 28, carbs: 62, fat: 15, sugar: 6),
    tags: [tagVegan, tagProtein],
    meals: _mains,
    allergens: {Allergen.soy},
    diet: Diet.vegan,
  ),
  Recipe(
    name: 'Insalata di quinoa, ceci e feta',
    grams: 400,
    portion: Nutrients(kcal: 520, protein: 24, carbs: 60, fat: 20, sugar: 5),
    tags: [tagVegetarian],
    meals: _mains,
    allergens: {Allergen.lactose},
    diet: Diet.vegetarian,
  ),
  Recipe(
    name: 'Yogurt greco, avena e frutti di bosco',
    grams: 300,
    portion: Nutrients(kcal: 380, protein: 26, carbs: 48, fat: 8, sugar: 16),
    tags: [tagProtein, tagVegetarian],
    meals: _light,
    allergens: {Allergen.lactose, Allergen.gluten},
    diet: Diet.vegetarian,
  ),
  Recipe(
    name: 'Uova strapazzate, pane integrale e avocado',
    grams: 260,
    portion: Nutrients(kcal: 520, protein: 24, carbs: 40, fat: 28, sugar: 3),
    tags: [tagVegetarian],
    meals: {Meal.breakfast, Meal.lunch},
    allergens: {Allergen.eggs, Allergen.gluten},
    diet: Diet.vegetarian,
  ),
  Recipe(
    name: 'Fiocchi di latte con frutta e mandorle',
    grams: 300,
    portion: Nutrients(kcal: 360, protein: 28, carbs: 30, fat: 14, sugar: 20),
    tags: [tagPostWorkout, tagVegetarian],
    meals: _light,
    allergens: {Allergen.lactose, Allergen.nuts},
    diet: Diet.vegetarian,
  ),
  Recipe(
    name: 'Banana e burro di arachidi',
    grams: 150,
    portion: Nutrients(kcal: 320, protein: 10, carbs: 25, fat: 22, sugar: 11),
    tags: [tagVegan],
    meals: _light,
    allergens: {Allergen.peanuts},
    diet: Diet.vegan,
  ),
  Recipe(
    name: 'Hummus con verdure e pane pita',
    grams: 250,
    portion: Nutrients(kcal: 420, protein: 16, carbs: 54, fat: 16, sugar: 5),
    tags: [tagVegan],
    meals: {Meal.snack, Meal.lunch},
    allergens: {Allergen.gluten},
    diet: Diet.vegan,
  ),
  Recipe(
    name: 'Porridge d\'avena con latte di soia e mela',
    grams: 350,
    portion: Nutrients(kcal: 400, protein: 16, carbs: 62, fat: 9, sugar: 18),
    tags: [tagVegan],
    meals: {Meal.breakfast},
    allergens: {Allergen.gluten, Allergen.soy},
    diet: Diet.vegan,
  ),
];

/// Tre piatti per il prossimo pasto: rispettano dieta e allergie, non
/// superano le calorie rimaste e sono ordinati per quante proteine mancanti
/// coprono. Dopo l'allenamento, a parità, vincono i piatti post-allenamento.
List<Recipe> recommendRecipes({
  required Meal meal,
  required double kcalLeft,
  required double proteinLeft,
  required Diet diet,
  required Set<Allergen> allergies,
  bool trainedToday = false,
  List<Recipe> from = recipes,
  int count = 3,
}) {
  final candidates = [
    for (final r in from)
      if (r.meals.contains(meal) &&
          dietAllows(diet, r.diet) &&
          r.allergens.intersection(allergies).isEmpty &&
          r.portion.kcal <= kcalLeft)
        r,
  ];

  double score(Recipe r) {
    final coverage = proteinLeft <= 0
        ? 0.0
        : (r.portion.protein / proteinLeft).clamp(0.0, 1.0);
    final density = r.portion.protein / r.portion.kcal;
    final bonus = trainedToday && r.tags.contains(tagPostWorkout) ? 0.05 : 0;
    // Il peso della densità rompe i pareggi (es. proteine già coperte).
    return coverage + bonus + density * 0.1;
  }

  candidates.sort((a, b) => score(b).compareTo(score(a)));
  return candidates.take(count).toList();
}
