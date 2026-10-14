// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/data/providers.dart';
import '../../core/router/routes.dart';
import '../account/data/account_providers.dart';
import '../account/domain/backend.dart';
import 'settings_screen.dart';

/// Account, codice amico e copia dei dati sul server.
class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String done,
  ) async {
    try {
      await action();
      if (context.mounted) _snack(context, done);
    } on BackendException catch (e) {
      if (context.mounted) _snack(context, e.message);
    } on FormatException catch (e) {
      if (context.mounted) _snack(context, e.message);
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(backendProvider);
    final account = ref.watch(accountProvider).value;
    final db = ref.read(databaseProvider);

    if (!backend.isConfigured) {
      return const SettingsGroup(
        title: 'Account e amici',
        children: [
          ListTile(
            leading: Icon(Icons.cloud_off_outlined),
            title: Text('Sfide online non attive'),
            subtitle: Text(
              'Questa versione non è collegata a un server: puoi allenarti '
              'in modalità sfida da solo. Per attivarle vedi docs/SERVER.md.',
            ),
          ),
        ],
      );
    }

    if (account == null) {
      return SettingsGroup(
        title: 'Account e amici',
        children: [
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Accedi o registrati'),
            subtitle: const Text(
              'Per sfidare gli amici e salvare una copia dei tuoi dati',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.login),
          ),
        ],
      );
    }

    return SettingsGroup(
      title: 'Account e amici',
      children: [
        ListTile(
          leading: const Icon(Icons.account_circle_outlined),
          title: Text(account.name),
          subtitle: Text(account.email),
        ),
        ListTile(
          leading: const Icon(Icons.badge_outlined),
          title: Text('Il tuo codice amico: ${account.friendCode}'),
          subtitle: const Text('Tocca per copiarlo'),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: account.friendCode));
            if (context.mounted) _snack(context, 'Codice copiato');
          },
        ),
        ListTile(
          leading: const Icon(Icons.cloud_upload_outlined),
          title: const Text('Salva una copia sul server'),
          subtitle: const Text('Profilo, allenamenti, diario e sfide'),
          onTap: () => _run(
            context,
            () async => backend.uploadBackup(await db.exportAll()),
            'Copia salvata',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_download_outlined),
          title: const Text('Ripristina la copia'),
          subtitle: const Text('Sostituisce i dati di questo telefono'),
          onTap: () async {
            final ok = await _confirm(
              context,
              title: 'Ripristinare la copia?',
              message:
                  'I dati di questo telefono verranno sostituiti con quelli '
                  'salvati sul server.',
              action: 'Ripristina',
            );
            if (!ok || !context.mounted) return;
            await _run(context, () async {
              final data = await backend.downloadBackup();
              if (data == null) {
                throw const BackendException(
                  'Non c\'è ancora nessuna copia salvata.',
                );
              }
              await db.importAll(data);
            }, 'Dati ripristinati');
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Esci'),
          onTap: () => _run(context, backend.signOut, 'Sei uscito'),
        ),
        ListTile(
          leading: Icon(
            Icons.person_remove_outlined,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(
            'Cancella l\'account',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          subtitle: const Text(
            'Dal server: account, amici, sfide e copia. I dati sul telefono '
            'restano.',
          ),
          onTap: () async {
            final ok = await _confirm(
              context,
              title: 'Cancellare l\'account?',
              message:
                  'Account, amicizie, sfide e copia verranno cancellati dal '
                  'server. Non si può annullare.',
              action: 'Cancella',
            );
            if (ok && context.mounted) {
              await _run(context, backend.deleteAccount, 'Account cancellato');
            }
          },
        ),
      ],
    );
  }
}
