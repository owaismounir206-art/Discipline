// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/account/data/memory_backend.dart';
import 'package:ritmo/features/account/domain/backend.dart';
import 'package:ritmo/features/challenge/data/live_challenge.dart';
import 'package:ritmo/features/challenge/domain/challenge.dart';

final start = DateTime(2026, 10, 13, 18);

void main() {
  /// Una sfida testa a testa tra me (Alex) e Luca, con tempo finto.
  void withChallenge(
    void Function(
      FakeAsync fake,
      MemoryBackend backend,
      LiveChallenge live,
      List<ChallengeResult> results,
    )
    body, {
    ChallengeMode mode = ChallengeMode.headToHead,
  }) {
    fakeAsync((fake) {
      DateTime now() => start.add(fake.elapsed);
      final backend = MemoryBackend(isConfigured: true, clock: now)
        ..addUser(const Friend(id: 'luca', name: 'Luca'), 'LUCA22');
      late LiveChallenge live;
      final results = <ChallengeResult>[];
      backend
          .signUp(email: 'alex@example.org', password: 'password', name: 'Alex')
          .then((_) => backend.addFriend('LUCA22'))
          .then((_) => backend.createRoom(mode, friendId: 'luca'))
          .then((roomId) {
            live = LiveChallenge(
              backend: backend,
              roomId: roomId,
              me: backend.currentAccount!.id,
              clock: now,
              onFinished: results.add,
            );
            return live.start();
          });
      fake.flushMicrotasks();
      body(fake, backend, live, results);
      live.dispose();
    });
  }

  test('attesa, conto alla rovescia, via e fine dopo 60 secondi', () {
    withChallenge((fake, backend, live, results) {
      expect(live.phase, RoomPhase.waiting);
      expect(live.connected, isTrue);
      expect(live.isHost, isTrue);
      expect(live.isSolo, isTrue);

      backend.simulateJoin(live.roomId, 'luca');
      fake.flushMicrotasks();
      expect(live.isSolo, isFalse);
      expect(live.opponentName, 'Luca');

      live.begin();
      fake.flushMicrotasks();
      expect(live.phase, RoomPhase.countdown);
      expect(live.room!.countdownLeft(live.serverNow), 3);

      // Prima del via i "+1" non contano.
      live.addRep();
      expect(live.myCount, 0);

      fake.elapse(const Duration(seconds: 3));
      expect(live.phase, RoomPhase.running);
      for (var i = 0; i < 5; i++) {
        live.addRep();
      }
      live.addRep(manual: false);
      fake.flushMicrotasks();
      backend.simulateCount(live.roomId, 'luca', 4);
      fake.flushMicrotasks();
      expect(live.myCount, 6);
      expect(live.opponentCount, 4);
      expect(backend.room(live.roomId)!.countOf(live.me), 6);
      expect(backend.room(live.roomId)!.manualOf(live.me), 5);

      fake.elapse(const Duration(seconds: 60));
      expect(live.phase, RoomPhase.finished);
      expect(results, hasLength(1));
      expect(results.single.summary, 'Hai vinto 6 a 4');
      expect(results.single.manualNote, 'Di cui 5 contati a mano');

      // Dopo la fine non si conta più e il risultato non si ripete.
      live.addRep();
      fake.elapse(const Duration(seconds: 5));
      expect(live.myCount, 6);
      expect(results, hasLength(1));
    });
  });

  test('riconnessione: i conteggi locali non si perdono', () {
    withChallenge((fake, backend, live, results) {
      backend.simulateJoin(live.roomId, 'luca');
      live.begin();
      fake.elapse(const Duration(seconds: 4));
      live
        ..addRep()
        ..addRep();
      fake.flushMicrotasks();

      backend.simulateDisconnect(live.roomId);
      fake.flushMicrotasks();
      expect(live.connected, isFalse);

      // Un messaggio vecchio (conteggio più basso) non torna indietro.
      backend.simulateCount(live.roomId, 'luca', 3);
      fake.elapse(const Duration(seconds: 3));
      expect(live.connected, isTrue);
      expect(live.myCount, 2);
      expect(live.opponentCount, 3);
    });
  });

  test('gara a 50: finisce appena qualcuno arriva a 50', () {
    withChallenge(mode: ChallengeMode.raceTo50, (fake, backend, live, results) {
      backend.simulateJoin(live.roomId, 'luca');
      live.begin();
      fake.elapse(const Duration(seconds: 4));
      backend.simulateCount(live.roomId, 'luca', 50);
      fake.elapse(const Duration(milliseconds: 400));
      expect(live.phase, RoomPhase.finished);
      expect(results.single.outcome, ChallengeOutcome.loss);
    });
  });

  test('l\'orologio del telefono avanti di 5 secondi viene corretto', () {
    fakeAsync((fake) {
      DateTime server() => start.add(fake.elapsed);
      DateTime phone() => server().add(const Duration(seconds: 5));
      final backend = MemoryBackend(isConfigured: true, clock: server);
      late LiveChallenge live;
      backend.createRoom(ChallengeMode.headToHead).then((id) {
        live = LiveChallenge(
          backend: backend,
          roomId: id,
          me: 'io',
          clock: phone,
        );
        return live.start();
      });
      fake.flushMicrotasks();
      expect(live.serverNow, server());
      live.dispose();
    });
  });

  test('incitamenti dall\'amico', () {
    withChallenge((fake, backend, live, results) {
      backend.simulateCheer(live.roomId, 'Luca');
      fake.flushMicrotasks();
      expect(live.lastCheer, 'Luca');
    });
  });
}
