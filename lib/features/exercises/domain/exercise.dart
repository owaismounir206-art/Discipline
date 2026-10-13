// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:meta/meta.dart';

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
  skills('Skill', isMain: false);

  const ChainId(this.label, {required this.isMain});

  final String label;

  /// Le catene principali decidono il livello mostrato.
  final bool isMain;
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

  /// Tempo stimato di una serie, per calcolare la durata della sessione.
  int get estimatedSetSeconds => switch (measure) {
    Measure.seconds => range.max,
    Measure.reps => range.max * 3 * (perSide ? 2 : 1),
  };

  /// "8–12 rip." oppure "30–60 s", con "per lato" se serve.
  String get targetLabel =>
      '$range ${measure.short}${perSide ? ' per lato' : ''}';
}
