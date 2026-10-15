// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/pose_camera.dart';
import '../domain/rep_counter.dart';

/// Fotocamera che conta i push-up: anteprima, conteggio e stato.
///
/// Si occupa di aprire e chiudere la fotocamera; chi la usa riceve le
/// ripetizioni da [onRep] e può ridisegnare lo stato con [overlay].
class RepCameraView extends ConsumerStatefulWidget {
  const RepCameraView({
    super.key,
    required this.onRep,
    this.controller,
    this.front = true,
    this.compact = false,
    this.onError,
  });

  final VoidCallback onRep;

  /// Per leggere il conteggio dall'esterno e azzerarlo.
  final RepCameraController? controller;
  final bool front;

  /// Versione piccola (dentro la sfida): niente testi grandi.
  final bool compact;
  final ValueChanged<String>? onError;

  @override
  ConsumerState<RepCameraView> createState() => _RepCameraViewState();
}

/// Stato del conteggio, leggibile dall'esterno.
class RepCameraController extends ChangeNotifier {
  final counter = PushUpCounter();
  var badForm = false;
  var personVisible = false;
  String? error;

  int get count => counter.count;

  void reset() {
    counter.reset();
    badForm = false;
    notifyListeners();
  }

  void _changed() => notifyListeners();
}

class _RepCameraViewState extends ConsumerState<RepCameraView> {
  late final RepCameraController _state;
  PoseCameraSession? _session;
  StreamSubscription<PoseFrame?>? _sub;
  var _loading = true;
  Timer? _formReset;

  @override
  void initState() {
    super.initState();
    _state = widget.controller ?? RepCameraController();
    unawaited(_open());
  }

  Future<void> _open() async {
    // Nuova fotocamera (es. cambio frontale/posteriore): via l'errore vecchio.
    // (Avviso dopo il frame: qui siamo ancora dentro initState.)
    if (_state.error != null) {
      _state.error = null;
      scheduleMicrotask(_state._changed);
    }
    try {
      final session = await ref
          .read(poseCameraProvider)
          .open(front: widget.front);
      if (!mounted) {
        await session.close();
        return;
      }
      _session = session;
      _sub = session.frames.listen(_onFrame);
      setState(() => _loading = false);
    } on PoseCameraException catch (e) {
      if (!mounted) return;
      _state
        ..error = e.message
        .._changed();
      widget.onError?.call(e.message);
      setState(() => _loading = false);
    }
  }

  void _onFrame(PoseFrame? frame) {
    final counter = _state.counter;
    final event = counter.update(frame);
    _state.personVisible = frame?.best(counter.minLikelihood) != null;
    switch (event) {
      case RepEvent.rep:
        _state.badForm = false;
        unawaited(HapticFeedback.lightImpact());
        widget.onRep();
      case RepEvent.badForm:
        _state.badForm = true;
        unawaited(HapticFeedback.heavyImpact());
        _formReset?.cancel();
        _formReset = Timer(const Duration(seconds: 2), () {
          _state.badForm = false;
          _state._changed();
        });
      case RepEvent.none:
        break;
    }
    _state._changed();
  }

  @override
  void dispose() {
    _formReset?.cancel();
    unawaited(_sub?.cancel());
    unawaited(_session?.close());
    if (widget.controller == null) _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final session = _session;
    if (session == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(Icons.videocam_off, color: scheme.onSurfaceVariant),
        ),
      );
    }
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(width: 240, height: 320, child: session.buildPreview()),
      ),
    );
  }
}
