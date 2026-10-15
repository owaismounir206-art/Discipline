// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/common.dart';
import '../../exercises/domain/exercise.dart';
import '../../exercises/domain/placement.dart';
import '../../exercises/domain/progression.dart';
import '../../profile/data/profile_repository.dart';
import '../data/today_plan.dart';

/// Proposte di cambio variante della doppia progressione.
final suggestionsProvider = Provider<List<ProgressionSuggestion>>((ref) {
  final profile = ref.watch(athleteProfileProvider).value;
  final chains = ref.watch(chainProgressProvider).value ?? const {};
  if (profile == null) return const [];
  final today = ref.watch(todayProvider);
  return [
    for (final p in chains.values) ?suggestChange(p, profile.experience, today),
  ];
});

/// Accetta o rifiuta una proposta.
Future<void> answerSuggestion(
  WidgetRef ref,
  ProgressionSuggestion suggestion, {
  required bool accept,
}) async {
  // Letti prima delle attese: la schermata può chiudersi nel frattempo.
  final repo = ref.read(profileRepositoryProvider);
  final today = ref.read(todayProvider);
  final chains = {...await repo.loadChains()};
  final current = chains[suggestion.chain];
  if (current == null) return;
  chains[suggestion.chain] = accept
      ? changePosition(current, suggestion.to.position, today)
      // Rifiutata: si riparte a contare, così non la riproponiamo subito.
      : current.copyWith(topStreak: 0, belowStreak: 0);
  // Arrivato a diamante e trazioni: si aprono le skill.
  final profile = await repo.loadProfile();
  if (accept &&
      profile != null &&
      !chains.containsKey(ChainId.skills) &&
      skillsUnlocked(profile.difficulty, {
        for (final e in chains.entries) e.key: e.value.position,
      })) {
    chains[ChainId.skills] = ChainProgress(
      chain: ChainId.skills,
      position: 0,
      since: today,
    );
  }
  await repo.saveChains(chains);
}

class SuggestionsCard extends ConsumerWidget {
  const SuggestionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(suggestionsProvider);
    if (suggestions.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DisciplineCard(
      color: scheme.secondaryContainer,
      semanticsLabel: 'Proposte di progressione',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          for (final s in suggestions) ...[
            Row(
              spacing: 12,
              children: [
                IconBadge(
                  icon: s.direction == ChangeDirection.harder
                      ? Icons.trending_up
                      : Icons.trending_down,
                  background: scheme.surface,
                  foreground: scheme.primary,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        s.direction == ChangeDirection.harder
                            ? 'Pronto per «${s.to.name}»?'
                            : 'Facciamo un passo indietro?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                      Text(
                        s.message,
                        style: theme.textTheme.bodySmall?.copyWith(
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
                  onPressed: () => answerSuggestion(ref, s, accept: false),
                  child: const Text('Non ora'),
                ),
                FilledButton(
                  onPressed: () => answerSuggestion(ref, s, accept: true),
                  child: Text(
                    s.direction == ChangeDirection.harder ? 'Proviamo' : 'Ok',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
