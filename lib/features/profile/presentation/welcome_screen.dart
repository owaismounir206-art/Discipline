// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/common.dart';

/// Primo avvio: cos'è Discipline e poi il profilo atleta.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget point(IconData icon, String title, String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 14,
      children: [
        IconBadge(
          icon: icon,
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
          size: 44,
          radius: 14,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            IconBadge(
              icon: Icons.local_fire_department,
              background: scheme.primary,
              foreground: scheme.onPrimary,
              size: 72,
              radius: 24,
            ),
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text(
                'Discipline',
                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 40),
              ),
            ),
            Text(
              'Calisthenics libera e gratuita',
              style: theme.textTheme.titleLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            point(
              Icons.trending_up,
              'Si adatta a te',
              'Allenamenti a corpo libero che crescono con il tuo livello.',
            ),
            const SizedBox(height: 18),
            point(
              Icons.local_fire_department_outlined,
              'Una streak giusta',
              'Contano solo i giorni che scegli: il riposo non la interrompe.',
            ),
            const SizedBox(height: 18),
            point(
              Icons.lock_outline,
              'Gratis e privata',
              'Niente pubblicità né abbonamenti. I tuoi dati restano sul '
                  'telefono.',
            ),
            const SizedBox(height: 40),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: () => context.push(Routes.onboardingProfile),
              child: const Text('Inizia'),
            ),
          ],
        ),
      ),
    );
  }
}
