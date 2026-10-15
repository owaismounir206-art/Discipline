// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import 'discipline_colors.dart';

/// Raggi degli angoli usati in tutta l'app (dal design).
abstract final class DisciplineRadii {
  static const card = 24.0;
  static const cardLarge = 28.0;
  static const chip = 10.0;
}

/// Costruisce il tema Material 3 di Discipline a partire da uno schema di colori.
///
/// Lo schema di solito è [DisciplineColors.light] o [DisciplineColors.dark]; su Android
/// 12+ può arrivare dai colori dello sfondo (dynamic color).
abstract final class DisciplineTheme {
  static const fontFamily = 'Figtree';

  static ThemeData get light => fromScheme(DisciplineColors.light);

  static ThemeData get dark => fromScheme(DisciplineColors.dark);

  static ThemeData fromScheme(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
    );
    final text = _textTheme(base.textTheme);
    const pill = StadiumBorder();
    const buttonSize = Size(64, 48);
    final buttonText = text.labelLarge?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w700,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      // Cambio schermata Material You: la nuova entra scorrendo e sfumando.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DisciplineRadii.card),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: pill,
          minimumSize: buttonSize,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: pill,
          minimumSize: buttonSize,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: pill,
          minimumSize: buttonSize,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: pill,
          minimumSize: buttonSize,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      // Scelte (ChoiceChip): stesso aspetto ovunque, la selezionata piena.
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DisciplineRadii.chip),
        ),
        labelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        selectedColor: scheme.secondaryContainer,
        showCheckmark: false,
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BorderSide(color: scheme.secondaryContainer)
              : BorderSide(color: scheme.outlineVariant),
        ),
      ),
      // Campi di testo: tutti pieni e arrotondati (prima alcuni erano solo
      // sottolineati).
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        elevation: 0,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return text.labelMedium?.copyWith(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DisciplineRadii.card),
        ),
      ),
    );
  }

  /// Scala tipografica del design: titoli grandi e pesanti, testo compatto.
  static TextTheme _textTheme(TextTheme base) => base.copyWith(
    // Titolo delle schermate principali ("Ciao, Alex", "Cibo", ...).
    headlineMedium: base.headlineMedium?.copyWith(
      fontSize: 30,
      height: 36 / 30,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    // Numeri in evidenza ("12 allenamenti di fila").
    headlineSmall: base.headlineSmall?.copyWith(
      fontSize: 28,
      height: 32 / 28,
      fontWeight: FontWeight.w800,
    ),
    // Titoli delle card e delle schermate secondarie.
    titleLarge: base.titleLarge?.copyWith(
      fontSize: 22,
      height: 28 / 22,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w700,
    ),
    bodyMedium: base.bodyMedium?.copyWith(fontSize: 14),
    bodySmall: base.bodySmall?.copyWith(fontSize: 13),
    labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
  );
}
