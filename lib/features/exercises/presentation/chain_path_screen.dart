// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/styles/app_style.dart';
import '../../../core/widgets/common.dart';
import '../../profile/data/profile_repository.dart';
import '../domain/catalog.dart';
import '../domain/exercise.dart';
import 'exercise_figure.dart';
import '../../../core/feedback/ui_feedback.dart';

/// Percorsi a tappe (design "Esercizi e abilità"): ogni catena è una strada
/// dalla variante più facile alla più difficile. Le famiglie per variare
/// (cardio, mobilità, complementari) sono elenchi liberi.
class ChainPathScreen extends ConsumerStatefulWidget {
  const ChainPathScreen({super.key, required this.chain});

  final ChainId chain;

  @override
  ConsumerState<ChainPathScreen> createState() => _ChainPathScreenState();
}

class _ChainPathScreenState extends ConsumerState<ChainPathScreen> {
  late ChainId _chain = widget.chain;
  int? _open;
  final _keys = {for (final c in ChainId.values) c: GlobalKey()};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(jump: true));
  }

  /// Porta in vista il chip selezionato.
  void _reveal({bool jump = false}) {
    final chip = _keys[_chain]?.currentContext;
    if (chip == null || !chip.mounted) return;
    Scrollable.ensureVisible(
      chip,
      alignment: 0.5,
      duration: jump
          ? Duration.zero
          : DisciplineMotion.of(context, DisciplineMotion.medium),
      curve: DisciplineMotion.decelerate,
    );
  }

  int? _position(ChainId chain) =>
      ref.read(chainProgressProvider).value?[chain]?.position;

  void _select(ChainId chain) {
    if (chain == _chain) return;
    UiFeedback.instance.play(UiSound.select);
    setState(() {
      _chain = chain;
      _open = _position(chain);
    });
    _reveal();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progress = ref.watch(chainProgressProvider).value ?? const {};
    final position = progress[_chain]?.position;
    final list = Catalog.chain(_chain);
    final open = _open ?? position;
    final duration = DisciplineMotion.of(context, DisciplineMotion.medium);
    final locked = _chain.isProgression && position == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Percorsi')),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 56,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  spacing: 8,
                  children: [
                    for (final c in ChainId.values)
                      _ChainChip(
                        key: _keys[c],
                        chain: c,
                        selected: c == _chain,
                        onTap: () => _select(c),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: AnimatedSwitcher(
                duration: duration,
                child: Text(
                  !_chain.isProgression
                      ? '${list.length} esercizi per variare: usali nel '
                            'riscaldamento, nel timer o quando vuoi.'
                      : locked
                      ? 'Percorso non ancora iniziato: si sblocca con il tuo '
                            'livello.'
                      : 'Tappa ${position! + 1} di ${list.length} · '
                            'ogni tappa sblocca la successiva',
                  key: ValueKey(_chain),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: duration,
                switchInCurve: DisciplineMotion.decelerate,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: ListView(
                  key: ValueKey(_chain),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    for (final (i, e) in list.indexed)
                      _Step(
                        exercise: e,
                        state: !_chain.isProgression
                            ? _StepState.free
                            : position == null
                            ? _StepState.locked
                            : i < position
                            ? _StepState.done
                            : i == position
                            ? _StepState.current
                            : _StepState.locked,
                        first: i == 0,
                        last: i == list.length - 1,
                        lineDone: position != null && i < position,
                        open: open == i,
                        onTap: () => setState(() => _open = open == i ? -1 : i),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChainChip extends StatelessWidget {
  const _ChainChip({
    super.key,
    required this.chain,
    required this.selected,
    required this.onTap,
  });

  final ChainId chain;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = DisciplineMotion.of(context, DisciplineMotion.medium);
    final appStyle = AppStyle.of(context);
    // Area di tocco di almeno 48 px: l'altezza cresce con il testo grande.
    final radius = BorderRadius.circular(
      selected
          ? appStyle.buttonRadius.clamp(0, 24)
          : appStyle.smallRadius.clamp(0, 16),
    );
    return Center(
      child: Semantics(
        button: true,
        selected: selected,
        child: AnimatedContainer(
          duration: duration,
          curve: DisciplineMotion.decelerate,
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: radius,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outline,
            ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // heightFactor: il testo sta al centro dell'altezza minima.
              child: Center(
                heightFactor: 1,
                child: AnimatedDefaultTextStyle(
                  duration: duration,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.fontFamily,
                    color: selected
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  ),
                  child: Text(chain.label),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _StepState { done, current, locked, free }

class _Step extends StatelessWidget {
  const _Step({
    required this.exercise,
    required this.state,
    required this.first,
    required this.last,
    required this.lineDone,
    required this.open,
    required this.onTap,
  });

  final Exercise exercise;
  final _StepState state;
  final bool first;
  final bool last;
  final bool lineDone;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final duration = DisciplineMotion.of(context, DisciplineMotion.medium);
    final current = state == _StepState.current;
    final sub = switch (state) {
      _StepState.done => 'Completata',
      _StepState.current => 'Ci sei · ${exercise.targetLabel}',
      _StepState.locked => 'Da sbloccare',
      _StepState.free => exercise.targetLabel,
    };

    // Stack invece di IntrinsicHeight: la linea segue l'altezza della
    // scheda anche mentre si apre (AnimatedSize).
    return Stack(
      children: [
        // Linea del percorso.
        Positioned(
          left: 20.5,
          top: first ? 26 : 0,
          bottom: last ? null : 0,
          height: last ? 26 : null,
          child: AnimatedContainer(
            duration: duration,
            width: 3,
            color: lineDone || state == _StepState.done
                ? scheme.primary
                : scheme.outlineVariant,
          ),
        ),
        Positioned(
          left: 2,
          top: 6,
          child: _Node(state: state, index: exercise.position),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 56, bottom: 10),
          child: DisciplineCard(
            color: open
                ? scheme.primaryContainer
                : current
                ? scheme.surfaceContainer
                : scheme.surfaceContainerLow,
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: state == _StepState.locked
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurface,
                            ),
                          ),
                          Text(
                            sub,
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: duration,
                      curve: DisciplineMotion.decelerate,
                      child: Icon(
                        Icons.expand_more,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                // AnimatedSize con durata zero (animazioni spente)
                // dà errori di layout: in quel caso niente animazione.
                if (duration == Duration.zero)
                  open
                      ? _Details(exercise: exercise)
                      : const SizedBox(width: double.infinity)
                else
                  AnimatedSize(
                    duration: duration,
                    curve: DisciplineMotion.decelerate,
                    alignment: Alignment.topCenter,
                    child: open
                        ? _Details(exercise: exercise)
                        : const SizedBox(width: double.infinity),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.state, required this.index});

  final _StepState state;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = DisciplineMotion.of(context, DisciplineMotion.medium);
    final (bg, fg, border) = switch (state) {
      _StepState.done => (scheme.primary, scheme.onPrimary, scheme.primary),
      _StepState.current => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        scheme.primary,
      ),
      _StepState.locked => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
        Colors.transparent,
      ),
      _StepState.free => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Colors.transparent,
      ),
    };
    return AnimatedContainer(
      duration: duration,
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 3),
      ),
      child: Center(
        child: switch (state) {
          _StepState.done => Icon(Icons.check, size: 20, color: fg),
          _StepState.locked => Icon(Icons.lock_outline, size: 18, color: fg),
          _ => Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        },
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 104,
                height: 78,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(
                    AppStyle.of(context).smallRadius.clamp(0, 16),
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child: ExerciseFigure(
                  motion: motionFor(exercise),
                  size: const Size(92, 66),
                ),
              ),
              Expanded(
                child: Text(
                  exercise.instructions.first,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('Come si esegue'),
              onPressed: () => context.push(Routes.exercise(exercise.id)),
            ),
          ),
        ],
      ),
    );
  }
}
