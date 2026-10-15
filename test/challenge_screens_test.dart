// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:discipline/core/widgets/motion_widgets.dart';
import 'package:discipline/core/router/routes.dart';
import 'package:discipline/core/utils/local_date.dart';
import 'package:discipline/features/challenge/domain/friend_code.dart';
import 'package:discipline/features/challenge/domain/timed.dart';
import 'package:discipline/features/rewards/data/rewards_repository.dart';
import 'package:discipline/features/rewards/domain/rewards.dart';
import 'package:discipline/features/settings/backup.dart';

import 'helpers.dart';

/// Orologio che i test possono far avanzare.
class TestClock {
  DateTime now = testNow;

  DateTime call() => now;

  void advance(Duration d) => now = now.add(d);
}

class FakeBackupFiles implements BackupFiles {
  String? exported;
  String? exportedName;

  @override
  Future<void> export(String fileName, String content) async {
    exportedName = fileName;
    exported = content;
  }

  @override
  Future<String?> pick() async => exported;
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(DisciplineNavigationBar),
      matching: find.text(label),
    ),
  );
  await settle(tester);
}

/// Come settle, per le schermate con un timer sempre attivo.
Future<void> step(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> elapse(WidgetTester tester, TestClock clock, Duration d) async {
  clock.advance(d);
  await step(tester);
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
}

Future<void> go(WidgetTester tester, String location) async {
  final context = tester.element(find.byType(Scaffold).first);
  unawaited(GoRouter.of(context).push(location));
  await step(tester);
}

void main() {
  testWidgets('sfida del giorno: aggiungi, riscatta i punti', (tester) async {
    final db = memoryDatabase();
    await seedProfile(db);
    await pumpDiscipline(tester, db);
    await openTab(tester, 'Sfide');

    expect(find.text('Recluta'), findsOneWidget);
    expect(find.text('Sfida del giorno'), findsOneWidget);
    expect(find.text('Sfida della settimana'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Aggiungi').first);
    await settle(tester);
    expect(find.text('Quanti ne hai fatti?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Aggiungi'));
    await settle(tester);

    final claim = find.widgetWithText(FilledButton, 'Riscatta +40');
    expect(claim, findsOneWidget);
    await tester.tap(claim);
    await settle(tester);
    // Festa con i coriandoli.
    expect(find.text('SFIDA COMPLETATA'), findsOneWidget);
    expect(find.text('+40 punti'), findsOneWidget);
    await tester.tap(find.text('Continua'));
    await settle(tester);
    expect(find.text('Completata'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    final points = await tester.runAsync(() => RewardsRepository(db).points());
    expect(balanceOf(points!), 40);
    await disposeDiscipline(tester, db);
  });

  testWidgets('un minuto da solo: record e punti', (tester) async {
    final db = memoryDatabase();
    await seedProfile(db);
    final clock = TestClock();
    await pumpDiscipline(tester, db, clock: clock.call);
    await openTab(tester, 'Sfide');

    final card = find.text('Un minuto');
    await scrollTo(tester, card);
    await tester.tap(card);
    await step(tester);
    expect(find.textContaining('Mettiti in posizione'), findsOneWidget);

    await tester.tap(find.text('Via!'));
    await step(tester);
    expect(find.text('3'), findsOneWidget);
    await elapse(tester, clock, const Duration(seconds: 3));
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('+1 push-up'));
      await tester.pump();
    }
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.text('Ho finito'));
    await step(tester);

    expect(find.text('Primo record!'), findsOneWidget);
    expect(find.text('3 push-up'), findsOneWidget);
    expect(find.text('Contati a mano'), findsOneWidget);
    expect(find.text('+3 punti'), findsOneWidget);
    expect(find.text('Sfida un amico a batterti'), findsOneWidget);

    await tester.tap(find.text('Chiudi'));
    await step(tester);
    expect(find.text('Record: 3 push-up'), findsOneWidget);
    await disposeDiscipline(tester, db);
  });

  testWidgets('codice di un amico: accetta, battilo, rispondi', (tester) async {
    final db = memoryDatabase();
    await seedProfile(db);
    final clock = TestClock();
    final shared = <String>[];
    await pumpDiscipline(
      tester,
      db,
      clock: clock.call,
      extra: [shareOverride(shared)],
    );
    await go(tester, Routes.friendChallenge);

    await tester.enterText(find.byType(TextField), 'ABC');
    await tester.pump();
    expect(find.textContaining('Codice non valido'), findsOneWidget);

    final code = encodeFriendChallenge(
      const FriendChallenge(
        mode: TimedMode.minute,
        score: 2,
        name: 'Luca',
        date: LocalDate(2026, 10, 12),
      ),
    );
    await tester.enterText(find.byType(TextField), code);
    await tester.pump();
    expect(find.text('Luca ti sfida'), findsOneWidget);
    expect(find.text('Un minuto: 2 push-up'), findsOneWidget);
    await tester.tap(find.text('Accetta la sfida'));
    await step(tester);

    expect(find.text('Luca: 2 push-up. Riesci a fare meglio?'), findsOneWidget);
    await tester.tap(find.text('Via!'));
    await elapse(tester, clock, const Duration(seconds: 3));
    expect(find.text('Da battere'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('+1 push-up'));
      await tester.pump();
    }
    await elapse(tester, clock, const Duration(seconds: 61));

    expect(find.text('Hai battuto Luca!'), findsOneWidget);
    // Prima la festa, poi il risultato.
    expect(find.text('SFIDA VINTA'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Continua'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('SFIDA VINTA'), findsNothing);
    expect(find.text('+23 punti'), findsOneWidget);
    await tester.tap(find.text('Rispondi a Luca'));
    await tester.pump();
    expect(shared.single, startsWith('Ti ho battuto, Luca!'));
    await disposeDiscipline(tester, db);
  });

  testWidgets('negozio: giorno jolly e colori', (tester) async {
    final db = memoryDatabase();
    await seedProfile(db);
    await tester.runAsync(
      () => RewardsRepository(db).award(PointKind.challenge, 500, at: testNow),
    );
    await pumpDiscipline(tester, db);
    await openTab(tester, 'Sfide');

    final buy = find.text('Compra · 150 punti');
    await scrollTo(tester, buy);
    await tester.tap(buy);
    await settle(tester);
    expect(find.text('Giorno jolly comprato'), findsOneWidget);
    expect(find.textContaining('Ne hai 1 su 2'), findsOneWidget);

    final ocean = find.text('Oceano · 300');
    await scrollTo(tester, ocean);
    await tester.tap(ocean);
    await settle(tester);
    final theme = await tester.runAsync(() => db.readJson('theme'));
    expect((theme! as Map)['palette'], 'ocean');
    expect(find.text('Oceano'), findsOneWidget);
    // 500 − 150 − 300.
    final points = await tester.runAsync(() => RewardsRepository(db).points());
    expect(balanceOf(points!), 50);
    await disposeDiscipline(tester, db);
  });

  testWidgets('backup su file: esporta e reimporta', (tester) async {
    final db = memoryDatabase();
    await seedProfile(db);
    final files = FakeBackupFiles();
    await pumpDiscipline(
      tester,
      db,
      extra: [backupFilesProvider.overrideWithValue(files)],
    );
    await tester.tap(find.byTooltip('Profilo e impostazioni'));
    await settle(tester);

    final export = find.text('Esporta in un file');
    await tester.scrollUntilVisible(export, 200);
    await tester.ensureVisible(export);
    await tester.pumpAndSettle();
    await tester.tap(export);
    await settle(tester);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await settle(tester);
    expect(files.exportedName, 'discipline-backup-2026-10-13.json');
    expect(files.exported, contains('"app": "discipline"'));

    await tester.ensureVisible(find.text('Importa da un file'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Importa da un file'));
    await settle(tester);
    await tester.tap(find.text('Importa'));
    await settle(tester);
    expect(find.text('Dati importati'), findsOneWidget);
    await disposeDiscipline(tester, db);
  });
}
