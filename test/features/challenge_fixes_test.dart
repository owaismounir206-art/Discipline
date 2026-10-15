// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/core/utils/local_date.dart';
import 'package:discipline/features/challenge/domain/friend_code.dart';
import 'package:discipline/features/challenge/domain/generated.dart';
import 'package:discipline/features/challenge/domain/timed.dart';
import 'package:discipline/features/exercises/domain/exercise.dart';
import 'package:discipline/features/profile/domain/athlete_profile.dart';
import 'package:discipline/features/rewards/data/rewards_repository.dart';
import 'package:discipline/features/rewards/domain/rewards.dart';

import '../helpers.dart';

void main() {
  const positions = {
    ChainId.push: 3,
    ChainId.pull: 2,
    ChainId.dip: 1,
    ChainId.legs: 1,
    ChainId.core: 1,
  };

  test('la sfida della settimana resta la stessa tutti i giorni', () {
    // Dieci settimane, ogni giorno.
    for (var w = 0; w < 10; w++) {
      final monday = const LocalDate(2026, 10, 12).addDays(7 * w);
      final weekly = {
        for (var d = 0; d < 7; d++)
          generateChallenges(
            today: monday.addDays(d),
            positions: positions,
            difficulty: Difficulty.intermediate,
          ).firstWhere((c) => c.period == ChallengePeriod.week),
      };
      expect(
        weekly.map((c) => (c.id, c.exercise.id, c.target)).toSet(),
        hasLength(1),
        reason: 'settimana del ${monday.key}',
      );
      // E quella del giorno non è mai lo stesso esercizio.
      for (var d = 0; d < 7; d++) {
        final both = generateChallenges(
          today: monday.addDays(d),
          positions: positions,
          difficulty: Difficulty.intermediate,
        );
        expect(both[0].exercise.chain, isNot(both[1].exercise.chain));
      }
    }
  });

  test('ora legale: la sfida del giorno cambia ogni giorno', () {
    String day(LocalDate d) => generateChallenges(
      today: d,
      positions: positions,
      difficulty: Difficulty.intermediate,
    ).firstWhere((c) => c.period == ChallengePeriod.day).exercise.id;
    // In Italia l'ora cambia il 29 marzo 2026.
    expect(
      day(const LocalDate(2026, 3, 29)),
      isNot(day(const LocalDate(2026, 3, 30))),
    );
  });

  test('il codice di un amico conserva la data (anche d\'estate)', () {
    for (final date in const [
      LocalDate(2026, 1, 1),
      LocalDate(2026, 7, 10),
      LocalDate(2026, 10, 25),
      LocalDate(2027, 3, 28),
    ]) {
      final c = FriendChallenge(
        mode: TimedMode.minute,
        score: 30,
        name: 'Luca',
        date: date,
      );
      expect(decodeFriendChallenge(encodeFriendChallenge(c))!.date, date);
    }
  });

  test('due tocchi su "Compra" non superano i giorni jolly', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final repo = RewardsRepository(db);
    await repo.award(PointKind.workout, 5000, at: testNow, ref: 'x');
    await repo.buyFreeze(testNow);
    await Future.wait([
      repo.buyFreeze(testNow),
      repo.buyFreeze(testNow).catchError((_) {}),
    ]);
    expect(await repo.freezesOwned(), maxFreezes);
  });

  test('due tocchi su un tema: pagato una volta, nessun errore', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final repo = RewardsRepository(db);
    await repo.award(PointKind.workout, 5000, at: testNow, ref: 'x');
    final palette = AppPalette.values.firstWhere((p) => !p.free);
    await Future.wait([
      repo.buyPalette(palette, testNow),
      repo.buyPalette(palette, testNow),
    ]);
    expect(balanceOf(await repo.points()), 5000 - palette.cost);
  });
}
