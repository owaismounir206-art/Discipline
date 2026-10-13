// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

// Genera gli screenshot del README in docs/screenshots/.
//
//   flutter test --update-goldens tool/screenshots_test.dart

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ritmo/app.dart';
import 'package:ritmo/core/data/database.dart';

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
  find.byType(RitmoApp),
  matchesGoldenFile('../docs/screenshots/$name.png'),
);

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
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
    await pumpRitmo(tester, db);
    await wait(tester);
    await shoot('oggi');
    await disposeRitmo(tester, db);
  });

  testWidgets('profilo atleta', (tester) async {
    await tester.runAsync(() => seedHistory(db));
    await pumpRitmo(tester, db);
    await tester.tap(find.byTooltip('Profilo e impostazioni'));
    await wait(tester);
    await tester.tap(find.text('Profilo atleta'));
    await wait(tester);
    await shoot('profilo');
    await disposeRitmo(tester, db);
  });

  testWidgets('allenamento', (tester) async {
    await tester.runAsync(() => seedHistory(db));
    await pumpRitmo(tester, db);
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
    await disposeRitmo(tester, db);
  });

  testWidgets('allenati', (tester) async {
    await tester.runAsync(() => seedHistory(db));
    await pumpRitmo(tester, db);
    await openTab(tester, 'Allenati');
    await shoot('allenati');
    await disposeRitmo(tester, db);
  });
}
