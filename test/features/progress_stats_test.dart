// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/utils/local_date.dart';
import 'package:ritmo/features/exercises/domain/exercise.dart';
import 'package:ritmo/features/exercises/domain/progression.dart';
import 'package:ritmo/features/progress/domain/progress_stats.dart';

const today = LocalDate(2026, 10, 13);

SetRecord push(LocalDate d, int v, [String id = 'push_classic']) =>
    (date: d, exerciseId: id, chain: ChainId.push, value: v);

SetRecord pull(LocalDate d, int v, String id) =>
    (date: d, exerciseId: id, chain: ChainId.pull, value: v);

SetRecord plank(LocalDate d, int v) =>
    (date: d, exerciseId: 'core_plank', chain: ChainId.core, value: v);

void main() {
  group('Grafico ripetizioni', () {
    test('settimana: un bar per sessione e oggi a parte', () {
      final sets = [
        push(today.addDays(-14), 99), // fuori finestra
        push(today.addDays(-6), 10),
        push(today.addDays(-6), 12),
        push(today.addDays(-1), 30),
        push(today, 8),
        plank(today.addDays(-1), 60), // a tempo: non conta
      ];
      final bars = repsChart(sets, ProgressPeriod.week, today);
      expect(bars.map((b) => b.label), ['7/10', '12/10', 'oggi']);
      expect(bars.map((b) => b.value), [22, 30, 8]);
      expect(bars.last.current, isTrue);
      expect(lastCompleteValue(bars), 30);
    });

    test('settimana: al massimo 7 sessioni più oggi', () {
      final sets = [for (var i = 1; i <= 12; i++) push(today.addDays(-i), i)];
      final bars = repsChart(sets, ProgressPeriod.week, today);
      expect(bars, hasLength(7));
      expect(bars.last.label, '12/10');
    });

    test('mese: 8 settimane da lunedì, l\'ultima in corso', () {
      final sets = [push(today, 5), push(today.addDays(-7), 9)];
      final bars = repsChart(sets, ProgressPeriod.month, today);
      expect(bars, hasLength(8));
      expect(bars.last.label, 'ora');
      expect(bars.last.value, 5);
      expect(bars[6].label, '5/10');
      expect(bars[6].value, 9);
    });

    test('anno: 12 mesi anche a cavallo dell\'anno', () {
      const jan = LocalDate(2027, 1, 20);
      final sets = [push(jan, 3), push(const LocalDate(2026, 12, 5), 4)];
      final bars = repsChart(sets, ProgressPeriod.year, jan);
      expect(bars, hasLength(12));
      expect(bars.first.label, 'feb');
      expect(bars[10].label, 'dic');
      expect(bars[10].value, 4);
      expect(bars.last.label, 'gen');
      expect(bars.last.current, isTrue);
    });

    test('variazione tra la prima e l\'ultima barra completa', () {
      final bars = [
        const ChartBar(label: '29/9', value: 150, start: today),
        const ChartBar(label: '12/10', value: 196, start: today),
        const ChartBar(label: 'oggi', value: 95, start: today, current: true),
      ];
      expect(repsTrend(bars), (percent: 31, since: '29/9'));
      expect(repsTrend(bars.sublist(1)), isNull);
    });
  });

  group('Record', () {
    test('push-up del mese contano tutte le varianti del mese', () {
      final sets = [
        push(today, 10),
        push(const LocalDate(2026, 10, 1), 5, 'push_knee'),
        push(const LocalDate(2026, 9, 30), 99),
      ];
      expect(pushUpsInMonth(sets, today), 15);
    });

    test('trazioni di fila: solo trazioni vere, o il test', () {
      final sets = [
        pull(today, 20, 'pull_australian'),
        pull(today, 7, 'pull_up'),
        pull(today, 9, 'pull_wide'),
      ];
      expect(maxPullUps(sets), 9);
      expect(maxPullUps(sets, fromTest: 12), 12);
      expect(maxPullUps([]), 0);
    });

    test('plank massimo', () {
      expect(maxPlankSeconds([plank(today, 90), plank(today, 130)]), 130);
      expect(maxPlankSeconds([], fromTest: 45), 45);
    });
  });

  group('Abilità sbloccate', () {
    const start = LocalDate(2026, 9, 1);
    final chains = {
      ChainId.push: const ChainProgress(
        chain: ChainId.push,
        position: 4,
        since: LocalDate(2026, 10, 12),
      ),
      ChainId.pull: const ChainProgress(
        chain: ChainId.pull,
        position: 3,
        since: LocalDate(2026, 9, 20),
      ),
      ChainId.core: const ChainProgress(
        chain: ChainId.core,
        position: 0,
        since: start,
      ),
    };

    test('dalla più recente, senza le varianti di partenza', () {
      final skills = unlockedSkills(chains, [
        push(today, 15, 'push_diamond'),
        push(today, 12, 'push_diamond'),
      ], start);
      expect(skills.map((s) => s.exercise.name), [
        'Push-up diamante',
        'Trazioni',
      ]);
      expect(skills.first.best, 15);
      expect(skills.last.best, 0);
    });

    test('conta le varianti raggiunte', () {
      expect(variantsReached(chains), 5 + 4 + 1);
    });
  });
}
