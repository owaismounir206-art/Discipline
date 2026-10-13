// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:meta/meta.dart';

/// Un giorno del calendario (senza ora né fuso orario).
///
/// Streak, diario e allenamenti ragionano per "giorno del telefono": un
/// allenamento iniziato alle 23:50 conta per quel giorno anche se finisce
/// dopo mezzanotte. Le operazioni usano il calendario (non `Duration`) per
/// non sbagliare nei giorni del cambio dell'ora.
@immutable
class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  factory LocalDate.fromDateTime(DateTime dateTime) {
    final local = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    return LocalDate(local.year, local.month, local.day);
  }

  factory LocalDate.today() => LocalDate.fromDateTime(DateTime.now());

  /// Legge una data scritta come `2026-10-13`.
  factory LocalDate.parse(String text) {
    final parts = text.split('-');
    if (parts.length != 3) {
      throw FormatException('Data non valida', text);
    }
    return LocalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    ).normalized;
  }

  final int year;
  final int month;
  final int day;

  /// Mezzanotte locale di questo giorno.
  DateTime get dateTime => DateTime(year, month, day);

  LocalDate get normalized => LocalDate.fromDateTime(dateTime);

  /// 1 = lunedì … 7 = domenica, come [DateTime.weekday].
  int get weekday => dateTime.weekday;

  LocalDate addDays(int days) =>
      LocalDate.fromDateTime(DateTime(year, month, day + days));

  /// Giorni di calendario da [other] a questo giorno (positivo se dopo).
  int daysSince(LocalDate other) => DateTime.utc(
    year,
    month,
    day,
  ).difference(DateTime.utc(other.year, other.month, other.day)).inDays;

  /// Il lunedì della settimana di questo giorno.
  LocalDate get startOfWeek => addDays(1 - weekday);

  LocalDate get startOfMonth => LocalDate(year, month, 1);

  bool isBefore(LocalDate other) => compareTo(other) < 0;

  bool isAfter(LocalDate other) => compareTo(other) > 0;

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// Formato `2026-10-13`, usato nel database.
  String get key =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  String toString() => key;
}
