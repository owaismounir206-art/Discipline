// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:meta/meta.dart';

import '../../exercises/domain/catalog.dart';
import '../../exercises/domain/exercise.dart';

/// Le fasi del timer, ognuna con il suo colore.
enum Phase { prepare, work, rest }

/// Il tipo di timer scelto dall'utente.
enum IntervalKind {
  tabata('Tabata'),
  emom('EMOM'),
  amrap('AMRAP'),
  custom('Libero'),
  warmUp('Riscaldamento'),
  coolDown('Defaticamento'),
  quick('Allenamento rapido'),

  /// Circuito con esercizi scelti (allenamenti specifici, skill, scheda).
  circuit('Circuito');

  const IntervalKind(this.label);

  final String label;

  bool get isRoutine => index >= warmUp.index;
}

@immutable
class IntervalStep {
  const IntervalStep(this.phase, this.seconds, this.label, {this.exercise});

  final Phase phase;
  final int seconds;
  final String label;

  /// L'esercizio da fare (solo per le routine).
  final Exercise? exercise;
}

/// Impostazioni del timer: lavoro, pausa, giri o minuti.
@immutable
class IntervalConfig {
  const IntervalConfig({
    required this.kind,
    this.work = 20,
    this.rest = 10,
    this.rounds = 8,
    this.minutes = 10,
    this.seed = 0,
    this.ids = const [],
    this.title,
  });

  /// Circuito con questi esercizi, [rounds] giri di [work] secondi.
  const IntervalConfig.circuit(
    this.ids, {
    required this.title,
    this.work = 40,
    this.rest = 20,
    this.rounds = 2,
  }) : kind = IntervalKind.circuit,
       minutes = 10,
       seed = 0;

  const IntervalConfig.of(IntervalKind kind, {int seed = 0})
    : this(
        kind: kind,
        work: kind == IntervalKind.custom ? 40 : 20,
        rest: kind == IntervalKind.custom ? 20 : 10,
        rounds: 8,
        minutes: kind == IntervalKind.emom ? 10 : 12,
        seed: seed,
      );

  final IntervalKind kind;
  final int work;
  final int rest;
  final int rounds;
  final int minutes;

  /// Sceglie gli esercizi dell'allenamento rapido (cambia ogni giorno).
  final int seed;

  /// Esercizi del circuito.
  final List<String> ids;

  /// Nome mostrato al posto del tipo (es. "Bicipiti").
  final String? title;

  String get label => title ?? kind.label;

  IntervalConfig copyWith({int? work, int? rest, int? rounds, int? minutes}) =>
      IntervalConfig(
        kind: kind,
        work: (work ?? this.work).clamp(5, 300),
        rest: (rest ?? this.rest).clamp(0, 300),
        rounds: (rounds ?? this.rounds).clamp(1, 50),
        minutes: (minutes ?? this.minutes).clamp(1, 60),
        seed: seed,
        ids: ids,
        title: title,
      );

  /// Parametri per l'indirizzo della schermata.
  Map<String, String> toQuery() => {
    'tipo': kind.name,
    'lavoro': '$work',
    'pausa': '$rest',
    'giri': '$rounds',
    'minuti': '$minutes',
    'seme': '$seed',
    if (ids.isNotEmpty) 'esercizi': ids.join(','),
    'titolo': ?title,
  };

  static IntervalConfig fromQuery(Map<String, String> q) {
    final kind =
        IntervalKind.values.asNameMap()[q['tipo']] ?? IntervalKind.tabata;
    final base = IntervalConfig.of(
      kind,
      seed: int.tryParse(q['seme'] ?? '') ?? 0,
    );
    final ids = [
      for (final id in (q['esercizi'] ?? '').split(','))
        if (id.isNotEmpty) id,
    ];
    final title = q['titolo'];
    return IntervalConfig(
      kind: base.kind,
      work: base.work,
      rest: base.rest,
      rounds: kind == IntervalKind.circuit ? 2 : base.rounds,
      minutes: base.minutes,
      seed: base.seed,
      ids: ids,
      title: title == null || title.isEmpty ? null : title,
    ).copyWith(
      work: int.tryParse(q['lavoro'] ?? ''),
      rest: int.tryParse(q['pausa'] ?? ''),
      rounds: int.tryParse(q['giri'] ?? ''),
      minutes: int.tryParse(q['minuti'] ?? ''),
    );
  }
}

/// Tempo di preparazione prima di partire.
const prepareSeconds = 10;

/// Esercizi delle routine.
const _warmUp = [
  'mob_arm_circles',
  'mob_hip_circles',
  'mob_cat_cow',
  'cardio_jumping_jack',
  'mob_deep_squat',
  'acc_scap_pull',
  'cardio_high_knees',
];

const _coolDown = [
  'mob_child_pose',
  'mob_cobra',
  'mob_pike_stretch',
  'mob_couch',
  'mob_thoracic',
  'mob_deep_squat',
];

const _quickPool = [
  'cardio_jumping_jack',
  'cardio_squat_jump',
  'cardio_mountain_climber',
  'acc_glute_bridge',
  'cardio_high_knees',
  'acc_shoulder_taps',
  'acc_reverse_lunge',
  'cardio_skater',
  'acc_hindu_pushup',
  'acc_side_plank',
  'cardio_burpee',
  'acc_dead_bug',
];

/// I passi di un timer, dalla preparazione all'ultimo giro.
List<IntervalStep> buildSteps(IntervalConfig c) {
  final steps = <IntervalStep>[
    const IntervalStep(Phase.prepare, prepareSeconds, 'Preparati'),
  ];

  void routine(List<String> ids, int work, int rest) {
    for (final (i, id) in ids.indexed) {
      final e = Catalog.byId(id);
      if (e == null) continue;
      final label = e.perSide ? '${e.name} · cambia lato a metà' : e.name;
      steps.add(IntervalStep(Phase.work, work, label, exercise: e));
      if (rest > 0 && i < ids.length - 1) {
        steps.add(IntervalStep(Phase.rest, rest, 'Recupera'));
      }
    }
  }

  switch (c.kind) {
    case IntervalKind.tabata:
    case IntervalKind.custom:
      for (var r = 1; r <= c.rounds; r++) {
        steps.add(IntervalStep(Phase.work, c.work, 'Lavora'));
        if (c.rest > 0 && r < c.rounds) {
          steps.add(IntervalStep(Phase.rest, c.rest, 'Recupera'));
        }
      }
    case IntervalKind.emom:
      for (var m = 1; m <= c.minutes; m++) {
        steps.add(IntervalStep(Phase.work, 60, 'Minuto $m'));
      }
    case IntervalKind.amrap:
      steps.add(IntervalStep(Phase.work, c.minutes * 60, 'Più giri possibili'));
    case IntervalKind.warmUp:
      routine(_warmUp, 40, 0);
    case IntervalKind.coolDown:
      routine(_coolDown, 45, 0);
    case IntervalKind.circuit:
      for (var r = 1; r <= c.rounds; r++) {
        if (r > 1)
          steps.add(IntervalStep(Phase.rest, 30, 'Pronto per il giro $r'));
        routine(c.ids, c.work, c.rest);
      }
    case IntervalKind.quick:
      // 10 esercizi, 40" di lavoro e 20" di recupero: 10 minuti.
      final start = (c.seed * 5) % _quickPool.length;
      routine(
        [
          for (var i = 0; i < 10; i++)
            _quickPool[(start + i) % _quickPool.length],
        ],
        40,
        20,
      );
  }
  return steps;
}

int totalSeconds(List<IntervalStep> steps) =>
    steps.fold(0, (sum, s) => sum + s.seconds);

/// Dove si trova il timer dopo [elapsed] secondi (pause escluse).
@immutable
class TimerPosition {
  const TimerPosition({
    required this.index,
    required this.remaining,
    required this.progress,
    required this.done,
  });

  /// Passo attuale.
  final int index;

  /// Secondi che mancano alla fine del passo (arrotondati per eccesso).
  final int remaining;

  /// Avanzamento del passo, da 0 a 1.
  final double progress;

  final bool done;
}

TimerPosition positionAt(List<IntervalStep> steps, Duration elapsed) {
  var left = elapsed.inMilliseconds;
  for (final (i, s) in steps.indexed) {
    final ms = s.seconds * 1000;
    if (left < ms) {
      return TimerPosition(
        index: i,
        remaining: ((ms - left) / 1000).ceil(),
        progress: left / ms,
        done: false,
      );
    }
    left -= ms;
  }
  return TimerPosition(
    index: steps.length - 1,
    remaining: 0,
    progress: 1,
    done: true,
  );
}

/// Inizio (in secondi) del passo [index].
int startOf(List<IntervalStep> steps, int index) =>
    totalSeconds(steps.sublist(0, index));

/// "Giro 3 di 8": conta i passi di lavoro.
(int, int) roundOf(List<IntervalStep> steps, int index) {
  final works = [
    for (final (i, s) in steps.indexed)
      if (s.phase == Phase.work) i,
  ];
  final done = works.where((i) => i <= index).length;
  return (done.clamp(1, works.length), works.length);
}

String clock(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
