// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/database.dart';
import '../data/providers.dart';

/// Preferenze di aspetto scelte dall'utente.
@immutable
class ThemeSettings {
  const ThemeSettings({
    this.mode = ThemeMode.system,
    this.useDynamicColor = false,
    this.palette = 'coral',
    this.style = 'material',
  });

  /// Chiaro, scuro o come il telefono.
  final ThemeMode mode;

  /// Se vero, su Android 12+ usa i colori dello sfondo invece del corallo.
  final bool useDynamicColor;

  /// Colori dell'app (nome di un AppPalette sbloccato con i punti).
  final String palette;

  /// Stile grafico (nome di uno [StyleId]); "material" è Material You.
  final String style;

  ThemeSettings copyWith({
    ThemeMode? mode,
    bool? useDynamicColor,
    String? palette,
    String? style,
  }) => ThemeSettings(
    mode: mode ?? this.mode,
    useDynamicColor: useDynamicColor ?? this.useDynamicColor,
    palette: palette ?? this.palette,
    style: style ?? this.style,
  );

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    'dynamic': useDynamicColor,
    'palette': palette,
    'style': style,
  };

  factory ThemeSettings.fromJson(Map<String, Object?> json) => ThemeSettings(
    mode: ThemeMode.values.firstWhere(
      (m) => m.name == json['mode'],
      orElse: () => ThemeMode.system,
    ),
    useDynamicColor: json['dynamic'] as bool? ?? false,
    palette: json['palette'] as String? ?? 'coral',
    style: json['style'] as String? ?? 'material',
  );
}

/// Tema letto prima di avviare l'app (main.dart): così non si vede per un
/// attimo il tema predefinito a ogni apertura.
final initialThemeProvider = Provider<ThemeSettings>(
  (ref) => const ThemeSettings(),
);

/// Legge il tema salvato (per l'avvio).
Future<ThemeSettings> loadThemeSettings(AppDatabase db) async {
  final json = await db.readJson(ThemeSettingsNotifier._key);
  return json is Map<String, Object?>
      ? ThemeSettings.fromJson(json)
      : const ThemeSettings();
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
    return ref.read(initialThemeProvider);
  }

  Future<void> _save(ThemeSettings next) async {
    state = next;
    await ref.read(databaseProvider).writeJson(_key, next.toJson());
  }

  Future<void> setMode(ThemeMode mode) => _save(state.copyWith(mode: mode));

  Future<void> setUseDynamicColor(bool value) =>
      _save(state.copyWith(useDynamicColor: value));

  /// Le palette sono di Material You: sceglierne una torna a quello stile.
  Future<void> setPalette(String name) => _save(
    state.copyWith(palette: name, useDynamicColor: false, style: 'material'),
  );

  Future<void> setStyle(String name) => _save(state.copyWith(style: name));
}

final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
      ThemeSettingsNotifier.new,
    );
