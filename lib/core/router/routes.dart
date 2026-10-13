// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

/// Percorsi delle schermate. I link d'invito usano `ritmo://invito/CODICE`.
abstract final class Routes {
  // Le 5 schede.
  static const today = '/oggi';
  static const workout = '/allenati';
  static const challenge = '/sfida';
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
  static const nutrition = '/cibo/consigli';
  static const bodyData = '/cibo/dati';
  static const login = '/accesso';
  static const challengeLive = '/sfida/live';

  static String exercise(String id) => '/esercizio/$id';
  static String live(String id) => '$challengeLive/$id';
  static String invite(String code) => '/invito/$code';
}
