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

  /// Dalle spalle al centro della testa.
  static const neck = 0.105;

  /// Raggio della testa.
  static const head = 0.064;
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

Ang _angles(Offset root, Offset joint, Offset end) =>
    Ang(angleOf(joint - root), angleOf(end - joint));

/// Posa a metà strada tra [a] e [b]. Se un arto passa da bersaglio ([To])
/// ad angoli ([Ang]) o viceversa, il bersaglio diventa angoli (con le
/// stesse pieghe di [solve]), così l'arto non salta a metà strada.
Pose lerpPose(
  Pose a,
  Pose b,
  double t, {
  double armBend = 1,
  double legBend = -1,
  bool mirror = false,
}) {
  late final ja = solve(a, armBend: armBend, legBend: legBend, mirror: mirror);
  late final jb = solve(b, armBend: armBend, legBend: legBend, mirror: mirror);
  Limb limb(Limb p, Limb q, Ang Function(Joints) angles) => switch ((p, q)) {
    (To(), Ang()) => _lerpLimb(angles(ja), q, t),
    (Ang(), To()) => _lerpLimb(p, angles(jb), t),
    _ => _lerpLimb(p, q, t),
  };
  return Pose(
    hip: Offset.lerp(a.hip, b.hip, t)!,
    low: _lerpAngle(a.low, b.low, t),
    high: _lerpAngle(a.highAngle, b.highAngle, t),
    neck: _lerpAngle(a.neckAngle, b.neckAngle, t),
    arm: limb(a.arm, b.arm, (j) => _angles(j.shoulder, j.elbow, j.hand)),
    arm2: limb(
      a.arm2 ?? a.arm,
      b.arm2 ?? b.arm,
      (j) => _angles(j.shoulder, j.elbow2, j.hand2),
    ),
    leg: limb(a.leg, b.leg, (j) => _angles(j.hip, j.knee, j.ankle)),
    leg2: limb(
      a.leg2 ?? a.leg,
      b.leg2 ?? b.leg,
      (j) => _angles(j.hip, j.knee2, j.ankle2),
    ),
    toe: _lerpOptional(a.toe, b.toe, t),
    toe2: _lerpOptional(a.toe2 ?? a.toe, b.toe2 ?? b.toe, t),
  );
}

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

/// [mirror]: vista di fronte, il braccio e la gamba lontani (a sinistra)
/// si piegano a specchio rispetto a quelli vicini.
Joints solve(
  Pose p, {
  double armBend = 1,
  double legBend = -1,
  bool mirror = false,
}) {
  final side = mirror ? -1.0 : 1.0;
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
    armBend * side,
  );
  final (knee, ankle) = _reach(p.hip, p.leg, Bones.thigh, Bones.shin, legBend);
  final (knee2, ankle2) = _reach(
    p.hip,
    p.leg2 ?? p.leg,
    Bones.thigh,
    Bones.shin,
    legBend * side,
  );
  Offset tipOf(Offset knee, Offset ankle, double? toe, [double turn = -80]) =>
      ankle + dir(toe ?? angleOf(ankle - knee) + turn) * Bones.foot;
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
    tip2: mirror && p.toe2 == null && p.toe == null
        ? tipOf(knee2, ankle2, null, 80)
        : tipOf(knee2, ankle2, p.toe2 ?? p.toe),
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
        return lerpPose(
          keys[i].$1,
          keys[(i + 1) % keys.length].$1,
          eased,
          armBend: armBend,
          legBend: legBend,
          mirror: front,
        );
      }
      x -= w;
    }
    return keys.first.$1;
  }

  Joints jointsAt(double t) {
    final j = solve(at(t), armBend: armBend, legBend: legBend, mirror: front);
    return floor ? _feetAbove(j) : j;
  }

  /// Con il pavimento, la punta del piede non lo attraversa: il piede
  /// ruota intorno alla caviglia finché la punta lo sfiora.
  static Joints _feetAbove(Joints j) {
    Offset lift(Offset ankle, Offset tip) {
      const lowest = -0.004;
      if (tip.dy <= lowest) return tip;
      final s = (lowest - ankle.dy) / Bones.foot;
      if (s.abs() > 1) return tip;
      final a = math.asin(s) * 180 / math.pi;
      final now = angleOf(tip - ankle);
      final best =
          (_lerpAngle(now, a, 1) - now).abs() <=
              (_lerpAngle(now, 180 - a, 1) - now).abs()
          ? a
          : 180 - a;
      return ankle + dir(best) * Bones.foot;
    }

    return Joints(
      hip: j.hip,
      mid: j.mid,
      shoulder: j.shoulder,
      head: j.head,
      elbow: j.elbow,
      hand: j.hand,
      elbow2: j.elbow2,
      hand2: j.hand2,
      knee: j.knee,
      ankle: j.ankle,
      tip: lift(j.ankle, j.tip),
      knee2: j.knee2,
      ankle2: j.ankle2,
      tip2: lift(j.ankle2, j.tip2),
    );
  }

  /// Riquadro della figurina in tutto il ciclo, con gli attrezzi vicini. Un
  /// muro o un palo molto alti vengono tagliati: conta la figurina.
  Rect get bounds => _bounds[name] ??= _computeBounds();

  Rect _computeBounds() {
    var r = Rect.zero;
    var first = true;
    void add(Rect o) {
      r = first ? o : r.expandToInclude(o);
      first = false;
    }

    for (var i = 0; i < 48; i++) {
      final j = jointsAt(i / 48);
      for (final o in j.all) {
        add(Rect.fromCircle(center: o, radius: 0));
      }
      add(Rect.fromCircle(center: j.head, radius: Bones.head));
    }
    final reach = r.inflate(0.14);
    Offset near(double x, double y) => Offset(
      x.clamp(reach.left, reach.right),
      y.clamp(reach.top, reach.bottom),
    );
    for (final p in props) {
      switch (p) {
        case Bar(:final ax, :final ay, :final bx, :final by):
          add(Rect.fromPoints(near(ax, ay), near(bx, by)));
        case Block(:final left, :final top, :final right, :final bottom):
          add(Rect.fromPoints(near(left, top), near(right, bottom)));
      }
    }
    if (floor) add(Rect.fromLTRB(r.left, 0, r.right, 0));
    return r.inflate(0.05);
  }

  static final _bounds = <String, Rect>{};
}

/// Riquadro minimo (in altezze): le pose raccolte (crow, L-sit) non
/// diventano giganti rispetto a quelle in piedi o in verticale.
const _minWidth = 1.2;
const _minHeight = 0.8;

/// Spessore degli arti rispetto all'altezza della figurina.
const _limb = 0.045;

/// Disegna la figurina nel riquadro [size]: arti a tratto pieno con le
/// estremità arrotondate, busto più spesso, testa piena staccata dal busto,
/// lato lontano più chiaro. Gli spessori seguono la figurina, non il
/// riquadro, così ogni movimento ha lo stesso tratto.
void paintFigure(
  Canvas canvas,
  Size size,
  Motion motion,
  double t, {
  required Color color,
  required Color ground,
}) {
  final raw = motion.bounds;
  final b = Rect.fromCenter(
    center: raw.center,
    width: math.max(raw.width, _minWidth),
    height: math.max(raw.height, _minHeight),
  );
  // Il pavimento resta in fondo: il riquadro cresce verso l'alto.
  final box = motion.floor ? b.translate(0, raw.bottom - b.bottom) : b;
  final scale = math.min(size.width / box.width, size.height / box.height);
  if (scale <= 0 || !scale.isFinite) return;
  final dx = (size.width - box.width * scale) / 2 - box.left * scale;
  final dy = (size.height - box.height * scale) / 2 - box.top * scale;
  Offset px(Offset o) => Offset(o.dx * scale + dx, o.dy * scale + dy);

  final limb = math.max(1.4, scale * _limb);
  final j = motion.jointsAt(t);

  canvas
    ..save()
    ..clipRect(Offset.zero & size);

  Paint stroke(Color c, double width) => Paint()
    ..color = c
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  if (motion.floor) {
    final width = limb * 0.6;
    final y = dy + width / 2;
    canvas.drawLine(
      Offset(size.width * 0.03, y),
      Offset(size.width * 0.97, y),
      stroke(ground, width),
    );
  }
  for (final p in motion.props) {
    switch (p) {
      case Bar(:final ax, :final ay, :final bx, :final by, :final thick):
        canvas.drawLine(
          px(Offset(ax, ay)),
          px(Offset(bx, by)),
          stroke(ground, limb * (thick ? 0.85 : 0.5)),
        );
      case Block(:final rect):
        final r = Rect.fromPoints(px(rect.topLeft), px(rect.bottomRight));
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, Radius.circular(limb * 0.5)),
          Paint()..color = ground.withValues(alpha: ground.a * 0.6),
        );
    }
  }

  Path chain(List<Offset> points) {
    final path = Path()..moveTo(px(points.first).dx, px(points.first).dy);
    for (final p in points.skip(1)) {
      path.lineTo(px(p).dx, px(p).dy);
    }
    return path;
  }

  void limbPath(List<Offset> points, Color c) {
    canvas.drawPath(chain(points), stroke(c, limb));
  }

  void hand(Offset o, Color c) =>
      canvas.drawCircle(px(o), limb * 0.62, Paint()..color = c);

  // Lato lontano più chiaro (di lato), uguale (di fronte).
  final far = motion.front ? color : color.withValues(alpha: color.a * 0.45);
  limbPath([j.hip, j.knee2, j.ankle2, j.tip2], far);
  limbPath([j.shoulder, j.elbow2, j.hand2], far);
  hand(j.hand2, far);

  // Schiena morbida: curva che passa per metà schiena.
  final control = j.mid * 2 - (j.hip + j.shoulder) / 2;
  final spine = Path()
    ..moveTo(px(j.hip).dx, px(j.hip).dy)
    ..quadraticBezierTo(
      px(control).dx,
      px(control).dy,
      px(j.shoulder).dx,
      px(j.shoulder).dy,
    );
  canvas.drawPath(spine, stroke(color, limb * 1.45));

  limbPath([j.hip, j.knee, j.ankle, j.tip], color);
  limbPath([j.shoulder, j.elbow, j.hand], color);
  hand(j.hand, color);
  canvas
    ..drawCircle(
      px(j.head),
      math.max(Bones.head * scale, limb * 1.4),
      Paint()..color = color,
    )
    ..restore();
}
