// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/features/camera/domain/rep_counter.dart';

/// Corpo di profilo con gomito a [elbowDeg] e linea spalla–anca–caviglia a
/// [hipDeg] (180 = schiena dritta).
PoseFrame frame({
  required double elbowDeg,
  double hipDeg = 178,
  double likelihood = 1,
}) {
  final e = elbowDeg * math.pi / 180;
  final h = hipDeg * math.pi / 180;
  Landmark p(double x, double y) => Landmark(x, y, likelihood: likelihood);
  return PoseFrame(
    right: BodySide(
      shoulder: p(0, 0),
      elbow: p(0, 1),
      wrist: p(math.sin(e), 1 - math.cos(e)),
      hip: p(2, 0),
      ankle: p(2 - 2 * math.cos(h), 2 * math.sin(h)),
    ),
  );
}

/// Un push-up: su → giù (n fotogrammi) → su, con gomito che scende e sale.
List<PoseFrame> pushUp({double hipDeg = 178, int downFrames = 4}) => [
  for (final a in <double>[175, 150, 120, 95])
    frame(elbowDeg: a, hipDeg: hipDeg),
  for (var i = 0; i < downFrames; i++) frame(elbowDeg: 70, hipDeg: hipDeg),
  for (final a in <double>[100, 130, 155, 172, 175, 175])
    frame(elbowDeg: a, hipDeg: hipDeg),
];

List<RepEvent> feed(PushUpCounter c, Iterable<PoseFrame?> frames) => [
  for (final f in frames) c.update(f),
];

void main() {
  test('gli angoli sono misurati bene', () {
    final side = frame(elbowDeg: 90, hipDeg: 170).right!;
    expect(elbowAngle(side), closeTo(90, 0.5));
    expect(bodyLineAngle(side), closeTo(170, 0.5));
    expect(elbowAngle(frame(elbowDeg: 180).right!), closeTo(180, 0.5));
    expect(elbowAngle(frame(elbowDeg: 45).right!), closeTo(45, 0.5));
  });

  test('conta cinque push-up completi', () {
    final c = PushUpCounter();
    final events = feed(c, [
      frame(elbowDeg: 175),
      for (var i = 0; i < 5; i++) ...pushUp(),
    ]);
    expect(c.count, 5);
    expect(events.where((e) => e == RepEvent.rep), hasLength(5));
    expect(c.phase, RepPhase.up);
  });

  test('mezza ripetizione (gomito che non scende) non conta', () {
    final c = PushUpCounter();
    feed(c, [
      frame(elbowDeg: 175),
      for (var i = 0; i < 3; i++) ...[
        for (final a in <double>[170, 140, 115, 110, 130, 165])
          frame(elbowDeg: a),
      ],
    ]);
    expect(c.count, 0);
  });

  test('isteresi: oscillare tra 90° e 160° non conta due volte', () {
    final c = PushUpCounter();
    feed(c, [
      frame(elbowDeg: 175),
      for (final a in <double>[
        80,
        80,
        85,
        100,
        92,
        120,
        88,
        88,
        140,
        170,
        175,
        175,
        175,
      ])
        frame(elbowDeg: a),
    ]);
    expect(c.count, 1);
  });

  test('picco di un solo fotogramma è rumore', () {
    final c = PushUpCounter(smoothing: 1);
    feed(c, [
      frame(elbowDeg: 175),
      frame(elbowDeg: 60),
      frame(elbowDeg: 175),
      frame(elbowDeg: 175),
    ]);
    expect(c.count, 0);
  });

  test('schiena non dritta: ripetizione scartata', () {
    final c = PushUpCounter();
    final events = feed(c, [
      frame(elbowDeg: 175),
      ...pushUp(hipDeg: 135),
      ...pushUp(),
    ]);
    expect(c.count, 1);
    expect(events, contains(RepEvent.badForm));
  });

  test('punti poco sicuri e persona assente vengono ignorati', () {
    final c = PushUpCounter();
    feed(c, [
      frame(elbowDeg: 175),
      null,
      for (var i = 0; i < 12; i++) frame(elbowDeg: 20, likelihood: 0.1),
      ...pushUp(),
      null,
    ]);
    expect(c.count, 1);
  });

  test('sceglie il lato più affidabile', () {
    final good = frame(elbowDeg: 170).right!;
    final bad = frame(elbowDeg: 20, likelihood: 0.6).right!;
    final f = PoseFrame(left: bad, right: good);
    expect(f.best(0.5), same(good));
    expect(PoseFrame(left: bad).best(0.8), isNull);
  });

  test('il rumore del rilevatore viene attenuato', () {
    final c = PushUpCounter();
    final noisy = [for (final f in pushUp(downFrames: 6)) f];
    // Un singolo fotogramma sbagliato (gomito a 170°) nella fase bassa.
    noisy[6] = frame(elbowDeg: 170);
    feed(c, [frame(elbowDeg: 175), ...noisy]);
    expect(c.count, 1);
  });

  test('reset azzera tutto', () {
    final c = PushUpCounter();
    feed(c, [frame(elbowDeg: 175), ...pushUp()]);
    expect(c.count, 1);
    c.reset();
    expect(c.count, 0);
    expect(c.phase, RepPhase.searching);
  });
}
