// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/data/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/discipline_theme.dart';
import '../../core/theme/theme_settings.dart';
import '../../core/utils/local_date.dart';
import '../../core/widgets/motion_widgets.dart';
import '../profile/data/profile_repository.dart';
import '../profile/domain/athlete_profile.dart';
import '../streak/data/reminders.dart';
import 'backup.dart';

/// Impostazioni e profilo.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _updateReminder(WidgetRef ref, ReminderTime? time) async {
    final repo = ref.read(profileRepositoryProvider);
    final profile = await repo.loadProfile();
    if (profile == null) return;
    final next = time == null
        ? profile.copyWith(clearReminder: true)
        : profile.copyWith(reminder: time);
    await repo.saveProfile(
      next,
      LocalDate.fromDateTime(ref.read(clockProvider)()),
    );
    await ref.read(remindersProvider).schedule(next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    final notifier = ref.read(themeSettingsProvider.notifier);
    final profile = ref.watch(athleteProfileProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _SectionTitle('Profilo'),
          _Group(
            children: [
              ListTile(
                leading: const Icon(Icons.sports_gymnastics_outlined),
                title: const Text('Profilo atleta'),
                subtitle: profile == null
                    ? null
                    : Text(
                        '${profile.difficulty.label} · '
                        '${trainingDaysLabel(profile.trainingDays)}',
                      ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.athleteProfile),
              ),
              ListTile(
                leading: const Icon(Icons.monitor_weight_outlined),
                title: const Text('Dati per la nutrizione'),
                subtitle: const Text('Peso, altezza, obiettivo e allergie'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.bodyData),
              ),
            ],
          ),
          const _SectionTitle('Promemoria'),
          _Group(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Promemoria di allenamento'),
                subtitle: const Text('Solo nei giorni che hai scelto'),
                value: profile?.reminder != null,
                onChanged: profile == null
                    ? null
                    : (on) => _updateReminder(
                        ref,
                        on ? const ReminderTime(18, 0) : null,
                      ),
              ),
              if (profile?.reminder != null)
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Orario'),
                  trailing: Text(
                    profile!.reminder!.label,
                    style: theme.textTheme.titleMedium,
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: profile.reminder!.hour,
                        minute: profile.reminder!.minute,
                      ),
                      helpText: 'Orario del promemoria',
                    );
                    if (picked != null) {
                      await _updateReminder(
                        ref,
                        ReminderTime(picked.hour, picked.minute),
                      );
                    }
                  },
                ),
            ],
          ),
          const _SectionTitle('Aspetto'),
          _Group(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Tema', style: theme.textTheme.titleMedium),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SlidingSegmented<ThemeMode>(
                  semanticsLabel: 'Tema',
                  segments: const [
                    (value: ThemeMode.system, label: 'Sistema'),
                    (value: ThemeMode.light, label: 'Chiaro'),
                    (value: ThemeMode.dark, label: 'Scuro'),
                  ],
                  selected: settings.mode,
                  onChanged: notifier.setMode,
                ),
              ),
              SwitchListTile(
                title: const Text('Colori dal tuo sfondo'),
                subtitle: const Text(
                  'Usa i colori del telefono invece del corallo di Discipline. '
                  'Solo su Android 12 o successivi.',
                ),
                value: settings.useDynamicColor,
                onChanged: notifier.setUseDynamicColor,
              ),
            ],
          ),
          const _SectionTitle('I tuoi dati'),
          _Group(
            children: [
              const ListTile(
                leading: Icon(Icons.phone_android),
                title: Text('Salvati sul telefono'),
                subtitle: Text(
                  'Allenamenti, streak e diario restano qui. Nessun dato '
                  'viene venduto o condiviso.',
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Elimina tutti i dati',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () => _confirmWipe(context, ref),
              ),
            ],
          ),
          const BackupSection(),
          const _SectionTitle('Informazioni'),
          _Group(
            children: [
              const ListTile(
                leading: Icon(Icons.favorite_outline),
                title: Text('Libera e gratuita'),
                subtitle: Text(
                  'Discipline è open source (GPL-3.0): niente pubblicità, '
                  'abbonamenti o tracciamento. Sviluppata con l\'aiuto '
                  'dell\'AI (Claude).',
                ),
              ),
              const ListTile(
                leading: Icon(Icons.code),
                title: Text('Codice sorgente'),
                subtitle: Text('github.com/owaismounir206-art/Discipline'),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Licenze open source'),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Discipline',
                  applicationLegalese:
                      'Copyright (C) 2026 Discipline contributors\n'
                      'Distribuita con licenza GNU GPL v3 o successiva.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmWipe(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare tutti i dati?'),
        content: const Text(
          'Profilo, allenamenti, streak e diario verranno cancellati da '
          'questo telefono. Non si può annullare.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(databaseProvider).wipe();
      if (context.mounted) context.go(Routes.welcome);
    }
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
        borderRadius: BorderRadius.circular(DisciplineRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Gruppo di impostazioni riusabile da altre sezioni (es. account).
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _SectionTitle(title),
      _Group(children: children),
    ],
  );
}
