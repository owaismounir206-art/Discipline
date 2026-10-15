// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/core/data/database.dart';
import 'package:discipline/core/utils/local_date.dart';
import 'package:discipline/core/widgets/motion_widgets.dart';
import 'package:discipline/features/food/data/food_repository.dart';
import 'package:discipline/features/food/domain/foods.dart';
import 'package:discipline/features/food/domain/nutrition.dart';
import 'package:discipline/features/food/presentation/week_and_water.dart';
import 'package:discipline/features/rewards/data/rewards_repository.dart';
import 'package:discipline/features/rewards/domain/rewards.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());

  test('il peso più recente aggiorna i dati del corpo', () async {
    final repo = FoodRepository(db);
    await repo.saveBody(
      const BodyProfile(
        sex: Sex.male,
        age: 30,
        heightCm: 180,
        weightKg: 80,
        goal: Goal.maintain,
      ),
    );
    await repo.setWeight(const LocalDate(2026, 10, 10), 79.46);
    await repo.setWeight(const LocalDate(2026, 10, 1), 81);
    final weights = await repo.watchWeights().first;
    expect(weights.keys.first, const LocalDate(2026, 10, 1));
    expect(weights[const LocalDate(2026, 10, 10)], 79.5);
    // Una misura più vecchia non cambia il peso attuale.
    expect((await repo.watchBody().first)!.weightKg, 79.5);
    await repo.removeWeight(const LocalDate(2026, 10, 1));
    expect(await repo.watchWeights().first, hasLength(1));
    await db.close();
  });

  test('un prodotto creato dallo scanner conserva il codice a barre', () async {
    final repo = FoodRepository(db);
    await repo.addFavorite(
      const FoodItem(
        name: 'Barretta',
        source: FoodSource.custom,
        barcode: '8001234567890',
        per100: Nutrients(kcal: 400, protein: 20, carbs: 50, fat: 12),
      ),
      100,
    );
    final saved = await repo.watchFavorites().first;
    expect(saved.single.barcode, '8001234567890');
    await db.close();
  });

  test('litri d\'acqua leggibili', () {
    expect(litersText(10000), '10');
    expect(litersText(2000), '2');
    expect(litersText(2500), '2,5');
    expect(litersText(1250), '1,25');
  });

  test('due prodotti diversi con lo stesso nome restano entrambi', () async {
    final repo = FoodRepository(db);
    FoodItem yogurt(String code, double kcal) => FoodItem(
      name: 'Yogurt',
      source: FoodSource.custom,
      barcode: code,
      per100: Nutrients(kcal: kcal, protein: 4, carbs: 5, fat: 3),
    );
    await repo.addFavorite(yogurt('111', 60), 125);
    await repo.addFavorite(yogurt('222', 90), 125);
    // Lo stesso prodotto salvato di nuovo si aggiorna, non si duplica.
    await repo.addFavorite(yogurt('222', 95), 125);
    final saved = await repo.watchFavorites().first;
    expect(saved.map((f) => f.barcode).toSet(), {'111', '222'});
    expect(saved.firstWhere((f) => f.barcode == '222').per100.kcal, 95);
    await db.close();
  });

  testWidgets('Progressi: calendario e diario del peso', (tester) async {
    await tester.runAsync(() => seedHistory(db));
    await pumpDiscipline(tester, db);
    await tester.tap(
      find.descendant(
        of: find.byType(DisciplineNavigationBar),
        matching: find.text('Progressi'),
      ),
    );
    await settle(tester);

    await tester.scrollUntilVisible(find.text('Calendario'), 300);
    expect(find.textContaining('allenamenti in 16 settimane'), findsOneWidget);
    expect(find.textContaining('0 allenamenti'), findsNothing);

    final weigh = find.text('Pesati');
    await tester.scrollUntilVisible(weigh, 200);
    await tester.ensureVisible(weigh);
    await settle(tester);
    await tester.tap(weigh);
    await settle(tester);
    await tester.tap(find.byTooltip('Più 100 grammi'));
    await tester.tap(find.text('Salva'));
    await settle(tester);
    expect(find.text('70,1 kg'), findsOneWidget);
    expect(find.text('Cambia il peso di oggi'), findsOneWidget);
    await disposeDiscipline(tester, db);
  });

  testWidgets('salire di grado fa partire la festa', (tester) async {
    await tester.runAsync(() => seedProfile(db));
    await pumpDiscipline(tester, db);
    await tester.runAsync(
      () =>
          RewardsRepository(db)
              .award(PointKind.workout, Rank.steady.from, at: testNow),
    );
    await settle(tester);
    expect(find.text('NUOVO GRADO'), findsOneWidget);
    expect(find.text(Rank.steady.label), findsWidgets);
    await tester.tap(find.text('Continua'));
    await settle(tester);
    expect(find.text('NUOVO GRADO'), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    await disposeDiscipline(tester, db);
  });
}
