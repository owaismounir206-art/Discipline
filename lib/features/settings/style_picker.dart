// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/feedback/ui_feedback.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/styles/app_style.dart';
import '../../core/theme/styles/style_backdrop.dart';
import '../../core/theme/styles/style_catalog.dart';
import '../../core/theme/theme_settings.dart';

/// Scelta dello stile grafico: una piccola anteprima per ognuno, si
/// applica subito.
class StylePicker extends ConsumerWidget {
  const StylePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final current = styleById(ref.watch(themeSettingsProvider).style);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final columns = box.maxWidth >= 520 ? 4 : 3;
            const gap = 10.0;
            final width = (box.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final style in appStyles)
                  SizedBox(
                    width: width,
                    child: _StyleTile(
                      style: style,
                      selected: style.id == current.id,
                      onTap: () {
                        UiFeedback.instance.play(UiSound.select);
                        ref
                            .read(themeSettingsProvider.notifier)
                            .setStyle(style.id.name);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
        AnimatedSwitcher(
          duration: DisciplineMotion.of(context, DisciplineMotion.short),
          child: Text(
            current.tagline,
            key: ValueKey(current.id),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final AppStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = stylePreview(style);
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Stile ${style.label}',
      excludeSemantics: true,
      child: Column(
        spacing: 6,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: AnimatedContainer(
              duration: DisciplineMotion.of(context, DisciplineMotion.short),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: selected ? 3 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(selected ? 11 : 13),
                child: Material(
                  color: p.bg,
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                style.isKanji ? '今日' : 'Aa',
                                style: TextStyle(
                                  fontFamily: style.isKanji
                                      ? 'YujiBoku'
                                      : style.displayFont,
                                  fontWeight: style.displayWeight,
                                  fontSize: style.id == StyleId.gameboy
                                      ? 14
                                      : 22,
                                  height: 1.1,
                                  color: p.ink,
                                ),
                              ),
                              const Spacer(),
                              if (selected)
                                Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: p.ink,
                                ),
                            ],
                          ),
                          const Spacer(),
                          // Una card in miniatura con il colore d'accento.
                          Container(
                            height: 22,
                            decoration: BoxDecoration(
                              color: p.card,
                              borderRadius: BorderRadius.circular(
                                style.radius.clamp(0, 8),
                              ),
                              border: style.borderWidth >= 2
                                  ? Border.all(color: p.ink, width: 1.5)
                                  : null,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: FractionallySizedBox(
                              widthFactor: 0.6,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: p.accent,
                                  borderRadius: BorderRadius.circular(
                                    style.radius >= 8 ? 4 : 0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            style.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
