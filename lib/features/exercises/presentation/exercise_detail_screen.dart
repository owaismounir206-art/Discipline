// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/data/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/discipline_theme.dart';
import '../../../core/utils/local_date.dart';
import '../../../core/widgets/common.dart';
import '../../profile/data/profile_repository.dart';
import '../domain/catalog.dart';
import '../domain/progression.dart';

/// Dettaglio di un esercizio: come si esegue, errori comuni, catena.
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = Catalog.byId(exerciseId);
    if (exercise == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Esercizio non trovato')),
      );
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chain = Catalog.chain(exercise.chain);
    final progress = ref.watch(chainProgressProvider).value?[exercise.chain];
    final isCurrent = progress?.position == exercise.position;

    return Scaffold(
      appBar: AppBar(title: Text(exercise.chain.label)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Semantics(
              header: true,
              child: Text(
                exercise.name,
                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 28),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Tag(exercise.muscleGroup.label),
                _Tag(exercise.targetLabel),
                _Tag('Variante ${exercise.position + 1} di ${chain.length}'),
              ],
            ),
            const SizedBox(height: 16),
            DisciplineCard(
              color: scheme.primaryContainer,
              radius: DisciplineRadii.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Text(
                    'Come si esegue',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  for (var i = 0; i < exercise.instructions.length; i++)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            exercise.instructions[i],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            DisciplineCard(
              radius: DisciplineRadii.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text('Errori comuni', style: theme.textTheme.titleMedium),
                  for (final m in exercise.mistakes)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 20,
                          color: scheme.primary,
                        ),
                        Expanded(
                          child: Text(m, style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionTitle(
              'La catena',
              trailing: ChainDots(
                length: chain.length,
                position: exercise.position,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Lavora nell\'intervallo ${exercise.targetLabel}. Quando chiudi '
              'tutte le serie al massimo per 2 sessioni di fila, Discipline ti '
              'propone la variante successiva.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              spacing: 8,
              children: [
                if (exercise.position > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Più facile'),
                      onPressed: () => context.pushReplacement(
                        Routes.exercise(chain[exercise.position - 1].id),
                      ),
                    ),
                  ),
                if (exercise.position < chain.length - 1)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Più difficile'),
                      onPressed: () => context.pushReplacement(
                        Routes.exercise(chain[exercise.position + 1].id),
                      ),
                    ),
                  ),
              ],
            ),
            if (progress != null && !isCurrent) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  final repo = ref.read(profileRepositoryProvider);
                  final chains = {...await repo.loadChains()};
                  chains[exercise.chain] = changePosition(
                    chains[exercise.chain]!,
                    exercise.position,
                    LocalDate.fromDateTime(ref.read(clockProvider)()),
                  );
                  await repo.saveChains(chains);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '«${exercise.name}» è la tua nuova variante',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Usa questa variante'),
              ),
            ] else if (isCurrent) ...[
              const SizedBox(height: 12),
              Center(
                child: Chip(
                  avatar: Icon(Icons.check, color: scheme.primary),
                  label: const Text('È la tua variante attuale'),
                  side: BorderSide.none,
                  backgroundColor: scheme.primaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(DisciplineRadii.chip),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
