// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';
import 'dart:math' as math;

import '../../challenge/domain/challenge.dart';
import '../domain/backend.dart';

/// Backend tutto sul telefono.
///
/// - Senza server ([isConfigured] falso) permette solo gli allenamenti in
///   modalità sfida da soli: account e amici rispondono con un messaggio
///   che spiega come attivarli.
/// - Nei test ([isConfigured] vero) simula il server: account, amici e un
///   avversario che conta i suoi push-up ([simulateCount]).
class MemoryBackend implements RitmoBackend {
  MemoryBackend({
    this.isConfigured = false,
    DateTime Function()? clock,
    math.Random? random,
  }) : _clock = clock ?? DateTime.now,
       _random = random ?? math.Random();

  @override
  final bool isConfigured;
  final DateTime Function() _clock;
  final math.Random _random;

  static const notConfigured = BackendException(
    'Questa versione di Ritmo non è collegata a un server: le sfide con '
    'gli amici e il backup non sono attivi. Puoi comunque allenarti in '
    'modalità sfida da solo.',
  );

  Account? _account;
  final _accounts = <String, ({Account account, String password})>{};
  final _accountController = StreamController<Account?>.broadcast();

  /// Utenti "registrati" che puoi aggiungere con il loro codice.
  final users = <String, Friend>{};
  final _friendCodes = <String, String>{};
  final _friends = <String, Friend>{};
  final _friendsController = StreamController<List<Friend>>.broadcast();

  final _invites = <ChallengeInvite>[];
  final _invitesController =
      StreamController<List<ChallengeInvite>>.broadcast();

  final _rooms = <String, ChallengeRoom>{};
  final _roomControllers = <String, StreamController<ChallengeRoom>>{};
  final _cheerControllers = <String, StreamController<String>>{};
  var _nextRoom = 0;

  Map<String, Object?>? _backup;
  Presence? lastPresence;

  void _requireServer() {
    if (!isConfigured) throw notConfigured;
  }

  Account _requireAccount() {
    _requireServer();
    final account = _account;
    if (account == null) {
      throw const BackendException('Accedi per usare questa funzione.');
    }
    return account;
  }

  // ---------------------------------------------------------------- Account

  @override
  Account? get currentAccount => _account;

  @override
  Stream<Account?> watchAccount() async* {
    yield _account;
    yield* _accountController.stream;
  }

  void _setAccount(Account? account) {
    _account = account;
    _accountController.add(account);
    _friendsController.add(_friends.values.toList());
  }

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _requireServer();
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const BackendException('Esiste già un account con questa email.');
    }
    if (password.length < 8) {
      throw const BackendException(
        'La password deve avere almeno 8 caratteri.',
      );
    }
    final account = Account(
      id: 'u${_accounts.length + 1}',
      email: key,
      name: name.trim(),
      friendCode: generateFriendCode(_random),
    );
    _accounts[key] = (account: account, password: password);
    _setAccount(account);
    return true;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    _requireServer();
    final entry = _accounts[email.trim().toLowerCase()];
    if (entry == null || entry.password != password) {
      throw const BackendException('Email o password non corrette.');
    }
    _setAccount(entry.account);
  }

  @override
  Future<void> signOut() async => _setAccount(null);

  @override
  Future<void> deleteAccount() async {
    final account = _requireAccount();
    _accounts.remove(account.email);
    _friends.clear();
    _backup = null;
    _setAccount(null);
  }

  // ------------------------------------------------------------------ Amici

  /// Aggiunge un utente che si può trovare con il suo codice.
  void addUser(Friend user, String code) {
    users[user.id] = user;
    _friendCodes[normalizeCode(code)] = user.id;
  }

  /// Cambia lo stato di un amico (online, si sta allenando...).
  void setFriendPresence(String id, Presence presence) {
    final friend = _friends[id];
    if (friend == null) return;
    _friends[id] = friend.copyWith(presence: presence);
    _friendsController.add(_friends.values.toList());
  }

  @override
  Stream<List<Friend>> watchFriends() async* {
    yield _account == null ? const [] : _friends.values.toList();
    yield* _friendsController.stream.map(
      (list) => _account == null ? const [] : list,
    );
  }

  @override
  Future<Friend> addFriend(String code) async {
    final me = _requireAccount();
    final normalized = normalizeCode(code);
    if (!isValidFriendCode(normalized)) {
      throw const BackendException(
        'Il codice ha 6 caratteri, lettere e numeri.',
      );
    }
    if (normalized == me.friendCode) {
      throw const BackendException('Questo è il tuo codice.');
    }
    final id = _friendCodes[normalized];
    if (id == null) {
      throw const BackendException('Nessuno ha questo codice.');
    }
    final friend = users[id]!;
    _friends[id] = friend;
    _friendsController.add(_friends.values.toList());
    return friend;
  }

  @override
  Future<void> removeFriend(String friendId) async {
    _friends.remove(friendId);
    _friendsController.add(_friends.values.toList());
  }

  @override
  Future<void> setPresence(Presence presence, {String? level}) async {
    lastPresence = presence;
  }

  // ----------------------------------------------------------------- Sfide

  String get _myId => _account?.id ?? 'io';
  String get _myName => _account?.name ?? 'Tu';

  /// Un amico ti invita (nei test).
  String simulateInvite(String friendId, ChallengeMode mode) {
    final friend = users[friendId]!;
    final id = 'stanza${++_nextRoom}';
    _rooms[id] = ChallengeRoom(
      id: id,
      mode: mode,
      hostId: friendId,
      players: {friendId: friend.name},
    );
    _invites.add(
      ChallengeInvite(
        roomId: id,
        mode: mode,
        fromId: friendId,
        fromName: friend.name,
      ),
    );
    _invitesController.add(List.of(_invites));
    return id;
  }

  /// L'amico entra nella stanza che hai creato.
  void simulateJoin(String roomId, String friendId) {
    _update(
      roomId,
      (r) =>
          r.copyWith(players: {...r.players, friendId: users[friendId]!.name}),
    );
  }

  /// L'amico ha fatto [count] push-up.
  void simulateCount(String roomId, String friendId, int count) =>
      _update(roomId, (r) => r.withCount(friendId, count));

  /// L'amico ti incita.
  void simulateCheer(String roomId, String name) =>
      _cheerControllers[roomId]?.add(name);

  /// Simula una connessione caduta.
  void simulateDisconnect(String roomId) => _roomControllers[roomId]?.addError(
    const BackendException('Connessione persa'),
  );

  ChallengeRoom? room(String id) => _rooms[id];

  void _update(String roomId, ChallengeRoom Function(ChallengeRoom) change) {
    final room = _rooms[roomId];
    if (room == null) return;
    final next = change(room);
    _rooms[roomId] = next;
    _roomControllers[roomId]?.add(next);
  }

  @override
  Stream<List<ChallengeInvite>> watchInvites() async* {
    yield List.of(_invites);
    yield* _invitesController.stream;
  }

  @override
  Future<String> createRoom(ChallengeMode mode, {String? friendId}) async {
    if (friendId != null) _requireAccount();
    final id = 'stanza${++_nextRoom}';
    _rooms[id] = ChallengeRoom(
      id: id,
      mode: mode,
      hostId: _myId,
      players: {_myId: _myName},
    );
    return id;
  }

  @override
  Future<void> joinRoom(String roomId) async {
    _invites.removeWhere((i) => i.roomId == roomId);
    _invitesController.add(List.of(_invites));
    _update(roomId, (r) => r.copyWith(players: {...r.players, _myId: _myName}));
  }

  @override
  Stream<ChallengeRoom> watchRoom(String roomId) {
    final controller = _roomControllers.putIfAbsent(
      roomId,
      StreamController<ChallengeRoom>.broadcast,
    );
    return Stream.multi((sink) {
      final room = _rooms[roomId];
      if (room == null) {
        sink.addError(const BackendException('Sfida non trovata.'));
      } else {
        sink.add(room);
      }
      final sub = controller.stream.listen(sink.add, onError: sink.addError);
      sink.onCancel = sub.cancel;
    });
  }

  @override
  Future<void> startRoom(String roomId) async => _update(
    roomId,
    (r) => r.copyWith(
      startAt: _clock().add(const Duration(seconds: countdownSeconds)),
    ),
  );

  @override
  Future<void> reportCount(String roomId, int count, int manual) async =>
      _update(roomId, (r) => r.withCount(_myId, count, manualCount: manual));

  @override
  Future<void> leaveRoom(String roomId) async {
    _invites.removeWhere((i) => i.roomId == roomId);
    _invitesController.add(List.of(_invites));
    final room = _rooms[roomId];
    if (room != null && room.startAt == null) {
      _update(roomId, (r) => r.copyWith(cancelled: true));
    }
  }

  @override
  Future<void> cheer(String roomId) async {}

  @override
  Stream<String> watchCheers(String roomId) => _cheerControllers
      .putIfAbsent(roomId, StreamController<String>.broadcast)
      .stream;

  @override
  Future<DateTime> serverNow() async => _clock();

  // ---------------------------------------------------------------- Backup

  @override
  Future<void> uploadBackup(Map<String, Object?> data) async {
    _requireAccount();
    _backup = data;
  }

  @override
  Future<Map<String, Object?>?> downloadBackup() async {
    _requireAccount();
    return _backup;
  }
}
