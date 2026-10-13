// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/utils/italian_date.dart';
import '../../core/widgets/coming_soon_card.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/tab_scaffold.dart';

/// Scheda "Oggi": streak, livello, allenamento del giorno e inviti.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TabScaffold(
      header: ScreenHeader(
        overline: formatItalianDate(DateTime.now(), capitalize: true),
        title: 'Ciao!',
        actions: [
          IconButton(
            tooltip: 'Notifiche',
            color: scheme.onSurfaceVariant,
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => showComingSoon(context, 'Notifiche'),
          ),
          const SizedBox(width: 4),
          IconButton.filled(
            tooltip: 'Profilo e impostazioni',
            style: IconButton.styleFrom(
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              fixedSize: const Size(44, 44),
            ),
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      children: const [
        ComingSoonCard(
          icon: Icons.local_fire_department_outlined,
          title: 'La tua streak',
          message:
              'Conta solo i giorni che scegli tu. '
              'I giorni di riposo non la interrompono.',
          phase: 4,
        ),
        ComingSoonCard(
          icon: Icons.sports_gymnastics_outlined,
          title: 'Il tuo profilo atleta',
          message:
              'Difficoltà, esperienza, giorni di allenamento e un breve '
              'test iniziale per partire dal livello giusto.',
          phase: 2,
        ),
        ComingSoonCard(
          icon: Icons.play_circle_outline,
          title: 'Allenamento di oggi',
          message:
              'La scheda del giorno con timer di recupero, serie e '
              'varianti più facili o più difficili.',
          phase: 3,
        ),
      ],
    );
  }
}
