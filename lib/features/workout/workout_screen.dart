// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/coming_soon_card.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/tab_scaffold.dart';

/// Scheda "Allenati": schede di allenamento e catalogo esercizi.
class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabScaffold(
      header: ScreenHeader(
        title: 'Allenati',
        subtitle: 'Corpo libero, al tuo livello',
      ),
      children: [
        ComingSoonCard(
          icon: Icons.fitness_center_outlined,
          title: 'Catalogo esercizi',
          message:
              'Push-up, trazioni, dip, gambe, core e skill, organizzati '
              'in catene di progressione: dalla variante più facile alla '
              'più difficile.',
          phase: 2,
        ),
        ComingSoonCard(
          icon: Icons.timer_outlined,
          title: 'Allenamento in corso',
          message:
              'Timer di recupero, contatore delle ripetizioni e '
              'schermo sempre acceso.',
          phase: 3,
        ),
      ],
    );
  }
}
