// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Un punto del corpo trovato dalla fotocamera (coordinate dell'immagine).
@immutable
class Landmark {
  const Landmark(this.x, this.y, {this.likelihood = 1});

  final double x;
  final double y;

  /// Quanto il rilevatore è sicuro del punto (0–1).
  final double likelihood;
}

/// Il lato del corpo visibile (di profilo se ne vede uno solo).
@immutable
class BodySide {
  const BodySide({
    required this.shoulder,
    required this.elbow,
    required this.wrist,
    required this.hip,
    required this.ankle,
  });

  final Landmark shoulder;
  final Landmark elbow;
  final Landmark wrist;
  final Landmark hip;
  final Landmark ankle;

  Iterable<Landmark> get all => [shoulder, elbow, wrist, hip, ankle];

  double get minLikelihood => all.map((l) => l.likelihood).reduce(math.min);
}

/// Un fotogramma: i due lati (uno può mancare).
@immutable
class PoseFrame {
  const PoseFrame({this.left, this.right});

  final BodySide? left;
  final BodySide? right;

  /// Il lato più affidabile, se abbastanza sicuro.
  BodySide? best(double minLikelihood) {
    final sides = [left, right].whereType<BodySide>().toList()
      ..sort((a, b) => b.minLikelihood.compareTo(a.minLikelihood));
    final side = sides.firstOrNull;
    return side != null && side.minLikelihood >= minLikelihood ? side : null;
  }
}

/// Angolo in gradi (0–180) nel punto [b] tra i segmenti b→a e b→c.
double angleAt(Landmark a, Landmark b, Landmark c) {
  final v1x = a.x - b.x;
  final v1y = a.y - b.y;
  final v2x = c.x - b.x;
  final v2y = c.y - b.y;
  final n1 = math.sqrt(v1x * v1x + v1y * v1y);
  final n2 = math.sqrt(v2x * v2x + v2y * v2y);
  if (n1 == 0 || n2 == 0) return 180;
  final cos = ((v1x * v2x + v1y * v2y) / (n1 * n2)).clamp(-1.0, 1.0);
  return math.acos(cos) * 180 / math.pi;
}

double elbowAngle(BodySide s) => angleAt(s.shoulder, s.elbow, s.wrist);

/// Linea del corpo: spalla–anca–caviglia (180° = schiena dritta).
double bodyLineAngle(BodySide s) => angleAt(s.shoulder, s.hip, s.ankle);

/// Cosa è successo dopo un fotogramma.
enum RepEvent {
  /// Niente di nuovo.
  none,

  /// Una ripetizione valida.
  rep,

  /// Ripetizione scartata: schiena non dritta.
  badForm,
}

/// Stato visibile all'interfaccia.
enum RepPhase { searching, up, down }

/// Conta i push-up dagli angoli del corpo.
///
/// - **Giù**: gomito sotto [downAngle] (90°). **Su**: sopra [upAngle] (160°).
///   Tra i due valori non cambia nulla (isteresi): piccole oscillazioni non
///   contano due volte.
/// - Gli angoli sono mediati su [smoothing] fotogrammi per togliere il
///   rumore del rilevatore.
/// - Si conta solo se in basso la schiena era dritta (linea del corpo tra
///   [minBodyLine] e 180°): niente "push-up col sedere in aria".
/// - I fotogrammi con punti poco sicuri o senza persona sono ignorati.
class PushUpCounter {
  PushUpCounter({
    this.downAngle = 90,
    this.upAngle = 160,
    this.minBodyLine = 160,
    this.smoothing = 3,
    this.minLikelihood = 0.5,
    this.minDownFrames = 2,
  });

  final double downAngle;
  final double upAngle;
  final double minBodyLine;
  final int smoothing;
  final double minLikelihood;

  /// Fotogrammi minimi in basso: scarta i falsi picchi di un solo frame.
  final int minDownFrames;

  final List<double> _elbows = [];
  var _count = 0;
  var _phase = RepPhase.searching;
  var _downFrames = 0;
  var _formOk = true;
  double? _lastElbow;
  double? _lastBodyLine;

  int get count => _count;
  RepPhase get phase => _phase;
  double? get elbow => _lastElbow;
  double? get bodyLine => _lastBodyLine;

  /// Vero se la schiena è dritta adesso (per il suggerimento a schermo).
  bool get formOk => (_lastBodyLine ?? 180) >= minBodyLine;

  void reset() {
    _elbows.clear();
    _count = 0;
    _phase = RepPhase.searching;
    _downFrames = 0;
    _formOk = true;
    _lastElbow = null;
    _lastBodyLine = null;
  }

  /// Un fotogramma (null = nessuna persona).
  RepEvent update(PoseFrame? frame) {
    final side = frame?.best(minLikelihood);
    if (side == null) return RepEvent.none;

    _elbows.add(elbowAngle(side));
    if (_elbows.length > smoothing) _elbows.removeAt(0);
    final elbow = _elbows.reduce((a, b) => a + b) / _elbows.length;
    final line = bodyLineAngle(side);
    _lastElbow = elbow;
    _lastBodyLine = line;

    switch (_phase) {
      case RepPhase.searching:
        if (elbow >= upAngle) _phase = RepPhase.up;
        return RepEvent.none;
      case RepPhase.up:
        if (elbow <= downAngle) {
          _phase = RepPhase.down;
          _downFrames = 1;
          _formOk = line >= minBodyLine;
        }
        return RepEvent.none;
      case RepPhase.down:
        if (elbow <= downAngle) {
          _downFrames++;
          if (line < minBodyLine) _formOk = false;
        }
        if (elbow >= upAngle) {
          _phase = RepPhase.up;
          final valid = _downFrames >= minDownFrames;
          final ok = _formOk;
          _downFrames = 0;
          if (!valid) return RepEvent.none;
          if (!ok) return RepEvent.badForm;
          _count++;
          return RepEvent.rep;
        }
        return RepEvent.none;
    }
  }
}
