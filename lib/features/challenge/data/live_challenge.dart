// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:material_ui/material_ui.dart' show ChangeNotifier;

import '../../account/domain/backend.dart';
import '../domain/challenge.dart';

/// Una sfida in corso, vista dal tuo telefono.
///
/// - Il timer usa l'ora del server (corretta della differenza con il
///   telefono), così parte e finisce insieme per tutti.
/// - Ogni push-up si conta subito qui e si manda al server; se la
///   connessione cade si riprova e si rimanda l'ultimo valore (il server
///   tiene sempre il più alto, quindi rimandarlo non fa danni).
class LiveChallenge extends ChangeNotifier {
  LiveChallenge({
    required this.backend,
    required this.roomId,
    required this.me,
    required this.clock,
    this.onFinished,
    this.retryDelay = const Duration(seconds: 2),
  });

  final RitmoBackend backend;
  final String roomId;
  final String me;
  final DateTime Function() clock;
  final Duration retryDelay;

  /// Chiamato una volta sola, quando la sfida finisce.
  final void Function(ChallengeResult result)? onFinished;

  ChallengeRoom? _room;
  Duration _offset = Duration.zero;
  var _connected = false;
  var _myCount = 0;
  var _myManual = 0;
  var _sentCount = -1;
  var _sending = false;
  var _finished = false;
  var _disposed = false;
  String? error;
  String? lastCheer;

  StreamSubscription<ChallengeRoom>? _roomSub;
  StreamSubscription<String>? _cheerSub;
  Timer? _ticker;
  Timer? _retry;

  ChallengeRoom? get room => _room;
  bool get connected => _connected;
  DateTime get serverNow => clock().add(_offset);
  RoomPhase get phase => _room?.phaseAt(serverNow) ?? RoomPhase.waiting;
  bool get isHost => _room?.hostId == me;
  bool get isSolo => (_room?.players.length ?? 1) < 2;
  String? get opponentId => _room?.opponentOf(me);
  String get opponentName => _room?.players[opponentId] ?? 'Il tuo amico';
  int get myCount => _myCount;
  int get opponentCount => opponentId == null ? 0 : _room!.countOf(opponentId!);

  Future<void> start() async {
    await syncClock();
    _subscribe();
    _cheerSub = backend.watchCheers(roomId).listen((name) {
      lastCheer = name;
      _notify();
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  /// Differenza tra l'ora del server e quella del telefono (metà del tempo
  /// di andata e ritorno è il ritardo di rete stimato).
  Future<void> syncClock() async {
    try {
      final sent = clock();
      final server = await backend.serverNow();
      final received = clock();
      final midpoint = sent.add(received.difference(sent) ~/ 2);
      _offset = server.difference(midpoint);
    } on BackendException {
      _offset = Duration.zero;
    }
  }

  void _subscribe() {
    _roomSub?.cancel();
    _roomSub = backend
        .watchRoom(roomId)
        .listen(
          (room) {
            final wasConnected = _connected;
            _connected = true;
            error = null;
            // I miei conteggi locali valgono più di quelli in arrivo.
            _room = room.withCount(me, _myCount, manualCount: _myManual);
            _myCount = _room!.countOf(me);
            _myManual = _room!.manualOf(me);
            if (!wasConnected) _flush();
            _tick();
          },
          onError: (Object e) {
            _connected = false;
            error = e is BackendException ? e.message : null;
            _notify();
            _retry?.cancel();
            _retry = Timer(retryDelay, () {
              if (!_disposed) _subscribe();
            });
          },
        );
  }

  void _tick() {
    final room = _room;
    if (room != null &&
        !_finished &&
        room.phaseAt(serverNow) == RoomPhase.finished) {
      _finished = true;
      unawaited(_flush());
      if (!room.cancelled) onFinished?.call(room.resultFor(me));
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Un push-up in più (a mano con "+1" o dalla fotocamera).
  void addRep({bool manual = true}) {
    final room = _room;
    if (room == null || phase != RoomPhase.running) return;
    _myCount++;
    if (manual) _myManual++;
    _room = room.withCount(me, _myCount, manualCount: _myManual);
    _tick();
    unawaited(_flush());
  }

  /// Manda l'ultimo conteggio (uno alla volta, sempre il più recente).
  Future<void> _flush() async {
    if (_sending || _sentCount == _myCount || _myCount == 0) return;
    _sending = true;
    final count = _myCount;
    try {
      await backend.reportCount(roomId, count, _myManual);
      _sentCount = count;
    } on BackendException {
      _connected = false;
      _notify();
    } finally {
      _sending = false;
    }
    if (!_disposed && _connected && _sentCount != _myCount) await _flush();
  }

  Future<void> begin() => backend.startRoom(roomId);

  Future<void> cheer() => backend.cheer(roomId);

  Future<void> leave() => backend.leaveRoom(roomId);

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _retry?.cancel();
    unawaited(_roomSub?.cancel());
    unawaited(_cheerSub?.cancel());
    super.dispose();
  }
}
