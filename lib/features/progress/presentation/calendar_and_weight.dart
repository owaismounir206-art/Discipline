// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/motion.dart';
import '../../../core/utils/local_date.dart';
import '../../../core/widgets/common.dart';
import '../../food/data/food_repository.dart';
import '../../streak/domain/streak.dart';
import '../../workout/data/today_plan.dart';

/// Settimane mostrate nel calendario.
const calendarWeeks = 16;

/// Calendario degli allenamenti: una colonna per settimana, una riga per
/// giorno. Le caselle compaiono a onda, da sinistra a destra.
class TrainingCalendar extends ConsumerStatefulWidget {
  const TrainingCalendar({super.key});

  @override
  ConsumerState<TrainingCalendar> createState() => _TrainingCalendarState();
}

class _TrainingCalendarState extends ConsumerState<TrainingCalendar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _wave.value = 1;
    } else if (_wave.value == 0 && !_wave.isAnimating) {
      _wave.forward();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = ref.watch(todayProvider);
    final statuses = ref.watch(streakProvider).statuses;
    final start = today.startOfWeek.addDays(-7 * (calendarWeeks - 1));
    final done = statuses.entries
        .where(
          (e) =>
              !e.key.isBefore(start) &&
              (e.value == DayStatus.done || e.value == DayStatus.bonus),
        )
        .length;

    Color colorOf(DayStatus? s) => switch (s) {
      DayStatus.done => scheme.primary,
      DayStatus.bonus => scheme.tertiary,
      // Salvato: stesso colore di "fatto" ma più chiaro (prima era quasi
      // uguale).
      DayStatus.protected ||
      DayStatus.recovered => scheme.primary.withValues(alpha: 0.4),
      DayStatus.missed => scheme.error.withValues(alpha: 0.35),
      DayStatus.today || DayStatus.scheduled => scheme.primaryContainer,
      _ => scheme.surfaceContainerHighest,
    };

    return DisciplineCard(
      padding: const EdgeInsets.all(18),
      semanticsLabel:
          'Calendario: $done allenamenti nelle ultime $calendarWeeks '
          'settimane',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Calendario', style: theme.textTheme.titleMedium),
              Text(
                '$done allenamenti in $calendarWeeks settimane',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          ExcludeSemantics(
            child: LayoutBuilder(
              builder: (context, box) {
                const labelWidth = 16.0;
                const gap = 3.0;
                final cell = math.min(
                  (box.maxWidth - labelWidth - gap * calendarWeeks) /
                      calendarWeeks,
                  20.0,
                );
                return AnimatedBuilder(
                  animation: _wave,
                  builder: (context, _) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          for (final d in 'LMMGVSD'.split(''))
                            SizedBox(
                              width: labelWidth,
                              height: cell + gap,
                              child: Text(
                                d,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                      for (var w = 0; w < calendarWeeks; w++)
                        Padding(
                          padding: const EdgeInsets.only(left: gap),
                          child: Column(
                            children: [
                              for (var d = 0; d < 7; d++)
                                _cell(
                                  start.addDays(w * 7 + d),
                                  today,
                                  cell,
                                  gap,
                                  w,
                                  colorOf,
                                  statuses,
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _Legend(color: scheme.primary, label: 'Fatto'),
              _Legend(color: scheme.tertiary, label: 'Extra'),
              _Legend(
                color: scheme.primary.withValues(alpha: 0.4),
                label: 'Salvato',
              ),
              _Legend(
                color: scheme.error.withValues(alpha: 0.35),
                label: 'Saltato',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(
    LocalDate day,
    LocalDate today,
    double size,
    double gap,
    int week,
    Color Function(DayStatus?) colorOf,
    Map<LocalDate, DayStatus> statuses,
  ) {
    final future = day.isAfter(today);
    // Ogni colonna parte un po' dopo la precedente.
    final from = week / calendarWeeks * 0.6;
    final v = DisciplineMotion.decelerate.transform(
      ((_wave.value - from) / 0.4).clamp(0.0, 1.0),
    );
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Transform.scale(
        scale: 0.4 + 0.6 * v,
        child: Opacity(
          opacity: v,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: future ? Colors.transparent : colorOf(statuses[day]),
              borderRadius: BorderRadius.circular(size / 4),
              border: day == today
                  ? Border.all(color: scheme.primary, width: 2)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 6,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

String kg(double v) => '${v.toStringAsFixed(1).replaceAll('.', ',')} kg';

/// Diario del peso con un grafico che si disegna da sinistra.
class WeightCard extends ConsumerWidget {
  const WeightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final weights = ref.watch(weightsProvider).value ?? const {};
    final today = ref.watch(todayProvider);
    final entries = weights.entries.toList();
    final last = entries.isEmpty ? null : entries.last;
    final monthAgo = today.addDays(-30);
    final base = entries.where((e) => !e.key.isBefore(monthAgo)).firstOrNull;
    final change = last != null && base != null && base.key != last.key
        ? last.value - base.value
        : null;

    return DisciplineCard(
      padding: const EdgeInsets.all(18),
      semanticsLabel: last == null
          ? 'Peso: nessuna misura'
          : 'Peso: ${kg(last.value)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peso',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      last == null ? '—' : kg(last.value),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (change != null)
                Flexible(
                  child: Text(
                    '${change >= 0 ? '+' : '−'}${kg(change.abs())} in 30 giorni',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (entries.length >= 2)
            SizedBox(
              height: 110,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(entries.length),
                tween: Tween(begin: 0, end: 1),
                duration: DisciplineMotion.of(
                  context,
                  const Duration(milliseconds: 900),
                ),
                curve: DisciplineMotion.decelerate,
                builder: (context, t, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _WeightPainter(
                    points: [
                      for (final e
                          in entries.length > 30
                              ? entries.sublist(entries.length - 30)
                              : entries)
                        e.value,
                    ],
                    t: t,
                    color: scheme.primary,
                    grid: scheme.outlineVariant,
                  ),
                ),
              ),
            )
          else
            Text(
              entries.isEmpty
                  ? 'Pesati una volta a settimana, alla stessa ora: qui vedrai '
                        'l\'andamento. Il peso più recente aggiorna anche i '
                        'consigli sul cibo.'
                  : 'Aggiungi un\'altra misura per vedere il grafico.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.monitor_weight_outlined),
              label: Text(
                weights.containsKey(today)
                    ? 'Cambia il peso di oggi'
                    : 'Pesati',
              ),
              onPressed: () => showWeightSheet(
                context,
                ref,
                today,
                weights[today] ??
                    last?.value ??
                    ref.read(bodyProfileProvider).value?.weightKg ??
                    70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showWeightSheet(
  BuildContext context,
  WidgetRef ref,
  LocalDate day,
  double initial,
) async {
  var value = (initial * 10).round();
  final saved = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                Text('Il peso di oggi', style: theme.textTheme.titleLarge),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 16,
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Meno 100 grammi',
                      onPressed: () =>
                          setState(() => value = math.max(200, value - 1)),
                      icon: const Icon(Icons.remove),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          kg(value / 10),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Più 100 grammi',
                      onPressed: () =>
                          setState(() => value = math.min(4000, value + 1)),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    for (final d in [-10, -5, 5, 10])
                      ActionChip(
                        label: Text(
                          '${d > 0 ? '+' : '−'}${(d.abs() / 10).toStringAsFixed(1).replaceAll('.', ',')}',
                        ),
                        onPressed: () => setState(
                          () => value = (value + d).clamp(200, 4000),
                        ),
                      ),
                  ],
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Salva'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  if (saved ?? false) {
    await ref.read(foodRepositoryProvider).setWeight(day, value / 10);
  }
}

class _WeightPainter extends CustomPainter {
  _WeightPainter({
    required this.points,
    required this.t,
    required this.color,
    required this.grid,
  });

  final List<double> points;
  final double t;
  final Color color;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final lo = points.reduce(math.min) - 0.5;
    final hi = points.reduce(math.max) + 0.5;
    Offset at(int i) => Offset(
      size.width * i / (points.length - 1),
      size.height * (1 - (points[i] - lo) / (hi - lo)),
    );
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final y in [0.0, 0.5, 1.0]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        gridPaint,
      );
    }
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      // Curva morbida tra un punto e l'altro.
      final a = at(i - 1);
      final b = at(i);
      final mid = (a.dx + b.dx) / 2;
      path.cubicTo(mid, a.dy, mid, b.dy, b.dx, b.dy);
    }
    canvas
      ..save()
      ..clipRect(Rect.fromLTWH(-4, -4, size.width * t + 8, size.height + 8));
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas
      ..drawPath(fill, Paint()..color = color.withValues(alpha: 0.12))
      ..drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(at(points.length - 1), 5, Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(_WeightPainter old) =>
      old.t != t || old.points != points || old.color != color;
}
