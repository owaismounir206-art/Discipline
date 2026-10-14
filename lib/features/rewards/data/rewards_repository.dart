// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart';
import '../../../core/data/providers.dart';
import '../../../core/utils/local_date.dart';
import '../../challenge/domain/generated.dart';
import '../../challenge/domain/timed.dart';
import '../domain/rewards.dart';

/// Errore da mostrare così com'è.
class RewardsException implements Exception {
  const RewardsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Una sfida a tempo salvata.
typedef SavedTimedResult = ({
  TimedResult result,
  String? friendName,
  int? friendScore,
  DateTime at,
});

/// Punti, giorni jolly, temi sbloccati e risultati delle sfide.
class RewardsRepository {
  RewardsRepository(this._db);

  final AppDatabase _db;
  static const _protectedKey = 'protectedDays';

  // --- Punti ---

  Stream<List<PointEntry>> watchPoints() =>
      (_db.select(_db.pointEntries)..orderBy([(t) => OrderingTerm.desc(t.at)]))
          .watch()
          .map((rows) => [for (final r in rows) _entry(r)]);

  Future<List<PointEntry>> points() async => [
    for (final r in await _db.select(_db.pointEntries).get()) _entry(r),
  ];

  PointEntry _entry(PointRow r) => PointEntry(
    kind: PointKind.values.asNameMap()[r.kind] ?? PointKind.workout,
    amount: r.amount,
    at: r.at,
    ref: r.ref,
    note: r.note,
  );

  /// Aggiunge punti. Con [ref] già usato non fa nulla e restituisce false.
  Future<bool> award(
    PointKind kind,
    int amount, {
    required DateTime at,
    String? ref,
    String? note,
  }) async {
    if (amount <= 0) return false;
    return _db.transaction(() async {
      if (ref != null && await hasRef(ref)) return false;
      await _db
          .into(_db.pointEntries)
          .insert(
            PointEntriesCompanion.insert(
              kind: kind.name,
              amount: amount,
              at: at,
              ref: Value(ref),
              note: Value(note),
            ),
          );
      return true;
    });
  }

  Future<bool> hasRef(String ref) async =>
      await (_db.select(
        _db.pointEntries,
      )..where((t) => t.ref.equals(ref))).getSingleOrNull() !=
      null;

  Future<void> _spend(
    PointKind kind,
    int cost, {
    required DateTime at,
    String? ref,
    String? note,
  }) => _db.transaction(() async {
    final balance = balanceOf(await points());
    if (balance < cost) {
      throw RewardsException(
        'Ti mancano ${cost - balance} punti. Allenati e completa le sfide!',
      );
    }
    await _db
        .into(_db.pointEntries)
        .insert(
          PointEntriesCompanion.insert(
            kind: kind.name,
            amount: -cost,
            at: at,
            ref: Value(ref),
            note: Value(note),
          ),
        );
  });

  // --- Giorni jolly ---

  Stream<Set<LocalDate>> watchProtectedDays() => _db
      .watchJson(_protectedKey)
      .map(
        (json) => {
          for (final d in (json as List?) ?? const []) LocalDate.parse('$d'),
        },
      );

  Future<Set<LocalDate>> protectedDays() async => {
    for (final d in (await _db.readJson(_protectedKey) as List?) ?? const [])
      LocalDate.parse('$d'),
  };

  Future<int> freezesOwned() async {
    final bought = (await points())
        .where((e) => e.kind == PointKind.freeze)
        .length;
    return bought - (await protectedDays()).length;
  }

  Future<void> buyFreeze(DateTime now) async {
    if (await freezesOwned() >= maxFreezes) {
      throw const RewardsException(
        'Hai già $maxFreezes giorni jolly: usali prima di comprarne altri.',
      );
    }
    await _spend(PointKind.freeze, freezeCost, at: now, note: 'Giorno jolly');
  }

  /// Protegge un allenamento saltato con un giorno jolly.
  Future<void> useFreeze(LocalDate day) async {
    if (await freezesOwned() <= 0) {
      throw const RewardsException('Non hai giorni jolly.');
    }
    final days = await protectedDays();
    await _db.writeJson(_protectedKey, [
      for (final d in {...days, day}) d.key,
    ]);
  }

  // --- Temi ---

  Future<void> buyPalette(AppPalette palette, DateTime now) async {
    if (palette.free || await hasRef('tema-${palette.name}')) return;
    await _spend(
      PointKind.theme,
      palette.cost,
      at: now,
      ref: 'tema-${palette.name}',
      note: palette.label,
    );
  }

  // --- Sfide generate ---

  Stream<List<ChallengeEntry>> watchChallengeEntries() => _db
      .select(_db.challengeEntries)
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            ChallengeEntry(
              challengeId: r.challengeId,
              value: r.value,
              verified: r.verified,
            ),
        ],
      );

  Future<void> addChallengeEntry(
    String challengeId,
    int value, {
    required bool verified,
    required DateTime at,
  }) => _db
      .into(_db.challengeEntries)
      .insert(
        ChallengeEntriesCompanion.insert(
          challengeId: challengeId,
          value: value,
          verified: Value(verified),
          at: at,
        ),
      );

  // --- Sfide a tempo ---

  Stream<List<SavedTimedResult>> watchTimed() =>
      (_db.select(
        _db.timedResults,
      )..orderBy([(t) => OrderingTerm.desc(t.at)])).watch().map(
        (rows) => [
          for (final r in rows)
            (
              result: TimedResult(
                mode: TimedMode.values.asNameMap()[r.mode] ?? TimedMode.minute,
                reps: r.reps,
                manual: r.manualReps,
                elapsed: Duration(milliseconds: r.elapsedMs),
              ),
              friendName: r.friendName,
              friendScore: r.friendScore,
              at: r.at,
            ),
        ],
      );

  /// Salva il risultato e restituisce l'id.
  Future<int> saveTimed(
    TimedResult result, {
    required DateTime at,
    String? friendName,
    int? friendScore,
  }) => _db
      .into(_db.timedResults)
      .insert(
        TimedResultsCompanion.insert(
          mode: result.mode.name,
          reps: result.reps,
          manualReps: result.manual,
          elapsedMs: result.elapsed.inMilliseconds,
          score: Value(result.score),
          friendName: Value(friendName),
          friendScore: Value(friendScore),
          at: at,
        ),
      );
}

final rewardsRepositoryProvider = Provider<RewardsRepository>(
  (ref) => RewardsRepository(ref.watch(databaseProvider)),
);
