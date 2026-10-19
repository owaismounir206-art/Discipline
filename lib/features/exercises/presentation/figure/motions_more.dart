// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:ui';

import 'skeleton.dart';

// Pose chiave dei movimenti aggiunti. Stesse convenzioni di motions.dart:
// pavimento a y = 0, caviglia a -0.03, mani appoggiate a -0.01, la
// figurina guarda a destra.

const _feet = To(0, -0.03);
const _armsDown = Ang(84, 88);
const _bar = Bar(-0.22, -1.0, 0.22, -1.0, thick: true);
const _hands = To(0.03, -1.0);

// ---- Braccia e presa -------------------------------------------------------

/// Curl dei bicipiti in piedi: i gomiti restano ai fianchi.
const _curl = Motion('curl', [
  (Pose(hip: Offset(0, -0.47), arm: Ang(80, 88), leg: _feet), 1),
  (Pose(hip: Offset(0, -0.47), arm: Ang(82, -62), leg: _feet), 1),
], ms: 2000);

/// Flessione dei polsi da seduti, avambracci sulle cosce.
const _wristCurl = Motion(
  'wristCurl',
  [
    (
      Pose(
        hip: Offset(-0.06, -0.27),
        low: -52,
        high: -38,
        neck: -30,
        arm: Ang(92, 22),
        leg: To(0.16, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.06, -0.27),
        low: -52,
        high: -38,
        neck: -30,
        arm: Ang(92, -18),
        leg: To(0.16, -0.03),
      ),
      1,
    ),
  ],
  props: [Block(-0.22, -0.25, 0.04, 0)],
  ms: 1400,
);

/// Farmer hold: braccia tese lungo i fianchi, piccoli passi.
const _gripHold = Motion('gripHold', [
  (
    Pose(
      hip: Offset(0, -0.465),
      arm: Ang(97, 93),
      arm2: Ang(84, 88),
      leg: To(0.09, -0.03),
      leg2: To(-0.09, -0.03),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.47),
      arm: Ang(96, 92),
      arm2: Ang(85, 88),
      leg: To(0.01, -0.06),
      leg2: To(-0.01, -0.03),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.465),
      arm: Ang(95, 92),
      arm2: Ang(86, 89),
      leg: To(-0.09, -0.03),
      leg2: To(0.09, -0.03),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.47),
      arm: Ang(96, 92),
      arm2: Ang(85, 88),
      leg: To(-0.01, -0.03),
      leg2: To(0.01, -0.06),
    ),
    1,
  ),
], ms: 1600);

/// Estensione dei tricipiti a corpo libero, mani su una sbarra bassa: la
/// testa scende verso la sbarra e i gomiti puntano in basso.
const _tricepsExtension = Motion(
  'tricepsExtension',
  [
    (
      Pose(
        hip: Offset(0.311, -0.341),
        low: -45,
        neck: -42,
        arm: To(0.80, -0.50),
        leg: _feet,
        toe: -60,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.381, -0.25),
        low: -30,
        neck: -24,
        arm: To(0.80, -0.50),
        leg: _feet,
        toe: -60,
      ),
      1,
    ),
  ],
  props: [
    Bar(0.70, -0.50, 0.98, -0.50, thick: true),
    Bar(0.94, -0.50, 0.94, 0),
  ],
  ms: 2000,
);

// ---- Skill alla sbarra e statici -------------------------------------------

/// V-sit: in equilibrio sui glutei, busto e gambe a V, braccia avanti.
const _vSit = Motion('vSit', [
  (
    Pose(
      hip: Offset(0, -0.06),
      low: -118,
      neck: -100,
      arm: Ang(-28, -30),
      leg: Ang(-42, -42),
      toe: -30,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.06),
      low: -114,
      neck: -96,
      arm: Ang(-24, -26),
      leg: Ang(-46, -46),
      toe: -34,
    ),
    1,
  ),
], ms: 2600);

/// Back lever raccolto: prono sotto la sbarra, braccia dietro, ginocchia al
/// petto.
const _tuckBackLever = Motion(
  'tuckBackLever',
  [
    (
      Pose(
        hip: Offset(-0.06, -0.81),
        low: 0,
        neck: 4,
        arm: _hands,
        leg: Ang(32, 178),
        toe: 180,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.06, -0.80),
        low: 2,
        neck: 6,
        arm: _hands,
        leg: Ang(30, 176),
        toe: 180,
      ),
      1,
    ),
  ],
  ms: 2600,
  floor: false,
  props: [_bar],
);

/// Back lever: corpo teso orizzontale sotto la sbarra, a faccia in giù.
const _backLever = Motion(
  'backLever',
  [
    (
      Pose(
        hip: Offset(-0.06, -0.81),
        low: 0,
        neck: 4,
        arm: _hands,
        leg: Ang(180, 180),
        toe: 180,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.06, -0.80),
        low: 2,
        neck: 6,
        arm: _hands,
        leg: Ang(178, 178),
        toe: 178,
      ),
      1,
    ),
  ],
  ms: 2600,
  floor: false,
  props: [_bar],
);

const _german = Pose(
  hip: Offset(-0.12, -0.85),
  low: 20,
  neck: 45,
  arm: _hands,
  leg: Ang(100, 96),
  toe: 20,
);

/// German hang: braccia dietro la schiena, busto inclinato in avanti, gambe
/// giù.
const _germanHang = Motion(
  'germanHang',
  [
    (_german, 1),
    (
      Pose(
        hip: Offset(-0.125, -0.85),
        low: 23,
        neck: 48,
        arm: _hands,
        leg: Ang(96, 94),
        toe: 16,
      ),
      1,
    ),
  ],
  ms: 3000,
  floor: false,
  props: [_bar],
);

const _hang = Pose(
  hip: Offset(0, -0.46),
  arm: _hands,
  leg: Ang(84, 98),
  toe: 30,
);

// Skin the cat: il busto ruota intorno alle spalle, che restano sotto la
// sbarra (braccia appena piegate per non staccare le mani).
const _cat1 = Pose(
  hip: Offset(0.115, -0.519),
  low: -120,
  arm: _hands,
  leg: Ang(-60, 95),
);
const _cat2 = Pose(
  hip: Offset(0.201, -0.635),
  low: -150,
  arm: _hands,
  leg: Ang(-80, 70),
);
const _cat3 = Pose(
  hip: Offset(0.24, -0.78),
  low: 180,
  arm: _hands,
  leg: Ang(-100, 50),
);
const _cat4 = Pose(
  hip: Offset(0.185, -0.965),
  low: 135,
  arm: _hands,
  leg: Ang(-140, 10),
);
const _cat5 = Pose(
  hip: Offset(0.03, -1.05),
  low: 90,
  arm: _hands,
  leg: Ang(-100, -80),
);
const _cat6 = Pose(
  hip: Offset(-0.125, -0.965),
  low: 45,
  arm: _hands,
  leg: Ang(-160, -150),
);
const _cat7 = Pose(
  hip: Offset(-0.1525, -0.869),
  low: 20,
  neck: 40,
  arm: _hands,
  leg: Ang(95, 100),
  toe: 20,
);

/// Skin the cat: dall'appeso si raccolgono le gambe, si passa capovolti e
/// si scende in german hang, poi si torna indietro.
const _skinTheCat = Motion(
  'skinTheCat',
  [
    (_hang, 0.8),
    (_cat1, 0.4),
    (_cat2, 0.4),
    (_cat3, 0.5),
    (_cat4, 0.5),
    (_cat5, 0.5),
    (_cat6, 0.5),
    (_cat7, 1.2),
    (_cat6, 0.5),
    (_cat5, 0.5),
    (_cat4, 0.5),
    (_cat3, 0.5),
    (_cat2, 0.4),
    (_cat1, 0.4),
  ],
  ms: 7000,
  floor: false,
  props: [_bar],
  still: 5,
);

/// Bandiera al palo, vista di fronte: un braccio tira in alto, l'altro
/// spinge in basso, il corpo resta orizzontale.
const _humanFlag = Motion(
  'humanFlag',
  [
    (
      Pose(
        hip: Offset(0.44, -0.62),
        low: 180,
        neck: -112,
        arm: To(0.0, -0.87),
        arm2: To(0.0, -0.37),
        leg: Ang(0, 0),
        toe: 0,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.44, -0.63),
        low: 178,
        neck: -114,
        arm: To(0.0, -0.87),
        arm2: To(0.0, -0.37),
        leg: Ang(-4, -4),
        toe: -4,
      ),
      1,
    ),
  ],
  props: [Bar(0, 0, 0, -1.1, thick: true)],
  front: true,
  ms: 2600,
);

/// Elbow lever: gomiti nella pancia, corpo orizzontale in equilibrio sulle
/// mani.
const _elbowLever = Motion('elbowLever', [
  (
    Pose(
      hip: Offset(-0.147, -0.15),
      low: -8,
      neck: -4,
      arm: To(0.0, -0.01),
      leg: To(-0.58, -0.12),
      toe: 180,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.147, -0.155),
      low: -10,
      neck: -6,
      arm: To(0.0, -0.01),
      leg: To(-0.58, -0.16),
      toe: 180,
    ),
    1,
  ),
], ms: 2600);

/// Planche: dalla versione raccolta le gambe si distendono e il corpo resta
/// orizzontale sopra le mani.
const _planche = Motion(
  'planche',
  [
    (
      Pose(
        hip: Offset(-0.26, -0.285),
        low: -2,
        neck: 8,
        arm: To(0, -0.01),
        leg: Ang(40, 190),
      ),
      0.8,
    ),
    (
      Pose(
        hip: Offset(-0.26, -0.285),
        low: -2,
        neck: 6,
        arm: To(0, -0.01),
        leg: Ang(180, 180),
        toe: 180,
      ),
      0.6,
    ),
    (
      Pose(
        hip: Offset(-0.26, -0.285),
        low: -2,
        neck: 6,
        arm: To(0, -0.01),
        leg: Ang(180, 180),
        toe: 180,
      ),
      1.2,
    ),
  ],
  ms: 3200,
  still: 1,
);

// ---- Core ------------------------------------------------------------------

/// Compressione in pike: seduti a gambe tese, le gambe si staccano da terra.
const _pikeCompression = Motion('pikeCompression', [
  (
    Pose(
      hip: Offset(0, -0.06),
      low: -58,
      high: -50,
      neck: -40,
      arm: To(0.245, -0.01),
      leg: Ang(-1, -1),
      toe: -20,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.06),
      low: -54,
      high: -46,
      neck: -36,
      arm: To(0.25, -0.01),
      leg: Ang(-14, -14),
      toe: -30,
    ),
    1,
  ),
], ms: 1600);

/// Sollevamento gambe da sdraiati: gambe tese da terra alla verticale.
const _legRaise = Motion('legRaise', [
  (
    Pose(
      hip: Offset(0, -0.06),
      low: 180,
      neck: -176,
      arm: Ang(2, 2),
      leg: Ang(-4, -4),
      toe: -70,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.06),
      low: 180,
      neck: -176,
      arm: Ang(2, 2),
      leg: Ang(-92, -92),
      toe: -170,
    ),
    1,
  ),
], ms: 2200);

/// Sollevamento gambe tese alla sbarra, fino all'orizzontale.
const _hangingLegRaise = Motion(
  'hangingLegRaise',
  [
    (_hang, 1),
    (
      Pose(
        hip: Offset(0.03, -0.45),
        low: -98,
        arm: _hands,
        leg: Ang(-4, -4),
        toe: -40,
      ),
      1,
    ),
  ],
  ms: 2000,
  floor: false,
  props: [_bar],
);

/// Piedi alla sbarra: il bacino sale, le punte toccano la sbarra.
const _toesToBar = Motion(
  'toesToBar',
  [
    (_hang, 1),
    (
      Pose(
        hip: Offset(0.10, -0.58),
        low: -138,
        neck: -120,
        arm: _hands,
        leg: Ang(-76, -76),
        toe: -100,
      ),
      1,
    ),
  ],
  ms: 2000,
  floor: false,
  props: [_bar],
);

/// Bicicletta: spalle sollevate, mani dietro la testa, gambe alternate.
const _bicycleCrunch = Motion('bicycleCrunch', [
  (
    Pose(
      hip: Offset(0, -0.06),
      low: -172,
      high: -142,
      neck: -135,
      arm: To(-0.3, -0.24),
      leg: Ang(-102, 4),
      leg2: Ang(-12, -10),
      toe: 0,
      toe2: -10,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.06),
      low: -172,
      high: -142,
      neck: -135,
      arm: To(-0.3, -0.24),
      leg: Ang(-12, -10),
      leg2: Ang(-102, 4),
      toe: -10,
      toe2: 0,
    ),
    1,
  ),
], ms: 1400);

/// V-up: da sdraiati, braccia e gambe si chiudono a V sopra il bacino.
const _vUp = Motion('vUp', [
  (
    Pose(
      hip: Offset(0, -0.06),
      low: 180,
      neck: -178,
      arm: Ang(-177, -177),
      leg: Ang(-2, -2),
      toe: -70,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.06),
      low: -132,
      neck: -120,
      arm: Ang(-62, -58),
      leg: Ang(-48, -48),
      toe: -30,
    ),
    0.8,
  ),
], ms: 1600);

/// Flutter kick: spalle e gambe staccate da terra, gambe che si alternano.
const _flutterKick = Motion('flutterKick', [
  (
    Pose(
      hip: Offset(0, -0.06),
      low: -174,
      neck: -168,
      arm: Ang(8, 4),
      leg: Ang(-15, -15),
      leg2: Ang(-4, -4),
      toe: -5,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.06),
      low: -174,
      neck: -168,
      arm: Ang(8, 4),
      leg: Ang(-4, -4),
      leg2: Ang(-15, -15),
      toe: -5,
    ),
    1,
  ),
], ms: 700);

/// Sit-up: da sdraiati a busto eretto, ginocchia piegate.
const _sitUp = Motion('sitUp', [
  (
    Pose(
      hip: Offset(0, -0.06),
      low: 180,
      neck: -174,
      arm: Ang(-8, -4),
      leg: To(0.28, -0.03),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.06),
      low: -106,
      high: -98,
      neck: -104,
      arm: Ang(2, 4),
      leg: To(0.28, -0.03),
    ),
    1,
  ),
], ms: 2000);

/// Y raise da proni: braccia a Y che si sollevano da terra.
const _proneYRaise = Motion('proneYRaise', [
  (
    Pose(
      hip: Offset(0, -0.06),
      low: 0,
      neck: -4,
      arm: Ang(4, 4),
      leg: Ang(176, 176),
      toe: 175,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.06),
      low: -2,
      high: -6,
      neck: -6,
      arm: Ang(-14, -14),
      leg: Ang(176, 176),
      toe: 175,
    ),
    0.8,
  ),
  (
    Pose(
      hip: Offset(0, -0.06),
      low: -2,
      high: -6,
      neck: -6,
      arm: Ang(-14, -14),
      leg: Ang(176, 176),
      toe: 175,
    ),
    0.6,
  ),
], ms: 2600);

/// Wall slide, visto di fronte: schiena al muro, braccia da W a Y.
const _wallSlide = Motion(
  'wallSlide',
  [
    (
      Pose(
        hip: Offset(0, -0.47),
        arm: Ang(25, -85),
        arm2: Ang(155, -95),
        leg: To(0.06, -0.03),
        leg2: To(-0.06, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0, -0.47),
        arm: Ang(-58, -64),
        arm2: Ang(-122, -116),
        leg: To(0.06, -0.03),
        leg2: To(-0.06, -0.03),
      ),
      1,
    ),
  ],
  front: true,
  ms: 2600,
);

// ---- Gambe e glutei --------------------------------------------------------

/// Donkey kick: in quadrupedia, una gamba piegata spinge indietro e su.
const _donkeyKick = Motion('donkeyKick', [
  (
    Pose(
      hip: Offset(0, -0.27),
      low: 0,
      neck: 10,
      arm: To(0.30, -0.01),
      leg: Ang(90, 180),
      leg2: Ang(90, 180),
      toe: 180,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.27),
      low: 0,
      neck: 8,
      arm: To(0.30, -0.01),
      leg: Ang(-165, -92),
      leg2: Ang(90, 180),
      toe: 180,
    ),
    1,
  ),
], ms: 1600);

/// Slanci laterali da sdraiati su un fianco, visti di fronte.
const _sideLegRaise = Motion(
  'sideLegRaise',
  [
    (
      Pose(
        hip: Offset(0, -0.07),
        low: -10,
        neck: -15,
        arm: Ang(42, -80),
        arm2: Ang(-175, -170),
        leg: Ang(180, 180),
        leg2: Ang(181, 181),
        toe: 180,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0, -0.07),
        low: -10,
        neck: -15,
        arm: Ang(42, -80),
        arm2: Ang(-175, -170),
        leg: Ang(-145, -145),
        leg2: Ang(181, 181),
        toe: -145,
        toe2: 180,
      ),
      1,
    ),
  ],
  front: true,
  ms: 1800,
);

/// Hip thrust: spalle sulla panca, il bacino sale fino all'orizzontale.
const _hipThrust = Motion(
  'hipThrust',
  [
    (
      Pose(
        hip: Offset(-0.05, -0.12),
        low: -142,
        neck: -135,
        arm: Ang(-170, 175),
        leg: To(0.21, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0, -0.31),
        low: 180,
        neck: -158,
        arm: Ang(178, 180),
        leg: To(0.21, -0.03),
      ),
      1,
    ),
  ],
  props: [Block(-0.62, -0.28, -0.25, 0)],
  ms: 1800,
);

/// Sissy squat: sulle punte, ginocchia avanti, busto e cosce in linea.
const _sissySquat = Motion('sissySquat', [
  (
    Pose(
      hip: Offset(0, -0.50),
      low: -92,
      arm: Ang(2, 0),
      leg: To(0, -0.07),
      toe: 58,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0.02, -0.31),
      low: -122,
      neck: -105,
      arm: Ang(-4, -6),
      leg: To(0, -0.07),
      toe: 58,
    ),
    1,
  ),
], ms: 2400);

/// Stacco su una gamba: busto e gamba libera si allineano in orizzontale.
const _singleLegDeadlift = Motion('singleLegDeadlift', [
  (
    Pose(hip: Offset(0, -0.47), arm: _armsDown, leg: _feet, leg2: Ang(96, 96)),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.03, -0.45),
      low: -4,
      neck: 4,
      arm: Ang(90, 90),
      leg: _feet,
      leg2: Ang(178, 178),
    ),
    1,
  ),
], ms: 2600);

/// Good morning: mani dietro la testa, busto che si piega in avanti.
const _goodMorning = Motion('goodMorning', [
  (Pose(hip: Offset(0, -0.47), arm: To(-0.03, -0.84), leg: _feet), 1),
  (
    Pose(
      hip: Offset(-0.10, -0.45),
      low: -10,
      neck: -8,
      arm: To(0.25, -0.57),
      leg: _feet,
    ),
    1,
  ),
], ms: 2600);

// ---- Pliometria -------------------------------------------------------------

const _lungeL = Pose(
  hip: Offset(-0.02, -0.24),
  arm: Ang(60, 20),
  arm2: Ang(125, 105),
  leg: To(0.25, -0.03),
  leg2: To(-0.30, -0.06),
  toe2: 60,
);

const _lungeR = Pose(
  hip: Offset(-0.02, -0.24),
  arm: Ang(125, 105),
  arm2: Ang(60, 20),
  leg: To(-0.30, -0.06),
  leg2: To(0.25, -0.03),
  toe: 60,
);

/// Affondi saltati: si salta e si cambia gamba in aria.
const _jumpLunge = Motion('jumpLunge', [
  (_lungeL, 0.8),
  (
    Pose(
      hip: Offset(0, -0.58),
      arm: Ang(90, 70),
      leg: To(0.06, -0.16),
      leg2: To(-0.06, -0.16),
    ),
    0.5,
  ),
  (_lungeR, 0.8),
  (
    Pose(
      hip: Offset(0, -0.58),
      arm: Ang(90, 70),
      leg: To(-0.06, -0.16),
      leg2: To(0.06, -0.16),
    ),
    0.5,
  ),
], ms: 1600);

/// Salto in lungo: carica con le braccia indietro, volo, atterraggio.
const _broadJump = Motion(
  'broadJump',
  [
    (
      Pose(hip: Offset(-0.30, -0.47), arm: _armsDown, leg: To(-0.30, -0.03)),
      0.5,
    ),
    (
      Pose(
        hip: Offset(-0.47, -0.24),
        low: -40,
        high: -48,
        arm: Ang(150, 145),
        leg: To(-0.30, -0.03),
      ),
      0.5,
    ),
    (
      Pose(
        hip: Offset(-0.02, -0.56),
        low: -62,
        neck: -50,
        arm: Ang(-30, -40),
        leg: To(0.14, -0.30),
        toe: 20,
      ),
      0.5,
    ),
    (
      Pose(
        hip: Offset(0.14, -0.24),
        low: -50,
        high: -58,
        arm: Ang(10, 0),
        leg: To(0.30, -0.03),
      ),
      0.6,
    ),
    (Pose(hip: Offset(0.30, -0.47), arm: _armsDown, leg: To(0.30, -0.03)), 0.4),
    (Pose(hip: Offset(0.30, -0.47), arm: _armsDown, leg: To(0.30, -0.03)), 0),
  ],
  ms: 2200,
  still: 2,
);

/// Salto sul box: carica, salto e atterraggio raccolto sul rialzo.
const _boxJump = Motion(
  'boxJump',
  [
    (
      Pose(hip: Offset(-0.12, -0.47), arm: _armsDown, leg: To(-0.12, -0.03)),
      0.5,
    ),
    (
      Pose(
        hip: Offset(-0.28, -0.24),
        low: -45,
        high: -52,
        arm: Ang(150, 145),
        leg: To(-0.12, -0.03),
      ),
      0.5,
    ),
    (
      Pose(
        hip: Offset(0.16, -0.68),
        low: -70,
        neck: -60,
        arm: Ang(-30, -40),
        leg: To(0.32, -0.40),
        toe: 30,
      ),
      0.5,
    ),
    (
      Pose(
        hip: Offset(0.28, -0.56),
        low: -50,
        high: -58,
        arm: Ang(10, 0),
        leg: To(0.44, -0.33),
      ),
      0.6,
    ),
    (Pose(hip: Offset(0.44, -0.77), arm: _armsDown, leg: To(0.44, -0.33)), 0.4),
    (Pose(hip: Offset(0.44, -0.77), arm: _armsDown, leg: To(0.44, -0.33)), 0),
  ],
  props: [Block(0.26, -0.30, 0.62, 0)],
  ms: 2400,
  still: 2,
);

/// Tibiali: schiena al muro, talloni a terra, le punte salgono.
const _tibialisRaise = Motion(
  'tibialisRaise',
  [
    (
      Pose(
        hip: Offset(0.158, -0.46),
        low: -102,
        neck: -96,
        arm: Ang(98, 96),
        leg: To(0.25, -0.03),
        toe: -2,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.158, -0.46),
        low: -102,
        neck: -96,
        arm: Ang(98, 96),
        leg: To(0.25, -0.03),
        toe: -42,
      ),
      1,
    ),
  ],
  props: [Bar(0.0, 0, 0.0, -1.0, thick: true)],
  ms: 1200,
);

// ---- Total body ------------------------------------------------------------

const _inchFold = Pose(
  hip: Offset(-0.06, -0.46),
  low: 25,
  high: 60,
  neck: 75,
  arm: To(0.22, -0.01),
  leg: _feet,
  toe: 10,
);

const _inchPike = Pose(
  hip: Offset(0.20, -0.40),
  low: 38,
  neck: 70,
  arm: To(0.60, -0.01),
  leg: _feet,
  toe: 35,
);

/// Inchworm: piegati in avanti, le mani camminano fino al plank e tornano.
const _inchworm = Motion(
  'inchworm',
  [
    (Pose(hip: Offset(0, -0.47), arm: _armsDown, leg: _feet, toe: 10), 0.8),
    (_inchFold, 1),
    (_inchPike, 1),
    (
      Pose(
        hip: Offset(0.409, -0.193),
        low: -21.7,
        neck: -26,
        arm: To(0.68, -0.01),
        leg: _feet,
        toe: 35,
      ),
      0.8,
    ),
    (_inchPike, 1),
    (_inchFold, 1),
  ],
  ms: 6000,
  still: 3,
);

/// Plank inverso: mani dietro, corpo teso a pancia in su.
const _reversePlank = Motion('reversePlank', [
  (
    Pose(
      hip: Offset(0.20, -0.07),
      low: -133.6,
      neck: -110,
      arm: To(-0.05, -0.01),
      leg: To(0.63, -0.03),
      toe: -20,
    ),
    0.6,
  ),
  (
    Pose(
      hip: Offset(0.219, -0.193),
      low: -158.3,
      neck: -140,
      arm: To(-0.05, -0.01),
      leg: To(0.63, -0.03),
      toe: -20,
    ),
    0.6,
  ),
  (
    Pose(
      hip: Offset(0.219, -0.193),
      low: -158.3,
      neck: -140,
      arm: To(-0.05, -0.01),
      leg: To(0.63, -0.03),
      toe: -20,
    ),
    1.4,
  ),
], ms: 3200);

/// Bear plank: quadrupedia con le ginocchia sospese appena sopra il
/// pavimento.
const _bearPlank = Motion('bearPlank', [
  (
    Pose(
      hip: Offset(0, -0.27),
      low: 0,
      neck: 10,
      arm: To(0.30, -0.01),
      leg: To(-0.20, -0.06),
      toe: 75,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.293),
      low: -1,
      neck: 8,
      arm: To(0.30, -0.01),
      leg: To(-0.20, -0.06),
      toe: 75,
    ),
    1,
  ),
], ms: 2400);

const _wallWalkB = Pose(
  hip: Offset(0.332, -0.336),
  low: 11,
  neck: 22,
  arm: To(0.62, -0.01),
  leg: To(-0.10, -0.42),
  toe: 160,
);

const _wallWalkC = Pose(
  hip: Offset(0.237, -0.467),
  low: 40,
  neck: 55,
  arm: To(0.46, -0.01),
  leg: To(-0.10, -0.75),
  toe: 170,
);

/// Wall walk: dal plank i piedi salgono il muro e le mani si avvicinano,
/// fino alla verticale a petto al muro.
const _wallWalk = Motion(
  'wallWalk',
  [
    (
      Pose(
        hip: Offset(0.309, -0.193),
        low: -21.7,
        neck: -26,
        arm: To(0.58, -0.01),
        leg: To(-0.10, -0.03),
        toe: 35,
      ),
      1,
    ),
    (_wallWalkB, 1),
    (_wallWalkC, 1),
    (
      Pose(
        hip: Offset(-0.027, -0.586),
        low: 80.4,
        neck: 84,
        arm: To(0.03, -0.01),
        leg: To(-0.10, -1.0),
        toe: 178,
      ),
      1.4,
    ),
    (_wallWalkC, 1),
    (_wallWalkB, 1),
  ],
  props: [Bar(-0.14, 0, -0.14, -1.12, thick: true)],
  ms: 6400,
  still: 3,
);

/// Push-up battendo le mani: spinta esplosiva, le mani si staccano.
const _clapPushUp = Motion('clapPushUp', [
  (
    Pose(
      hip: Offset(0.439, -0.07),
      low: -3.9,
      neck: -8,
      arm: To(0.68, -0.01),
      leg: _feet,
      toe: 35,
    ),
    0.4,
  ),
  (
    Pose(
      hip: Offset(0.38, -0.24),
      low: -30,
      neck: -34,
      arm: To(0.70, -0.22),
      leg: _feet,
      toe: 35,
    ),
    0.35,
  ),
  (
    Pose(
      hip: Offset(0.409, -0.193),
      low: -21.7,
      neck: -26,
      arm: To(0.68, -0.01),
      leg: _feet,
      toe: 35,
    ),
    0.5,
  ),
], ms: 1200);

// ---- Mobilità e allungamenti ----------------------------------------------

/// Piccione: gamba davanti piegata, gamba dietro tesa, busto che scende.
const _pigeonStretch = Motion('pigeonStretch', [
  (
    Pose(
      hip: Offset(0, -0.12),
      low: -80,
      neck: -84,
      arm: Ang(84, 86),
      leg: Ang(24, 180),
      leg2: Ang(168, 168),
      toe: 180,
      toe2: 180,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.12),
      low: -15,
      high: -5,
      neck: 5,
      arm: Ang(88, 0),
      leg: Ang(24, 180),
      leg2: Ang(168, 168),
      toe: 180,
      toe2: 180,
    ),
    1.4,
  ),
], ms: 4000);

/// Allungamento da seduti: busto avanti verso le punte dei piedi.
const _seatedFold = Motion('seatedFold', [
  (
    Pose(
      hip: Offset(0, -0.06),
      low: -86,
      high: -90,
      arm: Ang(-80, -84),
      leg: To(0.44, -0.03),
      toe: -70,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.06),
      low: -30,
      high: -8,
      neck: 6,
      arm: Ang(18, 22),
      leg: To(0.44, -0.03),
      toe: -70,
    ),
    1.4,
  ),
], ms: 4000);

/// Shadow boxing: in guardia, colpi dritti alternati.
const _shadowBoxing = Motion('shadowBoxing', [
  (
    Pose(
      hip: Offset(0, -0.45),
      low: -86,
      arm: To(0.11, -0.79),
      arm2: To(0.08, -0.81),
      leg: To(0.12, -0.03),
      leg2: To(-0.14, -0.03),
    ),
    0.7,
  ),
  (
    Pose(
      hip: Offset(0.01, -0.44),
      low: -84,
      arm: To(0.30, -0.76),
      arm2: To(0.08, -0.81),
      leg: To(0.12, -0.03),
      leg2: To(-0.14, -0.03),
    ),
    0.5,
  ),
  (
    Pose(
      hip: Offset(0, -0.45),
      low: -86,
      arm: To(0.11, -0.79),
      arm2: To(0.08, -0.81),
      leg: To(0.12, -0.03),
      leg2: To(-0.14, -0.03),
    ),
    0.7,
  ),
  (
    Pose(
      hip: Offset(0.03, -0.44),
      low: -80,
      arm: To(0.11, -0.79),
      arm2: To(0.33, -0.76),
      leg: To(0.12, -0.03),
      leg2: To(-0.14, -0.03),
      toe2: 40,
    ),
    0.5,
  ),
], ms: 1300);

/// Allungamento dei femorali in piedi: tallone avanti, busto che scende.
const _hamstringStretch = Motion('hamstringStretch', [
  (
    Pose(
      hip: Offset(0, -0.34),
      low: -88,
      arm: Ang(80, 72),
      leg: To(0.30, -0.03),
      leg2: To(-0.12, -0.03),
      toe: -60,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.34),
      low: -25,
      high: -15,
      neck: 0,
      arm: Ang(100, 92),
      leg: To(0.30, -0.03),
      leg2: To(-0.12, -0.03),
      toe: -60,
    ),
    1.4,
  ),
], ms: 4000);

/// Movimenti dei nuovi esercizi (campo `figure`).
const moreMotions = <Motion>[
  _curl,
  _wristCurl,
  _gripHold,
  _tricepsExtension,
  _vSit,
  _tuckBackLever,
  _backLever,
  _germanHang,
  _skinTheCat,
  _humanFlag,
  _elbowLever,
  _planche,
  _pikeCompression,
  _legRaise,
  _hangingLegRaise,
  _toesToBar,
  _bicycleCrunch,
  _vUp,
  _flutterKick,
  _sitUp,
  _proneYRaise,
  _wallSlide,
  _donkeyKick,
  _sideLegRaise,
  _hipThrust,
  _sissySquat,
  _singleLegDeadlift,
  _goodMorning,
  _jumpLunge,
  _broadJump,
  _boxJump,
  _tibialisRaise,
  _inchworm,
  _reversePlank,
  _bearPlank,
  _wallWalk,
  _clapPushUp,
  _pigeonStretch,
  _seatedFold,
  _shadowBoxing,
  _hamstringStretch,
];
