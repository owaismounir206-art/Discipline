// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/features/exercises/domain/exercise.dart';
import 'package:discipline/features/exercises/domain/placement.dart';
import 'package:discipline/features/exercises/domain/progression.dart';
import 'package:discipline/features/profile/domain/athlete_profile.dart';
import 'package:discipline/features/rewards/data/rewards_repository.dart';
import 'package:discipline/features/workout/data/session_controller.dart';
import 'package:discipline/features/workout/domain/workout_plan.dart';

import '../helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('una sessione a metà non conta come "al massimo"', () {
    const range = TargetRange(8, 12);
    expect(evaluateSets(range, [12], planned: 3), SessionOutcome.inRange);
    expect(evaluateSets(range, [12, 12, 12], planned: 3), SessionOutcome.top);
  });

  test('skill sbloccate allenandosi, non solo dal profilo', () {
    expect(
      skillsUnlocked(Difficulty.advanced, {ChainId.push: 4, ChainId.pull: 3}),
      isTrue,
    );
    expect(
      skillsUnlocked(Difficulty.intermediate, {
        ChainId.push: 6,
        ChainId.pull: 5,
      }),
      isFalse,
    );
  });

  test('doppio tocco su "Serie completata": una sola serie', () async {
    final db = memoryDatabase();
    await seedProfile(db);
    final container = ProviderContainer(overrides: testOverrides(db));
    addTearDown(container.dispose);
    final sub = container.listen(sessionControllerProvider, (_, _) {});
    addTearDown(sub.close);
    final controller = container.read(sessionControllerProvider.notifier);
    await controller.start(WorkoutTemplate.pull);

    await Future.wait([controller.completeSet(), controller.completeSet()]);
    final logs = await db.select(db.setLogs).get();
    expect(logs, hasLength(1));
    expect(container.read(sessionControllerProvider)!.completedSets, 1);
    await controller.finish();
  });

  test('allenamento completo: punti base e bonus della serie', () async {
    final db = memoryDatabase();
    await seedProfile(db);
    final container = ProviderContainer(overrides: testOverrides(db));
    addTearDown(container.dispose);
    final sub = container.listen(sessionControllerProvider, (_, _) {});
    addTearDown(sub.close);
    final controller = container.read(sessionControllerProvider.notifier);
    // Martedì: tocca alla scheda Tirata.
    await controller.start(WorkoutTemplate.pull);
    while (!(container.read(sessionControllerProvider)?.finished ?? true)) {
      await controller.completeSet();
      // Tempo per far arrivare al calcolo della streak le serie salvate.
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    final kinds = (await RewardsRepository(
      db,
    ).points()).map((p) => p.kind.name).toSet();
    expect(kinds, containsAll(['workout', 'streak']));
  });

  test(
    'il secondo allenamento corto dello stesso giorno non dà punti',
    () async {
      final db = memoryDatabase();
      await seedProfile(db);
      final container = ProviderContainer(overrides: testOverrides(db));
      addTearDown(container.dispose);
      final sub = container.listen(sessionControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final controller = container.read(sessionControllerProvider.notifier);
      await controller.start(WorkoutTemplate.pull);
      await controller.completeSet();
      await controller.finish();
      expect(container.read(sessionControllerProvider)!.pointsEarned, 0);
    },
  );
}
