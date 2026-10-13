// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

/// Rapporto di contrasto WCAG tra due colori.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('RitmoColors', () {
    test('il tema chiaro usa i token del design', () {
      final s = RitmoColors.light;
      expect(s.brightness, Brightness.light);
      expect(s.primary, const Color(0xFF8F4C38));
      expect(s.primaryContainer, const Color(0xFFFFDBD1));
      expect(s.tertiaryContainer, const Color(0xFFF5E1A7));
      expect(s.surface, const Color(0xFFFFF8F6));
      expect(s.surfaceContainer, const Color(0xFFFCEAE5));
      expect(s.onSurface, const Color(0xFF231917));
      expect(s.outline, const Color(0xFF85736E));
    });

    test('il tema scuro usa i token del design', () {
      final s = RitmoColors.dark;
      expect(s.brightness, Brightness.dark);
      expect(s.primary, const Color(0xFFFFB5A0));
      expect(s.onPrimary, const Color(0xFF561F0F));
      expect(s.surface, const Color(0xFF1A110F));
      expect(s.surfaceContainer, const Color(0xFF271D1B));
      expect(s.onSurfaceVariant, const Color(0xFFD8C2BC));
    });

    for (final (name, s) in [
      ('chiaro', RitmoColors.light),
      ('scuro', RitmoColors.dark),
    ]) {
      test('contrasto del testo almeno 4.5:1 nel tema $name', () {
        final pairs = {
          'onSurface/surface': (s.onSurface, s.surface),
          'onSurfaceVariant/surface': (s.onSurfaceVariant, s.surface),
          'onSurfaceVariant/surfaceContainer': (
            s.onSurfaceVariant,
            s.surfaceContainer,
          ),
          'onPrimary/primary': (s.onPrimary, s.primary),
          'onPrimaryContainer/primaryContainer': (
            s.onPrimaryContainer,
            s.primaryContainer,
          ),
          'onSecondaryContainer/secondaryContainer': (
            s.onSecondaryContainer,
            s.secondaryContainer,
          ),
          'onTertiaryContainer/tertiaryContainer': (
            s.onTertiaryContainer,
            s.tertiaryContainer,
          ),
        };
        pairs.forEach((label, pair) {
          expect(
            contrast(pair.$1, pair.$2),
            greaterThanOrEqualTo(4.5),
            reason: label,
          );
        });
      });
    }
  });

  test('il tema usa Material 3 e il font Figtree', () {
    final theme = RitmoTheme.light;
    expect(theme.useMaterial3, isTrue);
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Figtree');
    expect(theme.navigationBarTheme.backgroundColor, const Color(0xFFFCEAE5));
  });
}
