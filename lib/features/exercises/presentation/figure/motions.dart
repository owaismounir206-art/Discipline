// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:ui';

import '../../domain/exercise.dart';
import 'skeleton.dart';

// Le pose chiave di ogni movimento. Pavimento a y = 0, caviglia a -0.03,
// mani appoggiate a -0.01; la figurina guarda a destra.

const _feet = To(0, -0.03);
const _armsDown = Ang(84, 88);
const _armsForward = Ang(2, 0);

// ---- Spinta ----------------------------------------------------------------

const wallPushUp = Motion(
  'wallPushUp',
  [
    (
      Pose(
        hip: Offset(0.16, -0.44),
        low: -68.7,
        arm: To(0.55, -0.68),
        leg: _feet,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.25, -0.39),
        low: -55.2,
        arm: To(0.55, -0.68),
        leg: _feet,
      ),
      1,
    ),
  ],
  props: [Bar(0.57, 0, 0.57, -1.0, thick: true)],
);

const inclinePushUp = Motion(
  'inclinePushUp',
  [
    (
      Pose(
        hip: Offset(0.261, -0.341),
        low: -45,
        arm: To(0.48, -0.29),
        leg: To(-0.05, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.338, -0.237),
        low: -28,
        neck: -24,
        arm: To(0.48, -0.29),
        leg: To(-0.05, -0.03),
      ),
      1,
    ),
  ],
  props: [Block(0.36, -0.28, 0.62, 0)],
);

const kneePushUp = Motion('kneePushUp', [
  (
    Pose(
      hip: Offset(0.187, -0.147),
      low: -32,
      arm: To(0.44, -0.01),
      leg: To(-0.207, -0.105),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0.219, -0.053),
      low: -6,
      neck: -4,
      arm: To(0.44, -0.01),
      leg: To(-0.207, -0.105),
    ),
    1,
  ),
]);

const pushUp = Motion('pushUp', [
  (
    Pose(
      hip: Offset(0.409, -0.193),
      low: -21.7,
      neck: -26,
      arm: To(0.68, -0.01),
      leg: _feet,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0.439, -0.07),
      low: -3.9,
      neck: -8,
      arm: To(0.68, -0.01),
      leg: _feet,
    ),
    1,
  ),
]);

const hinduPushUp = Motion(
  'hinduPushUp',
  [
    (
      Pose(
        hip: Offset(0.27, -0.38),
        low: 46,
        neck: 62,
        arm: To(0.62, -0.01),
        leg: _feet,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.36, -0.13),
        low: 2,
        neck: 8,
        arm: To(0.62, -0.01),
        leg: _feet,
      ),
      0.8,
    ),
    (
      Pose(
        hip: Offset(0.40, -0.06),
        low: -18,
        high: -55,
        neck: -72,
        arm: To(0.60, -0.01),
        leg: _feet,
      ),
      0.6,
    ),
    (
      Pose(
        hip: Offset(0.40, -0.06),
        low: -18,
        high: -55,
        neck: -72,
        arm: To(0.60, -0.01),
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
      hip: Offset(0.22, -0.41),
      low: 50,
      neck: 72,
      arm: To(0.56, -0.01),
      leg: _feet,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0.27, -0.36),
      low: 76,
      neck: 92,
      arm: To(0.56, -0.01),
      leg: _feet,
    ),
    1,
  ),
], armBend: -1);

const elevatedPike = Motion(
  'elevatedPike',
  [
    (
      Pose(
        hip: Offset(0.30, -0.62),
        low: 76,
        neck: 90,
        arm: To(0.45, -0.01),
        leg: To(0, -0.31),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.36, -0.55),
        low: 86,
        neck: 98,
        arm: To(0.45, -0.01),
        leg: To(0, -0.31),
      ),
      1,
    ),
  ],
  props: [Block(-0.16, -0.28, 0.08, 0)],
  armBend: -1,
);

const wallHandstandPushUp = Motion(
  'wallHspu',
  [
    (
      Pose(
        hip: Offset(0, -0.59),
        low: 90,
        arm: To(0.02, -0.01),
        leg: To(-0.07, -1.02),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.01, -0.42),
        low: 92,
        neck: 95,
        arm: To(0.02, -0.01),
        leg: To(-0.08, -0.85),
      ),
      1,
    ),
  ],
  props: [Bar(-0.13, 0, -0.13, -1.08, thick: true)],
  ms: 2200,
);

const wallHandstand = Motion(
  'wallHandstand',
  [
    (
      Pose(
        hip: Offset(0, -0.59),
        low: 90,
        arm: To(0.02, -0.01),
        leg: To(-0.07, -1.02),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.005, -0.585),
        low: 89,
        arm: To(0.02, -0.01),
        leg: To(-0.065, -1.02),
      ),
      1,
    ),
  ],
  props: [Bar(-0.13, 0, -0.13, -1.08, thick: true)],
  ms: 2600,
);

const handstand = Motion('handstand', [
  (
    Pose(
      hip: Offset(0.012, -0.59),
      low: 89,
      arm: To(0, -0.01),
      leg: To(0.03, -1.03),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.012, -0.59),
      low: 91,
      arm: To(0, -0.01),
      leg: To(-0.03, -1.03),
    ),
    1,
  ),
], ms: 2600);

const crow = Motion('crow', [
  (
    Pose(
      hip: Offset(-0.12, -0.36),
      low: 41.6,
      neck: 30,
      arm: To(0, -0.01),
      leg: To(-0.22, -0.30),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.10, -0.38),
      low: 36,
      neck: 26,
      arm: To(0, -0.01),
      leg: To(-0.21, -0.36),
    ),
    1,
  ),
], ms: 2400);

const tuckPlanche = Motion('tuckPlanche', [
  (
    Pose(
      hip: Offset(-0.25, -0.29),
      low: -4,
      neck: 8,
      arm: To(0, -0.01),
      leg: To(-0.20, -0.15),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.25, -0.31),
      low: -7,
      neck: 6,
      arm: To(0, -0.01),
      leg: To(-0.20, -0.18),
    ),
    1,
  ),
], ms: 2400);

// ---- Tirata ----------------------------------------------------------------

const _bar = Bar(-0.22, -1.0, 0.22, -1.0, thick: true);
const _hands = To(0.03, -1.0);

const pullUp = Motion(
  'pullUp',
  [
    (Pose(hip: Offset(0, -0.42), arm: _hands, leg: To(-0.08, -0.03)), 1),
    (
      Pose(
        hip: Offset(-0.02, -0.67),
        low: -92,
        high: -84,
        arm: _hands,
        leg: To(-0.12, -0.28),
      ),
      1,
    ),
  ],
  floor: false,
  props: [_bar],
);

const negativePullUp = Motion(
  'negativePullUp',
  [
    (
      Pose(
        hip: Offset(-0.02, -0.67),
        low: -92,
        high: -84,
        arm: _hands,
        leg: To(-0.12, -0.28),
      ),
      0.6,
    ),
    (
      Pose(
        hip: Offset(-0.02, -0.67),
        low: -92,
        high: -84,
        arm: _hands,
        leg: To(-0.12, -0.28),
      ),
      2.4,
    ),
    (Pose(hip: Offset(0, -0.42), arm: _hands, leg: To(-0.08, -0.03)), 0.8),
  ],
  ms: 3600,
  floor: false,
  props: [_bar],
);

const lSitPullUp = Motion(
  'lSitPullUp',
  [
    (
      Pose(
        hip: Offset(-0.02, -0.42),
        low: -94,
        arm: _hands,
        leg: To(0.42, -0.44),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.05, -0.66),
        low: -98,
        high: -86,
        arm: _hands,
        leg: To(0.39, -0.70),
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
        hip: Offset(0.415, -0.176),
        low: -19.4,
        arm: To(0.70, -0.55),
        leg: _feet,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.366, -0.274),
        low: -33.7,
        arm: To(0.70, -0.55),
        leg: _feet,
      ),
      1,
    ),
  ],
  props: [Bar(0.58, -0.55, 0.82, -0.55, thick: true)],
);

/// Rematore sotto il tavolo: come le australiane, al bordo di un tavolo.
const tableRow = Motion(
  'tableRow',
  [
    (
      Pose(
        hip: Offset(0.415, -0.176),
        low: -19.4,
        arm: To(0.70, -0.55),
        leg: To(0, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.366, -0.274),
        low: -33.7,
        arm: To(0.70, -0.55),
        leg: To(0, -0.03),
      ),
      1,
    ),
  ],
  props: [Block(0.62, -0.58, 1.02, -0.53), Bar(0.98, -0.53, 0.98, 0)],
);

/// Dip tra due sedie: le parallele sono gli schienali.
const chairDip = Motion(
  'chairDip',
  [
    (
      Pose(
        hip: Offset(-0.02, -0.62),
        low: -88,
        high: -82,
        arm: To(0.04, -0.62),
        leg: To(-0.18, -0.30),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.04, -0.40),
        low: -80,
        high: -65,
        neck: -70,
        arm: To(0.04, -0.62),
        leg: To(-0.22, -0.09),
      ),
      1,
    ),
  ],
  props: [
    Block(-0.05, -0.64, 0.20, -0.60),
    Bar(0.18, -0.60, 0.18, -0.36),
    Block(-0.05, -0.38, 0.30, -0.34),
    Bar(-0.03, -0.34, -0.03, 0),
    Bar(0.28, -0.34, 0.28, 0),
  ],
);

const deadHang = Motion(
  'deadHang',
  [
    (Pose(hip: Offset(0, -0.42), arm: _hands, leg: To(-0.03, 0)), 1),
    (
      Pose(hip: Offset(0.015, -0.42), low: -89, arm: _hands, leg: To(-0.01, 0)),
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
    (Pose(hip: Offset(0, -0.42), arm: _hands, leg: To(-0.03, 0)), 1),
    (
      Pose(
        hip: Offset(0, -0.47),
        low: -94,
        high: -86,
        neck: -86,
        arm: _hands,
        leg: To(-0.03, -0.05),
      ),
      1,
    ),
  ],
  floor: false,
  props: [_bar],
);

const frontLever = Motion(
  'frontLever',
  [
    (Pose(hip: Offset(0, -0.42), arm: _hands, leg: To(-0.02, 0.02)), 0.8),
    (
      Pose(
        hip: Offset(-0.24, -0.74),
        low: 0,
        neck: 2,
        arm: _hands,
        leg: To(-0.68, -0.74),
        toe: 180,
      ),
      0.6,
    ),
    (
      Pose(
        hip: Offset(-0.24, -0.74),
        low: 0,
        neck: 2,
        arm: _hands,
        leg: To(-0.68, -0.74),
        toe: 180,
      ),
      1.2,
    ),
  ],
  ms: 3200,
  floor: false,
  props: [_bar],
  still: 1,
);

const tuckFrontLever = Motion(
  'tuckFrontLever',
  [
    (Pose(hip: Offset(0, -0.42), arm: _hands, leg: To(-0.02, 0.02)), 0.8),
    (
      Pose(
        hip: Offset(-0.24, -0.74),
        low: 0,
        neck: 2,
        arm: _hands,
        leg: To(-0.33, -0.86),
      ),
      0.6,
    ),
    (
      Pose(
        hip: Offset(-0.24, -0.74),
        low: 0,
        neck: 2,
        arm: _hands,
        leg: To(-0.33, -0.86),
      ),
      1.2,
    ),
  ],
  ms: 3200,
  floor: false,
  props: [_bar],
  legBend: 1,
);

const muscleUp = Motion(
  'muscleUp',
  [
    (Pose(hip: Offset(0, -0.42), arm: _hands, leg: To(-0.06, -0.02)), 1),
    (
      Pose(
        hip: Offset(-0.06, -0.68),
        low: -100,
        high: -80,
        arm: _hands,
        leg: To(-0.14, -0.25),
      ),
      0.6,
    ),
    (
      Pose(
        hip: Offset(-0.06, -0.82),
        low: -70,
        high: -55,
        neck: -50,
        arm: _hands,
        leg: To(-0.10, -0.40),
      ),
      0.6,
    ),
    (
      Pose(
        hip: Offset(-0.02, -0.98),
        low: -92,
        arm: To(0.03, -1.0),
        leg: To(-0.04, -0.55),
      ),
      1,
    ),
  ],
  ms: 3000,
  floor: false,
  props: [_bar],
  still: 2,
);

// ---- Dip -------------------------------------------------------------------

const dip = Motion(
  'dip',
  [
    (
      Pose(
        hip: Offset(-0.02, -0.62),
        low: -88,
        high: -82,
        arm: To(0.04, -0.62),
        leg: To(-0.18, -0.30),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.04, -0.40),
        low: -80,
        high: -65,
        neck: -70,
        arm: To(0.04, -0.62),
        leg: To(-0.22, -0.09),
      ),
      1,
    ),
  ],
  props: [Bar(-0.12, -0.62, 0.24, -0.62, thick: true), Bar(0.2, -0.62, 0.2, 0)],
);

const benchDip = Motion(
  'benchDip',
  [
    (
      Pose(
        hip: Offset(-0.02, -0.25),
        arm: To(-0.08, -0.25),
        leg: To(0.36, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.01, -0.08),
        arm: To(-0.08, -0.25),
        leg: To(0.36, -0.03),
      ),
      1,
    ),
  ],
  props: [Block(-0.26, -0.24, -0.04, 0)],
  legBend: -1,
);

const barDip = Motion(
  'barDip',
  [
    (
      Pose(
        hip: Offset(-0.04, -0.62),
        low: -84,
        high: -78,
        arm: To(0.07, -0.62),
        leg: To(-0.02, -0.20),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.10, -0.44),
        low: -60,
        high: -48,
        neck: -50,
        arm: To(0.07, -0.62),
        leg: To(-0.02, -0.02),
      ),
      1,
    ),
  ],
  props: [Bar(-0.14, -0.62, 0.24, -0.62, thick: true)],
);

// ---- Gambe -----------------------------------------------------------------

const squat = Motion('squat', [
  (Pose(hip: Offset(-0.02, -0.47), arm: _armsDown, leg: _feet), 1),
  (
    Pose(
      hip: Offset(-0.18, -0.22),
      low: -55,
      high: -62,
      arm: _armsForward,
      leg: _feet,
    ),
    1,
  ),
]);

const deepSquat = Motion('deepSquat', [
  (
    Pose(
      hip: Offset(-0.12, -0.13),
      low: -70,
      high: -78,
      arm: Ang(30, -40),
      leg: _feet,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.12, -0.15),
      low: -74,
      high: -82,
      arm: Ang(30, -40),
      leg: _feet,
    ),
    1,
  ),
], ms: 3200);

const squatJump = Motion(
  'squatJump',
  [
    (
      Pose(
        hip: Offset(-0.18, -0.22),
        low: -50,
        high: -58,
        arm: Ang(130, 125),
        leg: _feet,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0, -0.62),
        low: -90,
        arm: Ang(-82, -86),
        leg: To(0, -0.18),
        toe: 70,
      ),
      0.7,
    ),
    (Pose(hip: Offset(-0.02, -0.47), arm: Ang(40, 50), leg: _feet), 0.6),
  ],
  ms: 1500,
  still: 1,
);

const lunge = Motion('lunge', [
  (
    Pose(
      hip: Offset(0, -0.43),
      arm: _armsDown,
      leg: To(0.25, -0.03),
      leg2: To(-0.30, -0.03),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.02, -0.23),
      arm: _armsDown,
      leg: To(0.25, -0.03),
      leg2: To(-0.30, -0.03),
      toe2: 90,
    ),
    1,
  ),
]);

const bulgarian = Motion(
  'bulgarian',
  [
    (
      Pose(
        hip: Offset(-0.02, -0.45),
        arm: _armsDown,
        leg: To(0.22, -0.03),
        leg2: To(-0.36, -0.30),
        toe2: 170,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.06, -0.24),
        low: -80,
        arm: _armsDown,
        leg: To(0.22, -0.03),
        leg2: To(-0.36, -0.30),
        toe2: 170,
      ),
      1,
    ),
  ],
  props: [Block(-0.50, -0.27, -0.30, 0)],
);

const stepUp = Motion(
  'stepUp',
  [
    (
      Pose(
        hip: Offset(0, -0.47),
        arm: _armsDown,
        leg: To(0.22, -0.31),
        leg2: To(-0.02, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.2, -0.76),
        arm: _armsDown,
        leg: To(0.22, -0.31),
        leg2: To(0.22, -0.48),
        toe2: 40,
      ),
      1,
    ),
  ],
  props: [Block(0.10, -0.28, 0.42, 0)],
  ms: 2000,
);

const pistol = Motion('pistol', [
  (
    Pose(
      hip: Offset(-0.02, -0.47),
      arm: _armsForward,
      leg: _feet,
      leg2: To(0.22, -0.22),
      toe2: -60,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.20, -0.17),
      low: -48,
      high: -58,
      arm: _armsForward,
      leg: _feet,
      leg2: To(0.24, -0.18),
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
        hip: Offset(-0.02, -0.47),
        arm: To(0.30, -0.62),
        leg: _feet,
        leg2: To(0.22, -0.22),
        toe2: -60,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.18, -0.18),
        low: -52,
        high: -60,
        arm: To(0.30, -0.62),
        leg: _feet,
        leg2: To(0.24, -0.18),
        toe2: -70,
      ),
      1,
    ),
  ],
  props: [Bar(0.32, 0, 0.32, -0.72, thick: true)],
  ms: 2400,
);

const shrimp = Motion('shrimp', [
  (
    Pose(
      hip: Offset(0, -0.47),
      arm: _armsForward,
      leg: _feet,
      leg2: To(-0.22, -0.30),
      toe2: 170,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(-0.12, -0.24),
      low: -62,
      high: -70,
      arm: _armsForward,
      leg: _feet,
      leg2: To(-0.30, -0.06),
      toe2: 175,
    ),
    1,
  ),
], ms: 2400);

const calfRaise = Motion('calfRaise', [
  (Pose(hip: Offset(0, -0.47), arm: _armsDown, leg: _feet, toe: 8), 1),
  (Pose(hip: Offset(0, -0.52), arm: _armsDown, leg: To(0, -0.08), toe: 58), 1),
], ms: 1400);

const wallSit = Motion(
  'wallSit',
  [
    (
      Pose(hip: Offset(-0.12, -0.25), arm: Ang(70, 30), leg: To(0.12, -0.03)),
      1,
    ),
    (
      Pose(hip: Offset(-0.12, -0.255), arm: Ang(72, 28), leg: To(0.12, -0.03)),
      1,
    ),
  ],
  props: [Bar(-0.18, 0, -0.18, -0.90, thick: true)],
  ms: 3000,
);

const nordic = Motion(
  'nordic',
  [
    (
      Pose(
        hip: Offset(0.01, -0.25),
        arm: Ang(80, 70),
        leg: To(-0.21, -0.05),
        toe: 180,
      ),
      0.6,
    ),
    (
      Pose(
        hip: Offset(0.15, -0.17),
        low: -32,
        arm: Ang(55, 40),
        leg: To(-0.21, -0.05),
        toe: 180,
      ),
      2,
    ),
    (
      Pose(
        hip: Offset(0.19, -0.13),
        low: -18,
        arm: To(0.62, -0.01),
        leg: To(-0.21, -0.05),
        toe: 180,
      ),
      0.6,
    ),
  ],
  ms: 3600,
  props: [Block(-0.30, -0.10, -0.16, -0.06)],
  still: 1,
);

const gluteBridge = Motion(
  'gluteBridge',
  [
    (
      Pose(
        hip: Offset(0, -0.06),
        low: 3,
        neck: 0,
        arm: To(0.02, -0.02),
        leg: To(-0.28, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0, -0.25),
        low: 33.7,
        neck: 10,
        arm: To(0.02, -0.02),
        leg: To(-0.28, -0.03),
      ),
      1,
    ),
  ],
  legBend: 1,
  armBend: -1,
);

// ---- Core ------------------------------------------------------------------

const plank = Motion('plank', [
  (
    Pose(
      hip: Offset(0.43, -0.12),
      low: -12.2,
      neck: -14,
      arm: To(0.86, -0.01),
      leg: _feet,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0.43, -0.13),
      low: -12.6,
      neck: -16,
      arm: To(0.86, -0.01),
      leg: _feet,
    ),
    1,
  ),
], ms: 2800);

const sidePlank = Motion(
  'sidePlank',
  [
    (
      Pose(
        hip: Offset(0.40, -0.17),
        low: -14,
        neck: -16,
        arm: To(0.66, -0.01),
        arm2: Ang(-95, -92),
        leg: _feet,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.40, -0.10),
        low: -6,
        neck: -8,
        arm: To(0.66, -0.01),
        arm2: Ang(-95, -92),
        leg: _feet,
      ),
      1,
    ),
  ],
  front: true,
  ms: 2600,
);

const shoulderTaps = Motion('shoulderTaps', [
  (
    Pose(
      hip: Offset(0.409, -0.193),
      low: -21.7,
      neck: -26,
      arm: To(0.68, -0.01),
      arm2: To(0.66, -0.01),
      leg: _feet,
    ),
    0.5,
  ),
  (
    Pose(
      hip: Offset(0.409, -0.193),
      low: -21.7,
      neck: -26,
      arm: To(0.62, -0.30),
      arm2: To(0.66, -0.01),
      leg: _feet,
    ),
    0.5,
  ),
  (
    Pose(
      hip: Offset(0.409, -0.193),
      low: -21.7,
      neck: -26,
      arm: To(0.68, -0.01),
      arm2: To(0.66, -0.01),
      leg: _feet,
    ),
    0.5,
  ),
  (
    Pose(
      hip: Offset(0.409, -0.193),
      low: -21.7,
      neck: -26,
      arm: To(0.68, -0.01),
      arm2: To(0.62, -0.30),
      leg: _feet,
    ),
    0.5,
  ),
], ms: 1600);

const hollow = Motion('hollow', [
  (
    Pose(
      hip: Offset(0, -0.04),
      low: -8,
      high: -16,
      neck: -14,
      arm: Ang(-8, -6),
      leg: To(-0.43, -0.12),
      toe: 190,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.04),
      low: -4,
      high: -10,
      neck: -8,
      arm: Ang(-4, -2),
      leg: To(-0.43, -0.08),
      toe: 185,
    ),
    1,
  ),
], ms: 2400);

const lSit = Motion(
  'lSit',
  [
    (
      Pose(
        hip: Offset(0, -0.12),
        low: -92,
        arm: To(0.02, -0.12),
        leg: To(0.44, -0.05),
        toe: -40,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0, -0.13),
        low: -94,
        arm: To(0.02, -0.12),
        leg: To(0.44, -0.15),
        toe: -50,
      ),
      1,
    ),
  ],
  props: [
    Bar(-0.06, -0.12, 0.10, -0.12, thick: true),
    Bar(0.02, -0.12, 0.02, 0),
  ],
  ms: 2600,
);

const tuckLSit = Motion(
  'tuckLSit',
  [
    (
      Pose(
        hip: Offset(0, -0.12),
        low: -92,
        arm: To(0.02, -0.12),
        leg: To(0.16, -0.10),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0, -0.13),
        low: -94,
        arm: To(0.02, -0.12),
        leg: To(0.16, -0.18),
      ),
      1,
    ),
  ],
  props: [
    Bar(-0.06, -0.12, 0.10, -0.12, thick: true),
    Bar(0.02, -0.12, 0.02, 0),
  ],
  ms: 2600,
);

const dragonFlag = Motion(
  'dragonFlag',
  [
    (
      Pose(
        hip: Offset(0.355, -0.311),
        low: 60,
        neck: 0,
        arm: To(0.66, -0.06),
        leg: To(0.135, -0.692),
        toe: -120,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.22, -0.135),
        low: 15,
        neck: 0,
        arm: To(0.66, -0.06),
        leg: To(-0.20, -0.25),
        toe: 165,
      ),
      1,
    ),
  ],
  props: [Block(0.18, -0.06, 0.78, 0)],
  armBend: -1,
  ms: 3000,
);

const deadBug = Motion('deadBug', [
  (
    Pose(
      hip: Offset(0, -0.05),
      low: 0,
      arm: Ang(-90, -90),
      arm2: Ang(-90, -90),
      leg: Ang(-90, 180),
      leg2: Ang(-90, 180),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.05),
      low: 0,
      arm: Ang(-10, -8),
      arm2: Ang(-90, -90),
      leg: Ang(-90, 180),
      leg2: To(-0.43, -0.09),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.05),
      low: 0,
      arm: Ang(-90, -90),
      arm2: Ang(-90, -90),
      leg: Ang(-90, 180),
      leg2: Ang(-90, 180),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.05),
      low: 0,
      arm: Ang(-90, -90),
      arm2: Ang(-10, -8),
      leg: To(-0.43, -0.09),
      leg2: Ang(-90, 180),
    ),
    1,
  ),
], ms: 3200);

const _knee = To(-0.22, -0.05);

const birdDog = Motion('birdDog', [
  (
    Pose(
      hip: Offset(0, -0.27),
      low: 0,
      neck: 10,
      arm: To(0.30, -0.01),
      leg: _knee,
      toe: 180,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.28),
      low: 0,
      neck: 0,
      arm: Ang(-4, -2),
      arm2: To(0.30, -0.01),
      leg: _knee,
      leg2: To(-0.44, -0.30),
      toe: 180,
      toe2: 180,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.27),
      low: 0,
      neck: 10,
      arm: To(0.30, -0.01),
      leg: _knee,
      toe: 180,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.28),
      low: 0,
      neck: 0,
      arm: To(0.30, -0.01),
      arm2: Ang(-4, -2),
      leg: To(-0.44, -0.30),
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
      hip: Offset(0, -0.06),
      low: 0,
      neck: 2,
      arm: To(0.58, -0.03),
      leg: To(-0.44, -0.03),
      toe: 175,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.06),
      low: -5,
      high: -16,
      neck: -18,
      arm: Ang(-12, -12),
      leg: To(-0.43, -0.15),
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
        arm: Ang(82, 86),
        arm2: Ang(98, 94),
        leg: To(0.04, -0.03),
        leg2: To(-0.04, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0, -0.46),
        arm: Ang(-50, -62),
        arm2: Ang(-130, -118),
        leg: To(0.19, -0.03),
        leg2: To(-0.19, -0.03),
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
      hip: Offset(0, -0.50),
      arm: Ang(120, 50),
      arm2: Ang(55, -35),
      leg: To(0.12, -0.30),
      leg2: To(-0.02, -0.06),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.50),
      arm: Ang(55, -35),
      arm2: Ang(120, 50),
      leg: To(-0.02, -0.06),
      leg2: To(0.12, -0.30),
    ),
    1,
  ),
], ms: 700);

const mountainClimber = Motion('mountainClimber', [
  (
    Pose(
      hip: Offset(0.38, -0.22),
      low: -24,
      neck: -28,
      arm: To(0.66, -0.01),
      leg: To(0.30, -0.08),
      leg2: _feet,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0.38, -0.22),
      low: -24,
      neck: -28,
      arm: To(0.66, -0.01),
      leg: _feet,
      leg2: To(0.30, -0.08),
    ),
    1,
  ),
], ms: 800);

const skater = Motion(
  'skater',
  [
    (
      Pose(
        hip: Offset(0.14, -0.40),
        low: -80,
        arm: Ang(160, 150),
        arm2: Ang(150, 140),
        leg: To(0.18, -0.03),
        leg2: To(0.0, -0.12),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.14, -0.40),
        low: -100,
        arm: Ang(30, 40),
        arm2: Ang(20, 30),
        leg: To(0.0, -0.12),
        leg2: To(-0.18, -0.03),
      ),
      1,
    ),
  ],
  front: true,
  ms: 1300,
);

const burpee = Motion(
  'burpee',
  [
    (Pose(hip: Offset(0, -0.47), arm: _armsDown, leg: _feet), 0.6),
    (
      Pose(
        hip: Offset(-0.06, -0.20),
        low: -40,
        high: -30,
        neck: -20,
        arm: To(0.22, -0.01),
        leg: _feet,
      ),
      0.5,
    ),
    (
      Pose(
        hip: Offset(-0.042, -0.195),
        low: -22,
        neck: -26,
        arm: To(0.22, -0.01),
        leg: To(-0.45, -0.03),
      ),
      0.6,
    ),
    (
      Pose(
        hip: Offset(-0.06, -0.20),
        low: -40,
        high: -30,
        neck: -20,
        arm: To(0.22, -0.01),
        leg: _feet,
      ),
      0.5,
    ),
    (
      Pose(
        hip: Offset(0, -0.62),
        arm: Ang(-80, -86),
        leg: To(0, -0.17),
        toe: 70,
      ),
      0.6,
    ),
  ],
  ms: 2600,
  still: 2,
);

const bearCrawl = Motion('bearCrawl', [
  (
    Pose(
      hip: Offset(0, -0.31),
      low: -4,
      neck: 10,
      arm: To(0.38, -0.01),
      arm2: To(0.28, -0.01),
      leg: To(-0.02, -0.03),
      leg2: To(-0.14, -0.03),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.31),
      low: -4,
      neck: 10,
      arm: To(0.28, -0.01),
      arm2: To(0.38, -0.01),
      leg: To(-0.14, -0.03),
      leg2: To(-0.02, -0.03),
    ),
    1,
  ),
], ms: 1200);

// ---- Mobilità --------------------------------------------------------------

const armCircles = Motion('armCircles', [
  (
    Pose(
      hip: Offset(0, -0.47),
      arm: Ang(90, 90),
      leg: To(0, -0.03),
      leg2: To(-0.02, -0.03),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.47),
      arm: Ang(0, 0),
      leg: To(0, -0.03),
      leg2: To(-0.02, -0.03),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.47),
      arm: Ang(-90, -90),
      leg: To(0, -0.03),
      leg2: To(-0.02, -0.03),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.47),
      arm: Ang(180, 180),
      leg: To(0, -0.03),
      leg2: To(-0.02, -0.03),
    ),
    1,
  ),
], ms: 2000);

const hipCircles = Motion(
  'hipCircles',
  [
    (
      Pose(
        hip: Offset(0.05, -0.46),
        low: -95,
        arm: Ang(130, 30),
        arm2: Ang(50, 150),
        leg: To(0.12, -0.03),
        leg2: To(-0.12, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0, -0.44),
        low: -90,
        arm: Ang(130, 30),
        arm2: Ang(50, 150),
        leg: To(0.12, -0.03),
        leg2: To(-0.12, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.05, -0.46),
        low: -85,
        arm: Ang(130, 30),
        arm2: Ang(50, 150),
        leg: To(0.12, -0.03),
        leg2: To(-0.12, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0, -0.48),
        low: -90,
        arm: Ang(130, 30),
        arm2: Ang(50, 150),
        leg: To(0.12, -0.03),
        leg2: To(-0.12, -0.03),
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
        arm: Ang(-20, -20),
        arm2: Ang(160, 160),
        leg: To(0.10, -0.03),
        leg2: To(-0.10, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0, -0.47),
        arm: Ang(20, 20),
        arm2: Ang(200, 200),
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
      low: -24,
      high: 22,
      neck: 70,
      arm: To(0.30, -0.01),
      leg: _knee,
      toe: 180,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.27),
      low: 16,
      high: -16,
      neck: -40,
      arm: To(0.30, -0.01),
      leg: _knee,
      toe: 180,
    ),
    1,
  ),
], ms: 3200);

const childPose = Motion(
  'childPose',
  [
    (
      Pose(
        hip: Offset(-0.02, -0.10),
        low: -26,
        high: 6,
        neck: 48,
        arm: To(0.58, -0.01),
        leg: Ang(15, 175),
        toe: 180,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(-0.02, -0.11),
        low: -32,
        high: 2,
        neck: 44,
        arm: To(0.56, -0.01),
        leg: Ang(15, 175),
        toe: 180,
      ),
      1,
    ),
  ],
  ms: 3600,
  armBend: -1,
);

const cobra = Motion('cobra', [
  (
    Pose(
      hip: Offset(0, -0.05),
      low: 0,
      neck: 4,
      arm: To(0.30, -0.01),
      leg: To(-0.44, -0.03),
      toe: 175,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.05),
      low: -16,
      high: -52,
      neck: -64,
      arm: To(0.30, -0.01),
      leg: To(-0.44, -0.03),
      toe: 175,
    ),
    1,
  ),
], ms: 3200);

const pikeStretch = Motion(
  'pikeStretch',
  [
    (
      Pose(
        hip: Offset(0, -0.06),
        low: -78,
        high: -86,
        arm: Ang(-50, -60),
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
        arm: To(0.44, -0.06),
        leg: To(0.44, -0.03),
        toe: -70,
      ),
      1,
    ),
  ],
  ms: 3600,
  armBend: -1,
);

const couchStretch = Motion(
  'couchStretch',
  [
    (
      Pose(
        hip: Offset(0, -0.25),
        arm: Ang(110, 60),
        leg: To(0.24, -0.03),
        leg2: To(-0.20, -0.26),
        toe2: -90,
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.05, -0.23),
        low: -96,
        arm: Ang(110, 60),
        leg: To(0.24, -0.03),
        leg2: To(-0.20, -0.26),
        toe2: -90,
      ),
      1,
    ),
  ],
  props: [Bar(-0.27, 0, -0.27, -0.45, thick: true)],
  ms: 3200,
);

// ---- Esercizi aggiunti nella 1.2 -------------------------------------------

/// Crunch: sdraiato, ginocchia piegate, le spalle si staccano da terra.
const crunch = Motion(
  'crunch',
  [
    (
      Pose(
        hip: Offset(0, -0.06),
        low: 2,
        neck: 0,
        arm: Ang(-170, -175),
        leg: To(-0.28, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0, -0.06),
        low: -8,
        high: -38,
        neck: -45,
        arm: Ang(-165, -170),
        leg: To(-0.28, -0.03),
      ),
      1,
    ),
  ],
  legBend: 1,
  ms: 1800,
);

/// Crunch inverso: le ginocchia vengono al petto e il bacino si stacca.
const reverseCrunch = Motion(
  'reverseCrunch',
  [
    (
      Pose(
        hip: Offset(0, -0.06),
        low: 2,
        neck: 0,
        arm: To(0.30, -0.02),
        leg: Ang(-95, 180),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0, -0.11),
        low: 9,
        neck: 4,
        arm: To(0.30, -0.02),
        leg: Ang(-55, -140),
      ),
      1,
    ),
  ],
  armBend: -1,
  ms: 1800,
);

/// Torsioni russe, viste di fronte: busto inclinato, mani da un lato
/// all'altro.
const russianTwist = Motion('russianTwist', [
  (
    Pose(
      hip: Offset(0, -0.06),
      low: -120,
      neck: -105,
      arm: To(0.10, -0.20),
      leg: To(0.30, -0.14),
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0, -0.06),
      low: -122,
      neck: -110,
      arm: To(-0.01, -0.06),
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
        hip: Offset(0.44, -0.31),
        low: 0,
        neck: -2,
        arm: To(0.72, -0.01),
        leg: To(0, -0.31),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.425, -0.196),
        low: 15,
        neck: 18,
        arm: To(0.72, -0.01),
        leg: To(0, -0.31),
      ),
      1,
    ),
  ],
  props: [Block(-0.16, -0.28, 0.08, 0)],
);

/// Pseudo-planche: spalle oltre le mani.
const pseudoPlanche = Motion('pseudoPlanche', [
  (
    Pose(
      hip: Offset(0.40, -0.17),
      low: -16,
      neck: -20,
      arm: To(0.56, -0.01),
      leg: _feet,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0.43, -0.07),
      low: -4,
      neck: -8,
      arm: To(0.56, -0.01),
      leg: _feet,
    ),
    1,
  ),
]);

/// Ponte su una gamba: l'altra gamba resta tesa in alto.
const singleLegBridge = Motion(
  'singleLegBridge',
  [
    (
      Pose(
        hip: Offset(0, -0.06),
        low: 3,
        neck: 0,
        arm: To(0.02, -0.02),
        leg: To(-0.28, -0.03),
        leg2: Ang(-150, -150),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0, -0.25),
        low: 33.7,
        neck: 10,
        arm: To(0.02, -0.02),
        leg: To(-0.28, -0.03),
        leg2: Ang(-146, -146),
      ),
      1,
    ),
  ],
  legBend: 1,
  armBend: -1,
);

/// Affondo laterale, visto di fronte: il peso va da una parte.
const lateralLunge = Motion(
  'lateralLunge',
  [
    (
      Pose(
        hip: Offset(0, -0.44),
        arm: Ang(82, 86),
        arm2: Ang(98, 94),
        leg: To(0.26, -0.03),
        leg2: To(-0.26, -0.03),
      ),
      1,
    ),
    (
      Pose(
        hip: Offset(0.14, -0.27),
        low: -84,
        arm: Ang(78, 70),
        arm2: Ang(102, 110),
        leg: To(0.26, -0.03),
        leg2: To(-0.26, -0.03),
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
    (Pose(hip: Offset(0, -0.42), arm: _hands, leg: To(-0.02, 0.02)), 1),
    (
      Pose(
        hip: Offset(0.02, -0.45),
        low: -96,
        arm: _hands,
        leg: To(0.20, -0.24),
      ),
      1,
    ),
  ],
  floor: false,
  props: [_bar],
);

/// Allungamento in piedi: busto giù verso i piedi.
const standingFold = Motion(
  'standingFold',
  [
    (Pose(hip: Offset(0, -0.47), arm: _armsDown, leg: _feet), 1),
    (
      Pose(
        hip: Offset(-0.08, -0.46),
        low: 25,
        high: 50,
        neck: 68,
        arm: To(0.10, -0.14),
        leg: _feet,
      ),
      1.4,
    ),
  ],
  ms: 3600,
  still: 1,
);

/// Polsi: in quadrupedia, il peso va avanti e indietro.
const wristPrep = Motion('wristPrep', [
  (
    Pose(
      hip: Offset(-0.03, -0.27),
      low: -2,
      neck: 10,
      arm: To(0.30, -0.01),
      leg: _knee,
      toe: 180,
    ),
    1,
  ),
  (
    Pose(
      hip: Offset(0.07, -0.25),
      low: 6,
      neck: 16,
      arm: To(0.30, -0.01),
      leg: To(-0.16, -0.05),
      toe: 180,
    ),
    1,
  ),
], ms: 2400);

/// Corda immaginaria: piccoli salti sulle punte, polsi che girano.
const jumpRope = Motion('jumpRope', [
  (Pose(hip: Offset(0, -0.47), arm: Ang(100, 30), leg: _feet, toe: 30), 1),
  (
    Pose(hip: Offset(0, -0.53), arm: Ang(100, 10), leg: To(0, -0.09), toe: 60),
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
      ChainId.accessory => squat,
    };

/// Solo per i test: gli esercizi con un movimento dedicato.
Iterable<String> get motionIds => _byId.keys;
