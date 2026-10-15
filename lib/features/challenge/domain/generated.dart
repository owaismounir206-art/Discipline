// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../../../core/utils/local_date.dart';
import '../../exercises/domain/catalog.dart';
import '../../exercises/domain/exercise.dart';
import '../../profile/domain/athlete_profile.dart';

enum ChallengePeriod {
  day('Sfida del giorno'),
  week('Sfida della settimana');

  const ChallengePeriod(this.label);

  final String label;
}

/// Una sfida generata dall'app, tarata sul tuo livello.
@immutable
class GeneratedChallenge {
  const GeneratedChallenge({
    required this.period,
    required this.exercise,
    required this.target,
    required this.from,
    required this.to,
  });

  final ChallengePeriod period;

  /// L'esercizio della catena al tuo livello (valgono tutte le varianti
  /// della stessa catena).
  final Exercise exercise;
  final int target;
  final LocalDate from;

  /// Ultimo giorno (compreso).
  final LocalDate to;

  /// Stabile per periodo: "giorno-2026-10-14", "settimana-2026-10-12".
  String get id =>
      '${period == ChallengePeriod.day ? 'giorno' : 'settimana'}-${from.key}';

  Measure get measure => exercise.measure;

  /// Punti base (la fotocamera li moltiplica, vedi [pointsFor]).
  int get basePoints => period == ChallengePeriod.day ? 40 : 150;

  /// "40 push-up" / "3:00 di plank".
  String get goalText => measure == Measure.seconds
      ? '${_minutes(target)} di ${exercise.name.toLowerCase()}'
      : '$target ${exercise.name.toLowerCase()}';

  String get description => period == ChallengePeriod.day
      ? 'Oggi, anche a più riprese. Contano le serie dell\'allenamento.'
      : 'Entro domenica, sommando tutti i giorni.';

  /// "35" o "2:51" (per le tenute).
  String amount(int value) =>
      measure == Measure.seconds ? _minutes(value) : '$value';

  bool includes(LocalDate date) => !date.isBefore(from) && !date.isAfter(to);
}

String _minutes(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// Ripetizioni o secondi aggiunti a mano o con la fotocamera.
@immutable
class ChallengeEntry {
  const ChallengeEntry({
    required this.challengeId,
    required this.value,
    required this.verified,
  });

  final String challengeId;
  final int value;

  /// Contati dalla fotocamera.
  final bool verified;
}

/// Una serie fatta durante gli allenamenti (dallo storico).
typedef WorkoutSet = ({
  LocalDate date,
  ChainId chain,
  String exerciseId,
  int value,
});

@immutable
class ChallengeProgress {
  const ChallengeProgress({
    required this.done,
    required this.verified,
    required this.target,
  });

  final int done;

  /// Di cui contati dalla fotocamera.
  final int verified;
  final int target;

  bool get completed => done >= target;
  double get ratio => target == 0 ? 1 : math.min(1, done / target);

  /// Almeno metà contata dalla fotocamera: punti × 1,5.
  bool get cameraBonus => done > 0 && verified * 2 >= done;
}

ChallengeProgress progressOf(
  GeneratedChallenge c, {
  required Iterable<WorkoutSet> sets,
  required Iterable<ChallengeEntry> entries,
}) {
  var done = 0;
  var verified = 0;
  for (final s in sets) {
    if (!c.includes(s.date) || s.chain != c.exercise.chain) continue;
    if (Catalog.byId(s.exerciseId)?.measure != c.measure) continue;
    done += s.value;
  }
  for (final e in entries) {
    if (e.challengeId != c.id) continue;
    done += e.value;
    if (e.verified) verified += e.value;
  }
  return ChallengeProgress(done: done, verified: verified, target: c.target);
}

/// Punti per una sfida completata.
int pointsFor(GeneratedChallenge c, ChallengeProgress p) =>
    p.cameraBonus ? (c.basePoints * 1.5).round() : c.basePoints;

/// Catene da cui pescare (le trazioni no: serve una sbarra).
const _chains = [
  ChainId.push,
  ChainId.legs,
  ChainId.core,
  ChainId.dip,
  ChainId.cardio,
  ChainId.accessory,
];

/// Esercizi delle famiglie per variare che vanno bene senza attrezzi.
List<Exercise> _variety(ChainId chain) => [
  for (final e in Catalog.chain(chain))
    if (!const {
      'acc_nordic',
      'acc_chin_up',
      'acc_scap_pull',
      'acc_dead_hang',
      'acc_hanging_knee_raise',
    }.contains(e.id))
      e,
];

double _multiplier(Difficulty d) => switch (d) {
  Difficulty.beginner => 2,
  Difficulty.intermediate => 3,
  Difficulty.advanced => 4,
  Difficulty.elite => 5,
};

int _round5(double v) => math.max(5, (v / 5).round() * 5);

/// Sfida del giorno e della settimana: sempre le stesse per lo stesso
/// giorno (dipendono dalla data), diverse tra loro.
List<GeneratedChallenge> generateChallenges({
  required LocalDate today,
  required Map<ChainId, int> positions,
  required Difficulty difficulty,
}) {
  final monday = today.startOfWeek;
  // Giorni di calendario (senza ore): il cambio dell'ora legale non fa
  // ripetere la stessa sfida due giorni di fila.
  const epoch = LocalDate(2026, 1, 1);
  final daySeed = today.daysSince(epoch);
  final weekSeed = monday.daysSince(epoch) ~/ 7;
  // La sfida della settimana resta la stessa per tutta la settimana; se
  // coincide con quella del giorno, è quella del giorno a spostarsi.
  final weekChain = _chains[(weekSeed * 3 + 1) % _chains.length];
  var dayChain = _chains[daySeed % _chains.length];
  if (dayChain == weekChain) {
    dayChain = _chains[(_chains.indexOf(dayChain) + 1) % _chains.length];
  }
  final mult = _multiplier(difficulty);

  GeneratedChallenge make(ChallengePeriod period, ChainId chain) {
    final seed = period == ChallengePeriod.day ? daySeed : weekSeed;
    final exercise = chain.isProgression
        ? Catalog.at(chain, positions[chain] ?? 0)
        : _variety(chain)[(seed * 7) % _variety(chain).length];
    final perDay = exercise.range.max * mult;
    final total = period == ChallengePeriod.day ? perDay : perDay * 4;
    return GeneratedChallenge(
      period: period,
      exercise: exercise,
      target: exercise.measure == Measure.seconds
          ? (total / 15).round() * 15
          : _round5(total),
      from: period == ChallengePeriod.day ? today : monday,
      to: period == ChallengePeriod.day ? today : monday.addDays(6),
    );
  }

  return [
    make(ChallengePeriod.day, dayChain),
    make(ChallengePeriod.week, weekChain),
  ];
}
