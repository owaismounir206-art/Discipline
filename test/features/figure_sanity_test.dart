// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/features/exercises/presentation/figure/motions.dart';
import 'package:discipline/features/exercises/presentation/figure/skeleton.dart';

// Controlli di buon senso su ogni movimento (anche quelli aggiunti in
// futuro): campiona il ciclo e cerca figurine impossibili.

const _samples = 60;

/// Quanto può "affondare" nel pavimento un'articolazione (in altezze).
const _floorTolerance = 0.012;

/// Quanto può mancare il bersaglio una mano o un piede.
const _reachTolerance = 0.012;

/// Angolo (−180, 180] da [a] a [b], positivo in senso orario sullo schermo.
double _turn(double a, double b) {
  var d = (b - a) % 360;
  if (d > 180) d -= 360;
  return d;
}

void main() {
  final problems = <String>[];

  setUpAll(() {
    for (final m in allMotions) {
      for (var i = 0; i < _samples; i++) {
        final t = i / _samples;
        final at = '${m.name} a ${t.toStringAsFixed(2)}';
        final pose = m.at(t);
        final j = m.jointsAt(t);

        if (j.all.any((o) => o.dx.isNaN || o.dy.isNaN)) {
          problems.add('$at: NaN');
          continue;
        }

        if (m.floor) {
          const names = [
            'bacino', 'metà schiena', 'spalle', 'testa', 'gomito', 'mano', //
            'gomito lontano', 'mano lontana', 'ginocchio', 'caviglia',
            'punta del piede', 'ginocchio lontano', 'caviglia lontana',
            'punta del piede lontano',
          ];
          final all = j.all.toList();
          for (var k = 0; k < all.length; k++) {
            if (all[k].dy > _floorTolerance) {
              problems.add('$at: ${names[k]} sotto il pavimento');
            }
          }
          if (j.head.dy + Bones.head > _floorTolerance) {
            problems.add('$at: la testa attraversa il pavimento');
          }
        }

        void reach(Limb limb, Offset end, String what) {
          final miss = limb is To ? (limb.point - end).distance : 0.0;
          if (miss > _reachTolerance) {
            problems.add(
              '$at: $what non arriva al bersaglio '
              '(manca ${miss.toStringAsFixed(3)})',
            );
          }
        }

        reach(pose.arm, j.hand, 'mano');
        reach(pose.arm2 ?? pose.arm, j.hand2, 'mano lontana');
        reach(pose.leg, j.ankle, 'piede');
        reach(pose.leg2 ?? pose.leg, j.ankle2, 'piede lontano');

        // Di lato la figurina guarda a destra: il ginocchio si piega solo
        // in avanti (la tibia ruota in senso orario rispetto alla coscia),
        // il gomito solo all'indietro (l'avambraccio in senso antiorario).
        if (!m.front) {
          void bend(Offset a, Offset b, Offset c, double sign, String what) {
            final flex = sign * _turn(angleOf(b - a), angleOf(c - b));
            if (flex < -12 || flex > 170) {
              problems.add(
                '$at: $what piegato al contrario '
                '(${flex.toStringAsFixed(0)}°)',
              );
            }
          }

          bend(j.hip, j.knee, j.ankle, 1, 'ginocchio');
          bend(j.hip, j.knee2, j.ankle2, 1, 'ginocchio lontano');
          bend(j.shoulder, j.elbow, j.hand, -1, 'gomito');
          bend(j.shoulder, j.elbow2, j.hand2, -1, 'gomito lontano');
        }
      }
    }
  });

  test('nessuna figurina impossibile', () {
    // Un solo messaggio per movimento e problema, per leggibilità.
    final unique = <String>{
      for (final p in problems)
        p
            .replaceFirst(RegExp(r' a \d\.\d\d'), '')
            .replaceFirst(RegExp(r' \([^)]*\)$'), ''),
    };
    expect(unique, isEmpty, reason: unique.join('\n'));
  });

  test('nomi dei movimenti unici', () {
    final names = allMotions.map((m) => m.name).toList();
    expect(names.toSet().length, names.length);
  });
}
