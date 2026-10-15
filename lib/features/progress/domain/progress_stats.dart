// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../../../core/utils/local_date.dart';
import '../../exercises/domain/catalog.dart';
import '../../exercises/domain/exercise.dart';
import '../../exercises/domain/progression.dart';

/// Una serie salvata, ridotta a ciò che serve alle statistiche.
typedef SetRecord = ({
  LocalDate date,
  String exerciseId,
  ChainId chain,
  int value,
});

enum ProgressPeriod {
  week('Settimana', 'ultima sessione'),
  month('Mese', 'ultima settimana'),
  year('Anno', 'ultimo mese');

  const ProgressPeriod(this.label, this.lastLabel);

  final String label;

  /// "Ripetizioni, ultima sessione".
  final String lastLabel;
}

@immutable
class ChartBar {
  const ChartBar({
    required this.label,
    required this.value,
    required this.start,
    this.current = false,
  });

  final String label;
  final int value;
  final LocalDate start;

  /// Periodo in corso (oggi, questa settimana, questo mese): colore chiaro.
  final bool current;
}

const _months = [
  'gen',
  'feb',
  'mar',
  'apr',
  'mag',
  'giu',
  'lug',
  'ago',
  'set',
  'ott',
  'nov',
  'dic',
];

/// Ripetizioni (solo esercizi a ripetizioni) raggruppate per periodo.
///
/// - Settimana: le ultime sessioni (fino a 8 giorni di allenamento negli
///   ultimi 14 giorni), più oggi.
/// - Mese: le ultime 8 settimane.
/// - Anno: gli ultimi 12 mesi.
List<ChartBar> repsChart(
  List<SetRecord> sets,
  ProgressPeriod period,
  LocalDate today,
) {
  final reps = sets.where(
    (s) => Catalog.byId(s.exerciseId)?.measure != Measure.seconds,
  );
  switch (period) {
    case ProgressPeriod.week:
      final from = today.addDays(-13);
      final byDay = <LocalDate, int>{};
      for (final s in reps) {
        if (s.date.isBefore(from) || s.date.isAfter(today)) continue;
        byDay[s.date] = (byDay[s.date] ?? 0) + s.value;
      }
      final days = byDay.keys.where((d) => d != today).toList()..sort();
      final shown = days.length > 7 ? days.sublist(days.length - 7) : days;
      return [
        for (final d in shown)
          ChartBar(label: '${d.day}/${d.month}', value: byDay[d]!, start: d),
        if (byDay.containsKey(today))
          ChartBar(
            label: 'oggi',
            value: byDay[today]!,
            start: today,
            current: true,
          ),
      ];
    case ProgressPeriod.month:
      final thisWeek = today.startOfWeek;
      final starts = [for (var i = 7; i >= 0; i--) thisWeek.addDays(-7 * i)];
      return [
        for (final start in starts)
          ChartBar(
            label: start == thisWeek ? 'ora' : '${start.day}/${start.month}',
            value: reps
                .where(
                  (s) =>
                      !s.date.isBefore(start) &&
                      s.date.isBefore(start.addDays(7)),
                )
                .fold(0, (a, s) => a + s.value),
            start: start,
            current: start == thisWeek,
          ),
      ];
    case ProgressPeriod.year:
      final starts = [
        for (var i = 11; i >= 0; i--)
          LocalDate(today.year, today.month - i, 1).normalized,
      ];
      return [
        for (final start in starts)
          ChartBar(
            label: _months[start.month - 1],
            value: reps
                .where(
                  (s) =>
                      s.date.year == start.year && s.date.month == start.month,
                )
                .fold(0, (a, s) => a + s.value),
            start: start,
            current: start.year == today.year && start.month == today.month,
          ),
      ];
  }
}

/// Variazione percentuale tra la prima e l'ultima barra completa (non in
/// corso) con un valore; null se non ci sono abbastanza dati.
({int percent, String since})? repsTrend(List<ChartBar> bars) {
  final done = bars.where((b) => !b.current && b.value > 0).toList();
  if (done.length < 2) return null;
  final first = done.first;
  final last = done.last;
  return (
    percent: ((last.value - first.value) / first.value * 100).round(),
    since: first.label,
  );
}

/// Ultimo periodo completo con un valore (per il numero grande).
int lastCompleteValue(List<ChartBar> bars) {
  final done = bars.where((b) => !b.current && b.value > 0);
  return done.isEmpty ? 0 : done.last.value;
}

/// Push-up (tutte le varianti) nel mese di [today].
int pushUpsInMonth(List<SetRecord> sets, LocalDate today) => sets
    .where(
      (s) =>
          s.chain == ChainId.push &&
          s.date.year == today.year &&
          s.date.month == today.month,
    )
    .fold(0, (a, s) => a + s.value);

/// Massimo di trazioni vere (dalla variante "Trazioni" in su) in una serie,
/// oppure il test iniziale se è più alto.
int maxPullUps(List<SetRecord> sets, {int fromTest = 0}) {
  final realPullUp = Catalog.byId('pull_up')!.position;
  return sets
      .where(
        (s) =>
            s.chain == ChainId.pull &&
            (Catalog.byId(s.exerciseId)?.position ?? 0) >= realPullUp,
      )
      .fold(fromTest, (a, s) => math.max(a, s.value));
}

/// Plank più lungo (secondi), oppure il test iniziale se è più alto.
int maxPlankSeconds(List<SetRecord> sets, {int fromTest = 0}) => sets
    .where((s) => s.exerciseId == 'core_plank')
    .fold(fromTest, (a, s) => math.max(a, s.value));

/// Un'abilità sbloccata: una variante raggiunta in una catena.
@immutable
class UnlockedSkill {
  const UnlockedSkill({
    required this.exercise,
    required this.since,
    required this.best,
  });

  final Exercise exercise;
  final LocalDate since;

  /// Miglior serie fatta con questa variante.
  final int best;
}

/// Varianti raggiunte dopo il punto di partenza ([start]), dalla più
/// recente. Le catene ferme alla variante iniziale non compaiono.
List<UnlockedSkill> unlockedSkills(
  Map<ChainId, ChainProgress> chains,
  List<SetRecord> sets,
  LocalDate start,
) {
  final result = [
    for (final p in chains.values)
      // Solo varianti più difficili di quella di partenza: tornare a una
      // più facile o cambiare il profilo non è una conquista.
      if (p.since.isAfter(start) && p.position > p.start)
        UnlockedSkill(
          exercise: p.exercise,
          since: p.since,
          best: sets
              .where((s) => s.exerciseId == p.exercise.id)
              .fold(0, (a, s) => math.max(a, s.value)),
        ),
  ]..sort((a, b) => b.since.compareTo(a.since));
  return result;
}

/// Numero di varianti conquistate in tutte le catene (le precedenti
/// all'attuale contano come superate).
int variantsReached(Map<ChainId, ChainProgress> chains) =>
    chains.values.fold(0, (a, p) => a + p.position + 1);
