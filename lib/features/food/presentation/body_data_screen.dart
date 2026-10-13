// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/common.dart';
import '../../profile/data/profile_repository.dart';
import '../data/food_repository.dart';
import '../domain/nutrition.dart';

/// Dati del corpo, obiettivo, dieta e allergie.
class BodyDataScreen extends ConsumerStatefulWidget {
  const BodyDataScreen({super.key});

  @override
  ConsumerState<BodyDataScreen> createState() => _BodyDataScreenState();
}

class _BodyDataScreenState extends ConsumerState<BodyDataScreen> {
  var _body = const BodyProfile(
    sex: Sex.male,
    age: 25,
    weightKg: 70,
    heightCm: 175,
    goal: Goal.maintain,
  );
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(bodyProfileProvider).value;
    if (!_loaded && saved != null) {
      _body = saved;
      _loaded = true;
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final days =
        ref.watch(athleteProfileProvider).value?.trainingDays.length ?? 3;
    final auto = activityFromTrainingDays(days);

    return Scaffold(
      appBar: AppBar(title: const Text('I tuoi dati')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              'Servono per stimare il tuo fabbisogno. Restano sul telefono.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle('Sesso'),
            const SizedBox(height: 8),
            SegmentedButton<Sex>(
              showSelectedIcon: false,
              segments: [
                for (final s in Sex.values)
                  ButtonSegment(value: s, label: Text(s.label)),
              ],
              selected: {_body.sex},
              onSelectionChanged: (s) =>
                  setState(() => _body = _body.copyWith(sex: s.first)),
            ),
            const SizedBox(height: 16),
            ValueStepper(
              label: 'Età',
              value: _body.age,
              min: 14,
              max: 99,
              onChanged: (v) => setState(() => _body = _body.copyWith(age: v)),
            ),
            const SizedBox(height: 8),
            ValueStepper(
              label: 'Peso',
              value: _body.weightKg.round(),
              min: 35,
              max: 250,
              suffix: ' kg',
              onChanged: (v) => setState(
                () => _body = _body.copyWith(weightKg: v.toDouble()),
              ),
            ),
            const SizedBox(height: 8),
            ValueStepper(
              label: 'Altezza',
              value: _body.heightCm.round(),
              min: 120,
              max: 230,
              suffix: ' cm',
              onChanged: (v) => setState(
                () => _body = _body.copyWith(heightCm: v.toDouble()),
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle('Obiettivo'),
            const SizedBox(height: 8),
            RadioGroup<Goal>(
              groupValue: _body.goal,
              onChanged: (v) => setState(() => _body = _body.copyWith(goal: v)),
              child: Column(
                children: [
                  for (final g in Goal.values)
                    RadioListTile<Goal>(
                      value: g,
                      title: Text(g.label),
                      subtitle: Text(switch (g) {
                        Goal.cut => '−400 kcal al giorno',
                        Goal.maintain => 'Calorie pari al consumo',
                        Goal.bulk => '+300 kcal al giorno',
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const SectionTitle('Attività'),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _body.activity?.name ?? 'auto',
              onChanged: (v) => setState(
                () => _body = v == 'auto' || v == null
                    ? _body.copyWith(automaticActivity: true)
                    : _body.copyWith(activity: ActivityLevel.values.byName(v)),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'auto',
                    title: const Text('Automatica'),
                    subtitle: Text(
                      'Dai tuoi $days giorni di allenamento: '
                      '${auto.label.toLowerCase()}',
                    ),
                  ),
                  for (final a in ActivityLevel.values)
                    RadioListTile<String>(
                      value: a.name,
                      title: Text(a.label),
                      subtitle: Text(a.description),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SectionTitle(
              'Proteine',
              trailing: Text(
                '${_body.proteinPerKg.toStringAsFixed(1).replaceAll('.', ',')} g/kg',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                ),
              ),
            ),
            Slider(
              value: _body.proteinPerKg,
              min: proteinMinPerKg,
              max: proteinMaxPerKg,
              divisions: 6,
              label: _body.proteinPerKg.toStringAsFixed(1),
              onChanged: (v) =>
                  setState(() => _body = _body.copyWith(proteinPerKg: v)),
            ),
            const SizedBox(height: 8),
            const SectionTitle('Alimentazione'),
            const SizedBox(height: 8),
            SegmentedButton<Diet>(
              showSelectedIcon: false,
              segments: [
                for (final d in Diet.values)
                  ButtonSegment(value: d, label: Text(d.label)),
              ],
              selected: {_body.diet},
              onSelectionChanged: (s) =>
                  setState(() => _body = _body.copyWith(diet: s.first)),
            ),
            const SizedBox(height: 16),
            const SectionTitle('Allergie e intolleranze'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in Allergen.values)
                  FilterChip(
                    label: Text(a.label),
                    selected: _body.allergies.contains(a),
                    onSelected: (on) => setState(
                      () => _body = _body.copyWith(
                        allergies: on
                            ? {..._body.allergies, a}
                            : ({..._body.allergies}..remove(a)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: () async {
                await ref.read(foodRepositoryProvider).saveBody(_body);
                if (context.mounted) context.pop();
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}
