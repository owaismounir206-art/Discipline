// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'ui_feedback.dart';

/// Il "motore" dell'app con il suono dei tocchi: ogni tocco che aziona
/// qualcosa (pulsante, card, voce di elenco, interruttore) fa un piccolo
/// suono, senza doverlo aggiungere a mano in ogni schermata.
///
/// Come funziona: Flutter decide chi riceve un tocco in una "arena" dove i
/// riconoscitori di gesti competono. Quando vince un riconoscitore di tocco
/// e il dito si alza senza essersi spostato, il tocco è avvenuto.
/// Scorrere un elenco o scrivere in un campo non suonano.
class DisciplineBinding extends WidgetsFlutterBinding {
  final _arena = SoundingArena();

  @override
  GestureArenaManager get gestureArena => _arena;

  @override
  BinaryMessenger createBinaryMessenger() =>
      QuietClicks(super.createBinaryMessenger());

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    _arena.track(event);
    super.handleEvent(event, entry);
    _arena.finish(event);
  }
}

/// Arena che riconosce i tocchi riusciti.
@visibleForTesting
class SoundingArena extends GestureArenaManager {
  SoundingArena({void Function()? onTap})
    : _onTap = onTap ?? UiFeedback.instance.tap;

  final void Function() _onTap;
  final _down = <int, Offset>{};
  final _moved = <int>{};
  final _waiting = <int>{};
  int? _lifting;

  @override
  GestureArenaEntry add(int pointer, GestureArenaMember member) => super.add(
    pointer,
    member is BaseTapGestureRecognizer ? _Sounding(member, this) : member,
  );

  void _won(int pointer) {
    // Vinto mentre il dito si alza: il tocco è già completo.
    if (_lifting == pointer) {
      _onTap();
    } else {
      // Vinto subito (unico interessato): si aspetta che il dito si alzi.
      _waiting.add(pointer);
    }
  }

  void track(PointerEvent event) {
    switch (event) {
      case PointerDownEvent():
        _down[event.pointer] = event.position;
        _moved.remove(event.pointer);
      case PointerMoveEvent():
        final start = _down[event.pointer];
        if (start != null && (event.position - start).distance > kTouchSlop) {
          _moved.add(event.pointer);
        }
      case PointerUpEvent():
        _lifting = event.pointer;
      default:
    }
  }

  void finish(PointerEvent event) {
    if (event is PointerUpEvent) {
      _lifting = null;
      if (_waiting.remove(event.pointer) && !_moved.contains(event.pointer)) {
        _onTap();
      }
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _down.remove(event.pointer);
      _moved.remove(event.pointer);
      _waiting.remove(event.pointer);
    }
  }
}

class _Sounding implements GestureArenaMember {
  _Sounding(this._inner, this._arena);

  final GestureArenaMember _inner;
  final SoundingArena _arena;

  @override
  void acceptGesture(int pointer) {
    _arena._won(pointer);
    _inner.acceptGesture(pointer);
  }

  @override
  void rejectGesture(int pointer) => _inner.rejectGesture(pointer);
}

/// Su Android i pulsanti chiedono anche il "clic" di sistema: con i suoni
/// di Discipline accesi lo saltiamo, altrimenti si sentirebbero due suoni.
@visibleForTesting
class QuietClicks implements BinaryMessenger {
  QuietClicks(this._inner);

  final BinaryMessenger _inner;
  static const _codec = JSONMethodCodec();

  @override
  Future<ByteData?>? send(String channel, ByteData? message) {
    if (channel == SystemChannels.platform.name &&
        message != null &&
        UiFeedback.instance.sounds) {
      try {
        if (_codec.decodeMethodCall(message).method == 'SystemSound.play') {
          return Future.value(_codec.encodeSuccessEnvelope(null));
        }
      } on Object {
        // Messaggio non leggibile: lo lasciamo passare.
      }
    }
    return _inner.send(channel, message);
  }

  @override
  void setMessageHandler(String channel, MessageHandler? handler) =>
      _inner.setMessageHandler(channel, handler);

  @override
  // Richiesto dall'interfaccia, anche se Flutter non lo usa più.
  // ignore: deprecated_member_use
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? data,
    PlatformMessageResponseCallback? callback,
  ) =>
      // ignore: deprecated_member_use
      _inner.handlePlatformMessage(channel, data, callback);
}
