// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'app_style.dart';

/// Il contorno di card e pulsanti negli stili: angoli tondi, tagliati o
/// inclinati, più gli effetti dello stile (ombra piena spostata, bagliore,
/// riflesso del vetro, luci interne della plastilina).
///
/// Ombra piena e bagliore vanno fuori dal bordo: chi la usa non deve
/// ritagliare il contenuto con questa forma (Clip.none).
@immutable
class StyleBorder extends OutlinedBorder {
  const StyleBorder({
    super.side,
    this.radius = 0,
    this.corner = CornerKind.round,
    this.shadowOffset,
    this.shadowColor = const Color(0xFF000000),
    this.glow,
    this.glassEdge = false,
    this.clayEdge = false,
  });

  /// Contorno della card per uno stile.
  factory StyleBorder.card(AppStyle style, ColorScheme scheme) => StyleBorder(
    radius: style.radius,
    corner: style.corner,
    side: style.borderWidth > 0
        ? BorderSide(
            color: style.borderColor ?? scheme.outline,
            width: style.borderWidth,
          )
        : BorderSide.none,
    shadowOffset: style.hardShadow,
    shadowColor: style.hardShadowColor ?? scheme.outline,
    glow: style.glow,
    glassEdge: style.glassEdge,
    clayEdge: style.clayEdge,
  );

  final double radius;
  final CornerKind corner;
  final Offset? shadowOffset;
  final Color shadowColor;
  final Color? glow;
  final bool glassEdge;
  final bool clayEdge;

  Path _path(Rect r) {
    final cut = math.min(radius, r.shortestSide / 2);
    switch (corner) {
      case CornerKind.round:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(r, Radius.circular(cut)));
      case CornerKind.cut:
        // Tagliati in alto a destra e in basso a sinistra, come un HUD.
        return Path()
          ..moveTo(r.left, r.top)
          ..lineTo(r.right - cut, r.top)
          ..lineTo(r.right, r.top + cut)
          ..lineTo(r.right, r.bottom)
          ..lineTo(r.left + cut, r.bottom)
          ..lineTo(r.left, r.bottom - cut)
          ..close();
      case CornerKind.slant:
        final s = math.min(radius, r.width / 4);
        return Path()
          ..moveTo(r.left + s, r.top)
          ..lineTo(r.right, r.top)
          ..lineTo(r.right - s, r.bottom)
          ..lineTo(r.left, r.bottom)
          ..close();
    }
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.strokeInset));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final path = _path(rect);
    if (glow case final g?) {
      canvas.drawPath(
        path,
        Paint()
          ..color = g
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10),
      );
    }
    if (shadowOffset case final o? when o != Offset.zero) {
      canvas.drawPath(
        Path.combine(PathOperation.difference, _path(rect.shift(o)), path),
        Paint()..color = shadowColor,
      );
    }
    if (clayEdge) {
      canvas
        ..save()
        ..clipPath(path)
        ..drawPath(
          path.shift(const Offset(5, 6)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10
            ..color = const Color(0x99FFFFFF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        )
        ..drawPath(
          path.shift(const Offset(-6, -7)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 12
            ..color = const Color(0x1A2A1460)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        )
        ..restore();
    }
    if (glassEdge) {
      canvas.drawPath(
        _path(rect.deflate(0.5)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x99FFFFFF), Color(0x1FFFFFFF), Color(0x40FFFFFF)],
            stops: [0, 0.6, 1],
          ).createShader(rect),
      );
    }
    if (side.style != BorderStyle.none && side.width > 0) {
      canvas.drawPath(_path(rect.deflate(side.width / 2)), side.toPaint());
    }
  }

  @override
  StyleBorder copyWith({
    BorderSide? side,
    double? radius,
    Offset? shadowOffset,
    Color? shadowColor,
  }) => StyleBorder(
    side: side ?? this.side,
    radius: radius ?? this.radius,
    corner: corner,
    shadowOffset: shadowOffset ?? this.shadowOffset,
    shadowColor: shadowColor ?? this.shadowColor,
    glow: glow,
    glassEdge: glassEdge,
    clayEdge: clayEdge,
  );

  /// Senza ombra spostata (pulsante premuto).
  StyleBorder get pressed => StyleBorder(
    side: side,
    radius: radius,
    corner: corner,
    shadowColor: shadowColor,
    glow: glow,
    glassEdge: glassEdge,
    clayEdge: clayEdge,
  );

  @override
  ShapeBorder scale(double t) => StyleBorder(
    side: side.scale(t),
    radius: radius * t,
    corner: corner,
    shadowOffset: shadowOffset == null ? null : shadowOffset! * t,
    shadowColor: shadowColor,
    glow: glow,
    glassEdge: glassEdge,
    clayEdge: clayEdge,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) =>
      a is StyleBorder ? (t < 0.5 ? a : this) : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) =>
      b is StyleBorder ? (t < 0.5 ? this : b) : super.lerpTo(b, t);

  @override
  bool operator ==(Object other) =>
      other is StyleBorder &&
      other.side == side &&
      other.radius == radius &&
      other.corner == corner &&
      other.shadowOffset == shadowOffset &&
      other.shadowColor == shadowColor &&
      other.glow == glow &&
      other.glassEdge == glassEdge &&
      other.clayEdge == clayEdge;

  @override
  int get hashCode => Object.hash(
    side,
    radius,
    corner,
    shadowOffset,
    shadowColor,
    glow,
    glassEdge,
    clayEdge,
  );
}
