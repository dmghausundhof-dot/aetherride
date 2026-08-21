import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

String friendPinImageId({required String userId, required bool live}) {
  final tag = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  return 'aether-friend-$tag-${live ? 'live' : 'stale'}';
}

/// Flache Scheibe mit Initialen. Live = Accent, stale = Ring. Kein 3D.
Future<Uint8List> buildFriendPinPng({
  required bool live,
  required String initials,
}) async {
  const size = 96.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const c = Offset(48, 48);
  final fill = live ? AppColors.accent : AppColors.overlay;
  final ink = live ? AppColors.onAccent : AppColors.muted;
  final ring = live ? AppColors.accent : AppColors.border;

  canvas.drawCircle(c, 36, Paint()..color = fill);
  canvas.drawCircle(
    c,
    36,
    Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );

  final text = initials.trim().isEmpty ? '?' : initials.trim().toUpperCase();
  final shown = text.length > 2 ? text.substring(0, 2) : text;
  final tp = TextPainter(
    text: TextSpan(
      text: shown,
      style: TextStyle(
        color: ink,
        fontSize: shown.length >= 2 ? 28 : 34,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}
