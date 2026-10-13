// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:meta/meta.dart';

import '../../../core/utils/local_date.dart';
import '../../profile/domain/athlete_profile.dart';
import 'catalog.dart';
import 'exercise.dart';

/// Stato della doppia progressione in una catena.
@immutable
class ChainProgress {
  const ChainProgress({
    required this.chain,
    required this.position,
    required this.since,
    this.topStreak = 0,
    this.belowStreak = 0,
  });

  final ChainId chain;

  /// Variante attuale nella catena.
  final int position;

  /// Giorno in cui si è passati a questa variante.
  final LocalDate since;

  /// Sessioni di fila con tutte le serie al massimo dell'intervallo.
  final int topStreak;

  /// Sessioni di fila sotto il minimo dell'intervallo.
  final int belowStreak;

  Exercise get exercise => Catalog.at(chain, position);

  bool get isLast => position >= Catalog.lastPosition(chain);

  ChainProgress copyWith({
    int? position,
    LocalDate? since,
    int? topStreak,
    int? belowStreak,
  }) => ChainProgress(
    chain: chain,
    position: position ?? this.position,
    since: since ?? this.since,
    topStreak: topStreak ?? this.topStreak,
    belowStreak: belowStreak ?? this.belowStreak,
  );

  Map<String, Object?> toJson() => {
    'position': position,
    'since': since.key,
    'top': topStreak,
    'below': belowStreak,
  };

  factory ChainProgress.fromJson(ChainId chain, Map<String, Object?> json) =>
      ChainProgress(
        chain: chain,
        position: (json['position']! as num).toInt().clamp(
          0,
          Catalog.lastPosition(chain),
        ),
        since: LocalDate.parse(json['since']! as String),
        topStreak: (json['top'] as num?)?.toInt() ?? 0,
        belowStreak: (json['below'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is ChainProgress &&
      other.chain == chain &&
      other.position == position &&
      other.since == since &&
      other.topStreak == topStreak &&
      other.belowStreak == belowStreak;

  @override
  int get hashCode =>
      Object.hash(chain, position, since, topStreak, belowStreak);
}

/// Sessioni di fila necessarie per proporre un cambio di variante.
const sessionsToChange = 2;

/// Esito di una sessione per un esercizio della catena.
enum SessionOutcome {
  /// Tutte le serie al massimo dell'intervallo.
  top,

  /// Media delle serie sotto il minimo.
  belowMin,

  /// Dentro l'intervallo.
  inRange,
}

/// Valuta le serie fatte rispetto all'intervallo dell'esercizio.
SessionOutcome evaluateSets(TargetRange range, List<int> sets) {
  if (sets.isEmpty) return SessionOutcome.belowMin;
  if (sets.every((v) => v >= range.max)) return SessionOutcome.top;
  final average = sets.reduce((a, b) => a + b) / sets.length;
  if (average < range.min) return SessionOutcome.belowMin;
  return SessionOutcome.inRange;
}

/// Aggiorna la catena dopo una sessione in cui si è usata la sua variante
/// attuale. Le serie fatte con altre varianti non contano.
ChainProgress recordSession(ChainProgress progress, List<int> sets) {
  if (sets.isEmpty) return progress;
  return switch (evaluateSets(progress.exercise.range, sets)) {
    SessionOutcome.top => progress.copyWith(
      topStreak: progress.topStreak + 1,
      belowStreak: 0,
    ),
    SessionOutcome.belowMin => progress.copyWith(
      topStreak: 0,
      belowStreak: progress.belowStreak + 1,
    ),
    SessionOutcome.inRange => progress.copyWith(topStreak: 0, belowStreak: 0),
  };
}

enum ChangeDirection { harder, easier }

/// Proposta di cambio variante da mostrare all'utente.
@immutable
class ProgressionSuggestion {
  const ProgressionSuggestion({
    required this.chain,
    required this.direction,
    required this.from,
    required this.to,
  });

  final ChainId chain;
  final ChangeDirection direction;
  final Exercise from;
  final Exercise to;

  String get message => switch (direction) {
    ChangeDirection.harder =>
      'Hai chiuso tutte le serie al massimo per $sessionsToChange sessioni '
          'di fila: prova «${to.name}».',
    ChangeDirection.easier =>
      'Per $sessionsToChange sessioni non sei arrivato al minimo: '
          'torna a «${to.name}» per costruire forza.',
  };
}

/// Decide se proporre una variante diversa.
///
/// - Più facile: subito dopo [sessionsToChange] sessioni sotto il minimo.
/// - Più difficile: dopo [sessionsToChange] sessioni al massimo, ma solo se
///   è passato il tempo di controllo legato all'esperienza (ogni 1, 2, 3 o
///   4 settimane dall'ultimo cambio).
ProgressionSuggestion? suggestChange(
  ChainProgress progress,
  Experience experience,
  LocalDate today,
) {
  if (progress.belowStreak >= sessionsToChange && progress.position > 0) {
    return ProgressionSuggestion(
      chain: progress.chain,
      direction: ChangeDirection.easier,
      from: progress.exercise,
      to: Catalog.at(progress.chain, progress.position - 1),
    );
  }
  final waited =
      today.daysSince(progress.since) >= experience.checkEveryWeeks * 7;
  if (progress.topStreak >= sessionsToChange && !progress.isLast && waited) {
    return ProgressionSuggestion(
      chain: progress.chain,
      direction: ChangeDirection.harder,
      from: progress.exercise,
      to: Catalog.at(progress.chain, progress.position + 1),
    );
  }
  return null;
}

/// Passa a un'altra variante (proposta accettata o scelta a mano).
ChainProgress changePosition(
  ChainProgress progress,
  int position,
  LocalDate today,
) => ChainProgress(
  chain: progress.chain,
  position: position.clamp(0, Catalog.lastPosition(progress.chain)),
  since: today,
);
