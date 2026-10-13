// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Condivide un testo con le app del telefono (WhatsApp, Telegram...).
typedef ShareText = Future<void> Function(String text);

final shareTextProvider = Provider<ShareText>(
  (ref) =>
      (text) => SharePlus.instance.share(ShareParams(text: text)),
);
