/// Browse-Karte: Radnetz zuerst, Relief nur als leise Tiefe.
/// Layer-Level (Pfad unter Schotter unter Radweg, unter Labels):
/// siehe `browse_map_stack.dart`.
///
/// Drei ehrliche Farben — unbewertete Pfade sind grün, nicht grau.
/// Gravel/City liegen leise über dem Basemap, nicht als zweite Straße.
///
/// Höhe ist standardmäßig an, aber flach, damit die Wege lesbar bleiben.
abstract final class BrowseMapPaint {
  static const wayHex = '#3E78B0';
  static const gravelHex = '#B8974A';
  static const trailHex = '#3B7A45';

  static const wayWidth = 2.15;
  static const gravelWidth = 1.85;
  static const trailWidth = 2.05;
  static const liveCyclewayWidth = 2.45;
  static const liveTrackWidth = 1.15;
  static const livePathWidth = 1.85;
  static const mtbWidth = 2.35;
  static const urbanWidth = 1.65;
  static const liveStreetWidth = 1.15;

  static const packMinZoom = 10.0;
  static const liveCyclewayMinZoom = 10.0;
  static const livePathMinZoom = 11.0;
  static const liveTrackMinZoom = 13.0;
  static const mtbMinZoom = 10.0;
  static const unratedMinZoom = 11.0;
  static const gravelMinZoom = 11.0;
  static const roadMinZoom = 10.0;
  static const urbanMinZoom = 11.0;

  /// Trails / S-Skala — dürfen stehen.
  static const lineOpacity = 0.70;
  /// City / Gravel / Asphalt-Overlay auf vorhandenen Straßen.
  static const quietOpacity = 0.34;
  /// Untagged farm/field tracks — must not read as the planned route.
  static const farmTrackOpacity = 0.16;
  static const List<double> farmTrackDash = [1.4, 2.2];
  static const streetHintOpacity = 0.18;
  static const visibilityOpacity = 0.70;

  static double opacityForClass(String classId) {
    return switch (classId) {
      'road' || 'urban' || 'gravel' => quietOpacity,
      _ => lineOpacity,
    };
  }

  static const hillshadeOnByDefault = true;
  static const hillshadeExaggeration = 0.18;
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
