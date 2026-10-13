// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;

import 'package:meta/meta.dart';

enum ChallengeMode {
  headToHead('Testa a testa', 'Più push-up in 1 minuto'),
  raceTo50('Gara a 50', 'Vince chi arriva prima a 50'),
  team('Squadra', 'Insieme fino a 100 push-up');

  const ChallengeMode(this.label, this.description);

  final String label;
  final String description;

  /// Durata massima: 60 s per il testa a testa, 5 minuti per le altre.
  Duration get timeLimit => this == ChallengeMode.headToHead
      ? const Duration(seconds: 60)
      : const Duration(minutes: 5);

  /// Obiettivo di ripetizioni (null = vince chi ne fa di più).
  int? get goal => switch (this) {
    ChallengeMode.headToHead => null,
    ChallengeMode.raceTo50 => 50,
    ChallengeMode.team => 100,
  };
}

/// Secondi di conto alla rovescia prima del via.
const countdownSeconds = 3;

enum RoomPhase {
  /// In attesa che l'amico entri.
  waiting,

  /// 3, 2, 1...
  countdown,

  /// Sfida in corso.
  running,

  /// Finita (tempo scaduto, obiettivo raggiunto o annullata).
  finished,
}

/// La "stanza" condivisa di una sfida.
@immutable
class ChallengeRoom {
  const ChallengeRoom({
    required this.id,
    required this.mode,
    required this.hostId,
    required this.players,
    this.counts = const {},
    this.manual = const {},
    this.startAt,
    this.cancelled = false,
  });

  final String id;
  final ChallengeMode mode;
  final String hostId;

  /// Partecipanti: id → nome (l'host per primo).
  final Map<String, String> players;

  /// Ripetizioni per partecipante.
  final Map<String, int> counts;

  /// Di cui contate a mano con "+1".
  final Map<String, int> manual;

  /// Ora del via, decisa dal server (dopo il conto alla rovescia).
  final DateTime? startAt;
  final bool cancelled;

  int countOf(String id) => counts[id] ?? 0;
  int manualOf(String id) => manual[id] ?? 0;
  int get total => counts.values.fold(0, (a, b) => a + b);

  DateTime? get endsAt => startAt?.add(mode.timeLimit);

  bool get goalReached => switch (mode) {
    ChallengeMode.headToHead => false,
    ChallengeMode.raceTo50 => counts.values.any((c) => c >= mode.goal!),
    ChallengeMode.team => total >= mode.goal!,
  };

  RoomPhase phaseAt(DateTime serverNow) {
    if (cancelled) return RoomPhase.finished;
    final start = startAt;
    if (start == null) return RoomPhase.waiting;
    if (serverNow.isBefore(start)) return RoomPhase.countdown;
    if (goalReached || !serverNow.isBefore(endsAt!)) return RoomPhase.finished;
    return RoomPhase.running;
  }

  /// Secondi al via durante il conto alla rovescia.
  int countdownLeft(DateTime serverNow) => startAt == null
      ? countdownSeconds
      : math.max(
          0,
          (startAt!.difference(serverNow).inMilliseconds / 1000).ceil(),
        );

  /// Tempo trascorso dal via (0 prima, massimo il limite).
  Duration elapsed(DateTime serverNow) {
    if (startAt == null || serverNow.isBefore(startAt!)) return Duration.zero;
    final d = serverNow.difference(startAt!);
    return d > mode.timeLimit ? mode.timeLimit : d;
  }

  /// Tempo rimasto prima della fine.
  Duration remaining(DateTime serverNow) => mode.timeLimit - elapsed(serverNow);

  /// Nuovo conteggio di un partecipante: i conteggi possono solo salire,
  /// così rimandare lo stesso valore dopo una riconnessione non fa danni.
  ChallengeRoom withCount(String id, int count, {int? manualCount}) =>
      ChallengeRoom(
        id: this.id,
        mode: mode,
        hostId: hostId,
        players: players,
        counts: {...counts, id: math.max(countOf(id), count)},
        manual: {
          ...manual,
          id: math.max(manualOf(id), manualCount ?? manualOf(id)),
        },
        startAt: startAt,
        cancelled: cancelled,
      );

  ChallengeRoom copyWith({
    Map<String, String>? players,
    DateTime? startAt,
    bool? cancelled,
  }) => ChallengeRoom(
    id: id,
    mode: mode,
    hostId: hostId,
    players: players ?? this.players,
    counts: counts,
    manual: manual,
    startAt: startAt ?? this.startAt,
    cancelled: cancelled ?? this.cancelled,
  );

  /// Primo avversario di [me] (o null se sei da solo).
  String? opponentOf(String me) =>
      players.keys.where((id) => id != me).firstOrNull;

  ChallengeResult resultFor(String me) {
    final mine = countOf(me);
    final other = opponentOf(me);
    final theirs = other == null ? 0 : countOf(other);
    final outcome = switch (mode) {
      ChallengeMode.team =>
        goalReached
            ? ChallengeOutcome.teamSuccess
            : ChallengeOutcome.teamMissed,
      _ when other == null => ChallengeOutcome.solo,
      _ when mine > theirs => ChallengeOutcome.win,
      _ when mine < theirs => ChallengeOutcome.loss,
      _ => ChallengeOutcome.draw,
    };
    return ChallengeResult(
      roomId: id,
      mode: mode,
      friendId: other,
      friendName: other == null ? null : players[other],
      mine: mine,
      theirs: theirs,
      manual: manualOf(me),
      outcome: outcome,
    );
  }
}

enum ChallengeOutcome {
  win('Hai vinto'),
  loss('Hai perso'),
  draw('Pareggio'),
  teamSuccess('Obiettivo di squadra raggiunto'),
  teamMissed('Obiettivo di squadra mancato'),
  solo('Allenamento da solo');

  const ChallengeOutcome(this.label);

  final String label;
}

@immutable
class ChallengeResult {
  const ChallengeResult({
    required this.roomId,
    required this.mode,
    required this.mine,
    required this.theirs,
    required this.manual,
    required this.outcome,
    this.friendId,
    this.friendName,
  });

  final String roomId;
  final ChallengeMode mode;
  final String? friendId;
  final String? friendName;
  final int mine;
  final int theirs;

  /// Ripetizioni contate a mano con "+1".
  final int manual;
  final ChallengeOutcome outcome;

  /// "Hai vinto 42 a 38".
  String get summary => switch (outcome) {
    ChallengeOutcome.teamSuccess || ChallengeOutcome.teamMissed =>
      '${outcome.label} · ${mine + theirs} push-up',
    ChallengeOutcome.solo => '$mine push-up',
    _ => '${outcome.label} $mine a $theirs',
  };

  /// "di cui 3 contati a mano" (vuoto se tutti automatici).
  String get manualNote => manual == 0
      ? 'Tutti contati con la fotocamera'
      : manual == mine
      ? 'Contati a mano'
      : 'Di cui $manual contati a mano';
}

/// Bilancio contro un amico: "5–3" (vittorie–sconfitte).
({int wins, int losses, int draws}) balanceAgainst(
  Iterable<ChallengeResult> history,
  String friendId,
) {
  var wins = 0;
  var losses = 0;
  var draws = 0;
  for (final r in history.where((r) => r.friendId == friendId)) {
    switch (r.outcome) {
      case ChallengeOutcome.win:
        wins++;
      case ChallengeOutcome.loss:
        losses++;
      case ChallengeOutcome.draw:
        draws++;
      default:
        break;
    }
  }
  return (wins: wins, losses: losses, draws: draws);
}

/// Codice amico: 6 caratteri facili da dettare (niente 0/O, 1/I).
String generateFriendCode(math.Random random) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return List.generate(
    6,
    (_) => alphabet[random.nextInt(alphabet.length)],
  ).join();
}

bool isValidFriendCode(String code) =>
    RegExp(r'^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$')
        .hasMatch(normalizeCode(code));

String normalizeCode(String code) =>
    code.trim().toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

/// Link d'invito: ritmo://app/invito/CODICE (il router legge solo il
/// percorso, "/invito/CODICE").
String inviteLink(String code) => 'ritmo://app/invito/${normalizeCode(code)}';

/// Testo da condividere per invitare un amico.
String inviteMessage(String name, String code) =>
    '${name.isEmpty ? 'Ti' : '$name ti'} sfida su Ritmo, l\'app di '
    'calisthenics gratuita! 💪\n'
    'Aggiungimi con il codice ${normalizeCode(code)} oppure apri: '
    '${inviteLink(code)}\n'
    'Scarica Ritmo: https://github.com/owaismounir206-art/Discipline/releases';
