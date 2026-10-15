// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:meta/meta.dart';

import '../../../core/utils/local_date.dart';
import 'timed.dart';

/// Una sfida da mandare a un amico: modalità, punteggio da battere e nome.
///
/// Tutto sta nel codice: niente server. L'amico lo inserisce, fa la stessa
/// sfida e vede subito chi ha vinto.
@immutable
class FriendChallenge {
  const FriendChallenge({
    required this.mode,
    required this.score,
    required this.name,
    required this.date,
  });

  final TimedMode mode;

  /// Ripetizioni (minuto) o decimi di secondo (gara a 50).
  final int score;
  final String name;
  final LocalDate date;

  String get scoreLabel => scoreText(mode, score);

  @override
  bool operator ==(Object other) =>
      other is FriendChallenge &&
      other.mode == mode &&
      other.score == score &&
      other.name == name &&
      other.date == date;

  @override
  int get hashCode => Object.hash(mode, score, name, date);
}

const _version = 1;
const _maxNameBytes = 12;

/// Giorno zero delle date nel codice (giorni di calendario, senza fuso).
const _epochDay = LocalDate(2026, 1, 1);

/// Alfabeto Crockford: niente I, L, O, U (si confondono dettando).
const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// Nome tagliato a 12 byte senza spezzare le lettere accentate.
String _shortName(String name) {
  var out = name.trim();
  while (utf8.encode(out).length > _maxNameBytes) {
    out = String.fromCharCodes(out.runes.toList()..removeLast());
  }
  return out.trimRight();
}

int _checksum(List<int> bytes) {
  var c = 0x5A;
  for (final b in bytes) {
    c = ((c * 31) + b) & 0xFF;
  }
  return c;
}

/// Codice da condividere, es. "0H2K-5Z9A-…" (lettere e numeri a gruppi).
String encodeFriendChallenge(FriendChallenge c) {
  final days = c.date.daysSince(_epochDay).clamp(0, 65535);
  final score = c.score.clamp(0, 65535);
  final name = utf8.encode(_shortName(c.name));
  final bytes = <int>[
    _version,
    c.mode.index,
    score >> 8,
    score & 0xFF,
    days >> 8,
    days & 0xFF,
    ...name,
  ];
  bytes.add(_checksum(bytes));

  // Base32: 5 bit per carattere.
  final out = StringBuffer();
  var buffer = 0;
  var bits = 0;
  for (final b in bytes) {
    buffer = (buffer << 8) | b;
    bits += 8;
    while (bits >= 5) {
      bits -= 5;
      out.write(_alphabet[(buffer >> bits) & 31]);
    }
  }
  if (bits > 0) out.write(_alphabet[(buffer << (5 - bits)) & 31]);

  final raw = out.toString();
  return [
    for (var i = 0; i < raw.length; i += 4)
      raw.substring(i, i + 4 > raw.length ? raw.length : i + 4),
  ].join('-');
}

/// Legge un codice; null se non è valido (errore di battitura o altro).
FriendChallenge? decodeFriendChallenge(String code) {
  final clean = code
      .toUpperCase()
      .replaceAll(RegExp(r'[\s-]'), '')
      .replaceAll('O', '0')
      .replaceAll(RegExp('[IL]'), '1');
  if (clean.isEmpty) return null;
  final bytes = <int>[];
  var buffer = 0;
  var bits = 0;
  for (final ch in clean.split('')) {
    final v = _alphabet.indexOf(ch);
    if (v < 0) return null;
    buffer = ((buffer << 5) | v) & 0xFFFF;
    bits += 5;
    if (bits >= 8) {
      bits -= 8;
      bytes.add((buffer >> bits) & 0xFF);
    }
  }
  if (bytes.length < 7) return null;
  final body = bytes.sublist(0, bytes.length - 1);
  if (_checksum(body) != bytes.last) return null;
  if (body[0] != _version || body[1] >= TimedMode.values.length) return null;
  final String name;
  try {
    name = utf8.decode(body.sublist(6));
  } on FormatException {
    return null;
  }
  final days = (body[4] << 8) | body[5];
  return FriendChallenge(
    mode: TimedMode.values[body[1]],
    score: (body[2] << 8) | body[3],
    name: name,
    date: _epochDay.addDays(days),
  );
}

/// Testo da mandare su WhatsApp, Telegram...
String friendChallengeMessage(FriendChallenge c) =>
    '${c.name.isEmpty ? 'Ti sfido' : '${c.name} ti sfida'} su Discipline! 💪\n'
    '${c.mode.label}: ${c.scoreLabel}. Riesci a battermi?\n'
    'In Discipline apri Sfide › Sfida un amico e inserisci il codice:\n'
    '${encodeFriendChallenge(c)}';

/// Risposta dopo aver fatto la sfida di un amico.
String friendReplyMessage(FriendChallenge c, TimedResult mine, String me) {
  final my = mine.score;
  final won = my != null && isBetterScore(c.mode, my, c.score);
  final tie = my == c.score;
  final verdict = won
      ? 'Ti ho battuto'
      : tie
      ? 'Pareggio'
      : 'Hai vinto tu';
  return '$verdict${c.name.isEmpty ? '' : ', ${c.name}'}! '
      '${c.mode.label}: io ${mine.scoreLabel}, tu ${c.scoreLabel}. '
      '${me.isEmpty ? '' : '— $me, '}su Discipline 💪';
}
