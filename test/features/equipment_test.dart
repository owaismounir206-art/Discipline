// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/features/exercises/domain/catalog.dart';
import 'package:discipline/features/exercises/domain/equipment.dart';
import 'package:discipline/features/exercises/domain/exercise.dart';
import 'package:discipline/features/profile/domain/athlete_profile.dart';
import 'package:discipline/features/workout/domain/workout_plan.dart';

import '../helpers.dart';

void main() {
  const positions = {
    ChainId.push: 3,
    ChainId.pull: 3,
    ChainId.dip: 2,
    ChainId.legs: 2,
    ChainId.core: 1,
    ChainId.shoulders: 1,
    ChainId.skills: 3,
  };

  test('in ogni posto si fanno solo esercizi possibili', () {
    for (final place in TrainingPlace.values) {
      for (final template in WorkoutTemplate.values) {
        final plan = buildWorkout(
          template: template,
          positions: positions,
          difficulty: Difficulty.elite,
          place: place,
        );
        for (final e in plan.exercises) {
          expect(
            canDo(e.exercise, place),
            isTrue,
            reason: '${e.exercise.id} a ${place.label}',
          );
        }
        expect(plan.exercises, isNotEmpty);
        expect(plan.title, isNotEmpty);
      }
    }
  });

  test('a casa le trazioni diventano rematore sotto il tavolo', () {
    final plan = buildWorkout(
      template: WorkoutTemplate.pull,
      positions: positions,
      difficulty: Difficulty.intermediate,
      place: TrainingPlace.home,
    );
    final first = plan.exercises.first;
    expect(first.exercise.id, 'acc_table_row');
    // Il sostituto non fa avanzare la catena delle trazioni.
    expect(first.isVolume, isTrue);
    expect(plan.summary, endsWith('a casa'));
  });

  test('con la sbarra ma senza elastici: trazioni negative', () {
    expect(
      adaptTo(Catalog.byId('pull_band')!, TrainingPlace.homeBar).id,
      'pull_negative',
    );
    expect(
      adaptTo(Catalog.byId('pull_band')!, TrainingPlace.gym).id,
      'pull_band',
    );
  });

  test('il posto si salva nel profilo; i profili vecchi restano al parco', () {
    final json = testProfile.copyWith(place: TrainingPlace.home).toJson();
    expect(AthleteProfile.fromJson(json).place, TrainingPlace.home);
    final old = {...testProfile.toJson()}..remove('place');
    expect(AthleteProfile.fromJson(old).place, TrainingPlace.park);
  });
}
