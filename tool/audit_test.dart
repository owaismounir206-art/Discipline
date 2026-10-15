// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

// Revisione grafica: ogni schermata a tutta altezza (tutto lo scorrimento)
// in build/audit/. Non va nel repository.
//   flutter test --update-goldens tool/audit_test.dart

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:discipline/app.dart';
import 'package:discipline/core/data/database.dart';
import 'package:discipline/core/router/routes.dart';
import 'package:discipline/core/widgets/motion_widgets.dart';
import 'package:discipline/features/rewards/data/rewards_repository.dart';
import 'package:discipline/features/rewards/domain/rewards.dart';

import '../test/helpers.dart';

Future<void> loadFonts() async {
  final figtree = FontLoader('Figtree');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    figtree.addFont(rootBundle.load('assets/fonts/Figtree-$weight.ttf'));
  }
  await figtree.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<void> wait(WidgetTester tester, [int times = 6]) async {
  for (var i = 0; i < times; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> shoot(String name) => expectLater(
  find.byType(DisciplineApp),
  matchesGoldenFile('../build/audit/$name.png'),
);

void main() {
  setUpAll(loadFonts);

  Future<AppDatabase> open(WidgetTester tester, double height) async {
    final db = memoryDatabase();
    await tester.runAsync(() async {
      await seedHistory(db);
      await seedFood(db, now: DateTime(2026, 10, 13, 13));
      await RewardsRepository(db)
          .award(PointKind.workout, 700, at: testNow, ref: 'x');
    });
    await pumpDiscipline(tester, db, now: DateTime(2026, 10, 13, 13));
    tester.view
      ..physicalSize = Size(1170, height * 3)
      ..devicePixelRatio = 3;
    await wait(tester);
    return db;
  }

  const tabs = {
    'Oggi': 2200.0,
    'Allenati': 2600.0,
    'Sfide': 2600.0,
    'Cibo': 2300.0,
    'Progressi': 2600.0,
  };
  for (final MapEntry(key: tab, value: height) in tabs.entries) {
    testWidgets('scheda $tab', (tester) async {
      final db = await open(tester, height);
      await tester.tap(
        find.descendant(
          of: find.byType(DisciplineNavigationBar),
          matching: find.text(tab),
        ),
      );
      await wait(tester);
      await shoot('scheda-${tab.toLowerCase()}');
      await disposeDiscipline(tester, db);
    });
  }

  const pages = {
    'impostazioni': (Routes.settings, 2400.0),
    'profilo': (Routes.athleteProfile, 2400.0),
    'cerca-cibo': (Routes.foodSearch, 2200.0),
    'ricetta': (Routes.homemade, 1300.0),
    'ai-cibo': (Routes.aiFood, 1000.0),
    'ai-impostazioni': (Routes.aiSettings, 1300.0),
    'timer': (Routes.timer, 1500.0),
    'esercizio': ('/esercizio/push_diamond', 1900.0),
    'consigli': (Routes.nutrition, 1900.0),
    'dati-corpo': (Routes.bodyData, 1900.0),
  };
  for (final MapEntry(key: name, value: (route, height)) in pages.entries) {
    testWidgets('pagina $name', (tester) async {
      final db = await open(tester, height);
      unawaited(
        GoRouter.of(tester.element(find.byType(DisciplineNavigationBar)))
            .push(route),
      );
      await wait(tester);
      await shoot(name);
      await disposeDiscipline(tester, db);
    });
  }
}
