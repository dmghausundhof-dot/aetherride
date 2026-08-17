/// Browse-Karte: Radnetz zuerst, Relief nur als leise Tiefe.
///
/// Drei ehrliche Farben — unbewertete Pfade sind grün, nicht grau:
///   Asphalt / Radweg  `#1565C0`  (dedizierter Radweg dicker)
///   Schotter / Track  `#C49A3C`
///   Pfad / Trail      `#2E7D32`
///
/// Höhe ist standardmäßig an, aber flach, damit die Wege lesbar bleiben.
abstract final class BrowseMapPaint {
  static const wayHex = '#1565C0';
  static const gravelHex = '#C49A3C';
  static const trailHex = '#2E7D32';

  static const wayWidth = 3.4;
  static const gravelWidth = 3.0;
  static const trailWidth = 2.4;
  static const liveCyclewayWidth = 3.9;
  static const liveTrackWidth = 3.0;
  static const livePathWidth = 2.15;
  static const mtbWidth = 3.0;
  static const urbanWidth = 2.8;

  static const packMinZoom = 10.0;
  static const liveCyclewayMinZoom = 10.0;
  static const livePathMinZoom = 11.0;
  static const liveTrackMinZoom = 11.0;
  static const mtbMinZoom = 10.0;
  static const unratedMinZoom = 11.0;
  static const gravelMinZoom = 11.0;
  static const roadMinZoom = 10.0;
  static const urbanMinZoom = 11.0;

  static const lineOpacity = 0.94;
  static const visibilityOpacity = 0.90;

  static const hillshadeOnByDefault = true;
  static const hillshadeExaggeration = 0.14;
  static const hillshadeShadowHex = '#6a7a72';
  static const hillshadeHighlightHex = '#f6f8f6';
  static const hillshadeAccentHex = '#9aa8a0';

  static const legendHeight = 20.0;

  static List<dynamic> zoomWidth(double width) => [
        'interpolate',
        ['linear'],
        ['zoom'],
        10,
        width * 0.75,
        12,
        width,
        14,
        width * 1.45,
      ];

  static List<dynamic> liveZoomWidth(double width) => [
        'interpolate',
        ['linear'],
        ['zoom'],
        10,
        width * 0.8,
        12,
        width,
        15,
        width * 1.4,
      ];
}
