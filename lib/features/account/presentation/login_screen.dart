// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../profile/data/profile_repository.dart';
import '../data/account_providers.dart';
import '../domain/backend.dart';

/// Accesso o registrazione (serve solo per amici, sfide e backup).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _register = false;
  var _busy = false;
  var _hidePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.text = ref.read(athleteProfileProvider).value?.name ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final backend = ref.read(backendProvider);
    try {
      if (_register) {
        final ready = await backend.signUp(
          email: _email.text,
          password: _password.text,
          name: _name.text,
        );
        if (!ready) {
          setState(() {
            _busy = false;
            _register = false;
            _error =
                'Ti abbiamo mandato un\'email: conferma l\'indirizzo e poi '
                'accedi qui.';
          });
          return;
        }
      } else {
        await backend.signIn(email: _email.text, password: _password.text);
      }
      if (mounted) context.pop();
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
    final scheme = theme.colorScheme;
    final configured = ref.watch(backendProvider).isConfigured;

    return Scaffold(
      appBar: AppBar(title: Text(_register ? 'Crea un account' : 'Accedi')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(
                'L\'account serve solo per sfidare gli amici e salvare una '
                'copia dei dati. Allenamenti, streak e diario funzionano '
                'anche senza.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (!configured)
                Card(
                  color: scheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Questa versione non è collegata a un server. Chi '
                      'compila l\'app può attivarlo seguendo docs/SERVER.md.',
                      style: TextStyle(color: scheme.onTertiaryContainer),
                    ),
                  ),
                )
              else ...[
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: false, label: Text('Accedi')),
                    ButtonSegment(value: true, label: Text('Registrati')),
                  ],
                  selected: {_register},
                  onSelectionChanged: (s) => setState(() {
                    _register = s.first;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 16),
                if (_register) ...[
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 40,
                    decoration: const InputDecoration(
                      labelText: 'Nome che vedranno gli amici',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Scrivi un nome (anche solo un soprannome)'
                        : null,
                  ),
                  const SizedBox(height: 8),
                ],
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => RegExp(r'^\S+@\S+\.\S+$').hasMatch(v ?? '')
                      ? null
                      : 'Email non valida',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: _hidePassword,
                  autofillHints: [
                    _register
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: _register ? 'Almeno 8 caratteri' : null,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: _hidePassword
                          ? 'Mostra password'
                          : 'Nascondi password',
                      icon: Icon(
                        _hidePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                  validator: (v) =>
                      (v ?? '').length < 8 ? 'Almeno 8 caratteri' : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(_error!, style: TextStyle(color: scheme.error)),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : Text(_register ? 'Crea account' : 'Accedi'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sul server salviamo solo email, nome, codice amico, '
                  'livello e le sfide. Puoi cancellare tutto dalle '
                  'impostazioni.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
