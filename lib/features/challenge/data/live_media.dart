// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';

/// Video e audio tra gli amici durante la sfida (facoltativo).
///
/// Quando c'è, la fotocamera la usa il video e le ripetizioni si contano a
/// mano con "+1": la fotocamera non può servire a due cose insieme.
abstract class LiveMedia extends ChangeNotifier {
  bool get micOn;
  bool get cameraOn;
  bool get connected;
  String? get error;

  Widget? localVideo();
  Widget? remoteVideo();

  Future<void> connect();
  Future<void> setMic(bool on);
  Future<void> setCamera(bool on);
  Future<void> disconnect();
}

/// Chiede al server un biglietto d'ingresso per la stanza video.
typedef TokenFetcher = Future<String> Function(String roomId);

Future<String> fetchLiveKitToken(String roomId) async {
  final res = await Supabase.instance.client.functions.invoke(
    'livekit-token',
    body: {'room': roomId},
  );
  final token = (res.data as Map?)?['token'];
  if (token is! String) throw StateError('Token mancante');
  return token;
}

class LiveKitMedia extends LiveMedia {
  LiveKitMedia({
    required this.url,
    required this.roomId,
    required this.fetchToken,
  });

  final String url;
  final String roomId;
  final TokenFetcher fetchToken;

  final _room = Room();
  var _mic = false;
  var _camera = false;
  var _connected = false;
  String? _error;

  @override
  bool get micOn => _mic;
  @override
  bool get cameraOn => _camera;
  @override
  bool get connected => _connected;
  @override
  String? get error => _error;

  @override
  Future<void> connect() async {
    try {
      final token = await fetchToken(roomId);
      _room.addListener(notifyListeners);
      await _room.connect(url, token);
      _connected = true;
      _error = null;
    } catch (_) {
      _error = 'Video non disponibile: la sfida va avanti senza.';
    }
    notifyListeners();
  }

  @override
  Future<void> setMic(bool on) async {
    if (!_connected) return;
    try {
      await _room.localParticipant?.setMicrophoneEnabled(on);
      _mic = on;
    } catch (_) {
      _error = 'Non riesco a usare il microfono.';
    }
    notifyListeners();
  }

  @override
  Future<void> setCamera(bool on) async {
    if (!_connected) return;
    try {
      await _room.localParticipant?.setCameraEnabled(on);
      _camera = on;
    } catch (_) {
      _error = 'Non riesco a usare la fotocamera.';
    }
    notifyListeners();
  }

  Widget? _video(Participant? p, {bool mirror = false}) {
    final track = p?.videoTrackPublications
        .where((t) => !t.muted)
        .map((t) => t.track)
        .whereType<VideoTrack>()
        .firstOrNull;
    return track == null
        ? null
        : VideoTrackRenderer(
            track,
            fit: VideoViewFit.cover,
            mirrorMode: mirror
                ? VideoViewMirrorMode.mirror
                : VideoViewMirrorMode.off,
          );
  }

  @override
  Widget? localVideo() =>
      _camera ? _video(_room.localParticipant, mirror: true) : null;

  @override
  Widget? remoteVideo() => _video(_room.remoteParticipants.values.firstOrNull);

  @override
  Future<void> disconnect() async {
    _room.removeListener(notifyListeners);
    try {
      await _room.disconnect();
    } catch (_) {}
    _connected = false;
  }

  @override
  void dispose() {
    unawaited(disconnect().whenComplete(_room.dispose));
    super.dispose();
  }
}

/// Crea il video di una sfida (null se non c'è un server video).
typedef LiveMediaFactory = LiveMedia? Function(String roomId);

final liveMediaFactoryProvider = Provider<LiveMediaFactory>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.hasVideo) return (_) => null;
  return (roomId) => LiveKitMedia(
    url: config.livekitUrl,
    roomId: roomId,
    fetchToken: fetchLiveKitToken,
  );
});
