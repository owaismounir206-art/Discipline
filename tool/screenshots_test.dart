// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

// Genera gli screenshot del README in docs/screenshots/.
//
//   flutter test --update-goldens tool/screenshots_test.dart

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ritmo/app.dart';
import 'package:ritmo/core/theme/theme_settings.dart';

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

class _DarkSettings extends ThemeSettingsNotifier {
  @override
  ThemeSettings build() => const ThemeSettings(mode: ThemeMode.dark);
}

void main() {
  setUpAll(loadFonts);

  Future<void> capture(
    WidgetTester tester,
    String name, {
    String? tab,
    bool dark = false,
  }) async {
    tester.view
      ..physicalSize = const Size(780, 1688)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (dark) themeSettingsProvider.overrideWith(_DarkSettings.new),
        ],
        child: const RitmoApp(),
      ),
    );
    await tester.pumpAndSettle();
    if (tab != null) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
    }
    await expectLater(
      find.byType(RitmoApp),
      matchesGoldenFile('../docs/screenshots/$name.png'),
    );
  }

  testWidgets('oggi', (tester) => capture(tester, 'oggi'));
  testWidgets('sfida', (tester) => capture(tester, 'sfida', tab: 'Sfida'));
  testWidgets(
    'cibo-scuro',
    (tester) => capture(tester, 'cibo-scuro', tab: 'Cibo', dark: true),
  );
}
