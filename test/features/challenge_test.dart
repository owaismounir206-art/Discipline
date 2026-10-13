// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/challenge/domain/challenge.dart';

final start = DateTime.utc(2026, 10, 13, 18);

ChallengeRoom room(ChallengeMode mode, {DateTime? startAt}) => ChallengeRoom(
  id: 'r1',
  mode: mode,
  hostId: 'me',
  players: const {'me': 'Alex', 'luca': 'Luca'},
  startAt: startAt,
);

void main() {
  group('Fasi della stanza', () {
    test('attesa → conto alla rovescia → in corso → finita', () {
      final waiting = room(ChallengeMode.headToHead);
      expect(waiting.phaseAt(start), RoomPhase.waiting);

      final r = waiting.copyWith(startAt: start);
      final before = start.subtract(const Duration(milliseconds: 2500));
      expect(r.phaseAt(before), RoomPhase.countdown);
      expect(r.countdownLeft(before), 3);
      expect(r.phaseAt(start), RoomPhase.running);
      expect(
        r.phaseAt(start.add(const Duration(seconds: 59))),
        RoomPhase.running,
      );
      expect(
        r.phaseAt(start.add(const Duration(seconds: 60))),
        RoomPhase.finished,
      );
      expect(r.remaining(start.add(const Duration(seconds: 26))).inSeconds, 34);
    });

    test('gara a 50: finisce quando qualcuno arriva a 50', () {
      var r = room(ChallengeMode.raceTo50, startAt: start);
      final mid = start.add(const Duration(seconds: 30));
      r = r.withCount('luca', 49);
      expect(r.phaseAt(mid), RoomPhase.running);
      r = r.withCount('me', 50);
      expect(r.phaseAt(mid), RoomPhase.finished);
      expect(r.resultFor('me').outcome, ChallengeOutcome.win);
      expect(r.resultFor('luca').outcome, ChallengeOutcome.loss);
    });

    test('squadra: insieme fino a 100', () {
      var r = room(ChallengeMode.team, startAt: start);
      r = r.withCount('me', 60).withCount('luca', 39);
      final mid = start.add(const Duration(minutes: 2));
      expect(r.phaseAt(mid), RoomPhase.running);
      r = r.withCount('luca', 40);
      expect(r.phaseAt(mid), RoomPhase.finished);
      expect(r.resultFor('me').outcome, ChallengeOutcome.teamSuccess);
      expect(r.resultFor('me').summary, contains('100 push-up'));
    });

    test('annullata è finita', () {
      expect(
        room(ChallengeMode.headToHead).copyWith(cancelled: true).phaseAt(start),
        RoomPhase.finished,
      );
    });
  });

  group('Conteggi', () {
    test('possono solo salire (riconnessioni e messaggi ripetuti)', () {
      var r = room(ChallengeMode.headToHead, startAt: start);
      r = r.withCount('me', 10, manualCount: 2);
      r = r.withCount('me', 8, manualCount: 1);
      expect(r.countOf('me'), 10);
      expect(r.manualOf('me'), 2);
      r = r.withCount('me', 11);
      expect(r.manualOf('me'), 2);
    });

    test('risultato con ripetizioni contate a mano', () {
      final r = room(
        ChallengeMode.headToHead,
        startAt: start,
      ).withCount('me', 42, manualCount: 3).withCount('luca', 38);
      final res = r.resultFor('me');
      expect(res.summary, 'Hai vinto 42 a 38');
      expect(res.manualNote, 'Di cui 3 contati a mano');
      expect(res.friendName, 'Luca');
      expect(r.resultFor('luca').manualNote, 'Tutti contati con la fotocamera');
    });

    test('pareggio e allenamento da solo', () {
      final draw = room(
        ChallengeMode.headToHead,
        startAt: start,
      ).withCount('me', 5).withCount('luca', 5);
      expect(draw.resultFor('me').outcome, ChallengeOutcome.draw);
      const solo = ChallengeRoom(
        id: 's',
        mode: ChallengeMode.headToHead,
        hostId: 'me',
        players: {'me': 'Alex'},
        counts: {'me': 20},
        manual: {'me': 20},
      );
      expect(solo.resultFor('me').outcome, ChallengeOutcome.solo);
      expect(solo.resultFor('me').manualNote, 'Contati a mano');
    });
  });

  test('bilancio contro un amico', () {
    ChallengeResult r(String friend, ChallengeOutcome o) => ChallengeResult(
      roomId: 'x',
      mode: ChallengeMode.headToHead,
      friendId: friend,
      mine: 1,
      theirs: 1,
      manual: 0,
      outcome: o,
    );
    final history = [
      r('luca', ChallengeOutcome.win),
      r('luca', ChallengeOutcome.win),
      r('luca', ChallengeOutcome.loss),
      r('luca', ChallengeOutcome.draw),
      r('sara', ChallengeOutcome.loss),
    ];
    expect(balanceAgainst(history, 'luca'), (wins: 2, losses: 1, draws: 1));
  });

  group('Codici e inviti', () {
    test('codici amico leggibili e validi', () {
      final random = math.Random(1);
      for (var i = 0; i < 50; i++) {
        final code = generateFriendCode(random);
        expect(isValidFriendCode(code), isTrue, reason: code);
        expect(code, isNot(matches(RegExp('[01OI]'))));
      }
      expect(isValidFriendCode(' abc-def '), isTrue);
      expect(isValidFriendCode('ABC10O'), isFalse);
      expect(isValidFriendCode('ABC'), isFalse);
    });

    test('link e messaggio d\'invito', () {
      expect(inviteLink('abc def'), 'ritmo://app/invito/ABCDEF');
      expect(inviteMessage('Alex', 'ABCDEF'), contains('Alex ti sfida'));
      expect(inviteMessage('', 'ABCDEF'), startsWith('Ti sfida'));
    });
  });
}
