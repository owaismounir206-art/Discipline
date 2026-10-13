// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' hide Presence;

import '../../challenge/domain/challenge.dart';
import '../domain/backend.dart';

/// Backend su Supabase (open source, si può anche ospitare da sé).
/// Lo schema del database è in `supabase/migrations/`.
class SupabaseBackend implements RitmoBackend {
  SupabaseBackend(this._client, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _authSub = _client.auth.onAuthStateChange.listen((state) async {
      final user = state.session?.user;
      _account = user == null ? null : await _loadAccount(user);
      _accountController.add(_account);
    });
  }

  final SupabaseClient _client;
  final DateTime Function() _clock;
  late final StreamSubscription<AuthState> _authSub;
  final _accountController = StreamController<Account?>.broadcast();
  Account? _account;

  /// Un amico è "online" se si è fatto sentire negli ultimi 3 minuti.
  static const onlineWindow = Duration(minutes: 3);

  @override
  bool get isConfigured => true;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const BackendException('Accedi per usare questa funzione.');
    }
    return id;
  }

  /// Traduce gli errori del server in messaggi comprensibili.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException catch (e) {
      throw BackendException(_authMessage(e));
    } on PostgrestException catch (e) {
      throw BackendException(
        e.message.isNotEmpty && !e.message.contains('violates')
            ? e.message
            : 'Il server ha rifiutato la richiesta.',
      );
    } on BackendException {
      rethrow;
    } catch (_) {
      throw const BackendException(
        'Server non raggiungibile. Controlla la connessione e riprova.',
      );
    }
  }

  static String _authMessage(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login')) return 'Email o password non corrette.';
    if (m.contains('already registered')) {
      return 'Esiste già un account con questa email.';
    }
    if (m.contains('email not confirmed')) {
      return 'Conferma prima l\'email: ti abbiamo scritto un messaggio.';
    }
    if (m.contains('password')) {
      return 'Password non valida: usa almeno 8 caratteri.';
    }
    return 'Accesso non riuscito: ${e.message}';
  }

  Future<Account?> _loadAccount(User user) async {
    try {
      final row = await _client
          .from('profiles')
          .select('name, friend_code')
          .eq('id', user.id)
          .single();
      return Account(
        id: user.id,
        email: user.email ?? '',
        name: row['name'] as String,
        friendCode: row['friend_code'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------- Account

  @override
  Account? get currentAccount => _account;

  @override
  Stream<Account?> watchAccount() async* {
    final user = _client.auth.currentUser;
    if (_account == null && user != null) {
      _account = await _loadAccount(user);
    }
    yield _account;
    yield* _accountController.stream;
  }

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) => _guard(() async {
    final res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'name': name.trim()},
    );
    return res.session != null;
  });

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(
        () => _client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        ),
      );

  @override
  Future<void> signOut() => _guard(() async {
    await setPresence(Presence.offline).catchError((_) {});
    await _client.auth.signOut();
  });

  @override
  Future<void> deleteAccount() => _guard(() async {
    await _client.rpc<void>('delete_my_account');
    await _client.auth.signOut();
  });

  // ------------------------------------------------------------------ Amici

  Friend _friend(Map<String, dynamic> row) {
    final lastSeen = DateTime.tryParse(row['last_seen'] as String? ?? '');
    final status = row['status'] as String? ?? 'offline';
    final fresh =
        lastSeen != null && _clock().difference(lastSeen) < onlineWindow;
    return Friend(
      id: row['id'] as String,
      name: row['name'] as String,
      level: row['level'] as String?,
      lastSeen: lastSeen,
      presence: !fresh
          ? Presence.offline
          : status == 'training'
          ? Presence.training
          : status == 'online'
          ? Presence.online
          : Presence.offline,
    );
  }

  @override
  Stream<List<Friend>> watchFriends() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Stream.value(const []);
    // Quando cambia l'elenco degli amici, si riascoltano i loro profili.
    late final StreamController<List<Friend>> controller;
    StreamSubscription<List<Map<String, dynamic>>>? links;
    StreamSubscription<List<Map<String, dynamic>>>? profiles;
    controller = StreamController<List<Friend>>(
      onListen: () {
        links = _client
            .from('friendships')
            .stream(primaryKey: ['user_id', 'friend_id'])
            .eq('user_id', uid)
            .listen((rows) {
              unawaited(profiles?.cancel());
              final ids = [for (final r in rows) r['friend_id'] as String];
              if (ids.isEmpty) {
                controller.add(const []);
                return;
              }
              profiles = _client
                  .from('profiles')
                  .stream(primaryKey: ['id'])
                  .inFilter('id', ids)
                  .listen(
                    (rows) => controller.add(
                      [for (final r in rows) _friend(r)]
                        ..sort((a, b) => a.name.compareTo(b.name)),
                    ),
                    onError: controller.addError,
                  );
            }, onError: controller.addError);
      },
      onCancel: () async {
        await profiles?.cancel();
        await links?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<Friend> addFriend(String code) => _guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'add_friend_by_code',
      params: {'code': normalizeCode(code)},
    );
    return _friend({...(rows.first as Map<String, dynamic>)});
  });

  @override
  Future<void> removeFriend(String friendId) => _guard(
    () => _client.rpc<void>('remove_friend', params: {'other': friendId}),
  );

  @override
  Future<void> setPresence(Presence presence, {String? level}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _guard(
      () => _client
          .from('profiles')
          .update({
            'status': presence.name,
            'last_seen': _clock().toUtc().toIso8601String(),
            'level': ?level,
          })
          .eq('id', uid),
    );
  }

  // ----------------------------------------------------------------- Sfide

  ChallengeRoom _room(Map<String, dynamic> row) {
    Map<String, int> ints(Object? json) => {
      for (final e in (json as Map? ?? const {}).entries)
        e.key as String: (e.value as num).toInt(),
    };
    return ChallengeRoom(
      id: row['id'] as String,
      mode: ChallengeMode.values.byName(row['mode'] as String),
      hostId: row['host_id'] as String,
      players: {
        for (final e in (row['players'] as Map? ?? const {}).entries)
          e.key as String: e.value as String,
      },
      counts: ints(row['counts']),
      manual: ints(row['manual']),
      startAt: DateTime.tryParse(row['start_at'] as String? ?? ''),
      cancelled: row['cancelled'] as bool? ?? false,
    );
  }

  @override
  Stream<List<ChallengeInvite>> watchInvites() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Stream.value(const []);
    return _client
        .from('challenge_rooms')
        .stream(primaryKey: ['id'])
        .eq('invited_id', uid)
        .map(
          (rows) => [
            for (final row in rows)
              if (row['start_at'] == null &&
                  row['cancelled'] != true &&
                  !(row['players'] as Map).containsKey(uid) &&
                  _clock().difference(
                        DateTime.parse(row['created_at'] as String),
                      ) <
                      const Duration(minutes: 15))
                ChallengeInvite(
                  roomId: row['id'] as String,
                  mode: ChallengeMode.values.byName(row['mode'] as String),
                  fromId: row['host_id'] as String,
                  fromName:
                      (row['players'] as Map)[row['host_id']] as String? ??
                      'Un amico',
                ),
          ],
        );
  }

  @override
  Future<String> createRoom(ChallengeMode mode, {String? friendId}) =>
      _guard(() async {
        _uid;
        return _client.rpc<String>(
          'create_room',
          params: {'p_mode': mode.name, 'p_friend': friendId},
        );
      });

  @override
  Future<void> joinRoom(String roomId) =>
      _guard(() => _client.rpc<void>('join_room', params: {'p_room': roomId}));

  @override
  Stream<ChallengeRoom> watchRoom(String roomId) => _client
      .from('challenge_rooms')
      .stream(primaryKey: ['id'])
      .eq('id', roomId)
      .where((rows) => rows.isNotEmpty)
      .map((rows) => _room(rows.first));

  @override
  Future<void> startRoom(String roomId) =>
      _guard(() => _client.rpc<void>('start_room', params: {'p_room': roomId}));

  @override
  Future<void> reportCount(String roomId, int count, int manual) => _guard(
    () => _client.rpc<void>(
      'report_count',
      params: {'p_room': roomId, 'p_count': count, 'p_manual': manual},
    ),
  );

  @override
  Future<void> leaveRoom(String roomId) =>
      _guard(() => _client.rpc<void>('leave_room', params: {'p_room': roomId}));

  final _cheerChannels = <String, RealtimeChannel>{};

  RealtimeChannel _cheerChannel(String roomId) => _cheerChannels.putIfAbsent(
    roomId,
    () => _client.channel('sfida:$roomId'),
  );

  @override
  Future<void> cheer(String roomId) => _guard(
    () => _cheerChannel(roomId).sendBroadcastMessage(
      event: 'incita',
      payload: {'name': _account?.name ?? 'Il tuo amico'},
    ),
  );

  @override
  Stream<String> watchCheers(String roomId) {
    late final StreamController<String> controller;
    controller = StreamController<String>(
      onListen: () {
        _cheerChannel(roomId)
            .onBroadcast(
              event: 'incita',
              callback: (payload) =>
                  controller.add(payload['name'] as String? ?? 'Il tuo amico'),
            )
            .subscribe();
      },
      onCancel: () async {
        final channel = _cheerChannels.remove(roomId);
        if (channel != null) await _client.removeChannel(channel);
      },
    );
    return controller.stream;
  }

  @override
  Future<DateTime> serverNow() => _guard(() async {
    final value = await _client.rpc<String>('server_now');
    return DateTime.parse(value);
  });

  // ---------------------------------------------------------------- Backup

  @override
  Future<void> uploadBackup(Map<String, Object?> data) => _guard(
    () => _client.from('backups').upsert({
      'user_id': _uid,
      'data': data,
      'updated_at': _clock().toUtc().toIso8601String(),
    }),
  );

  @override
  Future<Map<String, Object?>?> downloadBackup() => _guard(() async {
    final row = await _client
        .from('backups')
        .select('data')
        .eq('user_id', _uid)
        .maybeSingle();
    return (row?['data'] as Map?)?.cast<String, Object?>();
  });

  Future<void> dispose() async {
    await _authSub.cancel();
    await _accountController.close();
  }
}
