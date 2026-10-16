// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/feedback/ui_feedback.dart';

/// Effetti del telefono durante l'allenamento: schermo acceso, vibrazione e
/// suono a fine recupero. Nei test si sostituisce con una versione muta.
abstract interface class SessionFeedback {
  Future<void> keepScreenOn(bool on);
  Future<void> restFinished();
  Future<void> setDone();

  /// Bip breve negli ultimi secondi di una fase del timer.
  Future<void> tick();

  /// Fine allenamento: [completed] se conta per la serie di giorni.
  Future<void> finished({required bool completed});
}

class DeviceSessionFeedback implements SessionFeedback {
  UiFeedback get _ui => UiFeedback.instance;

  @override
  Future<void> keepScreenOn(bool on) async {
    try {
      await WakelockPlus.toggle(enable: on);
    } on Object {
      // Non tutti i dispositivi lo supportano: non è grave.
    }
  }

  @override
  Future<void> restFinished() async => _ui.play(UiSound.restEnd);

  @override
  Future<void> setDone() async => _ui.play(UiSound.success);

  @override
  Future<void> tick() async => _ui.play(UiSound.tick);

  @override
  Future<void> finished({required bool completed}) async =>
      _ui.play(completed ? UiSound.complete : UiSound.success);
}

class SilentSessionFeedback implements SessionFeedback {
  @override
  Future<void> keepScreenOn(bool on) async {}

  @override
  Future<void> restFinished() async {}

  @override
  Future<void> setDone() async {}

  @override
  Future<void> tick() async {}

  @override
  Future<void> finished({required bool completed}) async {}
}

final sessionFeedbackProvider = Provider<SessionFeedback>(
  (ref) => DeviceSessionFeedback(),
);
