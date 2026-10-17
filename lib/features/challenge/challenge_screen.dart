// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import '../camera/presentation/camera_counter_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/data/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/discipline_theme.dart';
import '../../core/theme/theme_settings.dart';
import '../../core/theme/styles/app_style.dart';
import '../../core/theme/styles/style_border.dart';
import '../../core/utils/italian_date.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/tab_scaffold.dart';
import '../exercises/domain/exercise.dart';
import '../rewards/data/rewards_repository.dart';
import '../rewards/data/rewards_state.dart';
import '../rewards/domain/rewards.dart';
import '../streak/domain/streak.dart';
import '../workout/data/today_plan.dart';
import 'domain/generated.dart';
import 'domain/timed.dart';

void _snack(BuildContext context, String text) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));

/// Scheda "Sfide": sfide generate, punti, negozio e badge. Tutto offline.
class ChallengeScreen extends ConsumerWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final balance = ref.watch(balanceProvider);
    final challenges = ref.watch(activeChallengesProvider);

    return TabScaffold(
      header: ScreenHeader(
        title: 'Sfide',
        subtitle: 'Guadagna punti, sblocca premi',
        actions: [_PointsPill(points: balance)],
      ),
      children: [
        const _RankCard(),
        for (final c in challenges) _GeneratedCard(status: c),
        const SectionTitle('A tempo'),
        for (final mode in TimedMode.values) _TimedCard(mode: mode),
        DisciplineCard(
          color: scheme.secondaryContainer,
          radius: 24,
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          onTap: () => context.push(Routes.friendChallenge),
          child: Row(
            spacing: 12,
            children: [
              const IconBadge(icon: Icons.groups_outlined),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sfida un amico',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    Text(
                      'Con un codice, senza account né internet',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSecondaryContainer),
            ],
          ),
        ),
        const SectionTitle('Negozio'),
        const _FreezeCard(),
        const _PaletteCard(),
        const SectionTitle('Badge'),
        const _BadgeGrid(),
      ],
    );
  }
}

class _PointsPill extends StatelessWidget {
  const _PointsPill({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = AppStyle.of(context);
    return Semantics(
      label: '$points punti',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(style.buttonRadius.clamp(0, 20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Icon(Icons.stars, size: 20, color: scheme.onTertiaryContainer),
            AnimatedCount(
              value: points,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: scheme.onTertiaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankCard extends ConsumerWidget {
  const _RankCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final info = ref.watch(rankProvider);
    final next = info.next;
    return DisciplineCard(
      color: scheme.primaryContainer,
      radius: DisciplineRadii.cardLarge,
      semanticsLabel: 'Grado ${info.rank.label}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            spacing: 12,
            children: [
              Icon(
                Icons.military_tech,
                size: 36,
                color: scheme.onPrimaryContainer,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Il tuo grado',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      info.rank.label,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AnimatedProgressBar(
            value: info.progress,
            color: scheme.primary,
            background: scheme.surfaceContainerHighest,
          ),
          Text(
            next == null
                ? 'Hai raggiunto il grado più alto!'
                : 'Mancano ${info.missing} punti per diventare ${next.label}',
            style: TextStyle(fontSize: 13, color: scheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class _GeneratedCard extends ConsumerWidget {
  const _GeneratedCard({required this.status});

  final ChallengeStatus status;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final c = status.challenge;
    final left = (c.target - status.progress.done).clamp(1, c.target);
    final added = await showModalBottomSheet<CameraCount>(
      context: context,
      showDragHandle: true,
      builder: (_) => _AddSheet(challenge: c, initial: left),
    );
    if (added == null) return;
    final rewards = ref.read(rewardsRepositoryProvider);
    final at = ref.read(clockProvider)();
    // Le ripetizioni viste dalla fotocamera valgono di più; quelle toccate a
    // mano no, anche se aggiunte dalla schermata della fotocamera.
    if (added.camera > 0) {
      await rewards.addChallengeEntry(
        c.id,
        added.camera,
        verified: true,
        at: at,
      );
    }
    if (added.manual > 0) {
      await rewards.addChallengeEntry(
        c.id,
        added.manual,
        verified: false,
        at: at,
      );
    }
  }

  Future<void> _claim(BuildContext context, WidgetRef ref) async {
    final points = pointsFor(status.challenge, status.progress);
    final ok = await ref
        .read(rewardsRepositoryProvider)
        .award(
          PointKind.challenge,
          points,
          at: ref.read(clockProvider)(),
          ref: 'sfida-${status.challenge.id}',
          note: status.challenge.goalText,
        );
    if (ok && context.mounted) {
      await celebrate(
        context,
        kicker: 'Sfida completata',
        title: status.challenge.goalText,
        points: points,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = status.challenge;
    final p = status.progress;
    final points = pointsFor(c, p);

    return DisciplineCard(
      radius: DisciplineRadii.cardLarge,
      semanticsLabel: '${c.period.label}: ${c.goalText}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.period.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  p.cameraBonus
                      ? '$points punti · bonus fotocamera'
                      : '$points punti',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          Text(c.goalText, style: theme.textTheme.titleLarge),
          Text(
            c.description,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          AnimatedProgressBar(
            value: p.ratio,
            color: p.completed ? scheme.tertiary : scheme.primary,
            background: scheme.surfaceContainerHighest,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${c.amount(p.done)} di ${c.amount(c.target)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (status.claimed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    Icon(Icons.check_circle, color: scheme.tertiary),
                    const Text('Completata'),
                  ],
                )
              else if (p.completed)
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  icon: const Icon(Icons.stars, size: 18),
                  label: Text('Riscatta +$points'),
                  onPressed: () => _claim(context, ref),
                )
              else
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Aggiungi'),
                  onPressed: () => _add(context, ref),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddSheet extends StatefulWidget {
  const _AddSheet({required this.challenge, required this.initial});

  final GeneratedChallenge challenge;
  final int initial;

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  late int _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final c = widget.challenge;
    final seconds = c.measure == Measure.seconds;
    final canCount = !seconds && c.exercise.chain == ChainId.push;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(
              'Quanti ne hai fatti?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ValueStepper(
              label: c.exercise.name,
              value: _value,
              min: 1,
              max: 999,
              step: seconds ? 15 : 1,
              suffix: seconds ? ' s' : null,
              onChanged: (v) => setState(() => _value = v),
            ),
            if (canCount)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Conta con la fotocamera (×1,5 punti)'),
                onPressed: () async {
                  final reps = await context.push<CameraCount>(
                    Routes.cameraCounter,
                  );
                  if (reps != null &&
                      reps.camera + reps.manual > 0 &&
                      context.mounted) {
                    Navigator.pop(context, reps);
                  }
                },
              ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () => Navigator.pop<CameraCount>(context, (
                camera: 0,
                manual: _value,
              )),
              child: const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimedCard extends ConsumerWidget {
  const _TimedCard({required this.mode});

  final TimedMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final best = ref.watch(bestTimedProvider)[mode];
    return DisciplineCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      onTap: () => context.push(Routes.timed(mode.name)),
      semanticsLabel: '${mode.label}, ${mode.description}',
      child: Row(
        spacing: 12,
        children: [
          IconBadge(
            icon: mode == TimedMode.minute
                ? Icons.timer_outlined
                : Icons.flag_outlined,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(mode.label, style: theme.textTheme.titleMedium),
                Text(
                  best == null
                      ? mode.description
                      : 'Record: ${scoreText(mode, best)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.play_circle, size: 36, color: scheme.primary),
        ],
      ),
    );
  }
}

class _FreezeCard extends ConsumerWidget {
  const _FreezeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final owned = ref.watch(freezesOwnedProvider);
    final balance = ref.watch(balanceProvider);
    final today = ref.watch(todayProvider);
    final missed = freezableDay(ref.watch(streakProvider), today);
    final repo = ref.read(rewardsRepositoryProvider);

    return DisciplineCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            spacing: 12,
            children: [
              const IconBadge(icon: Icons.shield_outlined),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Giorno jolly', style: theme.textTheme.titleMedium),
                    Text(
                      'Protegge la serie se salti un allenamento. '
                      'Ne hai $owned su $maxFreezes.',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: owned >= maxFreezes || balance < freezeCost
                    ? null
                    : () async {
                        try {
                          await repo.buyFreeze(ref.read(clockProvider)());
                          if (context.mounted) {
                            _snack(context, 'Giorno jolly comprato');
                          }
                        } on RewardsException catch (e) {
                          if (context.mounted) _snack(context, e.message);
                        }
                      },
                child: const Text('Compra · $freezeCost punti'),
              ),
              if (missed != null && owned > 0)
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: () async {
                    await repo.useFreeze(missed);
                    if (context.mounted) {
                      _snack(context, 'Serie salvata!');
                    }
                  },
                  child: Text('Salva ${formatItalianDate(missed.dateTime)}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaletteCard extends ConsumerWidget {
  const _PaletteCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unlocked = ref.watch(unlockedPalettesProvider);
    final current = ref.watch(themeSettingsProvider);
    final balance = ref.watch(balanceProvider);
    final settings = ref.read(themeSettingsProvider.notifier);

    return DisciplineCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            spacing: 12,
            children: [
              const IconBadge(icon: Icons.palette_outlined),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Colori dell\'app',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      'Ogni tema costa ${AppPalette.ocean.cost} punti',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in AppPalette.values)
                _PaletteChip(
                  palette: p,
                  owned: unlocked.contains(p),
                  selected:
                      !current.useDynamicColor && current.palette == p.name,
                  affordable: balance >= p.cost,
                  onTap: () async {
                    if (!unlocked.contains(p)) {
                      try {
                        await ref
                            .read(rewardsRepositoryProvider)
                            .buyPalette(p, ref.read(clockProvider)());
                      } on RewardsException catch (e) {
                        if (context.mounted) _snack(context, e.message);
                        return;
                      }
                    }
                    await settings.setPalette(p.name);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaletteChip extends StatelessWidget {
  const _PaletteChip({
    required this.palette,
    required this.owned,
    required this.selected,
    required this.affordable,
    required this.onTap,
  });

  final AppPalette palette;
  final bool owned;
  final bool selected;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      selected: selected,
      showCheckmark: false,
      avatar: CircleAvatar(backgroundColor: palette.seed, radius: 10),
      label: Text(owned ? palette.label : '${palette.label} · ${palette.cost}'),
      tooltip: owned
          ? 'Usa ${palette.label}'
          : 'Sblocca ${palette.label} per ${palette.cost} punti',
      labelStyle: TextStyle(
        color: !owned && !affordable ? scheme.onSurfaceVariant : null,
      ),
      onSelected: !owned && !affordable ? null : (_) => onTap(),
    );
  }
}

class _BadgeGrid extends ConsumerWidget {
  const _BadgeGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(badgesProvider);
    final rows = <List<Achievement>>[
      for (var i = 0; i < badges.length; i += 2)
        badges.sublist(i, i + 2 > badges.length ? badges.length : i + 2),
    ];
    return Column(
      spacing: 10,
      children: [
        for (final row in rows)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                for (final b in row)
                  Expanded(child: _AchievementTile(badge: b)),
                if (row.length == 1) const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.badge});

  final Achievement badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = AppStyle.of(context);
    final earned = badge.earned;
    return Semantics(
      label:
          '${badge.title}: ${badge.description}. '
          '${earned ? 'Ottenuto' : '${badge.value} su ${badge.goal}'}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: DisciplineMotion.of(context, DisciplineMotion.long),
        curve: DisciplineMotion.decelerate,
        padding: const EdgeInsets.all(14),
        decoration: ShapeDecoration(
          color: earned ? scheme.tertiaryContainer : scheme.surfaceContainer,
          shape: StyleBorder.card(style, scheme),
          shadows: style.softShadows,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Icon(
              badge.icon,
              color: earned
                  ? scheme.onTertiaryContainer
                  : scheme.onSurfaceVariant,
            ),
            Text(
              badge.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: earned ? scheme.onTertiaryContainer : scheme.onSurface,
              ),
            ),
            Text(
              badge.description,
              style: TextStyle(
                fontSize: 12,
                color: earned
                    ? scheme.onTertiaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (!earned)
              AnimatedProgressBar(
                value: badge.progress,
                color: scheme.primary,
                background: scheme.surfaceContainerHighest,
                height: 6,
              ),
          ],
        ),
      ),
    );
  }
}
