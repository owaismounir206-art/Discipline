// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/data/providers.dart';
import '../../core/utils/local_date.dart';
import 'settings_screen.dart';

/// Salva e apre i file di backup (nessun server: il file è tuo).
abstract interface class BackupFiles {
  /// Crea il file e lo passa alle app del telefono (Drive, email...).
  Future<void> export(String fileName, String content);

  /// Fa scegliere un file; null se annullato.
  Future<String?> pick();
}

class DeviceBackupFiles implements BackupFiles {
  @override
  Future<void> export(String fileName, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Backup di Discipline',
      ),
    );
  }

  @override
  Future<String?> pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    return utf8.decode(await file.readAsBytes());
  }
}

final backupFilesProvider = Provider<BackupFiles>((ref) => DeviceBackupFiles());

/// Sezione delle impostazioni: esporta e importa tutti i dati.
class BackupSection extends ConsumerWidget {
  const BackupSection({super.key});

  void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final files = ref.read(backupFilesProvider);

    return SettingsGroup(
      title: 'Copia dei dati',
      children: [
        ListTile(
          leading: const Icon(Icons.file_upload_outlined),
          title: const Text('Esporta in un file'),
          subtitle: const Text(
            'Salvalo dove vuoi: Drive, email, un messaggio a te stesso',
          ),
          onTap: () async {
            final data = await db.exportAll();
            final today = LocalDate.fromDateTime(ref.read(clockProvider)());
            await files.export(
              'discipline-backup-${today.key}.json',
              const JsonEncoder.withIndent(' ').convert(data),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_download_outlined),
          title: const Text('Importa da un file'),
          subtitle: const Text('Sostituisce i dati di questo telefono'),
          onTap: () async {
            final text = await files.pick();
            if (text == null || !context.mounted) return;
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Importare il backup?'),
                content: const Text(
                  'I dati di questo telefono verranno sostituiti con quelli '
                  'del file.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annulla'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Importa'),
                  ),
                ],
              ),
            );
            if (ok != true) return;
            try {
              final data = jsonDecode(text);
              if (data is! Map) throw const FormatException();
              await db.importAll(data.cast<String, Object?>());
              if (context.mounted) _snack(context, 'Dati importati');
            } on FormatException {
              if (context.mounted) {
                _snack(context, 'Questo file non è un backup di Discipline.');
              }
            }
          },
        ),
      ],
    );
  }
}
