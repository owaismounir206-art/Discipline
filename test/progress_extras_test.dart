// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/core/data/database.dart';
import 'package:discipline/core/utils/local_date.dart';
import 'package:discipline/core/widgets/motion_widgets.dart';
import 'package:discipline/features/food/data/food_repository.dart';
import 'package:discipline/features/food/domain/nutrition.dart';
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
