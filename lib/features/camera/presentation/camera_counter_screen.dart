// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/discipline_theme.dart';
import '../domain/rep_counter.dart';
import 'rep_camera.dart';

/// Conta i push-up con la fotocamera e restituisce il totale.
class CameraCounterScreen extends StatefulWidget {
  const CameraCounterScreen({super.key});

  @override
  State<CameraCounterScreen> createState() => _CameraCounterScreenState();
}

class _CameraCounterScreenState extends State<CameraCounterScreen> {
  final _state = RepCameraController();
  var _front = true;
  var _manual = 0;
  var _cameraKey = 0;

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  int get _total => _state.count + _manual;

  /// Restituisce le ripetizioni viste dalla fotocamera e quelle aggiunte a
  /// mano, separate: solo le prime valgono come "verificate".
  void _finish() =>
      context.pop<CameraCount>((camera: _state.count, manual: _manual));

  @override
  Widget build(BuildContext context) {
    final dark = DisciplineTheme.dark;
    final scheme = dark.colorScheme;
    return Theme(
      data: dark,
      child: ListenableBuilder(
        listenable: _state,
        builder: (context, _) {
          final counter = _state.counter;
          final String status;
          if (_state.error != null) {
            status = _state.error!;
          } else if (_state.badForm) {
            status = 'Tieni la schiena dritta: questa non vale';
          } else if (!_state.personVisible) {
            status =
                'Metti il telefono a terra, di lato: devo vederti '
                'tutto il corpo';
          } else if (counter.phase == RepPhase.searching) {
            status = 'Ti vedo! Parti in alto, braccia tese';
          } else {
            status = counter.phase == RepPhase.down
                ? 'Spingi!'
                : 'Scendi finché i gomiti arrivano a 90°';
          }
          return Scaffold(
            backgroundColor: scheme.surface,
            appBar: AppBar(
              backgroundColor: scheme.surface,
              title: const Text('Conta con la fotocamera'),
              actions: [
                IconButton(
                  tooltip: _front
                      ? 'Usa la fotocamera posteriore'
                      : 'Usa la fotocamera anteriore',
                  icon: const Icon(Icons.cameraswitch_outlined),
                  onPressed: () => setState(() {
                    _front = !_front;
                    _cameraKey++;
                  }),
                ),
              ],
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          DisciplineRadii.cardLarge,
                        ),
                        child: ColoredBox(
                          color: scheme.surfaceContainerHigh,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              RepCameraView(
                                key: ValueKey(_cameraKey),
                                front: _front,
                                controller: _state,
                                onRep: () {},
                              ),
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 12,
                                child: Semantics(
                                  liveRegion: true,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: _state.badForm
                                          ? scheme.errorContainer
                                          : scheme.surfaceContainer.withValues(
                                              alpha: 0.9,
                                            ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        status,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: _state.badForm
                                              ? scheme.onErrorContainer
                                              : scheme.onSurface,
                                        ),
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
                    Semantics(
                      liveRegion: true,
                      label: '$_total push-up',
                      excludeSemantics: true,
                      child: Text(
                        '$_total',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 72,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      _manual == 0
                          ? 'push-up contati'
                          : 'push-up contati ($_manual a mano)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    Row(
                      spacing: 12,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 56),
                          ),
                          onPressed: () => setState(() => _manual++),
                          child: const Text('+1 a mano'),
                        ),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                            ),
                            onPressed: _finish,
                            child: const Text('Fatto'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Risultato del conteggio con la fotocamera.
typedef CameraCount = ({int camera, int manual});
