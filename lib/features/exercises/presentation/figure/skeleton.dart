// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;
import 'dart:ui';

import 'package:meta/meta.dart';

// Figurina vista di lato, rivolta a destra. Coordinate in "altezze" (una
// persona in piedi è alta circa 1), con y verso il basso e il pavimento a
// y = 0. Gli angoli sono in gradi: 0 = destra, 90 = giù, -90 = su.

/// Lunghezze dei segmenti del corpo.
abstract final class Bones {
  static const spineLow = 0.14;
  static const spineHigh = 0.15;
  static const neck = 0.085;
  static const head = 0.055;
  static const upperArm = 0.15;
  static const forearm = 0.14;
  static const thigh = 0.22;
  static const shin = 0.22;
  static const foot = 0.06;

  /// Distanza tra caviglia e pavimento in piedi.
  static const ankle = 0.03;
}

Offset dir(double degrees) {
  final r = degrees * math.pi / 180;
  return Offset(math.cos(r), math.sin(r));
}

double angleOf(Offset v) => math.atan2(v.dy, v.dx) * 180 / math.pi;

/// Come si muove un braccio o una gamba.
@immutable
sealed class Limb {
  const Limb();
}

/// La mano (o il piede) va a questo punto; gomito e ginocchio si piegano da
/// soli (cinematica inversa a due segmenti).
final class To extends Limb {
  const To(this.x, this.y);

  final double x;
  final double y;

  Offset get point => Offset(x, y);
}

/// Angoli fissi dei due segmenti (braccio e avambraccio, coscia e tibia).
final class Ang extends Limb {
  const Ang(this.first, this.second);

  final double first;
  final double second;
}

/// Una posa: posizione del bacino, curva della schiena, testa e arti.
@immutable
class Pose {
  const Pose({
    required this.hip,
    this.low = -90,
    this.high,
    this.neck,
    required this.arm,
    this.arm2,
    required this.leg,
    this.leg2,
    this.toe,
    this.toe2,
  });

  final Offset hip;

  /// Direzione bacino → metà schiena.
  final double low;

  /// Direzione metà schiena → spalle (uguale a [low] se manca).
  final double? high;

  /// Direzione spalle → testa (uguale alla schiena se manca).
  final double? neck;

  /// Braccio e gamba dal lato vicino; quelli lontani li copiano se mancano.
  final Limb arm;
  final Limb? arm2;
  final Limb leg;
  final Limb? leg2;

  /// Direzione del piede (se manca segue la tibia).
  final double? toe;
  final double? toe2;

  double get highAngle => high ?? low;
  double get neckAngle => neck ?? highAngle;
}

double _lerpAngle(double a, double b, double t) {
  var d = (b - a) % 360;
  if (d > 180) d -= 360;
  if (d < -180) d += 360;
  return a + d * t;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

Limb _lerpLimb(Limb a, Limb b, double t) => switch ((a, b)) {
  (final To p, final To q) => To(_lerp(p.x, q.x, t), _lerp(p.y, q.y, t)),
  (final Ang p, final Ang q) => Ang(
    _lerpAngle(p.first, q.first, t),
    _lerpAngle(p.second, q.second, t),
  ),
  _ => t < 0.5 ? a : b,
};

double? _lerpOptional(double? a, double? b, double t) =>
    a == null || b == null ? (t < 0.5 ? a : b) : _lerpAngle(a, b, t);

Pose lerpPose(Pose a, Pose b, double t) => Pose(
  hip: Offset.lerp(a.hip, b.hip, t)!,
  low: _lerpAngle(a.low, b.low, t),
  high: _lerpAngle(a.highAngle, b.highAngle, t),
  neck: _lerpAngle(a.neckAngle, b.neckAngle, t),
  arm: _lerpLimb(a.arm, b.arm, t),
  arm2: _lerpLimb(a.arm2 ?? a.arm, b.arm2 ?? b.arm, t),
  leg: _lerpLimb(a.leg, b.leg, t),
  leg2: _lerpLimb(a.leg2 ?? a.leg, b.leg2 ?? b.leg, t),
  toe: _lerpOptional(a.toe, b.toe, t),
  toe2: _lerpOptional(a.toe2 ?? a.toe, b.toe2 ?? b.toe, t),
);

/// Le articolazioni calcolate da una posa.
@immutable
class Joints {
  const Joints({
    required this.hip,
    required this.mid,
    required this.shoulder,
    required this.head,
    required this.elbow,
    required this.hand,
    required this.elbow2,
    required this.hand2,
    required this.knee,
    required this.ankle,
    required this.tip,
    required this.knee2,
    required this.ankle2,
    required this.tip2,
  });

  final Offset hip, mid, shoulder, head;
  final Offset elbow, hand, elbow2, hand2;
  final Offset knee, ankle, tip, knee2, ankle2, tip2;

  Iterable<Offset> get all => [
    hip, mid, shoulder, head, elbow, hand, elbow2, hand2, //
    knee, ankle, tip, knee2, ankle2, tip2,
  ];
}

/// Cinematica inversa: dove va l'articolazione di mezzo e dove arriva la
/// punta. [bend] sceglie da che parte si piega (+1 o -1).
(Offset, Offset) _reach(
  Offset root,
  Limb limb,
  double a,
  double b,
  double bend,
) {
  switch (limb) {
    case Ang(:final first, :final second):
      final joint = root + dir(first) * a;
      return (joint, joint + dir(second) * b);
    case To(:final point):
      final v = point - root;
      final d = v.distance.clamp((a - b).abs() + 1e-4, a + b - 1e-4);
      final base = angleOf(v);
      final cos = ((a * a + d * d - b * b) / (2 * a * d)).clamp(-1.0, 1.0);
      final offset = math.acos(cos) * 180 / math.pi;
      final joint = root + dir(base + bend * offset) * a;
      return (joint, root + dir(base) * d);
  }
}

Joints solve(Pose p, {double armBend = 1, double legBend = -1}) {
  final mid = p.hip + dir(p.low) * Bones.spineLow;
  final shoulder = mid + dir(p.highAngle) * Bones.spineHigh;
  final head = shoulder + dir(p.neckAngle) * Bones.neck;
  final (elbow, hand) = _reach(
    shoulder,
    p.arm,
    Bones.upperArm,
    Bones.forearm,
    armBend,
  );
  final (elbow2, hand2) = _reach(
    shoulder,
    p.arm2 ?? p.arm,
    Bones.upperArm,
    Bones.forearm,
    armBend,
  );
  final (knee, ankle) = _reach(p.hip, p.leg, Bones.thigh, Bones.shin, legBend);
  final (knee2, ankle2) = _reach(
    p.hip,
    p.leg2 ?? p.leg,
    Bones.thigh,
    Bones.shin,
    legBend,
  );
  Offset tipOf(Offset knee, Offset ankle, double? toe) =>
      ankle + dir(toe ?? angleOf(ankle - knee) - 80) * Bones.foot;
  return Joints(
    hip: p.hip,
    mid: mid,
    shoulder: shoulder,
    head: head,
    elbow: elbow,
    hand: hand,
    elbow2: elbow2,
    hand2: hand2,
    knee: knee,
    ankle: ankle,
    tip: tipOf(knee, ankle, p.toe),
    knee2: knee2,
    ankle2: ankle2,
    tip2: tipOf(knee2, ankle2, p.toe2 ?? p.toe),
  );
}

/// Attrezzi disegnati intorno alla figurina.
@immutable
sealed class Prop {
  const Prop();
}

/// Sbarra, parallele, muro: un segmento.
final class Bar extends Prop {
  const Bar(this.ax, this.ay, this.bx, this.by, {this.thick = false});

  final double ax, ay, bx, by;
  final bool thick;
}

/// Panca, gradino, rialzo: un rettangolo.
final class Block extends Prop {
  const Block(this.left, this.top, this.right, this.bottom);

  final double left, top, right, bottom;

  Rect get rect => Rect.fromLTRB(left, top, right, bottom);
}

/// Un movimento: pose chiave in ciclo. Il peso di ogni posa è quanto dura
/// il passaggio alla successiva (una posa ripetuta è una pausa).
@immutable
class Motion {
  const Motion(
    this.name,
    this.keys, {
    this.ms = 1800,
    this.props = const [],
    this.floor = true,
    this.front = false,
    this.armBend = 1,
    this.legBend = -1,
    this.still = 1,
  });

  final String name;
  final List<(Pose, double)> keys;
  final int ms;
  final List<Prop> props;
  final bool floor;

  /// Vista di fronte: braccia e gambe dei due lati ugualmente visibili.
  final bool front;
  final double armBend;
  final double legBend;

  /// Posa mostrata ferma quando le animazioni sono spente.
  final int still;

  /// Posa al punto [t] del ciclo (0–1), con accelerazione morbida tra le
  /// pose chiave.
  Pose at(double t) {
    if (keys.length == 1) return keys.first.$1;
    final total = keys.fold<double>(0, (s, k) => s + k.$2);
    var x = (t % 1) * total;
    for (var i = 0; i < keys.length; i++) {
      final w = keys[i].$2;
      if (x <= w || i == keys.length - 1) {
        final u = w == 0 ? 1.0 : (x / w).clamp(0.0, 1.0);
        final eased = u * u * (3 - 2 * u);
        return lerpPose(keys[i].$1, keys[(i + 1) % keys.length].$1, eased);
      }
      x -= w;
    }
    return keys.first.$1;
  }

  Joints jointsAt(double t) => solve(at(t), armBend: armBend, legBend: legBend);

  /// Riquadro che contiene tutto il ciclo e gli attrezzi.
  Rect get bounds => _bounds[name] ??= _computeBounds();

  Rect _computeBounds() {
    var r = Rect.zero;
    var first = true;
    void add(Offset o) {
      r = first
          ? Rect.fromCircle(center: o, radius: 0)
          : r.expandToInclude(Rect.fromCircle(center: o, radius: 0));
      first = false;
    }

    for (var i = 0; i < 48; i++) {
      final j = jointsAt(i / 48);
      j.all.forEach(add);
      add(j.head + const Offset(-Bones.head, -Bones.head));
      add(j.head + const Offset(Bones.head, Bones.head));
    }
    for (final p in props) {
      switch (p) {
        case Bar(:final ax, :final ay, :final bx, :final by):
          add(Offset(ax, ay));
          add(Offset(bx, by));
        case Block(:final rect):
          add(rect.topLeft);
          add(rect.bottomRight);
      }
    }
    if (floor) add(Offset(r.left, 0));
    return r.inflate(0.04);
  }

  static final _bounds = <String, Rect>{};
}

/// Disegna la figurina nel riquadro [size].
void paintFigure(
  Canvas canvas,
  Size size,
  Motion motion,
  double t, {
  required Color color,
  required Color ground,
}) {
  // Riquadro minimo: le pose raccolte (crow, L-sit) non diventano giganti
  // rispetto alle altre. Si allarga verso l'alto per non staccare il
  // pavimento dal fondo.
  final raw = motion.bounds;
  final w = math.max(raw.width, 0.95);
  final h = math.max(raw.height, 0.62);
  final b = Rect.fromLTRB(
    raw.center.dx - w / 2,
    raw.bottom - h,
    raw.center.dx + w / 2,
    raw.bottom,
  );
  final scale = math.min(size.width / b.width, size.height / b.height);
  final dx = (size.width - b.width * scale) / 2 - b.left * scale;
  final dy = (size.height - b.height * scale) / 2 - b.top * scale;
  Offset px(Offset o) => Offset(o.dx * scale + dx, o.dy * scale + dy);

  final stroke = math.max(2.5, scale * 0.032);
  final j = motion.jointsAt(t);

  final propPaint = Paint()
    ..color = ground
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke * 0.7;
  if (motion.floor) {
    final y = dy;
    canvas.drawLine(
      Offset(size.width * 0.04, y),
      Offset(size.width * 0.96, y),
      propPaint,
    );
  }
  for (final p in motion.props) {
    switch (p) {
      case Bar(:final ax, :final ay, :final bx, :final by, :final thick):
        canvas.drawLine(
          px(Offset(ax, ay)),
          px(Offset(bx, by)),
          Paint()
            ..color = ground
            ..strokeCap = StrokeCap.round
            ..strokeWidth = stroke * (thick ? 1.1 : 0.7),
        );
      case Block(:final rect):
        final r = Rect.fromPoints(px(rect.topLeft), px(rect.bottomRight));
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, Radius.circular(stroke * 0.6)),
          Paint()..color = ground.withValues(alpha: 0.55),
        );
    }
  }

  Paint line(double alpha, [double width = 1]) => Paint()
    ..color = color.withValues(alpha: color.a * alpha)
    ..strokeWidth = stroke * width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  void chain(List<Offset> points, Paint paint) {
    final path = Path()..moveTo(px(points.first).dx, px(points.first).dy);
    for (final p in points.skip(1)) {
      path.lineTo(px(p).dx, px(p).dy);
    }
    canvas.drawPath(path, paint);
  }

  // Lato lontano più chiaro (di lato), uguale (di fronte).
  final far = line(motion.front ? 1 : 0.42);
  final near = line(1);
  chain([j.hip, j.knee2, j.ankle2, j.tip2], far);
  chain([j.shoulder, j.elbow2, j.hand2], far);

  // Schiena morbida: curva che passa vicino a metà schiena.
  final spine = Path()
    ..moveTo(px(j.hip).dx, px(j.hip).dy)
    ..quadraticBezierTo(
      px(j.mid).dx,
      px(j.mid).dy,
      px(j.shoulder).dx,
      px(j.shoulder).dy,
    );
  canvas
    ..drawPath(spine, line(1, 1.25))
    ..drawLine(px(j.shoulder), px(j.head), near);
  chain([j.hip, j.knee, j.ankle, j.tip], near);
  chain([j.shoulder, j.elbow, j.hand], near);
  canvas.drawCircle(px(j.head), Bones.head * scale, Paint()..color = color);
}
