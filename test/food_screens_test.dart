// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:discipline/core/widgets/motion_widgets.dart';
import 'package:discipline/core/data/database.dart';
import 'package:discipline/core/utils/local_date.dart';
import 'package:discipline/features/food/data/food_repository.dart';
import 'package:discipline/features/food/data/food_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'helpers.dart';

Future<void> openFood(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(DisciplineNavigationBar),
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
    await pumpDiscipline(tester, db);
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
    await disposeDiscipline(tester, db);
  });

  testWidgets('diario: cerca, sceglie i grammi e aggiunge', (tester) async {
    await tester.runAsync(() => seedProfile(db));
    await tester.runAsync(() => seedFood(db));
    await pumpDiscipline(tester, db, now: DateTime(2026, 10, 13, 20));
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
    await disposeDiscipline(tester, db);
  });

  testWidgets('consigli: fabbisogno, 3 piatti e nota', (tester) async {
    await tester.runAsync(() => seedProfile(db));
    await tester.runAsync(() => seedFood(db));
    await pumpDiscipline(tester, db, now: DateTime(2026, 10, 13, 20));
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
    await disposeDiscipline(tester, db);
  });

  testWidgets('giorni: torna a ieri, aggiungi e torna a oggi', (tester) async {
    await tester.runAsync(() => seedProfile(db));
    await tester.runAsync(() => seedFood(db));
    await pumpDiscipline(tester, db, now: DateTime(2026, 10, 13, 20));
    await openFood(tester);

    expect(find.text('Oggi, martedì 13 ottobre'), findsOneWidget);
    await tester.tap(find.byTooltip('Giorno prima'));
    await settle(tester);
    expect(find.text('Ieri, lunedì 12 ottobre'), findsOneWidget);
    expect(
      find.textContaining('Niente registrato in questo giorno'),
      findsOneWidget,
    );
    // Niente consigli per i giorni passati.
    expect(find.textContaining('Cosa mangio'), findsNothing);

    await tester.scrollUntilVisible(find.text('Aggiungi la colazione'), 200);
    await tester.ensureVisible(find.text('Aggiungi la colazione'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aggiungi la colazione'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'banana');
    await tester.pump(const Duration(milliseconds: 600));
    await settle(tester);
    await tester.tap(find.text('Banana').last);
    await settle(tester);
    await tester.tap(find.text('Aggiungi alla colazione').last);
    await settle(tester);

    final rows = await tester.runAsync(() => db.select(db.foodEntries).get());
    expect(rows!.where((r) => r.date == '2026-10-12').map((r) => r.name), [
      'Banana',
    ]);
    expect(find.text('Colazione'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Torna a oggi'), -200);
    await tester.tap(find.text('Torna a oggi'));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('Oggi, martedì 13 ottobre'),
      -200,
    );
    expect(find.text('Oggi, martedì 13 ottobre'), findsOneWidget);
    expect(find.text('Pranzo'), findsOneWidget);
    await disposeDiscipline(tester, db);
  });

  testWidgets('correggi i grammi di una voce', (tester) async {
    await tester.runAsync(() => seedProfile(db));
    await tester.runAsync(() => seedFood(db));
    await pumpDiscipline(tester, db, now: DateTime(2026, 10, 13, 20));
    await openFood(tester);

    final row = find.text('Banana, Burro di arachidi');
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await settle(tester);
    await tester.tap(find.text('Banana'));
    await settle(tester);
    await tester.tap(find.text('200 g'));
    await tester.pump();
    await tester.tap(find.text('Salva'));
    await settle(tester);

    final rows = await tester.runAsync(() => db.select(db.foodEntries).get());
    final banana = rows!.singleWhere((r) => r.name == 'Banana');
    expect(banana.grams, 200);
    expect(rows, hasLength(8));
    await disposeDiscipline(tester, db);
  });

  testWidgets('crea un alimento che non trovi', (tester) async {
    await tester.runAsync(() => seedProfile(db));
    await tester.runAsync(() => FoodRepository(db).saveBody(testBody));
    await pumpDiscipline(tester, db, now: DateTime(2026, 10, 13, 8));
    await openFood(tester);
    await tester.scrollUntilVisible(find.text('Aggiungi la colazione'), 200);
    await tester.ensureVisible(find.text('Aggiungi la colazione'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aggiungi la colazione'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Barretta della nonna');
    await tester.pump(const Duration(milliseconds: 600));
    await settle(tester);

    final create = find.text('Crea un alimento');
    await tester.scrollUntilVisible(
      create,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(create);
    await settle(tester);
    final fields = find.byType(TextFormField);
    expect(
      tester.widget<TextFormField>(fields.at(0)).controller!.text,
      'Barretta della nonna',
    );
    await tester.enterText(fields.at(1), '420');
    await tester.enterText(fields.at(2), '12,5');
    await tester.enterText(fields.at(3), '50');
    await tester.enterText(fields.at(4), '18');
    await tester.enterText(fields.at(5), '60');
    await tester.tap(find.text('Crea e scegli i grammi'));
    await tester.pump();
    expect(
      find.text('Gli zuccheri non possono superare i carboidrati.'),
      findsOneWidget,
    );
    await tester.enterText(fields.at(5), '20');
    await tester.tap(find.text('Crea e scegli i grammi'));
    await settle(tester);

    expect(find.text('Grammi'), findsOneWidget);
    await tester.tap(find.text('Aggiungi alla colazione').last);
    await settle(tester);

    final rows = await tester.runAsync(() => db.select(db.foodEntries).get());
    expect(rows!.single.name, 'Barretta della nonna');
    expect(rows.single.protein100, 12.5);
    expect(rows.single.source, 'custom');
    final favorites = await tester.runAsync(
      () => db.select(db.favoriteFoods).get(),
    );
    expect(favorites!.single.name, 'Barretta della nonna');
    await disposeDiscipline(tester, db);
  });

  testWidgets('acqua e settimana', (tester) async {
    await tester.runAsync(() => seedProfile(db));
    await tester.runAsync(() => seedFood(db));
    await pumpDiscipline(tester, db, now: DateTime(2026, 10, 13, 20));
    await openFood(tester);

    final add = find.byTooltip('Aggiungi un bicchiere (250 ml)');
    await tester.scrollUntilVisible(
      add,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(add);
    await settle(tester);
    await tester.tap(add);
    await settle(tester);
    await tester.tap(add);
    await settle(tester);
    // Peso di prova 72 kg → 2,5 litri.
    expect(find.text('0,5 l di 2,5 l'), findsOneWidget);
    await tester.tap(find.byTooltip('Togli un bicchiere (250 ml)'));
    await settle(tester);
    expect(await tester.runAsync(() => db.readJson('water')), {
      '2026-10-13': 250,
    });

    final week = find.text('Questa settimana');
    await tester.scrollUntilVisible(
      week,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Media'), findsOneWidget);
    final monday = find.bySemanticsLabel('Lunedì: 0 kcal');
    await tester.ensureVisible(monday);
    await tester.pumpAndSettle();
    await tester.tap(monday);
    await settle(tester);
    final container = ProviderScope.containerOf(tester.element(monday));
    expect(container.read(foodDayProvider), const LocalDate(2026, 10, 12));
    await disposeDiscipline(tester, db);
  });
}
