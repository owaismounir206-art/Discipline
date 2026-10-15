// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/core/data/database.dart';
import 'package:discipline/core/widgets/motion_widgets.dart';
import 'package:discipline/features/exercises/presentation/exercise_figure.dart';
import 'package:discipline/features/exercises/presentation/figure/motions.dart'
    show squat;
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

/// La figurina si muove sempre: niente pumpAndSettle.
Future<void> step(WidgetTester tester, [int times = 4]) async {
  for (var i = 0; i < times; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());

  testWidgets('dalla griglia dei percorsi alle tappe e alla scheda', (
    tester,
  ) async {
    await tester.runAsync(() => seedProfile(db));
    // Senza animazioni la figurina sta ferma e si può usare settle.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpDiscipline(tester, db);

    final nav = find.byType(DisciplineNavigationBar);
    await tester.tap(find.descendant(of: nav, matching: find.text('Allenati')));
    await settle(tester);

    final pull = find.text('Trazioni').last;
    await tester.scrollUntilVisible(
      find.text('Mobilità'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester);
    expect(find.byType(ExerciseFigure), findsWidgets);
    await tester.ensureVisible(pull);
    await settle(tester);
    await tester.tap(pull);
    await settle(tester);

    expect(find.text('Percorsi'), findsOneWidget);
    expect(find.textContaining('di 7 · ogni tappa'), findsOneWidget);
    expect(find.text('Completata'), findsWidgets);
    expect(find.textContaining('Ci sei'), findsOneWidget);
    // La tappa attuale è aperta con il pulsante per la scheda.
    expect(find.text('Come si esegue'), findsOneWidget);

    // Le famiglie per variare non hanno lucchetti.
    await tester.ensureVisible(find.text('Mobilità'));
    await settle(tester);
    await tester.tap(find.text('Mobilità'));
    await settle(tester);
    expect(find.textContaining('12 esercizi per variare'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);

    await tester.tap(find.text('Cerchi con le braccia').first);
    await settle(tester);
    await tester.tap(find.text('Come si esegue'));
    await settle(tester);
    expect(find.text('Cerchi con le braccia'), findsWidgets);
    expect(find.byType(ExerciseFigure), findsOneWidget);

    await disposeDiscipline(tester, db);
  });

  testWidgets('la figurina gira finché le animazioni sono attive', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: ExerciseFigure(motion: squat)),
      ),
    );
    await step(tester);
    expect(tester.hasRunningAnimations, isTrue);
  });
}
