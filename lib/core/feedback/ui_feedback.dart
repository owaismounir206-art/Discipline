// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// I suoni dell'app (creati da `tool/make_sounds.py`).
enum UiSound {
  /// Un tocco qualsiasi su un pulsante, una card, una voce.
  tap('tocco.wav'),

  /// Cambio di scheda o di opzione in un selettore.
  select('scelta.wav'),
  toggleOn('attiva.wav'),
  toggleOff('disattiva.wav'),

  /// Qualcosa di fatto: serie completata, cibo o acqua aggiunti.
  success('fatto.wav'),

  /// Allenamento finito.
  complete('completato.wav'),

  /// Grado nuovo, medaglia, record.
  celebrate('festa.wav'),
  error('errore.wav'),

  /// Timer: ultimi secondi e fine recupero. Suonano anche con i suoni
  /// dell'interfaccia spenti, perché servono ad allenarsi.
  tick('bip.wav', timer: true),
  restEnd('fine_recupero.wav', timer: true);

  const UiSound(this.file, {this.timer = false});

  final String file;
  final bool timer;
}

/// Chi suona davvero. Nei test non suona niente.
abstract interface class UiSoundPlayer {
  Future<void> warmUp();
  Future<void> play(UiSound sound);
}

class SilentSoundPlayer implements UiSoundPlayer {
  const SilentSoundPlayer();

  @override
  Future<void> warmUp() async {}

  @override
  Future<void> play(UiSound sound) async {}
}

/// Suoni brevi a bassa latenza, che si mescolano alla musica invece di
/// fermarla e tacciono con il telefono in silenzioso.
class DeviceSoundPlayer implements UiSoundPlayer {
  static final _context = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  /// Qualche lettore per suono, così due tocchi veloci non si tagliano.
  final _rings = <UiSound, Future<List<AudioPlayer>>>{};
  final _next = <UiSound, int>{};

  Future<List<AudioPlayer>> _ring(UiSound sound) => _rings[sound] ??= () async {
    final size = sound == UiSound.tap || sound == UiSound.select ? 3 : 2;
    return [for (var i = 0; i < size; i++) await _player(sound)];
  }();

  Future<AudioPlayer> _player(UiSound sound) async {
    final player = AudioPlayer();
    if (defaultTargetPlatform == TargetPlatform.android) {
      await player.setPlayerMode(PlayerMode.lowLatency);
    }
    await player.setAudioContext(_context);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource('sounds/${sound.file}'));
    return player;
  }

  @override
  Future<void> warmUp() async {
    try {
      await AudioPlayer.global.setAudioContext(_context);
      // I più frequenti si preparano subito: il primo tocco suona in tempo.
      await Future.wait([
        for (final s in [UiSound.tap, UiSound.select, UiSound.success])
          _ring(s),
      ]);
    } on Object {
      // Senza audio l'app funziona lo stesso.
    }
  }

  @override
  Future<void> play(UiSound sound) async {
    try {
      final ring = await _ring(sound);
      final i = _next[sound] = ((_next[sound] ?? -1) + 1) % ring.length;
      final player = ring[i];
      await player.stop();
      await player.resume();
    } on Object {
      // Si riprova a preparare il suono la prossima volta.
      _rings.remove(sound)?.ignore();
    }
  }
}

/// Suoni e vibrazioni di ogni tocco e azione, in un posto solo.
///
/// I tocchi generici arrivano da soli (vedi `feedback_binding.dart`); le
/// azioni importanti chiamano [play] con il loro suono, che prende il posto
/// del tocco.
class UiFeedback {
  UiFeedback._();

  static final instance = UiFeedback._();

  UiSoundPlayer player = const SilentSoundPlayer();

  /// Suoni dell'interfaccia (il timer suona comunque).
  bool sounds = true;

  /// Vibrazioni leggere.
  bool haptics = true;

  final _sinceExplicit = Stopwatch();
  var _tapPending = false;

  /// Un tocco qualsiasi. Suona appena finisce l'evento, a meno che nel
  /// frattempo non sia partito un suono più preciso (es. "fatto").
  void tap() {
    if (!sounds || _tapPending) return;
    if (_sinceExplicit.isRunning && _sinceExplicit.elapsedMilliseconds < 120) {
      return;
    }
    _tapPending = true;
    scheduleMicrotask(() {
      if (!_tapPending) return;
      _tapPending = false;
      unawaited(player.play(UiSound.tap));
    });
  }

  /// Dimentica l'ultimo suono (per i test).
  @visibleForTesting
  void reset() {
    _tapPending = false;
    _sinceExplicit
      ..stop()
      ..reset();
  }

  /// Il suono di un'azione, con la sua vibrazione.
  void play(UiSound sound) {
    _tapPending = false;
    _sinceExplicit
      ..reset()
      ..start();
    if (haptics) unawaited(_vibrate(sound));
    if (sounds || sound.timer) unawaited(player.play(sound));
  }

  Future<void> _vibrate(UiSound sound) async {
    switch (sound) {
      case UiSound.tap:
        return;
      case UiSound.select ||
          UiSound.toggleOn ||
          UiSound.toggleOff ||
          UiSound.tick:
        await HapticFeedback.selectionClick();
      case UiSound.success:
        await HapticFeedback.mediumImpact();
      case UiSound.error:
        await HapticFeedback.lightImpact();
      case UiSound.complete || UiSound.celebrate:
        await HapticFeedback.heavyImpact();
      case UiSound.restEnd:
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 180));
        await HapticFeedback.heavyImpact();
    }
  }
}
