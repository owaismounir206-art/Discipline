// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'app_style.dart';
import 'style_catalog.dart';

/// L'orologio degli sfondi che si muovono: uno solo per tutta l'app, così
/// lo sfondo è continuo tra una schermata e l'altra. Gira da 0 a 1 in un
/// minuto; fermo se lo stile non si muove o se le animazioni sono ridotte.
class StyleClock extends StatefulWidget {
  const StyleClock({super.key, required this.style, required this.child});

  final AppStyle style;
  final Widget child;

  static Animation<double> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ClockScope>()?.notifier ??
      const AlwaysStoppedAnimation(0);

  @override
  State<StyleClock> createState() => _StyleClockState();
}

class _StyleClockState extends State<StyleClock>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(StyleClock old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.style.ambient && !still) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ClockScope(notifier: _controller, child: widget.child);
}

class _ClockScope extends InheritedNotifier<Animation<double>> {
  const _ClockScope({required super.notifier, required super.child});

  // Chi disegna ascolta l'animazione da solo: niente ricostruzioni.
  @override
  bool updateShouldNotify(_ClockScope old) => old.notifier != notifier;
}

/// Lo sfondo dello stile dietro una schermata (opaco).
class StyleBackdrop extends StatelessWidget {
  const StyleBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style = AppStyle.of(context);
    final scheme = Theme.of(context).colorScheme;
    if (style.id == StyleId.material) {
      return ColoredBox(color: scheme.surface, child: child);
    }
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _BackdropPainter(
                style.id,
                scheme,
                StyleClock.of(context),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Ogni schermata nuova porta con sé lo sfondo dello stile, poi entra con
/// la transizione del sistema.
class StylePageTransitionsBuilder extends PageTransitionsBuilder {
  const StylePageTransitionsBuilder(this.inner);

  final PageTransitionsBuilder inner;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      inner.delegatedTransition;

  @override
  Duration get transitionDuration => inner.transitionDuration;

  @override
  Duration get reverseTransitionDuration => inner.reverseTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => inner.buildTransitions(
    route,
    context,
    animation,
    secondaryAnimation,
    StyleBackdrop(child: child),
  );
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.id, this.scheme, this.clock) : super(repaint: clock);

  final StyleId id;
  final ColorScheme scheme;
  final Animation<double> clock;

  /// Onda lenta: [cycles] giri al minuto.
  double _wave(int cycles, [double phase = 0]) =>
      math.sin((clock.value * cycles + phase) * 2 * math.pi);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = scheme.surface);
    switch (id) {
      case StyleId.material:
        break;
      case StyleId.glass:
        _glass(canvas, size);
      case StyleId.fluent:
        _glow(
          canvas,
          Offset(size.width, 0),
          size.width,
          const Color(0x140F6CBD),
        );
        _glow(
          canvas,
          Offset(0, size.height),
          size.width,
          const Color(0x0D8764B8),
        );
      case StyleId.cartoon:
        _dots(canvas, size, 20, 2, const Color(0x66FFFFFF));
        _cloud(canvas, Offset(size.width - 70 + 22 * _wave(2), 96), 92);
        _cloud(canvas, Offset(-20 - 18 * _wave(1, .3), size.height * 0.55), 74);
      case StyleId.swiss:
        // Una linea rossa sottile che si allunga come la lancetta dei secondi.
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width * clock.value, 3),
          Paint()..color = const Color(0xFFD70512),
        );
      case StyleId.brutal:
        _grid(canvas, size, 24, const Color(0x14000000));
      case StyleId.gameboy:
        final line = Paint()..color = const Color(0x0F0F380F);
        for (var y = 0.0; y < size.height; y += 3) {
          canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), line);
        }
      case StyleId.clay:
        _blob(
          canvas,
          Offset(size.width - 20, 150 + 12 * _wave(6)),
          38,
          const Color(0xFFFFC2B3),
        );
        _blob(
          canvas,
          Offset(14, size.height * 0.48 + 10 * _wave(6, .4)),
          24,
          const Color(0xFFA8EBD6),
        );
        _blob(
          canvas,
          Offset(size.width - 34, size.height - 190 + 12 * _wave(6, .7)),
          30,
          const Color(0xFFFFE39F),
        );
      case StyleId.cyber:
        _grid(canvas, size, 22, const Color(0x122AF5FF));
        // Una scansione che scende ogni sei secondi.
        final y = (clock.value * 10 % 1) * (size.height + 160) - 80;
        canvas.drawRect(
          Rect.fromLTWH(0, y - 60, size.width, 120),
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x002AF5FF), Color(0x1A2AF5FF), Color(0x002AF5FF)],
            ).createShader(Rect.fromLTWH(0, y - 60, size.width, 120)),
        );
      case StyleId.sport:
        // Banda arancione obliqua in alto a destra, lontana dal testo.
        final w = size.width;
        canvas.drawPath(
          Path()
            ..moveTo(w - 56, 0)
            ..lineTo(w, 0)
            ..lineTo(w, 210)
            ..lineTo(w - 12, 210)
            ..close(),
          Paint()..color = const Color(0xFFFF4D00),
        );
      case StyleId.zen:
        _paper(canvas, size);
        _glow(
          canvas,
          Offset(
            size.width * (0.8 + 0.08 * _wave(1)),
            size.height * (0.2 + 0.05 * _wave(1, .25)),
          ),
          size.width * 0.9,
          const Color(0x2955695A),
        );
      case StyleId.kanji:
        final gold = Paint()..color = const Color(0x0DC9A45C);
        for (var x = 48.0; x < size.width; x += 48) {
          canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), gold);
        }
        // Il sole rosso dietro l'intestazione, che sale e scende piano.
        canvas.drawCircle(
          Offset(size.width - 34, 96 + 8 * _wave(3)),
          104,
          Paint()..color = const Color(0xE6C8372A),
        );
    }
  }

  void _glass(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2756), Color(0xFF151A36), Color(0xFF2A1838)],
        ).createShader(rect),
    );
    final w = size.width;
    final h = size.height;
    _glow(
      canvas,
      Offset(w * (0.1 + 0.12 * _wave(2)), h * (0.25 + 0.06 * _wave(1, .2))),
      w * 0.75,
      const Color(0x70FF7A45),
    );
    _glow(
      canvas,
      Offset(w * (0.95 + 0.1 * _wave(1, .5)), h * (0.5 + 0.08 * _wave(2, .1))),
      w * 0.7,
      const Color(0x703C7BFF),
    );
    _glow(
      canvas,
      Offset(w * (0.3 + 0.12 * _wave(1, .8)), h * (0.88 + 0.05 * _wave(2, .6))),
      w * 0.65,
      const Color(0x60FF4F93),
    );
  }

  void _glow(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  void _dots(Canvas canvas, Size size, double step, double r, Color color) {
    final p = Paint()..color = color;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), r, p);
      }
    }
  }

  void _grid(Canvas canvas, Size size, double step, Color color) {
    final p = Paint()..color = color;
    for (var x = step; x < size.width; x += step) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), p);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
  }

  void _cloud(Canvas canvas, Offset at, double width) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(at.dx, at.dy, width, 30),
      const Radius.circular(20),
    );
    canvas
      ..drawRRect(r, Paint()..color = const Color(0xFFFFFFFF))
      ..drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFF1D1D1D),
      );
  }

  void _blob(Canvas canvas, Offset c, double r, Color color) {
    canvas
      ..drawCircle(
        c + const Offset(6, 10),
        r,
        Paint()
          ..color = const Color(0x2E5A46A0)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      )
      ..drawCircle(c, r, Paint()..color = color)
      ..drawCircle(
        c - Offset(r * 0.3, r * 0.35),
        r * 0.45,
        Paint()
          ..color = const Color(0x80FFFFFF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
  }

  static final _grain = () {
    final rnd = math.Random(7);
    return [
      for (var i = 0; i < 1400; i++) Offset(rnd.nextDouble(), rnd.nextDouble()),
    ];
  }();

  void _paper(Canvas canvas, Size size) {
    final dark = Paint()..color = const Color(0x142B2B28);
    final light = Paint()..color = const Color(0x33FFFFFF);
    for (final (i, p) in _grain.indexed) {
      canvas.drawRect(
        Rect.fromLTWH(p.dx * size.width, p.dy * size.height, 1.2, 1.2),
        i.isEven ? dark : light,
      );
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.id != id || old.scheme != scheme || old.clock != clock;
}

/// Colori per l'anteprima di uno stile nelle impostazioni.
({Color bg, Color card, Color accent, Color ink}) stylePreview(AppStyle s) {
  if (s.id == StyleId.material) {
    return (
      bg: const Color(0xFFFFF8F6),
      card: const Color(0xFFFCEAE5),
      accent: const Color(0xFF8F4C38),
      ink: const Color(0xFF231917),
    );
  }
  final c = styleScheme(s.id);
  final card = s.id == StyleId.glass
      ? const Color(0xFF3B3F63)
      : c.surfaceContainer;
  return (
    bg: c.surface,
    card: card,
    accent: c.primary == card ? c.secondary : c.primary,
    ink: c.onSurface,
  );
}
