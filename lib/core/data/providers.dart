// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/local_date.dart';
import 'database.dart';

/// Database locale. Nei test si sostituisce con uno in memoria.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Orologio dell'app. Nei test e negli screenshot si fissa una data.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Oggi, secondo l'orologio del telefono.
LocalDate todayFrom(Ref ref) =>
    LocalDate.fromDateTime(ref.read(clockProvider)());
