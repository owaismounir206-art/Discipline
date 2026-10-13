// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/coming_soon_card.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/tab_scaffold.dart';

/// Scheda "Sfida": push-up in diretta con gli amici.
class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TabScaffold(
      header: ScreenHeader(
        title: 'Sfida',
        subtitle: 'Push-up in diretta con i tuoi amici',
        actions: [
          HeaderPillButton(
            icon: Icons.person_add_alt_outlined,
            label: 'Invita',
            onPressed: () => showComingSoon(context, 'Inviti'),
          ),
        ],
      ),
      children: const [
        ComingSoonCard(
          icon: Icons.bolt_outlined,
          title: 'Sfide in tempo reale',
          message:
              'Testa a testa in 60 secondi, gara a 50 o di squadra '
              'fino a 100: i contatori si aggiornano su entrambi i telefoni.',
          phase: 8,
        ),
        ComingSoonCard(
          icon: Icons.group_add_outlined,
          title: 'I tuoi amici',
          message: 'Aggiungi amici con un codice o un link d\'invito.',
          phase: 7,
        ),
      ],
    );
  }
}
