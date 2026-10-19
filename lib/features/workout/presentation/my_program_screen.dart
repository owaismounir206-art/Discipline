// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/feedback/ui_feedback.dart';
import '../../../core/router/routes.dart';
import '../../profile/domain/athlete_profile.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../ai/ai_assistant.dart';
import '../../exercises/domain/exercise.dart';
import '../../food/data/ai_food.dart';
import '../data/program_state.dart';
import '../data/today_plan.dart';
import '../domain/my_program.dart';

/// Avvia un giorno della scheda come allenamento guidato.
void startProgramDay(BuildContext context, ProgramDay day) =>
    context.push(Routes.session, extra: (day.name, day.toPlan()));

String _setLabel(ProgramExercise e) {
  final unit = e.exercise!.measure == Measure.seconds ? 's' : 'rip.';
  return '${e.sets} × ${e.target} $unit · recupero ${e.rest} s';
}

/// "La mia scheda": scrivi la tua scheda, l'AI la trasforma negli esercizi
/// dell'app e la segui con l'allenamento guidato.
class MyProgramScreen extends ConsumerStatefulWidget {
  const MyProgramScreen({super.key});

  @override
  ConsumerState<MyProgramScreen> createState() => _MyProgramScreenState();
}

class _MyProgramScreenState extends ConsumerState<MyProgramScreen> {
  final _text = TextEditingController();
  bool _editing = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _read() async {
    if (_text.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final program = await readProgram(
        ref.read(aiFoodServiceProvider),
        ref.read(aiContextProvider),
        _text.text,
      );
      await saveProgram(ref, program);
      UiFeedback.instance.play(UiSound.success);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _editing = false;
      });
    } on AiException catch (e) {
      UiFeedback.instance.play(UiSound.error);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      UiFeedback.instance.play(UiSound.error);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Qualcosa è andato storto: riprova.';
      });
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare la scheda?'),
        content: const Text(
          'Torni agli allenamenti preparati dall\'app. Gli allenamenti già '
          'fatti restano.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok ?? false) await saveProgram(ref, null);
  }

  @override
  Widget build(BuildContext context) {
    final program = ref.watch(myProgramProvider).value;
    final aiReady = ref.watch(aiSettingsProvider).value?.provider != null;
    final editing = _editing || program == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('La mia scheda'),
        actions: [
          if (program != null && !editing) ...[
            IconButton(
              tooltip: 'Modifica la scheda',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() {
                _text.text = program.source;
                _editing = true;
              }),
            ),
            IconButton(
              tooltip: 'Elimina la scheda',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          ],
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: editing
              ? _editor(context, aiReady, canCancel: program != null)
              : _program(context, program),
        ),
      ),
    );
  }

  List<Widget> _editor(
    BuildContext context,
    bool aiReady, {
    required bool canCancel,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return [
      Text(
        'Ti alleni già con una tua scheda? Scrivila o incollala qui, come '
        'vuoi: giorni, esercizi, serie, ripetizioni, recuperi. L\'AI la '
        'trasforma negli esercizi dell\'app (con le figurine e il timer) e '
        'la segui giorno per giorno. Pesi e macchine diventano l\'esercizio '
        'a corpo libero più simile.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _text,
        minLines: 8,
        maxLines: 20,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'La tua scheda',
          alignLabelWithHint: true,
          hintText:
              'Es.\nLunedì - Spinta: push-up 4x12, dip 3x10, pike push-up '
              '3x8, plank 3x45s\nMercoledì - Tirata: trazioni 5x6, '
              'australian 3x12, curl con asciugamano 3x15\nVenerdì - '
              'Gambe: squat bulgaro 4x10, pistol assistito 3x6, '
              'polpacci 4x20',
        ),
      ),
      const SizedBox(height: 12),
      if (!aiReady)
        OutlinedButton.icon(
          icon: const Icon(Icons.key_outlined),
          label: const Text('Prima collega l\'AI (gratis)'),
          onPressed: () => context.push(Routes.aiSettings),
        )
      else
        FilledButton.icon(
          icon: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: const Text('Trasforma con l\'AI'),
          onPressed: _busy ? null : _read,
        ),
      if (canCancel) ...[
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : () => setState(() => _editing = false),
          child: const Text('Annulla'),
        ),
      ],
      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, style: TextStyle(color: scheme.error)),
      ],
    ];
  }

  List<Widget> _program(BuildContext context, MyProgram? program) {
    if (program == null) return const [];
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = ref.watch(todayProvider).weekday;
    return [
      Text(program.name, style: theme.textTheme.headlineSmall),
      const SizedBox(height: 4),
      Text(
        'Gli allenamenti della tua scheda contano per la streak e i punti, '
        'ma non spostano i tuoi percorsi: le varianti le scegli tu.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      if (program.notes.isNotEmpty) ...[
        const SizedBox(height: 12),
        DisciplineCard(
          color: scheme.secondaryContainer,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              for (final n in program.notes)
                Text(
                  '• $n',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
            ],
          ),
        ),
      ],
      for (final day in program.days) ...[
        SectionTitle(
          day.weekday == null
              ? day.name
              : '${day.name} · ${weekdayNames[day.weekday! - 1]}',
        ),
        DisciplineCard(
          color: day.weekday == today ? scheme.primaryContainer : null,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              for (final e in day.exercises)
                InkWell(
                  onTap: () => context.push(Routes.exercise(e.id)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.exercise!.name, style: theme.textTheme.titleSmall),
                      Text(
                        [
                          _setLabel(e),
                          if (e.original != null &&
                              e.original!.toLowerCase() !=
                                  e.exercise!.name.toLowerCase())
                            'nella scheda: ${e.original}',
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: Text('Inizia · circa ${day.toPlan().minutes} min'),
                onPressed: () => startProgramDay(context, day),
              ),
            ],
          ),
        ),
      ],
    ];
  }
}

/// Card di "Allenati" e "Oggi": porta alla tua scheda (o a crearla).
class MyProgramCard extends ConsumerWidget {
  const MyProgramCard({super.key, this.todayOnly = false});

  /// In "Oggi" si mostra solo se la scheda ha un giorno per oggi.
  final bool todayOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final program = ref.watch(myProgramProvider).value;
    final day = program?.dayFor(ref.watch(todayProvider).weekday);
    if (todayOnly && day == null) return const SizedBox.shrink();

    final title = switch ((program, day)) {
      (null, _) => 'La mia scheda',
      (_, final ProgramDay d) => 'Oggi dalla tua scheda: ${d.name}',
      (final MyProgram p, null) => p.name,
    };
    final subtitle = switch ((program, day)) {
      (null, _) =>
        'Hai già una tua scheda? Scrivila e l\'AI la trasforma in '
            'allenamenti guidati',
      (_, final ProgramDay d) =>
        d.exercises.map((e) => e.exercise!.name).join(', '),
      (final MyProgram p, null) =>
        '${p.days.length} ${p.days.length == 1 ? 'giorno' : 'giorni'} · '
            'tocca per sceglierne uno',
    };
    return PressScale(
      child: DisciplineCard(
        color: scheme.secondaryContainer,
        onTap: () => context.push(Routes.programs),
        child: Row(
          spacing: 14,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 36,
              color: scheme.onSecondaryContainer,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            if (day != null)
              IconButton.filled(
                tooltip: 'Inizia ${day.name}',
                icon: const Icon(Icons.play_arrow),
                onPressed: () => startProgramDay(context, day),
              )
            else
              Icon(Icons.chevron_right, color: scheme.onSecondaryContainer),
          ],
        ),
      ),
    );
  }
}
