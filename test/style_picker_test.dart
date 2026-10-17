// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:discipline/core/router/routes.dart';
import 'package:discipline/core/theme/styles/app_style.dart';
import 'package:discipline/core/widgets/motion_widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

void main() {
  testWidgets('scegli uno stile: si applica subito e si ricorda', (
    tester,
  ) async {
    final db = memoryDatabase();
    await tester.runAsync(() => seedProfile(db));
    await pumpDiscipline(tester, db);
    unawaited(
      GoRouter.of(tester.element(find.byType(DisciplineNavigationBar)))
          .push(Routes.settings),
    );
    await settle(tester);

    final fluent = find.bySemanticsLabel('Stile Fluent');
    await tester.scrollUntilVisible(
      fluent,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await settle(tester);
    expect(find.text('Tema'), findsOneWidget);
    await tester.tap(fluent);
    await settle(tester);

    final context = tester.element(find.text('Impostazioni'));
    expect(AppStyle.of(context).id, StyleId.fluent);
    expect(Theme.of(context).textTheme.bodyMedium?.fontFamily, 'OpenSans');
    // Chiaro/scuro valgono solo per lo stile Discipline.
    expect(find.text('Tema'), findsNothing);
    final saved = await tester.runAsync(() => db.readJson('theme'));
    expect((saved! as Map)['style'], 'fluent');

    await tester.tap(find.bySemanticsLabel('Stile Discipline'));
    await settle(tester);
    expect(
      AppStyle.of(tester.element(find.text('Impostazioni'))).id,
      StyleId.material,
    );
    expect(find.text('Tema'), findsOneWidget);
    await disposeDiscipline(tester, db);
  });
}
