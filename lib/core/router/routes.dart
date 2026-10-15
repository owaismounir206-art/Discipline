// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

/// Percorsi delle schermate.
abstract final class Routes {
  // Le 5 schede.
  static const today = '/oggi';
  static const workout = '/allenati';
  static const challenge = '/sfide';
  static const food = '/cibo';
  static const progress = '/progressi';

  // Primo avvio.
  static const welcome = '/benvenuto';
  static const onboardingProfile = '/benvenuto/profilo';

  // Schermate a tutto schermo.
  static const settings = '/impostazioni';
  static const athleteProfile = '/profilo-atleta';
  static const session = '/allenamento';
  static const cameraCounter = '/fotocamera';
  static const foodSearch = '/cibo/cerca';
  static const foodScanner = '/cibo/scanner';
  static const foodPick = '/cibo/scegli';
  static const homemade = '/cibo/ricetta';
  static const nutrition = '/cibo/consigli';
  static const bodyData = '/cibo/dati';
  static const timedChallenge = '/sfide/a-tempo';
  static const friendChallenge = '/sfide/amico';
  static const timer = '/timer';
  static const timerRunning = '/timer/via';

  static String exercise(String id) => '/esercizio/$id';

  /// Percorso a tappe di una catena (nome dell'enum).
  static String path(String chain) => '/percorso/$chain';

  /// Timer in corso con le sue impostazioni.
  static String timerRun(Map<String, String> query) =>
      Uri(path: timerRunning, queryParameters: query).toString();

  /// Sfida a tempo; con [code] è la sfida di un amico.
  static String timed(String mode, {String? code}) => Uri(
    path: timedChallenge,
    queryParameters: {'modo': mode, 'codice': ?code},
  ).toString();
}
