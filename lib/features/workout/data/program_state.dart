// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/providers.dart';
import '../domain/my_program.dart';

const _key = 'my_program';

/// La tua scheda salvata (null se non ne hai una).
final myProgramProvider = StreamProvider<MyProgram?>((ref) {
  return ref.watch(databaseProvider).watchJson(_key).map((json) {
    if (json is! Map<String, Object?>) return null;
    final program = MyProgram.fromJson(json);
    return program.days.isEmpty ? null : program;
  });
});

/// Salva la scheda (null la cancella).
Future<void> saveProgram(WidgetRef ref, MyProgram? program) {
  final db = ref.read(databaseProvider);
  return program == null
      ? db.deleteKey(_key)
      : db.writeJson(_key, program.toJson());
}
