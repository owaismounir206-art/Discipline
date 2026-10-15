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
import '../../exercises/domain/catalog.dart';
import '../../exercises/domain/equipment.dart';
import '../../exercises/domain/placement.dart';
import '../../streak/data/reminders.dart';
import '../../workout/domain/workout_plan.dart';
import '../data/profile_repository.dart';
import '../domain/athlete_profile.dart';

/// Profilo atleta (design "Livello"): difficoltà, esperienza, giorni e
/// test iniziale. Usato sia al primo avvio sia per modificare il profilo.
class AthleteProfileScreen extends ConsumerStatefulWidget {
  const AthleteProfileScreen({super.key, this.onboarding = false});

  final bool onboarding;

  @override
  ConsumerState<AthleteProfileScreen> createState() =>
      _AthleteProfileScreenState();
}

class _AthleteProfileScreenState extends ConsumerState<AthleteProfileScreen> {
  final _name = TextEditingController();
  var _difficulty = Difficulty.intermediate;
  var _experience = Experience.threeToTwelveMonths;
  var _days = <int>{1, 2, 4, 6};
  var _place = TrainingPlace.park;
  var _pushUps = 10;
  var _pullUps = 0;
  var _plank = 30;
  AthleteProfile? _loaded;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    ref.read(profileRepositoryProvider).loadProfile().then((p) {
      if (p == null || !mounted) return;
      setState(() {
        _loaded = p;
        _name.text = p.name;
        _difficulty = p.difficulty;
        _experience = p.experience;
        _days = {...p.trainingDays};
        _place = p.place;
        _pushUps = p.test.maxPushUps;
        _pullUps = p.test.maxPullUps;
        _plank = p.test.plankSeconds;
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final profile = AthleteProfile(
      name: _name.text.trim(),
      difficulty: _difficulty,
      experience: _experience,
      trainingDays: _days,
      place: _place,
      test: InitialTest(
        maxPushUps: _pushUps,
        maxPullUps: _pullUps,
        plankSeconds: _plank,
      ),
      // Al primo avvio proponiamo un promemoria alle 18:00, modificabile
      // nelle impostazioni.
      reminder: _loaded == null ? const ReminderTime(18, 0) : _loaded!.reminder,
    );
    final today = LocalDate.fromDateTime(ref.read(clockProvider)());
    final placement = await ref
        .read(profileRepositoryProvider)
        .saveProfile(profile, today);
    await ref.read(remindersProvider).schedule(profile);
    if (!mounted) return;
    setState(() => _saving = false);

    if (placement != null) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _PlacementSheet(placement: placement),
      );
      if (!mounted) return;
    }
    if (widget.onboarding || !context.canPop()) {
      context.go(Routes.today);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = programSummary(_difficulty, _experience, _days.length);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.onboarding,
        title: const Text('Il tuo profilo atleta'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Come ti chiami?',
                hintText: 'Il tuo nome (facoltativo)',
                filled: true,
                fillColor: scheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle('Difficoltà'),
            const SizedBox(height: 10),
            _DifficultyGrid(
              selected: _difficulty,
              onSelected: (d) => setState(() => _difficulty = d),
            ),
            const SizedBox(height: 18),
            const SectionTitle('Da quanto ti alleni'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in Experience.values)
                  ChoiceChip(
                    label: Text(e.label),
                    selected: e == _experience,
                    onSelected: (_) => setState(() => _experience = e),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            const SectionTitle('Dove ti alleni'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in TrainingPlace.values)
                  ChoiceChip(
                    label: Text(p.label),
                    selected: p == _place,
                    onSelected: (_) => setState(() => _place = p),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_place.hint}. Senza sbarra o parallele gli esercizi che le '
              'usano diventano alternative con sedie e tavolo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 18 / 13,
              ),
            ),
            const SizedBox(height: 18),
            SectionTitle(
              'Giorni di allenamento',
              trailing: Text(
                '${_days.length} '
                '${_days.length == 1 ? 'giorno' : 'giorni'} a settimana',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _DaysPicker(
              days: _days,
              onChanged: (d) => setState(() => _days = d),
            ),
            const SizedBox(height: 10),
            Text(
              'La streak conta solo questi giorni: riposare negli altri non '
              'la interrompe.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 18 / 13,
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle('Test iniziale'),
            const SizedBox(height: 4),
            Text(
              'Quante ne fai di fila, senza fermarti? Fai il test ora o '
              'inserisci una stima: potrai rifarlo quando vuoi.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 18 / 13,
              ),
            ),
            const SizedBox(height: 10),
            ValueStepper(
              label: 'Push-up',
              value: _pushUps,
              max: 200,
              onChanged: (v) => setState(() => _pushUps = v),
            ),
            const SizedBox(height: 8),
            ValueStepper(
              label: 'Trazioni',
              value: _pullUps,
              max: 100,
              onChanged: (v) => setState(() => _pullUps = v),
            ),
            const SizedBox(height: 8),
            ValueStepper(
              label: 'Plank',
              value: _plank,
              step: 5,
              max: 600,
              suffix: ' s',
              onChanged: (v) => setState(() => _plank = v),
            ),
            const SizedBox(height: 18),
            DisciplineCard(
              color: scheme.tertiaryContainer,
              radius: DisciplineRadii.card,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              semanticsLabel: 'Il tuo programma',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Text(
                    'Il tuo programma',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onTertiaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    summary.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                  Text(
                    summary.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onTertiaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                textStyle: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
              ),
              onPressed: _saving || _days.isEmpty ? null : _save,
              child: Text(
                widget.onboarding ? 'Crea il mio programma' : 'Salva',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyGrid extends StatelessWidget {
  const _DifficultyGrid({required this.selected, required this.onSelected});

  final Difficulty selected;
  final ValueChanged<Difficulty> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget card(Difficulty d) {
      final on = d == selected;
      return Semantics(
        button: true,
        selected: on,
        child: Material(
          color: on ? scheme.primaryContainer : scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: on
                ? BorderSide(color: scheme.primary, width: 2)
                : BorderSide(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onSelected(d),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 76),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      d.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: on
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                    Text(
                      d.hint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: on
                            ? scheme.onPrimaryContainer.withValues(alpha: 0.85)
                            : scheme.onSurfaceVariant,
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

    return Column(
      spacing: 10,
      children: [
        for (var row = 0; row < 2; row++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                for (var col = 0; col < 2; col++)
                  Expanded(child: card(Difficulty.values[row * 2 + col])),
              ],
            ),
          ),
      ],
    );
  }
}

class _DaysPicker extends StatelessWidget {
  const _DaysPicker({required this.days, required this.onChanged});

  final Set<int> days;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var d = 1; d <= 7; d++)
          Semantics(
            label: weekdayNames[d - 1],
            selected: days.contains(d),
            button: true,
            excludeSemantics: true,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Material(
                  color: days.contains(d) ? scheme.primary : Colors.transparent,
                  shape: CircleBorder(
                    side: days.contains(d)
                        ? BorderSide.none
                        : BorderSide(color: scheme.outline),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      final next = {...days};
                      if (!next.remove(d)) next.add(d);
                      if (next.isNotEmpty) onChanged(next);
                    },
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Text(
                          weekdayLetters[d - 1],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: days.contains(d)
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Spiega da dove si parte, con le note gentili del test.
class _PlacementSheet extends StatelessWidget {
  const _PlacementSheet({required this.placement});

  final Placement placement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text('Il tuo punto di partenza', style: theme.textTheme.titleLarge),
            for (final note in placement.notes)
              DisciplineCard(
                color: scheme.tertiaryContainer,
                radius: 20,
                padding: const EdgeInsets.all(14),
                child: Text(
                  note,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
                ),
              ),
            for (final e in placement.positions.entries)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          Catalog.at(e.key, e.value).name,
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  ChainDots(
                    length: Catalog.chain(e.key).length,
                    position: e.value,
                  ),
                ],
              ),
            const SizedBox(height: 4),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Iniziamo'),
            ),
          ],
        ),
      ),
    );
  }
}
