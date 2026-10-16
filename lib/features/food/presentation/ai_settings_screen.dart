// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/update/update_card.dart' show openLinkProvider;
import '../../../core/widgets/motion_widgets.dart';
import '../data/ai_food.dart';
import '../../../core/feedback/ui_feedback.dart';

/// Chiave API personale per Groq o Google AI Studio. Resta nel portachiavi
/// del telefono: non va nei backup e non la vede nessun altro.
class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  final _key = TextEditingController();
  AiProvider _provider = AiProvider.groq;
  String? _model;
  List<String> _models = const [];
  bool _hasKey = false;
  bool _busy = false;
  bool _hidden = true;
  String? _message;

  AiFoodService get _service => ref.read(aiFoodServiceProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _service.settings();
    final provider = s.provider ?? AiProvider.groq;
    final key = await _service.key(provider);
    if (!mounted) return;
    setState(() {
      _provider = provider;
      _model = s.model;
      _hasKey = key != null;
      _key.text = '';
    });
  }

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _switch(AiProvider p) async {
    final key = await _service.key(p);
    if (!mounted) return;
    setState(() {
      _provider = p;
      _hasKey = key != null;
      _models = const [];
      _model = null;
      _message = null;
      _key.clear();
    });
  }

  /// Salva la chiave (se scritta) e la prova scaricando i modelli.
  Future<void> _test() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final typed = _key.text.trim();
    final key = typed.isNotEmpty ? typed : await _service.key(_provider);
    if (key == null) {
      setState(() {
        _busy = false;
        _message = 'Incolla prima la chiave.';
      });
      return;
    }
    try {
      final models = await _service.models(_provider, key);
      final model = _model != null && models.contains(_model)
          ? _model!
          : AiFoodService.pickModel(_provider, models);
      await _service.saveKey(_provider, key);
      await _service.saveSettings(
        AiSettings(provider: _provider, model: model),
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _hasKey = true;
        _models = models;
        _model = model;
        _key.clear();
        _message = 'Chiave valida: ora puoi scrivere cosa hai mangiato.';
      });
    } on AiException catch (e) {
      UiFeedback.instance.play(UiSound.error);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = e.message;
      });
    }
  }

  Future<void> _remove() async {
    await _service.saveKey(_provider, null);
    final s = await _service.settings();
    if (s.provider == _provider) {
      await _service.saveSettings(const AiSettings());
    }
    if (!mounted) return;
    setState(() {
      _hasKey = false;
      _models = const [];
      _model = null;
      _message = 'Chiave cancellata da questo telefono.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('AI per il diario del cibo')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              'Scrivi "due uova e una fetta di pane" e l\'AI mette gli '
              'alimenti nel diario: li controlli prima di salvarli. Serve una '
              'chiave tua, gratuita: Discipline non ne ha e non paga nulla.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SlidingSegmented<AiProvider>(
              semanticsLabel: 'Servizio AI',
              segments: [
                for (final p in AiProvider.values) (value: p, label: p.label),
              ],
              selected: _provider,
              onChanged: _switch,
            ),
            const SizedBox(height: 16),
            Text(
              '1. Crea una chiave gratuita su ${_provider.keyHint} (serve un '
              'account ${_provider == AiProvider.groq ? 'Groq' : 'Google'}).',
              style: theme.textTheme.bodyMedium,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: Text('Apri ${_provider.keyHint}'),
                onPressed: () =>
                    ref.read(openLinkProvider)(Uri.parse(_provider.keyUrl)),
              ),
            ),
            Text(
              '2. Incollala qui e tocca "Prova la chiave".',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _key,
              obscureText: _hidden,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: _hasKey
                    ? 'Chiave salvata (scrivine una nuova per cambiarla)'
                    : 'Chiave API',
                suffixIcon: IconButton(
                  tooltip: _hidden ? 'Mostra' : 'Nascondi',
                  icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _hidden = !_hidden),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.key),
              label: const Text('Prova la chiave'),
              onPressed: _busy ? null : _test,
            ),
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(
                _message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.primary,
                ),
              ),
            ],
            if (_models.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _model,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Modello'),
                items: [
                  for (final m in _models)
                    DropdownMenuItem(value: m, child: Text(m)),
                ],
                onChanged: (m) async {
                  if (m == null) return;
                  setState(() => _model = m);
                  await _service.saveSettings(
                    AiSettings(provider: _provider, model: m),
                  );
                },
              ),
            ],
            if (_hasKey) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                icon: Icon(Icons.delete_outline, color: scheme.error),
                label: Text(
                  'Cancella la chiave',
                  style: TextStyle(color: scheme.error),
                ),
                onPressed: _remove,
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Privacy: quando usi l\'AI il testo che scrivi (o la foto del '
              'piatto) viene inviato a ${_provider.label} con la tua chiave, '
              'secondo le loro condizioni (i piani gratuiti possono usare i '
              'dati per migliorare i modelli). Il coach e "Cosa cucino?" '
              'ricevono anche livello, età, peso, altezza, obiettivo, dieta, '
              'allergie e i valori di oggi, mai il tuo nome. '
              'La chiave resta nel portachiavi protetto del telefono e non '
              'finisce nei backup.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
