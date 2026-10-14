// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/local_date.dart';
import '../../challenge/domain/generated.dart';
import '../../challenge/domain/timed.dart';
import '../../exercises/domain/exercise.dart';
import '../../profile/data/profile_repository.dart';
import '../../workout/data/today_plan.dart';
import '../../workout/data/workout_repository.dart';
import '../domain/rewards.dart';
import 'rewards_repository.dart';

final pointsProvider = StreamProvider<List<PointEntry>>(
  (ref) => ref.watch(rewardsRepositoryProvider).watchPoints(),
);

final balanceProvider = Provider<int>(
  (ref) => balanceOf(ref.watch(pointsProvider).value ?? const []),
);

final rankProvider = Provider<RankInfo>(
  (ref) => rankFor(lifetimeOf(ref.watch(pointsProvider).value ?? const [])),
);

final protectedDaysProvider = StreamProvider<Set<LocalDate>>(
  (ref) => ref.watch(rewardsRepositoryProvider).watchProtectedDays(),
);

final freezesOwnedProvider = Provider<int>((ref) {
  final bought = (ref.watch(pointsProvider).value ?? const [])
      .where((e) => e.kind == PointKind.freeze)
      .length;
  return bought - (ref.watch(protectedDaysProvider).value?.length ?? 0);
});

final unlockedPalettesProvider = Provider<Set<AppPalette>>((ref) {
  final refs = {
    for (final e in ref.watch(pointsProvider).value ?? const <PointEntry>[])
      ?e.ref,
  };
  return {
    for (final p in AppPalette.values)
      if (p.free || refs.contains('tema-${p.name}')) p,
  };
});

final challengeEntriesProvider = StreamProvider<List<ChallengeEntry>>(
  (ref) => ref.watch(rewardsRepositoryProvider).watchChallengeEntries(),
);

final timedResultsProvider = StreamProvider<List<SavedTimedResult>>(
  (ref) => ref.watch(rewardsRepositoryProvider).watchTimed(),
);

/// Il record personale per ogni modalità (sfide da solo e con amici).
final bestTimedProvider = Provider<Map<TimedMode, int>>((ref) {
  final best = <TimedMode, int>{};
  for (final t
      in ref.watch(timedResultsProvider).value ?? const <SavedTimedResult>[]) {
    final score = t.result.score;
    if (score == null) continue;
    final old = best[t.result.mode];
    if (old == null || isBetterScore(t.result.mode, score, old)) {
      best[t.result.mode] = score;
    }
  }
  return best;
});

typedef ChallengeStatus = ({
  GeneratedChallenge challenge,
  ChallengeProgress progress,
  bool claimed,
});

/// Sfida del giorno e della settimana con i loro progressi.
final activeChallengesProvider = Provider<List<ChallengeStatus>>((ref) {
  final profile = ref.watch(athleteProfileProvider).value;
  final positions = ref.watch(positionsProvider);
  if (profile == null) return const [];
  final today = ref.watch(todayProvider);
  final sets = [
    for (final s in ref.watch(loggedSetsProvider).value ?? const <LoggedSet>[])
      (date: s.date, chain: s.chain, exerciseId: s.exerciseId, value: s.value),
  ];
  final entries =
      ref.watch(challengeEntriesProvider).value ?? const <ChallengeEntry>[];
  final refs = {
    for (final e in ref.watch(pointsProvider).value ?? const <PointEntry>[])
      ?e.ref,
  };
  return [
    for (final c in generateChallenges(
      today: today,
      positions: positions,
      difficulty: profile.difficulty,
    ))
      (
        challenge: c,
        progress: progressOf(c, sets: sets, entries: entries),
        claimed: refs.contains('sfida-${c.id}'),
      ),
  ];
});

final badgesProvider = Provider<List<Achievement>>((ref) {
  final sessions = ref.watch(sessionsProvider).value ?? const [];
  final sets = ref.watch(loggedSetsProvider).value ?? const <LoggedSet>[];
  final points = ref.watch(pointsProvider).value ?? const <PointEntry>[];
  final entries =
      ref.watch(challengeEntriesProvider).value ?? const <ChallengeEntry>[];
  final timed =
      ref.watch(timedResultsProvider).value ?? const <SavedTimedResult>[];
  var friendWins = 0;
  for (final t in timed) {
    final mine = t.result.score;
    if (t.friendScore != null &&
        mine != null &&
        isBetterScore(t.result.mode, mine, t.friendScore!)) {
      friendWins++;
    }
  }
  return achievementsFor(
    BadgeStats(
      workouts: sessions.where((s) => s.finished).length,
      bestStreak: ref.watch(streakProvider).best,
      pushUps: sets
          .where((s) => s.chain == ChainId.push)
          .fold(0, (sum, s) => sum + s.value),
      challenges:
          points.where((e) => e.kind == PointKind.challenge).length +
          timed.length,
      cameraReps:
          entries.where((e) => e.verified).fold(0, (sum, e) => sum + e.value) +
          timed.fold(0, (sum, t) => sum + t.result.verified),
      bestMinute: ref.watch(bestTimedProvider)[TimedMode.minute] ?? 0,
      friendWins: friendWins,
    ),
  );
});
