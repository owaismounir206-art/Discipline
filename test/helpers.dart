// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/app.dart';
import 'package:ritmo/core/data/database.dart';
import 'package:ritmo/core/data/providers.dart';
import 'package:ritmo/core/utils/local_date.dart';
import 'package:ritmo/features/exercises/domain/exercise.dart';
import 'package:ritmo/features/profile/data/profile_repository.dart';
import 'package:ritmo/features/profile/domain/athlete_profile.dart';
import 'package:ritmo/features/streak/data/reminders.dart';
import 'package:ritmo/features/workout/data/session_feedback.dart';

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
  List<Override> extra = const [],
}) => [
  databaseProvider.overrideWithValue(db),
  clockProvider.overrideWithValue(() => now ?? testNow),
  remindersProvider.overrideWithValue(FakeReminders()),
  sessionFeedbackProvider.overrideWithValue(SilentSessionFeedback()),
  ...extra,
];

/// Avvia l'app su un database in memoria.
Future<void> pumpRitmo(
  WidgetTester tester,
  AppDatabase db, {
  DateTime? now,
  List<Override> extra = const [],
}) async {
  // Schermo di un telefono (390 × 844 come nel design).
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(db, now: now, extra: extra),
      child: const RitmoApp(),
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
Future<void> disposeRitmo(WidgetTester tester, AppDatabase db) async {
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
