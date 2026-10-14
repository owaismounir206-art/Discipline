// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ritmo/core/data/database.dart';

import 'helpers.dart';

Finder navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());

  testWidgets('al primo avvio si crea il profilo atleta', (tester) async {
    await pumpRitmo(tester, db);
    expect(find.text('Calisthenics libera e gratuita'), findsOneWidget);

    await tester.tap(find.text('Inizia'));
    await settle(tester);
    expect(find.text('Il tuo profilo atleta'), findsOneWidget);
    final profileList = find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first;

    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.tap(find.text('Avanzato'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('4 sessioni da 45 min · Avanzato'),
      300,
      scrollable: profileList,
    );

    await tester.scrollUntilVisible(
      find.text('Crea il mio programma'),
      300,
      scrollable: profileList,
    );
    await tester.tap(find.text('Crea il mio programma'));
    await settle(tester);
    // Il test (10 push-up) abbassa il punto di partenza: lo spieghiamo.
    expect(find.text('Il tuo punto di partenza'), findsOneWidget);
    expect(find.textContaining('Hai scelto Avanzato'), findsWidgets);

    await tester.ensureVisible(find.text('Iniziamo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniziamo'));
    await settle(tester);
    expect(find.text('Ciao, Alex'), findsOneWidget);
    expect(find.text('Inizia la tua streak'), findsOneWidget);
    await disposeRitmo(tester, db);
  });

  testWidgets('ogni voce della navigation bar apre la sua schermata', (
    tester,
  ) async {
    await tester.runAsync(() => seedProfile(db));
    await pumpRitmo(tester, db);

    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(find.text('Ciao, Alex'), findsOneWidget);
    // Martedì con giorni L, M, G, S: tocca alla scheda Tirata.
    await tester.scrollUntilVisible(find.text('Oggi · Tirata'), 200);
    expect(find.text('Inizia allenamento'), findsOneWidget);

    final screens = {
      'Allenati': 'La tua settimana',
      'Sfide': 'Guadagna punti, sblocca premi',
      'Cibo': 'Cibo',
      'Progressi': 'Progressi',
      'Oggi': 'Inizia allenamento',
    };
    for (final MapEntry(key: tab, value: marker) in screens.entries) {
      await tester.tap(navLabel(tab));
      await settle(tester);
      expect(find.text(marker), findsWidgets, reason: tab);
    }
    await disposeRitmo(tester, db);
  });

  testWidgets('le impostazioni cambiano il tema e lo ricordano', (
    tester,
  ) async {
    await tester.runAsync(() => seedProfile(db));
    await pumpRitmo(tester, db);

    await tester.tap(find.byTooltip('Profilo e impostazioni'));
    await settle(tester);
    expect(find.text('Impostazioni'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.scrollUntilVisible(find.text('Scuro'), 200);
    await tester.tap(find.text('Scuro'));
    await settle(tester);
    final context = tester.element(find.text('Impostazioni'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(await tester.runAsync(() => db.readJson('theme')), {
      'mode': 'dark',
      'dynamic': false,
      'palette': 'coral',
    });
    await disposeRitmo(tester, db);
  });

  testWidgets('Oggi rispetta le linee guida di accessibilità', (tester) async {
    await tester.runAsync(() => seedProfile(db));
    final handle = tester.ensureSemantics();
    await pumpRitmo(tester, db);

    expect(find.byTooltip('Promemoria'), findsOneWidget);
    expect(find.byTooltip('Profilo e impostazioni'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
    await disposeRitmo(tester, db);
  });
}
