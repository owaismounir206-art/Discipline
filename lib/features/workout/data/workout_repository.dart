// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart';
import '../../../core/data/providers.dart';
import '../../../core/utils/local_date.dart';
import '../../exercises/domain/exercise.dart';
import '../domain/workout_plan.dart';

/// Una serie salvata.
typedef LoggedSet = ({
  LocalDate date,
  String exerciseId,
  ChainId chain,
  int value,
  bool isVolume,
});

/// Riassunto di una sessione per lo storico.
typedef SessionSummary = ({
  int id,
  LocalDate date,
  WorkoutTemplate template,
  int plannedSets,
  int completedSets,
  int totalReps,
  bool finished,
});

class WorkoutRepository {
  WorkoutRepository(this._db);

  final AppDatabase _db;

  Future<int> startSession({
    required LocalDate date,
    required WorkoutTemplate template,
    required int plannedSets,
    required DateTime now,
  }) => _db
      .into(_db.workoutSessions)
      .insert(
        WorkoutSessionsCompanion.insert(
          date: date.key,
          startedAt: now,
          template: template.name,
          plannedSets: plannedSets,
        ),
      );

  Future<void> logSet({
    required int sessionId,
    required Exercise exercise,
    required int value,
    required bool isVolume,
    required int completedSets,
    required DateTime now,
  }) => _db.transaction(() async {
    await _db
        .into(_db.setLogs)
        .insert(
          SetLogsCompanion.insert(
            sessionId: sessionId,
            exerciseId: exercise.id,
            chain: exercise.chain.name,
            value: value,
            isVolume: Value(isVolume),
            createdAt: now,
          ),
        );
    await (_db.update(_db.workoutSessions)
          ..where((t) => t.id.equals(sessionId)))
        .write(WorkoutSessionsCompanion(completedSets: Value(completedSets)));
  });

  Future<void> finishSession(int sessionId, DateTime now) =>
      (_db.update(_db.workoutSessions)..where((t) => t.id.equals(sessionId)))
          .write(WorkoutSessionsCompanion(endedAt: Value(now)));

  /// Elimina una sessione senza serie (allenamento abbandonato subito).
  Future<void> discardIfEmpty(int sessionId) async {
    final count = await (_db.select(
      _db.setLogs,
    )..where((t) => t.sessionId.equals(sessionId))).get();
    if (count.isEmpty) {
      await (_db.delete(
        _db.workoutSessions,
      )..where((t) => t.id.equals(sessionId))).go();
    }
  }

  /// Quota completata per giorno (il massimo tra le sessioni del giorno).
  Stream<Map<LocalDate, double>> watchCompletions() =>
      _db.select(_db.workoutSessions).watch().map((rows) {
        final result = <LocalDate, double>{};
        for (final r in rows) {
          if (r.plannedSets == 0) continue;
          final day = LocalDate.parse(r.date);
          final ratio = (r.completedSets / r.plannedSets).clamp(0.0, 1.0);
          if (ratio > (result[day] ?? 0)) result[day] = ratio;
        }
        return result;
      });

  Stream<List<LoggedSet>> watchSets() {
    final query = _db.select(_db.setLogs).join([
      innerJoin(
        _db.workoutSessions,
        _db.workoutSessions.id.equalsExp(_db.setLogs.sessionId),
      ),
    ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          if (ChainId.values.any(
            (c) => c.name == row.readTable(_db.setLogs).chain,
          ))
            (
              date: LocalDate.parse(row.readTable(_db.workoutSessions).date),
              exerciseId: row.readTable(_db.setLogs).exerciseId,
              chain: ChainId.values.byName(row.readTable(_db.setLogs).chain),
              value: row.readTable(_db.setLogs).value,
              isVolume: row.readTable(_db.setLogs).isVolume,
            ),
      ],
    );
  }

  Stream<List<SessionSummary>> watchSessions() {
    final sessions = _db.select(_db.workoutSessions)
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]);
    return sessions.watch().asyncMap((rows) async {
      final totals = <int, int>{};
      for (final set in await _db.select(_db.setLogs).get()) {
        totals[set.sessionId] = (totals[set.sessionId] ?? 0) + set.value;
      }
      return [
        for (final r in rows)
          (
            id: r.id,
            date: LocalDate.parse(r.date),
            template: WorkoutTemplate.values.firstWhere(
              (t) => t.name == r.template,
              orElse: () => WorkoutTemplate.fullBody,
            ),
            plannedSets: r.plannedSets,
            completedSets: r.completedSets,
            totalReps: totals[r.id] ?? 0,
            finished: r.endedAt != null,
          ),
      ];
    });
  }
}

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(ref.watch(databaseProvider)),
);

final completionsProvider = StreamProvider<Map<LocalDate, double>>(
  (ref) => ref.watch(workoutRepositoryProvider).watchCompletions(),
);

final loggedSetsProvider = StreamProvider<List<LoggedSet>>(
  (ref) => ref.watch(workoutRepositoryProvider).watchSets(),
);

final sessionsProvider = StreamProvider<List<SessionSummary>>(
  (ref) => ref.watch(workoutRepositoryProvider).watchSessions(),
);
