// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/common.dart';
import '../../food/data/ai_food.dart';
import '../ai_assistant.dart';
import '../../../core/feedback/ui_feedback.dart';

/// "Cosa cucino?": l'AI propone una ricetta per i valori che mancano oggi.
class KitchenScreen extends ConsumerStatefulWidget {
  const KitchenScreen({super.key});

  @override
  ConsumerState<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends ConsumerState<KitchenScreen> {
  final _text = TextEditingController();
  AiRecipe? _recipe;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final recipe = await suggestRecipe(
        ref.read(aiFoodServiceProvider),
        ref.read(aiContextProvider),
        _text.text,
      );
      if (!mounted) return;
      setState(() {
        _recipe = recipe;
        _busy = false;
      });
    } on AiException catch (e) {
      UiFeedback.instance.play(UiSound.error);
      if (!mounted) return;
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
    final recipe = _recipe;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cosa cucino?'),
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              'Una ricetta per il prossimo pasto, pensata per le calorie e '
              'le proteine che ti mancano oggi, la tua dieta e le tue '
              'allergie.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Cosa hai in casa? (facoltativo)',
                hintText: 'Es. pollo, zucchine, riso',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                recipe == null ? 'Proponi una ricetta' : 'Un\'altra idea',
              ),
              onPressed: _busy ? null : _ask,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
            if (recipe != null) ...[
              const SizedBox(height: 16),
              DisciplineCard(
                color: scheme.secondaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      recipe.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    Text(
                      [
                        if (recipe.minutes != null) '${recipe.minutes} min',
                        '${recipe.total.kcal.round()} kcal',
                        'P ${recipe.total.protein.round()} g',
                        'C ${recipe.total.carbs.round()} g',
                        'G ${recipe.total.fat.round()} g',
                      ].join(' · '),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    if (recipe.why != null)
                      Text(
                        recipe.why!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                  ],
                ),
              ),
              const SectionTitle('Ingredienti (1 porzione)'),
              for (final i in recipe.ingredients)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(i.food.name),
                  trailing: Text('${i.grams.round()} g'),
                ),
              if (recipe.steps.isNotEmpty) ...[
                const SectionTitle('Come si prepara'),
                for (final (n, step) in recipe.steps.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          child: Text(
                            '${n + 1}',
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                        Expanded(child: Text(step)),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.soup_kitchen_outlined),
                label: const Text('Salva tra le ricette di casa'),
                // Si apre l'editor già compilato: controlli e salvi tu.
                onPressed: () =>
                    context.push(Routes.homemade, extra: recipe.toHomemade()),
              ),
              const SizedBox(height: 8),
              Text(
                'Valori stimati dall\'AI: controllali prima di salvare.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
