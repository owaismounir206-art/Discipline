// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/ritmo_theme.dart';
import 'core/theme/theme_settings.dart';

class RitmoApp extends ConsumerWidget {
  const RitmoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
