// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart';
import '../../../core/data/providers.dart';
import '../../../core/utils/local_date.dart';
import '../../exercises/domain/exercise.dart';
import '../../exercises/domain/level.dart';
import '../../exercises/domain/placement.dart';
import '../../exercises/domain/progression.dart';
import '../../streak/domain/streak.dart';
import '../domain/athlete_profile.dart';

/// Salva profilo atleta, progressi delle catene e storico dei giorni.
class ProfileRepository {
  ProfileRepository(this._db);

  final AppDatabase _db;

  static const profileKey = 'profile';
  static const chainsKey = 'chains';
  static const scheduleKey = 'schedule';

  Stream<AthleteProfile?> watchProfile() => _db
      .watchJson(profileKey)
      .map(
        (json) => json == null
            ? null
            : AthleteProfile.fromJson(json as Map<String, Object?>),
      );

  Future<AthleteProfile?> loadProfile() async {
    final json = await _db.readJson(profileKey);
    return json == null
        ? null
        : AthleteProfile.fromJson(json as Map<String, Object?>);
  }

  Stream<Map<ChainId, ChainProgress>> watchChains() =>
      _db.watchJson(chainsKey).map(_chainsFromJson);

  Future<Map<ChainId, ChainProgress>> loadChains() async =>
      _chainsFromJson(await _db.readJson(chainsKey));

  Future<void> saveChains(Map<ChainId, ChainProgress> chains) => _db.writeJson(
    chainsKey,
    {for (final e in chains.entries) e.key.name: e.value.toJson()},
  );

  Stream<List<ScheduleChange>> watchSchedule() =>
      _db.watchJson(scheduleKey).map(_scheduleFromJson);

  Future<List<ScheduleChange>> loadSchedule() async =>
      _scheduleFromJson(await _db.readJson(scheduleKey));

  /// Salva il profilo. Se è nuovo o cambiano difficoltà, esperienza o test,
  /// ricalcola il punto di partenza e lo restituisce (per spiegarlo).
  Future<Placement?> saveProfile(AthleteProfile profile, LocalDate today) =>
      _db.transaction(() async {
        final previous = await loadProfile();
        await _db.writeJson(profileKey, profile.toJson());

        final schedule = addScheduleChange(
          await loadSchedule(),
          profile.trainingDays,
          today,
        );
        await _db.writeJson(scheduleKey, [
          for (final c in schedule) c.toJson(),
        ]);

        final changedLevel =
            previous == null ||
            previous.difficulty != profile.difficulty ||
            previous.experience != profile.experience ||
            previous.test != profile.test;
        if (!changedLevel) return null;

        final placement = computePlacement(profile);
        await saveChains({
          for (final e in placement.positions.entries)
            e.key: ChainProgress(chain: e.key, position: e.value, since: today),
        });
        return placement;
      });

  static Map<ChainId, ChainProgress> _chainsFromJson(Object? json) {
    if (json is! Map<String, Object?>) return const {};
    return {
      for (final e in json.entries)
        if (ChainId.values.any((c) => c.name == e.key))
          ChainId.values.byName(e.key): ChainProgress.fromJson(
            ChainId.values.byName(e.key),
            e.value! as Map<String, Object?>,
          ),
    };
  }

  static List<ScheduleChange> _scheduleFromJson(Object? json) {
    if (json is! List<Object?>) return const [];
    return [
      for (final c in json) ScheduleChange.fromJson(c! as Map<String, Object?>),
    ];
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(databaseProvider)),
);

final athleteProfileProvider = StreamProvider<AthleteProfile?>(
  (ref) => ref.watch(profileRepositoryProvider).watchProfile(),
);

final chainProgressProvider = StreamProvider<Map<ChainId, ChainProgress>>(
  (ref) => ref.watch(profileRepositoryProvider).watchChains(),
);

final scheduleProvider = StreamProvider<List<ScheduleChange>>(
  (ref) => ref.watch(profileRepositoryProvider).watchSchedule(),
);

/// Livello mostrato, dalle varianti raggiunte.
final levelProvider = Provider<LevelInfo?>((ref) {
  final chains = ref.watch(chainProgressProvider).value;
  if (chains == null || chains.isEmpty) return null;
  return computeLevel(chains);
});
