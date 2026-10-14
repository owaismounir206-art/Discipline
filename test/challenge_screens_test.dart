// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ritmo/core/router/routes.dart';
import 'package:ritmo/features/account/data/account_providers.dart';
import 'package:ritmo/features/account/data/memory_backend.dart';
import 'package:ritmo/features/account/domain/backend.dart';
import 'package:ritmo/features/challenge/data/live_media.dart';
import 'package:ritmo/features/challenge/domain/challenge.dart';

import 'helpers.dart';

/// Orologio che i test possono far avanzare.
class TestClock {
  DateTime now = testNow;

  DateTime call() => now;

  void advance(Duration d) => now = now.add(d);
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await settle(tester);
}

/// Come settle, per la sfida in diretta (che ha un timer sempre attivo).
Future<void> step(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Fa scorrere il tempo della sfida (timer da 200 ms).
Future<void> elapse(WidgetTester tester, TestClock clock, Duration d) async {
  clock.advance(d);
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

Future<MemoryBackend> serverWithLuca(TestClock clock) async {
  final backend = MemoryBackend(isConfigured: true, clock: clock.call)
    ..addUser(
      const Friend(id: 'luca', name: 'Luca', level: 'Intermedio'),
      'LUCA22',
    )
    ..addUser(const Friend(id: 'sara', name: 'Sara'), 'SARA22');
  await backend.signUp(
    email: 'alex@example.org',
    password: 'password',
    name: 'Alex',
  );
  await backend.addFriend('LUCA22');
  backend.setFriendPresence('luca', Presence.online);
  return backend;
}

void main() {
  testWidgets('senza server: spiegazione e allenamento da solo', (
    tester,
  ) async {
    final db = memoryDatabase();
    await seedProfile(db);
    final clock = TestClock();
    await pumpRitmo(tester, db, clock: clock.call);
    await openTab(tester, 'Sfida');

    expect(find.textContaining('hanno bisogno di un server'), findsOneWidget);
    final solo = find.text('Allenati da solo · Testa a testa');
    await tester.ensureVisible(solo);
    await tester.tap(solo);
    await step(tester);

    expect(find.textContaining('Mettiti in posizione'), findsOneWidget);
    await tester.tap(find.text('Via!'));
    await elapse(tester, clock, Duration.zero);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Preparati…'), findsOneWidget);

    await elapse(tester, clock, const Duration(seconds: 3));
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('+1 push-up'));
      await tester.pump();
    }
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Tocca a ogni push-up'), findsOneWidget);

    await elapse(tester, clock, const Duration(seconds: 61));
    expect(find.text('Fatto!'), findsOneWidget);
    expect(find.text('3 push-up'), findsOneWidget);
    expect(find.text('Contati a mano'), findsOneWidget);

    await tester.tap(find.text('Chiudi'));
    await step(tester);
    expect(find.text('Modalità'), findsOneWidget);
    await disposeRitmo(tester, db);
  });

  testWidgets('sfida un amico online, vinci e vedi il bilancio', (
    tester,
  ) async {
    final db = memoryDatabase();
    await seedProfile(db);
    final clock = TestClock();
    final backend = await serverWithLuca(clock);
    await pumpRitmo(
      tester,
      db,
      clock: clock.call,
      extra: [backendProvider.overrideWithValue(backend)],
    );
    await openTab(tester, 'Sfida');

    expect(find.text('Luca'), findsOneWidget);
    expect(find.text('Online · Intermedio'), findsOneWidget);
    await tester.tap(find.text('Gara a 50'));
    await tester.pump();
    final challenge = find.widgetWithText(FilledButton, 'Sfida');
    await tester.ensureVisible(challenge);
    await tester.tap(challenge);
    await step(tester);

    expect(find.text('Invito inviato. Aspettiamo che entri…'), findsOneWidget);
    backend.simulateJoin('stanza1', 'luca');
    await elapse(tester, clock, Duration.zero);
    expect(
      find.text('Luca è pronto. Quando vuoi, dai il via!'),
      findsOneWidget,
    );

    await tester.tap(find.text('Via!'));
    await elapse(tester, clock, const Duration(seconds: 3));
    expect(find.text('Gara a 50'), findsOneWidget);
    expect(find.text('Connesso'), findsOneWidget);
    await tester.tap(find.text('+1 push-up'));
    await tester.tap(find.text('+1 push-up'));
    backend.simulateCount('stanza1', 'luca', 1);
    await elapse(tester, clock, const Duration(seconds: 1));
    expect(find.text('Sei avanti di 1!'), findsOneWidget);
    expect(backend.room('stanza1')!.countOf('u1'), 2);

    backend
      ..simulateCheer('stanza1', 'Luca')
      ..simulateCount('stanza1', 'luca', 50);
    await elapse(tester, clock, const Duration(seconds: 1));
    expect(find.text('Hai perso'), findsOneWidget);
    expect(find.text('Hai perso 2 a 50'), findsOneWidget);

    await tester.tap(find.text('Chiudi'));
    await step(tester);
    expect(find.text('Ultima sfida con Luca'), findsOneWidget);
    expect(find.text('Hai perso 2 a 50 · bilancio 0–1'), findsOneWidget);
    await disposeRitmo(tester, db);
  });

  testWidgets('invito ricevuto in Oggi: accetta ed entra', (tester) async {
    final db = memoryDatabase();
    await seedProfile(db);
    final clock = TestClock();
    final backend = await serverWithLuca(clock);
    backend.simulateInvite('luca', ChallengeMode.team);
    await pumpRitmo(
      tester,
      db,
      clock: clock.call,
      extra: [backendProvider.overrideWithValue(backend)],
    );

    final card = find.text('Luca ti sfida!');
    await tester.scrollUntilVisible(
      card,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Squadra · Insieme fino a 100 push-up'), findsOneWidget);
    await tester.tap(find.text('Accetta'));
    await step(tester);
    expect(find.text('Sei dentro! Aspetta il via di Luca.'), findsOneWidget);
    expect(backend.room('stanza1')!.players.keys, contains('u1'));
    await disposeRitmo(tester, db);
  });

  testWidgets('aggiungi un amico con il codice e con il link', (tester) async {
    final db = memoryDatabase();
    await seedProfile(db);
    final clock = TestClock();
    final backend = await serverWithLuca(clock);
    await pumpRitmo(
      tester,
      db,
      clock: clock.call,
      extra: [backendProvider.overrideWithValue(backend)],
    );
    await openTab(tester, 'Sfida');

    final add = find.text('Aggiungi con un codice');
    await tester.ensureVisible(add);
    await tester.tap(add);
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'zzzzzz');
    await tester.tap(find.text('Aggiungi'));
    await settle(tester);
    expect(find.text('Nessuno ha questo codice.'), findsOneWidget);

    // Link d'invito ricevuto su WhatsApp: ritmo://app/invito/SARA22.
    final context = tester.element(find.byType(Scaffold).first);
    unawaited(GoRouter.of(context).push(Routes.invite('SARA22')));
    await settle(tester);
    expect(
      find.text('Vuoi aggiungere come amico chi ha il codice SARA22?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Aggiungi amico'));
    await settle(tester);
    expect(find.text('Sara è tra i tuoi amici'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Avvisa'), findsOneWidget);
    await disposeRitmo(tester, db);
  });

  group('Account nelle impostazioni', () {
    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Profilo e impostazioni'));
      await settle(tester);
    }

    testWidgets('senza server', (tester) async {
      final db = memoryDatabase();
      await seedProfile(db);
      await pumpRitmo(tester, db);
      await openSettings(tester);
      final info = find.text('Sfide online non attive');
      await tester.scrollUntilVisible(
        info,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(info, findsOneWidget);
      await disposeRitmo(tester, db);
    });

    testWidgets('registrazione, codice amico e copia dei dati', (tester) async {
      final db = memoryDatabase();
      await seedProfile(db);
      final backend = MemoryBackend(isConfigured: true, clock: () => testNow);
      await pumpRitmo(
        tester,
        db,
        extra: [backendProvider.overrideWithValue(backend)],
      );
      await openSettings(tester);
      final login = find.text('Accedi o registrati');
      await tester.scrollUntilVisible(
        login,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(login);
      await settle(tester);

      await tester.tap(find.text('Registrati'));
      await tester.pump();
      final fields = find.byType(TextFormField);
      expect(
        tester.widget<TextFormField>(fields.at(0)).controller!.text,
        'Alex',
      );
      await tester.enterText(fields.at(1), 'alex@example.org');
      await tester.enterText(fields.at(2), 'corta');
      await tester.tap(find.text('Crea account'));
      await tester.pump();
      expect(find.text('Almeno 8 caratteri'), findsWidgets);
      await tester.enterText(fields.at(2), 'password-lunga');
      await tester.tap(find.text('Crea account'));
      await settle(tester);

      final code = backend.currentAccount!.friendCode;
      final codeTile = find.text('Il tuo codice amico: $code');
      await tester.scrollUntilVisible(
        codeTile,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(codeTile, findsOneWidget);
      final upload = find.text('Salva una copia sul server');
      await tester.ensureVisible(upload);
      await tester.tap(upload);
      await settle(tester);
      expect(find.text('Copia salvata'), findsOneWidget);
      expect(
        (await backend.downloadBackup())!['tables'],
        isA<Map<String, Object?>>(),
      );
      await disposeRitmo(tester, db);
    });
  });

  testWidgets('con il video: microfono e video si accendono', (tester) async {
    final db = memoryDatabase();
    await seedProfile(db);
    final clock = TestClock();
    final backend = await serverWithLuca(clock);
    final media = FakeMedia();
    await pumpRitmo(
      tester,
      db,
      clock: clock.call,
      extra: [
        backendProvider.overrideWithValue(backend),
        liveMediaFactoryProvider.overrideWithValue((_) => media),
      ],
    );
    await openTab(tester, 'Sfida');
    final challenge = find.widgetWithText(FilledButton, 'Sfida');
    await tester.ensureVisible(challenge);
    await tester.tap(challenge);
    await step(tester);
    backend.simulateJoin('stanza1', 'luca');
    await elapse(tester, clock, Duration.zero);
    await tester.tap(find.text('Via!'));
    await elapse(tester, clock, const Duration(seconds: 4));

    expect(media.connectCalls, 1);
    await tester.tap(find.byTooltip('Accendi il microfono'));
    await step(tester);
    expect(media.micOn, isTrue);
    await tester.tap(find.byTooltip('Mostra il tuo video all\'amico'));
    await step(tester);
    expect(media.cameraOn, isTrue);
    expect(find.text('Video finto dell\'amico'), findsOneWidget);
    // Con il video la fotocamera non conta da sola.
    expect(find.text('Tocca a ogni push-up'), findsOneWidget);

    await tester.tap(find.byTooltip('Chiudi la sfida'));
    await step(tester);
    await tester.tap(find.text('Esci'));
    await step(tester);
    expect(media.disconnected, isTrue);
    await disposeRitmo(tester, db);
  });
}

class FakeMedia extends LiveMedia {
  var connectCalls = 0;
  var disconnected = false;
  var _mic = false;
  var _camera = false;

  @override
  bool get micOn => _mic;
  @override
  bool get cameraOn => _camera;
  @override
  bool get connected => connectCalls > 0;
  @override
  String? get error => null;

  @override
  Widget? localVideo() => const Text('Il mio video finto');
  @override
  Widget? remoteVideo() => const Text('Video finto dell\'amico');

  @override
  Future<void> connect() async {
    connectCalls++;
    notifyListeners();
  }

  @override
  Future<void> setMic(bool on) async {
    _mic = on;
    notifyListeners();
  }

  @override
  Future<void> setCamera(bool on) async {
    _camera = on;
    notifyListeners();
  }

  @override
  Future<void> disconnect() async => disconnected = true;
}
