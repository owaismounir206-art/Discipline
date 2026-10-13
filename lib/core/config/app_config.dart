// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Indirizzi dei servizi online, letti al momento della compilazione con
/// `--dart-define-from-file=config/ritmo.json` (file escluso da git: vedi
/// `config/ritmo.example.json`). Senza configurazione Ritmo funziona tutta
/// offline, tranne sfide con gli amici e backup.
@immutable
class AppConfig {
  const AppConfig({
    this.supabaseUrl = '',
    this.supabaseKey = '',
    this.livekitUrl = '',
  });

  static const fromEnvironment = AppConfig(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    livekitUrl: String.fromEnvironment('LIVEKIT_URL'),
  );

  final String supabaseUrl;
  final String supabaseKey;
  final String livekitUrl;

  /// C'è un server per account, amici e sfide?
  bool get hasServer => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  /// C'è un server video per vedersi durante le sfide?
  bool get hasVideo => hasServer && livekitUrl.isNotEmpty;
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment,
);
