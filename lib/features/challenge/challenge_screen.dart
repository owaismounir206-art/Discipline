// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/data/providers.dart';
import '../../core/router/routes.dart';
import '../../core/services/share.dart';
import '../../core/theme/ritmo_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/tab_scaffold.dart';
import '../account/data/account_providers.dart';
import '../account/domain/backend.dart';
import 'data/challenge_repository.dart';
import 'domain/challenge.dart';
import 'presentation/invite_card.dart';

/// Scheda "Sfida": push-up in diretta con gli amici (design "SfidaLobby").
class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key});

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  var _mode = ChallengeMode.headToHead;
  var _busy = false;

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _invite() async {
    final backend = ref.read(backendProvider);
    final account = ref.read(accountProvider).value;
    if (!backend.isConfigured) {
      _snack('Per invitare gli amici serve un server: vedi Impostazioni.');
      return;
    }
    if (account == null) {
      await context.push(Routes.login);
      return;
    }
    await ref.read(shareTextProvider)(
      inviteMessage(account.name, account.friendCode),
    );
  }

  Future<void> _challenge(Friend friend) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final id = await ref
          .read(backendProvider)
          .createRoom(_mode, friendId: friend.id);
      if (mounted) await context.push(Routes.live(id));
    } on BackendException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _practice() async {
    final id = await ref.read(practiceBackendProvider).createRoom(_mode);
    if (mounted) await context.push('${Routes.live(id)}?solo=1');
  }

  Future<void> _nudge(Friend friend) async {
    final account = ref.read(accountProvider).value;
    await ref.read(shareTextProvider)(
      'Ciao ${friend.name}! Ti va una sfida di push-up su Ritmo? '
      'Apri l\'app, ti aspetto 💪'
      '${account == null ? '' : ' (${account.name})'}',
    );
  }

  Future<void> _addFriend() async {
    final code = await showDialog<String>(
      context: context,
      builder: (context) => const _FriendCodeDialog(),
    );
    if (code == null || code.trim().isEmpty) return;
    try {
      final friend = await ref.read(backendProvider).addFriend(code);
      _snack('${friend.name} è tra i tuoi amici');
    } on BackendException catch (e) {
      _snack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final backend = ref.watch(backendProvider);
    final account = ref.watch(accountProvider).value;
    final friends = ref.watch(friendsProvider).value ?? const <Friend>[];
    final history = ref.watch(challengeHistoryProvider).value ?? const [];
    final now = ref.watch(clockProvider)();
    final last = history.where((r) => r.friendId != null).firstOrNull;

    return TabScaffold(
      header: ScreenHeader(
        title: 'Sfida',
        subtitle: 'Push-up in diretta con i tuoi amici',
        actions: [
          HeaderPillButton(
            icon: Icons.add,
            label: 'Invita',
            onPressed: _invite,
          ),
        ],
      ),
      children: [
        const InviteCard(),
        RitmoCard(
          color: scheme.surfaceContainer,
          radius: RitmoRadii.cardLarge,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 4),
                child: SectionTitle('Modalità'),
              ),
              for (final m in ChallengeMode.values)
                _ModeOption(
                  mode: m,
                  selected: m == _mode,
                  onTap: () => setState(() => _mode = m),
                ),
            ],
          ),
        ),
        const SectionTitle('Amici'),
        if (!backend.isConfigured)
          const _InfoCard(
            icon: Icons.cloud_off_outlined,
            text:
                'Le sfide con gli amici hanno bisogno di un server, che in '
                'questa versione non è collegato. Intanto puoi allenarti in '
                'modalità sfida da solo.',
          )
        else if (account == null)
          _InfoCard(
            icon: Icons.group_outlined,
            text: 'Accedi per aggiungere amici e sfidarli in diretta.',
            action: FilledButton(
              onPressed: () => context.push(Routes.login),
              child: const Text('Accedi'),
            ),
          )
        else ...[
          if (friends.isEmpty)
            Text(
              'Non hai ancora amici su Ritmo: invitali o aggiungi il loro '
              'codice. Il tuo è ${account.friendCode}.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          for (final f in friends)
            _FriendRow(
              friend: f,
              now: now,
              onChallenge: _busy ? null : () => _challenge(f),
              onNudge: () => _nudge(f),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.person_add_alt_outlined),
              label: const Text('Aggiungi con un codice'),
              onPressed: _addFriend,
            ),
          ),
        ],
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          icon: const Icon(Icons.timer_outlined),
          label: Text('Allenati da solo · ${_mode.label}'),
          onPressed: _practice,
        ),
        if (last != null) _LastChallengeCard(last: last, history: history),
      ],
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ChallengeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: '${mode.label}, ${mode.description}',
      excludeSemantics: true,
      child: Material(
        color: selected ? scheme.surface : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                spacing: 14,
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                    size: 22,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          mode.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.friend,
    required this.now,
    required this.onChallenge,
    required this.onNudge,
  });

  final Friend friend;
  final DateTime now;
  final VoidCallback? onChallenge;
  final VoidCallback onNudge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final online = friend.presence == Presence.online;
    final training = friend.presence == Presence.training;
    final dot = switch (friend.presence) {
      Presence.online => const Color(0xFF2E7D32),
      Presence.training => const Color(0xFFC77700),
      Presence.offline => null,
    };
    const buttonSize = Size(0, 48);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        spacing: 12,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: dot == null
                    ? scheme.surfaceContainerHighest
                    : online
                    ? scheme.secondary
                    : scheme.tertiary,
                foregroundColor: dot == null
                    ? scheme.onSurfaceVariant
                    : Colors.white,
                child: Text(
                  friend.initial,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (dot != null)
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  friend.statusLine(now),
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (online)
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: buttonSize),
              onPressed: onChallenge,
              child: Text('Sfida', semanticsLabel: 'Sfida ${friend.name}'),
            )
          else if (training)
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: buttonSize),
              onPressed: onChallenge,
              child: Text('Sfida', semanticsLabel: 'Sfida ${friend.name}'),
            )
          else
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: buttonSize,
                foregroundColor: scheme.onSurfaceVariant,
              ),
              onPressed: onNudge,
              child: Text('Avvisa', semanticsLabel: 'Avvisa ${friend.name}'),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RitmoCard(
      color: scheme.surfaceContainerLow,
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Icon(icon, color: scheme.primary),
              Expanded(child: Text(text)),
            ],
          ),
          ?action,
        ],
      ),
    );
  }
}

class _LastChallengeCard extends StatelessWidget {
  const _LastChallengeCard({required this.last, required this.history});

  final ChallengeResult last;
  final List<ChallengeResult> history;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final balance = balanceAgainst(history, last.friendId!);
    return RitmoCard(
      color: scheme.tertiaryContainer,
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        spacing: 12,
        children: [
          Icon(Icons.emoji_events_outlined, color: scheme.onTertiaryContainer),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ultima sfida con ${last.friendName}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.onTertiaryContainer,
                  ),
                ),
                Text(
                  '${last.summary} · bilancio '
                  '${balance.wins}–${balance.losses}',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendCodeDialog extends StatefulWidget {
  const _FriendCodeDialog();

  @override
  State<_FriendCodeDialog> createState() => _FriendCodeDialogState();
}

class _FriendCodeDialogState extends State<_FriendCodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Aggiungi un amico'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      textCapitalization: TextCapitalization.characters,
      maxLength: 7,
      decoration: const InputDecoration(
        labelText: 'Codice amico',
        hintText: 'Es. K7P2QX',
        border: OutlineInputBorder(),
      ),
      onSubmitted: (v) => Navigator.pop(context, v),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annulla'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('Aggiungi'),
      ),
    ],
  );
}
