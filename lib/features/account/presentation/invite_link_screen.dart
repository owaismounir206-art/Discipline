// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/routes.dart';
import '../../challenge/domain/challenge.dart';
import '../data/account_providers.dart';
import '../domain/backend.dart';

/// Aperta da un link d'invito (ritmo://app/invito/CODICE).
class InviteLinkScreen extends ConsumerStatefulWidget {
  const InviteLinkScreen({super.key, required this.code});

  final String code;

  @override
  ConsumerState<InviteLinkScreen> createState() => _InviteLinkScreenState();
}

class _InviteLinkScreenState extends ConsumerState<InviteLinkScreen> {
  var _busy = false;
  String? _error;

  Future<void> _add() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final friend = await ref.read(backendProvider).addFriend(widget.code);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${friend.name} è tra i tuoi amici')),
        );
      context.go(Routes.challenge);
    } on BackendException catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backend = ref.watch(backendProvider);
    final account = ref.watch(accountProvider).value;
    final code = normalizeCode(widget.code);

    final String message;
    final Widget? action;
    if (!backend.isConfigured) {
      message =
          'Questa versione di Ritmo non è collegata a un server, quindi non '
          'può aggiungere amici.';
      action = null;
    } else if (account == null) {
      message =
          'Accedi o registrati per aggiungere l\'amico con il codice $code.';
      action = FilledButton(
        onPressed: () => context.push(Routes.login),
        child: const Text('Accedi'),
      );
    } else {
      message = 'Vuoi aggiungere come amico chi ha il codice $code?';
      action = FilledButton(
        onPressed: _busy ? null : _add,
        child: const Text('Aggiungi amico'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Invito')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Icon(
              Icons.group_add_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (_error != null)
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ?action,
          ],
        ),
      ),
    );
  }
}
