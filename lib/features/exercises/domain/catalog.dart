// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'exercise.dart';

/// Catalogo degli esercizi a corpo libero, organizzato in catene.
abstract final class Catalog {
  static final Map<ChainId, List<Exercise>> chains = {
    ChainId.push: _push,
    ChainId.pull: _pull,
    ChainId.dip: _dip,
    ChainId.legs: _legs,
    ChainId.core: _core,
    ChainId.shoulders: _shoulders,
    ChainId.skills: _skills,
  };

  static final Map<String, Exercise> _byId = {
    for (final chain in chains.values)
      for (final exercise in chain) exercise.id: exercise,
  };

  static List<Exercise> get all => [for (final c in chains.values) ...c];

  static List<Exercise> chain(ChainId id) => chains[id]!;

  static Exercise at(ChainId id, int position) {
    final list = chain(id);
    return list[position.clamp(0, list.length - 1)];
  }

  static Exercise? byId(String id) => _byId[id];

  /// Ultima posizione della catena.
  static int lastPosition(ChainId id) => chain(id).length - 1;
}

const _push = [
  Exercise(
    id: 'push_wall',
    name: 'Push-up al muro',
    muscleGroup: MuscleGroup.chest,
    chain: ChainId.push,
    position: 0,
    measure: Measure.reps,
    range: TargetRange(10, 15),
    instructions: [
      'In piedi, a un passo dal muro, mani all\'altezza delle spalle.',
      'Corpo dritto dalla testa ai talloni.',
      'Piega i gomiti fino a portare il petto vicino al muro.',
      'Spingi e torna su con le braccia distese.',
    ],
    mistakes: [
      'Inarcare la schiena o spingere il bacino in avanti.',
      'Aprire troppo i gomiti: tienili a circa 45° dal corpo.',
    ],
  ),
  Exercise(
    id: 'push_incline',
    name: 'Push-up inclinati',
    muscleGroup: MuscleGroup.chest,
    chain: ChainId.push,
    position: 1,
    measure: Measure.reps,
    range: TargetRange(8, 12),
    instructions: [
      'Mani su un rialzo stabile (tavolo, panca, gradino alto).',
      'Corpo in linea, addome e glutei contratti.',
      'Scendi finché il petto sfiora il bordo.',
      'Spingi fino a distendere le braccia.',
    ],
    mistakes: ['Lasciar cadere il bacino.', 'Fare solo metà movimento.'],
  ),
  Exercise(
    id: 'push_knee',
    name: 'Push-up sulle ginocchia',
    muscleGroup: MuscleGroup.chest,
    chain: ChainId.push,
    position: 2,
    measure: Measure.reps,
    range: TargetRange(8, 12),
    instructions: [
      'Ginocchia a terra, mani poco più larghe delle spalle.',
      'Linea dritta da ginocchia a testa.',
      'Scendi con il petto verso terra controllando il movimento.',
      'Spingi fino a distendere le braccia.',
    ],
    mistakes: [
      'Piegare le anche invece di tenerle in linea.',
      'Guardare in avanti: lo sguardo va a terra.',
    ],
  ),
  Exercise(
    id: 'push_classic',
    name: 'Push-up classici',
    muscleGroup: MuscleGroup.chest,
    chain: ChainId.push,
    position: 3,
    measure: Measure.reps,
    range: TargetRange(8, 12),
    instructions: [
      'Mani sotto le spalle, piedi uniti, corpo in linea.',
      'Contrai addome e glutei.',
      'Scendi finché il petto è a un pugno da terra.',
      'Spingi forte fino a braccia distese.',
    ],
    mistakes: [
      'Bacino troppo alto o troppo basso.',
      'Gomiti larghi a 90°: tienili a circa 45°.',
      'Collo proteso in avanti.',
    ],
  ),
  Exercise(
    id: 'push_diamond',
    name: 'Push-up diamante',
    muscleGroup: MuscleGroup.chest,
    chain: ChainId.push,
    position: 4,
    measure: Measure.reps,
    range: TargetRange(8, 12),
    instructions: [
      'Mani vicine sotto il petto: pollici e indici formano un rombo.',
      'Corpo in linea, gomiti vicini ai fianchi.',
      'Scendi fino a sfiorare le mani con il petto.',
      'Spingi fino a distendere le braccia.',
    ],
    mistakes: [
      'Aprire i gomiti verso l\'esterno.',
      'Perdere la linea del corpo a fine serie.',
    ],
  ),
  Exercise(
    id: 'push_archer',
    name: 'Push-up arciere',
    muscleGroup: MuscleGroup.chest,
    chain: ChainId.push,
    position: 5,
    measure: Measure.reps,
    range: TargetRange(5, 8),
    perSide: true,
    instructions: [
      'Mani molto larghe, dita in avanti.',
      'Scendi verso un lato piegando un solo braccio.',
      'L\'altro braccio resta disteso e aiuta poco.',
      'Torna al centro e alterna i lati.',
    ],
    mistakes: [
      'Ruotare il busto invece di restare paralleli al suolo.',
      'Piegare entrambe le braccia.',
    ],
  ),
  Exercise(
    id: 'push_one_arm',
    name: 'Push-up a un braccio',
    muscleGroup: MuscleGroup.chest,
    chain: ChainId.push,
    position: 6,
    measure: Measure.reps,
    range: TargetRange(3, 6),
    perSide: true,
    instructions: [
      'Piedi larghi per avere equilibrio, una mano sotto il petto.',
      'L\'altra mano dietro la schiena.',
      'Scendi lentamente mantenendo le spalle parallele al suolo.',
      'Spingi fino a distendere il braccio.',
    ],
    mistakes: [
      'Ruotare il busto per aiutarsi.',
      'Scendere troppo veloce senza controllo.',
    ],
  ),
];

const _pull = [
  Exercise(
    id: 'pull_australian',
    name: 'Trazioni australiane',
    muscleGroup: MuscleGroup.back,
    chain: ChainId.pull,
    position: 0,
    measure: Measure.reps,
    range: TargetRange(8, 12),
    instructions: [
      'Sotto una sbarra bassa o un tavolo robusto, presa alla larghezza delle spalle.',
      'Corpo dritto, talloni a terra.',
      'Tira il petto verso la sbarra stringendo le scapole.',
      'Scendi lentamente a braccia distese.',
    ],
    mistakes: [
      'Lasciar cadere il bacino.',
      'Tirare con il collo invece che con la schiena.',
    ],
  ),
  Exercise(
    id: 'pull_negative',
    name: 'Trazioni negative',
    muscleGroup: MuscleGroup.back,
    chain: ChainId.pull,
    position: 1,
    measure: Measure.reps,
    range: TargetRange(4, 6),
    instructions: [
      'Sali con un salto o una sedia con il mento sopra la sbarra.',
      'Scendi il più lentamente possibile: almeno 5 secondi.',
      'Arriva a braccia distese e ripeti.',
    ],
    mistakes: [
      'Lasciarsi cadere nell\'ultima parte.',
      'Spalle alle orecchie: tienile basse e attive.',
    ],
  ),
  Exercise(
    id: 'pull_band',
    name: 'Trazioni con elastico',
    muscleGroup: MuscleGroup.back,
    chain: ChainId.pull,
    position: 2,
    measure: Measure.reps,
    range: TargetRange(6, 10),
    instructions: [
      'Aggancia un elastico alla sbarra e metti un piede o un ginocchio nell\'anello.',
      'Presa poco più larga delle spalle, palmi in avanti.',
      'Tira finché il mento supera la sbarra.',
      'Scendi controllando fino a braccia distese.',
    ],
    mistakes: [
      'Rimbalzare sull\'elastico in basso.',
      'Fare mezze ripetizioni.',
    ],
  ),
  Exercise(
    id: 'pull_up',
    name: 'Trazioni',
    muscleGroup: MuscleGroup.back,
    chain: ChainId.pull,
    position: 3,
    measure: Measure.reps,
    range: TargetRange(5, 8),
    instructions: [
      'Appeso alla sbarra, presa poco più larga delle spalle.',
      'Abbassa le scapole e contrai l\'addome.',
      'Tira finché il mento supera la sbarra.',
      'Scendi fino a braccia distese.',
    ],
    mistakes: [
      'Slanciarsi con le gambe.',
      'Non distendere le braccia in basso.',
    ],
  ),
  Exercise(
    id: 'pull_wide',
    name: 'Trazioni larghe',
    muscleGroup: MuscleGroup.back,
    chain: ChainId.pull,
    position: 4,
    measure: Measure.reps,
    range: TargetRange(5, 8),
    instructions: [
      'Presa molto larga, palmi in avanti.',
      'Tira portando il petto verso la sbarra.',
      'Gomiti verso il basso e all\'indietro.',
      'Scendi lentamente.',
    ],
    mistakes: ['Accorciare il movimento.', 'Inarcare troppo la schiena.'],
  ),
  Exercise(
    id: 'pull_archer',
    name: 'Trazioni arciere',
    muscleGroup: MuscleGroup.back,
    chain: ChainId.pull,
    position: 5,
    measure: Measure.reps,
    range: TargetRange(3, 6),
    perSide: true,
    instructions: [
      'Presa molto larga.',
      'Tira verso una mano: l\'altro braccio resta quasi disteso.',
      'Scendi e alterna il lato.',
    ],
    mistakes: [
      'Piegare entrambe le braccia allo stesso modo.',
      'Ruotare il corpo.',
    ],
  ),
];

const _dip = [
  Exercise(
    id: 'dip_bench',
    name: 'Dip su panca',
    muscleGroup: MuscleGroup.chest,
    chain: ChainId.dip,
    position: 0,
    measure: Measure.reps,
    range: TargetRange(8, 12),
    instructions: [
      'Mani sul bordo di una panca o sedia stabile dietro di te.',
      'Gambe piegate (più facile) o distese (più difficile).',
      'Piega i gomiti fino a circa 90°.',
      'Spingi fino a distendere le braccia.',
    ],
    mistakes: [
      'Scendere troppo: fa male alle spalle.',
      'Allontanare il bacino dalla panca.',
    ],
  ),
  Exercise(
    id: 'dip_negative',
    name: 'Dip negativi alle parallele',
    muscleGroup: MuscleGroup.chest,
    chain: ChainId.dip,
    position: 1,
    measure: Measure.reps,
    range: TargetRange(4, 6),
    instructions: [
      'Parti in alto alle parallele a braccia distese.',
      'Scendi in almeno 5 secondi fino a gomiti a 90°.',
      'Rimetti i piedi a terra e torna su.',
    ],
    mistakes: [
      'Lasciarsi cadere in basso.',
      'Spalle che salgono verso le orecchie.',
    ],
  ),
  Exercise(
    id: 'dip_parallel',
    name: 'Dip alle parallele',
    muscleGroup: MuscleGroup.chest,
    chain: ChainId.dip,
    position: 2,
    measure: Measure.reps,
    range: TargetRange(6, 10),
    instructions: [
      'In sospensione alle parallele, braccia distese.',
      'Busto leggermente in avanti.',
      'Scendi fino a gomiti a 90°.',
      'Spingi fino a distendere le braccia.',
    ],
    mistakes: ['Movimento a metà.', 'Dondolare con le gambe.'],
  ),
];

const _legs = [
  Exercise(
    id: 'legs_squat',
    name: 'Squat',
    muscleGroup: MuscleGroup.legs,
    chain: ChainId.legs,
    position: 0,
    measure: Measure.reps,
    range: TargetRange(12, 20),
    instructions: [
      'Piedi alla larghezza delle spalle, punte leggermente in fuori.',
      'Scendi spingendo il bacino indietro, petto alto.',
      'Cosce almeno parallele al suolo.',
      'Spingi sui talloni per risalire.',
    ],
    mistakes: [
      'Ginocchia che cadono verso l\'interno.',
      'Talloni che si sollevano.',
    ],
  ),
  Exercise(
    id: 'legs_lunge',
    name: 'Affondi',
    muscleGroup: MuscleGroup.legs,
    chain: ChainId.legs,
    position: 1,
    measure: Measure.reps,
    range: TargetRange(8, 12),
    perSide: true,
    instructions: [
      'Fai un passo lungo in avanti.',
      'Scendi finché il ginocchio dietro sfiora terra.',
      'Busto dritto, ginocchio davanti sopra la caviglia.',
      'Torna su e cambia gamba.',
    ],
    mistakes: [
      'Passo troppo corto.',
      'Ginocchio davanti che supera molto la punta del piede.',
    ],
  ),
  Exercise(
    id: 'legs_bulgarian',
    name: 'Bulgarian split squat',
    muscleGroup: MuscleGroup.legs,
    chain: ChainId.legs,
    position: 2,
    measure: Measure.reps,
    range: TargetRange(8, 12),
    perSide: true,
    instructions: [
      'Piede dietro appoggiato su una panca o sedia.',
      'Scendi in verticale sulla gamba davanti.',
      'Risali spingendo sul tallone davanti.',
    ],
    mistakes: [
      'Spingere con la gamba dietro.',
      'Perdere l\'equilibrio: guarda un punto fisso.',
    ],
  ),
  Exercise(
    id: 'legs_pistol_assisted',
    name: 'Pistol squat assistito',
    muscleGroup: MuscleGroup.legs,
    chain: ChainId.legs,
    position: 3,
    measure: Measure.reps,
    range: TargetRange(5, 8),
    perSide: true,
    instructions: [
      'Tieniti a un palo o a una porta con una mano.',
      'Una gamba distesa in avanti.',
      'Scendi sulla gamba d\'appoggio il più in basso possibile.',
      'Risali usando l\'appoggio il meno possibile.',
    ],
    mistakes: ['Tirarsi su con le braccia.', 'Tallone che si stacca da terra.'],
  ),
  Exercise(
    id: 'legs_pistol',
    name: 'Pistol squat',
    muscleGroup: MuscleGroup.legs,
    chain: ChainId.legs,
    position: 4,
    measure: Measure.reps,
    range: TargetRange(3, 6),
    perSide: true,
    instructions: [
      'In equilibrio su una gamba, l\'altra distesa in avanti.',
      'Braccia avanti per bilanciarti.',
      'Scendi fino in fondo con controllo.',
      'Risali senza appoggi.',
    ],
    mistakes: ['Rimbalzare in basso.', 'Ginocchio che cade verso l\'interno.'],
  ),
];

const _core = [
  Exercise(
    id: 'core_plank',
    name: 'Plank',
    muscleGroup: MuscleGroup.core,
    chain: ChainId.core,
    position: 0,
    measure: Measure.seconds,
    range: TargetRange(30, 60),
    instructions: [
      'Avambracci a terra, gomiti sotto le spalle.',
      'Corpo dritto dalla testa ai talloni.',
      'Contrai addome e glutei, respira normalmente.',
    ],
    mistakes: ['Bacino troppo alto o che cade.', 'Trattenere il respiro.'],
  ),
  Exercise(
    id: 'core_hollow',
    name: 'Hollow body',
    muscleGroup: MuscleGroup.core,
    chain: ChainId.core,
    position: 1,
    measure: Measure.seconds,
    range: TargetRange(20, 40),
    instructions: [
      'Sdraiato sulla schiena, braccia distese sopra la testa.',
      'Solleva spalle e gambe da terra.',
      'Schiena bassa schiacciata a terra.',
      'Tieni la posizione respirando.',
    ],
    mistakes: [
      'Schiena bassa che si stacca dal pavimento.',
      'Gambe troppo alte che rendono tutto più facile.',
    ],
  ),
  Exercise(
    id: 'core_tuck_lsit',
    name: 'L-sit raccolto',
    muscleGroup: MuscleGroup.core,
    chain: ChainId.core,
    position: 2,
    measure: Measure.seconds,
    range: TargetRange(10, 20),
    instructions: [
      'Mani a terra o su due parallele ai lati dei fianchi.',
      'Spingi forte e solleva il corpo.',
      'Ginocchia raccolte verso il petto.',
      'Tieni la posizione.',
    ],
    mistakes: ['Spalle che salgono verso le orecchie.', 'Braccia piegate.'],
  ),
  Exercise(
    id: 'core_lsit',
    name: 'L-sit',
    muscleGroup: MuscleGroup.core,
    chain: ChainId.core,
    position: 3,
    measure: Measure.seconds,
    range: TargetRange(10, 20),
    instructions: [
      'Come l\'L-sit raccolto, ma con le gambe distese in avanti.',
      'Gambe parallele al suolo, punte tese.',
      'Tieni la posizione.',
    ],
    mistakes: ['Gambe che cadono verso terra.', 'Ginocchia piegate.'],
  ),
];

const _shoulders = [
  Exercise(
    id: 'shoulders_pike',
    name: 'Pike push-up',
    muscleGroup: MuscleGroup.shoulders,
    chain: ChainId.shoulders,
    position: 0,
    measure: Measure.reps,
    range: TargetRange(6, 10),
    instructions: [
      'Mani e piedi a terra, bacino in alto: il corpo forma una V rovesciata.',
      'Piega i gomiti portando la testa verso terra davanti alle mani.',
      'Spingi fino a distendere le braccia.',
    ],
    mistakes: ['Gomiti larghi.', 'Abbassare il bacino durante il movimento.'],
  ),
  Exercise(
    id: 'shoulders_pike_elevated',
    name: 'Pike push-up con piedi rialzati',
    muscleGroup: MuscleGroup.shoulders,
    chain: ChainId.shoulders,
    position: 1,
    measure: Measure.reps,
    range: TargetRange(6, 10),
    instructions: [
      'Piedi su una panca o sedia, mani a terra.',
      'Bacino alto sopra le spalle.',
      'Scendi con la testa verso terra e spingi su.',
    ],
    mistakes: ['Mani troppo lontane dalla panca.', 'Movimento a metà.'],
  ),
];

const _skills = [
  Exercise(
    id: 'skill_crow',
    name: 'Crow pose',
    muscleGroup: MuscleGroup.fullBody,
    chain: ChainId.skills,
    position: 0,
    measure: Measure.seconds,
    range: TargetRange(10, 30),
    instructions: [
      'Accovacciato, mani a terra alla larghezza delle spalle.',
      'Appoggia le ginocchia sulla parte alta delle braccia.',
      'Sposta il peso in avanti e solleva i piedi.',
    ],
    mistakes: [
      'Guardare tra i piedi: guarda avanti.',
      'Non spostare abbastanza il peso sulle mani.',
    ],
  ),
  Exercise(
    id: 'skill_wall_handstand',
    name: 'Handstand al muro',
    muscleGroup: MuscleGroup.shoulders,
    chain: ChainId.skills,
    position: 1,
    measure: Measure.seconds,
    range: TargetRange(20, 45),
    instructions: [
      'Mani a terra a una spanna dal muro.',
      'Sali con le gambe fino ad appoggiare i talloni al muro.',
      'Braccia distese, spalle spinte verso le orecchie.',
      'Corpo allineato, addome contratto.',
    ],
    mistakes: ['Schiena inarcata a banana.', 'Braccia piegate.'],
  ),
  Exercise(
    id: 'skill_tuck_planche',
    name: 'Tuck planche',
    muscleGroup: MuscleGroup.fullBody,
    chain: ChainId.skills,
    position: 2,
    measure: Measure.seconds,
    range: TargetRange(5, 15),
    instructions: [
      'Mani a terra o su parallele, braccia distese.',
      'Inclinati in avanti e solleva i piedi raccogliendo le ginocchia.',
      'Schiena arrotondata, scapole aperte.',
    ],
    mistakes: ['Piegare le braccia.', 'Non inclinarsi abbastanza in avanti.'],
  ),
  Exercise(
    id: 'skill_tuck_front_lever',
    name: 'Front lever raccolto',
    muscleGroup: MuscleGroup.back,
    chain: ChainId.skills,
    position: 3,
    measure: Measure.seconds,
    range: TargetRange(5, 15),
    instructions: [
      'Appeso alla sbarra, braccia distese.',
      'Tira le spalle indietro e solleva il corpo in orizzontale.',
      'Ginocchia raccolte al petto, schiena parallela al suolo.',
    ],
    mistakes: ['Piegare le braccia.', 'Bacino più basso delle spalle.'],
  ),
  Exercise(
    id: 'skill_muscle_up',
    name: 'Muscle-up',
    muscleGroup: MuscleGroup.fullBody,
    chain: ChainId.skills,
    position: 4,
    measure: Measure.reps,
    range: TargetRange(2, 5),
    instructions: [
      'Presa stretta e salda sopra la sbarra.',
      'Trazione esplosiva fino al petto.',
      'Porta il busto sopra la sbarra ruotando i polsi.',
      'Finisci con un dip fino a braccia distese.',
    ],
    mistakes: [
      'Trazione troppo lenta o bassa.',
      'Salire con un braccio alla volta.',
    ],
  ),
];
