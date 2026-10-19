// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

// Anteprima di tutte le figurine in più momenti del ciclo:
//   flutter test --update-goldens tool/figures_test.dart
// Le immagini finiscono in build/figure/ (non nel repository): pagina-N.png
// con 5 momenti del ciclo per movimento, piccole-scuro.png con tutte le
// figurine piccole su fondo scuro.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:discipline/features/exercises/presentation/exercise_figure.dart';
import 'package:discipline/features/exercises/presentation/figure/skeleton.dart';

class _Still extends CustomPainter {
  _Still(this.motion, this.t, {this.dark = false});

  final Motion motion;
  final double t;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) => paintFigure(
    canvas,
    size,
    motion,
    t,
    color: dark ? const Color(0xFFFFB59E) : const Color(0xFF8F4C38),
    ground: dark ? const Color(0xFF53433F) : const Color(0xFFB0A09A),
  );

  @override
  bool shouldRepaint(_Still old) => true;
}

void main() {
  setUpAll(() async {
    final icons = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Figtree-Regular.ttf'));
    await icons.load();
  });

  const perPage = 12;
  const phases = [0.0, 0.2, 0.4, 0.6, 0.8];
  for (var page = 0; page * perPage < debugAllMotions.length; page++) {
    testWidgets('figure $page', (tester) async {
      final motions = debugAllMotions.skip(page * perPage).take(perPage);
      tester.view
        ..physicalSize = const Size(1100, 1500)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ColoredBox(
            color: Colors.white,
            child: Column(
              children: [
                for (final m in motions)
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 150,
                          child: Text(
                            m.name,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        for (final t in phases)
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              color: const Color(0xFFFFF4F0),
                              child: CustomPaint(
                                painter: _Still(m, t),
                                size: Size.infinite,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../build/figure/pagina-$page.png'),
      );
    });
  }

  testWidgets('figure piccole su fondo scuro', (tester) async {
    const cols = 10;
    const cell = Size(96, 66);
    final rows = (debugAllMotions.length / cols).ceil();
    tester.view
      ..physicalSize = Size(cell.width * cols, cell.height * rows)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: const Color(0xFF1A1110),
          child: Wrap(
            children: [
              for (final m in debugAllMotions)
                SizedBox.fromSize(
                  size: cell,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: ColoredBox(
                      color: const Color(0xFF271D1B),
                      child: CustomPaint(
                        painter: _Still(m, 0.3, dark: true),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../build/figure/piccole-scuro.png'),
    );
  });
}
