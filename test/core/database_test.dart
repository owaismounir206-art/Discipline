// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('salva e rilegge valori JSON', () async {
    expect(await db.readJson('x'), isNull);
    await db.writeJson('x', {
      'a': 1,
      'b': [1, 2],
    });
    expect(await db.readJson('x'), {
      'a': 1,
      'b': [1, 2],
    });
    await db.writeJson('x', 3);
    expect(await db.readJson('x'), 3);
    await db.deleteKey('x');
    expect(await db.readJson('x'), isNull);
  });

  test('wipe cancella tutto', () async {
    await db.writeJson('y', true);
    await db.wipe();
    expect(await db.readJson('y'), isNull);
  });
}
