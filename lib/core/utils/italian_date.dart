// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

const _weekdays = [
  'lunedì',
  'martedì',
  'mercoledì',
  'giovedì',
  'venerdì',
  'sabato',
  'domenica',
];

const _months = [
  'gennaio',
  'febbraio',
  'marzo',
  'aprile',
  'maggio',
  'giugno',
  'luglio',
  'agosto',
  'settembre',
  'ottobre',
  'novembre',
  'dicembre',
];

/// Formatta una data come nel design: "martedì 13 ottobre".
///
/// Con [capitalize] la prima lettera è maiuscola: "Martedì 13 ottobre".
String formatItalianDate(DateTime date, {bool capitalize = false}) {
  final text =
      '${_weekdays[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}';
  return capitalize ? text[0].toUpperCase() + text.substring(1) : text;
}
