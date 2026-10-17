// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../../../core/data/providers.dart';
import '../../../core/utils/local_date.dart';
import '../../exercises/domain/catalog.dart';
import '../../exercises/domain/exercise.dart';
import '../../exercises/domain/progression.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/athlete_profile.dart';
import '../../rewards/data/rewards_repository.dart';
import '../../rewards/domain/rewards.dart';
import '../../streak/domain/streak.dart';
import '../domain/workout_plan.dart';
import 'session_feedback.dart';
import 'today_plan.dart';
import 'workout_repository.dart';

/// Un esercizio della sessione con le serie fatte.
@immutable
class SessionExercise {
  const SessionExercise({
    required this.planned,
    required this.exercise,
    this.done = const [],
  });

  final PlannedExercise planned;

  /// Variante in uso (può cambiare con "Più facile" / "Più difficile").
  final Exercise exercise;

  /// Serie fatte: variante usata e valore.
  final List<({String exerciseId, int value})> done;

  int get setsDone => done.length;
  bool get complete => setsDone >= planned.sets;

  SessionExercise copyWith({
    Exercise? exercise,
    List<({String exerciseId, int value})>? done,
  }) => SessionExercise(
    planned: planned,
    exercise: exercise ?? this.exercise,
    done: done ?? this.done,
  );
}

enum TimerMode {
  /// Pronto per la serie.
  ready,

  /// Recupero tra le serie.
  rest,

  /// Tenuta in corso (esercizi a tempo).
  hold,
}

@immutable
class SessionState {
  const SessionState({
    required this.template,
    required this.difficulty,
    required this.exercises,
    required this.index,
    required this.value,
    required this.startedAt,
    required this.elapsed,
    this.sessionId,
    this.mode = TimerMode.ready,
    this.timerTotal = 0,
    this.timerSeconds = 0,
    this.finished = false,
    this.suggestions = const [],
    this.pointsEarned = 0,
  });

  final WorkoutTemplate template;
  final Difficulty difficulty;
  final List<SessionExercise> exercises;

  /// Esercizio attuale.
  final int index;

  /// Valore della serie in corso (ripetizioni o secondi).
  final int value;

  final DateTime startedAt;

  /// Secondi trascorsi dall'inizio.
  final int elapsed;
  final int? sessionId;

  final TimerMode mode;

  /// Durata del recupero (in [TimerMode.rest]).
  final int timerTotal;

  /// Secondi rimanenti di recupero, o secondi di tenuta.
  final int timerSeconds;

  final bool finished;

  /// Proposte di progressione calcolate alla fine.
  final List<ProgressionSuggestion> suggestions;

  /// Punti guadagnati con questo allenamento (calcolati alla fine).
  final int pointsEarned;

  SessionExercise get current => exercises[index];

  SessionExercise? get next =>
      index + 1 < exercises.length ? exercises[index + 1] : null;

  int get plannedSets => exercises.fold(0, (s, e) => s + e.planned.sets);

  int get completedSets => exercises.fold(0, (s, e) => s + e.setsDone);

  double get progress => plannedSets == 0 ? 0 : completedSets / plannedSets;

  int get totalReps => exercises.fold(
    0,
    (s, e) =>
        s +
        (e.exercise.measure == Measure.reps
            ? e.done.fold(0, (a, d) => a + d.value)
            : 0),
  );

  SessionState copyWith({
    List<SessionExercise>? exercises,
    int? index,
    int? value,
    int? elapsed,
    int? sessionId,
    TimerMode? mode,
    int? timerTotal,
    int? timerSeconds,
    bool? finished,
    List<ProgressionSuggestion>? suggestions,
    int? pointsEarned,
  }) => SessionState(
    template: template,
    difficulty: difficulty,
    exercises: exercises ?? this.exercises,
    index: index ?? this.index,
    value: value ?? this.value,
    startedAt: startedAt,
    elapsed: elapsed ?? this.elapsed,
    sessionId: sessionId ?? this.sessionId,
    mode: mode ?? this.mode,
    timerTotal: timerTotal ?? this.timerTotal,
    timerSeconds: timerSeconds ?? this.timerSeconds,
    finished: finished ?? this.finished,
    suggestions: suggestions ?? this.suggestions,
    pointsEarned: pointsEarned ?? this.pointsEarned,
  );
}

/// Valore iniziale proposto per una serie: il massimo dell'intervallo per
/// le ripetizioni (si abbassa se serve), zero per le tenute.
int defaultValue(Exercise e) => e.measure == Measure.reps ? e.range.max : 0;

class SessionController extends Notifier<SessionState?> {
  Timer? _ticker;

  /// Una serie si sta salvando: un secondo tocco non la registra due volte.
  bool _saving = false;
  bool _finishing = false;

  /// Quando l'app è andata in background: al ritorno si recuperano i
  /// secondi persi (il timer del telefono si ferma a schermo spento).
  DateTime? _pausedAt;
  AppLifecycleListener? _lifecycle;

  /// Lo schermo è tenuto acceso da questa sessione (va spento una volta
  /// sola: dopo, un'altra schermata può averlo riacceso per sé).
  bool _screenOn = false;

  SessionFeedback get _feedback => ref.read(sessionFeedbackProvider);
  WorkoutRepository get _repo => ref.read(workoutRepositoryProvider);
  DateTime _now() => ref.read(clockProvider)();

  @override
  SessionState? build() {
    final feedback = ref.read(sessionFeedbackProvider);
    ref.onDispose(() {
      _ticker?.cancel();
      _lifecycle?.dispose();
      if (_screenOn) unawaited(feedback.keepScreenOn(false));
    });
    return null;
  }

  void _watchLifecycle() {
    _lifecycle?.dispose();
    // In background il timer si ferma: al ritorno si recupera il tempo
    // passato una volta sola (prima veniva contato due volte se Android
    // teneva viva l'app).
    _lifecycle = AppLifecycleListener(
      onHide: () {
        _pausedAt = DateTime.now();
        _ticker?.cancel();
        _ticker = null;
      },
      onShow: () {
        final at = _pausedAt;
        _pausedAt = null;
        if (at == null) return;
        final s = state;
        if (s == null || s.finished) return;
        advance(DateTime.now().difference(at).inSeconds);
        _ticker?.cancel();
        _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
      },
    );
  }

  /// Fa passare [seconds] secondi in un colpo (ritorno dal background).
  void advance(int seconds) {
    for (var i = 0; i < seconds.clamp(0, 6 * 3600); i++) {
      final s = state;
      if (s == null || s.finished) return;
      tick();
    }
  }

  /// Avvia una sessione della scheda indicata con le varianti attuali.
  Future<void> start(WorkoutTemplate template) async {
    final repo = ref.read(profileRepositoryProvider);
    final profile = await repo.loadProfile();
    final chains = await repo.loadChains();
    // Uscito dalla schermata mentre si caricava: niente sessione.
    if (!ref.mounted || profile == null || chains.isEmpty) return;
    final plan = buildWorkout(
      template: template,
      positions: {for (final e in chains.entries) e.key: e.value.position},
      difficulty: profile.difficulty,
      place: profile.place,
    );
    final now = _now();
    final first = plan.exercises.first.exercise;
    state = SessionState(
      template: template,
      difficulty: profile.difficulty,
      exercises: [
        for (final p in plan.exercises)
          SessionExercise(planned: p, exercise: p.exercise),
      ],
      index: 0,
      value: defaultValue(first),
      startedAt: now,
      elapsed: 0,
    );
    final sessions = _repo;
    final id = await sessions.startSession(
      date: LocalDate.fromDateTime(now),
      template: template,
      plannedSets: plan.totalSets,
      now: now,
    );
    if (!ref.mounted) {
      await sessions.discardIfEmpty(id);
      return;
    }
    state = state?.copyWith(sessionId: id);
    _screenOn = true;
    await _feedback.keepScreenOn(true);
    // Uscito dalla schermata durante l'attesa: niente timer orfani.
    if (!ref.mounted) return;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    _watchLifecycle();
  }

  /// Avanza di un secondo (chiamato dal timer; pubblico per i test).
  void tick() {
    final s = state;
    if (s == null || s.finished) return;
    var next = s.copyWith(elapsed: s.elapsed + 1);
    switch (s.mode) {
      case TimerMode.rest:
        final left = s.timerSeconds - 1;
        if (left <= 0) {
          next = next.copyWith(mode: TimerMode.ready, timerSeconds: 0);
          unawaited(_feedback.restFinished());
        } else {
          next = next.copyWith(timerSeconds: left);
        }
      case TimerMode.hold:
        next = next.copyWith(
          timerSeconds: s.timerSeconds + 1,
          value: s.timerSeconds + 1,
        );
      case TimerMode.ready:
        break;
    }
    state = next;
  }

  void setValue(int value) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(value: value.clamp(0, 999));
  }

  void adjustRest(int seconds) {
    final s = state;
    if (s == null || s.mode != TimerMode.rest) return;
    final left = (s.timerSeconds + seconds).clamp(0, 600);
    state = left == 0
        ? s.copyWith(mode: TimerMode.ready, timerSeconds: 0)
        : s.copyWith(
            timerSeconds: left,
            timerTotal: (s.timerTotal + seconds).clamp(left, 600),
          );
  }

  void skipRest() {
    final s = state;
    if (s == null || s.mode != TimerMode.rest) return;
    state = s.copyWith(mode: TimerMode.ready, timerSeconds: 0);
  }

  /// Avvia o ferma il cronometro di una tenuta (plank, L-sit...).
  void toggleHold() {
    final s = state;
    if (s == null) return;
    if (s.mode == TimerMode.hold) {
      state = s.copyWith(mode: TimerMode.ready);
    } else {
      state = s.copyWith(mode: TimerMode.hold, timerSeconds: 0, value: 0);
    }
  }

  /// Passa alla variante più facile (−1) o più difficile (+1). Se
  /// l'esercizio non è di volume, la scelta diventa la tua variante attuale.
  Future<void> changeVariant(int delta) async {
    final s = state;
    if (s == null) return;
    final current = s.current;
    // I sostituti (es. rematore sotto il tavolo) stanno in liste di
    // esercizi vari, non in una progressione: niente "più facile".
    if (!current.exercise.chain.isProgression) return;
    final position = current.exercise.position + delta;
    if (position < 0 ||
        position > Catalog.lastPosition(current.exercise.chain)) {
      return;
    }
    final exercise = Catalog.at(current.exercise.chain, position);
    final exercises = [...s.exercises];
    exercises[s.index] = current.copyWith(exercise: exercise);
    // Se cambi variante durante una tenuta, la tenuta si ferma (la nuova
    // variante può essere a ripetizioni).
    final holding = s.mode == TimerMode.hold;
    state = s.copyWith(
      exercises: exercises,
      value: defaultValue(exercise),
      mode: holding ? TimerMode.ready : null,
      timerSeconds: holding ? 0 : null,
    );

    if (!current.planned.isVolume) {
      final repo = ref.read(profileRepositoryProvider);
      final chains = {...await repo.loadChains()};
      final progress = chains[exercise.chain];
      if (progress != null) {
        chains[exercise.chain] = changePosition(
          progress,
          position,
          LocalDate.fromDateTime(_now()),
        );
        await repo.saveChains(chains);
      }
    }
  }

  /// Registra la serie e avvia il recupero (o passa al prossimo esercizio).
  Future<void> completeSet() async {
    if (_saving) return;
    _saving = true;
    try {
      await _completeSet();
    } finally {
      _saving = false;
    }
  }

  Future<void> _completeSet() async {
    final s = state;
    if (s == null || s.finished) return;
    final current = s.current;
    final value = s.value;
    final updated = current.copyWith(
      done: [...current.done, (exerciseId: current.exercise.id, value: value)],
    );
    final exercises = [...s.exercises]..[s.index] = updated;
    final completed = exercises.fold(0, (a, e) => a + e.setsDone);
    unawaited(_feedback.setDone());
    if (s.sessionId != null) {
      await _repo.logSet(
        sessionId: s.sessionId!,
        exercise: current.exercise,
        value: value,
        isVolume: current.planned.isVolume,
        completedSets: completed,
        now: _now(),
      );
    }

    if (!ref.mounted) return;
    // Il timer è andato avanti durante il salvataggio: si parte dallo stato
    // attuale per non perdere secondi.
    final latest = state ?? s;
    var index = s.index;
    if (updated.complete) {
      index = exercises.indexWhere((e) => !e.complete);
      if (index == -1) {
        state = latest.copyWith(exercises: exercises);
        await finish();
        return;
      }
    }
    final next = exercises[index].exercise;
    final rest = current.planned.restSeconds;
    state = latest.copyWith(
      exercises: exercises,
      index: index,
      value: index == s.index && next.measure == Measure.reps
          ? value
          : defaultValue(next),
      mode: TimerMode.rest,
      timerTotal: rest,
      timerSeconds: rest,
    );
  }

  /// Salta l'esercizio attuale.
  Future<void> skipExercise() async {
    final s = state;
    if (s == null) return;
    var index = -1;
    for (var i = 1; i <= s.exercises.length; i++) {
      final candidate = (s.index + i) % s.exercises.length;
      if (candidate != s.index && !s.exercises[candidate].complete) {
        index = candidate;
        break;
      }
    }
    if (index == -1) {
      await finish();
      return;
    }
    state = s.copyWith(
      index: index,
      value: defaultValue(s.exercises[index].exercise),
      mode: TimerMode.ready,
      timerSeconds: 0,
    );
  }

  /// Punti dell'allenamento: base, serie di allenamenti e nuovi record.
  Future<int> _award(SessionState s, DateTime now, LocalDate today) async {
    final rewards = ref.read(rewardsRepositoryProvider);
    final id = s.sessionId!;
    var total = 0;
    Future<void> give(
      PointKind kind,
      int amount,
      String ref, [
      String? note,
    ]) async {
      if (await rewards.award(kind, amount, at: now, ref: ref, note: note)) {
        total += amount;
      }
    }

    final done = s.progress >= doneThreshold - 1e-9;
    // I punti base valgono per un allenamento vero (almeno l'80%), una volta
    // al giorno: iniziare e chiudere subito più volte non dà punti.
    if (done) {
      await give(PointKind.workout, pointsWorkout, 'allenamento-${today.key}');
    }

    // La serie conta solo se l'allenamento del giorno è programmato e fatto.
    // Lo stato può essere già "fatto": le serie si salvano una alla volta e
    // la streak si aggiorna prima della fine della sessione.
    // Calcolata dal database (non dalla cache): così è aggiornata con
    // l'ultima serie salvata anche se la schermata "Oggi" non è aperta.
    final streak = computeStreak(
      schedule: await ref.read(profileRepositoryProvider).loadSchedule(),
      completions: await _repo.watchCompletions().first,
      today: today,
      protectedDays: await rewards.protectedDays(),
    );
    final status = streak.statuses[today];
    if (done && (status == DayStatus.today || status == DayStatus.done)) {
      await give(
        PointKind.streak,
        streakBonus(
          status == DayStatus.done ? streak.current : streak.current + 1,
        ),
        'serie-${today.key}',
      );
    }

    final best = await _repo.bestBefore(id);
    for (final e in s.exercises) {
      final values = [
        for (final d in e.done)
          if (d.exerciseId == e.exercise.id) d.value,
      ];
      if (values.isEmpty) continue;
      final top = values.reduce((a, b) => a > b ? a : b);
      final before = best[e.exercise.id] ?? 0;
      if (before > 0 && top > before) {
        await give(
          PointKind.record,
          pointsRecord,
          'record-$id-${e.exercise.id}',
          e.exercise.name,
        );
      }
    }
    return total;
  }

  /// Chiude la sessione: salva, aggiorna la progressione e calcola le
  /// proposte di cambio variante.
  Future<void> finish() async {
    final s = state;
    if (s == null || s.finished || _finishing) return;
    _finishing = true;
    _ticker?.cancel();
    _lifecycle?.dispose();
    _lifecycle = null;
    _screenOn = false;
    await _feedback.keepScreenOn(false);
    final now = _now();
    // Il giorno dell'allenamento è quello in cui è iniziato (anche se finisce
    // dopo mezzanotte).
    final today = LocalDate.fromDateTime(s.startedAt);

    var points = 0;
    if (s.sessionId != null) {
      if (s.completedSets == 0) {
        await _repo.discardIfEmpty(s.sessionId!);
      } else {
        await _repo.finishSession(s.sessionId!, now);
        points = await _award(s, now, today);
      }
    }

    final repo = ref.read(profileRepositoryProvider);
    final chains = {...await repo.loadChains()};
    for (final e in s.exercises) {
      if (e.planned.isVolume) continue;
      final progress = chains[e.exercise.chain];
      if (progress == null) continue;
      final sets = [
        for (final d in e.done)
          if (d.exerciseId == progress.exercise.id) d.value,
      ];
      chains[e.exercise.chain] = recordSession(
        progress,
        sets,
        planned: e.planned.sets,
      );
    }
    await repo.saveChains(chains);

    final profile = await repo.loadProfile();
    if (!ref.mounted) return;
    if (s.completedSets > 0) {
      unawaited(_feedback.finished(completed: s.progress >= 0.8 - 1e-9));
    }
    state = s.copyWith(
      finished: true,
      pointsEarned: points,
      mode: TimerMode.ready,
      suggestions: profile == null
          ? const []
          : [
              for (final p in chains.values)
                ?suggestChange(p, profile.experience, today),
            ],
    );
    ref.invalidate(todayProvider);
  }
}

final sessionControllerProvider =
    NotifierProvider.autoDispose<SessionController, SessionState?>(
      SessionController.new,
    );
