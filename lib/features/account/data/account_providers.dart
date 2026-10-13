// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Presence;

import '../../../core/config/app_config.dart';
import '../../../core/data/providers.dart';
import '../../profile/data/profile_repository.dart';
import '../domain/backend.dart';
import 'memory_backend.dart';
import 'supabase_backend.dart';

/// Il server: Supabase se configurato, altrimenti tutto sul telefono.
final backendProvider = Provider<RitmoBackend>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.hasServer) {
    return MemoryBackend(clock: ref.watch(clockProvider));
  }
  final backend = SupabaseBackend(
    Supabase.instance.client,
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(backend.dispose);
  return backend;
});

final accountProvider = StreamProvider<Account?>(
  (ref) => ref.watch(backendProvider).watchAccount(),
);

final friendsProvider = StreamProvider<List<Friend>>((ref) {
  ref.watch(accountProvider.select((a) => a.value?.id));
  return ref.watch(backendProvider).watchFriends();
});

final invitesProvider = StreamProvider<List<ChallengeInvite>>((ref) {
  ref.watch(accountProvider.select((a) => a.value?.id));
  return ref.watch(backendProvider).watchInvites();
});

/// Fa sapere agli amici se sei online o ti stai allenando.
class PresenceReporter {
  PresenceReporter(this._backend, this._level);

  final RitmoBackend _backend;
  final String? Function() _level;
  var _state = Presence.online;
  Timer? _heartbeat;

  bool get _active => _backend.currentAccount != null;

  Future<void> _send() async {
    if (!_active) return;
    try {
      await _backend.setPresence(_state, level: _level());
    } on BackendException {
      // Offline: riproveremo al prossimo battito.
    }
  }

  /// App in primo piano: battito ogni minuto.
  void resume() {
    if (!_active) return;
    _heartbeat ??= Timer.periodic(const Duration(minutes: 1), (_) => _send());
    unawaited(_send());
  }

  /// App in background.
  void pause() {
    _heartbeat?.cancel();
    _heartbeat = null;
    if (!_active) return;
    unawaited(_backend.setPresence(Presence.offline).catchError((Object _) {}));
  }

  /// Durante un allenamento o una sfida.
  set training(bool value) {
    _state = value ? Presence.training : Presence.online;
    unawaited(_send());
  }

  void dispose() => _heartbeat?.cancel();
}

final presenceProvider = Provider<PresenceReporter>((ref) {
  final reporter = PresenceReporter(
    ref.watch(backendProvider),
    () => ref.read(levelProvider)?.level.label,
  );
  ref.onDispose(reporter.dispose);
  return reporter;
});
