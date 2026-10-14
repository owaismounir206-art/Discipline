// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Impostazioni e oggetti semplici salvati come JSON (profilo, progressi
/// delle catene, storico dei giorni scelti...).
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Una sessione di allenamento.
class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Giorno locale della sessione (`2026-10-13`): conta per la streak.
  TextColumn get date => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get template => text()();
  IntColumn get plannedSets => integer()();
  IntColumn get completedSets => integer().withDefault(const Constant(0))();
}

/// Una serie fatta durante una sessione.
class SetLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text()();
  TextColumn get chain => text()();

  /// Ripetizioni o secondi.
  IntColumn get value => integer()();

  /// Vero se la serie è di volume (variante più facile, non conta per la
  /// progressione).
  BoolColumn get isVolume => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Un alimento nel diario.
class FoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()();

  /// breakfast, lunch, snack, dinner.
  TextColumn get meal => text()();
  TextColumn get name => text()();
  RealColumn get grams => real()();
  RealColumn get kcal100 => real()();
  RealColumn get protein100 => real()();
  RealColumn get carbs100 => real()();
  RealColumn get fat100 => real()();
  RealColumn get sugar100 => real()();
  TextColumn get source => text()();
  TextColumn get barcode => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Alimenti preferiti, per aggiungerli in un tocco.
class FavoriteFoods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  RealColumn get grams => real()();
  RealColumn get kcal100 => real()();
  RealColumn get protein100 => real()();
  RealColumn get carbs100 => real()();
  RealColumn get fat100 => real()();
  RealColumn get sugar100 => real()();
  TextColumn get source => text()();
  TextColumn get barcode => text().nullable()();
}

/// Salvadanaio dei punti: ogni riga è un guadagno (+) o una spesa (−).
@DataClassName('PointRow')
class PointEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Vedi PointKind.
  TextColumn get kind => text()();
  IntColumn get amount => integer()();
  DateTimeColumn get at => dateTime()();

  /// Chiave unica ("allenamento-12"): gli stessi punti non si danno due volte.
  TextColumn get ref => text().nullable().unique()();
  TextColumn get note => text().nullable()();
}

/// Ripetizioni o secondi aggiunti a una sfida del giorno/settimana.
@DataClassName('ChallengeEntryRow')
class ChallengeEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get challengeId => text()();
  IntColumn get value => integer()();

  /// Contati dalla fotocamera.
  BoolColumn get verified => boolean().withDefault(const Constant(false))();
  DateTimeColumn get at => dateTime()();
}

/// Sfide a tempo fatte (da soli o contro il codice di un amico).
@DataClassName('TimedResultRow')
class TimedResults extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// minute, race50.
  TextColumn get mode => text()();
  IntColumn get reps => integer()();
  IntColumn get manualReps => integer()();
  IntColumn get elapsedMs => integer()();

  /// Punteggio confrontabile (null = gara a 50 non finita).
  IntColumn get score => integer().nullable()();

  /// Sfida di un amico: nome e punteggio da battere.
  TextColumn get friendName => text().nullable()();
  IntColumn get friendScore => integer().nullable()();
  DateTimeColumn get at => dateTime()();
}

@DriftDatabase(
  tables: [
    KeyValues,
    WorkoutSessions,
    SetLogs,
    FoodEntries,
    FavoriteFoods,
    PointEntries,
    ChallengeEntries,
    TimedResults,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'discipline'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Le sfide online non esistono più: al loro posto punti e sfide
        // generate dall'app.
        await m.deleteTable('challenge_results');
        await m.createTable(pointEntries);
        await m.createTable(challengeEntries);
        await m.createTable(timedResults);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // --- Valori JSON ---

  Future<Object?> readJson(String key) async {
    final row = await (select(
      keyValues,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row == null ? null : jsonDecode(row.value);
  }

  Stream<Object?> watchJson(String key) =>
      (select(keyValues)..where((t) => t.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : jsonDecode(row.value));

  Future<void> writeJson(String key, Object? value) =>
      into(keyValues)
          .insertOnConflictUpdate(KeyValue(key: key, value: jsonEncode(value)));

  Future<void> deleteKey(String key) =>
      (delete(keyValues)..where((t) => t.key.equals(key))).go();

  /// Cancella tutti i dati (usato da "Elimina i miei dati").
  Future<void> wipe() => transaction(() async {
    for (final table in allTables) {
      await delete(table).go();
    }
  });

  // --- Copia di sicurezza ---

  /// Versione del formato di [exportAll].
  static const backupVersion = 1;

  /// Tutti i dati in JSON (per il backup sul server o su file).
  Future<Map<String, Object?>> exportAll() async => {
    'app': 'discipline',
    'version': backupVersion,
    'schema': schemaVersion,
    'tables': {
      for (final table in allTables)
        table.actualTableName: [
          for (final row in await select(table).get())
            (row as DataClass).toJson(),
        ],
    },
  };

  /// Sostituisce tutti i dati con quelli di un backup di [exportAll].
  Future<void> importAll(Map<String, Object?> backup) async {
    // Si leggono anche i backup di quando l'app si chiamava Ritmo.
    if (!const {'discipline', 'ritmo'}.contains(backup['app']) ||
        backup['tables'] is! Map) {
      throw const FormatException('Non è un backup di Discipline');
    }
    final tables = (backup['tables']! as Map).cast<String, Object?>();
    List<Map<String, dynamic>> rows(TableInfo<Table, Object?> table) => [
      for (final row in (tables[table.actualTableName] as List?) ?? const [])
        (row as Map).cast<String, dynamic>(),
    ];
    await transaction(() async {
      await wipe();
      await batch((b) {
        b
          ..insertAll(keyValues, rows(keyValues).map(KeyValue.fromJson))
          ..insertAll(
            workoutSessions,
            rows(workoutSessions).map(WorkoutSession.fromJson),
          )
          ..insertAll(setLogs, rows(setLogs).map(SetLog.fromJson))
          ..insertAll(foodEntries, rows(foodEntries).map(FoodEntry.fromJson))
          ..insertAll(
            favoriteFoods,
            rows(favoriteFoods).map(FavoriteFood.fromJson),
          )
          ..insertAll(pointEntries, rows(pointEntries).map(PointRow.fromJson))
          ..insertAll(
            challengeEntries,
            rows(challengeEntries).map(ChallengeEntryRow.fromJson),
          )
          ..insertAll(
            timedResults,
            rows(timedResults).map(TimedResultRow.fromJson),
          );
      });
    });
  }
}
