// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/providers.dart';

/// Preferenze di aspetto scelte dall'utente.
@immutable
class ThemeSettings {
  const ThemeSettings({
    this.mode = ThemeMode.system,
    this.useDynamicColor = false,
    this.palette = 'coral',
  });

  /// Chiaro, scuro o come il telefono.
  final ThemeMode mode;

  /// Se vero, su Android 12+ usa i colori dello sfondo invece del corallo.
  final bool useDynamicColor;

  /// Colori dell'app (nome di un AppPalette sbloccato con i punti).
  final String palette;

  ThemeSettings copyWith({
    ThemeMode? mode,
    bool? useDynamicColor,
    String? palette,
  }) => ThemeSettings(
    mode: mode ?? this.mode,
    useDynamicColor: useDynamicColor ?? this.useDynamicColor,
    palette: palette ?? this.palette,
  );

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    'dynamic': useDynamicColor,
    'palette': palette,
  };

  factory ThemeSettings.fromJson(Map<String, Object?> json) => ThemeSettings(
    mode: ThemeMode.values.firstWhere(
      (m) => m.name == json['mode'],
      orElse: () => ThemeMode.system,
    ),
    useDynamicColor: json['dynamic'] as bool? ?? false,
    palette: json['palette'] as String? ?? 'coral',
  );
}

/// Preferenze salvate nel database locale.
class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
  static const _key = 'theme';

  @override
  ThemeSettings build() {
    final sub = ref.watch(databaseProvider).watchJson(_key).listen((json) {
      // Dopo "Elimina tutti i dati" o un backup senza tema: valori iniziali.
      state = json is Map<String, Object?>
          ? ThemeSettings.fromJson(json)
          : const ThemeSettings();
    });
    ref.onDispose(sub.cancel);
    return const ThemeSettings();
  }

  Future<void> _save(ThemeSettings next) async {
    state = next;
    await ref.read(databaseProvider).writeJson(_key, next.toJson());
  }

  Future<void> setMode(ThemeMode mode) => _save(state.copyWith(mode: mode));

  Future<void> setUseDynamicColor(bool value) =>
      _save(state.copyWith(useDynamicColor: value));

  Future<void> setPalette(String name) =>
      _save(state.copyWith(palette: name, useDynamicColor: false));
}

final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
      ThemeSettingsNotifier.new,
    );
