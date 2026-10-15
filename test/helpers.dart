// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/app.dart';
import 'package:discipline/core/data/database.dart';
import 'package:discipline/core/data/providers.dart';
import 'package:discipline/core/services/share.dart';
import 'package:discipline/core/update/update_checker.dart';
import 'package:discipline/core/utils/local_date.dart';
import 'package:discipline/features/exercises/domain/exercise.dart';
import 'package:discipline/features/food/data/food_repository.dart';
import 'package:discipline/features/food/data/open_food_facts.dart';
import 'package:discipline/features/food/domain/foods.dart';
import 'package:discipline/features/food/domain/nutrition.dart';
import 'package:discipline/features/profile/data/profile_repository.dart';
import 'package:discipline/features/profile/domain/athlete_profile.dart';
import 'package:discipline/features/streak/data/reminders.dart';
import 'package:discipline/features/workout/data/session_feedback.dart';

/// Martedì 13 ottobre 2026, 9:00.
final testNow = DateTime(2026, 10, 13, 9);

const testProfile = AthleteProfile(
  name: 'Alex',
  difficulty: Difficulty.intermediate,
  experience: Experience.threeToTwelveMonths,
  trainingDays: {1, 2, 4, 6},
  test: InitialTest(maxPushUps: 20, maxPullUps: 6, plankSeconds: 60),
  reminder: ReminderTime(18, 0),
);

class FakeReminders implements ReminderService {
  final scheduled = <AthleteProfile>[];

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(AthleteProfile profile) async => scheduled.add(profile);

  var cancelled = 0;

  @override
  Future<void> cancelAll() async => cancelled++;
}

/// Nessuna rete nei test: di base non c'è una versione nuova.
class FakeReleases implements ReleaseSource {
  FakeReleases([this.release]);

  Release? release;
  var calls = 0;

  @override
  Future<Release?> latest() async {
    calls++;
    return release;
  }
}

AppDatabase memoryDatabase() => AppDatabase(NativeDatabase.memory());

/// Salva un profilo (con il suo punto di partenza) nel database.
Future<void> seedProfile(
  AppDatabase db, [
  AthleteProfile profile = testProfile,
  LocalDate? from,
]) =>
    ProfileRepository(db)
        .saveProfile(profile, from ?? LocalDate.fromDateTime(testNow));

List<Override> testOverrides(
  AppDatabase db, {
  DateTime? now,
  DateTime Function()? clock,
  List<Override> extra = const [],
  ReleaseSource? releases,
}) => [
  databaseProvider.overrideWithValue(db),
  clockProvider.overrideWithValue(clock ?? () => now ?? testNow),
  remindersProvider.overrideWithValue(FakeReminders()),
  sessionFeedbackProvider.overrideWithValue(SilentSessionFeedback()),
  foodCatalogProvider.overrideWithValue(FakeFoodCatalog()),
  releaseSourceProvider.overrideWithValue(releases ?? FakeReleases()),
  ...extra,
];

/// Avvia l'app su un database in memoria.
Future<void> pumpDiscipline(
  WidgetTester tester,
  AppDatabase db, {
  DateTime? now,
  DateTime Function()? clock,
  List<Override> extra = const [],
  ReleaseSource? releases,
}) async {
  // Schermo di un telefono (390 × 844 come nel design).
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(
        db,
        now: now,
        clock: clock,
        extra: extra,
        releases: releases,
      ),
      child: const DisciplineApp(),
    ),
  );
  await settle(tester);
}

/// Come pumpAndSettle, ma lascia lavorare il database (che usa I/O reale).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }
}

/// Smonta l'app (evita timer pendenti nei test). Il database in memoria
/// viene liberato da solo.
Future<void> disposeDiscipline(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

/// Storico realistico: dal 14 settembre, tutti i giorni L, M, G, S fatti
/// fino a lunedì 12 ottobre, con serie di push-up, trazioni e plank.
Future<void> seedHistory(AppDatabase db) async {
  final start = DateTime(2026, 9, 14);
  await ProfileRepository(db)
      .saveProfile(testProfile, LocalDate.fromDateTime(start));
  for (var i = 0; i < 29; i++) {
    final day = DateTime(start.year, start.month, start.day + i, 18);
    if (!testProfile.trainingDays.contains(day.weekday)) continue;
    final id = await db
        .into(db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            date: LocalDate.fromDateTime(day).key,
            startedAt: day,
            endedAt: Value(day.add(const Duration(minutes: 35))),
            template: 'push',
            plannedSets: 12,
            completedSets: const Value(12),
          ),
        );
    final values = {
      'push_classic': (ChainId.push, 10 + i ~/ 4),
      'pull_up': (ChainId.pull, 5 + i ~/ 8),
      'core_hollow': (ChainId.core, 30 + i),
    };
    for (final MapEntry(key: exercise, value: (chain, value))
        in values.entries) {
      for (var s = 0; s < 3; s++) {
        await db
            .into(db.setLogs)
            .insert(
              SetLogsCompanion.insert(
                sessionId: id,
                exerciseId: exercise,
                chain: chain.name,
                value: value - s,
                createdAt: day,
              ),
            );
      }
    }
  }
}

/// Catalogo finto al posto di Open Food Facts.
class FakeFoodCatalog implements FoodCatalog {
  @override
  Future<FoodItem?> byBarcode(String barcode) async => barcode == '800'
      ? const FoodItem(
          name: 'Gallette di riso',
          per100: Nutrients(kcal: 380, protein: 8, carbs: 80, fat: 3),
          source: FoodSource.openFoodFacts,
        )
      : null;

  @override
  Future<List<FoodItem>> search(String query) async => [
    FoodItem(
      name: 'Yogurt proteico ($query)',
      per100: const Nutrients(kcal: 60, protein: 10, carbs: 4, fat: 0.2),
      source: FoodSource.openFoodFacts,
      brand: 'Marca',
    ),
  ];
}

const testBody = BodyProfile(
  sex: Sex.male,
  age: 24,
  weightKg: 72,
  heightCm: 178,
  goal: Goal.bulk,
);

/// Dati del corpo e una giornata di pasti (colazione, pranzo, spuntino).
Future<void> seedFood(AppDatabase db, {DateTime? now}) async {
  final repo = FoodRepository(db);
  await repo.saveBody(testBody);
  final day = LocalDate.fromDateTime(now ?? testNow);
  final at = now ?? testNow;
  FoodItem food(String name) => localFoods.firstWhere((f) => f.name == name);
  final meals = {
    Meal.breakfast: [
      ('Yogurt greco 0%', 250.0),
      ('Fiocchi d\'avena', 50.0),
      ('Mirtilli', 80.0),
    ],
    Meal.lunch: [
      ('Pasta di semola (cruda)', 100.0),
      ('Petto di pollo', 120.0),
      ('Pomodori', 150.0),
    ],
    Meal.snack: [('Banana', 120.0), ('Burro di arachidi', 25.0)],
  };
  for (final MapEntry(key: meal, value: items) in meals.entries) {
    for (final (name, grams) in items) {
      await repo.addEntry(
        date: day,
        meal: meal,
        food: food(name),
        grams: grams,
        now: at,
      );
    }
  }
}

/// Raccoglie i testi condivisi invece di aprire il menu del telefono.
Override shareOverride(List<String> sink) =>
    shareTextProvider.overrideWithValue((text) async => sink.add(text));
