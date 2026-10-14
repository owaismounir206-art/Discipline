// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/common.dart';
import '../../account/data/account_providers.dart';
import '../../account/domain/backend.dart';

/// Inviti a una sfida ricevuti dagli amici (in Oggi e in Sfida).
class InviteCard extends ConsumerWidget {
  const InviteCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invites = ref.watch(invitesProvider).value ?? const [];
    if (invites.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final backend = ref.read(backendProvider);

    Future<void> accept(ChallengeInvite invite) async {
      try {
        await backend.joinRoom(invite.roomId);
        if (context.mounted) await context.push(Routes.live(invite.roomId));
      } on BackendException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }

    return Column(
      spacing: 10,
      children: [
        for (final invite in invites)
          RitmoCard(
            color: scheme.secondaryContainer,
            radius: 24,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            semanticsLabel: '${invite.fromName} ti sfida',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Row(
                  spacing: 12,
                  children: [
                    Icon(Icons.bolt, color: scheme.onSecondaryContainer),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${invite.fromName} ti sfida!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSecondaryContainer,
                            ),
                          ),
                          Text(
                            '${invite.mode.label} · ${invite.mode.description}',
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => backend.leaveRoom(invite.roomId),
                      child: const Text('Non ora'),
                    ),
                    FilledButton(
                      onPressed: () => accept(invite),
                      child: const Text('Accetta'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
