// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ritmo/core/utils/local_date.dart';
import 'package:ritmo/features/food/data/food_repository.dart';
import 'package:ritmo/features/food/data/open_food_facts.dart';
import 'package:ritmo/features/food/domain/foods.dart';
import 'package:ritmo/features/food/domain/nutrition.dart';

import '../helpers.dart';

const alex = BodyProfile(
  sex: Sex.male,
  age: 24,
  weightKg: 72,
  heightCm: 178,
  goal: Goal.bulk,
);

void main() {
  group('Fabbisogno', () {
    test('Mifflin-St Jeor uomo e donna', () {
      expect(
        mifflinStJeor(sex: Sex.male, weightKg: 72, heightCm: 178, age: 24),
        1717.5,
      );
      expect(
        mifflinStJeor(sex: Sex.female, weightKg: 60, heightCm: 165, age: 30),
        10 * 60 + 6.25 * 165 - 5 * 30 - 161,
      );
    });

    test('come nel design: massa con 4 allenamenti a settimana', () {
      final t = computeTargets(alex, trainingDays: 4);
      expect(t.activity, ActivityLevel.moderate);
      expect(t.kcal, closeTo(1717.5 * 1.55 + 300, 0.01));
      expect(t.kcal.round(), inInclusiveRange(2900, 3000));
      expect(t.protein, closeTo(72 * 1.8, 0.01));
      expect(t.fat, closeTo(t.kcal * 0.25 / 9, 0.01));
      expect(t.protein * 4 + t.fat * 9 + t.carbs * 4, closeTo(t.kcal, 0.01));
      expect(t.sugarMax, closeTo(t.kcal * 0.1 / 4, 0.01));
      expect(t.fatPercent, 25);
      expect(t.raisedToBmr, isFalse);
    });

    test('attività dai giorni scelti o scelta a mano', () {
      expect(activityFromTrainingDays(0), ActivityLevel.sedentary);
      expect(activityFromTrainingDays(2), ActivityLevel.light);
      expect(activityFromTrainingDays(5), ActivityLevel.moderate);
      expect(activityFromTrainingDays(7), ActivityLevel.high);
      final manual = alex.copyWith(activity: ActivityLevel.high);
      expect(
        computeTargets(manual, trainingDays: 1).activity,
        ActivityLevel.high,
      );
      expect(manual.copyWith(automaticActivity: true).activity, isNull);
    });

    test('obiettivi: definizione −400, mantenimento 0, massa +300', () {
      double kcal(Goal g) =>
          computeTargets(alex.copyWith(goal: g), trainingDays: 4).kcal;
      expect(kcal(Goal.maintain) - kcal(Goal.cut), closeTo(400, 0.01));
      expect(kcal(Goal.bulk) - kcal(Goal.maintain), closeTo(300, 0.01));
    });

    test('mai sotto il metabolismo basale', () {
      const tiny = BodyProfile(
        sex: Sex.female,
        age: 60,
        weightKg: 45,
        heightCm: 150,
        goal: Goal.cut,
        activity: ActivityLevel.sedentary,
      );
      final t = computeTargets(tiny, trainingDays: 0);
      expect(t.kcal, t.bmr);
      expect(t.raisedToBmr, isTrue);
    });

    test('proteine tra 1,6 e 2,2 g/kg', () {
      expect(
        computeTargets(alex.copyWith(proteinPerKg: 3), trainingDays: 4).protein,
        closeTo(72 * 2.2, 0.01),
      );
      expect(
        computeTargets(alex.copyWith(proteinPerKg: 1), trainingDays: 4).protein,
        closeTo(72 * 1.6, 0.01),
      );
    });

    test('si salva e si rilegge', () {
      final b = alex.copyWith(
        diet: Diet.vegetarian,
        allergies: {Allergen.nuts, Allergen.gluten},
        activity: ActivityLevel.light,
      );
      final back = BodyProfile.fromJson(b.toJson());
      expect(back.toJson(), b.toJson());
    });
  });

  group('Pasti', () {
    test('pasto per ora del giorno', () {
      expect(mealForTime(DateTime(2026, 1, 1, 8)), Meal.breakfast);
      expect(mealForTime(DateTime(2026, 1, 1, 13)), Meal.lunch);
      expect(mealForTime(DateTime(2026, 1, 1, 17)), Meal.snack);
      expect(mealForTime(DateTime(2026, 1, 1, 20)), Meal.dinner);
    });

    test('il prossimo pasto salta quelli già registrati', () {
      final noon = DateTime(2026, 1, 1, 12);
      expect(nextMeal(noon, {}), Meal.lunch);
      expect(nextMeal(noon, {Meal.lunch}), Meal.snack);
      expect(nextMeal(noon, {Meal.lunch, Meal.snack}), Meal.dinner);
      expect(
        nextMeal(DateTime(2026, 1, 1, 21), Meal.values.toSet()),
        Meal.dinner,
      );
    });

    test('valori per grammi e somma', () {
      const pasta = Nutrients(kcal: 353, protein: 13, carbs: 72, fat: 1.5);
      final portion = pasta.forGrams(80);
      expect(portion.kcal, closeTo(282.4, 0.01));
      expect((portion + portion).protein, closeTo(20.8, 0.01));
      expect(
        const Nutrients(protein: 28, carbs: 52, fat: 10, sugar: 18).macrosLabel,
        'P 28 g · C 52 g · G 10 g · zuccheri 18 g',
      );
    });
  });

  group('Alimenti e consigli', () {
    test('cerca senza accenti né maiuscole', () {
      expect(searchLocalFoods('POLLO').map((f) => f.name), ['Petto di pollo']);
      expect(
        searchLocalFoods('pasta integ').single.name,
        'Pasta integrale (cruda)',
      );
      expect(searchLocalFoods('').length, localFoods.length);
    });

    test('la dieta filtra gli alimenti', () {
      expect(dietAllows(Diet.vegan, Diet.vegetarian), isFalse);
      expect(dietAllows(Diet.vegetarian, Diet.vegan), isTrue);
      expect(dietAllows(Diet.omnivore, Diet.omnivore), isTrue);
    });

    test('3 piatti ordinati per proteine, senza superare le kcal', () {
      final r = recommendRecipes(
        meal: Meal.dinner,
        kcalLeft: 1530,
        proteinLeft: 58,
        diet: Diet.omnivore,
        allergies: const {},
      );
      expect(r, hasLength(3));
      expect(
        r.first.portion.protein,
        greaterThanOrEqualTo(r[1].portion.protein),
      );
      expect(r.first.name, 'Petto di pollo, riso e broccoli');
    });

    test('rispetta calorie rimaste, dieta e allergie', () {
      final r = recommendRecipes(
        meal: Meal.dinner,
        kcalLeft: 530,
        proteinLeft: 40,
        diet: Diet.vegetarian,
        allergies: const {Allergen.eggs},
      );
      for (final x in r) {
        expect(x.portion.kcal, lessThanOrEqualTo(530));
        expect(x.diet, isNot(Diet.omnivore));
        expect(x.allergens, isNot(contains(Allergen.eggs)));
      }
      expect(
        recommendRecipes(
          meal: Meal.dinner,
          kcalLeft: 100,
          proteinLeft: 40,
          diet: Diet.omnivore,
          allergies: const {},
        ),
        isEmpty,
      );
    });

    test('dopo l\'allenamento preferisce i piatti post-allenamento', () {
      final r = recommendRecipes(
        meal: Meal.snack,
        kcalLeft: 800,
        proteinLeft: 10,
        diet: Diet.omnivore,
        allergies: const {},
        trainedToday: true,
      );
      expect(r.first.tags, contains(tagPostWorkout));
    });

    test('un piatto diventa un alimento con valori per 100 g', () {
      final item = recipes.first.toFoodItem();
      expect(
        item.per100.forGrams(recipes.first.grams).kcal,
        closeTo(recipes.first.portion.kcal, 0.01),
      );
    });
  });

  group('Open Food Facts', () {
    test('legge prodotto, marca, calorie da kJ e allergeni', () {
      final item = parseProduct({
        'code': '8001',
        'product_name_it': 'Gallette di riso',
        'brands': 'Marca, Altra',
        'nutriments': {
          'energy_100g': 1600,
          'proteins_100g': '7,5',
          'carbohydrates_100g': 80,
          'fat_100g': 3,
          'sugars_100g': 0.5,
        },
        'allergens_tags': ['en:gluten', 'en:sconosciuto'],
      })!;
      expect(item.displayName, 'Gallette di riso · Marca');
      expect(item.per100.kcal, closeTo(1600 / 4.184, 0.01));
      expect(item.per100.protein, 7.5);
      expect(item.allergens, {Allergen.gluten});
      expect(parseProduct({'product_name': 'Senza valori'}), isNull);
      expect(
        parseProduct({
          'nutriments': {'energy-kcal_100g': 100},
        }),
        isNull,
      );
    });

    test('ricerca e codice a barre con un server finto', () async {
      final client = MockClient((request) async {
        if (request.url.path.contains('/api/v2/product/123')) {
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'Latte',
                'nutriments': {'energy-kcal_100g': 46},
              },
            }),
            200,
          );
        }
        if (request.url.path.contains('/api/v2/product/')) {
          return http.Response('{"status":0}', 404);
        }
        expect(request.headers['User-Agent'], contains('Ritmo'));
        expect(request.url.queryParameters['search_terms'], 'pane');
        return http.Response(
          jsonEncode({
            'products': [
              {
                'product_name': 'Pane',
                'nutriments': {'energy-kcal_100g': 270},
              },
              {'product_name': 'Senza calorie'},
            ],
          }),
          200,
        );
      });
      final off = OpenFoodFacts(client: client);
      expect((await off.search('pane')).single.name, 'Pane');
      expect(await off.search('p'), isEmpty);
      expect((await off.byBarcode('123'))!.barcode, '123');
      expect(await off.byBarcode('999'), isNull);
    });

    test('offline: messaggio comprensibile', () async {
      final off = OpenFoodFacts(
        client: MockClient((_) => throw http.ClientException('offline')),
      );
      expect(
        () => off.search('pane'),
        throwsA(
          isA<FoodCatalogException>().having(
            (e) => e.message,
            'message',
            contains('offline'),
          ),
        ),
      );
    });
  });

  group('Diario', () {
    test('aggiunge, ripete il pasto di ieri, preferiti', () async {
      final db = memoryDatabase();
      final repo = FoodRepository(db);
      const today = LocalDate(2026, 10, 13);
      final now = DateTime(2026, 10, 13, 8);
      final pasta = localFoods.first;
      await repo.addEntry(
        date: today.addDays(-1),
        meal: Meal.lunch,
        food: pasta,
        grams: 80,
        now: now,
      );
      expect(await repo.repeatYesterday(Meal.lunch, today, now), 1);
      final entries = await repo.watchDay(today).first;
      expect(entries.single.meal, Meal.lunch);
      expect(entries.single.nutrients.kcal, closeTo(282.4, 0.01));

      await repo.deleteEntry(entries.single.id);
      expect(await repo.watchDay(today).first, isEmpty);

      await repo.addFavorite(pasta, 90);
      await repo.addFavorite(pasta, 100);
      final favorites = await repo.watchFavorites().first;
      expect(favorites.single.defaultGrams, 100);
      await repo.removeFavorite(pasta.name);
      expect(await repo.watchFavorites().first, isEmpty);
      await db.close();
    });
  });
}
