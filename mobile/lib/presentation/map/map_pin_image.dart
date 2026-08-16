import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

/// Simple circle pin for MapLibre `addImage` — OpenFreeMap has no `marker-15`.
/// Default fill is cartographic green; orange pins pass [AppColors.accent].
Future<Uint8List> buildMapPinPng({
  Color fill = const Color(0xFF00C853),
  Color stroke = AppColors.hofGround,
}) async {
  const size = 64.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final fillPaint = Paint()..color = fill;
  final strokePaint = Paint()
    ..color = stroke
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  canvas.drawCircle(const Offset(size / 2, size / 2), 22, fillPaint);
  canvas.drawCircle(const Offset(size / 2, size / 2), 22, strokePaint);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}
