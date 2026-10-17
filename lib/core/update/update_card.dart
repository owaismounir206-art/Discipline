// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/motion.dart';
import '../widgets/common.dart';
import 'update_checker.dart';

/// Apre un link nel browser. Nei test si sostituisce.
final openLinkProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Avviso in "Oggi" quando esce una versione nuova: scende dall'alto.
class UpdateCard extends ConsumerWidget {
  const UpdateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final release = ref.watch(availableUpdateProvider).value;
    final duration = DisciplineMotion.of(context, DisciplineMotion.long);
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: DisciplineMotion.decelerate,
      switchOutCurve: DisciplineMotion.accelerate,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.topCenter,
        child: FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, -0.3),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
      ),
      child: release == null
          ? const SizedBox(key: ValueKey('none'), width: double.infinity)
          : _Card(key: ValueKey(release.version), release: release),
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card({super.key, required this.release});

  final Release release;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final notes = release.highlights;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: DisciplineCard(
        color: scheme.surfaceContainerHighest,
        semanticsLabel: 'Aggiornamento disponibile',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Row(
              spacing: 12,
              children: [
                IconBadge(
                  icon: Icons.system_update,
                  size: 44,
                  radius: 14,
                  background: scheme.primary,
                  foreground: scheme.onPrimary,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discipline ${release.version} è pronta',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'Tu hai la $appVersion · i tuoi dati restano',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (notes.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  for (final n in notes)
                    Text(
                      '• $n',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(updateRepositoryProvider)
                        .dismiss(release.version),
                    child: const Text('Più tardi'),
                  ),
                ),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Scarica'),
                    onPressed: () => ref.read(openLinkProvider)(
                      release.downloadFor(Theme.of(context).platform),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Riquadro delle impostazioni: interruttore e controllo manuale.
class UpdateSettingsTiles extends ConsumerStatefulWidget {
  const UpdateSettingsTiles({super.key});

  @override
  ConsumerState<UpdateSettingsTiles> createState() =>
      _UpdateSettingsTilesState();
}

class _UpdateSettingsTilesState extends ConsumerState<UpdateSettingsTiles> {
  var _checking = false;

  Future<void> _checkNow() async {
    setState(() => _checking = true);
    Release? release;
    try {
      release = await ref.read(updateRepositoryProvider).check(force: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is UpdateCheckException
                ? 'Non riesco a controllare: sei offline?'
                : 'Non riesco a controllare: riprova tra poco.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _checking = false);
    ref.invalidate(availableUpdateProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (release == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Hai già l\'ultima versione.')),
      );
      return;
    }
    // Letti ora: l'avviso può restare visibile dopo aver chiuso le
    // impostazioni, quando questa schermata non esiste più.
    final open = ref.read(openLinkProvider);
    final link = release.downloadFor(Theme.of(context).platform);
    messenger.showSnackBar(
      SnackBar(
        content: Text('È uscita la versione ${release.version}.'),
        persist: false,
        action: SnackBarAction(label: 'Scarica', onPressed: () => open(link)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(updateSettingsProvider).value?.enabled ?? true;
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.system_update_outlined),
          title: const Text('Controlla gli aggiornamenti'),
          subtitle: const Text(
            'Una volta al giorno chiede a GitHub se c\'è una versione nuova. '
            'Non invia nessun tuo dato.',
          ),
          value: enabled,
          onChanged: (on) => ref.read(updateRepositoryProvider).setEnabled(on),
        ),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('Controlla ora'),
          subtitle: const Text('Versione installata: $appVersion'),
          trailing: _checking
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: _checking ? null : _checkNow,
        ),
      ],
    );
  }
}
