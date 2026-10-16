// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/data/database.dart';
import 'core/feedback/feedback_binding.dart';
import 'core/feedback/feedback_settings.dart';
import 'core/feedback/ui_feedback.dart';
import 'core/data/providers.dart';
import 'core/theme/theme_settings.dart';

const _styleFonts = {
  'Anton': 'Anton',
  'Archivo': 'Archivo',
  'ArchivoBlack': 'Archivo Black',
  'Baloo': 'Baloo 2',
  'Barlow': 'Barlow',
  'Fredoka': 'Fredoka',
  'OpenSans': 'Open Sans',
  'Orbitron': 'Orbitron',
  'PlexMono': 'IBM Plex Mono',
  'PressStart': 'Press Start 2P',
  'Rajdhani': 'Rajdhani',
  'Shippori': 'Shippori Mincho',
  'DotGothic': 'DotGothic16',
  'YujiBoku': 'Yuji Boku',
  'ZenKaku': 'Zen Kaku Gothic New',
};

Future<void> main() async {
  // Come WidgetsFlutterBinding, in più fa suonare i tocchi.
  DisciplineBinding();
  // Il font Figtree è incluso nell'app: aggiungiamo la sua licenza (OFL)
  // all'elenco delle licenze open source mostrato nelle impostazioni.
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Figtree'], license);
    // I caratteri degli stili (tool/make_fonts.py).
    for (final MapEntry(key: file, value: name) in _styleFonts.entries) {
      final text = await rootBundle.loadString(
        'assets/fonts/licenses/$file.txt',
      );
      yield LicenseEntryWithLineBreaks([name], text);
    }
  });

  // Database aperto qui per leggere subito il tema scelto (niente lampo del
  // tema predefinito all'avvio).
  final db = AppDatabase();
  final theme = await loadThemeSettings(db)
      .catchError((Object _) => const ThemeSettings());
  (await loadFeedbackSettings(db)
          .catchError((Object _) => const FeedbackSettings()))
      .apply();
  UiFeedback.instance.player = DeviceSoundPlayer();
  unawaited(UiFeedback.instance.player.warmUp());
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        initialThemeProvider.overrideWithValue(theme),
      ],
      child: const DisciplineApp(),
    ),
  );
}
