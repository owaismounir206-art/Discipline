// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/features/food/data/food_repository.dart';
import 'package:discipline/features/food/domain/foods.dart';
import 'package:discipline/features/food/domain/homemade.dart';
import 'package:discipline/features/food/domain/nutrition.dart';

import 'package:discipline/core/router/routes.dart';
import 'package:discipline/core/widgets/motion_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

const _pasta = FoodItem(
  name: 'Pasta',
  per100: Nutrients(kcal: 350, protein: 12, carbs: 72, fat: 1.5),
  allergens: {Allergen.gluten},
  diet: Diet.vegan,
);
const _sugo = FoodItem(
  name: 'Sugo al pomodoro',
  per100: Nutrients(kcal: 50, protein: 1.5, carbs: 8, fat: 1.5),
  diet: Diet.vegan,
);
const _parmigiano = FoodItem(
  name: 'Parmigiano',
  per100: Nutrients(kcal: 390, protein: 33, carbs: 0, fat: 28),
  allergens: {Allergen.lactose},
  diet: Diet.vegetarian,
);

void main() {
  test('calorie per porzione e per 100 g', () {
    const r = HomemadeRecipe(
      name: 'Pasta al sugo',
      ingredients: [
        Ingredient(_pasta, 320),
        Ingredient(_sugo, 300),
        Ingredient(_parmigiano, 40),
      ],
      portions: 4,
    );
    // 1120 + 150 + 156 = 1426 kcal in 660 g.
    expect(r.total.kcal, closeTo(1426, 0.01));
    expect(r.perPortion.kcal, closeTo(356.5, 0.01));
    expect(r.portionGrams, 165);
    // Pasta cotta: pesa di più, quindi meno calorie per 100 g.
    final cooked = r.copyWith(cookedGrams: 1200);
    expect(cooked.per100.kcal, closeTo(1426 / 12, 0.01));
    expect(cooked.portionGrams, 300);
    final food = r.toFood();
    expect(food.allergens, {Allergen.gluten, Allergen.lactose});
    expect(food.diet, Diet.vegetarian);
    expect(food.source, FoodSource.homemade);
  });

  test('salvata, rinominata e cancellata (anche dai preferiti)', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final repo = FoodRepository(db);
    const r = HomemadeRecipe(
      name: 'Pasta al sugo',
      ingredients: [Ingredient(_pasta, 320), Ingredient(_sugo, 300)],
      portions: 4,
    );
    await repo.saveHomemade(r);
    expect((await repo.watchHomemade().first).single.ingredients, hasLength(2));
    expect((await repo.watchFavorites().first).single.name, 'Pasta al sugo');

    await repo.saveHomemade(
      r.copyWith(name: 'Pasta della domenica'),
      previousName: 'Pasta al sugo',
    );
    expect(
      (await repo.watchHomemade().first).single.name,
      'Pasta della domenica',
    );
    expect((await repo.watchFavorites().first).map((f) => f.name), [
      'Pasta della domenica',
    ]);

    await repo.deleteHomemade('Pasta della domenica');
    expect(await repo.watchHomemade().first, isEmpty);
    expect(await repo.watchFavorites().first, isEmpty);
  });

  test('le ricette passano dal backup', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    await FoodRepository(db).saveHomemade(
      const HomemadeRecipe(
        name: 'Torta',
        ingredients: [Ingredient(_parmigiano, 10)],
        cookedGrams: 50,
      ),
    );
    final data = await db.exportAll();
    final other = memoryDatabase();
    addTearDown(other.close);
    await other.importAll(data);
    final back = (await FoodRepository(other).watchHomemade().first).single;
    expect(back.cookedGrams, 50);
    expect(back.ingredients.single.food.allergens, {Allergen.lactose});
  });

  testWidgets('crea una ricetta dagli ingredienti e la ritrova', (
    tester,
  ) async {
    final db = memoryDatabase();
    await tester.runAsync(() => seedProfile(db));
    await pumpDiscipline(tester, db);
    final context = tester.element(find.byType(DisciplineNavigationBar));
    unawaited(GoRouter.of(context).push(Routes.homemade));
    await settle(tester);

    await tester.enterText(find.byType(TextField).first, 'Pasta e piselli');
    await tester.tap(find.text('Aggiungi ingrediente'));
    await settle(tester);
    expect(find.text('Scegli un ingrediente'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'pasta di semola');
    await settle(tester);
    await tester.tap(find.text('Pasta di semola (cruda)'));
    await settle(tester);
    // Grammi dell'ingrediente.
    await tester.enterText(find.byType(TextField).last, '200');
    await tester.tap(find.text('Ok'));
    await settle(tester);
    expect(find.text('200 g · 706 kcal'), findsOneWidget);

    await tester.ensureVisible(find.text('Salva ricetta'));
    await settle(tester);
    // 2 porzioni.
    await tester.tap(find.byIcon(Icons.add).last);
    await settle(tester);
    expect(find.text('353 kcal'), findsOneWidget);
    await tester.tap(find.text('Salva ricetta'));
    await settle(tester);

    final saved = await tester.runAsync(
      () => FoodRepository(db).watchHomemade().first,
    );
    expect(saved!.single.name, 'Pasta e piselli');
    expect(saved.single.portions, 2);
    await disposeDiscipline(tester, db);
  });
}
