// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/features/exercises/domain/catalog.dart';
import 'package:discipline/features/exercises/presentation/figure/motions.dart';
import 'package:discipline/features/exercises/presentation/figure/skeleton.dart';

void main() {
  test('ogni esercizio del catalogo ha un movimento dedicato', () {
    final ids = motionIds.toSet();
    final missing = [
      for (final e in Catalog.all)
        if (!ids.contains(e.id) && motionNamed(e.figure) == null) e.id,
    ];
    expect(missing, isEmpty);
    // E nessun movimento si riferisce a un esercizio che non esiste.
    expect(ids.where((id) => Catalog.byId(id) == null), isEmpty);
  });

  test('le ossa non si allungano mai durante il movimento', () {
    for (final m in allMotions) {
      for (var i = 0; i <= 40; i++) {
        final j = m.jointsAt(i / 40);
        void bone(Offset a, Offset b, double length, String what) => expect(
          (a - b).distance,
          closeTo(length, 1e-6),
          reason: '${m.name} $what a ${i / 40}',
        );
        bone(j.shoulder, j.elbow, Bones.upperArm, 'braccio');
        bone(j.elbow, j.hand, Bones.forearm, 'avambraccio');
        bone(j.shoulder, j.elbow2, Bones.upperArm, 'braccio lontano');
        bone(j.hip, j.knee, Bones.thigh, 'coscia');
        bone(j.knee, j.ankle, Bones.shin, 'tibia');
        bone(j.hip, j.knee2, Bones.thigh, 'coscia lontana');
        bone(j.knee2, j.ankle2, Bones.shin, 'tibia lontana');
      }
    }
  });

  test('mani e piedi arrivano dove devono (sbarra, pavimento)', () {
    // Trazioni: le mani restano sulla sbarra per tutto il ciclo.
    for (var i = 0; i <= 20; i++) {
      final j = pullUp.jointsAt(i / 20);
      expect(j.hand.dy, closeTo(-1.0, 0.02));
    }
    // Push-up: mani e piedi restano a terra.
    for (var i = 0; i <= 20; i++) {
      final j = pushUp.jointsAt(i / 20);
      expect(j.hand.dy, closeTo(-0.01, 0.02));
      expect(j.ankle.dy, closeTo(-0.03, 0.03));
    }
  });

  test('le pose chiave si alternano in ordine', () {
    // A metà del ciclo dei push-up il petto è giù, all'inizio è su.
    expect(
      pushUp.jointsAt(0.5).shoulder.dy,
      greaterThan(pushUp.jointsAt(0).shoulder.dy),
    );
    // Nelle trazioni negative la discesa dura più della salita.
    final total = negativePullUp.keys.fold<double>(0, (s, k) => s + k.$2);
    expect(negativePullUp.keys[1].$2 / total, greaterThan(0.5));
  });
}
