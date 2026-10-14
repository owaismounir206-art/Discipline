// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/data/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/services/share.dart';
import '../../../core/utils/local_date.dart';
import '../../../core/widgets/common.dart';
import '../../profile/data/profile_repository.dart';
import '../../rewards/data/rewards_state.dart';
import '../domain/friend_code.dart';
import '../domain/timed.dart';

/// Sfida un amico senza server: un codice con il tuo punteggio da battere.
class FriendChallengeScreen extends ConsumerStatefulWidget {
  const FriendChallengeScreen({super.key});

  @override
  ConsumerState<FriendChallengeScreen> createState() =>
      _FriendChallengeScreenState();
}

class _FriendChallengeScreenState extends ConsumerState<FriendChallengeScreen> {
  final _code = TextEditingController();
  FriendChallenge? _decoded;
  var _touched = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _onCode(String text) => setState(() {
    _touched = text.trim().isNotEmpty;
    _decoded = decodeFriendChallenge(text);
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final best = ref.watch(bestTimedProvider);
    final name = ref.watch(athleteProfileProvider).value?.name ?? '';
    final today = LocalDate.fromDateTime(ref.watch(clockProvider)());
    final decoded = _decoded;

    return Scaffold(
      appBar: AppBar(title: const Text('Sfida un amico')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              'Niente account e niente server: mandi un codice con il tuo '
              'punteggio, l\'amico fa la stessa sfida e vede chi ha vinto.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle('Hai ricevuto un codice?'),
            const SizedBox(height: 10),
            TextField(
              controller: _code,
              onChanged: _onCode,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Codice della sfida',
                hintText: 'Es. 0H2K-5Z9A-…',
                border: const OutlineInputBorder(),
                errorText: _touched && decoded == null
                    ? 'Codice non valido: controlla di averlo copiato tutto'
                    : null,
              ),
            ),
            if (decoded != null) ...[
              const SizedBox(height: 12),
              RitmoCard(
                color: scheme.secondaryContainer,
                radius: 24,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Text(
                      '${decoded.name.isEmpty ? 'Un amico' : decoded.name} ti sfida',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    Text(
                      '${decoded.mode.label}: ${decoded.scoreLabel}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      icon: const Icon(Icons.bolt),
                      label: const Text('Accetta la sfida'),
                      onPressed: () => context.push(
                        Routes.timed(decoded.mode.name, code: _code.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            const SectionTitle('Lancia una sfida'),
            const SizedBox(height: 4),
            Text(
              'Si parte dal tuo record. Prima fai la sfida, poi manda il codice.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            for (final mode in TimedMode.values) ...[
              _ModeRow(
                mode: mode,
                best: best[mode],
                onShare: best[mode] == null
                    ? null
                    : () => ref.read(shareTextProvider)(
                        friendChallengeMessage(
                          FriendChallenge(
                            mode: mode,
                            score: best[mode]!,
                            name: name,
                            date: today,
                          ),
                        ),
                      ),
                onPlay: () => context.push(Routes.timed(mode.name)),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.mode,
    required this.best,
    required this.onShare,
    required this.onPlay,
  });

  final TimedMode mode;
  final int? best;
  final VoidCallback? onShare;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return RitmoCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(mode.label, style: theme.textTheme.titleMedium),
                Text(
                  best == null
                      ? 'Nessun record ancora'
                      : 'Il tuo record: ${scoreText(mode, best!)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onShare != null)
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Manda'),
              onPressed: onShare,
            )
          else
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: onPlay,
              child: const Text('Fai la sfida'),
            ),
        ],
      ),
    );
  }
}
