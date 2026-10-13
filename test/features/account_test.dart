// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/account/data/memory_backend.dart';
import 'package:ritmo/features/account/domain/backend.dart';
import 'package:ritmo/features/challenge/domain/challenge.dart';

import '../helpers.dart';

void main() {
  group('Senza server', () {
    test('account e amici spiegano che non c\'è un server', () async {
      final backend = MemoryBackend();
      expect(backend.isConfigured, isFalse);
      expect(
        () => backend.signIn(email: 'a@b.it', password: '12345678'),
        throwsA(isA<BackendException>()),
      );
      expect(await backend.watchFriends().first, isEmpty);
    });

    test('ci si può allenare da soli in modalità sfida', () async {
      final backend = MemoryBackend();
      final id = await backend.createRoom(ChallengeMode.raceTo50);
      final room = await backend.watchRoom(id).first;
      expect(room.players, hasLength(1));
      expect(room.resultFor('io').outcome, ChallengeOutcome.solo);
    });
  });

  group('Con server', () {
    late MemoryBackend backend;
    setUp(() async {
      backend = MemoryBackend(isConfigured: true)
        ..addUser(const Friend(id: 'luca', name: 'Luca'), 'LUCA22');
    });

    test('registrazione, uscita e accesso', () async {
      expect(
        () => backend.signUp(email: 'a@b.it', password: 'corta', name: 'A'),
        throwsA(isA<BackendException>()),
      );
      await backend.signUp(
        email: 'Alex@Example.org ',
        password: 'password',
        name: 'Alex',
      );
      final code = backend.currentAccount!.friendCode;
      expect(isValidFriendCode(code), isTrue);
      await backend.signOut();
      expect(backend.currentAccount, isNull);
      await expectLater(
        backend.signIn(email: 'alex@example.org', password: 'sbagliata'),
        throwsA(
          isA<BackendException>().having(
            (e) => e.message,
            'message',
            'Email o password non corrette.',
          ),
        ),
      );
      await backend.signIn(email: 'alex@example.org', password: 'password');
      expect(backend.currentAccount!.name, 'Alex');
    });

    test('amici con il codice', () async {
      await backend.signUp(email: 'a@b.it', password: 'password', name: 'A');
      await expectLater(
        backend.addFriend('ABC'),
        throwsA(isA<BackendException>()),
      );
      await expectLater(
        backend.addFriend(backend.currentAccount!.friendCode),
        throwsA(isA<BackendException>()),
      );
      final friend = await backend.addFriend('luca-22');
      expect(friend.name, 'Luca');
      expect((await backend.watchFriends().first).single.id, 'luca');
    });

    test('backup del database e ripristino', () async {
      final db = memoryDatabase();
      await seedHistory(db);
      final sets = await db.select(db.setLogs).get();
      await backend.signUp(email: 'a@b.it', password: 'password', name: 'A');
      await backend.uploadBackup(await db.exportAll());

      await db.wipe();
      expect(await db.select(db.setLogs).get(), isEmpty);
      await db.importAll((await backend.downloadBackup())!);
      final restored = await db.select(db.setLogs).get();
      expect(restored, hasLength(sets.length));
      expect(restored.first, sets.first);
      expect(await db.readJson('profile'), isNotNull);
      expect(
        () => db.importAll({'app': 'altro'}),
        throwsA(isA<FormatException>()),
      );
      await db.close();
    });
  });

  test('stato degli amici', () {
    final now = DateTime(2026, 10, 13, 18);
    expect(
      const Friend(
        id: 'l',
        name: 'Luca',
        presence: Presence.online,
        level: 'Intermedio',
      ).statusLine(now),
      'Online · Intermedio',
    );
    expect(
      Friend(
        id: 'd',
        name: 'davide',
        lastSeen: now.subtract(const Duration(hours: 2)),
      ).statusLine(now),
      'Offline · visto 2 h fa',
    );
    expect(const Friend(id: 'd', name: 'davide').initial, 'D');
  });
}
