// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/data/providers.dart';
import '../../../core/utils/local_date.dart';
import '../../exercises/domain/equipment.dart';
import '../../profile/data/profile_repository.dart';

const _icons = {
  TrainingPlace.home: Icons.home_outlined,
  TrainingPlace.homeBar: Icons.door_front_door_outlined,
  TrainingPlace.park: Icons.park_outlined,
  TrainingPlace.gym: Icons.fitness_center,
};

IconData placeIcon(TrainingPlace p) => _icons[p]!;

/// Scegli dove ti alleni: la scheda cambia subito gli esercizi che servono
/// attrezzi che non hai.
Future<void> showPlaceSheet(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(profileRepositoryProvider);
  final profile = await repo.loadProfile();
  if (profile == null || !context.mounted) return;
  final picked = await showModalBottomSheet<TrainingPlace>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Dove ti alleni?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final p in TrainingPlace.values)
            ListTile(
              leading: Icon(placeIcon(p)),
              title: Text(p.label),
              subtitle: Text(p.hint),
              trailing: p == profile.place ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, p),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (picked == null || picked == profile.place) return;
  await repo.saveProfile(
    profile.copyWith(place: picked),
    LocalDate.fromDateTime(ref.read(clockProvider)()),
  );
}
