// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:ui';

import '../../domain/exercise.dart';
import 'motions_more.dart';
import 'skeleton.dart';

// Le pose chiave di ogni movimento. Pavimento a y = 0, caviglia a -0.03,
// mani appoggiate a -0.01; la figurina guarda a destra. In piedi il bacino
// è a -0.47, le spalle a -0.76; braccia e gambe sono lunghe 0.29 e 0.44.
//
// Il petto guarda sempre dalla parte di `low + 90°`: a pancia in giù la
// testa è a destra, sdraiati sulla schiena (ponte, crunch, hollow) la testa
// è a sinistra, a testa in giù (verticale) il petto guarda a sinistra. Così
// gomiti e ginocchia si piegano dal verso giusto da soli.

const _feet = To(0, -0.03);
const _armsDown = Ang(94, 82);
const _armsForward = Ang(0, -4);

// ---- Spinta ----------------------------------------------------------------

const wallPushUp = Motion(
  'wallPushUp',
  [
    (
      Pose(
        hip: Offset(0.184, -0.429),
        low: -65.2,
        arm: To(0.585, -0.72),
        leg: _feet,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.25, -0.392),
        low: -55.4,
        neck: -50,
        arm: To(0.585, -0.72),
        leg: _feet,
      ),
      1,
    ),
  ],
  props: [Bar(0.625, 0, 0.625, -1.05, thick: true)],
);

const inclinePushUp = Motion(
  'inclinePushUp',
  [
    (
      Pose(
        hip: Offset(0.333, -0.318),
        low: -40.8,
        neck: -38,
        arm: To(0.73, -0.295),
        leg: _feet,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.381, -0.25),
        low: -30,
        neck: -24,
        arm: To(0.73, -0.295),
        leg: _feet,
      ),
      1,
    ),
  ],
  props: [Block(0.60, -0.28, 0.86, 0)],
);

const kneePushUp = Motion('kneePushUp', [
  (
    Pose(
      hip: Offset(0.189, -0.142),
      low: -30.7,
      neck: -28,
      arm: To(0.44, -0.01),
      leg: To(-0.143, -0.197),
      toe: 200,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0.217, -0.069),
      low: -10.2,
      neck: -10,
      arm: To(0.44, -0.01),
      leg: To(-0.06, -0.24),
      toe: 220,
    ),
    1,
  ),
]);

const pushUp = Motion('pushUp', [
  (
    Pose(
      hip: Offset(0.411, -0.187),
      low: -20.9,
      neck: -22,
      arm: To(0.69, -0.01),
      leg: _feet,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0.437, -0.084),
      low: -7.1,
      neck: -10,
      arm: To(0.69, -0.01),
      leg: _feet,
    ),
    1,
  ),
]);

/// Dal cane a testa in giù, tuffo in avanti radente, fino al cane a testa
/// in su; poi di nuovo indietro.
const hinduPushUp = Motion(
  'hinduPushUp',
  [
    (
      Pose(
        hip: Offset(0.259, -0.379),
        low: 40,
        neck: 100,
        arm: To(0.70, -0.01),
        leg: _feet,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.42, -0.155),
        low: 10,
        high: 4,
        neck: -10,
        arm: To(0.70, -0.01),
        leg: _feet,
      ),
      0.8,
    ),
    (
      Pose(
        hip: Offset(0.43, -0.10),
        low: -28,
        high: -45,
        neck: -62,
        arm: To(0.70, -0.01),
        leg: _feet,
      ),
      0.6,
    ),
    (
      Pose(
        hip: Offset(0.43, -0.10),
        low: -28,
        high: -45,
        neck: -62,
        arm: To(0.70, -0.01),
        leg: _feet,
      ),
      1,
    ),
  ],
  ms: 3000,
  still: 2,
);

const pikePushUp = Motion('pikePushUp', [
  (
    Pose(
      hip: Offset(0.126, -0.446),
      low: 49.4,
      neck: 100,
      arm: To(0.50, -0.01),
      leg: _feet,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0.22, -0.38),
      low: 39.3,
      neck: 95,
      arm: To(0.50, -0.01),
      leg: _feet,
    ),
    1,
  ),
]);

const elevatedPike = Motion(
  'elevatedPike',
  [
    (
      Pose(
        hip: Offset(0.346, -0.574),
        low: 78.6,
        neck: 110,
        arm: To(0.46, -0.01),
        leg: To(0, -0.31),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.38, -0.476),
        low: 72,
        neck: 100,
        arm: To(0.46, -0.01),
        leg: To(0, -0.31),
      ),
      1,
    ),
  ],
  props: [Block(-0.14, -0.28, 0.10, 0)],
);

// A testa in giù il petto guarda a sinistra, verso il muro.
const wallHandstandPushUp = Motion(
  'wallHspu',
  [
    (
      Pose(
        hip: Offset(0.0, -0.575),
        low: 92,
        neck: 100,
        arm: To(0.03, -0.01),
        leg: To(-0.09, -1.0),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.005, -0.47),
        low: 88,
        neck: 100,
        arm: To(0.03, -0.01),
        leg: To(-0.09, -0.90),
      ),
      1,
    ),
  ],
  props: [Bar(-0.15, 0, -0.15, -1.2, thick: true)],
  ms: 2200,
);

const wallHandstand = Motion(
  'wallHandstand',
  [
    (
      Pose(
        hip: Offset(0.0, -0.575),
        low: 92,
        neck: 100,
        arm: To(0.03, -0.01),
        leg: To(-0.09, -1.0),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.004, -0.575),
        low: 91,
        neck: 102,
        arm: To(0.03, -0.01),
        leg: To(-0.088, -1.0),
      ),
      1,
    ),
  ],
  props: [Bar(-0.15, 0, -0.15, -1.2, thick: true)],
  ms: 2600,
);

const handstand = Motion('handstand', [
  (
    Pose(
      hip: Offset(0.012, -0.575),
      low: 89,
      neck: 104,
      arm: To(0.0, -0.01),
      leg: To(0.035, -1.01),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.012, -0.575),
      low: 91,
      neck: 104,
      arm: To(0.0, -0.01),
      leg: To(-0.02, -1.01),
    ),
    1,
  ),
], ms: 2600);

/// Corvo: ginocchia appoggiate dietro le braccia, piedi che si staccano.
const crow = Motion('crow', [
  (
    Pose(
      hip: Offset(-0.14, -0.28),
      low: 15,
      neck: 20,
      arm: To(0.06, -0.01),
      leg: To(-0.10, -0.03),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.16, -0.36),
      low: 22.9,
      neck: 10,
      arm: To(0.06, -0.01),
      leg: To(-0.215, -0.26),
      toe: 170,
    ),
    1.4,
  ),
], ms: 2400);

/// Planche raccolta: braccia tese, spalle oltre le mani, ginocchia al petto.
const tuckPlanche = Motion('tuckPlanche', [
  (
    Pose(
      hip: Offset(-0.16, -0.24),
      low: -6,
      neck: -4,
      arm: To(0.05, -0.01),
      leg: To(-0.14, -0.16),
      toe: 180,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.19, -0.27),
      low: -3,
      neck: 0,
      arm: To(0.05, -0.01),
      leg: To(-0.17, -0.19),
      toe: 180,
    ),
    1.4,
  ),
], ms: 2400);

// ---- Tirata ----------------------------------------------------------------

const _bar = Bar(-0.15, -1.0, 0.19, -1.0, thick: true);
const _hands = To(0.03, -1.0);

const _hang = Pose(
  hip: Offset(-0.01, -0.425),
  low: -88,
  arm: _hands,
  leg: To(0.01, 0.01),
);

const _chinOver = Pose(
  hip: Offset(-0.06, -0.61),
  low: -84,
  high: -88,
  neck: -78,
  arm: _hands,
  leg: To(0.0, -0.21),
);

const pullUp = Motion(
  'pullUp',
  [(_hang, 1), (_chinOver, 1)],
  floor: false,
  props: [_bar],
);

const negativePullUp = Motion(
  'negativePullUp',
  [(_chinOver, 0.6), (_chinOver, 2.4), (_hang, 0.8)],
  ms: 3600,
  floor: false,
  props: [_bar],
);

const lSitPullUp = Motion(
  'lSitPullUp',
  [
    (
      Pose(
        hip: Offset(-0.03, -0.425),
        low: -86,
        arm: _hands,
        leg: To(0.40, -0.44),
        toe: -20,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.06, -0.64),
        low: -82,
        high: -88,
        neck: -78,
        arm: _hands,
        leg: To(0.37, -0.68),
        toe: -20,
      ),
      1,
    ),
  ],
  floor: false,
  props: [_bar],
);

const australianRow = Motion(
  'row',
  [
    (
      Pose(
        hip: Offset(0.422, -0.155),
        low: -16.5,
        neck: -14,
        arm: To(0.72, -0.52),
        leg: _feet,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.369, -0.27),
        low: -33,
        neck: -30,
        arm: To(0.72, -0.52),
        leg: _feet,
      ),
      1,
    ),
  ],
  props: [Bar(0.62, -0.52, 0.84, -0.52, thick: true)],
);

/// Rematore sotto il tavolo: come le australiane, al bordo di un tavolo.
const tableRow = Motion(
  'tableRow',
  [
    (
      Pose(
        hip: Offset(0.422, -0.155),
        low: -16.5,
        neck: -14,
        arm: To(0.72, -0.53),
        leg: _feet,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.369, -0.27),
        low: -33,
        neck: -30,
        arm: To(0.72, -0.53),
        leg: _feet,
      ),
      1,
    ),
  ],
  props: [Block(0.70, -0.57, 1.20, -0.52), Bar(1.14, -0.52, 1.14, 0)],
);

// Dip: bacino sotto le mani, ginocchia piegate e piedi dietro.
const _dipTop = Pose(
  hip: Offset(-0.03, -0.62),
  low: -86,
  high: -82,
  arm: To(0.03, -0.62),
  leg: To(-0.12, -0.24),
  toe: 120,
);

const _dipBottom = Pose(
  hip: Offset(-0.08, -0.47),
  low: -68,
  high: -58,
  neck: -62,
  arm: To(0.03, -0.62),
  leg: To(-0.20, -0.12),
  toe: 130,
);

/// Dip tra due sedie: le mani sugli schienali.
const chairDip = Motion(
  'chairDip',
  [(_dipTop, 1), (_dipBottom, 1)],
  props: [
    Bar(0.03, -0.6, 0.03, 0),
    Block(0.03, -0.32, 0.30, -0.28),
    Bar(0.28, -0.28, 0.28, 0),
  ],
);

const deadHang = Motion(
  'deadHang',
  [
    (_hang, 1),
    (
      Pose(hip: Offset(0.0, -0.425), low: -90, arm: _hands, leg: To(0.0, 0.01)),
      1,
    ),
  ],
  ms: 3000,
  floor: false,
  props: [_bar],
);

const scapPull = Motion(
  'scapPull',
  [
    (_hang, 1),
    (
      Pose(
        hip: Offset(-0.02, -0.47),
        low: -86,
        high: -84,
        neck: -82,
        arm: _hands,
        leg: To(0.0, -0.03),
      ),
      1,
    ),
  ],
  floor: false,
  props: [_bar],
);

// Front lever: corpo orizzontale a pancia in su, piedi verso destra, spalle
// sotto la sbarra e braccia tese.
const _lever = Pose(
  hip: Offset(0.17, -0.76),
  low: 180,
  neck: 184,
  arm: _hands,
  leg: To(0.605, -0.76),
  toe: -10,
);

const frontLever = Motion(
  'frontLever',
  [(_hang, 0.8), (_lever, 0.6), (_lever, 1.2)],
  ms: 3200,
  floor: false,
  props: [_bar],
  still: 1,
);

const tuckFrontLever = Motion(
  'tuckFrontLever',
  [
    (_hang, 0.8),
    (
      Pose(
        hip: Offset(0.14, -0.76),
        low: 182,
        neck: 186,
        arm: _hands,
        leg: To(0.22, -0.89),
        toe: -60,
      ),
      0.6,
    ),
    (
      Pose(
        hip: Offset(0.14, -0.76),
        low: 182,
        neck: 186,
        arm: _hands,
        leg: To(0.22, -0.89),
        toe: -60,
      ),
      1.2,
    ),
  ],
  ms: 3200,
  floor: false,
  props: [_bar],
);

const muscleUp = Motion(
  'muscleUp',
  [
    (_hang, 1),
    (_chinOver, 0.6),
    (
      Pose(
        hip: Offset(-0.03, -0.83),
        low: -68,
        high: -40,
        neck: -30,
        arm: _hands,
        leg: To(-0.14, -0.40),
      ),
      0.6,
    ),
    (
      Pose(
        hip: Offset(-0.01, -0.99),
        low: -88,
        arm: To(0.03, -1.0),
        leg: To(-0.03, -0.55),
      ),
      1,
    ),
  ],
  ms: 3000,
  floor: false,
  props: [_bar],
  still: 3,
);

// ---- Dip -------------------------------------------------------------------

const dip = Motion(
  'dip',
  [(_dipTop, 1), (_dipBottom, 1)],
  props: [
    Bar(-0.12, -0.62, 0.20, -0.62, thick: true),
    Bar(0.16, -0.62, 0.16, 0),
  ],
);

/// Dip alla panca: mani dietro sul bordo, gambe avanti, il bacino scende.
const benchDip = Motion(
  'benchDip',
  [
    (
      Pose(
        hip: Offset(-0.07, -0.29),
        low: -95,
        neck: -88,
        arm: To(-0.13, -0.295),
        leg: To(0.25, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.06, -0.15),
        low: -94,
        neck: -84,
        arm: To(-0.13, -0.295),
        leg: To(0.25, -0.03),
      ),
      1,
    ),
  ],
  props: [Block(-0.36, -0.28, -0.11, 0)],
);

/// Dip sulla sbarra dritta: sbarra davanti ai fianchi, busto inclinato.
const barDip = Motion(
  'barDip',
  [
    (
      Pose(
        hip: Offset(-0.04, -0.60),
        low: -82,
        high: -78,
        arm: To(0.04, -0.62),
        leg: To(-0.05, -0.18),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.14, -0.50),
        low: -45,
        high: -38,
        neck: -36,
        arm: To(0.04, -0.62),
        leg: To(-0.19, -0.07),
      ),
      1,
    ),
  ],
  props: [Bar(-0.12, -0.62, 0.22, -0.62, thick: true)],
);

// ---- Gambe -----------------------------------------------------------------

const _stand = Pose(hip: Offset(0, -0.47), arm: _armsDown, leg: _feet);

const squat = Motion('squat', [
  (_stand, 1),
  (
    Pose(
      hip: Offset(-0.18, -0.21),
      low: -58,
      high: -64,
      neck: -60,
      arm: _armsForward,
      leg: _feet,
    ),
    1,
  ),
]);

const deepSquat = Motion('deepSquat', [
  (
    Pose(
      hip: Offset(-0.10, -0.13),
      low: -72,
      high: -80,
      arm: Ang(55, -50),
      leg: To(0.02, -0.03),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.10, -0.15),
      low: -76,
      high: -84,
      arm: Ang(58, -48),
      leg: To(0.02, -0.03),
    ),
    1,
  ),
], ms: 3200);

const squatJump = Motion('squatJump', [
  (
    Pose(
      hip: Offset(-0.18, -0.21),
      low: -52,
      high: -58,
      arm: Ang(130, 115),
      leg: _feet,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.60),
      low: -90,
      arm: Ang(-78, -84),
      leg: To(-0.01, -0.165),
      toe: 75,
    ),
    0.7,
  ),
  (
    Pose(hip: Offset(-0.06, -0.40), low: -76, arm: Ang(40, 20), leg: _feet),
    0.6,
  ),
], ms: 1500);

const lunge = Motion('lunge', [
  (
    Pose(
      hip: Offset(-0.03, -0.39),
      arm: _armsDown,
      leg: To(0.22, -0.03),
      leg2: To(-0.29, -0.07),
      toe2: 45,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.04, -0.24),
      arm: _armsDown,
      leg: To(0.22, -0.03),
      leg2: To(-0.33, -0.07),
      toe2: 45,
    ),
    1,
  ),
]);

const bulgarian = Motion(
  'bulgarian',
  [
    (
      Pose(
        hip: Offset(-0.03, -0.42),
        low: -86,
        arm: _armsDown,
        leg: To(0.14, -0.03),
        leg2: To(-0.38, -0.29),
        toe2: 175,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.08, -0.22),
        low: -76,
        arm: _armsDown,
        leg: To(0.14, -0.03),
        leg2: To(-0.38, -0.29),
        toe2: 175,
      ),
      1,
    ),
  ],
  props: [Block(-0.56, -0.26, -0.33, 0)],
);

const stepUp = Motion(
  'stepUp',
  [
    (
      Pose(
        hip: Offset(0, -0.46),
        arm: _armsDown,
        leg: To(0.24, -0.28),
        leg2: To(-0.02, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.22, -0.71),
        arm: _armsDown,
        leg: To(0.24, -0.28),
        leg2: To(0.30, -0.50),
        toe2: 60,
      ),
      1,
    ),
  ],
  props: [Block(0.10, -0.25, 0.44, 0)],
  ms: 2000,
);

const pistol = Motion('pistol', [
  (
    Pose(
      hip: Offset(-0.01, -0.47),
      arm: _armsForward,
      leg: _feet,
      leg2: To(0.25, -0.18),
      toe2: -50,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.16, -0.16),
      low: -54,
      high: -62,
      arm: _armsForward,
      leg: _feet,
      leg2: To(0.27, -0.13),
      toe2: -70,
    ),
    1,
  ),
], ms: 2400);

const assistedPistol = Motion(
  'assistedPistol',
  [
    (
      Pose(
        hip: Offset(-0.01, -0.47),
        arm: To(0.25, -0.62),
        leg: _feet,
        leg2: To(0.25, -0.18),
        toe2: -50,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.16, -0.16),
        low: -54,
        high: -62,
        arm: To(0.25, -0.45),
        leg: _feet,
        leg2: To(0.27, -0.13),
        toe2: -70,
      ),
      1,
    ),
  ],
  props: [Bar(0.29, 0, 0.29, -0.78, thick: true)],
  ms: 2400,
);

/// Squat del gambero: il ginocchio dietro scende a sfiorare il pavimento.
const shrimp = Motion('shrimp', [
  (
    Pose(
      hip: Offset(0, -0.47),
      low: -86,
      arm: _armsForward,
      arm2: Ang(110, 100),
      leg: _feet,
      leg2: To(-0.22, -0.32),
      toe2: 180,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.10, -0.22),
      low: -58,
      high: -64,
      arm: _armsForward,
      arm2: Ang(120, 105),
      leg: _feet,
      leg2: To(-0.36, -0.13),
      toe2: 180,
    ),
    1,
  ),
], ms: 2400);

const calfRaise = Motion('calfRaise', [
  (_stand, 1),
  (Pose(hip: Offset(0, -0.53), arm: _armsDown, leg: To(0, -0.09), toe: 60), 1),
], ms: 1400);

const wallSit = Motion(
  'wallSit',
  [
    (Pose(hip: Offset(-0.14, -0.25), arm: Ang(60, 8), leg: To(0.08, -0.03)), 1),
    (
      Pose(hip: Offset(-0.14, -0.255), arm: Ang(62, 6), leg: To(0.08, -0.03)),
      1,
    ),
  ],
  props: [Bar(-0.20, 0, -0.20, -0.95, thick: true)],
  ms: 3000,
);

/// Nordic: in ginocchio con le caviglie bloccate, il corpo dritto cade in
/// avanti piano e le mani frenano a terra.
const nordic = Motion(
  'nordic',
  [
    (
      Pose(
        hip: Offset(0.0, -0.25),
        arm: To(0.10, -0.36),
        leg: To(-0.21, -0.04),
        toe: 180,
      ),
      0.6,
    ),
    (
      Pose(
        hip: Offset(0.151, -0.199),
        low: -50,
        arm: To(0.36, -0.30),
        leg: To(-0.21, -0.04),
        toe: 180,
      ),
      2,
    ),
    (
      Pose(
        hip: Offset(0.217, -0.105),
        low: -20,
        neck: -24,
        arm: To(0.58, -0.01),
        leg: To(-0.21, -0.04),
        toe: 180,
      ),
      0.5,
    ),
    (
      Pose(
        hip: Offset(0.151, -0.199),
        low: -50,
        arm: To(0.36, -0.30),
        leg: To(-0.21, -0.04),
        toe: 180,
      ),
      0.5,
    ),
  ],
  ms: 3600,
  props: [Block(-0.30, -0.12, -0.14, -0.08)],
);

// Sdraiati sulla schiena: testa a sinistra, piedi a destra.
const gluteBridge = Motion('gluteBridge', [
  (
    Pose(
      hip: Offset(0, -0.065),
      low: 180,
      neck: 192,
      arm: Ang(-2, -2),
      leg: To(0.28, -0.03),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.03, -0.21),
      low: 146.3,
      neck: 196,
      arm: Ang(-2, -2),
      leg: To(0.28, -0.03),
    ),
    1,
  ),
]);

// ---- Core ------------------------------------------------------------------

/// Plank sugli avambracci.
const plank = Motion('plank', [
  (
    Pose(
      hip: Offset(0.432, -0.114),
      low: -11.1,
      neck: -12,
      arm: To(0.856, -0.02),
      leg: _feet,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0.432, -0.125),
      low: -10.2,
      neck: -14,
      arm: To(0.856, -0.02),
      leg: _feet,
    ),
    1,
  ),
], ms: 2800);

/// Plank laterale vista di fronte: un braccio a terra, l'altro in alto.
const sidePlank = Motion(
  'sidePlank',
  [
    (
      Pose(
        hip: Offset(0.411, -0.187),
        low: -20.9,
        arm: To(0.682, -0.01),
        arm2: Ang(-95, -95),
        leg: _feet,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.42, -0.13),
        low: -14,
        neck: -12,
        arm: To(0.682, -0.01),
        arm2: Ang(-95, -95),
        leg: _feet,
      ),
      1,
    ),
  ],
  front: true,
  ms: 2600,
);

const _plankHigh = Pose(
  hip: Offset(0.411, -0.187),
  low: -20.9,
  neck: -22,
  arm: To(0.69, -0.01),
  arm2: To(0.67, -0.01),
  leg: _feet,
);

const shoulderTaps = Motion('shoulderTaps', [
  (_plankHigh, 0.5),
  (
    Pose(
      hip: Offset(0.411, -0.187),
      low: -20.9,
      neck: -22,
      arm: To(0.66, -0.23),
      arm2: To(0.67, -0.01),
      leg: _feet,
    ),
    0.5,
  ),
  (_plankHigh, 0.5),
  (
    Pose(
      hip: Offset(0.411, -0.187),
      low: -20.9,
      neck: -22,
      arm: To(0.69, -0.01),
      arm2: To(0.66, -0.23),
      leg: _feet,
    ),
    0.5,
  ),
], ms: 1600);

// Hollow body: sulla schiena, spalle e gambe staccate, braccia oltre la
// testa.
const hollow = Motion('hollow', [
  (
    Pose(
      hip: Offset(0, -0.05),
      low: 192,
      high: 200,
      neck: 198,
      arm: Ang(196, 196),
      leg: To(0.43, -0.13),
      toe: -10,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.05),
      low: 188,
      high: 196,
      neck: 194,
      arm: Ang(192, 192),
      leg: To(0.43, -0.10),
      toe: -6,
    ),
    1,
  ),
], ms: 2400);

const _parallettes = [
  Bar(-0.06, -0.12, 0.12, -0.12, thick: true),
  Bar(0.03, -0.12, 0.03, 0),
];

const lSit = Motion(
  'lSit',
  [
    (
      Pose(
        hip: Offset(-0.04, -0.13),
        low: -86,
        arm: To(0.03, -0.135),
        leg: To(0.395, -0.15),
        toe: -30,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.04, -0.14),
        low: -87,
        arm: To(0.03, -0.135),
        leg: To(0.39, -0.20),
        toe: -40,
      ),
      1,
    ),
  ],
  props: _parallettes,
  ms: 2600,
);

const tuckLSit = Motion(
  'tuckLSit',
  [
    (
      Pose(
        hip: Offset(-0.04, -0.13),
        low: -86,
        arm: To(0.03, -0.135),
        leg: To(0.12, -0.10),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.04, -0.14),
        low: -87,
        arm: To(0.03, -0.135),
        leg: To(0.12, -0.16),
      ),
      1,
    ),
  ],
  props: _parallettes,
  ms: 2600,
);

/// Dragon flag: spalle sulla panca, mani dietro la testa che tengono il
/// bordo, corpo dritto che scende piano.
const dragonFlag = Motion(
  'dragonFlag',
  [
    (
      Pose(
        hip: Offset(-0.30, -0.42),
        low: 110,
        neck: 190,
        arm: To(-0.57, -0.13),
        leg: To(-0.15, -0.833),
        toe: -110,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.12, -0.225),
        low: 165,
        neck: 190,
        arm: To(-0.57, -0.13),
        leg: To(0.305, -0.339),
        toe: -15,
      ),
      1.6,
    ),
  ],
  props: [Block(-0.62, -0.12, 0.10, 0)],
  ms: 3000,
);

const _tabletopArm = Ang(-90, -88);
const _tabletopLeg = Ang(-95, -5);

const deadBug = Motion('deadBug', [
  (
    Pose(
      hip: Offset(0, -0.065),
      low: 180,
      neck: 190,
      arm: _tabletopArm,
      leg: _tabletopLeg,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.065),
      low: 180,
      neck: 190,
      arm: Ang(-168, -168),
      arm2: _tabletopArm,
      leg: _tabletopLeg,
      leg2: Ang(-12, -12),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.065),
      low: 180,
      neck: 190,
      arm: _tabletopArm,
      leg: _tabletopLeg,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.065),
      low: 180,
      neck: 190,
      arm: _tabletopArm,
      arm2: Ang(-168, -168),
      leg: Ang(-12, -12),
      leg2: _tabletopLeg,
    ),
    1,
  ),
], ms: 3200);

// Quadrupedia: mani sotto le spalle, ginocchia sotto il bacino.
const _hand4 = To(0.29, -0.01);
const _knee = To(-0.21, -0.035);

const birdDog = Motion('birdDog', [
  (
    Pose(
      hip: Offset(0, -0.27),
      low: 0,
      neck: 20,
      arm: _hand4,
      leg: _knee,
      toe: 180,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.27),
      low: 0,
      neck: 0,
      arm: To(0.575, -0.30),
      arm2: _hand4,
      leg: _knee,
      leg2: To(-0.43, -0.31),
      toe: 180,
      toe2: 180,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.27),
      low: 0,
      neck: 20,
      arm: _hand4,
      leg: _knee,
      toe: 180,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.27),
      low: 0,
      neck: 0,
      arm: _hand4,
      arm2: To(0.575, -0.30),
      leg: To(-0.43, -0.31),
      leg2: _knee,
      toe: 180,
      toe2: 180,
    ),
    1,
  ),
], ms: 3600);

const superman = Motion('superman', [
  (
    Pose(
      hip: Offset(0, -0.055),
      low: 0,
      neck: -4,
      arm: Ang(0, 0),
      leg: To(-0.435, -0.04),
      toe: 180,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.055),
      low: -8,
      high: -20,
      neck: -26,
      arm: Ang(-18, -18),
      leg: To(-0.425, -0.14),
      toe: 170,
    ),
    1,
  ),
], ms: 2200);

// ---- Cardio ----------------------------------------------------------------

const jumpingJack = Motion(
  'jumpingJack',
  [
    (
      Pose(
        hip: Offset(0, -0.47),
        arm: Ang(80, 86),
        arm2: Ang(100, 94),
        leg: To(0.045, -0.03),
        leg2: To(-0.045, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0, -0.42),
        arm: Ang(-40, -55),
        arm2: Ang(-140, -125),
        leg: To(0.17, -0.03),
        leg2: To(-0.17, -0.03),
      ),
      1,
    ),
  ],
  front: true,
  ms: 1000,
);

const highKnees = Motion('highKnees', [
  (
    Pose(
      hip: Offset(0, -0.49),
      low: -88,
      arm: Ang(125, 45),
      arm2: Ang(60, -30),
      leg: To(0.12, -0.27),
      leg2: To(-0.02, -0.06),
      toe: 60,
      toe2: 40,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.49),
      low: -88,
      arm: Ang(60, -30),
      arm2: Ang(125, 45),
      leg: To(-0.02, -0.06),
      leg2: To(0.12, -0.27),
      toe: 40,
      toe2: 60,
    ),
    1,
  ),
], ms: 700);

const _climbMid = Pose(
  hip: Offset(0.38, -0.25),
  low: -8.4,
  neck: -14,
  arm: To(0.69, -0.01),
  leg: To(0.18, -0.10),
);

const mountainClimber = Motion('mountainClimber', [
  (
    Pose(
      hip: Offset(0.40, -0.19),
      low: -20.9,
      neck: -22,
      arm: To(0.69, -0.01),
      leg: To(0.36, -0.07),
      leg2: _feet,
    ),
    1,
  ),
  (_climbMid, 1),
  (
    Pose(
      hip: Offset(0.40, -0.19),
      low: -20.9,
      neck: -22,
      arm: To(0.69, -0.01),
      leg: _feet,
      leg2: To(0.36, -0.07),
    ),
    1,
  ),
  (_climbMid, 1),
], ms: 1000);

const skater = Motion(
  'skater',
  [
    (
      Pose(
        hip: Offset(0.12, -0.38),
        low: -78,
        arm: Ang(150, 160),
        arm2: Ang(160, 170),
        leg: To(0.18, -0.03),
        leg2: To(0.06, -0.12),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.12, -0.38),
        low: -102,
        arm: Ang(30, 20),
        arm2: Ang(20, 10),
        leg: To(-0.06, -0.12),
        leg2: To(-0.18, -0.03),
      ),
      1,
    ),
  ],
  front: true,
  ms: 1300,
);

const _burpeeSquat = Pose(
  hip: Offset(-0.10, -0.22),
  low: -20,
  high: 0,
  neck: -6,
  arm: To(0.24, -0.01),
  leg: _feet,
);

// A metà del salto indietro (e in avanti) il bacino si alza.
const _burpeeHop = Pose(
  hip: Offset(-0.07, -0.26),
  low: -2,
  neck: -10,
  arm: To(0.24, -0.01),
  leg: To(-0.24, -0.09),
);

const burpee = Motion(
  'burpee',
  [
    (_stand, 0.6),
    (_burpeeSquat, 0.3),
    (_burpeeHop, 0.3),
    (
      Pose(
        hip: Offset(-0.039, -0.187),
        low: -20.9,
        neck: -22,
        arm: To(0.24, -0.01),
        leg: To(-0.45, -0.03),
      ),
      0.3,
    ),
    (_burpeeHop, 0.3),
    (_burpeeSquat, 0.5),
    (
      Pose(
        hip: Offset(0, -0.60),
        arm: Ang(-62, -72),
        leg: To(-0.01, -0.165),
        toe: 75,
      ),
      0.6,
    ),
  ],
  ms: 2600,
  still: 3,
);

/// Orso: a quattro zampe con le ginocchia staccate, passi alternati.
const bearCrawl = Motion('bearCrawl', [
  (
    Pose(
      hip: Offset(0, -0.28),
      low: 0,
      neck: 20,
      arm: To(0.34, -0.01),
      arm2: To(0.24, -0.01),
      leg: To(-0.02, -0.03),
      leg2: To(-0.14, -0.03),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.28),
      low: 0,
      neck: 20,
      arm: To(0.24, -0.01),
      arm2: To(0.34, -0.01),
      leg: To(-0.14, -0.03),
      leg2: To(-0.02, -0.03),
    ),
    1,
  ),
], ms: 1200);

// ---- Mobilità --------------------------------------------------------------

const armCircles = Motion('armCircles', [
  (Pose(hip: Offset(0, -0.47), arm: Ang(90, 90), leg: _feet), 1),
  (Pose(hip: Offset(0, -0.47), arm: Ang(0, 0), leg: _feet), 1),
  (Pose(hip: Offset(0, -0.47), arm: Ang(-90, -90), leg: _feet), 1),
  (Pose(hip: Offset(0, -0.47), arm: Ang(180, 180), leg: _feet), 1),
], ms: 2000);

// Vista di fronte: mani sui fianchi, il bacino disegna un cerchio.
const _handsOnHips = Ang(60, 128);
const _handsOnHips2 = Ang(120, 52);

const hipCircles = Motion(
  'hipCircles',
  [
    (
      Pose(
        hip: Offset(0.04, -0.44),
        low: -96,
        arm: _handsOnHips,
        arm2: _handsOnHips2,
        leg: To(0.10, -0.03),
        leg2: To(-0.10, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0, -0.425),
        low: -90,
        arm: _handsOnHips,
        arm2: _handsOnHips2,
        leg: To(0.10, -0.03),
        leg2: To(-0.10, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.04, -0.44),
        low: -84,
        arm: _handsOnHips,
        arm2: _handsOnHips2,
        leg: To(0.10, -0.03),
        leg2: To(-0.10, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0, -0.455),
        low: -90,
        arm: _handsOnHips,
        arm2: _handsOnHips2,
        leg: To(0.10, -0.03),
        leg2: To(-0.10, -0.03),
      ),
      1,
    ),
  ],
  front: true,
  ms: 2400,
);

const thoracic = Motion(
  'thoracic',
  [
    (
      Pose(
        hip: Offset(0, -0.47),
        arm: Ang(-25, -25),
        arm2: Ang(165, 165),
        leg: To(0.10, -0.03),
        leg2: To(-0.10, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0, -0.47),
        arm: Ang(15, 15),
        arm2: Ang(205, 205),
        leg: To(0.10, -0.03),
        leg2: To(-0.10, -0.03),
      ),
      1,
    ),
  ],
  front: true,
  ms: 2600,
);

const catCow = Motion('catCow', [
  (
    Pose(
      hip: Offset(0, -0.27),
      low: -26,
      high: 26,
      neck: 75,
      arm: _hand4,
      leg: _knee,
      toe: 180,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.27),
      low: 14,
      high: -14,
      neck: -40,
      arm: _hand4,
      leg: _knee,
      toe: 180,
    ),
    1,
  ),
], ms: 3200);

const childPose = Motion('childPose', [
  (
    Pose(
      hip: Offset(-0.06, -0.09),
      low: -15,
      high: 15,
      neck: 12,
      arm: To(0.49, -0.02),
      leg: Ang(15, 178),
      toe: 180,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.06, -0.10),
      low: -20,
      high: 12,
      neck: 12,
      arm: To(0.49, -0.02),
      leg: Ang(17, 178),
      toe: 180,
    ),
    1,
  ),
], ms: 3600);

const cobra = Motion('cobra', [
  (
    Pose(
      hip: Offset(0, -0.05),
      low: 0,
      neck: -4,
      arm: To(0.24, -0.01),
      leg: To(-0.435, -0.04),
      toe: 180,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.05),
      low: -20,
      high: -55,
      neck: -65,
      arm: To(0.24, -0.01),
      leg: To(-0.435, -0.04),
      toe: 180,
    ),
    1,
  ),
], ms: 3200);

/// Seduti a gambe tese, il busto si piega sulle gambe e le mani vanno ai
/// piedi.
const pikeStretch = Motion('pikeStretch', [
  (
    Pose(
      hip: Offset(0, -0.065),
      low: -86,
      arm: To(0.14, -0.10),
      leg: To(0.435, -0.04),
      toe: -80,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.065),
      low: -30,
      high: -12,
      neck: 2,
      arm: To(0.47, -0.08),
      leg: To(0.435, -0.04),
      toe: -80,
    ),
    1,
  ),
], ms: 3600);

/// Couch stretch: ginocchio dietro a terra contro il muro, tibia sul muro.
const couchStretch = Motion(
  'couchStretch',
  [
    (
      Pose(
        hip: Offset(-0.06, -0.18),
        low: -90,
        arm: To(0.14, -0.26),
        leg: To(0.24, -0.03),
        leg2: To(-0.25, -0.25),
        toe2: -100,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.03, -0.17),
        low: -96,
        arm: To(0.14, -0.26),
        leg: To(0.24, -0.03),
        leg2: To(-0.25, -0.25),
        toe2: -100,
      ),
      1,
    ),
  ],
  props: [Bar(-0.30, 0, -0.30, -0.55, thick: true)],
  ms: 3200,
);

// ---- Esercizi aggiunti nella 1.2 -------------------------------------------

/// Crunch: sdraiato, ginocchia piegate, le spalle si staccano da terra.
const crunch = Motion('crunch', [
  (
    Pose(
      hip: Offset(0, -0.065),
      low: 180,
      neck: 192,
      arm: To(-0.36, -0.13),
      leg: To(0.28, -0.03),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.065),
      low: 186,
      high: 214,
      neck: 222,
      arm: To(-0.31, -0.25),
      leg: To(0.28, -0.03),
    ),
    1,
  ),
]);

/// Crunch inverso: le ginocchia vengono al petto e il bacino si stacca.
const reverseCrunch = Motion('reverseCrunch', [
  (
    Pose(
      hip: Offset(0, -0.065),
      low: 180,
      neck: 192,
      arm: Ang(-2, -2),
      leg: Ang(-95, -5),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0.0, -0.11),
      low: 170,
      neck: 190,
      arm: Ang(4, 0),
      leg: Ang(-140, -40),
    ),
    1,
  ),
]);

/// Torsioni russe: seduti a V con i piedi staccati, le mani vanno da un
/// fianco all'altro.
const russianTwist = Motion('russianTwist', [
  (
    Pose(
      hip: Offset(0, -0.065),
      low: -125,
      neck: -110,
      arm: To(0.04, -0.30),
      leg: To(0.30, -0.14),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.065),
      low: -122,
      neck: -112,
      arm: To(-0.04, -0.08),
      leg: To(0.30, -0.14),
    ),
    1,
  ),
], ms: 1400);

/// Push-up con i piedi su un rialzo.
const declinePushUp = Motion(
  'declinePushUp',
  [
    (
      Pose(
        hip: Offset(0.44, -0.298),
        low: 1.6,
        neck: -4,
        arm: To(0.74, -0.01),
        leg: To(0, -0.31),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.423, -0.189),
        low: 15.9,
        neck: 6,
        arm: To(0.74, -0.01),
        leg: To(0, -0.31),
      ),
      1,
    ),
  ],
  props: [Block(-0.14, -0.28, 0.10, 0)],
);

/// Pseudo-planche: spalle ben oltre le mani, che restano vicino ai fianchi.
const pseudoPlanche = Motion('pseudoPlanche', [
  (
    Pose(
      hip: Offset(0.42, -0.17),
      low: -18,
      neck: -20,
      arm: To(0.58, -0.01),
      leg: _feet,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0.437, -0.084),
      low: -7.1,
      neck: -10,
      arm: To(0.58, -0.01),
      leg: _feet,
    ),
    1,
  ),
]);

/// Ponte su una gamba: l'altra gamba resta tesa in alto.
const singleLegBridge = Motion('singleLegBridge', [
  (
    Pose(
      hip: Offset(0, -0.065),
      low: 180,
      neck: 192,
      arm: Ang(-2, -2),
      leg: To(0.28, -0.03),
      leg2: Ang(-50, -50),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.03, -0.21),
      low: 146.3,
      neck: 196,
      arm: Ang(-2, -2),
      leg: To(0.28, -0.03),
      leg2: Ang(-34, -34),
    ),
    1,
  ),
]);

/// Affondo laterale, visto di fronte: il peso va da una parte.
const lateralLunge = Motion(
  'lateralLunge',
  [
    (
      Pose(
        hip: Offset(0, -0.40),
        arm: Ang(80, 86),
        arm2: Ang(100, 94),
        leg: To(0.22, -0.03),
        leg2: To(-0.22, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.12, -0.25),
        low: -82,
        arm: Ang(70, 40),
        arm2: Ang(110, 140),
        leg: To(0.22, -0.03),
        leg2: To(-0.22, -0.03),
      ),
      1,
    ),
  ],
  front: true,
  ms: 2400,
);

/// Ginocchia al petto alla sbarra.
const hangingKneeRaise = Motion(
  'hangingKneeRaise',
  [
    (_hang, 1),
    (
      Pose(
        hip: Offset(0.0, -0.45),
        low: -96,
        arm: _hands,
        leg: To(0.12, -0.36),
        toe: 60,
      ),
      1,
    ),
  ],
  floor: false,
  props: [_bar],
);

/// Allungamento in piedi: busto giù verso i piedi.
const standingFold = Motion('standingFold', [
  (_stand, 1),
  (
    Pose(
      hip: Offset(-0.07, -0.465),
      low: 60,
      high: 80,
      neck: 95,
      arm: To(0.12, -0.08),
      leg: _feet,
    ),
    1.4,
  ),
], ms: 3600);

/// Polsi: in quadrupedia, il peso va avanti e indietro.
const wristPrep = Motion('wristPrep', [
  (
    Pose(
      hip: Offset(-0.03, -0.27),
      low: -2,
      neck: 20,
      arm: _hand4,
      leg: _knee,
      toe: 180,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0.06, -0.25),
      low: 4,
      neck: 24,
      arm: _hand4,
      leg: _knee,
      toe: 180,
    ),
    1,
  ),
], ms: 2400);

/// Corda immaginaria: piccoli salti sulle punte, polsi che girano.
const jumpRope = Motion('jumpRope', [
  (Pose(hip: Offset(0, -0.48), arm: Ang(100, 20), leg: _feet, toe: 30), 1),
  (
    Pose(hip: Offset(0, -0.54), arm: Ang(98, 5), leg: To(0, -0.095), toe: 65),
    1,
  ),
], ms: 600);

/// Tutti i movimenti (per l'anteprima e i test).
const allMotions = [
  wallPushUp, inclinePushUp, kneePushUp, pushUp, hinduPushUp, pikePushUp, //
  elevatedPike, wallHandstandPushUp, wallHandstand, handstand, crow,
  tuckPlanche, pullUp, negativePullUp, lSitPullUp, australianRow, deadHang,
  scapPull,
  tableRow,
  chairDip,
  frontLever,
  tuckFrontLever,
  muscleUp,
  dip,
  benchDip,
  barDip,
  squat, deepSquat, squatJump, lunge, bulgarian, stepUp, pistol,
  assistedPistol, shrimp, calfRaise, wallSit, nordic, gluteBridge, plank,
  sidePlank, shoulderTaps, hollow, lSit, tuckLSit, dragonFlag, deadBug,
  birdDog, superman, jumpingJack, highKnees, mountainClimber, skater,
  burpee, bearCrawl, armCircles, hipCircles, thoracic, catCow, childPose,
  cobra, pikeStretch, couchStretch, crunch, reverseCrunch, russianTwist,
  declinePushUp, pseudoPlanche, singleLegBridge, lateralLunge,
  hangingKneeRaise, standingFold, wristPrep, jumpRope,
  ...moreMotions,
];

const _byId = <String, Motion>{
  'push_wall': wallPushUp,
  'push_incline': inclinePushUp,
  'push_knee': kneePushUp,
  'push_classic': pushUp,
  'push_diamond': pushUp,
  'push_archer': pushUp,
  'push_one_arm': pushUp,
  'acc_hindu_pushup': hinduPushUp,
  'acc_table_row': tableRow,
  'acc_chair_dip': chairDip,
  'shoulders_pike': pikePushUp,
  'shoulders_pike_elevated': elevatedPike,
  'shoulders_wall_hspu': wallHandstandPushUp,
  'skill_wall_handstand': wallHandstand,
  'skill_handstand_free': handstand,
  'skill_crow': crow,
  'skill_tuck_planche': tuckPlanche,
  'pull_australian': australianRow,
  'pull_negative': negativePullUp,
  'pull_band': pullUp,
  'pull_up': pullUp,
  'pull_wide': pullUp,
  'pull_archer': pullUp,
  'pull_l_sit': lSitPullUp,
  'acc_chin_up': pullUp,
  'acc_scap_pull': scapPull,
  'acc_dead_hang': deadHang,
  'skill_tuck_front_lever': tuckFrontLever,
  'skill_front_lever': frontLever,
  'skill_muscle_up': muscleUp,
  'dip_bench': benchDip,
  'dip_negative': dip,
  'dip_parallel': dip,
  'dip_straight_bar': barDip,
  'legs_squat': squat,
  'legs_lunge': lunge,
  'acc_reverse_lunge': lunge,
  'legs_bulgarian': bulgarian,
  'legs_pistol_assisted': assistedPistol,
  'legs_pistol': pistol,
  'legs_shrimp': shrimp,
  'acc_step_up': stepUp,
  'acc_calf_raise': calfRaise,
  'acc_wall_sit': wallSit,
  'acc_nordic': nordic,
  'acc_glute_bridge': gluteBridge,
  'core_plank': plank,
  'acc_side_plank': sidePlank,
  'acc_shoulder_taps': shoulderTaps,
  'core_hollow': hollow,
  'core_tuck_lsit': tuckLSit,
  'core_lsit': lSit,
  'core_dragon_flag': dragonFlag,
  'acc_dead_bug': deadBug,
  'acc_bird_dog': birdDog,
  'acc_superman': superman,
  'cardio_jumping_jack': jumpingJack,
  'cardio_high_knees': highKnees,
  'cardio_mountain_climber': mountainClimber,
  'cardio_squat_jump': squatJump,
  'cardio_skater': skater,
  'cardio_burpee': burpee,
  'cardio_bear_crawl': bearCrawl,
  'mob_arm_circles': armCircles,
  'mob_hip_circles': hipCircles,
  'mob_cat_cow': catCow,
  'mob_thoracic': thoracic,
  'mob_deep_squat': deepSquat,
  'mob_pike_stretch': pikeStretch,
  'mob_couch': couchStretch,
  'mob_cobra': cobra,
  'mob_child_pose': childPose,
  'cardio_tuck_jump': squatJump,
  'cardio_jump_rope': jumpRope,
  'cardio_lateral_shuffle': skater,
  'mob_worlds_greatest': lunge,
  'mob_standing_fold': standingFold,
  'mob_wrist': wristPrep,
  'acc_decline_pushup': declinePushUp,
  'acc_wide_pushup': pushUp,
  'acc_pseudo_planche': pseudoPlanche,
  'acc_single_leg_bridge': singleLegBridge,
  'acc_sumo_squat': squat,
  'acc_lateral_lunge': lateralLunge,
  'acc_crunch': crunch,
  'acc_reverse_crunch': reverseCrunch,
  'acc_russian_twist': russianTwist,
  'acc_hanging_knee_raise': hangingKneeRaise,
};

/// Il movimento da mostrare per un esercizio.
Motion motionFor(Exercise e) =>
    _byId[e.id] ??
    motionNamed(e.figure) ??
    switch (e.chain) {
      ChainId.push => pushUp,
      ChainId.pull => pullUp,
      ChainId.dip => dip,
      ChainId.legs => squat,
      ChainId.core => plank,
      ChainId.shoulders => pikePushUp,
      ChainId.skills => handstand,
      ChainId.cardio => jumpingJack,
      ChainId.mobility => catCow,
      ChainId.accessory || ChainId.arms || ChainId.grip => squat,
      ChainId.posture => superman,
      ChainId.plyo => squatJump,
      ChainId.skillDrills => handstand,
    };

final _byName = {for (final m in allMotions) m.name: m};

/// Il movimento con quel nome (campo `figure` degli esercizi).
Motion? motionNamed(String? name) => name == null ? null : _byName[name];

/// Solo per i test: gli esercizi con un movimento dedicato.
Iterable<String> get motionIds => _byId.keys;
