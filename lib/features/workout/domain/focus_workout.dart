// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import '../../../core/utils/local_date.dart';
import '../../exercises/domain/catalog.dart';
import '../../exercises/domain/equipment.dart';
import '../../exercises/domain/exercise.dart';
import '../../profile/domain/athlete_profile.dart';
import 'workout_plan.dart';

/// Le zone da allenare a parte, dopo l'allenamento principale: completano
/// quello che la scheda del giorno allena meno.
List<Focus> focusForTemplate(WorkoutTemplate t) => switch (t) {
  WorkoutTemplate.push => const [Focus.triceps, Focus.shoulders, Focus.core],
  WorkoutTemplate.pull => const [Focus.biceps, Focus.forearms, Focus.obliques],
  WorkoutTemplate.legsCore => const [Focus.glutes, Focus.calves, Focus.core],
  WorkoutTemplate.fullBody => const [
    Focus.core,
    Focus.forearms,
    Focus.shoulders,
  ],
};

/// Le zone che si possono scegliere a mano nella sezione "Allenamenti
/// specifici".
const focusChoices = [
  Focus.core,
  Focus.obliques,
  Focus.biceps,
  Focus.triceps,
  Focus.forearms,
  Focus.chest,
  Focus.back,
  Focus.shoulders,
  Focus.legs,
  Focus.glutes,
  Focus.calves,
  Focus.cardio,
  Focus.mobility,
];

/// Difficoltà massima degli esercizi (1–4) per un livello.
int maxLevelFor(Difficulty d) => d.index + 1;

/// Numero che cambia ogni settimana: le scelte variano ma restano uguali
/// per tutta la settimana (il riepilogo e la sessione coincidono).
int weekSeed(LocalDate day) => day.daysSince(const LocalDate(2024, 1, 1)) ~/ 7;

/// Numero che cambia ogni giorno.
int daySeed(LocalDate day) => day.daysSince(const LocalDate(2024, 1, 1));

/// Gli esercizi adatti a una zona, al livello e a dove ti alleni: prima
/// quelli in cui la zona è la principale. Niente skill né tappe dei
/// percorsi: quelle restano nell'allenamento principale.
List<Exercise> focusPool(
  Focus focus, {
  required int maxLevel,
  TrainingPlace? place,
}) {
  final candidates = [
    for (final e in Catalog.all)
      if (!e.chain.isProgression &&
          e.chain != ChainId.skillDrills &&
          e.focusAreas.contains(focus) &&
          e.difficulty <= maxLevel &&
          (place == null || canDo(e, place)))
        e,
  ];
  int rank(Exercise e) => e.focusAreas.first == focus ? 0 : 1;
  // Ordinamento stabile: prima la zona principale, poi i più impegnativi
  // adatti al livello.
  candidates.sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    if (r != 0) return r;
    final l = b.difficulty.compareTo(a.difficulty);
    return l != 0 ? l : a.id.compareTo(b.id);
  });
  return candidates;
}

/// [count] esercizi per la zona, che ruotano con [seed].
List<Exercise> pickFocus(
  Focus focus, {
  required int maxLevel,
  TrainingPlace? place,
  int seed = 0,
  int count = 5,
}) {
  final pool = focusPool(focus, maxLevel: maxLevel, place: place);
  if (pool.length <= count) return pool;
  // Le prime metà della lista (zona principale) hanno la precedenza: si
  // ruota dentro un gruppo un po' più grande di quanto serve.
  final window = (count * 3).clamp(count, pool.length);
  final start = (seed * count) % window;
  return [for (var i = 0; i < count; i++) pool[(start + i) % window]];
}
