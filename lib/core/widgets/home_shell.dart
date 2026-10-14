// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

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
      body: navigationShell,
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
