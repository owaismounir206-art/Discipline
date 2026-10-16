// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/data/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/discipline_theme.dart';
import 'core/theme/styles/app_style.dart';
import 'core/theme/styles/style_backdrop.dart';
import 'core/theme/styles/style_catalog.dart';
import 'core/theme/theme_settings.dart';
import 'core/update/update_checker.dart';
import 'features/rewards/domain/rewards.dart';
import 'features/workout/data/today_plan.dart';

class DisciplineApp extends ConsumerStatefulWidget {
  const DisciplineApp({super.key});

  @override
  ConsumerState<DisciplineApp> createState() => _DisciplineAppState();
}

class _DisciplineAppState extends ConsumerState<DisciplineApp> {
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
    // Se l'app resta aperta per giorni, controlla ancora gli aggiornamenti
    // (al massimo una volta al giorno, lo garantisce il repository).
    ref.invalidate(availableUpdateProvider);
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
    // null e restano i colori di Discipline.
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final useDynamic =
            settings.useDynamicColor &&
            lightDynamic != null &&
            darkDynamic != null;
        final style = styleById(settings.style);
        // Gli stili hanno colori fissi: chiaro e scuro sono lo stesso tema.
        final styled = style.id == StyleId.material
            ? null
            : DisciplineTheme.forStyle(style);

        return MaterialApp.router(
          title: 'Discipline',
          debugShowCheckedModeBanner: false,
          theme:
              styled ??
              (useDynamic
                  ? DisciplineTheme.fromScheme(lightDynamic.harmonized())
                  : _paletteTheme(settings.palette, Brightness.light)),
          darkTheme:
              styled ??
              (useDynamic
                  ? DisciplineTheme.fromScheme(darkDynamic.harmonized())
                  : _paletteTheme(settings.palette, Brightness.dark)),
          themeMode: settings.mode,
          // Un solo orologio per gli sfondi che si muovono.
          builder: (context, child) =>
              StyleClock(style: style, child: child ?? const SizedBox()),
          locale: const Locale('it'),
          supportedLocales: const [Locale('it')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: router,
        );
      },
    );
  }
}

/// Tema dai colori scelti: il corallo usa i colori esatti del design, gli
/// altri sono generati dal loro colore base (Material You).
ThemeData _paletteTheme(String name, Brightness brightness) {
  final palette = AppPalette.values.asNameMap()[name] ?? AppPalette.coral;
  if (palette == AppPalette.coral) {
    return brightness == Brightness.light
        ? DisciplineTheme.light
        : DisciplineTheme.dark;
  }
  return DisciplineTheme.fromScheme(
    ColorScheme.fromSeed(seedColor: palette.seed, brightness: brightness),
  );
}
