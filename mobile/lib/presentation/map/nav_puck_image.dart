import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import 'rider_map_image.dart';

/// MapLibre image-id prefix. Pro Style: [navPuckImageId].
const kNavPuckImageId = 'aether-nav-puck';

/// Native MapLibre location-puck layers (Android). Accuracy-Halo bleibt.
const kNativeLocationPuckLayerIds = <String>[
  'mapbox-location-foreground-layer',
  'mapbox-location-bearing-layer',
  'mapbox-location-background-layer',
  'mapbox-location-shadow-layer',
  'mapbox-location-pulsing-circle-layer',
];

/// Navi-Puck auf Karte und HUD. Default: [rider] (3D-Fahrer).
enum NavPuckStyle {
  rider,
  bergA,
  topDownBike,
  hofTor,
  aetherKomet,
  kiesel,
  lenkerBug,
  lichtkegel,
  chevron,
}

extension NavPuckStyleX on NavPuckStyle {
  String get id => name;

  String get imageId => navPuckImageId(this);

  String get titleDe => switch (this) {
        NavPuckStyle.rider => 'Fahrer',
        NavPuckStyle.bergA => 'Berg-A',
        NavPuckStyle.topDownBike => 'Rad von oben',
        NavPuckStyle.hofTor => 'Hof-Tor',
        NavPuckStyle.aetherKomet => 'Aether-Komet',
        NavPuckStyle.kiesel => 'Kiesel',
        NavPuckStyle.lenkerBug => 'Lenker-Bug',
        NavPuckStyle.lichtkegel => 'Lichtkegel',
        NavPuckStyle.chevron => 'Chevron',
      };

  String get subtitleDe => switch (this) {
        NavPuckStyle.rider =>
          '3D-Fahrer im FlowLine-Orange — Standort und Tourpunkte',
        NavPuckStyle.bergA => 'Buchstabe, Berg und Pfeil in einem',
        NavPuckStyle.topDownBike =>
          'Orthografisch: Nase, Hörner, zwei Reifen — dreht mit',
        NavPuckStyle.hofTor => 'Zwei Schenkel, unten offen',
        NavPuckStyle.aetherKomet => 'Speerblatt mit orangem Funken',
        NavPuckStyle.kiesel => 'Weiches Dreieck mit Halo',
        NavPuckStyle.lenkerBug => 'Spitze Nase, zwei Lenkerhörner',
        NavPuckStyle.lichtkegel => 'Dunkle Scheibe, oranger Kegel',
        NavPuckStyle.chevron => 'Klassischer Navi-Pfeil, etwas kleiner',
      };

  bool get isRecommended => this == NavPuckStyle.rider;

  bool get usesRiderAsset => this == NavPuckStyle.rider;

  /// 3D-Fahrer größer, klassischer Pfeil etwas kleiner.
  double get mapIconSize => usesRiderAsset
      ? RiderMapIconSize.nav
      : RiderMapIconSize.navClassic;

  static NavPuckStyle fromId(String? raw) {
    for (final s in NavPuckStyle.values) {
      if (s.id == raw) return s;
    }
    return NavPuckStyle.rider;
  }
}

String navPuckTitle(AppLocalizations? l10n, NavPuckStyle style) {
  if (l10n == null) return style.titleDe;
  return switch (style) {
    NavPuckStyle.rider => l10n.ridePuckRider,
    NavPuckStyle.bergA => l10n.ridePuckBergA,
    NavPuckStyle.topDownBike => l10n.ridePuckTopDown,
    NavPuckStyle.hofTor => l10n.ridePuckHofTor,
    NavPuckStyle.aetherKomet => l10n.ridePuckKomet,
    NavPuckStyle.kiesel => l10n.ridePuckKiesel,
    NavPuckStyle.lenkerBug => l10n.ridePuckLenkerBug,
    NavPuckStyle.lichtkegel => l10n.ridePuckLichtkegel,
    NavPuckStyle.chevron => l10n.ridePuckChevron,
  };
}

String navPuckSubtitle(AppLocalizations? l10n, NavPuckStyle style) {
  if (l10n == null) return style.subtitleDe;
  return switch (style) {
    NavPuckStyle.rider => l10n.ridePuckRiderSub,
    NavPuckStyle.bergA => l10n.ridePuckBergASub,
    NavPuckStyle.topDownBike => l10n.ridePuckTopDownSub,
    NavPuckStyle.hofTor => l10n.ridePuckHofTorSub,
    NavPuckStyle.aetherKomet => l10n.ridePuckKometSub,
    NavPuckStyle.kiesel => l10n.ridePuckKieselSub,
    NavPuckStyle.lenkerBug => l10n.ridePuckLenkerBugSub,
    NavPuckStyle.lichtkegel => l10n.ridePuckLichtkegelSub,
    NavPuckStyle.chevron => l10n.ridePuckChevronSub,
  };
}

String navPuckImageId(NavPuckStyle style) => '$kNavPuckImageId-${style.id}';

/// Offizielle Profil-Wahl: 3D-Standard plus klassischer Pfeil.
/// Ein bereits gespeicherter Experiment-Stil bleibt sichtbar, bis man wechselt.
List<NavPuckStyle> navPuckProfileChoices(NavPuckStyle current) {
  const core = [NavPuckStyle.rider, NavPuckStyle.chevron];
  if (core.contains(current)) return core;
  return [...core, current];
}

/// Viewport- vs. map-aligned puck rotation.
///
/// Heading-up kippt die Karte (`tilt > 0` → `icon-rotation-alignment: viewport`).
/// Dann muss das Chevron um `heading − camera` gedreht werden, sonst doppelt.
/// Norden-oben (`tilt = 0` → map-aligned): Rotation = Heading relativ zu Nord.
double navPuckIconRotateDeg({
  required double headingDeg,
  required double cameraBearingDeg,
  required bool northUp,
}) {
  final heading = (headingDeg % 360 + 360) % 360;
  if (northUp) return heading;
  final cam = (cameraBearingDeg % 360 + 360) % 360;
  return (heading - cam + 360) % 360;
}

/// Spitze zeigt nach oben (0° = Norden / Fahrtrichtung).
void paintNavPuck(
  Canvas canvas,
  Size size, {
  NavPuckStyle style = NavPuckStyle.chevron,
  Color? fill,
  Color? stroke,
  Color? inner,
}) {
  final side = size.shortestSide;
  if (side <= 0) return;
  final origin = Offset(
    (size.width - side) / 2,
    (size.height - side) / 2,
  );
  canvas.save();
  canvas.translate(origin.dx, origin.dy);
  final sq = Size(side, side);
  final fillC = fill ?? AppColors.accent;
  final strokeC = stroke ?? AppColors.hofGround;
  final chrome = AppColors.chrome;
  final innerC = inner ??
      switch (style) {
        NavPuckStyle.rider => chrome,
        NavPuckStyle.bergA => chrome,
        NavPuckStyle.topDownBike => const Color(0xFFFFFFFF),
        NavPuckStyle.kiesel => const Color(0xFFFFFFFF),
        NavPuckStyle.chevron => const Color(0xFFFFFFFF),
        NavPuckStyle.aetherKomet => chrome,
        NavPuckStyle.hofTor => chrome,
        NavPuckStyle.lenkerBug => const Color(0xFFFFFFFF),
        NavPuckStyle.lichtkegel => chrome,
      };
  switch (style) {
    case NavPuckStyle.rider:
      _paintRiderFallback(canvas, sq, fillC, strokeC);
    case NavPuckStyle.chevron:
      _paintChevron(canvas, sq, fillC, strokeC, innerC);
    case NavPuckStyle.bergA:
      _paintBergA(canvas, sq, fillC, strokeC, innerC);
    case NavPuckStyle.topDownBike:
      _paintTopDownBike(canvas, sq, fillC, strokeC, innerC);
    case NavPuckStyle.hofTor:
      _paintHofTor(canvas, sq, fillC, strokeC);
    case NavPuckStyle.aetherKomet:
      _paintAetherKomet(canvas, sq, fillC, strokeC, chrome);
    case NavPuckStyle.kiesel:
      _paintKiesel(canvas, sq, strokeC, innerC);
    case NavPuckStyle.lenkerBug:
      _paintLenkerBug(canvas, sq, fillC, strokeC);
    case NavPuckStyle.lichtkegel:
      _paintLichtkegel(canvas, sq, fillC, strokeC, chrome);
  }
  canvas.restore();
}

void _paintRiderFallback(Canvas canvas, Size size, Color fill, Color stroke) {
  final s = size.shortestSide;
  canvas.save();
  canvas.translate(s * 0.18, s * 0.16);
  canvas.scale(s / 56);
  final frame = Paint()
    ..color = stroke
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.3
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  canvas.drawCircle(const Offset(10, 32), 7.2, frame);
  canvas.drawCircle(const Offset(36, 32), 7.2, frame);
  canvas.drawCircle(const Offset(10, 32), 1.8, Paint()..color = fill);
  canvas.drawCircle(const Offset(36, 32), 1.8, Paint()..color = fill);
  final diamond = Path()
    ..moveTo(10, 32)
    ..lineTo(19, 32)
    ..lineTo(17, 16)
    ..lineTo(30, 18)
    ..lineTo(19, 32);
  canvas.drawPath(diamond, frame);
  canvas.drawLine(const Offset(17, 16), const Offset(10, 32), frame);
  canvas.drawLine(const Offset(30, 18), const Offset(36, 32), frame);
  canvas.drawLine(const Offset(30, 18), const Offset(29, 10), frame);
  canvas.drawLine(const Offset(29, 10), const Offset(38, 9), frame);
  canvas.drawOval(const Rect.fromLTWH(26.4, 1.4, 9.2, 6), Paint()..color = stroke);
  canvas.drawCircle(const Offset(30.2, 7.2), 2.8, Paint()..color = const Color(0xFFE2A07A));
  canvas.drawLine(
    const Offset(28, 10),
    const Offset(19, 23),
    Paint()
      ..color = fill
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round,
  );
  canvas.restore();
}

void _strokeThenFill(
  Canvas canvas,
  Path path,
  Color fill,
  Color stroke,
  double strokeW,
) {
  canvas.drawPath(
    path,
    Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true,
  );
  canvas.drawPath(
    path,
    Paint()
      ..color = fill
      ..style = PaintingStyle.fill
      ..isAntiAlias = true,
  );
}

/// Chevron zeigt nach oben (0° = Norden / Fahrtrichtung).
void _paintChevron(
  Canvas canvas,
  Size size,
  Color fill,
  Color stroke,
  Color inner,
) {
  final side = size.shortestSide;
  final pad = side * 0.10;
  final cx = size.width / 2;
  final top = pad;
  final bottom = size.height - pad;
  final left = pad;
  final right = size.width - pad;

  Path chevron(double inset) {
    final t = top + inset;
    final b = bottom - inset * 0.45;
    final l = left + inset;
    final r = right - inset;
    final notchY = t + (b - t) * 0.60;
    return Path()
      ..moveTo(cx, t)
      ..lineTo(r, b)
      ..lineTo(cx, notchY)
      ..lineTo(l, b)
      ..close();
  }

  final outer = chevron(0);
  final innerPath = chevron(side * 0.16);
  final strokeW = (side * 0.10).clamp(2.0, 12.0);
  _strokeThenFill(canvas, outer, fill, stroke, strokeW);
  canvas.drawPath(
    innerPath,
    Paint()
      ..color = inner
      ..style = PaintingStyle.fill
      ..isAntiAlias = true,
  );
}

/// Splash-Spitze: Orange, dunkler Rand, oranger Keil, kleine Sockel-Kerbe.
void _paintBergA(
  Canvas canvas,
  Size size,
  Color fill,
  Color stroke,
  Color chrome,
) {
  final s = size.shortestSide;
  final pad = s * 0.10;
  final cx = s / 2;
  final top = pad;
  final base = s * 0.86;
  final left = s * 0.12;
  final right = s * 0.88;
  final notchW = s * 0.16;
  final notchD = s * 0.07;

  final outer = Path()
    ..moveTo(cx, top)
    ..lineTo(right, base)
    ..lineTo(cx + notchW / 2, base)
    ..lineTo(cx, base - notchD)
    ..lineTo(cx - notchW / 2, base)
    ..lineTo(left, base)
    ..close();

  final strokeW = (s * 0.09).clamp(2.0, 11.0);
  _strokeThenFill(canvas, outer, fill, stroke, strokeW);

  final wedgeTop = top + s * 0.30;
  final wedgeBase = top + (base - top) * 0.58;
  final wedgeHalf = s * 0.11;
  final wedge = Path()
    ..moveTo(cx, wedgeTop)
    ..lineTo(cx + wedgeHalf, wedgeBase)
    ..lineTo(cx - wedgeHalf, wedgeBase)
    ..close();
  canvas.drawPath(
    wedge,
    Paint()
      ..color = chrome
      ..style = PaintingStyle.fill
      ..isAntiAlias = true,
  );
}

/// Zwei schräge Schenkel, unten offen — wie das Splash-Tor.
void _paintHofTor(
  Canvas canvas,
  Size size,
  Color fill,
  Color stroke,
) {
  final s = size.shortestSide;
  final pad = s * 0.10;
  final cx = s / 2;
  final top = pad;
  final bottom = s - pad;
  final left = s * 0.14;
  final right = s * 0.86;
  final leg = s * 0.20;

  final path = Path()
    ..moveTo(left, bottom)
    ..lineTo(cx, top)
    ..lineTo(right, bottom)
    ..lineTo(right - leg, bottom)
    ..lineTo(cx, top + leg * 1.55)
    ..lineTo(left + leg, bottom)
    ..close();

  final strokeW = (s * 0.09).clamp(2.0, 11.0);
  _strokeThenFill(canvas, path, fill, stroke, strokeW);
}

/// Weiches Speerblatt + oranger Funke am Heck.
void _paintAetherKomet(
  Canvas canvas,
  Size size,
  Color fill,
  Color stroke,
  Color chrome,
) {
  final s = size.shortestSide;
  final cx = s / 2;
  final top = s * 0.08;
  final spearBot = s * 0.70;
  final half = s * 0.22;

  final spear = Path()
    ..moveTo(cx, top)
    ..quadraticBezierTo(
        cx + half, (top + spearBot) * 0.42, cx + half * 0.42, spearBot)
    ..quadraticBezierTo(cx, spearBot + s * 0.05, cx - half * 0.42, spearBot)
    ..quadraticBezierTo(cx - half, (top + spearBot) * 0.42, cx, top)
    ..close();

  final strokeW = (s * 0.08).clamp(1.8, 10.0);
  _strokeThenFill(canvas, spear, fill, stroke, strokeW);

  final sparkR = (s * 0.09).clamp(2.5, 14.0);
  final spark = Offset(cx, s * 0.86);
  canvas.drawCircle(
    spark,
    sparkR + strokeW * 0.35,
    Paint()
      ..color = stroke
      ..style = PaintingStyle.fill
      ..isAntiAlias = true,
  );
  canvas.drawCircle(
    spark,
    sparkR,
    Paint()
      ..color = chrome
      ..style = PaintingStyle.fill
      ..isAntiAlias = true,
  );
}

/// Organisches, bauchiges Dreieck — weiß innen, dunkler Halo.
void _paintKiesel(
  Canvas canvas,
  Size size,
  Color halo,
  Color inner,
) {
  final s = size.shortestSide;
  final a = Offset(s / 2, s * 0.10);
  final b = Offset(s * 0.90, s * 0.86);
  final c = Offset(s * 0.10, s * 0.86);
  final bulge = s * 0.09;
  final corner = s * 0.16;
  final path = _pebblyTriangle(a, b, c, bulge, corner);

  final cx = s / 2;
  final cy = (a.dy + b.dy + c.dy) / 3;
  canvas.save();
  canvas.translate(cx, cy);
  canvas.scale(1.16);
  canvas.translate(-cx, -cy);
  canvas.drawPath(
    path,
    Paint()
      ..color = halo
      ..style = PaintingStyle.fill
      ..isAntiAlias = true,
  );
  canvas.restore();
  canvas.drawPath(
    path,
    Paint()
      ..color = inner
      ..style = PaintingStyle.fill
      ..isAntiAlias = true,
  );
}

Path _pebblyTriangle(
  Offset a,
  Offset b,
  Offset c,
  double bulge,
  double cornerR,
) {
  final centroid = Offset(
    (a.dx + b.dx + c.dx) / 3,
    (a.dy + b.dy + c.dy) / 3,
  );
  Offset along(Offset from, Offset to, double dist) {
    final v = to - from;
    final len = v.distance;
    if (len < 1e-4) return from;
    return from + v * (dist / len).clamp(0.0, 0.42);
  }

  Offset ctrl(Offset p, Offset q) {
    final mid = Offset((p.dx + q.dx) / 2, (p.dy + q.dy) / 2);
    var n = Offset(mid.dx - centroid.dx, mid.dy - centroid.dy);
    final d = n.distance;
    if (d < 1e-4) return mid;
    n = Offset(n.dx / d, n.dy / d);
    return mid + n * bulge;
  }

  final aToB = along(a, b, cornerR);
  final aToC = along(a, c, cornerR);
  final bToA = along(b, a, cornerR);
  final bToC = along(b, c, cornerR);
  final cToB = along(c, b, cornerR);
  final cToA = along(c, a, cornerR);

  return Path()
    ..moveTo(aToB.dx, aToB.dy)
    ..quadraticBezierTo(ctrl(a, b).dx, ctrl(a, b).dy, bToA.dx, bToA.dy)
    ..quadraticBezierTo(b.dx, b.dy, bToC.dx, bToC.dy)
    ..quadraticBezierTo(ctrl(b, c).dx, ctrl(b, c).dy, cToB.dx, cToB.dy)
    ..quadraticBezierTo(c.dx, c.dy, cToA.dx, cToA.dy)
    ..quadraticBezierTo(ctrl(c, a).dx, ctrl(c, a).dy, aToC.dx, aToC.dy)
    ..quadraticBezierTo(a.dx, a.dy, aToB.dx, aToB.dy)
    ..close();
}

/// Orthografisches Top-down-Rad: Nase + Hörner + Vorder-/Hinterreifen.
/// Keine isometrische ¾-Ansicht — Heading kommt von MapLibre `iconRotate`.
void _paintTopDownBike(
  Canvas canvas,
  Size size,
  Color frame,
  Color stroke,
  Color tireInner,
) {
  final s = size.shortestSide;
  final cx = s / 2;
  final strokeW = (s * 0.08).clamp(1.8, 10.0);

  final nose = Path()
    ..moveTo(cx, s * 0.05)
    ..lineTo(cx + s * 0.11, s * 0.22)
    ..lineTo(cx - s * 0.11, s * 0.22)
    ..close();

  final barY = s * 0.36;
  final hornTipY = s * 0.20;
  final hornOut = s * 0.12;
  final horns = Path()
    ..moveTo(hornOut, hornTipY)
    ..quadraticBezierTo(s * 0.20, barY, cx - s * 0.09, barY)
    ..lineTo(cx + s * 0.09, barY)
    ..quadraticBezierTo(s * 0.80, barY, s - hornOut, hornTipY)
    ..lineTo(s - hornOut + s * 0.01, hornTipY + s * 0.07)
    ..quadraticBezierTo(
      s * 0.78,
      barY + s * 0.06,
      cx + s * 0.08,
      barY + s * 0.07,
    )
    ..lineTo(cx - s * 0.08, barY + s * 0.07)
    ..quadraticBezierTo(
      s * 0.22,
      barY + s * 0.06,
      hornOut - s * 0.01,
      hornTipY + s * 0.07,
    )
    ..close();

  final body = RRect.fromLTRBR(
    cx - s * 0.075,
    s * 0.28,
    cx + s * 0.075,
    s * 0.78,
    Radius.circular(s * 0.075),
  );

  _strokeThenFill(canvas, nose, frame, stroke, strokeW);
  _strokeThenFill(canvas, horns, frame, stroke, strokeW);
  canvas.drawRRect(
    body,
    Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true,
  );
  canvas.drawRRect(
    body,
    Paint()
      ..color = frame
      ..style = PaintingStyle.fill
      ..isAntiAlias = true,
  );

  void tire(Offset c, double r) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
    canvas.drawCircle(
      c,
      r * 0.58,
      Paint()
        ..color = tireInner
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  tire(Offset(cx, s * 0.30), s * 0.12);
  tire(Offset(cx, s * 0.76), s * 0.135);
}

/// Von oben: spitze Nase, zwei winzige Lenkerhörner.
void _paintLenkerBug(
  Canvas canvas,
  Size size,
  Color fill,
  Color stroke,
) {
  final s = size.shortestSide;
  final cx = s / 2;
  final top = s * 0.08;
  final rear = s * 0.82;
  final bodyL = s * 0.30;
  final bodyR = s * 0.70;
  final hornY = s * 0.58;
  final hornOut = s * 0.08;
  final hornH = s * 0.055;
  final hornSweep = s * 0.02;

  final path = Path()
    ..moveTo(cx, top)
    ..quadraticBezierTo(s * 0.72, s * 0.32, bodyR, hornY - hornH)
    ..lineTo(s - hornOut, hornY - hornH + hornSweep)
    ..quadraticBezierTo(
      s - hornOut * 0.35,
      hornY + hornH * 0.2,
      s - hornOut,
      hornY + hornH + hornSweep,
    )
    ..lineTo(bodyR, hornY + hornH)
    ..quadraticBezierTo(s * 0.68, rear - s * 0.02, cx + s * 0.10, rear)
    ..quadraticBezierTo(cx, rear + s * 0.04, cx - s * 0.10, rear)
    ..quadraticBezierTo(s * 0.32, rear - s * 0.02, bodyL, hornY + hornH)
    ..lineTo(hornOut, hornY + hornH + hornSweep)
    ..quadraticBezierTo(
      hornOut * 0.35,
      hornY + hornH * 0.2,
      hornOut,
      hornY - hornH + hornSweep,
    )
    ..lineTo(bodyL, hornY - hornH)
    ..quadraticBezierTo(s * 0.28, s * 0.32, cx, top)
    ..close();

  final strokeW = (s * 0.08).clamp(1.8, 10.0);
  _strokeThenFill(canvas, path, fill, stroke, strokeW);
}

/// Dunkle Scheibe plus kurzer oranger Kegel nach vorn.
void _paintLichtkegel(
  Canvas canvas,
  Size size,
  Color coneFill,
  Color discFill,
  Color chrome,
) {
  final s = size.shortestSide;
  final cx = s / 2;
  final discC = Offset(cx, s * 0.64);
  final discR = s * 0.26;
  final peak = Offset(cx, s * 0.08);
  final baseY = discC.dy - discR * 0.22;
  final baseHalf = discR * 0.78;

  final cone = Path()
    ..moveTo(peak.dx, peak.dy)
    ..lineTo(cx + baseHalf, baseY)
    ..lineTo(cx - baseHalf, baseY)
    ..close();

  final strokeW = (s * 0.07).clamp(1.6, 9.0);
  _strokeThenFill(canvas, cone, coneFill, discFill, strokeW);

  canvas.drawCircle(
    discC,
    discR,
    Paint()
      ..color = discFill
      ..style = PaintingStyle.fill
      ..isAntiAlias = true,
  );
  canvas.drawCircle(
    discC,
    discR,
    Paint()
      ..color = chrome
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW * 0.85
      ..isAntiAlias = true,
  );
}

/// PNG für MapLibre `addImage` — Spitze zeigt nach oben.
Future<Uint8List> buildNavPuckPng({
  NavPuckStyle style = NavPuckStyle.rider,
  Color? fill,
  Color? stroke,
  Color? inner,
  int pixelSize = 128,
}) async {
  if (style == NavPuckStyle.rider) {
    try {
      return await buildRiderMapPng(live: true, pixelSize: pixelSize);
    } catch (_) {}
  }
  final size = pixelSize.toDouble();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  paintNavPuck(
    canvas,
    Size(size, size),
    style: style,
    fill: fill,
    stroke: stroke,
    inner: inner,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(pixelSize, pixelSize);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

/// HUD-/Chrome-Variante desselben Pucks (statt [Icons.navigation]).
class AetherNavMark extends StatelessWidget {
  const AetherNavMark({
    super.key,
    this.size = 24,
    this.color,
    this.stroke,
    this.inner,
    this.style = NavPuckStyle.rider,
    this.onLongPress,
  });

  final double size;
  final Color? color;
  final Color? stroke;
  final Color? inner;
  final NavPuckStyle style;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10nOrNull;
    final title = navPuckTitle(l10n, style);
    final child = style.usesRiderAsset
        ? Image.asset(
            kRiderLiveAsset,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stack) => CustomPaint(
              painter: _NavPuckPainter(
                style: style,
                fill: color,
                stroke: stroke,
                inner: inner,
              ),
            ),
          )
        : CustomPaint(
            painter: _NavPuckPainter(
              style: style,
              fill: color,
              stroke: stroke,
              inner: inner,
            ),
          );
    final mark = Semantics(
      label: l10n?.ridePuckSemantics(title) ?? 'Navigation, $title',
      child: SizedBox(width: size, height: size, child: child),
    );
    if (onLongPress == null) return mark;
    return GestureDetector(
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: mark,
    );
  }
}

class _NavPuckPainter extends CustomPainter {
  const _NavPuckPainter({
    required this.style,
    required this.fill,
    required this.stroke,
    required this.inner,
  });

  final NavPuckStyle style;
  final Color? fill;
  final Color? stroke;
  final Color? inner;

  @override
  void paint(Canvas canvas, Size size) {
    paintNavPuck(
      canvas,
      size,
      style: style,
      fill: fill,
      stroke: stroke,
      inner: inner,
    );
  }

  @override
  bool shouldRepaint(covariant _NavPuckPainter old) =>
      old.style != style ||
      old.fill != fill ||
      old.stroke != stroke ||
      old.inner != inner;
}
