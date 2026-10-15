// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/features/timer/domain/interval.dart';

void main() {
  group('Passi del timer', () {
    test('Tabata: preparazione, 8 lavori, 7 recuperi, 4 minuti', () {
      final steps = buildSteps(const IntervalConfig.of(IntervalKind.tabata));
      expect(steps.first.phase, Phase.prepare);
      expect(steps.where((s) => s.phase == Phase.work), hasLength(8));
      expect(steps.where((s) => s.phase == Phase.rest), hasLength(7));
      expect(totalSeconds(steps) - prepareSeconds, 8 * 20 + 7 * 10);
    });

    test('EMOM e AMRAP usano i minuti', () {
      final emom = buildSteps(
        const IntervalConfig.of(IntervalKind.emom).copyWith(minutes: 5),
      );
      expect(emom.where((s) => s.phase == Phase.work), hasLength(5));
      expect(emom.last.label, 'Minuto 5');
      final amrap = buildSteps(
        const IntervalConfig.of(IntervalKind.amrap).copyWith(minutes: 7),
      );
      expect(amrap.last.seconds, 420);
    });

    test('le routine hanno tutti gli esercizi del catalogo', () {
      for (final kind in [
        IntervalKind.warmUp,
        IntervalKind.coolDown,
        IntervalKind.quick,
      ]) {
        final steps = buildSteps(IntervalConfig.of(kind));
        final works = steps.where((s) => s.phase == Phase.work).toList();
        expect(works, isNotEmpty);
        expect(works.every((s) => s.exercise != null), isTrue, reason: '$kind');
      }
      final quick = buildSteps(const IntervalConfig.of(IntervalKind.quick));
      expect(totalSeconds(quick) - prepareSeconds, 10 * 40 + 9 * 20);
    });

    test('l\'allenamento rapido cambia con il seme', () {
      String first(int seed) => buildSteps(
        IntervalConfig.of(IntervalKind.quick, seed: seed),
      )[1].label;
      expect(first(0), isNot(first(1)));
    });

    test('le impostazioni passano dall\'indirizzo', () {
      final c = const IntervalConfig.of(IntervalKind.custom)
          .copyWith(work: 45, rest: 15, rounds: 6);
      final back = IntervalConfig.fromQuery(c.toQuery());
      expect(
        (back.kind, back.work, back.rest, back.rounds),
        (IntervalKind.custom, 45, 15, 6),
      );
      // Valori assurdi vengono riportati nei limiti.
      expect(
        IntervalConfig.fromQuery({'tipo': 'custom', 'lavoro': '0'}).work,
        5,
      );
    });
  });

  group('Posizione nel tempo', () {
    final steps = buildSteps(const IntervalConfig.of(IntervalKind.tabata));

    test('conta i secondi per eccesso e passa al passo dopo', () {
      var p = positionAt(steps, Duration.zero);
      expect((p.index, p.remaining), (0, 10));
      p = positionAt(steps, const Duration(milliseconds: 9500));
      expect((p.index, p.remaining), (0, 1));
      p = positionAt(steps, const Duration(seconds: 10));
      expect((p.index, p.remaining, steps[p.index].phase), (1, 20, Phase.work));
      p = positionAt(steps, const Duration(seconds: 30));
      expect(steps[p.index].phase, Phase.rest);
    });

    test('finisce dopo l\'ultimo passo', () {
      final p = positionAt(steps, Duration(seconds: totalSeconds(steps)));
      expect(p.done, isTrue);
    });

    test('giri e orologio', () {
      expect(roundOf(steps, 0), (1, 8));
      expect(roundOf(steps, 3), (2, 8));
      expect(roundOf(steps, steps.length - 1), (8, 8));
      expect(clock(65), '1:05');
      expect(startOf(steps, 2), 30);
    });
  });
}
