// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:meta/meta.dart';

/// Difficoltà scelta dall'utente.
enum Difficulty {
  beginner(
    label: 'Principiante',
    hint: '0–10 push-up di fila',
    sessionMinutes: 20,
    focus: 'Push-up sulle ginocchia, squat, plank',
  ),
  intermediate(
    label: 'Intermedio',
    hint: '10–30 push-up di fila',
    sessionMinutes: 35,
    focus: 'Push-up, dip, pike push-up, trazioni australiane',
  ),
  advanced(
    label: 'Avanzato',
    hint: '30+ push-up e trazioni',
    sessionMinutes: 45,
    focus: 'Push-up arciere, trazioni, L-sit',
  ),
  elite(
    label: 'Élite',
    hint: 'Planche, front lever',
    sessionMinutes: 60,
    focus: 'Handstand push-up, muscle-up, lever',
  );

  const Difficulty({
    required this.label,
    required this.hint,
    required this.sessionMinutes,
    required this.focus,
  });

  final String label;
  final String hint;

  /// Durata di una sessione.
  final int sessionMinutes;

  /// Esercizi tipici, mostrati nel riquadro "Il tuo programma".
  final String focus;
}

/// Da quanto tempo l'utente si allena: decide ogni quanto la difficoltà sale.
enum Experience {
  justStarted(label: 'Ho appena iniziato', checkEveryWeeks: 1),
  underThreeMonths(label: 'Meno di 3 mesi', checkEveryWeeks: 1),
  threeToTwelveMonths(label: '3–12 mesi', checkEveryWeeks: 2),
  oneToThreeYears(label: '1–3 anni', checkEveryWeeks: 3),
  overThreeYears(label: 'Più di 3 anni', checkEveryWeeks: 4);

  const Experience({required this.label, required this.checkEveryWeeks});

  final String label;

  /// Ogni quante settimane si può passare alla variante più difficile.
  final int checkEveryWeeks;

  /// "ogni settimana", "ogni 2 settimane", "ogni mese".
  String get progressionLabel => switch (checkEveryWeeks) {
    1 => 'ogni settimana',
    4 => 'ogni mese',
    final n => 'ogni $n settimane',
  };
}

/// Test iniziale: massimo di ripetizioni di fila e secondi di plank.
@immutable
class InitialTest {
  const InitialTest({
    required this.maxPushUps,
    required this.maxPullUps,
    required this.plankSeconds,
  });

  final int maxPushUps;
  final int maxPullUps;
  final int plankSeconds;

  Map<String, Object?> toJson() => {
    'pushUps': maxPushUps,
    'pullUps': maxPullUps,
    'plank': plankSeconds,
  };

  factory InitialTest.fromJson(Map<String, Object?> json) => InitialTest(
    maxPushUps: (json['pushUps'] as num?)?.toInt() ?? 0,
    maxPullUps: (json['pullUps'] as num?)?.toInt() ?? 0,
    plankSeconds: (json['plank'] as num?)?.toInt() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      other is InitialTest &&
      other.maxPushUps == maxPushUps &&
      other.maxPullUps == maxPullUps &&
      other.plankSeconds == plankSeconds;

  @override
  int get hashCode => Object.hash(maxPushUps, maxPullUps, plankSeconds);
}

/// Ora del promemoria (ore e minuti locali).
@immutable
class ReminderTime {
  const ReminderTime(this.hour, this.minute);

  final int hour;
  final int minute;

  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is ReminderTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

/// Profilo atleta: chi sei e quando ti alleni.
@immutable
class AthleteProfile {
  const AthleteProfile({
    this.name = '',
    required this.difficulty,
    required this.experience,
    required this.trainingDays,
    required this.test,
    this.reminder,
  });

  final String name;
  final Difficulty difficulty;
  final Experience experience;

  /// Giorni scelti, come [DateTime.weekday]: 1 = lunedì … 7 = domenica.
  final Set<int> trainingDays;

  final InitialTest test;

  /// Ora del promemoria nei giorni di allenamento; null = nessun promemoria.
  final ReminderTime? reminder;

  /// Iniziale del nome per l'avatar.
  String get initial => name.trim().isEmpty ? '' : name.trim()[0].toUpperCase();

  AthleteProfile copyWith({
    String? name,
    Difficulty? difficulty,
    Experience? experience,
    Set<int>? trainingDays,
    InitialTest? test,
    ReminderTime? reminder,
    bool clearReminder = false,
  }) => AthleteProfile(
    name: name ?? this.name,
    difficulty: difficulty ?? this.difficulty,
    experience: experience ?? this.experience,
    trainingDays: trainingDays ?? this.trainingDays,
    test: test ?? this.test,
    reminder: clearReminder ? null : reminder ?? this.reminder,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'difficulty': difficulty.name,
    'experience': experience.name,
    'days': (trainingDays.toList()..sort()),
    'test': test.toJson(),
    if (reminder != null) 'reminder': [reminder!.hour, reminder!.minute],
  };

  factory AthleteProfile.fromJson(Map<String, Object?> json) {
    final reminder = json['reminder'] as List<Object?>?;
    return AthleteProfile(
      name: json['name'] as String? ?? '',
      difficulty: Difficulty.values.byName(json['difficulty']! as String),
      experience: Experience.values.byName(json['experience']! as String),
      trainingDays: {
        for (final d in json['days']! as List<Object?>) (d! as num).toInt(),
      },
      test: InitialTest.fromJson(json['test']! as Map<String, Object?>),
      reminder: reminder == null
          ? null
          : ReminderTime(
              (reminder[0]! as num).toInt(),
              (reminder[1]! as num).toInt(),
            ),
    );
  }
}

/// Lettere dei giorni, da lunedì a domenica.
const weekdayLetters = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

/// Nomi completi dei giorni, da lunedì a domenica.
const weekdayNames = [
  'Lunedì',
  'Martedì',
  'Mercoledì',
  'Giovedì',
  'Venerdì',
  'Sabato',
  'Domenica',
];

/// "L · M · G · S" per i giorni scelti.
String trainingDaysLabel(Set<int> days) =>
    (days.toList()..sort()).map((d) => weekdayLetters[d - 1]).join(' · ');
