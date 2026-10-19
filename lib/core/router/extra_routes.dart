// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' hide Focus;

import '../../features/ai/presentation/coach_screen.dart';
import '../../features/ai/presentation/kitchen_screen.dart';
import '../../features/camera/presentation/camera_counter_screen.dart';
import '../../features/challenge/domain/timed.dart';
import '../../features/challenge/presentation/friend_challenge_screen.dart';
import '../../features/challenge/presentation/timed_challenge_screen.dart';
import '../../features/exercises/domain/exercise.dart';
import '../../features/exercises/domain/skill_guide.dart';
import '../../features/exercises/presentation/chain_path_screen.dart';
import '../../features/exercises/presentation/skills_screen.dart';
import '../../features/food/domain/homemade.dart';
import '../../features/food/domain/nutrition.dart';
import '../../features/food/presentation/ai_food_screen.dart';
import '../../features/food/presentation/ai_settings_screen.dart';
import '../../features/food/presentation/body_data_screen.dart';
import '../../features/food/presentation/food_search_screen.dart';
import '../../features/food/presentation/homemade_screen.dart';
import '../../features/food/presentation/nutrition_screen.dart';
import '../../features/food/presentation/scanner_screen.dart';
import '../../features/timer/domain/interval.dart';
import '../../features/workout/presentation/focus_cards.dart';
import '../../features/workout/presentation/my_program_screen.dart';
import '../../features/timer/presentation/interval_run_screen.dart';
import '../../features/timer/presentation/interval_setup_screen.dart';
import 'routes.dart';

GoRoute _page(
  GlobalKey<NavigatorState> root,
  String path,
  Widget Function(GoRouterState state) builder,
) => GoRoute(
  parentNavigatorKey: root,
  path: path,
  builder: (context, state) => builder(state),
);

/// Schermate a tutto schermo di cibo, account, sfide e fotocamera.
List<RouteBase> extraRoutes(GlobalKey<NavigatorState> root) => [
  _page(
    root,
    Routes.foodSearch,
    (state) => FoodSearchScreen(
      meal: state.extra is Meal ? state.extra! as Meal : Meal.snack,
    ),
  ),
  _page(root, Routes.foodScanner, (_) => const ScannerScreen()),
  _page(
    root,
    Routes.foodPick,
    (_) => const FoodSearchScreen(meal: Meal.snack, pickOnly: true),
  ),
  _page(
    root,
    Routes.aiFood,
    (state) => AiFoodScreen(
      meal: state.extra is Meal ? state.extra! as Meal : Meal.snack,
    ),
  ),
  _page(root, Routes.aiSettings, (_) => const AiSettingsScreen()),
  _page(root, Routes.kitchen, (_) => const KitchenScreen()),
  _page(root, Routes.coach, (_) => const CoachScreen()),
  _page(
    root,
    Routes.homemade,
    (state) => HomemadeScreen(
      recipe: state.extra is HomemadeRecipe
          ? state.extra! as HomemadeRecipe
          : null,
      prefill: state.extra is HomemadeDraft
          ? (state.extra! as HomemadeDraft).recipe
          : null,
    ),
  ),
  _page(root, Routes.nutrition, (_) => const NutritionScreen()),
  _page(root, Routes.bodyData, (_) => const BodyDataScreen()),
  _page(root, Routes.cameraCounter, (_) => const CameraCounterScreen()),
  _page(root, Routes.skills, (_) => const SkillsScreen()),
  _page(root, Routes.programs, (_) => const MyProgramScreen()),
  _page(root, '/skill/:id', (state) {
    final guide = skillGuideById(state.pathParameters['id']!);
    return guide == null
        ? const SkillsScreen()
        : SkillDetailScreen(guide: guide);
  }),
  _page(
    root,
    '/specifico/:zone',
    (state) => FocusScreen(
      focus:
          Focus.values.asNameMap()[state.pathParameters['zone']] ?? Focus.core,
    ),
  ),
  _page(
    root,
    Routes.timedChallenge,
    (state) => TimedChallengeScreen(
      mode:
          TimedMode.values.asNameMap()[state.uri.queryParameters['modo']] ??
          TimedMode.minute,
      friendCode: state.uri.queryParameters['codice'],
    ),
  ),
  _page(root, Routes.friendChallenge, (_) => const FriendChallengeScreen()),
  _page(root, Routes.timer, (_) => const IntervalSetupScreen()),
  _page(
    root,
    Routes.timerRunning,
    (state) => IntervalRunScreen(
      config: IntervalConfig.fromQuery(state.uri.queryParameters),
    ),
  ),
  _page(
    root,
    Routes.path(':chain'),
    (state) => ChainPathScreen(
      chain:
          ChainId.values.asNameMap()[state.pathParameters['chain']] ??
          ChainId.push,
    ),
  ),
];
