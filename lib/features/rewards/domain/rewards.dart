// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show Color, IconData, Icons;
import 'package:meta/meta.dart';

// --- Come si guadagnano i punti -------------------------------------------

/// Allenamento completato.
const pointsWorkout = 50;

/// Nuovo record personale in un esercizio.
const pointsRecord = 30;

/// Bonus per la serie: 5 punti per ogni allenamento di fila, fino a 50.
int streakBonus(int streak) => math.min(streak, 10) * 5;

/// Diario del cibo con almeno 3 pasti in un giorno.
const pointsDiary = 10;
const diaryMeals = 3;

/// Timer o routine portati a termine (una volta al giorno).
const pointsTimer = 15;

/// Sfida a tempo: un punto per push-up (1,5 se contato dalla fotocamera),
/// più 20 se batti il record o l'amico.
int timedPoints({
  required int manual,
  required int verified,
  required bool beatTarget,
}) => manual + (verified * 1.5).round() + (beatTarget ? 20 : 0);

/// Tipi di movimenti del salvadanaio.
enum PointKind {
  workout('Allenamento'),
  streak('Serie di allenamenti'),
  record('Nuovo record'),
  challenge('Sfida completata'),
  timed('Sfida a tempo'),
  diary('Diario completo'),
  timer('Timer completato'),
  freeze('Giorno jolly'),
  theme('Tema');

  const PointKind(this.label);

  final String label;
}

@immutable
class PointEntry {
  const PointEntry({
    required this.kind,
    required this.amount,
    required this.at,
    this.ref,
    this.note,
  });

  final PointKind kind;

  /// Positivo se guadagnati, negativo se spesi.
  final int amount;
  final DateTime at;

  /// Chiave unica per non dare due volte gli stessi punti.
  final String? ref;
  final String? note;
}

int balanceOf(Iterable<PointEntry> entries) =>
    entries.fold(0, (sum, e) => sum + e.amount);

/// Punti guadagnati in tutto (le spese non abbassano il grado).
int lifetimeOf(Iterable<PointEntry> entries) =>
    entries.where((e) => e.amount > 0).fold(0, (sum, e) => sum + e.amount);

// --- Gradi -----------------------------------------------------------------

enum Rank {
  rookie('Recluta', 0),
  steady('Costante', 500),
  athlete('Atleta', 1500),
  warrior('Guerriero', 4000),
  champion('Campione', 8000),
  legend('Leggenda', 15000);

  const Rank(this.label, this.from);

  final String label;

  /// Punti guadagnati necessari.
  final int from;
}

@immutable
class RankInfo {
  const RankInfo(this.rank, this.next, this.progress, this.missing);

  final Rank rank;
  final Rank? next;

  /// 0–1 verso il grado successivo.
  final double progress;

  /// Punti che mancano al grado successivo.
  final int missing;
}

RankInfo rankFor(int lifetime) {
  var rank = Rank.rookie;
  for (final r in Rank.values) {
    if (lifetime >= r.from) rank = r;
  }
  final next = rank.index + 1 < Rank.values.length
      ? Rank.values[rank.index + 1]
      : null;
  if (next == null) return RankInfo(rank, null, 1, 0);
  final span = next.from - rank.from;
  return RankInfo(
    rank,
    next,
    (lifetime - rank.from) / span,
    next.from - lifetime,
  );
}

// --- Negozio ---------------------------------------------------------------

/// Giorno jolly: protegge la serie quando salti un allenamento.
const freezeCost = 150;

/// Al massimo due di scorta: servono per gli imprevisti, non per saltare.
const maxFreezes = 2;

/// Il giorno jolly vale solo per un allenamento saltato negli ultimi giorni.
const freezeWindowDays = 3;

/// Colori dell'app da sbloccare.
enum AppPalette {
  coral('Corallo', Color(0xFF8F4C38), 0),
  ocean('Oceano', Color(0xFF00658E), 300),
  forest('Bosco', Color(0xFF3B6939), 300),
  lavender('Lavanda', Color(0xFF6750A4), 300),
  sunset('Tramonto', Color(0xFF9C4146), 300),
  sand('Sabbia', Color(0xFF7A5900), 300);

  const AppPalette(this.label, this.seed, this.cost);

  final String label;
  final Color seed;
  final int cost;

  bool get free => cost == 0;
}

// --- Achievement -----------------------------------------------------------------

/// Numeri dello storico da cui si calcolano i badge.
@immutable
class BadgeStats {
  const BadgeStats({
    this.workouts = 0,
    this.bestStreak = 0,
    this.pushUps = 0,
    this.challenges = 0,
    this.cameraReps = 0,
    this.bestMinute = 0,
    this.friendWins = 0,
  });

  final int workouts;
  final int bestStreak;
  final int pushUps;
  final int challenges;
  final int cameraReps;
  final int bestMinute;
  final int friendWins;
}

@immutable
class Achievement {
  const Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
    required this.goal,
  });

  final String title;
  final String description;
  final IconData icon;
  final int value;
  final int goal;

  bool get earned => value >= goal;
  double get progress => math.min(1, value / goal);
}

List<Achievement> achievementsFor(BadgeStats s) => [
  Achievement(
    title: 'Primo passo',
    description: 'Completa il primo allenamento',
    icon: Icons.flag_outlined,
    value: s.workouts,
    goal: 1,
  ),
  Achievement(
    title: 'Una settimana',
    description: '7 allenamenti di fila',
    icon: Icons.local_fire_department_outlined,
    value: s.bestStreak,
    goal: 7,
  ),
  Achievement(
    title: 'Un mese',
    description: '30 allenamenti di fila',
    icon: Icons.whatshot_outlined,
    value: s.bestStreak,
    goal: 30,
  ),
  Achievement(
    title: 'Mille',
    description: '1000 push-up in totale',
    icon: Icons.fitness_center,
    value: s.pushUps,
    goal: 1000,
  ),
  Achievement(
    title: 'Sfidante',
    description: '10 sfide completate',
    icon: Icons.emoji_events_outlined,
    value: s.challenges,
    goal: 10,
  ),
  Achievement(
    title: 'Occhio di falco',
    description: '100 ripetizioni contate dalla fotocamera',
    icon: Icons.videocam_outlined,
    value: s.cameraReps,
    goal: 100,
  ),
  Achievement(
    title: 'Mezzo centinaio',
    description: '50 push-up in un minuto',
    icon: Icons.timer_outlined,
    value: s.bestMinute,
    goal: 50,
  ),
  Achievement(
    title: 'Imbattibile',
    description: 'Vinci 5 sfide contro gli amici',
    icon: Icons.groups_outlined,
    value: s.friendWins,
    goal: 5,
  ),
];
