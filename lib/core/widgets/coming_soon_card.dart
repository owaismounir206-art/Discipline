// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../theme/ritmo_theme.dart';

/// Segnaposto per le parti dell'app non ancora costruite.
class ComingSoonCard extends StatelessWidget {
  const ComingSoonCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.phase,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Fase del piano di lavoro in cui arriva questa funzione.
  final int phase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(RitmoRadii.cardLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: ExcludeSemantics(
              child: Icon(icon, size: 28, color: scheme.onPrimaryContainer),
            ),
          ),
          Text(title, style: theme.textTheme.titleLarge),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Chip(
            label: Text('In arrivo · fase $phase'),
            backgroundColor: scheme.tertiaryContainer,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onTertiaryContainer,
              fontWeight: FontWeight.w700,
            ),
            side: BorderSide.none,
          ),
        ],
      ),
    );
  }
}
