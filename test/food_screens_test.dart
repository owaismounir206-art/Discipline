// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ritmo/core/data/database.dart';

import 'helpers.dart';

Future<void> openFood(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Cibo'),
    ),
  );
  await settle(tester);
}

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());

  testWidgets('senza dati chiede peso e obiettivo', (tester) async {
    await tester.runAsync(() => seedProfile(db));
    await pumpRitmo(tester, db);
    await openFood(tester);
    expect(find.textContaining('Inserisci peso, altezza'), findsOneWidget);
    await tester.tap(find.textContaining('Inserisci peso, altezza'));
    await settle(tester);
    expect(find.text('I tuoi dati'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Salva'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Salva'));
    await settle(tester);
    expect(await tester.runAsync(() => db.readJson('body')), isNotNull);
    expect(find.text('rimanenti'), findsOneWidget);
    await disposeRitmo(tester, db);
  });

  testWidgets('diario: cerca, sceglie i grammi e aggiunge', (tester) async {
    await tester.runAsync(() => seedProfile(db));
    await tester.runAsync(() => seedFood(db));
    await pumpRitmo(tester, db, now: DateTime(2026, 10, 13, 20));
    await openFood(tester);

    expect(find.text('Colazione'), findsOneWidget);
    expect(find.text('Pranzo'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Aggiungi la cena'), 200);
    await tester.ensureVisible(find.text('Aggiungi la cena'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aggiungi la cena'));
    await settle(tester);
    expect(find.text('Aggiungi alla cena'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'yogurt');
    await tester.pump(const Duration(milliseconds: 600));
    await settle(tester);
    expect(find.text('Yogurt proteico (yogurt) · Marca'), findsOneWidget);
    expect(find.text('Yogurt greco 0%'), findsOneWidget);

    await tester.tap(find.text('Yogurt greco 0%'));
    await settle(tester);
    expect(find.text('Grammi'), findsOneWidget);
    await tester.tap(find.text('Aggiungi alla cena').last);
    await settle(tester);

    expect(find.text('Cena'), findsOneWidget);
    final rows = await tester.runAsync(() => db.select(db.foodEntries).get());
    expect(rows!.where((r) => r.meal == 'dinner'), hasLength(1));
    await disposeRitmo(tester, db);
  });

  testWidgets('consigli: fabbisogno, 3 piatti e nota', (tester) async {
    await tester.runAsync(() => seedProfile(db));
    await tester.runAsync(() => seedFood(db));
    await pumpRitmo(tester, db, now: DateTime(2026, 10, 13, 20));
    await openFood(tester);
    await tester.scrollUntilVisible(find.text('Cosa mangio a cena?'), 200);
    await tester.ensureVisible(find.text('Cosa mangio a cena?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cosa mangio a cena?'));
    await settle(tester);

    expect(find.text('Consigli per te'), findsOneWidget);
    expect(find.text('Massa muscolare'), findsOneWidget);
    expect(find.text('Per cena'), findsOneWidget);
    expect(find.text('Aggiungi'), findsWidgets);
    await tester.tap(find.text('Aggiungi').first);
    await settle(tester);
    expect(find.text('Aggiunto'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Non sostituiscono'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Non sostituiscono'), findsOneWidget);
    await disposeRitmo(tester, db);
  });
}
