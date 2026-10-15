// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/core/data/database.dart';
import 'package:discipline/core/data/providers.dart';
import 'package:discipline/core/theme/discipline_theme.dart';
import 'package:discipline/features/rewards/data/rewards_repository.dart';
import 'package:discipline/features/timer/domain/interval.dart';
import 'package:discipline/features/timer/presentation/interval_run_screen.dart';
import 'package:discipline/features/timer/presentation/interval_setup_screen.dart';
import 'package:discipline/features/workout/data/session_feedback.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

class CountingFeedback extends SilentSessionFeedback {
  var ticks = 0;
  var changes = 0;

  @override
  Future<void> tick() async => ticks++;

  @override
  Future<void> restFinished() async => changes++;
}

Future<void> pumpScreen(
  WidgetTester tester,
  AppDatabase db,
  Widget child, {
  SessionFeedback? feedback,
}) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => testNow),
        sessionFeedbackProvider.overrideWithValue(
          feedback ?? SilentSessionFeedback(),
        ),
      ],
      child: MaterialApp(theme: DisciplineTheme.light, home: child),
    ),
  );
  await tester.pump();
}

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());

  testWidgets('il timer avanza, fa i bip e alla fine dà i punti', (
    tester,
  ) async {
    final feedback = CountingFeedback();
    final config = const IntervalConfig.of(IntervalKind.custom)
        .copyWith(work: 5, rest: 5, rounds: 2);
    await pumpScreen(
      tester,
      db,
      IntervalRunScreen(config: config),
      feedback: feedback,
    );

    expect(find.text('Pronti'), findsOneWidget);
    expect(find.text('0:10'), findsOneWidget);
    expect(find.text('Poi: Lavora · 0:05'), findsOneWidget);

    // Bip a 3, 2, 1 e cambio di fase.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('Lavoro'), findsOneWidget);
    expect(find.text('Giro 1 di 2'), findsOneWidget);
    expect(feedback.ticks, 3);
    expect(feedback.changes, 1);

    // Pausa: il tempo si ferma.
    await tester.tap(find.byTooltip('Pausa'));
    await tester.pump();
    final before =
        find.text('0:05').evaluate().length +
        find.text('0:04').evaluate().length;
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Lavoro'), findsOneWidget);
    expect(
      find.text('0:05').evaluate().length + find.text('0:04').evaluate().length,
      before,
    );
    await tester.tap(find.byTooltip('Riprendi'));
    await tester.pump();

    // Salta al recupero e poi fino in fondo.
    await tester.tap(find.byTooltip('Passo successivo'));
    await tester.pump();
    expect(find.text('Recupero'), findsOneWidget);
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(find.text('Fatto!'), findsOneWidget);
    expect(find.textContaining('+15 punti'), findsOneWidget);

    final points = await tester.runAsync(() => RewardsRepository(db).points());
    expect(points!.single.amount, 15);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('la scelta del timer mostra durata e routine', (tester) async {
    await pumpScreen(tester, db, const IntervalSetupScreen());
    await tester.pumpAndSettle();
    expect(find.text('3:50'), findsOneWidget);
    expect(find.textContaining('Riscaldamento ·'), findsOneWidget);

    await tester.tap(find.text('Libero'));
    await tester.pumpAndSettle();
    expect(find.text('Giri'), findsOneWidget);
    // 8 × 40 + 7 × 20 = 7:40
    expect(find.text('7:40'), findsOneWidget);

    await tester.tap(find.text('EMOM'));
    await tester.pumpAndSettle();
    expect(find.text('10:00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
