// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../timer/domain/interval.dart';
import '../domain/catalog.dart';
import '../domain/exercise.dart';
import '../domain/skill_guide.dart';
import 'exercise_figure.dart';

List<Exercise> _steps(SkillGuide g) => [
  for (final id in g.steps) ?Catalog.byId(id),
];

/// "Impara le skill": i principi e l'elenco delle skill.
class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Impara le skill')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              'Handstand, planche, front lever, muscle-up: si imparano tutte '
              'allo stesso modo. Prima le regole, poi la strada per ognuna.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            DisciplineCard(
              color: scheme.secondaryContainer,
              semanticsLabel: 'Come imparare le skill',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Text(
                    'Le regole d\'oro',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  for (final (i, (title, text)) in skillPrinciples.indexed)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: scheme.onSecondaryContainer,
                          foregroundColor: scheme.secondaryContainer,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: scheme.onSecondaryContainer,
                                ),
                              ),
                              Text(
                                text,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SectionTitle('Le skill'),
            for (final g in skillGuides)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SkillTile(guide: g),
              ),
          ],
        ),
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile({required this.guide});

  final SkillGuide guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final steps = _steps(guide);
    return PressScale(
      child: DisciplineCard(
        onTap: () => context.push(Routes.skill(guide.id)),
        padding: const EdgeInsets.all(12),
        child: Row(
          spacing: 12,
          children: [
            if (steps.isNotEmpty)
              ExerciseFigure(
                motion: motionFor(steps.last),
                size: const Size(72, 54),
                animate: false,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(guide.name, style: theme.textTheme.titleMedium),
                  Text(
                    '${steps.length} tappe · ${guide.time}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Una skill: requisiti, tappe da scegliere, metodo, consigli ed errori.
class SkillDetailScreen extends StatefulWidget {
  const SkillDetailScreen({super.key, required this.guide});

  final SkillGuide guide;

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  /// La tappa su cui ti alleni.
  var _step = 0;

  void _train(List<Exercise> steps) {
    final current = steps[_step];
    // La tappa scelta, quella prima (per il volume) e la seguente in
    // versione leggera solo se sei già oltre metà strada.
    final ids = [
      current.id,
      if (_step > 0) steps[_step - 1].id,
      if (_step + 1 < steps.length && _step * 2 >= steps.length)
        steps[_step + 1].id,
    ];
    final config = IntervalConfig.circuit(
      ids,
      title: widget.guide.name,
      work: 20,
      rest: 90,
      rounds: 4,
    );
    context.push(Routes.timerRun(config.toQuery()));
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.guide;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final steps = _steps(g);

    Widget list(String title, List<String> items, IconData icon) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Icon(icon, size: 20, color: scheme.primary),
                Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(g.name)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            if (steps.isNotEmpty)
              Center(
                child: ExerciseFigure(
                  motion: motionFor(steps.last),
                  size: const Size(220, 150),
                ),
              ),
            Text(g.summary, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text(
              'Tempo realistico: ${g.time}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            list('Prima di iniziare', g.requires, Icons.check_circle_outline),
            const SectionTitle('Le tappe'),
            Text(
              'Tocca la tappa a cui sei arrivato: l\'allenamento della skill '
              'parte da lì.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final (i, e) in steps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PressScale(
                  child: DisciplineCard(
                    color: i == _step
                        ? scheme.primaryContainer
                        : scheme.surfaceContainer,
                    onTap: () => setState(() => _step = i),
                    semanticsLabel:
                        'Tappa ${i + 1}: ${e.name}'
                        '${i == _step ? ', scelta' : ''}',
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                    child: Row(
                      spacing: 12,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: i == _step
                              ? scheme.primary
                              : scheme.surfaceContainerHighest,
                          foregroundColor: i == _step
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ExerciseFigure(
                          motion: motionFor(e),
                          size: const Size(60, 44),
                          animate: false,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.name, style: theme.textTheme.titleSmall),
                              Text(
                                e.targetLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Come si fa: ${e.name}',
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => context.push(Routes.exercise(e.id)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (steps.isNotEmpty)
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: Text('Allenati su «${steps[_step].name}»'),
                onPressed: () => _train(steps),
              ),
            list('Come allenarla', g.method, Icons.event_repeat),
            list('Consigli', g.tips, Icons.lightbulb_outline),
            list('Errori comuni', g.mistakes, Icons.error_outline),
          ],
        ),
      ),
    );
  }
}
