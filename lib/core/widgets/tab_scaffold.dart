// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

/// Struttura comune delle schermate nelle 5 schede: intestazione e contenuto
/// scorrevole con i margini del design (16 px ai lati, 14 px tra i blocchi).
class TabScaffold extends StatelessWidget {
  const TabScaffold({super.key, required this.header, required this.children});

  final Widget header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            header,
            for (final child in children) ...[
              const SizedBox(height: 14),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// Mostra un avviso per le azioni che arriveranno nelle prossime fasi.
void showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$feature: in arrivo')));
}
