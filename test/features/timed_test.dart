// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/core/utils/local_date.dart';
import 'package:discipline/features/challenge/domain/friend_code.dart';
import 'package:discipline/features/challenge/domain/timed.dart';

final t0 = DateTime(2026, 10, 13, 18);
DateTime at(int ms) => t0.add(Duration(milliseconds: ms));

void main() {
  group('Sfida a tempo', () {
    test('un minuto: conto alla rovescia, via, fine dopo 60 s', () {
      var run = const TimedRun(mode: TimedMode.minute);
      expect(run.phaseAt(t0), TimedPhase.ready);
      run = run.start(t0);
      expect(run.phaseAt(at(500)), TimedPhase.countdown);
      expect(run.countdownLeft(at(500)), 3);
      // Prima del via i push-up non contano.
      expect(run.addRep(at(1000), manual: true).reps, 0);
      run = run
          .addRep(at(4000), manual: true)
          .addRep(at(5000), manual: false)
          .addRep(at(6000), manual: false);
      expect(run.phaseAt(at(30000)), TimedPhase.running);
      expect(run.remainingAt(at(33000)).inSeconds, 30);
      expect(run.phaseAt(at(63000)), TimedPhase.finished);
      final r = run.resultAt(at(70000));
      expect(r.reps, 3);
      expect(r.manual, 1);
      expect(r.verified, 2);
      expect(r.score, 3);
      expect(r.elapsed, const Duration(seconds: 60));
      expect(r.scoreLabel, '3 push-up');
    });

    test('gara a 50: il cinquantesimo ferma il cronometro', () {
      var run = const TimedRun(mode: TimedMode.race50).start(t0);
      for (var i = 0; i < 50; i++) {
        run = run.addRep(at(3000 + 1000 + i * 1500), manual: true);
      }
      final end = at(3000 + 1000 + 49 * 1500);
      expect(run.phaseAt(end), TimedPhase.finished);
      final r = run.resultAt(at(999999));
      expect(r.completed, isTrue);
      expect(r.elapsed, const Duration(milliseconds: 1000 + 49 * 1500));
      expect(r.score, 745);
      expect(r.scoreLabel, '1:14,5');
      // Dopo la fine non si conta più.
      expect(run.addRep(at(200000), manual: true).reps, 50);
    });

    test('gara a 50 non finita in tempo non ha punteggio', () {
      final run = const TimedRun(mode: TimedMode.race50)
          .start(t0)
          .addRep(at(5000), manual: true);
      final r = run.resultAt(at(3000 + 5 * 60000 + 1));
      expect(r.completed, isFalse);
      expect(r.score, isNull);
      expect(r.scoreLabel, '1 su 50, tempo scaduto');
    });

    test('fermata a mano', () {
      var run = const TimedRun(mode: TimedMode.minute).start(t0);
      run = run.addRep(at(4000), manual: true).stop(at(20000));
      expect(run.phaseAt(at(21000)), TimedPhase.finished);
      expect(run.resultAt(at(40000)).elapsed, const Duration(seconds: 17));
    });

    test('confronto dei punteggi', () {
      expect(isBetterScore(TimedMode.minute, 40, 38), isTrue);
      expect(isBetterScore(TimedMode.race50, 700, 745), isTrue);
      expect(isBetterScore(TimedMode.race50, 800, 745), isFalse);
      expect(formatTenths(5), '0:00,5');
    });
  });

  group('Codice per sfidare un amico', () {
    const date = LocalDate(2026, 10, 13);

    test('andata e ritorno', () {
      for (final c in [
        const FriendChallenge(
          mode: TimedMode.minute,
          score: 42,
          name: 'Alex',
          date: date,
        ),
        const FriendChallenge(
          mode: TimedMode.race50,
          score: 745,
          name: 'Niccolò',
          date: LocalDate(2027, 1, 2),
        ),
        const FriendChallenge(
          mode: TimedMode.minute,
          score: 0,
          name: '',
          date: date,
        ),
      ]) {
        final code = encodeFriendChallenge(c);
        expect(code, matches(RegExp(r'^[0-9A-Z]{1,4}(-[0-9A-Z]{1,4})*$')));
        expect(decodeFriendChallenge(code), c, reason: code);
        // Minuscole, spazi e O/I scambiati per 0/1 vanno bene lo stesso.
        expect(
          decodeFriendChallenge(
            code.toLowerCase().replaceAll('-', ' ').replaceAll('0', 'o'),
          ),
          c,
        );
      }
    });

    test('nomi lunghi tagliati senza rompere gli accenti', () {
      final code = encodeFriendChallenge(
        const FriendChallenge(
          mode: TimedMode.minute,
          score: 10,
          name: 'Àèìòù Àèìòù Àèìòù',
          date: date,
        ),
      );
      expect(decodeFriendChallenge(code)!.name, 'Àèìòù');
    });

    test('un errore di battitura viene scoperto', () {
      final code = encodeFriendChallenge(
        const FriendChallenge(
          mode: TimedMode.minute,
          score: 42,
          name: 'Alex',
          date: date,
        ),
      );
      final last = code[code.length - 1];
      final typo =
          code.substring(0, code.length - 1) + (last == 'A' ? 'B' : 'A');
      expect(decodeFriendChallenge(typo), isNull);
      expect(decodeFriendChallenge(''), isNull);
      expect(decodeFriendChallenge('CIAO!'), isNull);
      expect(decodeFriendChallenge('1234'), isNull);
    });

    test('messaggi', () {
      const c = FriendChallenge(
        mode: TimedMode.minute,
        score: 42,
        name: 'Alex',
        date: date,
      );
      expect(friendChallengeMessage(c), contains('Alex ti sfida'));
      expect(friendChallengeMessage(c), contains(encodeFriendChallenge(c)));
      const mine = TimedResult(
        mode: TimedMode.minute,
        reps: 45,
        manual: 0,
        elapsed: Duration(seconds: 60),
      );
      expect(
        friendReplyMessage(c, mine, 'Sara'),
        startsWith('Ti ho battuto, Alex! Un minuto: io 45 push-up, tu 42'),
      );
    });
  });
}
