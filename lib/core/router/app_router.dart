// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/challenge/challenge_screen.dart';
import '../../features/exercises/presentation/exercise_detail_screen.dart';
import '../../features/food/food_screen.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/profile/presentation/athlete_profile_screen.dart';
import '../../features/profile/presentation/welcome_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/today/today_screen.dart';
import '../../features/workout/domain/workout_plan.dart';
import '../../features/workout/presentation/session_screen.dart';
import '../../features/workout/workout_screen.dart';
import '../widgets/home_shell.dart';
import '../widgets/motion_widgets.dart';
import 'extra_routes.dart';
import 'routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRoute _tab(String path, Widget screen) => GoRoute(
  path: path,
  pageBuilder: (context, state) => NoTransitionPage(child: screen),
);

GoRoute _page(String path, Widget Function(GoRouterState state) builder) =>
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: path,
      builder: (context, state) => builder(state),
    );

/// Stato del primo avvio: null finché il profilo non è stato letto.
class _OnboardingGate extends ChangeNotifier {
  bool? hasProfile;

  void update(bool? value) {
    if (value == hasProfile) return;
    hasProfile = value;
    notifyListeners();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final gate = _OnboardingGate();
  ref.listen(
    athleteProfileProvider,
    (_, next) => gate.update(next.hasValue ? next.value != null : null),
    fireImmediately: true,
  );

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.today,
    refreshListenable: gate,
    redirect: (context, state) {
      final hasProfile = gate.hasProfile;
      final onboarding = state.matchedLocation.startsWith(Routes.welcome);
      if (hasProfile == false && !onboarding) return Routes.welcome;
      // Con il profilo già creato si esce dal benvenuto dalla schermata del
      // profilo, dopo aver spiegato il punto di partenza.
      return null;
    },
    routes: [
      // Ogni scheda ha la sua pila di schermate e ricorda dove eri rimasto.
      // Cambiando scheda la nuova appare con una dissolvenza (fade through).
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            FadeThroughBranches(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
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
      _page(Routes.welcome, (_) => const WelcomeScreen()),
      _page(
        Routes.onboardingProfile,
        (_) => const AthleteProfileScreen(onboarding: true),
      ),
      _page(Routes.athleteProfile, (_) => const AthleteProfileScreen()),
      _page(Routes.settings, (_) => const SettingsScreen()),
      _page(
        Routes.session,
        (state) => SessionScreen(
          template: state.extra is WorkoutTemplate
              ? state.extra! as WorkoutTemplate
              : WorkoutTemplate.fullBody,
        ),
      ),
      _page(
        '/esercizio/:id',
        (state) =>
            ExerciseDetailScreen(exerciseId: state.pathParameters['id']!),
      ),
      ...extraRoutes(_rootNavigatorKey),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
