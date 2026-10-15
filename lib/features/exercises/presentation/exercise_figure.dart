// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import 'figure/motions.dart';
import 'figure/skeleton.dart';

export 'figure/motions.dart' show motionFor;
export 'figure/skeleton.dart' show Motion;

/// Figurina che ripete il movimento dell'esercizio: scheletro con ossa di
/// lunghezza fissa, gomiti e ginocchia che si piegano da soli, attrezzi
/// (sbarra, parallele, panca, muro) e pause dove l'esercizio le prevede.
/// Con "riduci animazioni" resta ferma sulla posa più significativa.
class ExerciseFigure extends StatefulWidget {
  const ExerciseFigure({
    super.key,
    required this.motion,
    this.size = const Size(120, 90),
    this.color,
    this.animate = true,
  });

  final Motion motion;
  final Size size;
  final Color? color;

  /// false = ferma sulla posa più significativa (es. nelle griglie, dove
  /// tante figurine in movimento insieme distraggono e consumano batteria).
  final bool animate;

  @override
  State<ExerciseFigure> createState() => _ExerciseFigureState();
}

class _ExerciseFigureState extends State<ExerciseFigure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.motion.ms),
  );

  bool get _reduce =>
      !widget.animate ||
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ExerciseFigure old) {
    super.didUpdateWidget(old);
    if (old.motion != widget.motion || old.animate != widget.animate) {
      _controller.duration = Duration(milliseconds: widget.motion.ms);
      _controller.reset();
      _sync();
    }
  }

  void _sync() {
    if (_reduce) {
      _controller
        ..stop()
        ..value = _stillPoint(widget.motion);
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  /// Punto del ciclo in cui si trova la posa "ferma".
  static double _stillPoint(Motion m) {
    final total = m.keys.fold<double>(0, (s, k) => s + k.$2);
    final before = m.keys.take(m.still).fold<double>(0, (s, k) => s + k.$2);
    return total == 0 ? 0 : before / total;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: widget.size,
            painter: _FigurePainter(
              motion: widget.motion,
              t: _controller.value,
              color: widget.color ?? scheme.primary,
              ground: scheme.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _FigurePainter extends CustomPainter {
  _FigurePainter({
    required this.motion,
    required this.t,
    required this.color,
    required this.ground,
  });

  final Motion motion;
  final double t;
  final Color color;
  final Color ground;

  @override
  void paint(Canvas canvas, Size size) =>
      paintFigure(canvas, size, motion, t, color: color, ground: ground);

  @override
  bool shouldRepaint(_FigurePainter old) =>
      old.t != t ||
      old.motion != motion ||
      old.color != color ||
      old.ground != ground;
}

/// Per l'anteprima di tutti i movimenti (tool/figures_test.dart).
const debugAllMotions = allMotions;
