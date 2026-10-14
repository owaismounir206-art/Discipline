// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:meta/meta.dart';

import '../../profile/domain/athlete_profile.dart';
import 'catalog.dart';
import 'exercise.dart';
import 'progression.dart';

/// Soglie di punteggio (0–1) da cui inizia ogni livello.
const levelThresholds = {
  Difficulty.beginner: 0.0,
  Difficulty.intermediate: 0.25,
  Difficulty.advanced: 0.55,
  Difficulty.elite: 0.8,
};

/// Livello mostrato all'utente, calcolato dalle varianti raggiunte.
@immutable
class LevelInfo {
  const LevelInfo({
    required this.level,
    required this.score,
    required this.progressToNext,
    this.next,
    this.nextSkill,
  });

  final Difficulty level;

  /// Media (0–1) della posizione raggiunta nelle catene principali.
  final double score;

  /// Avanzamento (0–1) verso il livello successivo; 1 se sei al massimo.
  final double progressToNext;

  final Difficulty? next;

  /// Prossima variante da conquistare, es. «Push-up arciere».
  final Exercise? nextSkill;

  int get percent => (progressToNext * 100).round();
}

LevelInfo computeLevel(Map<ChainId, ChainProgress> progress) {
  final main = ChainId.values.where((c) => c.isMain);
  var total = 0.0;
  for (final chain in main) {
    final position = progress[chain]?.position ?? 0;
    total += position / Catalog.lastPosition(chain);
  }
  final score = total / main.length;

  var level = Difficulty.beginner;
  for (final MapEntry(key: d, value: from) in levelThresholds.entries) {
    if (score >= from - 1e-9) level = d;
  }
  final next = level == Difficulty.elite
      ? null
      : Difficulty.values[level.index + 1];
  final from = levelThresholds[level]!;
  final to = next == null ? 1.0 : levelThresholds[next]!;
  final progressToNext = next == null
      ? 1.0
      : ((score - from) / (to - from)).clamp(0.0, 1.0);

  return LevelInfo(
    level: level,
    score: score,
    progressToNext: progressToNext,
    next: next,
    nextSkill: _nextSkill(progress),
  );
}

/// La variante successiva della catena principale più vicina al salto:
/// prima quella con più sessioni al massimo, a parità la prima in elenco.
Exercise? _nextSkill(Map<ChainId, ChainProgress> progress) {
  ChainProgress? best;
  for (final chain in ChainId.values.where((c) => c.isMain)) {
    final p = progress[chain];
    if (p == null || p.isLast) continue;
    if (best == null || p.topStreak > best.topStreak) best = p;
  }
  return best == null ? null : Catalog.at(best.chain, best.position + 1);
}
