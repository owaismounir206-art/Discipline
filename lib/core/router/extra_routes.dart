// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/account/presentation/invite_link_screen.dart';
import '../../features/account/presentation/login_screen.dart';
import '../../features/challenge/presentation/live_challenge_screen.dart';
import '../../features/food/domain/nutrition.dart';
import '../../features/food/presentation/body_data_screen.dart';
import '../../features/food/presentation/food_search_screen.dart';
import '../../features/food/presentation/nutrition_screen.dart';
import '../../features/food/presentation/scanner_screen.dart';
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
  _page(root, Routes.nutrition, (_) => const NutritionScreen()),
  _page(root, Routes.bodyData, (_) => const BodyDataScreen()),
  _page(root, Routes.login, (_) => const LoginScreen()),
  _page(
    root,
    '${Routes.challengeLive}/:id',
    (state) => LiveChallengeScreen(
      roomId: state.pathParameters['id']!,
      solo: state.uri.queryParameters['solo'] == '1',
    ),
  ),
  _page(
    root,
    '/invito/:code',
    (state) => InviteLinkScreen(code: state.pathParameters['code']!),
  ),
];
