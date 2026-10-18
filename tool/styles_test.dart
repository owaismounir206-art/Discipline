// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

// Revisione degli stili: le schermate principali in ogni stile, in
// build/styles/<stile>-<schermata>.png. Non va nel repository.
//   flutter test --update-goldens tool/styles_test.dart
//   (solo uno stile: --plain-name glass)

import 'dart:async';
import 'dart:io';

import 'package:discipline/app.dart';
import 'package:discipline/core/data/database.dart';
import 'package:discipline/core/router/routes.dart';
import 'package:discipline/core/theme/styles/style_catalog.dart';
import 'package:discipline/core/widgets/motion_widgets.dart';
import 'package:discipline/features/rewards/data/rewards_repository.dart';
import 'package:discipline/features/rewards/domain/rewards.dart';
import 'package:discipline/features/workout/domain/workout_plan.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../test/helpers.dart';

Future<void> loadFonts() async {
  final figtree = FontLoader('Figtree');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    figtree.addFont(rootBundle.load('assets/fonts/Figtree-$weight.ttf'));
  }
  await figtree.load();
  // I caratteri degli stili: una cartella per famiglia.
  for (final dir in Directory(
    'assets/fonts',
  ).listSync().whereType<Directory>()) {
    final family = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (family == 'licenses') continue;
    final loader = FontLoader(family);
    for (final file in dir.listSync().whereType<File>()) {
      loader.addFont(rootBundle.load(file.path));
    }
    await loader.load();
  }
  // Lo stile vetro usa il carattere del telefono: qui al suo posto Open Sans.
  final system = FontLoader('Roboto');
  for (final w in [400, 600, 700]) {
    system.addFont(rootBundle.load('assets/fonts/OpenSans/OpenSans-$w.ttf'));
  }
  await system.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<void> wait(WidgetTester tester, [int times = 6]) async {
  for (var i = 0; i < times; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }
}

void main() {
  setUpAll(loadFonts);

  Future<AppDatabase> open(
    WidgetTester tester,
    String style,
    double height,
  ) async {
    final db = memoryDatabase();
    await tester.runAsync(() async {
      await seedHistory(db);
      await seedFood(db, now: DateTime(2026, 10, 13, 13));
      await RewardsRepository(db)
          .award(PointKind.workout, 700, at: testNow, ref: 'x');
      await db.writeJson('theme', {'mode': 'system', 'style': style});
    });
    // Animazioni ferme: gli sfondi che si muovono non finirebbero mai.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpDiscipline(tester, db, now: DateTime(2026, 10, 13, 13));
    tester.view
      ..physicalSize = Size(1170, height * 3)
      ..devicePixelRatio = 3;
    await wait(tester);
    return db;
  }

  Future<void> shoot(String name) => expectLater(
    find.byType(DisciplineApp),
    matchesGoldenFile('../build/styles/$name.png'),
  );

  for (final style in appStyles) {
    final id = style.id.name;
    group(id, () {
      for (final (tab, height) in [
        ('Oggi', 1700.0),
        ('Allenati', 1700.0),
        ('Sfide', 1700.0),
        ('Cibo', 1700.0),
        ('Progressi', 1700.0),
      ]) {
        testWidgets('$id $tab', (tester) async {
          final db = await open(tester, id, height);
          await tester.tap(
            find.descendant(
              of: find.byType(DisciplineNavigationBar),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Semantics &&
                    w.properties.label == tab &&
                    w.properties.button == true,
              ),
            ),
          );
          await wait(tester);
          await shoot('$id-${tab.toLowerCase()}');
          await disposeDiscipline(tester, db);
        });
      }
      for (final (name, route, extra, height) in [
        ('impostazioni', Routes.settings, null, 1700.0),
        ('sessione', Routes.session, WorkoutTemplate.push, 900.0),
        ('timer', Routes.timer, null, 900.0),
      ]) {
        testWidgets('$id $name', (tester) async {
          final db = await open(tester, id, height);
          unawaited(
            GoRouter.of(tester.element(find.byType(DisciplineNavigationBar)))
                .push(route, extra: extra),
          );
          await wait(tester);
          await shoot('$id-$name');
          await disposeDiscipline(tester, db);
        });
      }
    });
  }
}
