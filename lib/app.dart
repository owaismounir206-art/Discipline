// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/data/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/ritmo_theme.dart';
import 'core/theme/theme_settings.dart';
import 'features/workout/data/today_plan.dart';

class RitmoApp extends ConsumerStatefulWidget {
  const RitmoApp({super.key});

  @override
  ConsumerState<RitmoApp> createState() => _RitmoAppState();
}

class _RitmoAppState extends ConsumerState<RitmoApp> {
  late final AppLifecycleListener _lifecycle;
  Timer? _midnight;

  @override
  void initState() {
    super.initState();
    // "Oggi" cambia a mezzanotte e quando l'app torna in primo piano.
    _lifecycle = AppLifecycleListener(onResume: _refreshDay);
    _scheduleMidnight();
  }

  void _refreshDay() {
    ref.invalidate(todayProvider);
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = ref.read(clockProvider)();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now), _refreshDay);
  }

  @override
  void dispose() {
    _midnight?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(themeSettingsProvider);

    // Su Android 12+ il sistema fornisce i colori dello sfondo; altrove sono
    // null e restano i colori di Ritmo.
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final useDynamic =
            settings.useDynamicColor &&
            lightDynamic != null &&
            darkDynamic != null;

        return MaterialApp.router(
          title: 'Ritmo',
          debugShowCheckedModeBanner: false,
          theme: useDynamic
              ? RitmoTheme.fromScheme(lightDynamic.harmonized())
              : RitmoTheme.light,
          darkTheme: useDynamic
              ? RitmoTheme.fromScheme(darkDynamic.harmonized())
              : RitmoTheme.dark,
          themeMode: settings.mode,
          locale: const Locale('it'),
          supportedLocales: const [Locale('it')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: router,
        );
      },
    );
  }
}
