import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'rider_map_image.dart';

String friendPinImageId({required String userId, required bool live}) {
  final tag = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  return 'aether-friend-$tag-${live ? 'live' : 'stale'}';
}

/// Kreis-Pin mit Fahrer-Silhouette + Initialen. Live = Orange, stale = Ring.
Future<Uint8List> buildFriendPinPng({
  required bool live,
  required String initials,
}) async {
  const size = 128.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final c = Offset(size / 2, size / 2);
  final fill = live ? AppColors.accent : const Color(0xFF3A3A42);
  final ink = live ? const Color(0xFF121215) : const Color(0xFF6B6B74);
  final mark = live ? Colors.white : const Color(0xFFC8C8CE);

  if (live) {
    canvas.drawCircle(
      c,
      58,
      Paint()..color = AppColors.accent.withValues(alpha: 0.22),
    );
  } else {
    canvas.drawCircle(
      c,
      56,
      Paint()
        ..color = const Color(0x66C8C8CE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
  }
  canvas.drawCircle(c, 50, Paint()..color = fill);
  canvas.drawCircle(
    c,
    50,
    Paint()
      ..color = live ? Colors.white : const Color(0xFF9A9AA2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2,
  );

  try {
    final src = await decodeRiderAsset(live: live);
    final dest = Rect.fromCenter(center: Offset(c.dx, c.dy + 10), width: 72, height: 72);
    canvas.drawImageRect(
      src,
      Rect.fromLTWH(0, 0, src.width.toDouble(), src.height.toDouble()),
      dest,
      Paint()..filterQuality = FilterQuality.high,
    );
  } catch (_) {
    _paintRider(canvas, Offset(c.dx, c.dy + 18), mark, live ? AppColors.accent : ink);
  }

  final text = initials.trim().isEmpty ? '?' : initials.trim().toUpperCase();
  final tp = TextPainter(
    text: TextSpan(
      text: text.length > 2 ? text.substring(0, 2) : text,
      style: TextStyle(
        color: mark,
        fontSize: text.length >= 2 ? 28 : 34,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - 38));

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

void _paintRider(Canvas canvas, Offset at, Color mark, Color accent) {
  canvas.save();
  canvas.translate(at.dx - 22, at.dy - 16);
  canvas.scale(0.92);
  final stroke = Paint()
    ..color = mark
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  canvas.drawCircle(const Offset(10, 30), 7.0, stroke);
  canvas.drawCircle(const Offset(35, 30), 7.0, stroke);
  canvas.drawCircle(const Offset(10, 30), 1.7, Paint()..color = accent);
  canvas.drawCircle(const Offset(35, 30), 1.7, Paint()..color = accent);
  final frame = Path()
    ..moveTo(10, 30)
    ..lineTo(18, 30)
    ..lineTo(16, 16)
    ..lineTo(29, 18)
    ..lineTo(18, 30);
  canvas.drawPath(frame, stroke);
  canvas.drawLine(const Offset(16, 16), const Offset(10, 30), stroke);
  canvas.drawLine(const Offset(29, 18), const Offset(35, 30), stroke);
  canvas.drawLine(const Offset(29, 18), const Offset(28, 10), stroke);
  canvas.drawLine(const Offset(28, 10), const Offset(36, 9), stroke);

  final jersey = Paint()
    ..color = accent
    ..strokeWidth = 3.4
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  canvas.drawOval(const Rect.fromLTWH(26.2, 1.2, 8.6, 5.6), Paint()..color = mark);
  canvas.drawCircle(const Offset(29.6, 6.6), 2.7, Paint()..color = mark);
  canvas.drawLine(const Offset(27.4, 9.2), const Offset(18.5, 22), jersey);
  canvas.drawLine(const Offset(26.8, 10.6), const Offset(35.2, 9.2), jersey);
  canvas.drawLine(
    const Offset(18.8, 20),
    const Offset(12.5, 30),
    Paint()
      ..color = mark
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round,
  );
  canvas.drawLine(
    const Offset(19.0, 20),
    const Offset(26.5, 30),
    Paint()
      ..color = mark
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round,
  );
  canvas.restore();
}
