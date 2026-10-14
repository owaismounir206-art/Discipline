// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

/// Regole del movimento (Material You): gli elementi partono veloci e si
/// posano dolcemente, come un oggetto vero che frena.
abstract final class RitmoMotion {
  /// Curva enfatizzata in decelerazione: ~80% della strada nel primo terzo.
  static const decelerate = Cubic(0.05, 0.7, 0.1, 1);

  /// Per ciò che esce di scena: va via in fretta.
  static const accelerate = Cubic(0.3, 0, 0.8, 0.15);

  /// Curva standard di Material 3.
  static const standard = Cubic(0.2, 0, 0, 1);

  /// Pressione dei pulsanti.
  static const press = Duration(milliseconds: 180);
  static const short = Duration(milliseconds: 200);

  /// Selettori, interruttori, barra di navigazione.
  static const medium = Duration(milliseconds: 400);

  /// Cambio schermata, ingressi delle card.
  static const long = Duration(milliseconds: 500);

  /// Zero se il telefono chiede di ridurre le animazioni.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false
      ? Duration.zero
      : duration;
}
