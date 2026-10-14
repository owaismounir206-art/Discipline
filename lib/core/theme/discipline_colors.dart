// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

/// Colori di Discipline: palette tonale Material 3 dal seed corallo `#8F4C38`.
///
/// I ruoli indicati nel design (vedi `design/`) sono fissati a mano; tutti gli
/// altri vengono generati dal seed, così la palette resta coerente.
abstract final class DisciplineColors {
  static const seed = Color(0xFF8F4C38);

  static final ColorScheme light = ColorScheme.fromSeed(seedColor: seed)
      .copyWith(
        primary: const Color(0xFF8F4C38),
        onPrimary: const Color(0xFFFFFFFF),
        primaryContainer: const Color(0xFFFFDBD1),
        onPrimaryContainer: const Color(0xFF3A0B01),
        secondary: const Color(0xFF77574E),
        onSecondary: const Color(0xFFFFFFFF),
        secondaryContainer: const Color(0xFFF7DCD3),
        onSecondaryContainer: const Color(0xFF2C1510),
        tertiary: const Color(0xFF6C5D2F),
        onTertiary: const Color(0xFFFFFFFF),
        tertiaryContainer: const Color(0xFFF5E1A7),
        onTertiaryContainer: const Color(0xFF231B00),
        surface: const Color(0xFFFFF8F6),
        onSurface: const Color(0xFF231917),
        onSurfaceVariant: const Color(0xFF53433F),
        surfaceContainerLowest: const Color(0xFFFFFFFF),
        surfaceContainerLow: const Color(0xFFFFF1ED),
        surfaceContainer: const Color(0xFFFCEAE5),
        surfaceContainerHigh: const Color(0xFFF7E4DF),
        surfaceContainerHighest: const Color(0xFFF1DFDA),
        outline: const Color(0xFF85736E),
        outlineVariant: const Color(0xFFD8C2BC),
      );

  static final ColorScheme dark =
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFFFB5A0),
        onPrimary: const Color(0xFF561F0F),
        primaryContainer: const Color(0xFF723523),
        onPrimaryContainer: const Color(0xFFFFDBD1),
        tertiary: const Color(0xFFD8C58D),
        onTertiary: const Color(0xFF3B2F05),
        tertiaryContainer: const Color(0xFF534619),
        onTertiaryContainer: const Color(0xFFF5E1A7),
        surface: const Color(0xFF1A110F),
        onSurface: const Color(0xFFF1DFDA),
        onSurfaceVariant: const Color(0xFFD8C2BC),
        surfaceContainerLowest: const Color(0xFF140C0A),
        surfaceContainerLow: const Color(0xFF231917),
        surfaceContainer: const Color(0xFF271D1B),
        surfaceContainerHigh: const Color(0xFF322826),
        surfaceContainerHighest: const Color(0xFF3D3230),
      );
}
