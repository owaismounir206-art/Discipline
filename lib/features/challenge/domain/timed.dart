// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Sfide a tempo di push-up, contro il cronometro, il tuo record o un amico.
enum TimedMode {
  minute('Un minuto', 'Più push-up possibili in 60 secondi'),
  race50('Gara a 50', 'Arriva a 50 push-up il prima possibile');

  const TimedMode(this.label, this.description);

  final String label;
  final String description;

  Duration get limit => this == TimedMode.minute
      ? const Duration(seconds: 60)
      : const Duration(minutes: 5);

  /// Obiettivo di ripetizioni (null = più possibile).
  int? get goal => this == TimedMode.race50 ? 50 : null;
}

/// Secondi di conto alla rovescia prima del via.
const countdownSeconds = 3;

enum TimedPhase { ready, countdown, running, finished }

/// Risultato di una sfida a tempo.
@immutable
class TimedResult {
  const TimedResult({
    required this.mode,
    required this.reps,
    required this.manual,
    required this.elapsed,
  });

  final TimedMode mode;
  final int reps;

  /// Di cui contate a mano (le altre dalla fotocamera).
  final int manual;
  final Duration elapsed;

  int get verified => reps - manual;

  /// Gara a 50 riuscita (sempre vero per il minuto).
  bool get completed => mode.goal == null || reps >= mode.goal!;

  /// Punteggio confrontabile: ripetizioni nel minuto, decimi di secondo
  /// nella gara a 50 (meno è meglio). Null se la gara non è finita.
  int? get score => switch (mode) {
    TimedMode.minute => reps,
    TimedMode.race50 =>
      completed ? math.max(1, (elapsed.inMilliseconds / 100).ceil()) : null,
  };

  /// "42 push-up" oppure "1:23,4".
  String get scoreLabel => switch (mode) {
    TimedMode.minute => '$reps push-up',
    TimedMode.race50 =>
      completed ? formatTenths(score!) : '$reps su 50, tempo scaduto',
  };
}

/// Vero se [a] è meglio di [b] per questa modalità.
bool isBetterScore(TimedMode mode, int a, int b) =>
    mode == TimedMode.minute ? a > b : a < b;

/// Testo di un punteggio: "42 push-up" o "1:23,4".
String scoreText(TimedMode mode, int score) =>
    mode == TimedMode.minute ? '$score push-up' : formatTenths(score);

/// Decimi di secondo → "1:23,4".
String formatTenths(int tenths) {
  final minutes = tenths ~/ 600;
  final seconds = (tenths % 600) ~/ 10;
  final t = tenths % 10;
  return '$minutes:${seconds.toString().padLeft(2, '0')},$t';
}

/// Lo stato di una sfida a tempo; la fase si calcola dall'ora corrente.
@immutable
class TimedRun {
  const TimedRun({
    required this.mode,
    this.startAt,
    this.reps = 0,
    this.manual = 0,
    this.endedAt,
  });

  final TimedMode mode;

  /// Ora del via (dopo il conto alla rovescia). Null = non ancora partita.
  final DateTime? startAt;
  final int reps;
  final int manual;

  /// Fine anticipata: obiettivo raggiunto o fermata a mano.
  final DateTime? endedAt;

  TimedPhase phaseAt(DateTime now) {
    final start = startAt;
    if (start == null) return TimedPhase.ready;
    if (now.isBefore(start)) return TimedPhase.countdown;
    if (endedAt != null) return TimedPhase.finished;
    if (!now.isBefore(start.add(mode.limit))) return TimedPhase.finished;
    return TimedPhase.running;
  }

  int countdownLeft(DateTime now) => startAt == null
      ? countdownSeconds
      : math.max(0, (startAt!.difference(now).inMilliseconds / 1000).ceil());

  Duration elapsedAt(DateTime now) {
    final start = startAt;
    if (start == null || now.isBefore(start)) return Duration.zero;
    final d = (endedAt ?? now).difference(start);
    return d > mode.limit ? mode.limit : d;
  }

  Duration remainingAt(DateTime now) => mode.limit - elapsedAt(now);

  TimedRun start(DateTime now) => TimedRun(
    mode: mode,
    startAt: now.add(const Duration(seconds: countdownSeconds)),
  );

  /// Un push-up in più (ignorato se la sfida non è in corso). Con la gara
  /// a 50 il cinquantesimo ferma il cronometro.
  TimedRun addRep(DateTime now, {required bool manual}) {
    if (phaseAt(now) != TimedPhase.running) return this;
    final next = reps + 1;
    return TimedRun(
      mode: mode,
      startAt: startAt,
      reps: next,
      manual: this.manual + (manual ? 1 : 0),
      endedAt: mode.goal != null && next >= mode.goal! ? now : null,
    );
  }

  TimedRun stop(DateTime now) => phaseAt(now) == TimedPhase.running
      ? TimedRun(
          mode: mode,
          startAt: startAt,
          reps: reps,
          manual: manual,
          endedAt: now,
        )
      : this;

  TimedResult resultAt(DateTime now) => TimedResult(
    mode: mode,
    reps: reps,
    manual: manual,
    elapsed: elapsedAt(now),
  );
}
