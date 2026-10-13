// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
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

/// Storico delle sfide (anche offline).
class ChallengeResults extends Table {
  TextColumn get id => text()();
  TextColumn get friendId => text()();
  TextColumn get friendName => text()();
  TextColumn get mode => text()();
  IntColumn get myScore => integer()();
  IntColumn get friendScore => integer()();

  /// Ripetizioni contate a mano con "+1".
  IntColumn get manualReps => integer().withDefault(const Constant(0))();

  /// win, loss, draw, team.
  TextColumn get outcome => text()();
  DateTimeColumn get playedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    KeyValues,
    WorkoutSessions,
    SetLogs,
    FoodEntries,
    FavoriteFoods,
    ChallengeResults,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'ritmo'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
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
    'app': 'ritmo',
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
    if (backup['app'] != 'ritmo' || backup['tables'] is! Map) {
      throw const FormatException('Non è un backup di Ritmo');
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
          ..insertAll(
            challengeResults,
            rows(challengeResults).map(ChallengeResult.fromJson),
          );
      });
    });
  }
}
