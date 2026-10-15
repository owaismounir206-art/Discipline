// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:meta/meta.dart';

enum Sex {
  male('Uomo'),
  female('Donna');

  const Sex(this.label);

  final String label;
}

enum ActivityLevel {
  sedentary('Sedentario', 'Poco movimento', 1.2),
  light('Leggero', '1–2 allenamenti a settimana', 1.375),
  moderate('Moderato', '3–5 allenamenti a settimana', 1.55),
  high('Intenso', '6–7 allenamenti a settimana', 1.725);

  const ActivityLevel(this.label, this.description, this.factor);

  final String label;
  final String description;
  final double factor;
}

/// Livello di attività stimato dai giorni di allenamento scelti.
ActivityLevel activityFromTrainingDays(int days) => switch (days) {
  <= 0 => ActivityLevel.sedentary,
  <= 2 => ActivityLevel.light,
  <= 5 => ActivityLevel.moderate,
  _ => ActivityLevel.high,
};

enum Goal {
  cut('Definizione', -400),
  maintain('Mantenimento', 0),
  bulk('Massa muscolare', 300);

  const Goal(this.label, this.kcalDelta);

  final String label;
  final int kcalDelta;

  /// "massa", "definizione", "mantenimento" per le frasi brevi.
  String get short => switch (this) {
    Goal.cut => 'definizione',
    Goal.maintain => 'mantenimento',
    Goal.bulk => 'massa',
  };
}

enum Diet {
  omnivore('Onnivoro'),
  vegetarian('Vegetariano'),
  vegan('Vegano');

  const Diet(this.label);

  final String label;
}

enum Allergen {
  gluten('Glutine'),
  lactose('Latte e lattosio'),
  eggs('Uova'),
  fish('Pesce'),
  shellfish('Crostacei'),
  nuts('Frutta a guscio'),
  peanuts('Arachidi'),
  soy('Soia');

  const Allergen(this.label);

  final String label;
}

/// Limiti delle proteine consigliate (g per kg di peso).
const proteinMinPerKg = 1.6;
const proteinMaxPerKg = 2.2;
const proteinDefaultPerKg = 1.8;

/// Dati del corpo e preferenze per i consigli alimentari.
@immutable
class BodyProfile {
  const BodyProfile({
    required this.sex,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.goal,
    this.activity,
    this.proteinPerKg = proteinDefaultPerKg,
    this.diet = Diet.omnivore,
    this.allergies = const {},
  });

  final Sex sex;
  final int age;
  final double weightKg;
  final double heightCm;
  final Goal goal;

  /// Scelto a mano; se null si stima dai giorni di allenamento.
  final ActivityLevel? activity;
  final double proteinPerKg;
  final Diet diet;
  final Set<Allergen> allergies;

  BodyProfile copyWith({
    Sex? sex,
    int? age,
    double? weightKg,
    double? heightCm,
    Goal? goal,
    ActivityLevel? activity,
    bool automaticActivity = false,
    double? proteinPerKg,
    Diet? diet,
    Set<Allergen>? allergies,
  }) => BodyProfile(
    sex: sex ?? this.sex,
    age: age ?? this.age,
    weightKg: weightKg ?? this.weightKg,
    heightCm: heightCm ?? this.heightCm,
    goal: goal ?? this.goal,
    activity: automaticActivity ? null : activity ?? this.activity,
    proteinPerKg: proteinPerKg ?? this.proteinPerKg,
    diet: diet ?? this.diet,
    allergies: allergies ?? this.allergies,
  );

  Map<String, Object?> toJson() => {
    'sex': sex.name,
    'age': age,
    'weight': weightKg,
    'height': heightCm,
    'goal': goal.name,
    if (activity != null) 'activity': activity!.name,
    'protein': proteinPerKg,
    'diet': diet.name,
    'allergies': [for (final a in allergies) a.name],
  };

  factory BodyProfile.fromJson(Map<String, Object?> json) => BodyProfile(
    sex: Sex.values.byName(json['sex']! as String),
    age: (json['age']! as num).toInt(),
    weightKg: (json['weight']! as num).toDouble(),
    heightCm: (json['height']! as num).toDouble(),
    goal: Goal.values.byName(json['goal']! as String),
    activity: json['activity'] == null
        ? null
        : ActivityLevel.values.byName(json['activity']! as String),
    proteinPerKg: (json['protein'] as num?)?.toDouble() ?? proteinDefaultPerKg,
    diet: Diet.values.byName(json['diet'] as String? ?? 'omnivore'),
    allergies: {
      for (final a in (json['allergies'] as List<Object?>? ?? const []))
        if (Allergen.values.any((x) => x.name == a))
          Allergen.values.byName(a! as String),
    },
  );
}

/// Fabbisogno giornaliero.
@immutable
class NutritionTargets {
  const NutritionTargets({
    required this.bmr,
    required this.tdee,
    required this.activity,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.sugarMax,
    required this.raisedToBmr,
  });

  /// Metabolismo basale (Mifflin-St Jeor).
  final double bmr;

  /// Consumo giornaliero stimato (basale × attività).
  final double tdee;
  final ActivityLevel activity;

  /// Obiettivo calorico.
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;

  /// Zuccheri aggiunti: al massimo il 10% delle calorie.
  final double sugarMax;

  /// Vero se l'obiettivo è stato alzato fino al metabolismo basale.
  final bool raisedToBmr;

  int get carbsPercent => (carbs * 4 / kcal * 100).round();
  int get fatPercent => (fat * 9 / kcal * 100).round();
}

/// Metabolismo basale con la formula di Mifflin-St Jeor.
double mifflinStJeor({
  required Sex sex,
  required double weightKg,
  required double heightCm,
  required int age,
}) => 10 * weightKg + 6.25 * heightCm - 5 * age + (sex == Sex.male ? 5 : -161);

/// Calcola il fabbisogno. L'obiettivo non scende mai sotto il basale.
NutritionTargets computeTargets(BodyProfile body, {required int trainingDays}) {
  final bmr = mifflinStJeor(
    sex: body.sex,
    weightKg: body.weightKg,
    heightCm: body.heightCm,
    age: body.age,
  );
  final activity = body.activity ?? activityFromTrainingDays(trainingDays);
  final tdee = bmr * activity.factor;
  final wanted = tdee + body.goal.kcalDelta;
  final kcal = wanted < bmr ? bmr : wanted;
  final protein =
      body.weightKg * body.proteinPerKg.clamp(proteinMinPerKg, proteinMaxPerKg);
  final fat = kcal * 0.25 / 9;
  final carbs = ((kcal - protein * 4 - fat * 9) / 4).clamp(
    0.0,
    double.infinity,
  );
  return NutritionTargets(
    bmr: bmr,
    tdee: tdee,
    activity: activity,
    kcal: kcal,
    protein: protein,
    fat: fat,
    carbs: carbs,
    sugarMax: kcal * 0.10 / 4,
    raisedToBmr: wanted < bmr,
  );
}

/// Valori nutrizionali (per 100 g o per una porzione).
/// Acqua consigliata al giorno: 35 ml per kg, a bicchieri da 250 ml
/// (tra 1,5 e 4 litri; 2 litri senza dati).
int waterTargetMl(BodyProfile? body) {
  if (body == null) return 2000;
  final ml = (body.weightKg * 35 / 250).round() * 250;
  return ml.clamp(1500, 4000);
}

/// Un bicchiere.
const glassMl = 250;

@immutable
class Nutrients {
  const Nutrients({
    this.kcal = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.sugar = 0,
  });

  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;

  static const zero = Nutrients();

  Nutrients operator +(Nutrients o) => Nutrients(
    kcal: kcal + o.kcal,
    protein: protein + o.protein,
    carbs: carbs + o.carbs,
    fat: fat + o.fat,
    sugar: sugar + o.sugar,
  );

  Nutrients operator *(double f) => Nutrients(
    kcal: kcal * f,
    protein: protein * f,
    carbs: carbs * f,
    fat: fat * f,
    sugar: sugar * f,
  );

  /// Valori per [grams] grammi, se questi sono per 100 g.
  Nutrients forGrams(double grams) => this * (grams / 100);

  /// "P 28 g · C 52 g · G 10 g · zuccheri 18 g".
  String get macrosLabel =>
      'P ${protein.round()} g · C ${carbs.round()} g · '
      'G ${fat.round()} g · zuccheri ${sugar.round()} g';
}

enum Meal {
  breakfast('Colazione', 'la colazione', 'alla colazione', 'a colazione'),
  lunch('Pranzo', 'il pranzo', 'al pranzo', 'a pranzo'),
  snack('Spuntino', 'lo spuntino', 'allo spuntino', 'per lo spuntino'),
  dinner('Cena', 'la cena', 'alla cena', 'a cena');

  const Meal(this.label, this.withArticle, this.toMeal, this.when);

  final String label;

  /// "Aggiungi la cena".
  final String withArticle;

  /// "Aggiungi alla cena".
  final String toMeal;

  /// "Cosa mangio a cena?".
  final String when;
}

/// Pasto previsto per un'ora del giorno.
Meal mealForTime(DateTime time) {
  final minutes = time.hour * 60 + time.minute;
  if (minutes < 10 * 60 + 30) return Meal.breakfast;
  if (minutes < 15 * 60) return Meal.lunch;
  if (minutes < 18 * 60 + 30) return Meal.snack;
  return Meal.dinner;
}

/// Prossimo pasto da riempire: quello dell'ora attuale o il primo dopo
/// ancora vuoto; a fine giornata resta la cena.
Meal nextMeal(DateTime now, Set<Meal> logged) {
  final current = mealForTime(now);
  for (final meal in Meal.values.skip(current.index)) {
    if (!logged.contains(meal)) return meal;
  }
  return Meal.dinner;
}
