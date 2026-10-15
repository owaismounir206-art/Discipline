// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/core/utils/local_date.dart';
import 'package:discipline/features/exercises/domain/catalog.dart';
import 'package:discipline/features/exercises/domain/exercise.dart';
import 'package:discipline/features/exercises/domain/level.dart';
import 'package:discipline/features/exercises/domain/placement.dart';
import 'package:discipline/features/exercises/domain/progression.dart';
import 'package:discipline/features/profile/domain/athlete_profile.dart';

AthleteProfile profile({
  Difficulty difficulty = Difficulty.intermediate,
  Experience experience = Experience.threeToTwelveMonths,
  int pushUps = 20,
  int pullUps = 6,
  int plank = 60,
}) => AthleteProfile(
  difficulty: difficulty,
  experience: experience,
  trainingDays: const {1, 3, 5},
  test: InitialTest(
    maxPushUps: pushUps,
    maxPullUps: pullUps,
    plankSeconds: plank,
  ),
);

void main() {
  group('Catalogo', () {
    test('ogni esercizio ha dati completi e posizione coerente', () {
      final ids = <String>{};
      for (final MapEntry(key: chain, value: list) in Catalog.chains.entries) {
        for (var i = 0; i < list.length; i++) {
          final e = list[i];
          expect(e.chain, chain, reason: e.id);
          expect(e.position, i, reason: e.id);
          expect(e.instructions, isNotEmpty, reason: e.id);
          expect(e.mistakes, isNotEmpty, reason: e.id);
          expect(e.range.min, greaterThan(0), reason: e.id);
          expect(ids.add(e.id), isTrue, reason: 'id duplicato ${e.id}');
        }
      }
    });

    test('le catene seguono le progressioni richieste', () {
      expect(Catalog.chain(ChainId.push).map((e) => e.name), [
        'Push-up al muro',
        'Push-up inclinati',
        'Push-up sulle ginocchia',
        'Push-up classici',
        'Push-up diamante',
        'Push-up arciere',
        'Push-up a un braccio',
      ]);
      expect(Catalog.chain(ChainId.pull), hasLength(7));
      expect(Catalog.chain(ChainId.dip), hasLength(4));
      expect(Catalog.chain(ChainId.legs), hasLength(6));
      expect(Catalog.chain(ChainId.core), hasLength(5));
      expect(Catalog.chain(ChainId.skills).map((e) => e.id), [
        'skill_crow',
        'skill_wall_handstand',
        'skill_tuck_planche',
        'skill_tuck_front_lever',
        'skill_muscle_up',
        'skill_handstand_free',
        'skill_front_lever',
      ]);
      expect(Catalog.chain(ChainId.core).first.measure, Measure.seconds);
    });

    test('le nuove tappe sono in fondo: le posizioni salvate non cambiano', () {
      // Posizioni dei percorsi prima della versione 1.0.
      const before = {
        ChainId.pull: 'pull_archer',
        ChainId.dip: 'dip_parallel',
        ChainId.legs: 'legs_pistol',
        ChainId.core: 'core_lsit',
        ChainId.shoulders: 'shoulders_pike_elevated',
        ChainId.skills: 'skill_muscle_up',
      };
      for (final MapEntry(key: chain, value: id) in before.entries) {
        expect(
          Catalog.chain(chain).indexWhere((e) => e.id == id),
          Catalog.byId(id)!.position,
        );
      }
      expect(Catalog.byId('pull_archer')!.position, 5);
      expect(Catalog.byId('legs_pistol')!.position, 4);
    });

    test('famiglie per variare: cardio, mobilità, complementari', () {
      expect(Catalog.all.length, greaterThanOrEqualTo(70));
      for (final c in [ChainId.cardio, ChainId.mobility, ChainId.accessory]) {
        expect(c.isProgression, isFalse);
        expect(c.isMain, isFalse);
        expect(Catalog.chain(c), isNotEmpty);
      }
    });

    test('at() resta dentro la catena', () {
      expect(Catalog.at(ChainId.dip, 99).id, 'dip_straight_bar');
      expect(Catalog.at(ChainId.dip, -3).id, 'dip_bench');
    });
  });

  group('Punto di partenza', () {
    test('il test pesa più della difficoltà dichiarata', () {
      final p = computePlacement(
        profile(difficulty: Difficulty.advanced, pushUps: 8),
      );
      expect(
        Catalog.at(ChainId.push, p.positions[ChainId.push]!).name,
        'Push-up classici',
      );
      expect(p.notes.first, contains('Hai scelto Avanzato'));
      expect(p.notes.first, contains('8 push-up'));
    });

    test('un test migliore del previsto fa partire più avanti', () {
      final p = computePlacement(
        profile(difficulty: Difficulty.beginner, pushUps: 35),
      );
      expect(p.positions[ChainId.push], greaterThanOrEqualTo(3));
      expect(p.notes.any((n) => n.startsWith('Ottimo test')), isTrue);
    });

    test('chi ha appena iniziato parte dal basso', () {
      final p = computePlacement(
        profile(
          difficulty: Difficulty.beginner,
          experience: Experience.justStarted,
          pushUps: 0,
          pullUps: 0,
          plank: 15,
        ),
      );
      expect(p.positions[ChainId.push], 1);
      expect(p.positions[ChainId.pull], 0);
      expect(p.positions[ChainId.core], 0);
      expect(p.positions[ChainId.legs], 0);
      expect(p.positions.containsKey(ChainId.skills), isFalse);
    });

    test('le skill si sbloccano solo per Avanzato/Élite forti', () {
      final strong = computePlacement(
        profile(
          difficulty: Difficulty.elite,
          experience: Experience.overThreeYears,
          pushUps: 50,
          pullUps: 15,
          plank: 150,
        ),
      );
      expect(strong.positions[ChainId.skills], 1);

      final weak = computePlacement(
        profile(difficulty: Difficulty.advanced, pushUps: 10, pullUps: 2),
      );
      expect(weak.positions.containsKey(ChainId.skills), isFalse);
      expect(weak.notes.last, contains('skill'));
    });

    test('tutte le posizioni sono valide', () {
      for (final d in Difficulty.values) {
        for (final e in Experience.values) {
          for (final n in [0, 3, 12, 25, 60]) {
            final p = computePlacement(
              profile(difficulty: d, experience: e, pushUps: n, pullUps: n),
            );
            for (final MapEntry(key: c, value: pos) in p.positions.entries) {
              expect(pos, inInclusiveRange(0, Catalog.lastPosition(c)));
            }
          }
        }
      }
    });
  });

  group('Doppia progressione', () {
    const day = LocalDate(2026, 10, 1);
    ChainProgress start([int position = 3]) =>
        ChainProgress(chain: ChainId.push, position: position, since: day);

    test('valuta le serie rispetto all\'intervallo', () {
      const r = TargetRange(8, 12);
      expect(evaluateSets(r, [12, 12, 13]), SessionOutcome.top);
      expect(evaluateSets(r, [12, 12, 11]), SessionOutcome.inRange);
      expect(evaluateSets(r, [7, 6, 8]), SessionOutcome.belowMin);
      expect(evaluateSets(r, []), SessionOutcome.belowMin);
    });

    test('2 sessioni al massimo propongono la variante successiva', () {
      var p = start();
      p = recordSession(p, [12, 12, 12]);
      expect(suggestChange(p, Experience.justStarted, day.addDays(8)), isNull);
      p = recordSession(p, [12, 13, 12]);
      final s = suggestChange(p, Experience.justStarted, day.addDays(8));
      expect(s?.direction, ChangeDirection.harder);
      expect(s?.to.name, 'Push-up diamante');
    });

    test('una sessione in mezzo azzera il conteggio', () {
      var p = start();
      p = recordSession(p, [12, 12, 12]);
      p = recordSession(p, [12, 10, 9]);
      p = recordSession(p, [12, 12, 12]);
      expect(p.topStreak, 1);
      expect(suggestChange(p, Experience.justStarted, day.addDays(30)), isNull);
    });

    test('la velocità dipende dall\'esperienza', () {
      var p = start();
      p = recordSession(p, [12, 12, 12]);
      p = recordSession(p, [12, 12, 12]);
      // 3–12 mesi: ogni 2 settimane.
      expect(
        suggestChange(p, Experience.threeToTwelveMonths, day.addDays(13)),
        isNull,
      );
      expect(
        suggestChange(p, Experience.threeToTwelveMonths, day.addDays(14)),
        isNotNull,
      );
      // 3+ anni: ogni 4 settimane.
      expect(
        suggestChange(p, Experience.overThreeYears, day.addDays(27)),
        isNull,
      );
      expect(
        suggestChange(p, Experience.overThreeYears, day.addDays(28)),
        isNotNull,
      );
    });

    test('2 sessioni sotto il minimo propongono la variante precedente', () {
      var p = start();
      p = recordSession(p, [6, 5, 5]);
      p = recordSession(p, [7, 6, 4]);
      final s = suggestChange(p, Experience.overThreeYears, day);
      expect(s?.direction, ChangeDirection.easier);
      expect(s?.to.name, 'Push-up sulle ginocchia');
      expect(s?.message, contains('torna a'));
    });

    test('non propone oltre gli estremi della catena', () {
      var first = start(0);
      first = recordSession(first, [1, 1]);
      first = recordSession(first, [1, 1]);
      expect(suggestChange(first, Experience.justStarted, day), isNull);

      var last = start(6);
      last = recordSession(last, [10, 10]);
      last = recordSession(last, [10, 10]);
      expect(
        suggestChange(last, Experience.justStarted, day.addDays(60)),
        isNull,
      );
    });

    test('cambiare variante riparte da zero', () {
      var p = recordSession(start(), [12, 12, 12]);
      p = changePosition(p, 4, day.addDays(10));
      expect(p.position, 4);
      expect(p.topStreak, 0);
      expect(p.since, day.addDays(10));
    });

    test('si salva e si rilegge', () {
      final p = recordSession(start(), [12, 12, 12]);
      expect(ChainProgress.fromJson(ChainId.push, p.toJson()), p);
    });
  });

  group('Livello', () {
    Map<ChainId, ChainProgress> at(Map<ChainId, int> positions) => {
      for (final MapEntry(key: c, value: pos) in positions.entries)
        c: ChainProgress(
          chain: c,
          position: pos,
          since: const LocalDate(2026, 1, 1),
        ),
    };

    test('tutto all\'inizio è Principiante allo 0%', () {
      final l = computeLevel(at({for (final c in ChainId.values) c: 0}));
      expect(l.level, Difficulty.beginner);
      expect(l.percent, 0);
      expect(l.next, Difficulty.intermediate);
      expect(l.nextSkill?.name, 'Push-up inclinati');
    });

    test('tutto al massimo è Élite al 100%', () {
      final l = computeLevel(
        at({for (final c in ChainId.values) c: Catalog.lastPosition(c)}),
      );
      expect(l.level, Difficulty.elite);
      expect(l.percent, 100);
      expect(l.next, isNull);
      expect(l.nextSkill, isNull);
    });

    test('a metà strada mostra la percentuale verso il successivo', () {
      final l = computeLevel(
        at({
          ChainId.push: 3,
          ChainId.pull: 2,
          ChainId.dip: 1,
          ChainId.legs: 1,
          ChainId.core: 1,
        }),
      );
      expect(l.level, Difficulty.intermediate);
      expect(l.percent, inInclusiveRange(1, 99));
    });

    test('la prossima abilità è nella catena più vicina al salto', () {
      final progress = at({
        ChainId.push: 4,
        ChainId.pull: 3,
        ChainId.dip: 1,
        ChainId.legs: 2,
        ChainId.core: 1,
      });
      progress[ChainId.push] = progress[ChainId.push]!.copyWith(topStreak: 1);
      expect(computeLevel(progress).nextSkill?.name, 'Push-up arciere');
    });
  });

  group('Profilo atleta', () {
    test('si salva e si rilegge', () {
      final p = profile().copyWith(
        name: 'Alex',
        reminder: const ReminderTime(18, 30),
      );
      final back = AthleteProfile.fromJson(p.toJson());
      expect(back.name, 'Alex');
      expect(back.difficulty, p.difficulty);
      expect(back.experience, p.experience);
      expect(back.trainingDays, p.trainingDays);
      expect(back.test, p.test);
      expect(back.reminder, const ReminderTime(18, 30));
      expect(back.initial, 'A');
    });

    test('etichette dei giorni e della progressione', () {
      expect(trainingDaysLabel({6, 1, 4, 2}), 'L · M · G · S');
      expect(
        Experience.threeToTwelveMonths.progressionLabel,
        'ogni 2 settimane',
      );
      expect(Experience.overThreeYears.progressionLabel, 'ogni mese');
    });
  });
}
