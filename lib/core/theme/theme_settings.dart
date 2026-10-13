// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Preferenze di aspetto scelte dall'utente.
@immutable
class ThemeSettings {
  const ThemeSettings({
    this.mode = ThemeMode.system,
    this.useDynamicColor = false,
  });

  /// Chiaro, scuro o come il telefono.
  final ThemeMode mode;

  /// Se vero, su Android 12+ usa i colori dello sfondo invece del corallo.
  final bool useDynamicColor;

  ThemeSettings copyWith({ThemeMode? mode, bool? useDynamicColor}) =>
      ThemeSettings(
        mode: mode ?? this.mode,
        useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      );
}

// TODO(fase 3): salvare le preferenze sul telefono insieme agli altri dati.
class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() => const ThemeSettings();

  void setMode(ThemeMode mode) => state = state.copyWith(mode: mode);

  void setUseDynamicColor(bool value) =>
      state = state.copyWith(useDynamicColor: value);
}

final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
      ThemeSettingsNotifier.new,
    );
