// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/motion.dart';
import '../theme/ritmo_theme.dart';

/// Contatore con − e + (ripetizioni, secondi, grammi).
class ValueStepper extends StatelessWidget {
  const ValueStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 999,
    this.step = 1,
    this.suffix,
    this.background,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  final String? suffix;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final buttonStyle = IconButton.styleFrom(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.primary,
      fixedSize: const Size(44, 44),
    );

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 8, 8, 8),
      decoration: BoxDecoration(
        color: background ?? scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(RitmoRadii.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Meno $label'.toLowerCase(),
            style: buttonStyle,
            onPressed: value - step >= min
                ? () {
                    HapticFeedback.selectionClick();
                    onChanged(value - step);
                  }
                : null,
            icon: const Icon(Icons.remove),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56),
            child: Semantics(
              liveRegion: true,
              label: '$label: $value${suffix ?? ''}',
              excludeSemantics: true,
              child: Text(
                '$value${suffix ?? ''}',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Più $label'.toLowerCase(),
            style: buttonStyle,
            onPressed: value + step <= max
                ? () {
                    HapticFeedback.selectionClick();
                    onChanged(value + step);
                  }
                : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

/// Barra di avanzamento a due segmenti, come nel design.
class SegmentBar extends StatelessWidget {
  const SegmentBar({
    super.key,
    required this.value,
    required this.color,
    required this.track,
    this.height = 8,
    this.semanticsLabel,
  });

  /// 0–1.
  final double value;
  final Color color;
  final Color track;
  final double height;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value.clamp(0.0, 1.0)),
    duration: RitmoMotion.of(context, RitmoMotion.long),
    curve: RitmoMotion.decelerate,
    builder: (context, v, _) => _build(v),
  );

  Widget _build(double animated) {
    final done = (animated * 1000).round();
    return Semantics(
      label: semanticsLabel,
      value: '${(value.clamp(0.0, 1.0) * 100).round()}%',
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4,
          children: [
            if (done > 0) Expanded(flex: done, child: _bar(color)),
            if (done < 1000) Expanded(flex: 1000 - done, child: _bar(track)),
          ],
        ),
      ),
    );
  }

  Widget _bar(Color c) => DecoratedBox(
    decoration: BoxDecoration(
      color: c,
      borderRadius: BorderRadius.circular(height / 2),
    ),
  );
}

/// Puntini della posizione in una catena di progressione.
class ChainDots extends StatelessWidget {
  const ChainDots({
    super.key,
    required this.length,
    required this.position,
    this.color,
    this.track,
  });

  final int length;
  final int position;
  final Color? color;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Variante ${position + 1} di $length',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          for (var i = 0; i < length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == position ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i <= position
                    ? (color ?? scheme.primary)
                    : (track ?? scheme.outlineVariant),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

/// Titolo di sezione (16 px, grassetto) come nel design.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              text,
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Card con angoli molto arrotondati e colore pieno.
class RitmoCard extends StatelessWidget {
  const RitmoCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(18),
    this.radius = RitmoRadii.cardLarge,
    this.onTap,
    this.semanticsLabel,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Semantics(
      container: true,
      label: semanticsLabel,
      child: Material(
        color: color ?? Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

/// Riga informativa con un'icona in un quadrato arrotondato.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.background,
    this.foreground,
    this.size = 40,
    this.radius = 12,
  });

  final IconData icon;

  /// Di serie: il contenitore primario del tema.
  final Color? background;
  final Color? foreground;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        icon,
        color: foreground ?? Theme.of(context).colorScheme.onPrimaryContainer,
        size: size * 0.55,
      ),
    ),
  );
}

/// Formatta secondi come "1:05".
String formatDuration(int totalSeconds) {
  final s = totalSeconds.abs();
  final minutes = s ~/ 60;
  final seconds = s % 60;
  return '${totalSeconds < 0 ? '-' : ''}$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Barra di avanzamento che scorre fino al nuovo valore (parte veloce e si
/// posa dolcemente).
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    required this.background,
    this.height = 10,
  });

  final double value;
  final Color color;
  final Color background;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height / 2),
    child: TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0.0, 1.0)),
      duration: RitmoMotion.of(context, RitmoMotion.long),
      curve: RitmoMotion.decelerate,
      builder: (context, v, _) => LinearProgressIndicator(
        value: v,
        minHeight: height,
        color: color,
        backgroundColor: background,
      ),
    ),
  );
}

/// Numero che scorre fino al nuovo valore (punti, contatori).
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({super.key, required this.value, this.style});

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value.toDouble()),
    duration: RitmoMotion.of(context, RitmoMotion.long),
    curve: RitmoMotion.decelerate,
    builder: (context, v, _) => Text(
      '${v.round()}',
      style: style?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
  );
}
