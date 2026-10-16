// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../theme/motion.dart';
import '../feedback/ui_feedback.dart';

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
                              UiFeedback.instance.play(UiSound.select);
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
                                UiFeedback.instance.play(UiSound.select);
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

/// Le schede dell'app una sopra l'altra: quella scelta appare sfumando e
/// crescendo appena, le altre restano nascoste ma ricordano dove eri.
class FadeThroughBranches extends StatelessWidget {
  const FadeThroughBranches({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      for (final (i, child) in children.indexed)
        _FadeThroughBranch(active: i == currentIndex, child: child),
    ],
  );
}

class _FadeThroughBranch extends StatefulWidget {
  const _FadeThroughBranch({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_FadeThroughBranch> createState() => _FadeThroughBranchState();
}

class _FadeThroughBranchState extends State<_FadeThroughBranch>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    value: widget.active ? 1 : 0,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: DisciplineMotion.decelerate,
  );
  late final _scale = Tween(begin: 0.97, end: 1.0).animate(_curve);

  @override
  void didUpdateWidget(_FadeThroughBranch old) {
    super.didUpdateWidget(old);
    if (widget.active == old.active) return;
    if (!widget.active) {
      _controller.value = 0;
      return;
    }
    final duration = DisciplineMotion.of(context, DisciplineMotion.medium);
    if (duration == Duration.zero) {
      _controller.value = 1;
    } else {
      _controller
        ..duration = duration
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Offstage(
    offstage: !widget.active,
    child: TickerMode(
      enabled: widget.active,
      child: FadeTransition(
        opacity: _curve,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    ),
  );
}

/// Un numero che conta fino al suo valore (e scorre quando cambia).
class CountUp extends StatelessWidget {
  const CountUp(this.value, {super.key, this.style, this.format});

  final int value;
  final TextStyle? style;

  /// Testo intorno al numero, es. (n) => '+$n punti'.
  final String Function(int value)? format;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.toDouble()),
    duration: DisciplineMotion.of(context, const Duration(milliseconds: 900)),
    curve: DisciplineMotion.decelerate,
    builder: (context, v, _) {
      final n = v.round();
      return Text(format?.call(n) ?? '$n', style: style);
    },
  );
}

/// Appare crescendo con un piccolo rimbalzo (icone di conferma, medaglie).
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: DisciplineMotion.of(context, DisciplineMotion.long),
    curve: Curves.easeOutBack,
    builder: (context, v, child) => Opacity(
      opacity: v.clamp(0, 1),
      child: Transform.scale(scale: 0.5 + 0.5 * v, child: child),
    ),
    child: child,
  );
}
