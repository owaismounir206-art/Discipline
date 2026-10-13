// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/exercises/domain/exercise.dart';
import 'package:ritmo/features/profile/domain/athlete_profile.dart';
import 'package:ritmo/features/workout/domain/workout_plan.dart';

void main() {
  const positions = {
    ChainId.push: 3,
    ChainId.pull: 2,
    ChainId.dip: 1,
    ChainId.legs: 1,
    ChainId.core: 1,
    ChainId.shoulders: 0,
  };

  group('Distribuzione settimanale', () {
    test('con 1 o 2 giorni sempre Full body', () {
      expect(weeklySchedule({3}), {3: WorkoutTemplate.fullBody});
      expect(weeklySchedule({1, 4}).values.toSet(), {WorkoutTemplate.fullBody});
    });

    test('con 4 giorni Spinta, Tirata, Gambe e core, Full body', () {
      expect(weeklySchedule({6, 1, 2, 4}), {
        1: WorkoutTemplate.push,
        2: WorkoutTemplate.pull,
        4: WorkoutTemplate.legsCore,
        6: WorkoutTemplate.fullBody,
      });
    });

    test('con 7 giorni il ciclo ricomincia', () {
      final s = weeklySchedule({1, 2, 3, 4, 5, 6, 7});
      expect(s[5], WorkoutTemplate.push);
      expect(s.length, 7);
    });
  });

  group('Sessione', () {
    test('Spinta intermedio come nel design', () {
      final plan = buildWorkout(
        template: WorkoutTemplate.push,
        positions: positions,
        difficulty: Difficulty.intermediate,
      );
      expect(plan.title, 'Push-up, dip e pike push-up');
      expect(plan.minutes, 35);
      expect(plan.exercises.first.exercise.name, 'Push-up classici');
      expect(plan.summary, startsWith('35 min · '));
      expect(plan.summary, endsWith(' · corpo libero'));
    });

    test('la durata sceglie quanti esercizi e serie', () {
      final beginner = buildWorkout(
        template: WorkoutTemplate.fullBody,
        positions: positions,
        difficulty: Difficulty.beginner,
      );
      final elite = buildWorkout(
        template: WorkoutTemplate.fullBody,
        positions: {...positions, ChainId.skills: 0},
        difficulty: Difficulty.elite,
      );
      expect(beginner.exercises, hasLength(3));
      expect(elite.exercises.length, greaterThan(beginner.exercises.length));
      for (final plan in [beginner, elite]) {
        for (final e in plan.exercises) {
          expect(e.sets, inInclusiveRange(2, 5));
        }
      }
      expect(
        elite.exercises.any((e) => e.exercise.chain == ChainId.skills),
        isTrue,
      );
    });

    test('il volume usa la variante precedente e non duplica', () {
      final plan = buildWorkout(
        template: WorkoutTemplate.pull,
        positions: positions,
        difficulty: Difficulty.advanced,
      );
      final volume = plan.exercises.where((e) => e.isVolume).toList();
      expect(volume.first.exercise.name, 'Trazioni negative');
      final ids = plan.exercises.map((e) => e.exercise.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('senza skill sbloccate non le propone', () {
      final plan = buildWorkout(
        template: WorkoutTemplate.push,
        positions: positions,
        difficulty: Difficulty.elite,
      );
      expect(
        plan.exercises.any((e) => e.exercise.chain == ChainId.skills),
        isFalse,
      );
    });
  });

  test('riassunto del programma come nel design', () {
    final s = programSummary(
      Difficulty.intermediate,
      Experience.threeToTwelveMonths,
      4,
    );
    expect(s.title, '4 sessioni da 35 min · Intermedio');
    expect(
      s.subtitle,
      'Push-up, dip, pike push-up, trazioni australiane. '
      'Difficoltà in aumento ogni 2 settimane.',
    );
  });
}
