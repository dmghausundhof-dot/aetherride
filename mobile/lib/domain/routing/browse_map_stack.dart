/// Browse-Karte: welches Netz-Layer sitzt auf welchem Level.
///
/// Unten → oben, alles unter Ortsnamen:
///   Pfad / Bridleway
///   Schotter / Track
///   S-Skala
///   Radweg / Asphalt
///   City
///   Labels
///
/// Fußwege, Treppen und Gehbereiche gehören nicht auf die Pfad-Lage.
const kBrowseLabelLayerCandidates = <String>[
  'pois',
  'places',
  'place',
  'place_label',
  'place-label',
  'poi',
  'poi_label',
  'poi-label',
  'transportation_name',
  'road_label',
  'water_name',
  'housenumber',
];

const kBrowseOverlayStackBottomToTop = <String>[
  'bike-overlay-mtb-unrated',
  'bike-overlay-gravel',
  'bike-overlay-mtb',
  'bike-overlay-road',
  'bike-overlay-urban',
];

const kBrowseLiveStackBottomToTop = <String>[
  'osm-live-path',
  'osm-live-track',
  'osm-sgrade-mtb',
  'osm-sgrade-mtb-rooty',
  'osm-live-cycleway',
];


const kOsmLivePathSubclasses = <String>['path', 'bridleway'];

const kOsmLivePathExcludeSubclasses = <String>[
  'footway',
  'pedestrian',
  'steps',
  'sidewalk',
  'platform',
  'corridor',
];

String? browseNetworkBeforeLayerId(Iterable<String> layerIds) {
  final have = layerIds.toSet();
  for (final id in kBrowseLabelLayerCandidates) {
    if (have.contains(id)) return id;
  }
  return null;
}

bool browseNetworkSitsBelowLabels(
  Iterable<String> layerIds, {
  Iterable<String> networkIds = const [
    ...kBrowseLiveStackBottomToTop,
    ...kBrowseOverlayStackBottomToTop,
  ],
}) {
  final ids = layerIds.toList();
  final labelId = browseNetworkBeforeLayerId(ids);
  if (labelId == null) return false;
  final labelIdx = ids.indexOf(labelId);
  return networkIds.every((id) {
    final i = ids.indexOf(id);
    return i >= 0 && i < labelIdx;
  });
}

bool browseStackOrderOk(
  Iterable<String> presentBottomToTop,
  Iterable<String> expectedBottomToTop,
) {
  final ranks = <String, int>{
    for (var i = 0; i < expectedBottomToTop.length; i++)
      expectedBottomToTop.elementAt(i): i,
  };
  var last = -1;
  for (final id in presentBottomToTop) {
    final rank = ranks[id];
    if (rank == null) continue;
    if (rank < last) return false;
    last = rank;
  }
  return last >= 0;
}
