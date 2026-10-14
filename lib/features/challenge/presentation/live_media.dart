// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../camera/presentation/rep_camera.dart';

/// Anteprima della tua fotocamera che conta i push-up.
class LocalCameraView extends StatelessWidget {
  const LocalCameraView({super.key, required this.onRep});

  final VoidCallback onRep;

  @override
  Widget build(BuildContext context) =>
      RepCameraView(onRep: onRep, compact: true);
}
