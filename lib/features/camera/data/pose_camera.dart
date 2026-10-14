// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/rep_counter.dart';

/// Errore da mostrare così com'è (permesso negato, nessuna fotocamera...).
class PoseCameraException implements Exception {
  const PoseCameraException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Una fotocamera aperta che manda i corpi trovati nelle immagini.
abstract interface class PoseCameraSession {
  Widget buildPreview();

  /// Un valore per fotogramma elaborato (null = nessuna persona).
  Stream<PoseFrame?> get frames;

  Future<void> close();
}

/// Apre la fotocamera. L'implementazione reale usa `camera` e ML Kit
/// (tutto sul telefono: le immagini non vengono mai inviate a nessuno).
abstract interface class PoseCamera {
  Future<PoseCameraSession> open({required bool front});
}

final poseCameraProvider = Provider<PoseCamera>((ref) => MlKitPoseCamera());

class MlKitPoseCamera implements PoseCamera {
  @override
  Future<PoseCameraSession> open({required bool front}) async {
    final List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } on CameraException catch (e) {
      throw PoseCameraException(_message(e));
    }
    final wanted = front ? CameraLensDirection.front : CameraLensDirection.back;
    final camera =
        cameras.where((c) => c.lensDirection == wanted).firstOrNull ??
        cameras.firstOrNull;
    if (camera == null) {
      throw const PoseCameraException('Non trovo nessuna fotocamera.');
    }
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    try {
      await controller.initialize();
    } on CameraException catch (e) {
      await controller.dispose();
      throw PoseCameraException(_message(e));
    }
    final session = _MlKitSession(controller, camera);
    await session.start();
    return session;
  }

  static String _message(CameraException e) => switch (e.code) {
    'CameraAccessDenied' ||
    'CameraAccessDeniedWithoutPrompt' ||
    'CameraAccessRestricted' =>
      'Ritmo non ha il permesso di usare la fotocamera. Puoi darlo dalle '
          'impostazioni del telefono, oppure contare a mano.',
    _ => 'Non riesco ad aprire la fotocamera. Puoi contare a mano.',
  };
}

class _MlKitSession implements PoseCameraSession {
  _MlKitSession(this._controller, this._camera);

  final CameraController _controller;
  final CameraDescription _camera;
  final _detector = PoseDetector(options: PoseDetectorOptions());
  final _frames = StreamController<PoseFrame?>.broadcast();
  var _busy = false;
  var _closed = false;

  @override
  Stream<PoseFrame?> get frames => _frames.stream;

  Future<void> start() => _controller.startImageStream(_onImage);

  @override
  Widget buildPreview() => CameraPreview(_controller);

  Future<void> _onImage(CameraImage image) async {
    // Un fotogramma alla volta: se il rilevatore è occupato, si salta.
    if (_busy || _closed) return;
    _busy = true;
    try {
      final input = _toInputImage(image);
      if (input == null) return;
      final poses = await _detector.processImage(input);
      if (!_closed) _frames.add(poses.isEmpty ? null : _toFrame(poses.first));
    } catch (_) {
      // Fotogramma rovinato: si passa al prossimo.
    } finally {
      _busy = false;
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    // L'app è sempre in verticale: la rotazione è quella del sensore.
    final rotation = InputImageRotationValue.fromRawValue(
      _camera.sensorOrientation,
    );
    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (rotation == null || format == null) return null;
    final supported = Platform.isAndroid
        ? format == InputImageFormat.nv21
        : format == InputImageFormat.bgra8888;
    if (!supported || image.planes.length != 1) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  PoseFrame _toFrame(Pose pose) {
    Landmark? point(PoseLandmarkType type) {
      final l = pose.landmarks[type];
      return l == null ? null : Landmark(l.x, l.y, likelihood: l.likelihood);
    }

    BodySide? side(
      PoseLandmarkType shoulder,
      PoseLandmarkType elbow,
      PoseLandmarkType wrist,
      PoseLandmarkType hip,
      PoseLandmarkType ankle,
    ) {
      final s = point(shoulder);
      final e = point(elbow);
      final w = point(wrist);
      final h = point(hip);
      final a = point(ankle);
      if (s == null || e == null || w == null || h == null || a == null) {
        return null;
      }
      return BodySide(shoulder: s, elbow: e, wrist: w, hip: h, ankle: a);
    }

    return PoseFrame(
      left: side(
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftWrist,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.leftAnkle,
      ),
      right: side(
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightElbow,
        PoseLandmarkType.rightWrist,
        PoseLandmarkType.rightHip,
        PoseLandmarkType.rightAnkle,
      ),
    );
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      if (_controller.value.isStreamingImages) {
        await _controller.stopImageStream();
      }
    } catch (_) {}
    await _controller.dispose();
    await _detector.close();
    await _frames.close();
  }
}
