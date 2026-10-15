// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/router/routes.dart';
import '../../core/update/update_card.dart';
import '../../core/theme/discipline_theme.dart';
import '../../core/utils/italian_date.dart';
import '../../core/utils/local_date.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/tab_scaffold.dart';
import '../profile/data/profile_repository.dart';
import '../profile/domain/athlete_profile.dart';
import '../rewards/data/rewards_repository.dart';
import '../rewards/data/rewards_state.dart';
import '../streak/domain/streak.dart';
import '../workout/data/today_plan.dart';
import '../workout/presentation/suggestions_card.dart';

/// Scheda "Oggi": streak, livello, allenamento del giorno e inviti.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(athleteProfileProvider).value;
    final today = ref.watch(todayProvider);
    final name = profile?.name.trim() ?? '';

    return TabScaffold(
      header: ScreenHeader(
        overline: formatItalianDate(today.dateTime, capitalize: true),
        title: name.isEmpty ? 'Ciao!' : 'Ciao, $name',
        actions: [
          IconButton(
            tooltip: 'Promemoria',
            color: scheme.onSurfaceVariant,
            icon: Icon(
              profile?.reminder == null
                  ? Icons.notifications_off_outlined
                  : Icons.notifications_outlined,
            ),
            onPressed: () => context.push(Routes.settings),
          ),
          const SizedBox(width: 4),
          Semantics(
            button: true,
            label: 'Profilo e impostazioni',
            excludeSemantics: true,
            child: IconButton.filled(
              tooltip: 'Profilo e impostazioni',
              style: IconButton.styleFrom(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                fixedSize: const Size(44, 44),
              ),
              icon: profile?.initial.isNotEmpty ?? false
                  ? Text(
                      profile!.initial,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    )
                  : const Icon(Icons.person_outline),
              onPressed: () => context.push(Routes.settings),
            ),
          ),
        ],
      ),
      children: [
        if (profile != null) ...[
          const UpdateCard(),
          _StreakCard(profile: profile),
          const _FreezeHint(),
          const _LevelCard(),
          const SuggestionsCard(),
          const _TodayWorkoutCard(),
        ] else
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}

class _StreakCard extends ConsumerWidget {
  const _StreakCard({required this.profile});

  final AthleteProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final streak = ref.watch(streakProvider);
    final schedule = ref.watch(scheduleProvider).value ?? const [];
    final today = ref.watch(todayProvider);
    final strip = weekStrip(streak: streak, schedule: schedule, today: today);
    final muted = Color.lerp(scheme.primary, scheme.onPrimary, 0.25)!;
    final soft = scheme.primaryContainer;

    final title = switch (streak.current) {
      0 => 'Inizia la tua streak',
      1 => '1 allenamento di fila',
      final n => '$n allenamenti di fila',
    };

    return DisciplineCard(
      color: scheme.primary,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      semanticsLabel: 'Streak',
      child: Column(
        spacing: 14,
        children: [
          Row(
            spacing: 14,
            children: [
              IconBadge(
                icon: Icons.local_fire_department,
                background: soft,
                foreground: scheme.primary,
                size: 52,
                radius: 18,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        title,
                        maxLines: 1,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                    Text(
                      'Contano solo i tuoi giorni: '
                      '${trainingDaysLabel(profile.trainingDays)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: soft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              for (final (day, status) in strip)
                Expanded(
                  child: _DayCell(
                    day: day,
                    status: status,
                    isToday: day == today,
                    muted: muted,
                  ),
                ),
            ],
          ),
          if (streak.best > streak.current || !streak.recoveryAvailable)
            Row(
              children: [
                if (streak.best > 0)
                  Expanded(
                    child: Text(
                      'Record: ${streak.best}',
                      style: theme.textTheme.bodySmall?.copyWith(color: soft),
                    ),
                  ),
                Text(
                  streak.recoveryAvailable
                      ? 'Giorno di recupero disponibile'
                      : 'Recupero già usato',
                  style: theme.textTheme.bodySmall?.copyWith(color: soft),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.status,
    required this.isToday,
    required this.muted,
  });

  final LocalDate day;
  final DayStatus status;
  final bool isToday;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final soft = scheme.primaryContainer;
    final letter = weekdayLetters[day.weekday - 1];
    final (label, Widget mark) = switch (status) {
      DayStatus.done || DayStatus.bonus => (
        status == DayStatus.bonus ? 'bonus' : 'fatto',
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: status == DayStatus.bonus ? muted : soft,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, size: 18, color: scheme.primary),
        ),
      ),
      DayStatus.today => (
        'oggi',
        _Outlined(
          dashed: true,
          color: soft,
          child: Text(
            'oggi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onPrimary,
            ),
          ),
        ),
      ),
      DayStatus.scheduled => (
        'programmato',
        _Outlined(
          color: muted,
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: soft,
            ),
          ),
        ),
      ),
      DayStatus.recovered => (
        'recuperato',
        _Outlined(
          color: muted,
          child: Icon(Icons.healing, size: 16, color: soft),
        ),
      ),
      DayStatus.protected => (
        'protetto dal giorno jolly',
        _Outlined(
          color: muted,
          child: Icon(Icons.shield_outlined, size: 16, color: soft),
        ),
      ),
      DayStatus.missed => (
        'saltato',
        _Outlined(
          color: muted,
          child: Icon(Icons.close, size: 16, color: muted),
        ),
      ),
      DayStatus.rest => (
        'riposo',
        SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: muted, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    };

    return Semantics(
      label: '${weekdayNames[day.weekday - 1]}: $label',
      excludeSemantics: true,
      child: Column(
        spacing: 5,
        children: [
          Text(
            letter,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: isToday ? scheme.onPrimary : soft,
            ),
          ),
          mark,
        ],
      ),
    );
  }
}

class _Outlined extends StatelessWidget {
  const _Outlined({
    required this.color,
    required this.child,
    this.dashed = false,
  });

  final Color color;
  final Widget child;
  final bool dashed;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _CirclePainter(color: color, dashed: dashed),
    child: SizedBox(width: 36, height: 36, child: Center(child: child)),
  );
}

class _CirclePainter extends CustomPainter {
  _CirclePainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Offset.zero & size;
    final circle = rect.deflate(1);
    if (!dashed) {
      canvas.drawOval(circle, paint);
      return;
    }
    const dashes = 14;
    const sweep = 2 * 3.141592653589793 / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(circle, i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_CirclePainter old) =>
      old.color != color || old.dashed != dashed;
}

class _LevelCard extends ConsumerWidget {
  const _LevelCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final level = ref.watch(levelProvider);
    final profile = ref.watch(athleteProfileProvider).value;
    if (level == null || profile == null) return const SizedBox.shrink();
    final accent = Color.lerp(scheme.primary, scheme.onPrimaryContainer, 0.4)!;

    final detail = [
      if (level.next != null)
        '${level.percent}% verso ${level.next!.label}'
      else
        'Livello massimo raggiunto',
      if (level.nextSkill != null)
        'prossima abilità: ${level.nextSkill!.name.toLowerCase()}',
    ].join(' · ');

    return DisciplineCard(
      color: scheme.primaryContainer,
      radius: DisciplineRadii.card,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      onTap: () => context.push(Routes.athleteProfile),
      semanticsLabel:
          'Il tuo livello: ${level.level.label}. $detail. Modifica profilo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Livello · ${profile.experience.label.toLowerCase()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                    Text(
                      level.level.label,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Modifica',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SegmentBar(
            value: level.progressToNext,
            color: scheme.primary,
            track: Color.lerp(scheme.primaryContainer, scheme.primary, 0.25)!,
          ),
          Text(
            detail,
            style: theme.textTheme.bodySmall?.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}

class _TodayWorkoutCard extends ConsumerWidget {
  const _TodayWorkoutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = ref.watch(todayWorkoutProvider);
    final streak = ref.watch(streakProvider);
    final todayDate = ref.watch(todayProvider);
    if (today == null) return const SizedBox.shrink();
    final status = streak.statuses[todayDate];
    final done = status == DayStatus.done || status == DayStatus.bonus;
    final muted = scheme.onTertiaryContainer.withValues(alpha: 0.8);

    final overline = today.scheduled
        ? 'Oggi · ${today.plan.template.label}'
        : 'Oggi è riposo · allenamento extra';

    return DisciplineCard(
      color: scheme.tertiaryContainer,
      semanticsLabel: 'Allenamento di oggi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                overline,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
              Text(
                done ? 'Fatto! Ottimo lavoro' : today.plan.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: scheme.onTertiaryContainer,
                ),
              ),
              Text(
                done
                    ? 'Puoi rifarlo o riposare: la streak è al sicuro.'
                    : today.scheduled
                    ? today.plan.summary
                    : 'Facoltativo: è un bonus e non cambia la streak.',
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ],
          ),
          PressScale(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.tertiary,
                foregroundColor: scheme.onTertiary,
              ),
              onPressed: () =>
                  context.push(Routes.session, extra: today.plan.template),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(done ? 'Allenati ancora' : 'Inizia allenamento'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hai saltato un allenamento ma hai un giorno jolly: salva la serie.
class _FreezeHint extends ConsumerWidget {
  const _FreezeHint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owned = ref.watch(freezesOwnedProvider);
    final missed = freezableDay(
      ref.watch(streakProvider),
      ref.watch(todayProvider),
    );
    if (owned <= 0 || missed == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return DisciplineCard(
      color: scheme.secondaryContainer,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        spacing: 12,
        children: [
          Icon(Icons.shield_outlined, color: scheme.onSecondaryContainer),
          Expanded(
            child: Text(
              'Hai saltato ${formatItalianDate(missed.dateTime)}. '
              'Usa un giorno jolly per salvare la serie.',
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () =>
                ref.read(rewardsRepositoryProvider).useFreeze(missed),
            child: const Text('Usa'),
          ),
        ],
      ),
    );
  }
}
