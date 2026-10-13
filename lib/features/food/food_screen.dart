// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/utils/italian_date.dart';
import '../../core/widgets/coming_soon_card.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/tab_scaffold.dart';

/// Scheda "Cibo": diario dei pasti e consigli.
class FoodScreen extends StatelessWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TabScaffold(
      header: ScreenHeader(
        title: 'Cibo',
        subtitle: 'Oggi, ${formatItalianDate(DateTime.now())}',
        actions: [
          HeaderPillButton(
            icon: Icons.qr_code_scanner,
            label: 'Scansiona',
            onPressed: () => showComingSoon(context, 'Scanner'),
          ),
        ],
      ),
      children: const [
        ComingSoonCard(
          icon: Icons.restaurant_menu_outlined,
          title: 'Diario del giorno',
          message:
              'Calorie rimanenti, proteine, carboidrati, grassi e '
              'zuccheri per colazione, pranzo, spuntino e cena.',
          phase: 6,
        ),
        ComingSoonCard(
          icon: Icons.lightbulb_outline,
          title: 'Consigli per te',
          message:
              'Il tuo fabbisogno giornaliero e 3 piatti consigliati '
              'per il prossimo pasto. Sono stime: non sostituiscono un '
              'nutrizionista.',
          phase: 6,
        ),
      ],
    );
  }
}
