// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../../../core/data/database.dart';
import '../../../core/data/providers.dart';
import '../../../core/utils/local_date.dart';
import '../../rewards/data/rewards_repository.dart';
import '../../rewards/domain/rewards.dart';
import '../domain/foods.dart';
import '../domain/homemade.dart';
import '../domain/nutrition.dart';

/// Una voce del diario.
@immutable
class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.date,
    required this.meal,
    required this.food,
    required this.grams,
  });

  final int id;
  final LocalDate date;
  final Meal meal;
  final FoodItem food;
  final double grams;

  Nutrients get nutrients => food.per100.forGrams(grams);
}

FoodItem _foodFrom({
  required String name,
  required double kcal,
  required double protein,
  required double carbs,
  required double fat,
  required double sugar,
  required String source,
  required double grams,
  String? barcode,
}) => FoodItem(
  name: name,
  per100: Nutrients(
    kcal: kcal,
    protein: protein,
    carbs: carbs,
    fat: fat,
    sugar: sugar,
  ),
  source: FoodSource.values.firstWhere(
    (s) => s.name == source,
    orElse: () => FoodSource.local,
  ),
  defaultGrams: grams,
  barcode: barcode,
);

class FoodRepository {
  FoodRepository(this._db);

  final AppDatabase _db;

  static const bodyKey = 'body';

  Stream<BodyProfile?> watchBody() => _db
      .watchJson(bodyKey)
      .map(
        (j) =>
            j == null ? null : BodyProfile.fromJson(j as Map<String, Object?>),
      );

  Future<void> saveBody(BodyProfile body) =>
      _db.writeJson(bodyKey, body.toJson());

  static const weightsKey = 'weights';

  /// Diario del peso: data → kg, in ordine di data.
  Stream<Map<LocalDate, double>> watchWeights() =>
      _db.watchJson(weightsKey).map(_weights);

  static Map<LocalDate, double> _weights(Object? json) {
    final list = [
      for (final e in ((json as Map?) ?? const {}).entries)
        (LocalDate.parse('${e.key}'), (e.value as num).toDouble()),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return {for (final (d, kg) in list) d: kg};
  }

  /// Salva il peso del giorno. Se è il più recente aggiorna anche i dati
  /// del corpo, così calorie e proteine seguono il peso attuale.
  Future<void> setWeight(LocalDate date, double kg) =>
      _db.transaction(() async {
        final rounded = (kg * 10).round() / 10;
        final current = _weights(await _db.readJson(weightsKey));
        current[date] = rounded.clamp(20.0, 400.0);
        await _db.writeJson(weightsKey, {
          for (final e in current.entries) e.key.key: e.value,
        });
        final latest = current.keys.reduce((a, b) => a.isAfter(b) ? a : b);
        final body = await _db.readJson(bodyKey);
        if (latest == date && body != null) {
          final profile = BodyProfile.fromJson(body as Map<String, Object?>);
          await saveBody(profile.copyWith(weightKg: current[date]));
        }
      });

  Future<void> removeWeight(LocalDate date) async {
    final current = _weights(await _db.readJson(weightsKey))..remove(date);
    await _db.writeJson(weightsKey, {
      for (final e in current.entries) e.key.key: e.value,
    });
  }

  /// Aggiunge un alimento al diario e restituisce il suo id.
  Future<int> addEntry({
    required LocalDate date,
    required Meal meal,
    required FoodItem food,
    required double grams,
    required DateTime now,
  }) async {
    final id = await _db
        .into(_db.foodEntries)
        .insert(
          FoodEntriesCompanion.insert(
            date: date.key,
            meal: meal.name,
            name: food.displayName,
            grams: grams,
            kcal100: food.per100.kcal,
            protein100: food.per100.protein,
            carbs100: food.per100.carbs,
            fat100: food.per100.fat,
            sugar100: food.per100.sugar,
            source: food.source.name,
            barcode: Value(food.barcode),
            createdAt: now,
          ),
        );
    await _rewardDiary(date, now);
    return id;
  }

  /// 10 punti il giorno in cui registri almeno 3 pasti (solo per oggi:
  /// riempire i giorni passati non vale).
  Future<void> _rewardDiary(LocalDate date, DateTime now) async {
    if (date != LocalDate.fromDateTime(now)) return;
    final rows = await (_db.select(
      _db.foodEntries,
    )..where((t) => t.date.equals(date.key))).get();
    if ({for (final r in rows) r.meal}.length < diaryMeals) return;
    await RewardsRepository(
      _db,
    ).award(PointKind.diary, pointsDiary, at: now, ref: 'diario-${date.key}');
  }

  /// Cambia grammi o pasto di una voce già nel diario.
  Future<void> updateEntry(
    int id, {
    required double grams,
    required Meal meal,
  }) => (_db.update(_db.foodEntries)..where((t) => t.id.equals(id))).write(
    FoodEntriesCompanion(grams: Value(grams), meal: Value(meal.name)),
  );

  /// Totali per giorno tra [from] e [to] (compresi).
  Stream<Map<LocalDate, Nutrients>> watchTotals(LocalDate from, LocalDate to) =>
      (_db.select(_db.foodEntries)
            ..where((t) => t.date.isBetweenValues(from.key, to.key)))
          .watch()
          .map((rows) {
            final totals = <LocalDate, Nutrients>{};
            for (final r in rows) {
              final e = _entry(r);
              totals[e.date] = (totals[e.date] ?? Nutrients.zero) + e.nutrients;
            }
            return totals;
          });

  // --- Acqua ---

  static const waterKey = 'water';

  /// Millilitri bevuti per giorno.
  Stream<Map<LocalDate, int>> watchWater() => _db
      .watchJson(waterKey)
      .map(
        (json) => {
          for (final e in ((json as Map?) ?? const {}).entries)
            LocalDate.parse('${e.key}'): (e.value as num).toInt(),
        },
      );

  Future<void> setWater(LocalDate date, int ml) async {
    final current = (await _db.readJson(waterKey) as Map?) ?? const {};
    await _db.writeJson(waterKey, {
      ...current.cast<String, Object?>(),
      date.key: ml.clamp(0, 10000),
    });
  }

  Future<void> deleteEntry(int id) =>
      (_db.delete(_db.foodEntries)..where((t) => t.id.equals(id))).go();

  Stream<List<DiaryEntry>> watchDay(LocalDate date) =>
      (_db.select(_db.foodEntries)
            ..where((t) => t.date.equals(date.key))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch()
          .map((rows) => [for (final r in rows) _entry(r)]);

  Future<List<DiaryEntry>> entriesOf(LocalDate date, Meal meal) async {
    final rows = await (_db.select(
      _db.foodEntries,
    )..where((t) => t.date.equals(date.key) & t.meal.equals(meal.name))).get();
    return [for (final r in rows) _entry(r)];
  }

  /// "Ripeti pasto di ieri": copia le voci di ieri dello stesso pasto.
  Future<int> repeatYesterday(Meal meal, LocalDate today, DateTime now) async {
    final yesterday = await entriesOf(today.addDays(-1), meal);
    for (final e in yesterday) {
      await addEntry(
        date: today,
        meal: meal,
        food: e.food,
        grams: e.grams,
        now: now,
      );
    }
    return yesterday.length;
  }

  DiaryEntry _entry(FoodEntry r) => DiaryEntry(
    id: r.id,
    date: LocalDate.parse(r.date),
    meal: Meal.values.firstWhere(
      (m) => m.name == r.meal,
      orElse: () => Meal.snack,
    ),
    grams: r.grams,
    food: _foodFrom(
      name: r.name,
      kcal: r.kcal100,
      protein: r.protein100,
      carbs: r.carbs100,
      fat: r.fat100,
      sugar: r.sugar100,
      source: r.source,
      grams: r.grams,
      barcode: r.barcode,
    ),
  );

  // --- Preferiti ---

  Stream<List<FoodItem>> watchFavorites() =>
      (_db.select(
        _db.favoriteFoods,
      )..orderBy([(t) => OrderingTerm.asc(t.name)])).watch().map(
        (rows) => [
          for (final r in rows)
            _foodFrom(
              name: r.name,
              kcal: r.kcal100,
              protein: r.protein100,
              carbs: r.carbs100,
              fat: r.fat100,
              sugar: r.sugar100,
              source: r.source,
              grams: r.grams,
              barcode: r.barcode,
            ),
        ],
      );

  /// Aggiunge o aggiorna un preferito (il nome è unico).
  /// Due prodotti diversi (codici a barre diversi) con lo stesso nome non si
  /// sovrascrivono: il secondo prende il codice nel nome.
  Future<void> addFavorite(FoodItem food, double grams) =>
      _db.transaction(() async {
        var name = food.displayName;
        final code = food.barcode;
        if (code != null) {
          // Lo stesso prodotto salvato con un altro nome: si aggiorna.
          await (_db.delete(
            _db.favoriteFoods,
          )..where((t) => t.barcode.equals(code))).go();
          final same = await (_db.select(
            _db.favoriteFoods,
          )..where((t) => t.name.equals(name))).getSingleOrNull();
          if (same != null && same.barcode != null && same.barcode != code) {
            name = '$name · $code';
          }
        }
        await removeFavorite(name);
        await _db
            .into(_db.favoriteFoods)
            .insert(
              FavoriteFoodsCompanion.insert(
                name: name,
                grams: grams,
                kcal100: food.per100.kcal,
                protein100: food.per100.protein,
                carbs100: food.per100.carbs,
                fat100: food.per100.fat,
                sugar100: food.per100.sugar,
                source: food.source.name,
                barcode: Value(food.barcode),
              ),
            );
      });

  // --- Ricette fatte in casa ---

  static const homemadeKey = 'homemade';

  Stream<List<HomemadeRecipe>> watchHomemade() =>
      _db.watchJson(homemadeKey).map(_recipes);

  static List<HomemadeRecipe> _recipes(Object? json) => [
    for (final r in (json as List?) ?? const [])
      HomemadeRecipe.fromJson((r as Map).cast<String, Object?>()),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  /// Salva la ricetta (sostituisce quella con lo stesso nome, o con
  /// [previousName] se l'hai rinominata) e la mette tra i preferiti.
  Future<void> saveHomemade(HomemadeRecipe recipe, {String? previousName}) =>
      _db.transaction(() async {
        final name = recipe.name.trim();
        final previous = previousName?.trim();
        final others = [
          for (final r in _recipes(await _db.readJson(homemadeKey)))
            if (r.name.trim() != name && r.name.trim() != previous) r,
        ];
        await _db.writeJson(homemadeKey, [
          for (final r in [...others, recipe.copyWith(name: name)]) r.toJson(),
        ]);
        if (previous != null && previous != name) {
          await removeFavorite(previous);
        }
        final food = recipe.toFood();
        await addFavorite(food, food.defaultGrams);
      });

  Future<void> deleteHomemade(String name) => _db.transaction(() async {
    final target = name.trim();
    await _db.writeJson(homemadeKey, [
      for (final r in _recipes(await _db.readJson(homemadeKey)))
        if (r.name.trim() != target) r.toJson(),
    ]);
    await removeFavorite(target);
  });

  Future<void> removeFavorite(String name) =>
      (_db.delete(_db.favoriteFoods)..where((t) => t.name.equals(name))).go();
}

final foodRepositoryProvider = Provider<FoodRepository>(
  (ref) => FoodRepository(ref.watch(databaseProvider)),
);

final bodyProfileProvider = StreamProvider<BodyProfile?>(
  (ref) => ref.watch(foodRepositoryProvider).watchBody(),
);

final weightsProvider = StreamProvider<Map<LocalDate, double>>(
  (ref) => ref.watch(foodRepositoryProvider).watchWeights(),
);

final homemadeProvider = StreamProvider<List<HomemadeRecipe>>(
  (ref) => ref.watch(foodRepositoryProvider).watchHomemade(),
);

final favoritesProvider = StreamProvider<List<FoodItem>>(
  (ref) => ref.watch(foodRepositoryProvider).watchFavorites(),
);
