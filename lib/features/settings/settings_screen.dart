// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/ritmo_theme.dart';
import '../../core/theme/theme_settings.dart';

/// Impostazioni: aspetto dell'app e informazioni sul progetto.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    final notifier = ref.read(themeSettingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _SectionTitle('Aspetto'),
          _Group(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Tema', style: theme.textTheme.titleMedium),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('Sistema'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Chiaro'),
                    ),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Scuro')),
                  ],
                  selected: {settings.mode},
                  onSelectionChanged: (value) => notifier.setMode(value.first),
                ),
              ),
              SwitchListTile(
                title: const Text('Colori dal tuo sfondo'),
                subtitle: const Text(
                  'Usa i colori del telefono invece del corallo di Ritmo. '
                  'Solo su Android 12 o successivi.',
                ),
                value: settings.useDynamicColor,
                onChanged: notifier.setUseDynamicColor,
              ),
            ],
          ),
          const _SectionTitle('Informazioni'),
          _Group(
            children: [
              const ListTile(
                leading: Icon(Icons.favorite_outline),
                title: Text('Libera e gratuita'),
                subtitle: Text(
                  'Ritmo è open source (GPL-3.0): niente pubblicità, '
                  'abbonamenti o tracciamento.',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Licenze open source'),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Ritmo',
                  applicationLegalese:
                      'Copyright (C) 2026 Ritmo contributors\n'
                      'Distribuita con licenza GNU GPL v3 o successiva.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RitmoRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
