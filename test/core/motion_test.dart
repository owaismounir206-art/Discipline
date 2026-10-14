// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ritmo/core/theme/motion.dart';
import 'package:ritmo/core/widgets/motion_widgets.dart';

Widget app(Widget child, {bool reduce = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Scaffold(
      body: Center(child: SizedBox(width: 300, child: child)),
    ),
  ),
);

void main() {
  test('la curva parte veloce e frena', () {
    expect(RitmoMotion.decelerate.transform(1 / 3), greaterThan(0.75));
    expect(RitmoMotion.decelerate.transform(1), 1);
  });

  testWidgets('selettore: la pillola scivola sull\'opzione scelta', (
    tester,
  ) async {
    var selected = 'a';
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) => SlidingSegmented<String>(
            segments: const [
              (value: 'a', label: 'Giorno'),
              (value: 'b', label: 'Settimana'),
              (value: 'c', label: 'Mese'),
            ],
            selected: selected,
            onChanged: (v) => setState(() => selected = v),
          ),
        ),
      ),
    );
    double pillLeft() => tester.getTopLeft(find.byType(AnimatedPositioned)).dx;
    final start = pillLeft();
    await tester.tap(find.text('Mese'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 130));
    final third = pillLeft() - start;
    await tester.pumpAndSettle();
    final end = pillLeft() - start;
    expect(selected, 'c');
    // Dopo un terzo del tempo ha già fatto gran parte della strada.
    expect(third / end, greaterThan(0.7));
    expect(
      tester.getSemantics(find.text('Mese')),
      matchesSemantics(
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        label: 'Mese',
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
  });

  testWidgets('con "riduci animazioni" le card appaiono subito', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const Entrance(index: 3, child: Text('Card')), reduce: true),
    );
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('Card'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, 1);
  });

  testWidgets('le card entrano una dopo l\'altra', (tester) async {
    await tester.pumpWidget(
      app(
        const Column(
          children: [
            Entrance(index: 0, child: Text('Prima')),
            Entrance(index: 4, child: Text('Quinta')),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    double opacity(String text) => tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.text(text),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;
    expect(opacity('Prima'), greaterThan(opacity('Quinta')));
    await tester.pumpAndSettle();
    expect(opacity('Quinta'), 1);
  });
}
