// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/motion.dart';
import '../feedback/ui_feedback.dart';

/// Festa per un traguardo: coriandoli, medaglia che entra con un piccolo
/// rimbalzo e punti che salgono. Con "riduci animazioni" resta tutto fermo.
Future<void> celebrate(
  BuildContext context, {
  required String kicker,
  required String title,
  String? subtitle,
  int points = 0,
  IconData icon = Icons.emoji_events,
}) {
  UiFeedback.instance.play(UiSound.celebrate);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Chiudi',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: DisciplineMotion.of(context, DisciplineMotion.medium),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: DisciplineMotion.decelerate,
      ),
      child: child,
    ),
    pageBuilder: (context, _, _) => _Celebration(
      kicker: kicker,
      title: title,
      subtitle: subtitle,
      points: points,
      icon: icon,
    ),
  );
}

class _Celebration extends StatefulWidget {
  const _Celebration({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.icon,
  });

  final String kicker;
  final String title;
  final String? subtitle;
  final int points;
  final IconData icon;

  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.value = 1;
    } else if (_c.value == 0 && !_c.isAnimating) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Parte di [_c] tra [from] e [to], con la curva di decelerazione.
  double _part(
    double from,
    double to, [
    Curve curve = DisciplineMotion.decelerate,
  ]) => curve.transform(((_c.value - from) / (to - from)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = [
      scheme.primary,
      scheme.tertiary,
      scheme.secondary,
      scheme.primaryContainer,
      scheme.tertiaryContainer,
      const Color(0xFF81C784),
    ];

    return SafeArea(
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final medal = _part(0, 0.4, Curves.easeOutBack);
            Widget rise(int i, Widget child) {
              final v = _part(0.12 + i * 0.08, 0.5 + i * 0.08);
              return Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, 24 * (1 - v)),
                  child: child,
                ),
              );
            }

            return Stack(
              children: [
                if (_c.value < 1)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ConfettiPainter(
                          t: _part(0, 0.8),
                          colors: colors,
                        ),
                      ),
                    ),
                  ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 16,
                      children: [
                        Transform.scale(
                          scale: 0.2 + 0.8 * medal,
                          child: Transform.rotate(
                            angle: -0.4 * (1 - medal),
                            child: Opacity(
                              opacity: medal.clamp(0.0, 1.0),
                              child: Container(
                                width: 128,
                                height: 128,
                                decoration: BoxDecoration(
                                  color: scheme.tertiaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.icon,
                                  size: 68,
                                  color: scheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ),
                        rise(
                          0,
                          Column(
                            spacing: 4,
                            children: [
                              Text(
                                widget.kicker.toUpperCase(),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: scheme.tertiaryContainer,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (widget.subtitle != null)
                                Text(
                                  widget.subtitle!,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (widget.points > 0)
                          rise(
                            1,
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Text(
                                // I punti salgono veloci e rallentano.
                                '+${(widget.points * _part(0.25, 0.85)).round()} punti',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: scheme.onTertiaryContainer,
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        rise(
                          2,
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Continua'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.t, required this.colors});

  final double t;
  final List<Color> colors;

  static const _count = 48;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final origin = Offset(size.width / 2, size.height * 0.3);
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final angle = i / _count * math.pi * 2 + (i % 3) * 0.2;
      final dist = 140 + (i * 37) % 120;
      // Volano verso l'esterno e poi cadono.
      final dx = math.cos(angle) * dist * t;
      final dy = math.sin(angle) * dist * 1.3 * t + 160 * t * t;
      final opacity = t < 0.1 ? t * 10 : (1 - t).clamp(0.0, 1.0);
      paint.color = colors[i % colors.length].withValues(alpha: opacity);
      canvas
        ..save()
        ..translate(origin.dx + dx, origin.dy + dy)
        ..rotate((i * 47 % 540) * math.pi / 180 * t);
      final w = 6.0 + (i % 3) * 3;
      final h = i.isOdd ? 10.0 : 6.0;
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w, height: h),
            const Radius.circular(2),
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
