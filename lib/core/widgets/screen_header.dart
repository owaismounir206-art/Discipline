// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../theme/styles/app_style.dart';
import '../theme/styles/kanji_text.dart';

/// Intestazione delle schermate principali: titolo grande, una riga di
/// contesto (sopra o sotto il titolo) e azioni a destra.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.overline,
    this.subtitle,
    this.actions = const [],
  });

  final String title;

  /// Testo piccolo sopra il titolo (es. la data nella schermata Oggi).
  final String? overline;

  /// Testo piccolo sotto il titolo.
  final String? subtitle;

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = AppStyle.of(context);
    final small = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final kanji = style.isKanji ? kanjiTitles[title] : null;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                if (overline != null)
                  Text(
                    overline!,
                    style: small?.copyWith(fontWeight: FontWeight.w500),
                  ),
                Semantics(
                  header: true,
                  label: title,
                  excludeSemantics: kanji != null,
                  child: kanji == null
                      ? _Title(text: style.title(title), style: style)
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          spacing: 10,
                          children: [
                            // Il titolo in kanji a pennello, l'italiano
                            // accanto più piccolo.
                            Text(
                              kanji,
                              style: TextStyle(
                                fontFamily: 'YujiBoku',
                                fontSize: 46,
                                height: 1.05,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  title.toUpperCase(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    letterSpacing: 3,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                if (subtitle != null) Text(subtitle!, style: small),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Il titolo grande; nello stile cartoon è bianco con il contorno nero.
class _Title extends StatelessWidget {
  const _Title({required this.text, required this.style});

  final String text;
  final AppStyle style;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.headlineMedium;
    if (style.id != StyleId.cartoon) return Text(text, style: base);
    return Stack(
      children: [
        Text(
          text,
          style: base?.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..strokeJoin = StrokeJoin.round
              ..color = const Color(0xFF1D1D1D),
          ),
        ),
        Text(text, style: base?.copyWith(color: const Color(0xFFFFFFFF))),
      ],
    );
  }
}

/// Pulsante tonale a pillola usato nelle intestazioni ("Scansiona", "Invita").
class HeaderPillButton extends StatelessWidget {
  const HeaderPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsetsDirectional.only(start: 12, end: 16),
        textStyle: Theme.of(context).textTheme.labelLarge
            ?.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}
