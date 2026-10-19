// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:meta/meta.dart';

/// Come si impara una skill: requisiti, tappe e metodo.
@immutable
class SkillGuide {
  const SkillGuide({
    required this.id,
    required this.name,
    required this.summary,
    required this.requires,
    required this.steps,
    required this.method,
    required this.tips,
    required this.mistakes,
    required this.time,
  });

  final String id;
  final String name;

  /// Cos'è, in una frase.
  final String summary;

  /// Forza di base da avere prima di iniziare.
  final List<String> requires;

  /// Id degli esercizi, dalla prima tappa alla skill.
  final List<String> steps;

  /// Come allenarla (frequenza, serie, quando passare alla tappa dopo).
  final List<String> method;
  final List<String> tips;
  final List<String> mistakes;

  /// Tempo realistico per arrivarci partendo dai requisiti.
  final String time;
}

/// I principi che valgono per tutte le skill.
const skillPrinciples = [
  (
    'Da freschi, a inizio allenamento',
    'Le skill sono tecnica e forza insieme: allenale subito dopo il '
        'riscaldamento, mai a fine sessione quando sei stanco.',
  ),
  (
    'Spesso e poco',
    '3–5 volte a settimana per 10–20 minuti funzionano meglio di una '
        'sessione lunga. Il sistema nervoso impara con la frequenza.',
  ),
  (
    'Tenute brevi e pulite',
    'Meglio 6 tenute da 5–8 secondi perfette che una da 20 secondi storta. '
        'Fermati quando la forma peggiora.',
  ),
  (
    'Una tappa alla volta',
    'Passa alla tappa dopo quando tieni 3 serie da 15–20 secondi (o fai '
        '3 serie da 5–8 ripetizioni) con la forma giusta.',
  ),
  (
    'Recupero vero',
    '2–3 minuti tra le serie di skill. Non è cardio: ogni tentativo deve '
        'essere al massimo della qualità.',
  ),
  (
    'Poche skill insieme',
    'Una o due skill di spinta e una di tirata al massimo. Troppe insieme '
        'rallentano tutte.',
  ),
  (
    'Polsi, spalle e gomiti',
    'Scalda sempre i polsi e le spalle. Dolore alle articolazioni = fermati '
        'e torna alla tappa precedente.',
  ),
  (
    'Filmati',
    'Un video di lato ti mostra subito se il corpo è dritto, se le braccia '
        'sono tese e dove perdi la linea.',
  ),
];

const skillGuides = [
  SkillGuide(
    id: 'handstand',
    name: 'Verticale (handstand)',
    summary:
        'In equilibrio sulle mani, corpo dritto come una linea dai polsi ai '
        'piedi. La base di quasi tutte le skill di spinta.',
    requires: [
      'Plank da 60 secondi',
      'Pike push-up: 3 serie da 8',
      'Polsi senza dolore in appoggio',
    ],
    steps: [
      'drill_wall_walk',
      'drill_chest_to_wall_hs',
      'drill_heel_pulls',
      'drill_handstand_kick_up',
      'skill_handstand_free',
      'drill_hs_shoulder_taps',
    ],
    method: [
      'Ogni giorno o quasi: 10–15 minuti di tentativi.',
      'Al muro: 4–6 tenute da 20–45 secondi, petto verso il muro.',
      'Libera: tanti tentativi brevi, conta solo quelli puliti.',
      'Passi al libero quando tieni 60 secondi al muro con il corpo dritto.',
    ],
    tips: [
      'Spingi forte il pavimento: spalle alle orecchie.',
      'L\'equilibrio si fa con le dita: premi per non cadere avanti, '
          'col palmo per non cadere indietro.',
      'Impara a uscire ruotando una mano (pirouette) prima di tentare il '
          'libero: così non hai paura di cadere.',
    ],
    mistakes: [
      'Schiena ad arco a banana: stringi addome e glutei.',
      'Braccia piegate o spalle chiuse.',
      'Guardare troppo avanti: lo sguardo va tra le mani.',
    ],
    time: '3–12 mesi',
  ),
  SkillGuide(
    id: 'hspu',
    name: 'Handstand push-up',
    summary:
        'Piegamenti in verticale: la testa scende fino a terra e risali. '
        'La massima forza di spinta sopra la testa.',
    requires: [
      'Verticale al muro da 45 secondi',
      'Pike push-up rialzati: 3 serie da 8',
    ],
    steps: [
      'shoulders_pike',
      'shoulders_pike_elevated',
      'drill_deficit_pike',
      'drill_hspu_negative',
      'shoulders_wall_hspu',
      'skill_freestanding_hspu',
    ],
    method: [
      '2–3 volte a settimana, 3–5 serie da 3–8 ripetizioni.',
      'Le negative: scendi in 4–5 secondi, risali con i piedi.',
      'Passa alla tappa dopo quando fai 3 serie da 8 pulite.',
    ],
    tips: [
      'La testa scende davanti alle mani: mani e testa fanno un triangolo.',
      'Gomiti a 45°, non aperti a 90°.',
      'Metti un cuscino sotto la testa le prime volte.',
    ],
    mistakes: [
      'Gomiti larghi: stressano le spalle.',
      'Scendere di colpo.',
      'Schiena inarcata al muro.',
    ],
    time: '4–12 mesi',
  ),
  SkillGuide(
    id: 'planche',
    name: 'Planche',
    summary:
        'Corpo orizzontale sospeso sopra le mani, braccia tese. Una delle '
        'skill più difficili: richiede anni di lavoro paziente.',
    requires: [
      'Push-up: 3 serie da 20',
      'Dip: 3 serie da 12',
      'Crow pose da 30 secondi',
    ],
    steps: [
      'acc_pseudo_planche',
      'drill_planche_lean',
      'skill_crow',
      'skill_tuck_planche',
      'drill_planche_pushup_tuck',
      'drill_adv_tuck_planche',
      'drill_straddle_planche',
      'skill_full_planche',
    ],
    method: [
      '3 volte a settimana, all\'inizio della sessione.',
      'Tenute: 6–8 da 5–10 secondi, recupero 2 minuti.',
      'Planche lean: spingi le spalle sempre più avanti delle mani.',
      'Passi alla tappa dopo con 3 serie da 15 secondi pulite.',
    ],
    tips: [
      'Braccia sempre tese: il gomito bloccato è la regola numero uno.',
      'Spalle avanti e scapole aperte (schiena tonda in alto).',
      'Mani girate verso l\'esterno o all\'indietro tolgono stress ai polsi.',
    ],
    mistakes: [
      'Piegare i gomiti per "aiutarsi".',
      'Fare troppo volume: i tendini del bicipite si infiammano.',
      'Saltare le tappe.',
    ],
    time: '1–4 anni',
  ),
  SkillGuide(
    id: 'front_lever',
    name: 'Front lever',
    summary:
        'Appeso alla sbarra, corpo orizzontale a pancia in su e braccia tese. '
        'La skill di tirata più famosa.',
    requires: ['Trazioni: 3 serie da 8', 'Hollow body da 30 secondi'],
    steps: [
      'acc_scap_pull',
      'drill_tuck_fl_raise',
      'skill_tuck_front_lever',
      'drill_adv_tuck_fl',
      'drill_one_leg_fl',
      'drill_fl_negative',
      'drill_straddle_fl',
      'skill_front_lever',
    ],
    method: [
      '2–3 volte a settimana, nei giorni di tirata.',
      'Tenute: 5–8 da 5–10 secondi; salite lente: 3 serie da 5.',
      'Passa alla tappa dopo con 3 serie da 15 secondi.',
    ],
    tips: [
      'Spingi la sbarra verso i fianchi con le braccia tese.',
      'Scapole giù e indietro, bacino in linea con le spalle.',
      'Le negative dal lever rovesciato costruiscono forza in fretta.',
    ],
    mistakes: [
      'Bacino che cade sotto la linea.',
      'Gomiti piegati.',
      'Tenute troppo lunghe e storte.',
    ],
    time: '6–24 mesi',
  ),
  SkillGuide(
    id: 'back_lever',
    name: 'Back lever',
    summary:
        'Appeso alla sbarra, corpo orizzontale a pancia in giù dietro le '
        'braccia. Più facile del front lever, ma stressa le spalle.',
    requires: ['Trazioni: 3 serie da 6', 'Spalle mobili (german hang)'],
    steps: [
      'drill_german_hang',
      'drill_skin_the_cat',
      'drill_tuck_back_lever',
      'drill_adv_tuck_bl',
      'drill_straddle_bl',
      'skill_back_lever',
    ],
    method: [
      '2 volte a settimana: le spalle hanno bisogno di adattarsi.',
      'Tenute: 5–6 da 5–10 secondi.',
      'German hang: 3 tenute da 10–20 secondi, senza forzare.',
    ],
    tips: [
      'Entra e esci dalla posizione sempre con il controllo (skin the cat).',
      'Glutei stretti e corpo dritto: niente pancia che scende.',
    ],
    mistakes: [
      'Forzare la spalla in apertura: scendi solo dove non fa male.',
      'Braccia piegate.',
    ],
    time: '3–12 mesi',
  ),
  SkillGuide(
    id: 'muscle_up',
    name: 'Muscle-up',
    summary:
        'Una trazione esplosiva che continua sopra la sbarra fino a braccia '
        'tese. Unisce tirata e spinta.',
    requires: ['Trazioni: 3 serie da 10', 'Dip: 3 serie da 10'],
    steps: [
      'pull_up',
      'drill_explosive_pullup',
      'dip_straight_bar',
      'drill_muscle_up_transition',
      'drill_muscle_up_negative',
      'skill_muscle_up',
    ],
    method: [
      '2–3 volte a settimana, prima della forza.',
      'Trazioni esplosive: 4–6 serie da 3–5, petto alla sbarra.',
      'Negative: scendi dalla posizione alta in 4–5 secondi.',
    ],
    tips: [
      'Tira verso i fianchi, non verso il mento: la sbarra va al petto basso.',
      'Una leggera oscillazione (hollow → arch) aiuta all\'inizio.',
      'Presa falsa (false grip) per il muscle-up lento e pulito.',
    ],
    mistakes: [
      'Tirare dritto in su: la sbarra blocca il passaggio.',
      'Un braccio che passa prima dell\'altro (chicken wing).',
    ],
    time: '2–9 mesi',
  ),
  SkillGuide(
    id: 'l_sit',
    name: 'L-sit e V-sit',
    summary:
        'Seduto in aria sulle mani con le gambe tese davanti (L), poi sempre '
        'più in alto (V). Core e compressione.',
    requires: ['Dip: 3 serie da 8', 'Plank da 60 secondi'],
    steps: [
      'core_tuck_lsit',
      'drill_compression_lift',
      'drill_one_leg_lsit',
      'core_lsit',
      'skill_v_sit',
    ],
    method: [
      '3–5 volte a settimana, anche a fine allenamento.',
      'Tenute: 5–6 da 10–20 secondi.',
      'Allunga i muscoli posteriori delle cosce: senza flessibilità la V non '
          'arriva.',
    ],
    tips: [
      'Spingi le spalle giù, lontano dalle orecchie.',
      'Punte dei piedi tese, ginocchia bloccate.',
      'Le paralette o due sedie rendono tutto più facile ai polsi.',
    ],
    mistakes: ['Spalle alzate.', 'Ginocchia piegate nella L.'],
    time: '1–6 mesi (L), 6–18 mesi (V)',
  ),
  SkillGuide(
    id: 'human_flag',
    name: 'Bandiera (human flag)',
    summary:
        'Corpo orizzontale di lato, tenendosi a un palo verticale: un braccio '
        'tira, l\'altro spinge.',
    requires: ['Trazioni: 3 serie da 8', 'Plank laterale da 60 secondi'],
    steps: [
      'acc_side_plank',
      'drill_vertical_flag',
      'drill_flag_tuck',
      'drill_flag_straddle',
      'skill_human_flag',
    ],
    method: [
      '2–3 volte a settimana, su entrambi i lati.',
      'Tenute: 5–6 da 5–10 secondi.',
    ],
    tips: [
      'Mani a una distanza di poco più delle spalle.',
      'Il braccio sotto spinge tesissimo, quello sopra tira.',
      'Inizia dalla bandiera verticale e abbassala piano.',
    ],
    mistakes: ['Braccio di sotto piegato.', 'Fianchi che cedono.'],
    time: '3–12 mesi',
  ),
  SkillGuide(
    id: 'pistol',
    name: 'Pistol squat',
    summary:
        'Squat completo su una gamba sola, l\'altra tesa in avanti. Forza, '
        'equilibrio e mobilità della caviglia.',
    requires: ['Squat: 3 serie da 20', 'Affondi bulgari: 3 serie da 8'],
    steps: [
      'legs_bulgarian',
      'legs_pistol_assisted',
      'drill_box_pistol',
      'legs_pistol',
    ],
    method: [
      '2–3 volte a settimana, 3–5 serie da 3–8 per gamba.',
      'Abbassa il rialzo un po\' alla volta.',
    ],
    tips: [
      'Braccia in avanti per bilanciare.',
      'Un rialzo sotto il tallone aiuta se la caviglia è rigida.',
    ],
    mistakes: ['Tallone che si stacca.', 'Ginocchio che rientra.'],
    time: '1–6 mesi',
  ),
  SkillGuide(
    id: 'one_arm_push_up',
    name: 'Push-up a un braccio',
    summary:
        'Un piegamento completo con una mano sola, corpo dritto e senza '
        'ruotare.',
    requires: ['Push-up: 3 serie da 25', 'Push-up diamante: 3 serie da 12'],
    steps: [
      'push_diamond',
      'push_archer',
      'drill_incline_one_arm_pushup',
      'push_one_arm',
    ],
    method: [
      '2–3 volte a settimana, 3–5 serie da 3–6 per braccio.',
      'Abbassa l\'appoggio inclinato settimana dopo settimana.',
    ],
    tips: [
      'Piedi larghi all\'inizio, poi sempre più vicini.',
      'Stringi forte glutei e addome: il bacino non deve ruotare.',
    ],
    mistakes: ['Ruotare il busto.', 'Gomito che si apre.'],
    time: '3–12 mesi',
  ),
  SkillGuide(
    id: 'one_arm_pull_up',
    name: 'Trazione a un braccio',
    summary:
        'Una trazione completa con un braccio solo. Richiede tanta forza e '
        'tendini pronti: va costruita con pazienza.',
    requires: ['Trazioni: 3 serie da 15', 'Trazioni arciere: 3 serie da 5'],
    steps: [
      'pull_archer',
      'drill_typewriter_pullup',
      'drill_one_arm_negative',
      'skill_one_arm_pullup',
    ],
    method: [
      '2 volte a settimana, 4–6 serie da 1–3 per braccio.',
      'Negative: 3–5 secondi di discesa, mai fino al dolore.',
    ],
    tips: [
      'Scapola attiva: tira prima giù la spalla.',
      'L\'altra mano può aiutare tenendo il polso, poi l\'avambraccio, poi '
          'niente.',
    ],
    mistakes: ['Troppo volume: gomiti doloranti.', 'Ruotare tutto il corpo.'],
    time: '1–3 anni',
  ),
  SkillGuide(
    id: 'elbow_lever',
    name: 'Elbow lever',
    summary:
        'Corpo orizzontale in equilibrio sui gomiti appoggiati ai fianchi. '
        'La prima skill di equilibrio sulle mani, accessibile a tutti.',
    requires: ['Plank da 45 secondi', 'Polsi senza dolore'],
    steps: ['mob_wrist', 'acc_pseudo_planche', 'skill_elbow_lever'],
    method: [
      '3–4 volte a settimana, 5–6 tenute da 5–15 secondi.',
      'Inizia con i piedi appoggiati e alleggerisci.',
    ],
    tips: [
      'Gomiti sotto le anche, dita girate di lato o indietro.',
      'Sposta il peso avanti finché i piedi si staccano da soli.',
    ],
    mistakes: ['Gomiti troppo larghi.', 'Testa che cade in avanti.'],
    time: '2–8 settimane',
  ),
  SkillGuide(
    id: 'dragon_flag',
    name: 'Dragon flag',
    summary:
        'Sdraiato su una panca, corpo dritto sollevato sulle spalle che '
        'scende lento. Il core più forte che c\'è.',
    requires: [
      'Hollow body da 45 secondi',
      'Sollevamenti gambe: 3 serie da 10',
    ],
    steps: [
      'core_hollow',
      'drill_tuck_dragon_flag',
      'drill_dragon_flag_negative',
      'core_dragon_flag',
    ],
    method: [
      '2–3 volte a settimana, 3–5 serie da 3–6.',
      'Le negative: 4–6 secondi di discesa.',
    ],
    tips: [
      'Il peso è sulle spalle, mai sul collo.',
      'Bacino bloccato: il corpo è una tavola.',
    ],
    mistakes: ['Piegarsi alle anche.', 'Scendere di colpo.'],
    time: '2–6 mesi',
  ),
];

SkillGuide? skillGuideById(String id) {
  for (final s in skillGuides) {
    if (s.id == id) return s;
  }
  return null;
}
