// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'catalog.dart';
import 'exercise.dart';

/// Attrezzi che possono servire (sedia, tavolo e muro ci sono sempre).
enum Equipment {
  bar('Sbarra per trazioni'),
  parallels('Parallele'),
  bands('Elastici');

  const Equipment(this.label);

  final String label;
}

/// Dove ti alleni: decide quali esercizi si possono fare.
enum TrainingPlace {
  home('Casa', 'a casa', 'Senza attrezzi: sedie, tavolo e muro', {}),
  homeBar('Casa con sbarra', 'a casa', 'Sbarra alla porta', {Equipment.bar}),
  park('Parco', 'al parco', 'Sbarra e parallele', {
    Equipment.bar,
    Equipment.parallels,
  }),
  gym('Palestra', 'in palestra', 'Sbarra, parallele ed elastici', {
    Equipment.bar,
    Equipment.parallels,
    Equipment.bands,
  });

  const TrainingPlace(this.label, this.where, this.hint, this.equipment);

  final String label;

  /// "al parco", "a casa"...
  final String where;
  final String hint;
  final Set<Equipment> equipment;
}

/// Attrezzi che servono per un esercizio.
Set<Equipment> needs(Exercise e) => switch (e.id) {
  'pull_band' => {Equipment.bar, Equipment.bands},
  'pull_australian' => {Equipment.bar},
  'dip_negative' || 'dip_parallel' => {Equipment.parallels},
  _ when e.chain == ChainId.pull => {Equipment.bar},
  'dip_straight_bar' ||
  'skill_tuck_front_lever' ||
  'skill_front_lever' ||
  'skill_muscle_up' ||
  'acc_chin_up' ||
  'acc_scap_pull' ||
  'acc_dead_hang' ||
  'acc_hanging_knee_raise' => {Equipment.bar},
  _ => {},
};

bool canDo(Exercise e, TrainingPlace place) =>
    place.equipment.containsAll(needs(e));

/// L'esercizio da fare in quel posto: lo stesso se si può, altrimenti il
/// sostituto più vicino (es. senza sbarra le trazioni diventano rematore
/// sotto il tavolo). I sostituti non cambiano la progressione della catena.
Exercise adaptTo(Exercise e, TrainingPlace place) {
  if (canDo(e, place)) return e;
  final have = place.equipment;
  // Elastici mancanti ma sbarra presente: trazioni negative.
  if (e.id == 'pull_band' && have.contains(Equipment.bar)) {
    return Catalog.byId('pull_negative')!;
  }
  return switch (e.chain) {
    ChainId.pull => Catalog.byId('acc_table_row')!,
    ChainId.dip =>
      have.contains(Equipment.bar) && e.position >= 2
          ? Catalog.byId('dip_straight_bar')!
          : Catalog.byId('acc_chair_dip')!,
    // Skill alla sbarra: si lavora sulla verticale o sul core.
    ChainId.skills =>
      e.id.contains('lever')
          ? Catalog.byId('core_dragon_flag')!
          : Catalog.byId('skill_wall_handstand')!,
    _ => switch (e.id) {
      'acc_chin_up' || 'acc_scap_pull' => Catalog.byId('acc_table_row')!,
      'acc_hanging_knee_raise' => Catalog.byId('acc_reverse_crunch')!,
      _ => Catalog.byId('acc_superman')!,
    },
  };
}
