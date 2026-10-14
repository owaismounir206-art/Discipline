// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

// Genera gli screenshot del README in docs/screenshots/.
//
//   flutter test --update-goldens tool/screenshots_test.dart

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:discipline/core/widgets/motion_widgets.dart';
import 'package:discipline/app.dart';
import 'package:discipline/core/data/database.dart';
import 'package:discipline/core/router/routes.dart';
import 'package:discipline/core/utils/local_date.dart';
import 'package:discipline/features/challenge/domain/friend_code.dart';
import 'package:discipline/features/challenge/domain/timed.dart';
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

/// Attende il database (I/O reale) e le animazioni, senza bloccarsi sui
/// timer dell'allenamento.
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
  matchesGoldenFile('../docs/screenshots/$name.png'),
);

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(DisciplineNavigationBar),
      matching: find.text(label),
    ),
  );
  await wait(tester);
}

void main() {
  setUpAll(loadFonts);

  late AppDatabase db;
  setUp(() async {
    db = memoryDatabase();
  });

  testWidgets('oggi', (tester) async {
    await tester.runAsync(() => seedHistory(db));
    await pumpDiscipline(tester, db);
    await wait(tester);
    await shoot('oggi');
    await disposeDiscipline(tester, db);
  });

  testWidgets('profilo atleta', (tester) async {
    await tester.runAsync(() => seedHistory(db));
    await pumpDiscipline(tester, db);
    await tester.tap(find.byTooltip('Profilo e impostazioni'));
    await wait(tester);
    await tester.tap(find.text('Profilo atleta'));
    await wait(tester);
    await shoot('profilo');
    await disposeDiscipline(tester, db);
  });

  testWidgets('allenamento', (tester) async {
    await tester.runAsync(() => seedHistory(db));
    await pumpDiscipline(tester, db);
    final start = find.text('Inizia allenamento');
    await tester.scrollUntilVisible(start, 200);
    await tester.ensureVisible(start);
    await wait(tester);
    await tester.tap(start);
    await wait(tester);
    await tester.tap(find.text('Serie completata'));
    await wait(tester);
    await tester.pump(const Duration(seconds: 22));
    await wait(tester, 2);
    await shoot('allenamento');
    await tester.tap(find.byTooltip('Indietro'));
    await wait(tester);
    await tester.tap(find.text('Termina'));
    await wait(tester);
    await disposeDiscipline(tester, db);
  });

  testWidgets('allenati', (tester) async {
    await tester.runAsync(() => seedHistory(db));
    await pumpDiscipline(tester, db);
    await openTab(tester, 'Allenati');
    await shoot('allenati');
    await disposeDiscipline(tester, db);
  });

  testWidgets('progressi', (tester) async {
    await tester.runAsync(() => seedHistory(db));
    await pumpDiscipline(tester, db);
    await openTab(tester, 'Progressi');
    await shoot('progressi');
    await disposeDiscipline(tester, db);
  });

  testWidgets('cibo', (tester) async {
    final evening = DateTime(2026, 10, 13, 19);
    await tester.runAsync(() => seedHistory(db));
    await tester.runAsync(() => seedFood(db, now: evening));
    await pumpDiscipline(tester, db, now: evening);
    await openTab(tester, 'Cibo');
    await shoot('cibo');
    await tester.tap(find.text('Cosa mangio a cena?'));
    await wait(tester);
    await shoot('consigli');
    await disposeDiscipline(tester, db);
  });

  testWidgets('sfide', (tester) async {
    await tester.runAsync(() async {
      await seedHistory(db);
      final repo = RewardsRepository(db);
      await repo.award(PointKind.workout, 1240, at: testNow, ref: 'storico');
      await repo.addChallengeEntry(
        'giorno-${LocalDate.fromDateTime(testNow).key}',
        20,
        verified: true,
        at: testNow,
      );
    });
    await pumpDiscipline(tester, db);
    await openTab(tester, 'Sfide');
    await shoot('sfide');
    await disposeDiscipline(tester, db);
  });

  testWidgets('sfida a tempo', (tester) async {
    var now = testNow;
    await tester.runAsync(() => seedHistory(db));
    await pumpDiscipline(tester, db, clock: () => now);
    final context = tester.element(find.byType(Scaffold).first);
    final code = encodeFriendChallenge(
      const FriendChallenge(
        mode: TimedMode.minute,
        score: 23,
        name: 'Luca',
        date: LocalDate(2026, 10, 12),
      ),
    );
    unawaited(GoRouter.of(context).push(Routes.timed('minute', code: code)));
    await wait(tester);
    await tester.tap(find.text('Via!'));
    now = now.add(const Duration(seconds: 3));
    await wait(tester, 2);
    for (var i = 0; i < 27; i++) {
      await tester.tap(find.text('+1 push-up'));
      await tester.pump();
    }
    now = now.add(const Duration(seconds: 26));
    await wait(tester, 2);
    await shoot('sfida-tempo');
    await disposeDiscipline(tester, db);
  });
}
