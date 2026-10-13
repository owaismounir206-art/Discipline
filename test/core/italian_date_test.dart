// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/utils/italian_date.dart';

void main() {
  group('formatItalianDate', () {
    test('scrive giorno della settimana, numero e mese in italiano', () {
      expect(formatItalianDate(DateTime(2026, 10, 13)), 'martedì 13 ottobre');
    });

    test('mette la maiuscola se richiesto', () {
      expect(
        formatItalianDate(DateTime(2026, 10, 13), capitalize: true),
        'Martedì 13 ottobre',
      );
    });

    test('gestisce inizio e fine della settimana e dell\'anno', () {
      expect(formatItalianDate(DateTime(2026, 1, 1)), 'giovedì 1 gennaio');
      expect(formatItalianDate(DateTime(2026, 12, 27)), 'domenica 27 dicembre');
      expect(formatItalianDate(DateTime(2026, 12, 28)), 'lunedì 28 dicembre');
    });
  });
}
