// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/core/widgets/motion_widgets.dart';
import 'package:discipline/core/data/database.dart';

import 'helpers.dart';

/// Durante l'allenamento c'è un timer ogni secondo: niente pumpAndSettle.
Future<void> step(WidgetTester tester, [int times = 3]) async {
  for (var i = 0; i < times; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> startWorkout(WidgetTester tester) async {
  final button = find.text('Inizia allenamento');
  await tester.scrollUntilVisible(button, 200);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
}

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());

  testWidgets('serie, recupero e riepilogo vengono salvati', (tester) async {
    await tester.runAsync(() => seedProfile(db));
    await pumpDiscipline(tester, db);

    await startWorkout(tester);
    await step(tester, 6);

    expect(find.text('Tirata · Intermedio'), findsOneWidget);
    expect(find.textContaining('Esercizio 1 di'), findsOneWidget);
    expect(find.text('Vai!'), findsOneWidget);
    expect(find.text('Più facile'), findsOneWidget);

    // Prima serie: parte il recupero.
    await tester.tap(find.text('Serie completata'));
    await step(tester);
    expect(find.text('Recupero'), findsOneWidget);
    expect(find.text('−15 s'), findsOneWidget);

    // Il recupero scende col tempo e si può saltare.
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.text('Salta'));
    await step(tester);
    expect(find.text('Vai!'), findsOneWidget);

    final sets = await tester.runAsync(() => db.select(db.setLogs).get());
    expect(sets, hasLength(1));
    final sessions = await tester.runAsync(
      () => db.select(db.workoutSessions).get(),
    );
    expect(sessions!.single.completedSets, 1);
    expect(sessions.single.date, '2026-10-13');

    // Termina: con poche serie il giorno non conta per la streak.
    await tester.tap(find.byTooltip('Altre opzioni'));
    await step(tester);
    await tester.tap(find.text('Termina allenamento'));
    await step(tester);
    await tester.tap(find.text('Termina'));
    await step(tester, 6);
    expect(find.text('Allenamento salvato'), findsOneWidget);
    expect(find.textContaining('serve almeno l\'80%'), findsOneWidget);

    await tester.tap(find.text('Fine'));
    await step(tester, 6);
    expect(find.byType(DisciplineNavigationBar), findsOneWidget);
    await disposeDiscipline(tester, db);
  });

  testWidgets('cambiare variante aggiorna la catena', (tester) async {
    await tester.runAsync(() => seedProfile(db));
    await pumpDiscipline(tester, db);
    await startWorkout(tester);
    await step(tester, 6);

    expect(find.text('Trazioni'), findsOneWidget);
    await tester.tap(find.text('Più difficile'));
    await step(tester);
    expect(find.text('Trazioni larghe'), findsOneWidget);

    final chains = await tester.runAsync(() => db.readJson('chains'));
    expect((chains! as Map)['pull']['position'], 4);

    await tester.tap(find.byTooltip('Indietro'));
    await step(tester, 6);
    await disposeDiscipline(tester, db);
  });
}
