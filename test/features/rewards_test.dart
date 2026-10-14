// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/core/utils/local_date.dart';
import 'package:discipline/features/challenge/domain/generated.dart';
import 'package:discipline/features/exercises/domain/exercise.dart';
import 'package:discipline/features/profile/domain/athlete_profile.dart';
import 'package:discipline/features/rewards/data/rewards_repository.dart';
import 'package:discipline/features/rewards/domain/rewards.dart';

import '../helpers.dart';

const tuesday = LocalDate(2026, 10, 13);
const positions = {
  ChainId.push: 3,
  ChainId.legs: 0,
  ChainId.core: 0,
  ChainId.dip: 0,
  ChainId.pull: 0,
};

void main() {
  group('Sfide generate', () {
    List<GeneratedChallenge> gen(LocalDate day, [Difficulty? d]) =>
        generateChallenges(
          today: day,
          positions: positions,
          difficulty: d ?? Difficulty.intermediate,
        );

    test(
      'stesse sfide per lo stesso giorno, una al giorno e una a settimana',
      () {
        final a = gen(tuesday);
        final b = gen(tuesday);
        expect([for (final c in a) c.id], [for (final c in b) c.id]);
        expect(a[0].period, ChallengePeriod.day);
        expect(a[0].from, tuesday);
        expect(a[1].period, ChallengePeriod.week);
        expect(a[1].from, const LocalDate(2026, 10, 12));
        expect(a[1].to, const LocalDate(2026, 10, 18));
        expect(a[0].exercise.chain, isNot(a[1].exercise.chain));
        // La settimanale resta la stessa per tutta la settimana.
        expect(gen(tuesday.addDays(3))[1].id, a[1].id);
        // Le trazioni (serve una sbarra) non escono mai.
        for (var i = 0; i < 60; i++) {
          for (final c in gen(tuesday.addDays(i))) {
            expect(c.exercise.chain, isNot(ChainId.pull));
            expect(c.target, greaterThan(0));
          }
        }
      },
    );

    test('tarate sul livello', () {
      final push = [for (var i = 0; i < 14; i++) ...gen(tuesday.addDays(i))]
          .firstWhere(
            (c) =>
                c.period == ChallengePeriod.day &&
                c.exercise.chain == ChainId.push,
          );
      // Push-up classici (8–12) × 3 = 36 → 35.
      expect(push.exercise.id, 'push_classic');
      expect(push.target, 35);
      final elite = generateChallenges(
        today: push.from,
        positions: positions,
        difficulty: Difficulty.elite,
      ).first;
      expect(elite.target, 60);
    });

    test('progressi: serie degli allenamenti e aggiunte a mano', () {
      final c = GeneratedChallenge(
        period: ChallengePeriod.day,
        exercise: gen(tuesday).first.exercise.chain == ChainId.push
            ? gen(tuesday).first.exercise
            : gen(tuesday.addDays(1)).first.exercise,
        target: 40,
        from: tuesday,
        to: tuesday,
      );
      final chain = c.exercise.chain;
      final p = progressOf(
        c,
        sets: [
          (date: tuesday, chain: chain, exerciseId: c.exercise.id, value: 12),
          (
            date: tuesday.addDays(-1),
            chain: chain,
            exerciseId: c.exercise.id,
            value: 50,
          ),
        ],
        entries: [
          ChallengeEntry(challengeId: c.id, value: 10, verified: true),
          ChallengeEntry(challengeId: c.id, value: 20, verified: true),
          const ChallengeEntry(
            challengeId: 'altra',
            value: 99,
            verified: false,
          ),
        ],
      );
      expect(p.done, 42);
      expect(p.verified, 30);
      expect(p.completed, isTrue);
      expect(p.cameraBonus, isTrue);
      expect(pointsFor(c, p), 60);
      final manual = progressOf(
        c,
        sets: const [],
        entries: [ChallengeEntry(challengeId: c.id, value: 5, verified: false)],
      );
      expect(manual.ratio, 5 / 40);
      expect(pointsFor(c, manual), 40);
    });
  });

  group('Punti e gradi', () {
    test('gradi', () {
      expect(rankFor(0).rank, Rank.rookie);
      final r = rankFor(1000);
      expect(r.rank, Rank.steady);
      expect(r.next, Rank.athlete);
      expect(r.missing, 500);
      expect(r.progress, 0.5);
      expect(rankFor(20000).next, isNull);
    });

    test('punti delle sfide a tempo e della serie', () {
      expect(timedPoints(manual: 10, verified: 0, beatTarget: false), 10);
      expect(timedPoints(manual: 0, verified: 10, beatTarget: true), 35);
      expect(streakBonus(1), 5);
      expect(streakBonus(30), 50);
    });

    test('i badge si sbloccano dai numeri', () {
      final none = achievementsFor(const BadgeStats());
      expect(none.where((b) => b.earned), isEmpty);
      final some = achievementsFor(
        const BadgeStats(workouts: 3, bestStreak: 8, pushUps: 1200),
      );
      expect(
        [for (final b in some.where((b) => b.earned)) b.title],
        ['Primo passo', 'Una settimana', 'Mille'],
      );
    });
  });

  group('Salvadanaio', () {
    late RewardsRepository repo;
    setUp(() => repo = RewardsRepository(memoryDatabase()));

    test('gli stessi punti non si danno due volte', () async {
      expect(
        await repo.award(PointKind.workout, 50, at: testNow, ref: 'a-1'),
        isTrue,
      );
      expect(
        await repo.award(PointKind.workout, 50, at: testNow, ref: 'a-1'),
        isFalse,
      );
      expect(await repo.award(PointKind.workout, 0, at: testNow), isFalse);
      expect(balanceOf(await repo.points()), 50);
    });

    test('giorni jolly: si comprano con i punti, massimo 2', () async {
      await expectLater(
        repo.buyFreeze(testNow),
        throwsA(isA<RewardsException>()),
      );
      await repo.award(PointKind.challenge, 500, at: testNow);
      await repo.buyFreeze(testNow);
      await repo.buyFreeze(testNow);
      expect(await repo.freezesOwned(), 2);
      await expectLater(
        repo.buyFreeze(testNow),
        throwsA(isA<RewardsException>()),
      );
      await repo.useFreeze(tuesday);
      expect(await repo.freezesOwned(), 1);
      expect(await repo.protectedDays(), {tuesday});
      final points = await repo.points();
      expect(balanceOf(points), 200);
      expect(lifetimeOf(points), 500);
    });

    test('temi: si pagano una volta sola', () async {
      await repo.award(PointKind.challenge, 400, at: testNow);
      await repo.buyPalette(AppPalette.ocean, testNow);
      await repo.buyPalette(AppPalette.ocean, testNow);
      await repo.buyPalette(AppPalette.coral, testNow);
      expect(balanceOf(await repo.points()), 100);
      await expectLater(
        repo.buyPalette(AppPalette.forest, testNow),
        throwsA(isA<RewardsException>()),
      );
    });
  });
}
