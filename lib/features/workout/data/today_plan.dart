// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/providers.dart';
import '../../../core/utils/local_date.dart';
import '../../exercises/domain/exercise.dart';
import '../../profile/data/profile_repository.dart';
import '../../rewards/data/rewards_state.dart';
import '../../streak/domain/streak.dart';
import '../domain/focus_workout.dart';
import '../domain/workout_plan.dart';
import 'workout_repository.dart';

/// Giorno corrente; si aggiorna quando l'app torna in primo piano.
final todayProvider = Provider<LocalDate>((ref) => todayFrom(ref));

/// Posizioni attuali nelle catene.
final positionsProvider = Provider<Map<ChainId, int>>((ref) {
  final chains = ref.watch(chainProgressProvider).value ?? const {};
  return {for (final e in chains.entries) e.key: e.value.position};
});

/// Scheda prevista per un giorno della settimana, se è un giorno scelto.
WorkoutTemplate? templateForWeekday(Set<int> days, int weekday) =>
    weeklySchedule(days)[weekday];

/// Allenamento di oggi: la scheda del giorno, oppure — nei giorni di riposo —
/// una sessione Full body facoltativa (bonus).
final todayWorkoutProvider = Provider<({WorkoutPlan plan, bool scheduled})?>((
  ref,
) {
  final profile = ref.watch(athleteProfileProvider).value;
  final positions = ref.watch(positionsProvider);
  if (profile == null || positions.isEmpty) return null;
  final today = ref.watch(todayProvider);
  // Gli stessi giorni che usa la streak: se cambi i giorni oggi, la modifica
  // vale da domani (oggi resta com'era, anche per la scheda in "Oggi").
  final schedule = ref.watch(scheduleProvider).value ?? const [];
  final days = daysOn(schedule, today) ?? profile.trainingDays;
  final template = templateForWeekday(days, today.weekday);
  return (
    plan: buildWorkout(
      template: template ?? WorkoutTemplate.fullBody,
      positions: positions,
      difficulty: profile.difficulty,
      place: profile.place,
      seed: weekSeed(today),
    ),
    scheduled: template != null,
  );
});

final streakProvider = Provider<StreakResult>((ref) {
  final schedule = ref.watch(scheduleProvider).value ?? const [];
  final completions = ref.watch(completionsProvider).value ?? const {};
  return computeStreak(
    schedule: schedule,
    completions: completions,
    today: ref.watch(todayProvider),
    protectedDays: ref.watch(protectedDaysProvider).value ?? const {},
  );
});

/// Il giorno saltato da proteggere con un giorno jolly, solo se serve
/// davvero: se proteggerlo non allunga la serie (era già a zero, o c'è un
/// altro giorno saltato prima) il jolly andrebbe sprecato.
final usefulFreezeDayProvider = Provider<LocalDate?>((ref) {
  final streak = ref.watch(streakProvider);
  final today = ref.watch(todayProvider);
  final missed = freezableDay(streak, today);
  if (missed == null) return null;
  final protected = ref.watch(protectedDaysProvider).value ?? const {};
  final after = computeStreak(
    schedule: ref.watch(scheduleProvider).value ?? const [],
    completions: ref.watch(completionsProvider).value ?? const {},
    today: today,
    protectedDays: {...protected, missed},
  );
  return after.current > streak.current ? missed : null;
});
