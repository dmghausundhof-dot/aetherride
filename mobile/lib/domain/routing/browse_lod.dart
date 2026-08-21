/// Progressive Disclosure für die Discover-Karte (Komoot / AllTrails).
///
/// Vier Aufgaben-Bänder, nicht fünf Label-Stufen:
///   Überblick  z < 10     Korridore, Heat, beliebte Loops
///   Netz       10–12.5    Trailnetz und Einstiege
///   Charakter  12.5–15.5  Surface, S-Skala, Fotos
///   Detail     ≥ 15.5     Linien, Gates, Feininformation
///
/// Pin-Beschriftung bleibt [TourFilters.browsePinZoomBand] (10/11/12/13).
library;

enum BrowseLodId { overview, network, character, detail }

class BrowseLod {
  const BrowseLod({
    required this.id,
    required this.label,
    required this.task,
    required this.minZoom,
    required this.maxZoom,
  });

  final BrowseLodId id;
  final String label;
  final String task;
  final double minZoom;
  final double maxZoom;
}

/// Kanonische Zoom-Schwellen — eine Quelle für Paint, Overlay und Pins.
abstract final class BrowseLodBands {
  static const overview = BrowseLod(
    id: BrowseLodId.overview,
    label: 'Überblick',
    task: 'Regionen und beliebte Korridore',
    minZoom: 0,
    maxZoom: 10,
  );
  static const network = BrowseLod(
    id: BrowseLodId.network,
    label: 'Netz',
    task: 'Trailnetz und Einstiege',
    minZoom: 10,
    maxZoom: 12.5,
  );
  static const character = BrowseLod(
    id: BrowseLodId.character,
    label: 'Charakter',
    task: 'Surface, Schwierigkeit, Fotos',
    minZoom: 12.5,
    maxZoom: 15.5,
  );
  static const detail = BrowseLod(
    id: BrowseLodId.detail,
    label: 'Detail',
    task: 'Linien, Gates, Feininformation',
    minZoom: 15.5,
    maxZoom: 22,
  );

  static const all = [overview, network, character, detail];

  /// ICN / Radfernwege dürfen auf dem Blatt stehen — nicht jedes MTB-Pfad.
  static const corridorMinZoom = 7.0;

  /// Beliebte Loops auf Überblick.
  static const overviewPinPopularity = 72;

  /// Einstiege ab Netz.
  static const networkPinPopularity = 48;
}

BrowseLod browseLodFromZoom(double zoom) {
  if (zoom < BrowseLodBands.network.minZoom) return BrowseLodBands.overview;
  if (zoom < BrowseLodBands.character.minZoom) return BrowseLodBands.network;
  if (zoom < BrowseLodBands.detail.minZoom) return BrowseLodBands.character;
  return BrowseLodBands.detail;
}

bool browseLodNeedsFullResync(BrowseLodId from, BrowseLodId to) => from != to;

/// Heat bleibt die Überblick-Sprache. Ab Detail stört sie die Linie.
bool browseLodShowsHeatmap(BrowseLodId lod) => lod != BrowseLodId.detail;

double browseLodHeatOpacity(BrowseLodId lod, double intensity) {
  final base = 0.18 + intensity * 0.25;
  return switch (lod) {
    BrowseLodId.overview => (base * 1.35).clamp(0.22, 0.62),
    BrowseLodId.network => base.clamp(0.12, 0.48),
    BrowseLodId.character => (base * 0.42).clamp(0.06, 0.22),
    BrowseLodId.detail => 0,
  };
}

double browseLodHeatWidth(BrowseLodId lod, double intensity) {
  final base = 6 + intensity * 8;
  return switch (lod) {
    BrowseLodId.overview => base * 1.25,
    BrowseLodId.network => base,
    BrowseLodId.character => base * 0.65,
    BrowseLodId.detail => 0,
  };
}

/// OSM-Wege / Pack-Overlay — nicht auf Länder-Zoom.
bool browseLodShowsTrailNetwork(BrowseLodId lod) =>
    lod != BrowseLodId.overview;

/// S-Skala, Surface-Dash, Photo-Dots.
bool browseLodShowsSurfaceStyle(BrowseLodId lod) =>
    lod == BrowseLodId.character || lod == BrowseLodId.detail;

bool browseLodShowsPhotos(BrowseLodId lod) => browseLodShowsSurfaceStyle(lod);

/// Flow-Beads, POI-Namen, Gates.
bool browseLodShowsFineDetail(BrowseLodId lod) => lod == BrowseLodId.detail;

/// Coverage-POIs / Foto-Orte. Treffen bleiben immer.
bool browseLodShowsCoveragePlaces(BrowseLodId lod) =>
    lod == BrowseLodId.character || lod == BrowseLodId.detail;

bool browseLodShowsStimmePlaces(BrowseLodId lod) =>
    lod != BrowseLodId.overview;

/// Tour-Pin / Ribbon: ausgewählt immer, sonst nach Beliebtheit.
bool browseLodPinVisible({
  required BrowseLodId lod,
  required int popularity,
  required bool selected,
}) {
  if (selected) return true;
  if (lod == BrowseLodId.overview) {
    return popularity >= BrowseLodBands.overviewPinPopularity;
  }
  if (lod == BrowseLodId.network) {
    return popularity >= BrowseLodBands.networkPinPopularity;
  }
  return true;
}

bool browseLodRibbonVisible({
  required BrowseLodId lod,
  required int popularity,
  required bool selected,
}) =>
    browseLodPinVisible(
      lod: lod,
      popularity: popularity,
      selected: selected,
    );

/// Coaching, wenn die Karte absichtlich wenig zeigt.
String browseLodZoomHint(BrowseLodId lod) => switch (lod) {
      BrowseLodId.overview => 'Reinzoomen für Trails und Fotos',
      BrowseLodId.network => 'Näher: Surface und S-Skala',
      BrowseLodId.character => '',
      BrowseLodId.detail => '',
    };

/// Zielzoom für den Hinweis-Tap.
double browseLodZoomHintTarget(BrowseLodId lod) => switch (lod) {
      BrowseLodId.overview => 11.2,
      BrowseLodId.network => 13.0,
      BrowseLodId.character => 16.0,
      BrowseLodId.detail => 16.0,
    };

/// Community-Heat ist öffentlich (k≥5). Eigene Spuren bleiben Consent.
bool browseLodPublicHeatAllowed(BrowseLodId lod) => browseLodShowsHeatmap(lod);

