// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

import '../theme/motion.dart';
import '../feedback/ui_feedback.dart';
import '../theme/styles/app_style.dart';
import '../theme/styles/kanji_text.dart';
import '../theme/styles/style_border.dart';

/// Un'opzione di [SlidingSegmented].
typedef Segment<T> = ({T value, String label});

/// Selettore a pillola: la pillola scivola sull'opzione scelta, partendo
/// veloce e posandosi dolcemente (Material You).
class SlidingSegmented<T> extends StatelessWidget {
  const SlidingSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.semanticsLabel,
  });

  final List<Segment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = AppStyle.of(context);
    final index = segments.indexWhere((s) => s.value == selected);
    final duration = DisciplineMotion.of(context, style.moveDuration);
    final textTheme = Theme.of(context).textTheme;
    final outer = style.buttonRadius.clamp(0.0, 28.0);
    final corner = style.corner == CornerKind.cut
        ? CornerKind.cut
        : CornerKind.round;
    final track = StyleBorder(
      radius: outer,
      corner: corner,
      side: style.borderWidth > 0
          ? BorderSide(
              color: style.borderColor ?? scheme.outline,
              width: style.borderWidth.clamp(1, 2),
            )
          : BorderSide.none,
    );
    final thumb = StyleBorder(
      radius: (outer - 4).clamp(0.0, 24.0),
      corner: corner,
    );

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(4),
        decoration: ShapeDecoration(
          color: scheme.surfaceContainer,
          shape: track,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth / segments.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: duration,
                  curve: style.moveCurve,
                  left: index < 0 ? 0 : index * width,
                  top: 0,
                  bottom: 0,
                  width: width,
                  child: AnimatedOpacity(
                    duration: duration,
                    opacity: index < 0 ? 0 : 1,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: scheme.primary,
                        shape: thumb,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final (i, s) in segments.indexed)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: i == index,
                          inMutuallyExclusiveGroup: true,
                          child: InkWell(
                            customBorder: thumb,
                            onTap: () {
                              if (i == index) return;
                              UiFeedback.instance.play(UiSound.select);
                              onChanged(s.value);
                            },
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: AnimatedDefaultTextStyle(
                                  duration: duration,
                                  curve: DisciplineMotion.decelerate,
                                  style:
                                      (textTheme.labelLarge ??
                                              const TextStyle())
                                          .copyWith(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: i == index
                                                ? scheme.onPrimary
                                                : scheme.onSurfaceVariant,
                                          ),
                                  // Le etichette lunghe si stringono invece
                                  // di essere tagliate.
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      style.navLabel(s.label),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Una voce della barra di navigazione.
typedef NavItem = ({IconData icon, IconData selectedIcon, String label});

/// Barra di navigazione con l'evidenziatore che scivola sotto la voce
/// scelta, nella forma dello stile: pillola (Material You), capsula di vetro
/// che galleggia, barretta Fluent, freccia a pixel, pennellata...
class DisciplineNavigationBar extends StatelessWidget {
  const DisciplineNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final style = AppStyle.of(context);
    final duration = DisciplineMotion.of(context, style.moveDuration);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final look = _NavLook.of(style, scheme);

    final bar = SizedBox(
      height: look.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / items.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: duration,
                curve: style.moveCurve,
                left: selectedIndex * width,
                top: 0,
                bottom: 0,
                width: width,
                child: _Indicator(look: look, style: style, scheme: scheme),
              ),
              Row(
                children: [
                  for (final (i, item) in items.indexed)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == selectedIndex,
                        label: item.label,
                        excludeSemantics: true,
                        // Senza questo TalkBack legge la scheda ma non
                        // può aprirla (excludeSemantics toglie il tocco).
                        onTap: () => onSelected(i),
                        child: InkResponse(
                          onTap: () {
                            UiFeedback.instance.play(UiSound.select);
                            onSelected(i);
                          },
                          highlightShape: BoxShape.rectangle,
                          containedInkWell: true,
                          child: _NavDestination(
                            item: item,
                            index: i,
                            selected: i == selectedIndex,
                            look: look,
                            style: style,
                            textTheme: textTheme,
                            duration: duration,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );

    if (look.floating) {
      // Galleggia sopra il contenuto (che le scorre dietro).
      Widget capsule = DecoratedBox(
        decoration: ShapeDecoration(
          color: look.background,
          shape: look.shape,
          shadows: look.shadows,
        ),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: look.shape),
          child: bar,
        ),
      );
      if (look.blur) {
        capsule = ClipPath(
          clipper: ShapeBorderClipper(shape: look.shape),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: capsule,
          ),
        );
      }
      return Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, bottom + 10),
        child: Material(type: MaterialType.transparency, child: capsule),
      );
    }

    Widget docked = Material(
      color: look.background,
      shape: look.shape,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: bar,
      ),
    );
    if (look.blur) {
      docked = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: docked,
        ),
      );
    }
    return docked;
  }
}

/// Come appare la barra in uno stile.
class _NavLook {
  const _NavLook({
    required this.background,
    required this.shape,
    required this.selected,
    required this.unselected,
    this.height = 80,
    this.floating = false,
    this.blur = false,
    this.shadows = const [],
    this.labelSize = 12,
  });

  final Color background;
  final ShapeBorder shape;
  final Color selected;
  final Color unselected;
  final double height;
  final bool floating;
  final bool blur;
  final List<BoxShadow> shadows;
  final double labelSize;

  static _NavLook of(AppStyle style, ColorScheme scheme) {
    Border top(Color c, [double w = 1]) => Border(
      top: BorderSide(color: c, width: w),
    );
    switch (style.id) {
      case StyleId.material:
        return _NavLook(
          background: scheme.surfaceContainer,
          shape: const RoundedRectangleBorder(),
          selected: scheme.onSecondaryContainer,
          unselected: scheme.onSurfaceVariant,
        );
      case StyleId.glass:
        return const _NavLook(
          background: Color(0x26FFFFFF),
          shape: StyleBorder(radius: 999, glassEdge: true),
          selected: Color(0xFFFFFFFF),
          unselected: Color(0xD9FFFFFF),
          height: 68,
          floating: true,
          blur: true,
          shadows: [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        );
      case StyleId.fluent:
        return _NavLook(
          background: const Color(0xDBFCFCFC),
          shape: top(scheme.outlineVariant),
          selected: scheme.primary,
          unselected: scheme.onSurfaceVariant,
          height: 72,
          blur: true,
        );
      case StyleId.cartoon:
        return const _NavLook(
          background: Color(0xFFFFFFFF),
          shape: StyleBorder(
            radius: 22,
            side: BorderSide(color: Color(0xFF1D1D1D), width: 3),
          ),
          selected: Color(0xFF1D1D1D),
          unselected: Color(0xFF203A52),
          height: 70,
          floating: true,
          shadows: [BoxShadow(color: Color(0xFF1D1D1D), offset: Offset(0, 5))],
        );
      case StyleId.swiss:
        return _NavLook(
          background: scheme.surface,
          shape: top(scheme.onSurface, 2),
          selected: scheme.onSurface,
          unselected: scheme.onSurfaceVariant,
          height: 70,
          labelSize: 11,
        );
      case StyleId.brutal:
        return const _NavLook(
          background: Color(0xFFFFFFFF),
          shape: StyleBorder(
            side: BorderSide(color: Color(0xFF000000), width: 3),
          ),
          selected: Color(0xFF000000),
          unselected: Color(0xFF2B2B2B),
          height: 70,
          floating: true,
          shadows: [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5))],
          labelSize: 10.5,
        );
      case StyleId.gameboy:
        return _NavLook(
          background: scheme.surfaceContainer,
          shape: top(scheme.outline, 3),
          selected: scheme.onSurface,
          unselected: scheme.onSurface,
          height: 74,
        );
      case StyleId.clay:
        return const _NavLook(
          background: Color(0xFFFFFFFF),
          shape: StyleBorder(radius: 30, clayEdge: true),
          selected: Color(0xFF2A1F55),
          unselected: Color(0xFF574D7A),
          height: 72,
          floating: true,
          shadows: [
            BoxShadow(
              color: Color(0x335A46A0),
              blurRadius: 22,
              offset: Offset(6, 10),
            ),
          ],
        );
      case StyleId.cyber:
        return _NavLook(
          background: const Color(0xE605070D),
          shape: top(const Color(0xFF1FA7B0)),
          selected: scheme.primary,
          unselected: scheme.onSurfaceVariant,
          height: 72,
          labelSize: 12,
        );
      case StyleId.sport:
        return const _NavLook(
          background: Color(0xFF0D0D0D),
          shape: RoundedRectangleBorder(),
          selected: Color(0xFFFFFFFF),
          unselected: Color(0xFFBDBDBD),
          height: 72,
        );
      case StyleId.zen:
        return _NavLook(
          background: scheme.surface.withValues(alpha: 0.94),
          shape: top(const Color(0x402B2B28)),
          selected: scheme.onSurface,
          unselected: scheme.onSurfaceVariant,
          height: 76,
        );
      case StyleId.kanji:
        return _NavLook(
          background: scheme.surface.withValues(alpha: 0.94),
          shape: top(const Color(0x73C9A45C)),
          selected: scheme.onSurface,
          unselected: scheme.onSurfaceVariant,
          height: 78,
        );
    }
  }
}

/// L'evidenziatore della voce scelta.
class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.look,
    required this.style,
    required this.scheme,
  });

  final _NavLook look;
  final AppStyle style;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    Widget box(
      EdgeInsets inset,
      ShapeBorder shape,
      Color color, [
      List<BoxShadow> shadows = const [],
    ]) => Padding(
      padding: inset,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: color,
          shape: shape,
          shadows: shadows,
        ),
      ),
    );
    Widget bar({
      required double width,
      required double height,
      required Alignment at,
      required Color color,
      double radius = 0,
      double inset = 4,
      List<BoxShadow> shadows = const [],
    }) => Align(
      alignment: at,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: inset),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: shadows,
          ),
        ),
      ),
    );
    switch (style.id) {
      case StyleId.material:
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 64,
              height: 32,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      case StyleId.glass:
        return box(
          const EdgeInsets.all(6),
          const StyleBorder(radius: 999, glassEdge: true),
          const Color(0x38FFFFFF),
        );
      case StyleId.fluent:
        return bar(
          width: 18,
          height: 3,
          at: Alignment.bottomCenter,
          color: scheme.primary,
          radius: 2,
          inset: 6,
        );
      case StyleId.cartoon:
        return box(
          const EdgeInsets.all(7),
          const StyleBorder(
            radius: 14,
            side: BorderSide(color: Color(0xFF1D1D1D), width: 2),
          ),
          scheme.primaryContainer,
        );
      case StyleId.swiss:
        return bar(
          width: 40,
          height: 4,
          at: Alignment.topCenter,
          color: scheme.secondary,
          inset: 0,
        );
      case StyleId.brutal:
        return box(
          const EdgeInsets.all(6),
          const StyleBorder(
            side: BorderSide(color: Color(0xFF000000), width: 2.5),
          ),
          scheme.primaryContainer,
        );
      case StyleId.gameboy:
        return Align(
          alignment: Alignment.topCenter,
          child: CustomPaint(
            size: const Size(16, 10),
            painter: _ArrowPainter(scheme.onSurface),
          ),
        );
      case StyleId.clay:
        return box(
          const EdgeInsets.all(7),
          const StyleBorder(radius: 22, clayEdge: true),
          scheme.primaryContainer,
        );
      case StyleId.cyber:
        return bar(
          width: 44,
          height: 2,
          at: Alignment.topCenter,
          color: scheme.primary,
          inset: 0,
          shadows: [BoxShadow(color: scheme.primary, blurRadius: 10)],
        );
      case StyleId.sport:
        return bar(
          width: 999,
          height: 4,
          at: Alignment.topCenter,
          color: scheme.primary,
          inset: 0,
        );
      case StyleId.zen:
        return bar(
          width: 6,
          height: 6,
          at: Alignment.bottomCenter,
          color: scheme.secondary,
          radius: 3,
          inset: 7,
        );
      case StyleId.kanji:
        return bar(
          width: 26,
          height: 4,
          at: Alignment.bottomCenter,
          color: scheme.primary,
          radius: 3,
          inset: 7,
        );
    }
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close(),
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}

class _NavDestination extends StatelessWidget {
  const _NavDestination({
    required this.item,
    required this.index,
    required this.selected,
    required this.look,
    required this.style,
    required this.textTheme,
    required this.duration,
  });

  final NavItem item;
  final int index;
  final bool selected;
  final _NavLook look;
  final AppStyle style;
  final TextTheme textTheme;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final color = selected ? look.selected : look.unselected;
    final scheme = Theme.of(context).colorScheme;
    final Widget icon = style.isKanji && index < kanjiTabs.length
        ? Text(
            kanjiTabs[index],
            key: ValueKey(selected),
            style: TextStyle(
              fontFamily: 'YujiBoku',
              fontSize: 22,
              height: 1.1,
              color: selected ? scheme.primary : color,
            ),
          )
        : Icon(
            selected ? item.selectedIcon : item.icon,
            key: ValueKey(selected),
            size: 24,
            color: style.id == StyleId.material && selected
                ? Theme.of(context).colorScheme.onSecondaryContainer
                : color,
          );
    return Column(
      mainAxisAlignment: style.id == StyleId.material
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        if (style.id == StyleId.material) const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: duration,
          switchInCurve: DisciplineMotion.decelerate,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: Tween(begin: 0.7, end: 1.0).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: icon,
        ),
        SizedBox(height: style.id == StyleId.material ? 12 : 4),
        AnimatedDefaultTextStyle(
          duration: duration,
          style: (textTheme.labelMedium ?? const TextStyle()).copyWith(
            fontSize: look.labelSize,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: style.uppercaseLabels ? 0.6 : null,
            color: selected && style.id == StyleId.material
                ? Theme.of(context).colorScheme.onSurface
                : color,
          ),
          child: Text(
            style.navLabel(item.label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // La barra è alta 70-80: oltre 1,3× la scritta non ci starebbe.
            textScaler: MediaQuery.textScalerOf(context)
                .clamp(maxScaleFactor: 1.3),
          ),
        ),
      ],
    );
  }
}

/// Risponde al dito con l'animazione dello stile: si rimpicciolisce
/// (Material You), affonda nella sua ombra (brutale), si schiaccia
/// (cartoon), trema come gelatina (clay), si imprime come un timbro (kanji).
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.95});

  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  var _down = false;

  void _set(bool down) {
    if (down != _down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final style = AppStyle.of(context);
    final still =
        DisciplineMotion.of(context, DisciplineMotion.press) == Duration.zero;
    final (Duration down, Duration up, Curve release) = switch (style.press) {
      PressKind.scale => (
        DisciplineMotion.press,
        DisciplineMotion.press,
        Curves.easeOutBack,
      ),
      PressKind.sink => (
        const Duration(milliseconds: 60),
        const Duration(milliseconds: 90),
        Curves.linear,
      ),
      PressKind.squash || PressKind.jelly => (
        const Duration(milliseconds: 120),
        const Duration(milliseconds: 650),
        Curves.elasticOut,
      ),
      PressKind.stamp => (
        const Duration(milliseconds: 90),
        const Duration(milliseconds: 420),
        Curves.easeOutBack,
      ),
    };
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: PressedScope(
        pressed: _down && style.press == PressKind.sink,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _down ? 1 : 0),
          duration: still ? Duration.zero : (_down ? down : up),
          curve: _down ? DisciplineMotion.standard : release,
          child: widget.child,
          builder: (context, t, child) => Transform(
            alignment: Alignment.center,
            transform: _transform(style, t),
            child: child,
          ),
        ),
      ),
    );
  }

  Matrix4 _transform(AppStyle style, double t) {
    switch (style.press) {
      case PressKind.scale:
        final s = 1 - (1 - widget.scale) * t;
        return Matrix4.diagonal3Values(s, s, 1);
      case PressKind.sink:
        final o = (style.hardShadow ?? const Offset(4, 4)) * t;
        return Matrix4.translationValues(o.dx, o.dy, 0);
      case PressKind.squash:
        return Matrix4.diagonal3Values(1 + 0.04 * t, 1 - 0.08 * t, 1);
      case PressKind.jelly:
        return Matrix4.diagonal3Values(1 - 0.06 * t, 1 + 0.03 * t, 1);
      case PressKind.stamp:
        final s = 1 - 0.05 * t;
        return Matrix4.diagonal3Values(s, s, 1)..rotateZ(-0.02 * t);
    }
  }
}

/// Dice alle card dentro un [PressScale] che sono premute (le ombre piene
/// spariscono mentre la card affonda).
class PressedScope extends InheritedWidget {
  const PressedScope({super.key, required this.pressed, required super.child});

  final bool pressed;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PressedScope>()?.pressed ??
      false;

  @override
  bool updateShouldNotify(PressedScope old) => old.pressed != pressed;
}

/// Ingresso di una card con l'animazione dello stile, una dopo l'altra
/// ([index]).
class Entrance extends StatefulWidget {
  const Entrance({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  static const _maxSteps = 6;
  AnimationController? _controller;
  Animation<double>? _animation;
  late AppStyle _style;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _style = AppStyle.of(context);
    if (_controller != null) return;
    final run = DisciplineMotion.of(context, _style.enterDuration);
    final delay = run == Duration.zero
        ? Duration.zero
        : _style.stagger * widget.index.clamp(0, _maxSteps);
    final total = run + delay;
    _controller = AnimationController(vsync: this, duration: total);
    _animation = CurvedAnimation(
      parent: _controller!,
      curve: Interval(
        total == Duration.zero
            ? 0
            : delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: _style.enterCurve,
      ),
    );
    if (run == Duration.zero) {
      _controller!.value = 1;
    } else {
      _controller!.forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation!,
    child: widget.child,
    builder: (context, child) => _frame(_animation!.value, child!),
  );

  Widget _frame(double a, Widget child) {
    if (a >= 1) return child;
    double steps(int n) => (a * n).floor() / n;
    Widget fade(double o, Widget c) =>
        Opacity(opacity: o.clamp(0.0, 1.0), child: c);
    switch (_style.enter) {
      case EnterKind.fadeUp:
        return fade(
          a,
          FractionalTranslation(
            translation: Offset(0, 0.08 * (1 - a)),
            child: child,
          ),
        );
      case EnterKind.grow:
        return fade(a, Transform.scale(scale: 0.94 + 0.06 * a, child: child));
      case EnterKind.drop:
        return fade(
          a * 2,
          Transform.translate(
            offset: Offset(0, -36 * (1 - a)),
            child: Transform.scale(scale: 0.9 + 0.1 * a, child: child),
          ),
        );
      case EnterKind.wipe:
        return ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: a.clamp(0.001, 1.0),
            child: child,
          ),
        );
      case EnterKind.slam:
        final s = steps(3);
        return fade(
          s == 0 ? 0 : 1,
          Transform.translate(offset: Offset(-28 * (1 - s), 0), child: child),
        );
      case EnterKind.steps:
        final s = steps(4);
        return fade(
          s,
          Transform.translate(offset: Offset(0, 16 * (1 - s)), child: child),
        );
      case EnterKind.puff:
        return fade(
          a * 1.6,
          Transform.scale(scale: 0.7 + 0.3 * a, child: child),
        );
      case EnterKind.boot:
        final o = a < 0.4
            ? a / 0.4
            : a < 0.55
            ? 0.25
            : a < 0.7
            ? 1.0
            : a < 0.8
            ? 0.5
            : 1.0;
        return fade(o, child);
      case EnterKind.slide:
        final from = widget.index.isEven ? -1.0 : 1.0;
        return ClipRect(
          child: FractionalTranslation(
            translation: Offset(from * (1 - a), 0),
            child: child,
          ),
        );
      case EnterKind.ink:
        return fade(a, Transform.scale(scale: 0.985 + 0.015 * a, child: child));
      case EnterKind.brush:
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: a.clamp(0.001, 1.0),
            child: child,
          ),
        );
    }
  }
}

/// Le schede dell'app una sopra l'altra: quella scelta appare sfumando e
/// crescendo appena, le altre restano nascoste ma ricordano dove eri.
class FadeThroughBranches extends StatelessWidget {
  const FadeThroughBranches({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      for (final (i, child) in children.indexed)
        _FadeThroughBranch(active: i == currentIndex, child: child),
    ],
  );
}

class _FadeThroughBranch extends StatefulWidget {
  const _FadeThroughBranch({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_FadeThroughBranch> createState() => _FadeThroughBranchState();
}

class _FadeThroughBranchState extends State<_FadeThroughBranch>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    value: widget.active ? 1 : 0,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: DisciplineMotion.decelerate,
  );
  late final _scale = Tween(begin: 0.97, end: 1.0).animate(_curve);

  @override
  void didUpdateWidget(_FadeThroughBranch old) {
    super.didUpdateWidget(old);
    if (widget.active == old.active) return;
    if (!widget.active) {
      _controller.value = 0;
      return;
    }
    final duration = DisciplineMotion.of(context, DisciplineMotion.medium);
    if (duration == Duration.zero) {
      _controller.value = 1;
    } else {
      _controller
        ..duration = duration
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Offstage(
    offstage: !widget.active,
    child: TickerMode(
      enabled: widget.active,
      child: FadeTransition(
        opacity: _curve,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    ),
  );
}

/// Un numero che conta fino al suo valore (e scorre quando cambia).
class CountUp extends StatelessWidget {
  const CountUp(this.value, {super.key, this.style, this.format});

  final int value;
  final TextStyle? style;

  /// Testo intorno al numero, es. (n) => '+$n punti'.
  final String Function(int value)? format;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.toDouble()),
    duration: DisciplineMotion.of(context, const Duration(milliseconds: 900)),
    curve: DisciplineMotion.decelerate,
    builder: (context, v, _) {
      final n = v.round();
      return Text(format?.call(n) ?? '$n', style: style);
    },
  );
}

/// Appare crescendo con un piccolo rimbalzo (icone di conferma, medaglie).
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: DisciplineMotion.of(context, DisciplineMotion.long),
    curve: Curves.easeOutBack,
    builder: (context, v, child) => Opacity(
      opacity: v.clamp(0, 1),
      child: Transform.scale(scale: 0.5 + 0.5 * v, child: child),
    ),
    child: child,
  );
}
