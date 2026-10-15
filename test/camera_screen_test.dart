// Discipline — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Discipline contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:discipline/core/router/routes.dart';
import 'package:discipline/features/camera/data/pose_camera.dart';
import 'package:discipline/features/camera/domain/rep_counter.dart';

import 'features/rep_counter_test.dart' as counter;

import 'package:discipline/features/camera/presentation/camera_counter_screen.dart';

import 'helpers.dart';

class FakeSession implements PoseCameraSession {
  final controller = StreamController<PoseFrame?>.broadcast();
  var closed = false;

  @override
  Stream<PoseFrame?> get frames => controller.stream;

  @override
  Widget buildPreview() => const ColoredBox(color: Colors.black);

  @override
  Future<void> close() async => closed = true;
}

class FakeCamera implements PoseCamera {
  FakeCamera({this.error});

  final String? error;
  final session = FakeSession();

  @override
  Future<PoseCameraSession> open({required bool front}) async {
    if (error != null) throw PoseCameraException(error!);
    return session;
  }
}

/// Manda i fotogrammi uno alla volta, lasciando girare l'interfaccia.
Future<void> send(
  WidgetTester tester,
  FakeSession session,
  Iterable<PoseFrame?> frames,
) async {
  for (final f in frames) {
    session.controller.add(f);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  await tester.pump();
}

void main() {
  testWidgets('conta i push-up dai fotogrammi e restituisce il totale', (
    tester,
  ) async {
    final camera = FakeCamera();
    CameraCount? result;
    final db = memoryDatabase();
    await seedProfile(db);
    await pumpDiscipline(
      tester,
      db,
      extra: [poseCameraProvider.overrideWithValue(camera)],
    );
    final context = tester.element(find.byType(Scaffold).first);
    unawaited(
      GoRouter.of(context)
          .push<CameraCount>(Routes.cameraCounter)
          .then((v) => result = v),
    );
    await settle(tester);

    expect(find.textContaining('devo vederti tutto il corpo'), findsOneWidget);

    await send(tester, camera.session, [
      counter.frame(elbowDeg: 175),
      ...counter.pushUp(),
      ...counter.pushUp(),
    ]);
    expect(find.text('2'), findsOneWidget);

    await send(tester, camera.session, counter.pushUp(hipDeg: 130));
    expect(find.textContaining('schiena dritta'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('+1 a mano'));
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
    expect(find.text('push-up contati (1 a mano)'), findsOneWidget);

    await tester.tap(find.text('Fatto'));
    await settle(tester);
    // Solo 2 viste dalla fotocamera: quella a mano non è "verificata".
    expect(result, (camera: 2, manual: 1));
    expect(camera.session.closed, isTrue);
    await disposeDiscipline(tester, db);
  });

  testWidgets('permesso negato: messaggio e conteggio a mano', (tester) async {
    final camera = FakeCamera(error: 'Discipline non ha il permesso.');
    final db = memoryDatabase();
    await seedProfile(db);
    await pumpDiscipline(
      tester,
      db,
      extra: [poseCameraProvider.overrideWithValue(camera)],
    );
    final context = tester.element(find.byType(Scaffold).first);
    unawaited(GoRouter.of(context).push<CameraCount>(Routes.cameraCounter));
    await settle(tester);
    expect(find.text('Discipline non ha il permesso.'), findsOneWidget);
    await tester.tap(find.text('+1 a mano'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    await disposeDiscipline(tester, db);
  });
}
