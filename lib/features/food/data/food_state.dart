// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/providers.dart';
import '../../../core/utils/local_date.dart';
import '../../profile/data/profile_repository.dart';
import '../../streak/domain/streak.dart';
import '../../workout/data/today_plan.dart';
import '../domain/foods.dart';
import '../domain/nutrition.dart';
import 'food_repository.dart';

/// Giorno mostrato nella scheda Cibo: null = oggi.
class FoodDayNotifier extends Notifier<LocalDate?> {
  @override
  LocalDate? build() => null;

  void show(LocalDate day, LocalDate today) =>
      state = day.isBefore(today) ? day : null;
}

final foodDayNotifierProvider = NotifierProvider<FoodDayNotifier, LocalDate?>(
  FoodDayNotifier.new,
);

/// Il giorno scelto (mai nel futuro).
final foodDayProvider = Provider<LocalDate>((ref) {
  final today = ref.watch(todayProvider);
  final chosen = ref.watch(foodDayNotifierProvider);
  return chosen == null || !chosen.isBefore(today) ? today : chosen;
});

/// Diario del giorno scelto.
final dayDiaryProvider = StreamProvider<List<DiaryEntry>>((ref) {
  final day = ref.watch(foodDayProvider);
  return ref.watch(foodRepositoryProvider).watchDay(day);
});

final dayTotalsProvider = Provider<Nutrients>((ref) {
  final entries = ref.watch(dayDiaryProvider).value ?? const [];
  return entries.fold(Nutrients.zero, (sum, e) => sum + e.nutrients);
});

/// Totali dei 7 giorni (da lunedì) della settimana del giorno scelto.
final weekTotalsProvider = StreamProvider<Map<LocalDate, Nutrients>>((ref) {
  final monday = ref.watch(foodDayProvider).startOfWeek;
  return ref
      .watch(foodRepositoryProvider)
      .watchTotals(monday, monday.addDays(6));
});

final waterProvider = StreamProvider<Map<LocalDate, int>>(
  (ref) => ref.watch(foodRepositoryProvider).watchWater(),
);

/// Diario di oggi.
final todayDiaryProvider = StreamProvider<List<DiaryEntry>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(foodRepositoryProvider).watchDay(today);
});

/// Totali di oggi.
final todayTotalsProvider = Provider<Nutrients>((ref) {
  final entries = ref.watch(todayDiaryProvider).value ?? const [];
  return entries.fold(Nutrients.zero, (sum, e) => sum + e.nutrients);
});

/// Fabbisogno, se l'utente ha inserito i suoi dati.
final targetsProvider = Provider<NutritionTargets?>((ref) {
  final body = ref.watch(bodyProfileProvider).value;
  if (body == null) return null;
  final days = ref.watch(athleteProfileProvider).value?.trainingDays.length;
  return computeTargets(body, trainingDays: days ?? 3);
});

/// Prossimo pasto da riempire.
final nextMealProvider = Provider<Meal>((ref) {
  final entries = ref.watch(todayDiaryProvider).value ?? const [];
  final now = ref.watch(clockProvider)();
  return nextMeal(now, {for (final e in entries) e.meal});
});

/// Consigli per il prossimo pasto.
final recommendationsProvider = Provider<List<Recipe>>((ref) {
  final body = ref.watch(bodyProfileProvider).value;
  final targets = ref.watch(targetsProvider);
  if (body == null || targets == null) return const [];
  final totals = ref.watch(todayTotalsProvider);
  final status = ref.watch(streakProvider).statuses[ref.watch(todayProvider)];
  return recommendRecipes(
    meal: ref.watch(nextMealProvider),
    kcalLeft: targets.kcal - totals.kcal,
    proteinLeft: targets.protein - totals.protein,
    diet: body.diet,
    allergies: body.allergies,
    trainedToday: status == DayStatus.done || status == DayStatus.bonus,
  );
});
