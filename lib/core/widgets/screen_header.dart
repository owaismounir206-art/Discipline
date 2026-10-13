// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

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
    final small = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

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
                  child: Text(title, style: theme.textTheme.headlineMedium),
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
