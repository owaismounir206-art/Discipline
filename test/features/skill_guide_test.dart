// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:discipline/features/exercises/domain/catalog.dart';
import 'package:discipline/features/exercises/domain/exercise.dart';
import 'package:discipline/features/exercises/domain/skill_guide.dart';
import 'package:discipline/features/profile/domain/athlete_profile.dart';
import 'package:discipline/features/timer/domain/interval.dart';
import 'package:discipline/features/workout/domain/focus_workout.dart';
import 'package:discipline/features/workout/domain/my_program.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ogni tappa delle skill esiste nel catalogo', () {
    for (final g in skillGuides) {
      for (final id in g.steps) {
        expect(Catalog.byId(id), isNotNull, reason: '${g.id}: $id');
      }
      expect(g.steps.toSet(), hasLength(g.steps.length), reason: g.id);
    }
  });

  test('ogni zona ha abbastanza esercizi per un circuito', () {
    for (final f in focusChoices) {
      for (final d in Difficulty.values) {
        final pick = pickFocus(f, maxLevel: maxLevelFor(d));
        expect(pick.length, 5, reason: '${f.label} ${d.label}');
        expect(pick.map((e) => e.id).toSet(), hasLength(5));
        for (final e in pick) {
          expect(e.difficulty, lessThanOrEqualTo(maxLevelFor(d)));
          expect(e.focusAreas, contains(f));
        }
      }
    }
  });

  test('il circuito diventa passi del timer', () {
    const c = IntervalConfig.circuit([
      'acc_glute_bridge',
      'acc_crunch',
    ], title: 'Prova');
    final back = IntervalConfig.fromQuery(c.toQuery());
    expect(back.ids, c.ids);
    expect(back.label, 'Prova');
    final steps = buildSteps(back);
    expect(steps.where((s) => s.phase == Phase.work), hasLength(4));
  });

  test('la scheda dell\'AI si legge e scarta gli esercizi inventati', () {
    final p = parseProgram('''
Ecco: {"name":"PPL","days":[{"name":"Spinta","weekday":1,"exercises":[
{"id":"push_classic","sets":4,"target":12,"rest":90,"original":"Piegamenti"},
{"id":"panca_piana","sets":3,"target":8,"rest":120}]},
{"name":"Vuoto","exercises":[]}],"notes":["Panca sostituita"]}''', 'testo');
    expect(p.days, hasLength(1));
    expect(p.days.single.exercises.single.id, 'push_classic');
    expect(p.dayFor(1)?.name, 'Spinta');
    expect(p.source, 'testo');
    final plan = p.days.single.toPlan();
    expect(plan.exercises.single.target, 12);
    expect(plan.exercises.single.isVolume, isTrue);
    expect(MyProgram.fromJson(p.toJson()).days.single.name, 'Spinta');
    expect(() => parseProgram('niente', ''), throwsFormatException);
    expect(catalogForAi(), contains('push_classic: Push-up classici'));
    expect(
      Catalog.all.where((e) => e.chain == ChainId.skillDrills),
      isNotEmpty,
    );
  });
}
