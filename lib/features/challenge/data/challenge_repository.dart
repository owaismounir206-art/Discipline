// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart' as db;
import '../../../core/data/providers.dart';
import '../domain/challenge.dart';

/// Storico delle sfide, salvato sul telefono.
class ChallengeRepository {
  ChallengeRepository(this._db);

  final db.AppDatabase _db;

  Future<void> save(ChallengeResult result, DateTime playedAt) => _db
      .into(_db.challengeResults)
      .insertOnConflictUpdate(
        db.ChallengeResultsCompanion.insert(
          id: result.roomId,
          friendId: result.friendId ?? '',
          friendName: result.friendName ?? '',
          mode: result.mode.name,
          myScore: result.mine,
          friendScore: result.theirs,
          manualReps: Value(result.manual),
          outcome: result.outcome.name,
          playedAt: playedAt,
        ),
      );

  /// Dalla più recente.
  Stream<List<ChallengeResult>> watchHistory() =>
      (_db.select(
        _db.challengeResults,
      )..orderBy([(t) => OrderingTerm.desc(t.playedAt)])).watch().map(
        (rows) => [
          for (final r in rows)
            ChallengeResult(
              roomId: r.id,
              mode: ChallengeMode.values.byName(r.mode),
              friendId: r.friendId.isEmpty ? null : r.friendId,
              friendName: r.friendName.isEmpty ? null : r.friendName,
              mine: r.myScore,
              theirs: r.friendScore,
              manual: r.manualReps,
              outcome: ChallengeOutcome.values.byName(r.outcome),
            ),
        ],
      );
}

final challengeRepositoryProvider = Provider<ChallengeRepository>(
  (ref) => ChallengeRepository(ref.watch(databaseProvider)),
);

final challengeHistoryProvider = StreamProvider<List<ChallengeResult>>(
  (ref) => ref.watch(challengeRepositoryProvider).watchHistory(),
);
