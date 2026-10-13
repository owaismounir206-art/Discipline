// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/coming_soon_card.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/tab_scaffold.dart';

/// Scheda "Progressi": grafici, record e abilità sbloccate.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TabScaffold(
      header: ScreenHeader(
        title: 'Progressi',
        actions: [
          IconButton(
            tooltip: 'Condividi',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            icon: const Icon(Icons.share_outlined),
            onPressed: () => showComingSoon(context, 'Condivisione'),
          ),
        ],
      ),
      children: const [
        ComingSoonCard(
          icon: Icons.bar_chart,
          title: 'Ripetizioni e record',
          message:
              'Grafico per settimana, mese e anno, push-up del mese, '
              'trazioni e plank massimi, streak record e abilità sbloccate.',
          phase: 5,
        ),
      ],
    );
  }
}
