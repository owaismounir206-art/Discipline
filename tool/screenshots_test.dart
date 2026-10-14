// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

// Genera gli screenshot del README in docs/screenshots/.
//
//   flutter test --update-goldens tool/screenshots_test.dart

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ritmo/app.dart';
import 'package:ritmo/core/data/database.dart';
import 'package:ritmo/core/router/routes.dart';

import 'package:ritmo/features/account/data/account_providers.dart';
import 'package:ritmo/features/account/data/memory_backend.dart';
import 'package:ritmo/features/account/domain/backend.dart';
import 'package:ritmo/features/challenge/data/challenge_repository.dart';
import 'package:ritmo/features/challenge/domain/challenge.dart';

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

  testWidgets('progressi', (tester) async {
    await tester.runAsync(() => seedHistory(db));
    await pumpRitmo(tester, db);
    await openTab(tester, 'Progressi');
    await shoot('progressi');
    await disposeRitmo(tester, db);
  });

  testWidgets('cibo', (tester) async {
    final evening = DateTime(2026, 10, 13, 19);
    await tester.runAsync(() => seedHistory(db));
    await tester.runAsync(() => seedFood(db, now: evening));
    await pumpRitmo(tester, db, now: evening);
    await openTab(tester, 'Cibo');
    await shoot('cibo');
    await tester.tap(find.text('Cosa mangio a cena?'));
    await wait(tester);
    await shoot('consigli');
    await disposeRitmo(tester, db);
  });

  Future<MemoryBackend> friends(DateTime Function() clock) async {
    final backend = MemoryBackend(isConfigured: true, clock: clock)
      ..addUser(
        const Friend(
          id: 'luca',
          name: 'Luca',
          presence: Presence.online,
          level: 'Intermedio',
        ),
        'LUCA22',
      )
      ..addUser(
        const Friend(
          id: 'sara',
          name: 'Sara',
          presence: Presence.training,
          level: 'Avanzato',
        ),
        'SARA22',
      )
      ..addUser(
        Friend(
          id: 'davide',
          name: 'Davide',
          lastSeen: testNow.subtract(const Duration(hours: 2)),
        ),
        'DAVJDE',
      );
    await backend.signUp(
      email: 'alex@example.org',
      password: 'password',
      name: 'Alex',
    );
    for (final code in ['LUCA22', 'SARA22', 'DAVJDE']) {
      await backend.addFriend(code);
    }
    return backend;
  }

  testWidgets('sfida', (tester) async {
    await tester.runAsync(() => seedHistory(db));
    final backend = await friends(() => testNow);
    final repo = ChallengeRepository(db);
    await tester.runAsync(() async {
      for (final (i, (mine, theirs)) in [
        (30, 34),
        (35, 31),
        (28, 28),
        (40, 36),
        (33, 37),
        (38, 30),
        (41, 39),
        (39, 41),
        (42, 38),
      ].indexed) {
        final room = ChallengeRoom(
          id: 'r$i',
          mode: ChallengeMode.headToHead,
          hostId: 'u1',
          players: const {'u1': 'Alex', 'luca': 'Luca'},
        ).withCount('u1', mine).withCount('luca', theirs);
        await repo.save(
          room.resultFor('u1'),
          testNow.subtract(Duration(days: 20 - i)),
        );
      }
    });
    await pumpRitmo(
      tester,
      db,
      extra: [backendProvider.overrideWithValue(backend)],
    );
    await openTab(tester, 'Sfida');
    await shoot('sfida');
    await disposeRitmo(tester, db);
  });

  testWidgets('sfida in diretta', (tester) async {
    var now = testNow;
    await tester.runAsync(() => seedHistory(db));
    final backend = await friends(() => now);
    final id = await backend.createRoom(
      ChallengeMode.headToHead,
      friendId: 'luca',
    );
    backend.simulateJoin(id, 'luca');
    await backend.startRoom(id);
    await pumpRitmo(
      tester,
      db,
      clock: () => now,
      extra: [backendProvider.overrideWithValue(backend)],
    );
    await openTab(tester, 'Sfida');
    final context = tester.element(find.byType(Scaffold).first);
    unawaited(GoRouter.of(context).push(Routes.live(id)));
    now = now.add(const Duration(seconds: 29));
    await wait(tester);
    for (var i = 0; i < 27; i++) {
      await tester.tap(find.text('+1 push-up'));
      await tester.pump();
    }
    backend.simulateCount(id, 'luca', 23);
    await wait(tester, 3);
    await shoot('sfida-live');
    await disposeRitmo(tester, db);
  });
}
