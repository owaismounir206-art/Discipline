// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:material_ui/material_ui.dart';

import 'discipline_colors.dart';
import 'styles/app_style.dart';
import 'styles/style_backdrop.dart';
import 'styles/style_border.dart';
import 'styles/style_catalog.dart';

/// Raggi degli angoli usati in tutta l'app (dal design).
abstract final class DisciplineRadii {
  static const card = 24.0;
  static const cardLarge = 28.0;
  static const chip = 10.0;
}

/// Costruisce il tema di Discipline: colori, caratteri e forme dello stile
/// scelto (Material You di serie).
///
/// Per Material You lo schema di solito è [DisciplineColors.light] o
/// [DisciplineColors.dark]; su Android 12+ può arrivare dai colori dello
/// sfondo (dynamic color). Gli altri stili hanno i loro colori fissi.
abstract final class DisciplineTheme {
  static const fontFamily = 'Figtree';

  static ThemeData get light => fromScheme(DisciplineColors.light);

  static ThemeData get dark => fromScheme(DisciplineColors.dark);

  /// Tema delle schermate a tutto schermo (timer, sfida a tempo,
  /// fotocamera): scuro in Material You, quello dello stile negli altri.
  static ThemeData immersive(BuildContext context) {
    final current = Theme.of(context);
    if (AppStyle.of(context).id != StyleId.material ||
        current.brightness == Brightness.dark) {
      return current;
    }
    return dark;
  }

  /// Il tema di uno stile che ha i suoi colori.
  static ThemeData forStyle(AppStyle style) =>
      fromScheme(styleScheme(style.id), style: style);

  static ThemeData fromScheme(
    ColorScheme scheme, {
    AppStyle style = AppStyle.material,
  }) {
    final material = style.id == StyleId.material;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: style.bodyFont,
    );
    final text = _textTheme(base.textTheme, style);
    const buttonSize = Size(64, 48);
    final buttonText = text.labelLarge?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: style.uppercaseLabels ? 0.8 : null,
    );
    final card = material
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DisciplineRadii.card),
          )
        : StyleBorder.card(style, scheme);
    final small = _small(style, scheme);
    final crisp = switch (style.id) {
      StyleId.swiss ||
      StyleId.brutal ||
      StyleId.gameboy ||
      StyleId.cyber ||
      StyleId.sport => true,
      _ => false,
    };
    ButtonStyle buttons(ButtonStyle from, {bool solid = true}) {
      if (material) return from;
      final shape = _buttonShape(style, scheme, solid: solid);
      return from.copyWith(
        shape: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.pressed) ? shape.pressed : shape,
        ),
        splashFactory: crisp ? NoSplash.splashFactory : null,
        overlayColor: _pressedOverlay(style, scheme),
        textStyle: WidgetStatePropertyAll(buttonText),
      );
    }

    final surfaceBar = switch (style.id) {
      StyleId.material => scheme.surface,
      StyleId.glass => const Color(0xF0151A36),
      _ => scheme.surface.withValues(alpha: 0.96),
    };

    return base.copyWith(
      // Negli stili lo sfondo lo disegna StyleBackdrop dietro la schermata.
      scaffoldBackgroundColor: material ? scheme.surface : Colors.transparent,
      textTheme: text,
      extensions: [style],
      splashFactory: crisp ? NoSplash.splashFactory : null,
      appBarTheme: AppBarTheme(
        backgroundColor: material ? scheme.surface : Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: material ? null : 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      // Cambio schermata: quella del sistema, con lo sfondo dello stile.
      pageTransitionsTheme: material
          ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
              },
            )
          : const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: StylePageTransitionsBuilder(
                  FadeForwardsPageTransitionsBuilder(),
                ),
                TargetPlatform.iOS: StylePageTransitionsBuilder(
                  CupertinoPageTransitionsBuilder(),
                ),
              },
            ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainer,
        // Ombre piene e bagliori stanno fuori dal bordo: non si ritaglia.
        clipBehavior: style.paintsOutside ? Clip.none : Clip.antiAlias,
        shape: card,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: style.id == StyleId.glass
            ? const Color(0xFF242A4E)
            : material
            ? null
            : scheme.surfaceContainerLowest,
        shape: material ? null : StyleBorder.card(style, scheme),
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      bottomSheetTheme: material
          ? null
          : BottomSheetThemeData(
              backgroundColor: style.id == StyleId.glass
                  ? const Color(0xFF242A4E)
                  : scheme.surfaceContainerLowest,
              modalBackgroundColor: style.id == StyleId.glass
                  ? const Color(0xFF242A4E)
                  : scheme.surfaceContainerLowest,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(style.radius.clamp(0, 28)),
                ),
                side: style.borderWidth >= 2
                    ? BorderSide(
                        color: style.borderColor ?? scheme.outline,
                        width: style.borderWidth,
                      )
                    : BorderSide.none,
              ),
            ),
      popupMenuTheme: material
          ? null
          : PopupMenuThemeData(
              color: style.id == StyleId.glass
                  ? const Color(0xFF242A4E)
                  : scheme.surfaceContainerLowest,
              shape: small,
            ),
      filledButtonTheme: FilledButtonThemeData(
        style: buttons(
          FilledButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: buttonSize,
            textStyle: buttonText,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: buttons(
          ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: buttonSize,
            textStyle: buttonText,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: buttons(
          OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: buttonSize,
            textStyle: buttonText,
            side: material
                ? null
                : BorderSide(
                    color: scheme.outline,
                    width: style.borderWidth >= 2 ? 2 : 1,
                  ),
          ),
          solid: false,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: buttons(
          TextButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: buttonSize,
            textStyle: buttonText,
          ),
          solid: false,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          shape: material ? null : small,
        ),
      ),
      // Scelte (ChoiceChip): stesso aspetto ovunque, la selezionata piena.
      chipTheme: base.chipTheme.copyWith(
        shape: material
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DisciplineRadii.chip),
              )
            : small,
        labelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        selectedColor: scheme.secondaryContainer,
        backgroundColor: material ? null : scheme.surfaceContainerLow,
        showCheckmark: false,
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BorderSide(
                  color: style.borderWidth >= 2
                      ? scheme.outline
                      : scheme.secondaryContainer,
                  width: style.borderWidth >= 2 ? 2 : 1,
                )
              : BorderSide(
                  color: style.borderWidth >= 2
                      ? scheme.outline
                      : scheme.outlineVariant,
                  width: style.borderWidth >= 2 ? 2 : 1,
                ),
        ),
      ),
      // Campi di testo: tutti pieni, con gli angoli dello stile.
      inputDecorationTheme: _inputs(style, scheme),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: material
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
            : small,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            material ? DisciplineRadii.card : style.smallRadius,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      switchTheme: material
          ? null
          : SwitchThemeData(
              trackOutlineColor: WidgetStatePropertyAll(scheme.outline),
            ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        elevation: 0,
        backgroundColor: material ? scheme.surfaceContainer : surfaceBar,
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
    );
  }

  /// Forma dei pulsanti pieni o con contorno.
  static StyleBorder _buttonShape(
    AppStyle style,
    ColorScheme scheme, {
    required bool solid,
  }) {
    final outlined = style.borderWidth >= 2;
    return StyleBorder(
      radius: style.buttonRadius,
      corner: style.buttonCorner,
      side: solid && outlined
          ? BorderSide(
              color: style.borderColor ?? scheme.outline,
              width: style.borderWidth,
            )
          : BorderSide.none,
      shadowOffset: solid && style.hardShadow != null
          ? style.hardShadow! * 0.8
          : null,
      shadowColor: style.hardShadowColor ?? scheme.outline,
      glassEdge: style.glassEdge && solid,
      clayEdge: style.clayEdge && solid,
    );
  }

  /// Chip, campi, menu, avvisi: elementi piccoli.
  static OutlinedBorder _small(AppStyle style, ColorScheme scheme) =>
      StyleBorder(
        radius: style.smallRadius,
        corner: style.corner == CornerKind.cut
            ? CornerKind.cut
            : CornerKind.round,
      );

  /// Colore sotto il dito: negli stili netti cambia colore di colpo.
  static WidgetStateProperty<Color?>? _pressedOverlay(
    AppStyle style,
    ColorScheme scheme,
  ) => switch (style.id) {
    StyleId.swiss => WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.pressed) ? const Color(0xFFD70512) : null,
    ),
    StyleId.gameboy => WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.pressed) ? const Color(0x66306230) : null,
    ),
    StyleId.cyber => WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.pressed) ? const Color(0x55FF2E88) : null,
    ),
    _ => null,
  };

  static InputDecorationTheme _inputs(AppStyle style, ColorScheme scheme) {
    final material = style.id == StyleId.material;
    final r = BorderRadius.circular(material ? 16 : style.smallRadius);
    final bordered = !material && style.borderWidth > 0;
    final idle = bordered
        ? BorderSide(
            color: style.borderWidth >= 2
                ? scheme.outline
                : scheme.outlineVariant,
            width: style.borderWidth >= 2 ? 2 : 1,
          )
        : BorderSide.none;
    OutlineInputBorder border(BorderSide side) =>
        OutlineInputBorder(borderRadius: r, borderSide: side);
    return InputDecorationTheme(
      filled: true,
      fillColor: material
          ? scheme.surfaceContainerHigh
          : style.borderWidth >= 2
          ? scheme.surfaceContainerLowest
          : scheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(idle),
      enabledBorder: border(idle),
      focusedBorder: border(BorderSide(color: scheme.primary, width: 2)),
      errorBorder: border(BorderSide(color: scheme.error, width: 1.5)),
      focusedErrorBorder: border(BorderSide(color: scheme.error, width: 2)),
    );
  }

  /// Scala tipografica: titoli grandi e pesanti (nel carattere dei titoli
  /// dello stile), testo compatto.
  static TextTheme _textTheme(TextTheme base, AppStyle style) {
    final display = style.displayFont;
    // Caratteri molto larghi (pixel, Orbitron): solo per titoli e numeri.
    final wide = style.id == StyleId.gameboy || style.id == StyleId.cyber;
    final bodyScale = switch (style.id) {
      StyleId.cyber => 1.1,
      StyleId.gameboy => 0.95,
      _ => 1.0,
    };
    TextStyle? body(TextStyle? s, double size) =>
        s?.copyWith(fontSize: size * bodyScale);
    TextStyle? head(TextStyle? s) =>
        s?.copyWith(fontFamily: display, fontWeight: style.displayWeight);
    return base.copyWith(
      // Titolo delle schermate principali ("Ciao, Alex", "Cibo", ...).
      headlineMedium: head(base.headlineMedium)?.copyWith(
        fontSize: style.titleSize,
        height: 1.15,
        letterSpacing: style.titleLetterSpacing,
      ),
      // Numeri in evidenza ("12 allenamenti di fila").
      headlineSmall: head(base.headlineSmall)?.copyWith(
        fontSize: wide ? 22 : 28,
        height: 32 / 28,
        fontWeight: style.id == StyleId.material
            ? FontWeight.w800
            : style.displayWeight,
      ),
      // Titoli delle card e delle schermate secondarie.
      titleLarge: (wide ? base.titleLarge : head(base.titleLarge))?.copyWith(
        fontSize: style.id == StyleId.sport ? 24 : 22 * bodyScale,
        height: 28 / 22,
        fontWeight: wide ? FontWeight.w700 : style.displayWeight,
      ),
      titleMedium: body(
        base.titleMedium,
        15,
      )?.copyWith(fontWeight: FontWeight.w700),
      bodyMedium: body(base.bodyMedium, 14),
      bodySmall: body(base.bodySmall, 13),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 14 * bodyScale,
      ),
      labelMedium: body(base.labelMedium, 12),
    );
  }
}
