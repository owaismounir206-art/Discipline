// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;

import 'package:discipline/core/theme/discipline_theme.dart';
import 'package:discipline/core/theme/styles/app_style.dart';
import 'package:discipline/core/theme/styles/style_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Un colore trasparente (vetro) appoggiato su uno sfondo.
Color _over(Color top, Color under) => Color.alphaBlend(top, under);

void main() {
  for (final style in appStyles.where((s) => s.id != StyleId.material)) {
    group(style.label, () {
      final s = styleScheme(style.id);

      // Gli sfondi su cui finisce il testo. Per il vetro anche il punto più
      // chiaro dello sfondo colorato.
      final grounds = <String, Color>{
        'surface': s.surface,
        if (style.id == StyleId.glass)
          'surface chiara': _over(const Color(0x70FF7A45), s.surface),
      };
      Color on(Color c, Color ground) => _over(c, ground);

      test('testo leggibile (almeno 4,5:1)', () {
        final failures = <String>[];
        void check(String name, Color fg, Color bg, [double min = 4.5]) {
          final c = _contrast(fg, bg);
          if (c < min) failures.add('$name: ${c.toStringAsFixed(2)}');
        }

        for (final MapEntry(key: g, value: ground) in grounds.entries) {
          final containers = {
            'surfaceContainerLowest': on(s.surfaceContainerLowest, ground),
            'surfaceContainerLow': on(s.surfaceContainerLow, ground),
            'surfaceContainer': on(s.surfaceContainer, ground),
            'surfaceContainerHigh': on(s.surfaceContainerHigh, ground),
            'surfaceContainerHighest': on(s.surfaceContainerHighest, ground),
          };
          check('onSurface/$g', s.onSurface, ground);
          check('onSurfaceVariant/$g', on(s.onSurfaceVariant, ground), ground);
          // primary si usa anche come colore del testo (pulsanti di testo,
          // titoli di sezione, link).
          check('primary/$g', s.primary, ground);
          for (final MapEntry(key: name, value: c) in containers.entries) {
            check('onSurface/$name su $g', s.onSurface, c);
            check('onSurfaceVariant/$name su $g', on(s.onSurfaceVariant, c), c);
          }
          check(
            'primary/surfaceContainer su $g',
            s.primary,
            containers['surfaceContainer']!,
          );
          for (final (name, fg, bg) in [
            ('onPrimary/primary', s.onPrimary, s.primary),
            (
              'onPrimaryContainer/primaryContainer',
              s.onPrimaryContainer,
              s.primaryContainer,
            ),
            ('onSecondary/secondary', s.onSecondary, s.secondary),
            (
              'onSecondaryContainer/secondaryContainer',
              s.onSecondaryContainer,
              s.secondaryContainer,
            ),
            ('onTertiary/tertiary', s.onTertiary, s.tertiary),
            (
              'onTertiaryContainer/tertiaryContainer',
              s.onTertiaryContainer,
              s.tertiaryContainer,
            ),
            ('onError/error', s.onError, s.error),
            ('error/surface', s.error, s.surface),
            (
              'onInverseSurface/inverseSurface',
              s.onInverseSurface,
              s.inverseSurface,
            ),
          ]) {
            final back = on(bg, ground);
            check('$name su $g', on(fg, back), back);
          }
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
      });

      test('il tema si costruisce con i caratteri dello stile', () {
        final theme = DisciplineTheme.forStyle(style);
        expect(theme.extension<AppStyle>(), style);
        expect(theme.colorScheme, s);
        if (style.bodyFont != null) {
          expect(theme.textTheme.bodyMedium?.fontFamily, style.bodyFont);
        }
      });
    });
  }

  test('ogni stile ha un nome diverso e si ritrova dal suo id', () {
    expect(appStyles.map((s) => s.label).toSet(), hasLength(appStyles.length));
    for (final s in appStyles) {
      expect(styleById(s.id.name), s);
    }
    expect(styleById('sconosciuto'), AppStyle.material);
  });
}
