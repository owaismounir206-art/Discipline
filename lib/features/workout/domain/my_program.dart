// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:meta/meta.dart';

import '../../exercises/domain/catalog.dart';
import '../../exercises/domain/exercise.dart';
import 'workout_plan.dart';

/// Un esercizio della tua scheda.
@immutable
class ProgramExercise {
  const ProgramExercise({
    required this.id,
    required this.sets,
    required this.target,
    required this.rest,
    this.original,
  });

  factory ProgramExercise.fromJson(Map<String, Object?> j) => ProgramExercise(
    id: '${j['id']}',
    sets: _int(j['sets'], 3, 1, 10),
    target: _int(j['target'], 10, 1, 600),
    rest: _int(j['rest'], 90, 0, 600),
    original: j['original'] is String ? j['original']! as String : null,
  );

  /// Esercizio del catalogo.
  final String id;
  final int sets;

  /// Ripetizioni (o secondi per le tenute).
  final int target;

  /// Recupero in secondi.
  final int rest;

  /// Come si chiamava nella scheda scritta da te, se diverso.
  final String? original;

  Exercise? get exercise => Catalog.byId(id);

  Map<String, Object?> toJson() => {
    'id': id,
    'sets': sets,
    'target': target,
    'rest': rest,
    'original': ?original,
  };
}

/// Un giorno della scheda.
@immutable
class ProgramDay {
  const ProgramDay({required this.name, required this.exercises, this.weekday});

  factory ProgramDay.fromJson(Map<String, Object?> j) {
    final weekday = j['weekday'];
    return ProgramDay(
      name: '${j['name'] ?? 'Allenamento'}'.trim(),
      weekday: weekday is num && weekday >= 1 && weekday <= 7
          ? weekday.toInt()
          : null,
      exercises: [
        for (final e in (j['exercises'] as List?) ?? const [])
          if (e is Map<String, Object?>) ProgramExercise.fromJson(e),
      ].where((e) => e.exercise != null).toList(),
    );
  }

  final String name;

  /// Giorno della settimana (1 = lunedì), se la scheda lo dice.
  final int? weekday;
  final List<ProgramExercise> exercises;

  /// La sessione da fare: conta come allenamento, ma non cambia i tuoi
  /// percorsi (le varianti le decidi tu nella scheda).
  WorkoutPlan toPlan() => WorkoutPlan(
    template: WorkoutTemplate.fullBody,
    minutes:
        ((exercises.fold(
                          0,
                          (s, e) =>
                              s +
                              e.sets *
                                  (e.rest +
                                      (e.exercise!.measure == Measure.seconds
                                          ? e.target
                                          : e.target * 3)),
                        ) /
                        60 /
                        5)
                    .round() *
                5)
            .clamp(5, 180),
    exercises: [
      for (final e in exercises)
        PlannedExercise(
          exercise: e.exercise!,
          sets: e.sets,
          restSeconds: e.rest,
          isVolume: true,
          target: e.target,
        ),
    ],
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'weekday': ?weekday,
    'exercises': [for (final e in exercises) e.toJson()],
  };
}

/// La tua scheda, letta dall'AI da quello che hai scritto.
@immutable
class MyProgram {
  const MyProgram({
    required this.name,
    required this.days,
    this.notes = const [],
    this.source = '',
  });

  factory MyProgram.fromJson(Map<String, Object?> j) => MyProgram(
    name: '${j['name'] ?? 'La mia scheda'}'.trim(),
    days: [
      for (final d in (j['days'] as List?) ?? const [])
        if (d is Map<String, Object?>) ProgramDay.fromJson(d),
    ].where((d) => d.exercises.isNotEmpty).toList(),
    notes: [
      for (final n in (j['notes'] as List?) ?? const [])
        if ('$n'.trim().isNotEmpty) '$n'.trim(),
    ],
    source: j['source'] is String ? j['source']! as String : '',
  );

  final String name;
  final List<ProgramDay> days;

  /// Cose della scheda che l'app non può seguire (es. pesi), spiegate.
  final List<String> notes;

  /// Il testo che hai scritto (per modificarlo).
  final String source;

  /// Il giorno da fare oggi: quello del giorno della settimana, se c'è.
  ProgramDay? dayFor(int weekday) {
    for (final d in days) {
      if (d.weekday == weekday) return d;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'days': [for (final d in days) d.toJson()],
    'notes': notes,
    'source': source,
  };
}

int _int(Object? v, int fallback, int min, int max) {
  final n = v is num ? v.round() : int.tryParse('$v');
  return (n ?? fallback).clamp(min, max);
}

/// Legge la risposta dell'AI. Gli esercizi che non esistono si scartano.
MyProgram parseProgram(String reply, String source) {
  final start = reply.indexOf('{');
  final end = reply.lastIndexOf('}');
  Object? json;
  if (start >= 0 && end > start) {
    try {
      json = jsonDecode(reply.substring(start, end + 1));
    } on FormatException {
      json = null;
    }
  }
  if (json is! Map<String, Object?>) {
    throw const FormatException('Risposta dell\'AI non leggibile: riprova.');
  }
  final program = MyProgram.fromJson({...json, 'source': source});
  if (program.days.isEmpty) {
    throw const FormatException(
      'L\'AI non ha trovato esercizi nella scheda: scrivila con più dettagli.',
    );
  }
  return program;
}

/// L'elenco degli esercizi da dare all'AI: "id: nome (rip./s)".
String catalogForAi() => [
  for (final e in Catalog.all)
    '${e.id}: ${e.name}${e.measure == Measure.seconds ? ' (s)' : ''}',
].join('\n');
