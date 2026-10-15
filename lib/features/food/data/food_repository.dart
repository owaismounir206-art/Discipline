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

  Future<void> addEntry({
    required LocalDate date,
    required Meal meal,
    required FoodItem food,
    required double grams,
    required DateTime now,
  }) async {
    await _db
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
  Future<void> addFavorite(FoodItem food, double grams) =>
      _db.transaction(() async {
        await removeFavorite(food.displayName);
        await _db
            .into(_db.favoriteFoods)
            .insert(
              FavoriteFoodsCompanion.insert(
                name: food.displayName,
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

  Future<void> removeFavorite(String name) =>
      (_db.delete(_db.favoriteFoods)..where((t) => t.name.equals(name))).go();
}

final foodRepositoryProvider = Provider<FoodRepository>(
  (ref) => FoodRepository(ref.watch(databaseProvider)),
);

final bodyProfileProvider = StreamProvider<BodyProfile?>(
  (ref) => ref.watch(foodRepositoryProvider).watchBody(),
);

final favoritesProvider = StreamProvider<List<FoodItem>>(
  (ref) => ref.watch(foodRepositoryProvider).watchFavorites(),
);
