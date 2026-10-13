// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:meta/meta.dart';

import '../../profile/domain/athlete_profile.dart';
import 'catalog.dart';
import 'exercise.dart';

/// Punto di partenza in ogni catena, con le spiegazioni per l'utente.
@immutable
class Placement {
  const Placement({required this.positions, required this.notes});

  /// Posizione di partenza per catena. Le skill ci sono solo se sbloccate.
  final Map<ChainId, int> positions;

  /// Spiegazioni gentili quando il test sposta il punto di partenza.
  final List<String> notes;
}

/// Quanto pesa il test rispetto a quello che l'utente dichiara.
const _testWeight = 0.7;

/// Varianti di partenza dichiarate per difficoltà
/// (Principiante, Intermedio, Avanzato, Élite).
const _declared = <ChainId, List<int>>{
  ChainId.push: [1, 3, 4, 5],
  ChainId.pull: [0, 2, 3, 4],
  ChainId.dip: [0, 1, 2, 2],
  ChainId.legs: [0, 1, 2, 3],
  ChainId.core: [0, 1, 2, 3],
  ChainId.shoulders: [0, 0, 1, 1],
};

int _experienceShift(Experience e) => switch (e) {
  Experience.justStarted => -1,
  Experience.overThreeYears => 1,
  _ => 0,
};

/// Variante suggerita dal test dei push-up classici.
int pushPositionFromTest(int maxPushUps) => switch (maxPushUps) {
  <= 0 => 1,
  < 5 => 2,
  < 15 => 3,
  < 30 => 4,
  _ => 5,
};

/// Variante suggerita dal test delle trazioni.
int pullPositionFromTest(int maxPullUps) => switch (maxPullUps) {
  <= 0 => 0,
  < 3 => 1,
  < 5 => 2,
  < 10 => 3,
  < 15 => 4,
  _ => 5,
};

/// Variante suggerita dal test del plank.
int corePositionFromTest(int plankSeconds) => switch (plankSeconds) {
  < 60 => 0,
  < 120 => 1,
  _ => 2,
};

int _clampTo(ChainId chain, num value) =>
    value.round().clamp(0, Catalog.lastPosition(chain));

/// Calcola da dove partire: difficoltà + esperienza + test iniziale.
/// Il test pesa di più (70%): se dichiari "Avanzato" ma fai 8 push-up,
/// parti dai push-up classici.
Placement computePlacement(AthleteProfile profile) {
  final level = profile.difficulty.index;
  final shift = _experienceShift(profile.experience);
  int declared(ChainId c) => _clampTo(c, _declared[c]![level] + shift);

  final fromTest = {
    ChainId.push: pushPositionFromTest(profile.test.maxPushUps),
    ChainId.pull: pullPositionFromTest(profile.test.maxPullUps),
    ChainId.core: corePositionFromTest(profile.test.plankSeconds),
  };

  final positions = <ChainId, int>{};
  var deltaSum = 0;
  for (final MapEntry(key: chain, value: tested) in fromTest.entries) {
    final d = declared(chain);
    positions[chain] = _clampTo(
      chain,
      _testWeight * tested + (1 - _testWeight) * d,
    );
    deltaSum += tested - d;
  }

  // Dip, gambe e spalle non hanno un test: si spostano come la media degli
  // altri test.
  final averageDelta = deltaSum / fromTest.length;
  for (final chain in [ChainId.dip, ChainId.legs, ChainId.shoulders]) {
    positions[chain] = _clampTo(
      chain,
      declared(chain) + _testWeight * averageDelta,
    );
  }

  final skillsUnlocked =
      profile.difficulty.index >= Difficulty.advanced.index &&
      positions[ChainId.push]! >= 4 &&
      positions[ChainId.pull]! >= 3;
  if (skillsUnlocked) {
    positions[ChainId.skills] = profile.difficulty == Difficulty.elite ? 1 : 0;
  }

  return Placement(
    positions: positions,
    notes: _notes(profile, positions, declared),
  );
}

List<String> _notes(
  AthleteProfile profile,
  Map<ChainId, int> positions,
  int Function(ChainId) declared,
) {
  final notes = <String>[];
  final test = profile.test;
  final difficulty = profile.difficulty.label;

  void explain(ChainId chain, String measure) {
    final start = Catalog.at(chain, positions[chain]!).name;
    final d = declared(chain);
    if (positions[chain]! < d) {
      notes.add(
        'Hai scelto $difficulty, ma con $measure partiamo da «$start». '
        'È la base giusta: costruiamo forza e salirai in fretta.',
      );
    } else if (positions[chain]! > d) {
      notes.add('Ottimo test! Con $measure partiamo già da «$start».');
    }
  }

  explain(ChainId.push, _count(test.maxPushUps, 'push-up', 'push-up'));
  explain(ChainId.pull, _count(test.maxPullUps, 'trazione', 'trazioni'));
  explain(ChainId.core, '${test.plankSeconds} secondi di plank');

  if (profile.difficulty.index >= Difficulty.advanced.index &&
      !positions.containsKey(ChainId.skills)) {
    notes.add(
      'Le skill (handstand, planche, front lever) si sbloccano quando '
      'arrivi ai push-up diamante e alle trazioni.',
    );
  }
  return notes;
}

String _count(int n, String one, String many) => n == 1 ? '1 $one' : '$n $many';
