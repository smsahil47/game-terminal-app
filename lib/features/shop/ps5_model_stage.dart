import 'dart:io';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../core/theme/app_theme.dart';

/// The same local PS5 model used in the website's station cards.
class Ps5ModelStage extends StatelessWidget {
  const Ps5ModelStage({super.key, this.height = 170});
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: double.infinity,
    decoration: BoxDecoration(
      color: AppTheme.surface,
      border: Border.all(color: AppTheme.border),
      borderRadius: BorderRadius.circular(9),
    ),
    clipBehavior: Clip.antiAlias,
    child: Platform.isAndroid || Platform.isIOS
        ? const ModelViewer(
            src: 'assets/brand/ps5.glb',
            alt: 'PlayStation 5 console',
            backgroundColor: AppTheme.surface,
            autoRotate: true,
            autoRotateDelay: 0,
            rotationPerSecond: '12deg',
            cameraControls: false,
            disableZoom: true,
            interactionPrompt: InteractionPrompt.none,
            ar: false,
            debugLogging: false,
          )
        : Image.asset('assets/brand/ps5.webp', fit: BoxFit.contain),
  );
}
