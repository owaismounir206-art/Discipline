// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../data/database.dart';
import '../data/providers.dart';
import 'ui_feedback.dart';

/// Suoni e vibrazioni: accesi di base, si spengono nelle impostazioni.
@immutable
class FeedbackSettings {
  const FeedbackSettings({this.sounds = true, this.haptics = true});

  final bool sounds;
  final bool haptics;

  Map<String, Object?> toJson() => {'sounds': sounds, 'haptics': haptics};

  static FeedbackSettings fromJson(Object? json) => json is Map
      ? FeedbackSettings(
          sounds: json['sounds'] as bool? ?? true,
          haptics: json['haptics'] as bool? ?? true,
        )
      : const FeedbackSettings();

  /// Le rende effettive subito.
  void apply() => UiFeedback.instance
    ..sounds = sounds
    ..haptics = haptics;
}

const _key = 'feedback';

/// Lette all'avvio (main.dart), prima del primo tocco.
Future<FeedbackSettings> loadFeedbackSettings(AppDatabase db) async =>
    FeedbackSettings.fromJson(await db.readJson(_key));

class FeedbackSettingsNotifier extends Notifier<FeedbackSettings> {
  @override
  FeedbackSettings build() {
    final sub = ref.watch(databaseProvider).watchJson(_key).listen((json) {
      // Anche dopo un backup importato o i dati cancellati.
      state = FeedbackSettings.fromJson(json)..apply();
    });
    ref.onDispose(sub.cancel);
    return FeedbackSettings(
      sounds: UiFeedback.instance.sounds,
      haptics: UiFeedback.instance.haptics,
    );
  }

  Future<void> _save(FeedbackSettings next) async {
    state = next..apply();
    await ref.read(databaseProvider).writeJson(_key, next.toJson());
  }

  Future<void> setSounds(bool on) async {
    await _save(FeedbackSettings(sounds: on, haptics: state.haptics));
    // Riaccesi: se ne sente subito uno, per capire com'è.
    if (on) UiFeedback.instance.play(UiSound.toggleOn);
  }

  Future<void> setHaptics(bool on) =>
      _save(FeedbackSettings(sounds: state.sounds, haptics: on));
}

final feedbackSettingsProvider =
    NotifierProvider<FeedbackSettingsNotifier, FeedbackSettings>(
      FeedbackSettingsNotifier.new,
    );
