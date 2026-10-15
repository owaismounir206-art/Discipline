// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/motion.dart';

/// Un'opzione di [SlidingSegmented].
typedef Segment<T> = ({T value, String label});

/// Selettore a pillola: la pillola scivola sull'opzione scelta, partendo
/// veloce e posandosi dolcemente (Material You).
class SlidingSegmented<T> extends StatelessWidget {
  const SlidingSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.semanticsLabel,
  });

  final List<Segment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final index = segments.indexWhere((s) => s.value == selected);
    final duration = DisciplineMotion.of(context, DisciplineMotion.medium);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(28),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth / segments.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: duration,
                  curve: DisciplineMotion.decelerate,
                  left: index < 0 ? 0 : index * width,
                  top: 0,
                  bottom: 0,
                  width: width,
                  child: AnimatedOpacity(
                    duration: duration,
                    opacity: index < 0 ? 0 : 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final (i, s) in segments.indexed)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: i == index,
                          inMutuallyExclusiveGroup: true,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              if (i == index) return;
                              HapticFeedback.selectionClick();
                              onChanged(s.value);
                            },
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: duration,
                                curve: DisciplineMotion.decelerate,
                                style:
                                    (textTheme.labelLarge ?? const TextStyle())
                                        .copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: i == index
                                              ? scheme.onPrimary
                                              : scheme.onSurfaceVariant,
                                        ),
                                child: Text(
                                  s.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Una voce della barra di navigazione.
typedef NavItem = ({IconData icon, IconData selectedIcon, String label});

/// Barra di navigazione Material You con l'evidenziatore che scivola sotto
/// la voce scelta.
class DisciplineNavigationBar extends StatelessWidget {
  const DisciplineNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _indicator = Size(64, 32);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final duration = DisciplineMotion.of(context, DisciplineMotion.medium);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: scheme.surfaceContainer,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: 80,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth / items.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: duration,
                    curve: DisciplineMotion.decelerate,
                    top: 12,
                    left:
                        selectedIndex * width + (width - _indicator.width) / 2,
                    width: _indicator.width,
                    height: _indicator.height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final (i, item) in items.indexed)
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: i == selectedIndex,
                            label: item.label,
                            excludeSemantics: true,
                            // Senza questo TalkBack legge la scheda ma non
                            // può aprirla (excludeSemantics toglie il tocco).
                            onTap: () => onSelected(i),
                            child: InkResponse(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onSelected(i);
                              },
                              highlightShape: BoxShape.rectangle,
                              containedInkWell: true,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  AnimatedSwitcher(
                                    duration: duration,
                                    switchInCurve: DisciplineMotion.decelerate,
                                    transitionBuilder: (child, animation) =>
                                        ScaleTransition(
                                          scale: Tween(
                                            begin: 0.7,
                                            end: 1.0,
                                          ).animate(animation),
                                          child: FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          ),
                                        ),
                                    child: Icon(
                                      i == selectedIndex
                                          ? item.selectedIcon
                                          : item.icon,
                                      key: ValueKey(i == selectedIndex),
                                      size: 24,
                                      color: i == selectedIndex
                                          ? scheme.onSecondaryContainer
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  AnimatedDefaultTextStyle(
                                    duration: duration,
                                    style:
                                        (textTheme.labelMedium ??
                                                const TextStyle())
                                            .copyWith(
                                              fontSize: 12,
                                              fontWeight: i == selectedIndex
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: i == selectedIndex
                                                  ? scheme.onSurface
                                                  : scheme.onSurfaceVariant,
                                            ),
                                    child: Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      // La barra è alta 80: oltre 1,5× la
                                      // scritta non ci starebbe.
                                      textScaler: MediaQuery.textScalerOf(
                                        context,
                                      ).clamp(maxScaleFactor: 1.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Si rimpicciolisce un poco mentre lo premi e torna su con un piccolo
/// rimbalzo: il pulsante "risponde" al dito.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.95});

  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  var _down = false;

  void _set(bool down) {
    if (down != _down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down ? widget.scale : 1,
      duration: DisciplineMotion.of(context, DisciplineMotion.press),
      curve: _down ? DisciplineMotion.standard : Curves.easeOutBack,
      child: widget.child,
    ),
  );
}

/// Ingresso di una card: sale e appare, una dopo l'altra ([index]).
class Entrance extends StatefulWidget {
  const Entrance({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  static const _step = Duration(milliseconds: 50);
  static const _maxSteps = 6;
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final run = DisciplineMotion.of(context, DisciplineMotion.long);
    final delay = _step * widget.index.clamp(0, _maxSteps);
    final total = run + delay;
    _controller = AnimationController(vsync: this, duration: total);
    _animation = CurvedAnimation(
      parent: _controller!,
      curve: Interval(
        total == Duration.zero
            ? 0
            : delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: DisciplineMotion.decelerate,
      ),
    );
    if (run == Duration.zero) {
      _controller!.value = 1;
    } else {
      _controller!.forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = _animation!;
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: widget.child,
      ),
    );
  }
}
