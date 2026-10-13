// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/app.dart';

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: RitmoApp()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('si apre su Oggi con le 5 voci della navigation bar', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    for (final label in ['Oggi', 'Allenati', 'Sfida', 'Cibo', 'Progressi']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
    expect(find.text('Ciao!'), findsOneWidget);
  });

  testWidgets('ogni voce apre la sua schermata', (tester) async {
    await pumpApp(tester);

    final screens = {
      'Allenati': 'Corpo libero, al tuo livello',
      'Sfida': 'Push-up in diretta con i tuoi amici',
      'Cibo': 'Diario del giorno',
      'Progressi': 'Ripetizioni e record',
      'Oggi': 'Ciao!',
    };
    for (final MapEntry(key: tab, value: marker) in screens.entries) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(marker), findsOneWidget, reason: tab);
    }
  });

  testWidgets('dal profilo si aprono le impostazioni e si cambia tema', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Profilo e impostazioni'));
    await tester.pumpAndSettle();
    expect(find.text('Impostazioni'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Scuro'));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('Impostazioni'));
    expect(Theme.of(context).brightness, Brightness.dark);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Ciao!'), findsOneWidget);
  });

  testWidgets('le icone hanno etichette per lo screen reader', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);

    expect(find.byTooltip('Notifiche'), findsOneWidget);
    expect(find.byTooltip('Profilo e impostazioni'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    handle.dispose();
  });
}
