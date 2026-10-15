// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

import '../domain/exercise.dart';

/// Il tipo di movimento disegnato dalla figurina.
enum FigureMotion { pushUp, pull, squat, plank, pike, jump, stretch, hang }

/// Sceglie l'animazione adatta a un esercizio.
FigureMotion motionFor(Exercise e) {
  final id = e.id;
  if (id.contains('handstand') || id.contains('hspu')) return FigureMotion.pike;
  if (e.chain == ChainId.mobility) return FigureMotion.stretch;
  if (id.contains('dead_hang') || id.contains('lever')) {
    return FigureMotion.hang;
  }
  if (e.chain == ChainId.cardio) {
    return id.contains('mountain') || id.contains('bear')
        ? FigureMotion.plank
        : FigureMotion.jump;
  }
  return switch (e.muscleGroup) {
    MuscleGroup.chest => FigureMotion.pushUp,
    MuscleGroup.back => FigureMotion.pull,
    MuscleGroup.legs => FigureMotion.squat,
    MuscleGroup.shoulders => FigureMotion.pike,
    MuscleGroup.core =>
      e.measure == Measure.seconds ? FigureMotion.plank : FigureMotion.pushUp,
    MuscleGroup.fullBody => FigureMotion.jump,
  };
}

/// Figurina che ripete il movimento all'infinito, con un ritmo morbido.
/// Con "riduci animazioni" resta ferma a metà movimento.
class ExerciseFigure extends StatefulWidget {
  const ExerciseFigure({
    super.key,
    required this.motion,
    this.size = const Size(120, 90),
    this.color,
  });

  final FigureMotion motion;
  final Size size;
  final Color? color;

  @override
  State<ExerciseFigure> createState() => _ExerciseFigureState();
}

class _ExerciseFigureState extends State<ExerciseFigure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _controller
        ..stop()
        ..value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
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
              // Andata e ritorno con accelerazione dolce (seno).
              t: (1 - math.cos(_controller.value * 2 * math.pi)) / 2,
              color: widget.color ?? scheme.primary,
              ground: scheme.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Punti del corpo in coordinate 0–1 (x da sinistra, y dall'alto).
typedef _Pose = Map<String, Offset>;

_Pose _lerp(_Pose a, _Pose b, double t) => {
  for (final k in {...a.keys, ...b.keys})
    k: Offset.lerp(a[k] ?? b[k]!, b[k] ?? a[k]!, t)!,
};

/// Due pose per movimento: inizio e fine.
(_Pose, _Pose) _poses(FigureMotion m) => switch (m) {
  FigureMotion.pushUp => (
    {
      'head': const Offset(.18, .30),
      'neck': const Offset(.25, .38),
      'hip': const Offset(.58, .52),
      'knee': const Offset(.75, .62),
      'foot': const Offset(.90, .72),
      'elbow': const Offset(.25, .55),
      'hand': const Offset(.25, .72),
    },
    {
      'head': const Offset(.18, .55),
      'neck': const Offset(.25, .60),
      'hip': const Offset(.58, .66),
      'knee': const Offset(.75, .69),
      'foot': const Offset(.90, .72),
      'elbow': const Offset(.37, .58),
      'hand': const Offset(.25, .72),
    },
  ),
  FigureMotion.plank => (
    {
      'head': const Offset(.18, .44),
      'neck': const Offset(.25, .50),
      'hip': const Offset(.58, .58),
      'knee': const Offset(.75, .64),
      'foot': const Offset(.90, .72),
      'elbow': const Offset(.25, .72),
      'hand': const Offset(.33, .72),
    },
    {
      'head': const Offset(.18, .42),
      'neck': const Offset(.25, .48),
      'hip': const Offset(.58, .55),
      'knee': const Offset(.70, .60),
      'foot': const Offset(.90, .72),
      'elbow': const Offset(.25, .72),
      'hand': const Offset(.33, .72),
    },
  ),
  FigureMotion.pull => (
    {
      'head': const Offset(.5, .40),
      'neck': const Offset(.5, .48),
      'hip': const Offset(.5, .74),
      'knee': const Offset(.5, .86),
      'foot': const Offset(.5, .98),
      'elbow': const Offset(.40, .26),
      'hand': const Offset(.38, .08),
      'elbow2': const Offset(.60, .26),
      'hand2': const Offset(.62, .08),
    },
    {
      'head': const Offset(.5, .08),
      'neck': const Offset(.5, .18),
      'hip': const Offset(.5, .44),
      'knee': const Offset(.5, .58),
      'foot': const Offset(.5, .70),
      'elbow': const Offset(.30, .22),
      'hand': const Offset(.38, .08),
      'elbow2': const Offset(.70, .22),
      'hand2': const Offset(.62, .08),
    },
  ),
  FigureMotion.hang => (
    {
      'head': const Offset(.5, .26),
      'neck': const Offset(.5, .32),
      'hip': const Offset(.5, .58),
      'knee': const Offset(.5, .74),
      'foot': const Offset(.5, .90),
      'elbow': const Offset(.42, .18),
      'hand': const Offset(.38, .08),
      'elbow2': const Offset(.58, .18),
      'hand2': const Offset(.62, .08),
    },
    {
      'head': const Offset(.42, .26),
      'neck': const Offset(.46, .30),
      'hip': const Offset(.66, .40),
      'knee': const Offset(.80, .44),
      'foot': const Offset(.94, .48),
      'elbow': const Offset(.40, .18),
      'hand': const Offset(.38, .08),
      'elbow2': const Offset(.56, .18),
      'hand2': const Offset(.62, .08),
    },
  ),
  FigureMotion.squat => (
    {
      'head': const Offset(.5, .10),
      'neck': const Offset(.5, .20),
      'hip': const Offset(.5, .50),
      'knee': const Offset(.52, .72),
      'foot': const Offset(.5, .95),
      'elbow': const Offset(.62, .32),
      'hand': const Offset(.72, .32),
    },
    {
      'head': const Offset(.56, .32),
      'neck': const Offset(.54, .42),
      'hip': const Offset(.34, .68),
      'knee': const Offset(.62, .72),
      'foot': const Offset(.5, .95),
      'elbow': const Offset(.70, .48),
      'hand': const Offset(.82, .48),
    },
  ),
  FigureMotion.pike => (
    {
      'head': const Offset(.5, .88),
      'neck': const Offset(.5, .76),
      'hip': const Offset(.5, .44),
      'knee': const Offset(.5, .24),
      'foot': const Offset(.5, .04),
      'elbow': const Offset(.42, .86),
      'hand': const Offset(.40, .97),
      'elbow2': const Offset(.58, .86),
      'hand2': const Offset(.60, .97),
    },
    {
      'head': const Offset(.5, .92),
      'neck': const Offset(.5, .82),
      'hip': const Offset(.5, .50),
      'knee': const Offset(.5, .30),
      'foot': const Offset(.5, .10),
      'elbow': const Offset(.36, .90),
      'hand': const Offset(.40, .97),
      'elbow2': const Offset(.64, .90),
      'hand2': const Offset(.60, .97),
    },
  ),
  FigureMotion.jump => (
    {
      'head': const Offset(.5, .14),
      'neck': const Offset(.5, .24),
      'hip': const Offset(.5, .54),
      'knee': const Offset(.48, .74),
      'foot': const Offset(.47, .95),
      'knee2': const Offset(.52, .74),
      'foot2': const Offset(.53, .95),
      'elbow': const Offset(.44, .38),
      'hand': const Offset(.44, .52),
      'elbow2': const Offset(.56, .38),
      'hand2': const Offset(.56, .52),
    },
    {
      'head': const Offset(.5, .08),
      'neck': const Offset(.5, .18),
      'hip': const Offset(.5, .48),
      'knee': const Offset(.38, .68),
      'foot': const Offset(.28, .88),
      'knee2': const Offset(.62, .68),
      'foot2': const Offset(.72, .88),
      'elbow': const Offset(.36, .10),
      'hand': const Offset(.32, .00),
      'elbow2': const Offset(.64, .10),
      'hand2': const Offset(.68, .00),
    },
  ),
  FigureMotion.stretch => (
    {
      'head': const Offset(.30, .44),
      'neck': const Offset(.36, .50),
      'hip': const Offset(.60, .60),
      'knee': const Offset(.70, .80),
      'foot': const Offset(.88, .95),
      'elbow': const Offset(.24, .62),
      'hand': const Offset(.16, .78),
    },
    {
      'head': const Offset(.34, .58),
      'neck': const Offset(.40, .62),
      'hip': const Offset(.62, .64),
      'knee': const Offset(.72, .82),
      'foot': const Offset(.88, .95),
      'elbow': const Offset(.22, .74),
      'hand': const Offset(.10, .88),
    },
  ),
};

class _FigurePainter extends CustomPainter {
  _FigurePainter({
    required this.motion,
    required this.t,
    required this.color,
    required this.ground,
  });

  final FigureMotion motion;
  final double t;
  final Color color;
  final Color ground;

  @override
  void paint(Canvas canvas, Size size) {
    final (a, b) = _poses(motion);
    final pose = _lerp(a, b, t);
    final w = size.width;
    final h = size.height;
    Offset at(String k) => Offset(pose[k]!.dx * w, pose[k]!.dy * h);
    final stroke = math.max(3.0, w / 28);

    final line = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Pavimento o sbarra.
    final groundPaint = Paint()
      ..color = ground
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    if (motion == FigureMotion.pull || motion == FigureMotion.hang) {
      canvas.drawLine(
        Offset(w * .2, h * .08),
        Offset(w * .8, h * .08),
        groundPaint..strokeWidth = stroke * .8,
      );
    } else {
      canvas.drawLine(
        Offset(w * .04, h * .98),
        Offset(w * .96, h * .98),
        groundPaint,
      );
    }

    void limb(String a, String b, [String? c]) {
      final path = Path()
        ..moveTo(at(a).dx, at(a).dy)
        ..lineTo(at(b).dx, at(b).dy);
      if (c != null) path.lineTo(at(c).dx, at(c).dy);
      canvas.drawPath(path, line);
    }

    // Busto e gambe.
    limb('neck', 'hip');
    limb('hip', 'knee', 'foot');
    if (pose.containsKey('knee2')) limb('hip', 'knee2', 'foot2');
    // Braccia.
    limb('neck', 'elbow', 'hand');
    if (pose.containsKey('elbow2')) limb('neck', 'elbow2', 'hand2');
    // Testa.
    canvas.drawCircle(
      at('head'),
      lerpDouble(w / 13, w / 12, t)!,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_FigurePainter old) =>
      old.t != t || old.motion != motion || old.color != color;
}
