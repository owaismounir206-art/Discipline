// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:meta/meta.dart';

import '../../../core/utils/local_date.dart';

/// Quota della sessione da completare perché il giorno conti come fatto.
const doneThreshold = 0.8;

/// Ogni quanti giorni è disponibile un giorno di recupero.
const recoveryEveryDays = 14;

/// Giorni di allenamento scelti, validi da una certa data in poi.
@immutable
class ScheduleChange {
  const ScheduleChange({required this.from, required this.days});

  final LocalDate from;

  /// Come [DateTime.weekday]: 1 = lunedì … 7 = domenica.
  final Set<int> days;

  Map<String, Object?> toJson() => {
    'from': from.key,
    'days': (days.toList()..sort()),
  };

  factory ScheduleChange.fromJson(Map<String, Object?> json) => ScheduleChange(
    from: LocalDate.parse(json['from']! as String),
    days: {for (final d in json['days']! as List<Object?>) (d! as num).toInt()},
  );
}

/// Aggiunge un cambio di giorni allo storico.
///
/// Il primo vale da oggi; i successivi da domani, così la streak attuale
/// resta e le nuove regole partono il giorno dopo.
List<ScheduleChange> addScheduleChange(
  List<ScheduleChange> history,
  Set<int> days,
  LocalDate today,
) {
  if (history.isNotEmpty && _sameDays(history.last.days, days)) return history;
  final from = history.isEmpty ? today : today.addDays(1);
  return [
    ...history.where((c) => c.from.isBefore(from)),
    ScheduleChange(from: from, days: {...days}),
  ];
}

bool _sameDays(Set<int> a, Set<int> b) =>
    a.length == b.length && a.containsAll(b);

/// Giorni programmati validi in una certa data (null prima dell'inizio).
Set<int>? daysOn(List<ScheduleChange> history, LocalDate date) {
  Set<int>? days;
  for (final change in history) {
    if (change.from.isAfter(date)) break;
    days = change.days;
  }
  return days;
}

enum DayStatus {
  /// Giorno programmato completato (almeno l'80%).
  done,

  /// Giorno programmato saltato: la streak si è azzerata.
  missed,

  /// Giorno programmato saltato ma salvato dal giorno di recupero.
  recovered,

  /// Giorno programmato saltato ma protetto da un giorno jolly.
  protected,

  /// Oggi è programmato e non è ancora fatto.
  today,

  /// Giorno programmato futuro.
  scheduled,

  /// Giorno di riposo.
  rest,

  /// Allenamento in un giorno di riposo: bonus, non aumenta la streak.
  bonus,
}

@immutable
class StreakResult {
  const StreakResult({
    required this.current,
    required this.best,
    required this.statuses,
    required this.recoveryAvailable,
    this.lastRecovery,
  });

  /// Allenamenti programmati di fila completati.
  final int current;

  /// Record personale.
  final int best;

  /// Stato di ogni giorno dall'inizio dello storico fino a oggi.
  final Map<LocalDate, DayStatus> statuses;

  /// Vero se un giorno saltato oggi o domani verrebbe recuperato.
  final bool recoveryAvailable;

  final LocalDate? lastRecovery;

  static const empty = StreakResult(
    current: 0,
    best: 0,
    statuses: {},
    recoveryAvailable: true,
  );
}

bool _recoveryReady(LocalDate? last, LocalDate day) =>
    last == null || day.daysSince(last) >= recoveryEveryDays;

/// Calcola la streak.
///
/// [completions] è la quota completata (0–1) per giorno, già il massimo
/// delle sessioni di quel giorno. [protectedDays] sono i giorni salvati con
/// un giorno jolly: non azzerano la serie e non la allungano.
StreakResult computeStreak({
  required List<ScheduleChange> schedule,
  required Map<LocalDate, double> completions,
  required LocalDate today,
  Set<LocalDate> protectedDays = const {},
}) {
  if (schedule.isEmpty || schedule.first.from.isAfter(today)) {
    return StreakResult.empty;
  }
  var current = 0;
  var best = 0;
  LocalDate? lastRecovery;
  final statuses = <LocalDate, DayStatus>{};

  for (
    var day = schedule.first.from;
    !day.isAfter(today);
    day = day.addDays(1)
  ) {
    final scheduled = daysOn(schedule, day)!.contains(day.weekday);
    final done = (completions[day] ?? 0) >= doneThreshold - 1e-9;

    if (!scheduled) {
      statuses[day] = done ? DayStatus.bonus : DayStatus.rest;
    } else if (done) {
      current++;
      if (current > best) best = current;
      statuses[day] = DayStatus.done;
    } else if (day == today) {
      statuses[day] = DayStatus.today;
    } else if (protectedDays.contains(day)) {
      statuses[day] = DayStatus.protected;
    } else if (current > 0 && _recoveryReady(lastRecovery, day)) {
      lastRecovery = day;
      statuses[day] = DayStatus.recovered;
    } else {
      current = 0;
      statuses[day] = DayStatus.missed;
    }
  }

  return StreakResult(
    current: current,
    best: best,
    statuses: statuses,
    recoveryAvailable: _recoveryReady(lastRecovery, today),
    lastRecovery: lastRecovery,
  );
}

/// Stato dei 7 giorni della settimana di [today] (da lunedì a domenica) per
/// la card della streak: i giorni futuri usano i giorni scelti più recenti.
List<(LocalDate, DayStatus)> weekStrip({
  required StreakResult streak,
  required List<ScheduleChange> schedule,
  required LocalDate today,
}) {
  final monday = today.startOfWeek;
  return [
    for (var i = 0; i < 7; i++)
      () {
        final day = monday.addDays(i);
        final known = streak.statuses[day];
        if (known != null) return (day, known);
        final days = daysOn(schedule, day) ?? schedule.lastOrNull?.days;
        final scheduled = days?.contains(day.weekday) ?? false;
        if (day.isAfter(today) && scheduled) return (day, DayStatus.scheduled);
        return (day, DayStatus.rest);
      }(),
  ];
}

/// Ultimo giorno programmato saltato che si può ancora proteggere con un
/// giorno jolly (entro [windowDays] giorni da oggi), se c'è.
LocalDate? freezableDay(
  StreakResult streak,
  LocalDate today, {
  int windowDays = 3,
}) {
  for (var i = 1; i <= windowDays; i++) {
    final day = today.addDays(-i);
    if (streak.statuses[day] == DayStatus.missed) return day;
  }
  return null;
}
