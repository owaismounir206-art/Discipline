// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:meta/meta.dart';

import 'equipment.dart';

/// Gruppo muscolare principale di un esercizio.
enum MuscleGroup {
  chest('Petto e tricipiti'),
  back('Schiena e bicipiti'),
  shoulders('Spalle'),
  legs('Gambe e glutei'),
  core('Addome'),
  fullBody('Corpo intero');

  const MuscleGroup(this.label);

  final String label;
}

/// Catena di progressione: varianti dello stesso movimento, dalla più facile
/// alla più difficile.
enum ChainId {
  push('Push-up', isMain: true),
  pull('Trazioni', isMain: true),
  dip('Dip', isMain: true),
  legs('Gambe', isMain: true),
  core('Core', isMain: true),
  shoulders('Spalle', isMain: false),
  skills('Skill', isMain: false),
  cardio('Cardio', isMain: false, isProgression: false),
  mobility('Mobilità', isMain: false, isProgression: false),
  accessory('Complementari', isMain: false, isProgression: false),
  arms('Braccia', isMain: false, isProgression: false),
  grip('Avambracci e presa', isMain: false, isProgression: false),
  posture('Schiena e postura', isMain: false, isProgression: false),
  plyo('Esplosività', isMain: false, isProgression: false),
  skillDrills('Propedeutici skill', isMain: false, isProgression: false);

  const ChainId(this.label, {required this.isMain, this.isProgression = true});

  final String label;

  /// Le catene principali decidono il livello mostrato.
  final bool isMain;

  /// Percorso con tappe da sbloccare. Le famiglie senza progressione
  /// (cardio, mobilità, complementari) servono per variare, scaldarsi e
  /// allungarsi.
  final bool isProgression;
}

/// Zona allenata, per gli allenamenti specifici (core, bicipiti...).
enum Focus {
  chest('Petto'),
  back('Schiena'),
  shoulders('Spalle'),
  biceps('Bicipiti'),
  triceps('Tricipiti'),
  forearms('Avambracci e presa'),
  core('Addome'),
  obliques('Obliqui'),
  legs('Gambe'),
  glutes('Glutei'),
  calves('Polpacci'),
  cardio('Fiato'),
  mobility('Mobilità'),
  skills('Skill');

  const Focus(this.label);

  final String label;
}

/// Come si misura una serie.
enum Measure {
  reps('ripetizioni', 'rip.'),
  seconds('secondi', 's');

  const Measure(this.label, this.short);

  final String label;
  final String short;
}

/// Intervallo di lavoro della doppia progressione (es. 8–12 ripetizioni).
@immutable
class TargetRange {
  const TargetRange(this.min, this.max) : assert(min <= max);

  final int min;
  final int max;

  @override
  String toString() => '$min–$max';
}

@immutable
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.chain,
    required this.position,
    required this.measure,
    required this.range,
    required this.instructions,
    required this.mistakes,
    this.perSide = false,
    this.focus = const {},
    this.level,
    this.equipment = const {},
    this.figure,
  });

  final String id;
  final String name;
  final MuscleGroup muscleGroup;
  final ChainId chain;

  /// Posizione nella catena: 0 = variante più facile.
  final int position;

  final Measure measure;
  final TargetRange range;

  /// Istruzioni brevi, un passo per voce.
  final List<String> instructions;

  /// Errori comuni da evitare.
  final List<String> mistakes;

  /// Vero se le ripetizioni si contano per lato (es. affondi, arciere).
  final bool perSide;

  /// Zone allenate. Se manca si ricava dal gruppo muscolare.
  final Set<Focus> focus;

  /// Difficoltà da 1 (base) a 4 (élite). Se manca si ricava dalla
  /// posizione nella catena.
  final int? level;

  /// Attrezzi necessari (oltre a quelli indicati in `needs`).
  final Set<Equipment> equipment;

  /// Nome del movimento della figurina (vedi `motions.dart`).
  final String? figure;

  /// Zone allenate, ricavate dal gruppo muscolare se non indicate.
  Set<Focus> get focusAreas {
    if (focus.isNotEmpty) return focus;
    return switch (chain) {
      ChainId.cardio || ChainId.plyo => {Focus.cardio, Focus.legs},
      ChainId.mobility => {Focus.mobility},
      ChainId.skills || ChainId.skillDrills => {Focus.skills},
      ChainId.grip => {Focus.forearms},
      ChainId.pull => {Focus.back, Focus.biceps, Focus.forearms},
      ChainId.dip => {Focus.chest, Focus.triceps},
      ChainId.push => {Focus.chest, Focus.triceps, Focus.shoulders},
      _ => switch (muscleGroup) {
        MuscleGroup.chest => {Focus.chest, Focus.triceps},
        MuscleGroup.back => {Focus.back, Focus.biceps},
        MuscleGroup.shoulders => {Focus.shoulders},
        MuscleGroup.legs => {Focus.legs, Focus.glutes},
        MuscleGroup.core => {Focus.core},
        MuscleGroup.fullBody => {Focus.cardio},
      },
    };
  }

  /// Difficoltà da 1 a 4.
  int get difficulty =>
      level ?? (chain.isProgression ? (1 + position ~/ 2).clamp(1, 4) : 1);

  /// Tempo stimato di una serie, per calcolare la durata della sessione.
  int get estimatedSetSeconds => switch (measure) {
    Measure.seconds => range.max,
    Measure.reps => range.max * 3 * (perSide ? 2 : 1),
  };

  /// "8–12 rip." oppure "30–60 s", con "per lato" se serve.
  String get targetLabel =>
      '$range ${measure.short}${perSide ? ' per lato' : ''}';
}
