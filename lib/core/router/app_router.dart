// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/challenge/challenge_screen.dart';
import '../../features/food/food_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/today/today_screen.dart';
import '../../features/workout/workout_screen.dart';
import '../widgets/home_shell.dart';
import 'routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRoute _tab(String path, Widget screen) => GoRoute(
  path: path,
  pageBuilder: (context, state) => NoTransitionPage(child: screen),
);

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.today,
    routes: [
      // Ogni scheda ha la sua pila di schermate e ricorda dove eri rimasto.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [_tab(Routes.today, const TodayScreen())],
          ),
          StatefulShellBranch(
            routes: [_tab(Routes.workout, const WorkoutScreen())],
          ),
          StatefulShellBranch(
            routes: [_tab(Routes.challenge, const ChallengeScreen())],
          ),
          StatefulShellBranch(routes: [_tab(Routes.food, const FoodScreen())]),
          StatefulShellBranch(
            routes: [_tab(Routes.progress, const ProgressScreen())],
          ),
        ],
      ),
      // Schermate a tutto schermo, sopra la navigation bar.
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
