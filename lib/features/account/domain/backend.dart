// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:meta/meta.dart';

import '../../challenge/domain/challenge.dart';

/// Il tuo account online (serve solo per amici, sfide e backup).
@immutable
class Account {
  const Account({
    required this.id,
    required this.email,
    required this.name,
    required this.friendCode,
  });

  final String id;
  final String email;
  final String name;

  /// Codice da dare agli amici per farti aggiungere.
  final String friendCode;
}

enum Presence {
  online('Online'),
  training('Si sta allenando'),
  offline('Offline');

  const Presence(this.label);

  final String label;
}

@immutable
class Friend {
  const Friend({
    required this.id,
    required this.name,
    this.presence = Presence.offline,
    this.level,
    this.lastSeen,
  });

  final String id;
  final String name;
  final Presence presence;

  /// "Intermedio", "Avanzato"... (come lo vede l'amico nell'app).
  final String? level;
  final DateTime? lastSeen;

  String get initial =>
      name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase();

  Friend copyWith({Presence? presence, DateTime? lastSeen}) => Friend(
    id: id,
    name: name,
    presence: presence ?? this.presence,
    level: level,
    lastSeen: lastSeen ?? this.lastSeen,
  );

  /// "Online · Intermedio", "Offline · visto 2 h fa".
  String statusLine(DateTime now) {
    final parts = <String>[presence.label];
    if (presence == Presence.offline) {
      final seen = lastSeen;
      if (seen != null) parts.add('visto ${agoLabel(seen, now)}');
    } else if (level != null) {
      parts.add(level!);
    }
    return parts.join(' · ');
  }
}

/// "adesso", "5 min fa", "2 h fa", "3 giorni fa".
String agoLabel(DateTime then, DateTime now) {
  final d = now.difference(then);
  if (d.inMinutes < 1) return 'adesso';
  if (d.inHours < 1) return '${d.inMinutes} min fa';
  if (d.inDays < 1) return '${d.inHours} h fa';
  if (d.inDays == 1) return 'ieri';
  return '${d.inDays} giorni fa';
}

/// Un amico ti ha invitato a una sfida.
@immutable
class ChallengeInvite {
  const ChallengeInvite({
    required this.roomId,
    required this.mode,
    required this.fromId,
    required this.fromName,
  });

  final String roomId;
  final ChallengeMode mode;
  final String fromId;
  final String fromName;
}

/// Errore da mostrare all'utente così com'è (già in italiano).
class BackendException implements Exception {
  const BackendException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Tutto ciò che richiede un server. L'app parla solo con questa
/// interfaccia: l'implementazione può essere Supabase, un altro servizio
/// o quella in memoria usata offline e nei test.
abstract interface class RitmoBackend {
  /// C'è davvero un server dietro? (falso = sfide solo in allenamento).
  bool get isConfigured;

  // Account.
  Account? get currentAccount;
  Stream<Account?> watchAccount();

  /// Restituisce false se serve confermare l'email prima di accedere.
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  });
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();

  /// Cancella account, amicizie, sfide e backup dal server.
  Future<void> deleteAccount();

  // Amici.
  Stream<List<Friend>> watchFriends();
  Future<Friend> addFriend(String code);
  Future<void> removeFriend(String friendId);
  Future<void> setPresence(Presence presence, {String? level});

  // Sfide.
  Stream<List<ChallengeInvite>> watchInvites();

  /// Crea una stanza. Senza [friendId] è un allenamento da solo.
  Future<String> createRoom(ChallengeMode mode, {String? friendId});
  Future<void> joinRoom(String roomId);
  Stream<ChallengeRoom> watchRoom(String roomId);

  /// Fa partire il conto alla rovescia (ora decisa dal server).
  Future<void> startRoom(String roomId);
  Future<void> reportCount(String roomId, int count, int manual);
  Future<void> leaveRoom(String roomId);
  Future<void> cheer(String roomId);

  /// Nomi di chi ti incita durante la sfida.
  Stream<String> watchCheers(String roomId);

  /// Ora del server, per sincronizzare i timer dei due telefoni.
  Future<DateTime> serverNow();

  // Backup.
  Future<void> uploadBackup(Map<String, Object?> data);
  Future<Map<String, Object?>?> downloadBackup();
}
