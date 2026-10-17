// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/styles/app_style.dart';
import '../../food/data/ai_food.dart';
import '../ai_assistant.dart';
import '../../../core/feedback/ui_feedback.dart';

/// Domande che si possono fare con un tocco.
const coachIdeas = [
  'Come miglioro le trazioni?',
  'Cosa mangio dopo l\'allenamento?',
  'Mi fanno male i polsi nei push-up',
  'Come arrivo alla verticale?',
  'Non ho tempo oggi: cosa faccio in 10 minuti?',
];

/// Il coach AI: una chat che conosce il tuo livello e i tuoi valori di oggi.
/// La conversazione non viene salvata.
class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _text.text).trim();
    if (text.isEmpty || _busy) return;
    _text.clear();
    setState(() {
      _messages.add(ChatMessage.user(text));
      _busy = true;
      _error = null;
    });
    _toBottom();
    try {
      // Solo gli ultimi messaggi: bastano e restano nei limiti gratuiti.
      var history = _messages.length > 12
          ? _messages.sublist(_messages.length - 12)
          : [..._messages];
      // La storia deve iniziare con una domanda, non con una risposta.
      final firstUser = history.indexWhere((m) => m.fromUser);
      if (firstUser > 0) history = history.sublist(firstUser);
      final reply = await askCoach(
        ref.read(aiFoodServiceProvider),
        ref.read(aiContextProvider),
        history,
      );
      if (!mounted) return;
      UiFeedback.instance.play(UiSound.select);
      setState(() {
        _messages.add(ChatMessage.ai(reply));
        _busy = false;
      });
    } on AiException catch (e) {
      UiFeedback.instance.play(UiSound.error);
      if (!mounted) return;
      setState(() {
        // La domanda torna nel campo, così si può riprovare.
        _messages.removeLast();
        _text.text = text;
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      UiFeedback.instance.play(UiSound.error);
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _text.text = text;
        _busy = false;
        _error = 'Qualcosa non è andato storto: riprova.';
      });
    }
    _toBottom();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach AI'),
        actions: [
          IconButton(
            tooltip: 'Impostazioni AI',
            icon: const Icon(Icons.key_outlined),
            onPressed: () => context.push(Routes.aiSettings),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  if (_messages.isEmpty) ...[
                    Text(
                      'Chiedi qualcosa su allenamento, recupero o '
                      'alimentazione. Il coach conosce il tuo livello, le '
                      'tue varianti e cosa hai mangiato oggi (non il tuo '
                      'nome).',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final idea in coachIdeas)
                          ActionChip(
                            label: Text(idea),
                            onPressed: () => _send(idea),
                          ),
                      ],
                    ),
                  ],
                  for (final m in _messages) _Bubble(message: m),
                  if (_busy)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!,
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
              child: Row(
                spacing: 4,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Scrivi una domanda',
                      ),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: 'Invia',
                    icon: const Icon(Icons.send_rounded),
                    onPressed: _busy ? null : _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mine = message.fromUser;
    final style = AppStyle.of(context);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(style.radius),
            topRight: Radius.circular(style.radius),
            bottomLeft: Radius.circular(
              mine ? style.radius : style.smallRadius,
            ),
            bottomRight: Radius.circular(
              mine ? style.smallRadius : style.radius,
            ),
          ),
        ),
        child: SelectableText(
          // Gli asterischi del markdown non servono in una bolla.
          message.text.replaceAll('**', ''),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: mine ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
