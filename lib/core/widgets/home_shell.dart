// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/rewards/data/rewards_state.dart';
import '../../features/rewards/domain/rewards.dart';
import 'celebration.dart';
import 'motion_widgets.dart';

/// Contenitore delle 5 schede con la navigation bar Material 3 in basso.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const items = <NavItem>[
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Oggi'),
    (
      icon: Icons.monitor_heart_outlined,
      selectedIcon: Icons.monitor_heart,
      label: 'Allenati',
    ),
    (icon: Icons.group_outlined, selectedIcon: Icons.group, label: 'Sfide'),
    (
      icon: Icons.restaurant_outlined,
      selectedIcon: Icons.restaurant,
      label: 'Cibo',
    ),
    (
      icon: Icons.show_chart_outlined,
      selectedIcon: Icons.show_chart,
      label: 'Progressi',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _RankWatcher(child: navigationShell),
      bottomNavigationBar: DisciplineNavigationBar(
        selectedIndex: navigationShell.currentIndex,
        items: items,
        // Toccare di nuovo la scheda attiva riporta all'inizio della scheda.
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// Festeggia quando si sale di grado.
class _RankWatcher extends ConsumerWidget {
  const _RankWatcher({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(pointsProvider, (previous, next) {
      // Solo tra due valori caricati: all'avvio non è una promozione.
      final before = previous?.value;
      final after = next.value;
      if (before == null || after == null) return;
      // Solo pochi punti nuovi (un allenamento, una sfida): un backup
      // importato o i dati cancellati cambiano tutto in una volta e non
      // sono una promozione.
      final added = after.length - before.length;
      if (added < 1 || added > 5) return;
      final old = rankFor(lifetimeOf(before));
      final now = rankFor(lifetimeOf(after));
      if (now.rank.index <= old.rank.index) return;
      celebrate(
        context,
        kicker: 'Nuovo grado',
        title: now.rank.label,
        subtitle: now.next == null
            ? 'Il grado più alto: complimenti!'
            : 'Prossimo: ${now.next!.label}, mancano ${now.missing} punti',
        icon: Icons.military_tech,
      );
    });
    return child;
  }
}
