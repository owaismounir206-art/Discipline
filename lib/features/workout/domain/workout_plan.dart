// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:meta/meta.dart';

import '../../exercises/domain/catalog.dart';
import '../../exercises/domain/exercise.dart';
import '../../profile/domain/athlete_profile.dart';

/// Tipo di scheda.
enum WorkoutTemplate {
  push('Spinta'),
  pull('Tirata'),
  legsCore('Gambe e core'),
  fullBody('Full body');

  const WorkoutTemplate(this.label);

  final String label;
}

/// Un posto nella scheda: una catena, eventualmente una variante più facile
/// (offset −1) per fare volume.
@immutable
class _Slot {
  const _Slot(this.chain, [this.offset = 0]);

  final ChainId chain;
  final int offset;
}

/// Esercizi di ogni scheda in ordine di priorità: con meno tempo si fanno i
/// primi.
const _slots = <WorkoutTemplate, List<_Slot>>{
  WorkoutTemplate.push: [
    _Slot(ChainId.push),
    _Slot(ChainId.dip),
    _Slot(ChainId.shoulders),
    _Slot(ChainId.core),
    _Slot(ChainId.skills),
    _Slot(ChainId.push, -1),
  ],
  WorkoutTemplate.pull: [
    _Slot(ChainId.pull),
    _Slot(ChainId.pull, -1),
    _Slot(ChainId.core),
    _Slot(ChainId.skills),
    _Slot(ChainId.legs),
  ],
  WorkoutTemplate.legsCore: [
    _Slot(ChainId.legs),
    _Slot(ChainId.core),
    _Slot(ChainId.legs, -1),
    _Slot(ChainId.core, -1),
    _Slot(ChainId.skills),
  ],
  WorkoutTemplate.fullBody: [
    _Slot(ChainId.push),
    _Slot(ChainId.pull),
    _Slot(ChainId.legs),
    _Slot(ChainId.core),
    _Slot(ChainId.dip),
    _Slot(ChainId.skills),
  ],
};

/// Nomi brevi per il titolo della scheda ("Push-up, dip e pike push-up").
const _chainShortNames = {
  ChainId.push: 'push-up',
  ChainId.pull: 'trazioni',
  ChainId.dip: 'dip',
  ChainId.legs: 'gambe',
  ChainId.core: 'core',
  ChainId.shoulders: 'pike push-up',
  ChainId.skills: 'skill',
};

/// Schede distribuite sui giorni scelti: con 1–2 giorni sempre Full body,
/// con 3 o più si alternano Spinta, Tirata, Gambe e core, Full body.
Map<int, WorkoutTemplate> weeklySchedule(Set<int> trainingDays) {
  final days = trainingDays.toList()..sort();
  if (days.length <= 2) {
    return {for (final d in days) d: WorkoutTemplate.fullBody};
  }
  const cycle = [
    WorkoutTemplate.push,
    WorkoutTemplate.pull,
    WorkoutTemplate.legsCore,
    WorkoutTemplate.fullBody,
  ];
  return {
    for (var i = 0; i < days.length; i++) days[i]: cycle[i % cycle.length],
  };
}

@immutable
class PlannedExercise {
  const PlannedExercise({
    required this.exercise,
    required this.sets,
    required this.restSeconds,
    this.isVolume = false,
  });

  final Exercise exercise;
  final int sets;
  final int restSeconds;

  /// Variante più facile della catena, per fare più volume. Non conta per la
  /// progressione.
  final bool isVolume;

  PlannedExercise withExercise(Exercise other) => PlannedExercise(
    exercise: other,
    sets: sets,
    restSeconds: restSeconds,
    isVolume: isVolume,
  );
}

@immutable
class WorkoutPlan {
  const WorkoutPlan({
    required this.template,
    required this.exercises,
    required this.minutes,
  });

  final WorkoutTemplate template;
  final List<PlannedExercise> exercises;

  /// Durata prevista della sessione.
  final int minutes;

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets);

  /// Titolo come nel design: "Push-up, dip e pike push-up".
  String get title {
    final names = <String>[];
    for (final e in exercises) {
      final name = _chainShortNames[e.exercise.chain]!;
      if (!names.contains(name)) names.add(name);
    }
    final shown = names.take(3).toList();
    final text = shown.length == 1
        ? shown.first
        : '${shown.sublist(0, shown.length - 1).join(', ')} e ${shown.last}';
    return text[0].toUpperCase() + text.substring(1);
  }

  /// "35 min · 5 esercizi · corpo libero".
  String get summary =>
      '$minutes min · ${exercises.length} '
      '${exercises.length == 1 ? 'esercizio' : 'esercizi'} · corpo libero';
}

int restSecondsFor(Difficulty d) => switch (d) {
  Difficulty.beginner => 60,
  Difficulty.intermediate => 75,
  Difficulty.advanced || Difficulty.elite => 90,
};

int _exerciseCount(Difficulty d) => switch (d) {
  Difficulty.beginner => 3,
  Difficulty.intermediate || Difficulty.advanced => 5,
  Difficulty.elite => 6,
};

int _warmupSeconds(Difficulty d) => d == Difficulty.beginner ? 180 : 300;

/// Costruisce la sessione di una scheda con le varianti attuali dell'utente,
/// adattando il numero di serie alla durata della difficoltà scelta.
WorkoutPlan buildWorkout({
  required WorkoutTemplate template,
  required Map<ChainId, int> positions,
  required Difficulty difficulty,
}) {
  final rest = restSecondsFor(difficulty);
  final chosen = <({Exercise exercise, bool volume})>[];
  for (final slot in _slots[template]!) {
    if (chosen.length >= _exerciseCount(difficulty)) break;
    final base = positions[slot.chain];
    if (base == null) continue;
    final position = base + slot.offset;
    if (position < 0) continue;
    final exercise = Catalog.at(slot.chain, position);
    if (chosen.any((c) => c.exercise.id == exercise.id)) continue;
    chosen.add((exercise: exercise, volume: slot.offset != 0));
  }

  final budget = difficulty.sessionMinutes * 60 - _warmupSeconds(difficulty);
  final perRound = chosen.fold(
    0,
    (sum, c) => sum + c.exercise.estimatedSetSeconds + rest,
  );
  final sets = perRound == 0 ? 0 : (budget / perRound).floor().clamp(2, 5);

  return WorkoutPlan(
    template: template,
    minutes: difficulty.sessionMinutes,
    exercises: [
      for (final c in chosen)
        PlannedExercise(
          exercise: c.exercise,
          sets: sets,
          restSeconds: c.exercise.chain == ChainId.skills ? rest + 30 : rest,
          isVolume: c.volume,
        ),
    ],
  );
}

/// Riassunto per il riquadro "Il tuo programma" del profilo atleta.
({String title, String subtitle}) programSummary(
  Difficulty difficulty,
  Experience experience,
  int days,
) => (
  title:
      '$days ${days == 1 ? 'sessione' : 'sessioni'} da '
      '${difficulty.sessionMinutes} min · ${difficulty.label}',
  subtitle:
      '${difficulty.focus}. Difficoltà in aumento '
      '${experience.progressionLabel}.',
);
