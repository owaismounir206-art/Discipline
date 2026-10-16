// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:discipline/core/feedback/feedback_binding.dart';
import 'package:discipline/core/feedback/feedback_settings.dart';
import 'package:discipline/core/feedback/ui_feedback.dart';
import 'package:discipline/core/router/routes.dart';
import 'package:discipline/core/widgets/motion_widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

class _Recorder implements UiSoundPlayer {
  final played = <UiSound>[];

  @override
  Future<void> warmUp() async {}

  @override
  Future<void> play(UiSound sound) async => played.add(sound);
}

class _Member implements GestureArenaMember {
  @override
  void acceptGesture(int pointer) {}

  @override
  void rejectGesture(int pointer) {}
}

class _Inner implements BinaryMessenger {
  final sent = <String>[];

  @override
  Future<ByteData?>? send(String channel, ByteData? message) {
    sent.add(channel);
    return Future.value();
  }

  @override
  void setMessageHandler(String channel, MessageHandler? handler) {}

  @override
  // ignore: deprecated_member_use
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? data,
    PlatformMessageResponseCallback? callback,
  ) async {}
}

void main() {
  late _Recorder recorder;
  setUp(() {
    recorder = _Recorder();
    UiFeedback.instance
      ..reset()
      ..player = recorder
      ..sounds = true
      ..haptics = false;
  });
  tearDown(() {
    UiFeedback.instance
      ..player = const SilentSoundPlayer()
      ..sounds = true
      ..haptics = true;
  });

  group('arena dei tocchi', () {
    const down = PointerDownEvent(pointer: 1, position: Offset(10, 10));
    const up = PointerUpEvent(pointer: 1, position: Offset(10, 10));

    test('tocco riuscito: un suono quando il dito si alza', () {
      var taps = 0;
      final arena = SoundingArena(onTap: () => taps++);
      final tap = TapGestureRecognizer()..onTap = () {};
      addTearDown(tap.dispose);
      arena
        ..track(down)
        ..add(1, tap)
        ..close(1)
        ..finish(down);
      expect(taps, 0, reason: 'il dito è ancora giù');
      arena
        ..track(up)
        ..sweep(1)
        ..finish(up);
      expect(taps, 1);
    });

    test('il dito scorre: nessun suono', () {
      var taps = 0;
      final arena = SoundingArena(onTap: () => taps++);
      final tap = TapGestureRecognizer()..onTap = () {};
      addTearDown(tap.dispose);
      arena
        ..track(down)
        ..add(1, tap)
        ..close(1)
        ..track(const PointerMoveEvent(pointer: 1, position: Offset(10, 80)))
        ..track(up)
        ..finish(up);
      expect(taps, 0);
    });

    test('tocco deciso all\'ultimo (es. in un elenco) e gesti diversi', () {
      var taps = 0;
      final arena = SoundingArena(onTap: () => taps++);
      final tap = TapGestureRecognizer()..onTap = () {};
      addTearDown(tap.dispose);
      // Tocco e trascinamento in gara: vince il tocco quando il dito si alza.
      arena
        ..track(down)
        ..add(1, tap)
        ..add(1, _Member())
        ..close(1)
        ..track(up)
        ..sweep(1)
        ..finish(up);
      expect(taps, 1);

      // Un gesto che non è un tocco non suona.
      arena
        ..track(down)
        ..add(1, _Member())
        ..close(1)
        ..track(up)
        ..sweep(1)
        ..finish(up);
      expect(taps, 1);
    });
  });

  test('un suono preciso prende il posto del tocco', () async {
    UiFeedback.instance
      ..tap()
      ..play(UiSound.success);
    await Future<void>.delayed(Duration.zero);
    expect(recorder.played, [UiSound.success]);

    // Il tocco che arriva subito dopo (stesso gesto) non si aggiunge.
    UiFeedback.instance.tap();
    await Future<void>.delayed(Duration.zero);
    expect(recorder.played, [UiSound.success]);
  });

  test('tocco semplice, e suoni spenti tranne il timer', () async {
    UiFeedback.instance.tap();
    await Future<void>.delayed(Duration.zero);
    expect(recorder.played, [UiSound.tap]);

    UiFeedback.instance
      ..sounds = false
      ..play(UiSound.success)
      ..play(UiSound.restEnd);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    UiFeedback.instance.tap();
    await Future<void>.delayed(Duration.zero);
    expect(recorder.played, [UiSound.tap, UiSound.restEnd]);
  });

  test('Android: il clic di sistema si salta solo con i suoni accesi', () {
    final inner = _Inner();
    final messenger = QuietClicks(inner);
    const codec = JSONMethodCodec();
    final click = codec.encodeMethodCall(
      const MethodCall('SystemSound.play', 'SystemSoundType.click'),
    );
    final other = codec.encodeMethodCall(
      const MethodCall('HapticFeedback.vibrate'),
    );
    unawaited(messenger.send('flutter/platform', click));
    unawaited(messenger.send('flutter/platform', other));
    expect(inner.sent, hasLength(1));

    UiFeedback.instance.sounds = false;
    unawaited(messenger.send('flutter/platform', click));
    expect(inner.sent, hasLength(2));
  });

  testWidgets('impostazioni: spegni i suoni e restano spenti', (tester) async {
    final db = memoryDatabase();
    await tester.runAsync(() => seedProfile(db));
    await pumpDiscipline(tester, db);
    final context = tester.element(find.byType(DisciplineNavigationBar));
    unawaited(GoRouter.of(context).push(Routes.settings));
    await settle(tester);

    final sounds = find.widgetWithText(SwitchListTile, 'Suoni');
    await tester.scrollUntilVisible(
      sounds,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await settle(tester);
    await tester.tap(sounds);
    await settle(tester);
    expect(UiFeedback.instance.sounds, isFalse);
    final saved = await tester.runAsync(() => loadFeedbackSettings(db));
    expect(saved!.sounds, isFalse);
    expect(saved.haptics, isTrue);

    await tester.tap(sounds);
    await settle(tester);
    expect(UiFeedback.instance.sounds, isTrue);
    expect(recorder.played, contains(UiSound.toggleOn));
    await disposeDiscipline(tester, db);
  });
}
