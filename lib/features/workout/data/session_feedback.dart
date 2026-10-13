// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Effetti del telefono durante l'allenamento: schermo acceso, vibrazione e
/// suono a fine recupero. Nei test si sostituisce con una versione muta.
abstract interface class SessionFeedback {
  Future<void> keepScreenOn(bool on);
  Future<void> restFinished();
  Future<void> setDone();
}

class DeviceSessionFeedback implements SessionFeedback {
  AudioPlayer? _player;

  @override
  Future<void> keepScreenOn(bool on) async {
    try {
      await WakelockPlus.toggle(enable: on);
    } on Object {
      // Non tutti i dispositivi lo supportano: non è grave.
    }
  }

  @override
  Future<void> restFinished() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    await HapticFeedback.heavyImpact();
    try {
      final player = _player ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(AssetSource('sounds/fine_recupero.wav'));
    } on Object {
      // Senza audio resta la vibrazione.
    }
  }

  @override
  Future<void> setDone() => HapticFeedback.mediumImpact();
}

class SilentSessionFeedback implements SessionFeedback {
  @override
  Future<void> keepScreenOn(bool on) async {}

  @override
  Future<void> restFinished() async {}

  @override
  Future<void> setDone() async {}
}

final sessionFeedbackProvider = Provider<SessionFeedback>(
  (ref) => DeviceSessionFeedback(),
);
