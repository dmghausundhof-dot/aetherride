/**
 * Browse-Karte: welches Netz-Layer sitzt auf welchem Level.
 *
 * Unten → oben, alles unter Ortsnamen:
 *   Pfad / Bridleway
 *   Schotter / Track
 *   S-Skala
 *   Radweg / Asphalt
 *   City
 *   Labels
 *
 * Fußwege, Treppen und Gehbereiche gehören nicht auf die Pfad-Lage.
 */

export const BROWSE_LABEL_LAYER_CANDIDATES = [
  "pois",
  "places",
  "place",
  "place_label",
  "place-label",
  "poi",
  "poi_label",
  "poi-label",
  "transportation_name",
  "road_label",
  "water_name",
  "housenumber",
] as const;

export const BROWSE_OVERLAY_STACK_BOTTOM_TO_TOP = [
  "bike-overlay-mtb-unrated",
  "bike-overlay-gravel",
  "bike-overlay-mtb",
  "bike-overlay-road",
  "bike-overlay-urban",
] as const;

export const BROWSE_LIVE_STACK_BOTTOM_TO_TOP = [
  "osm-live-path",
  "osm-live-track",
  "osm-sgrade-mtb",
  "osm-live-cycleway",
] as const;

export function browseNetworkBeforeLayerId(
  layerIds: Iterable<string>
): string | undefined {
  const have = new Set(layerIds);
  for (const id of BROWSE_LABEL_LAYER_CANDIDATES) {
    if (have.has(id)) return id;
  }
  return undefined;
}

export function browseNetworkBeforeLayerIdFromGet(
  getLayer: (id: string) => unknown
): string | undefined {
  for (const id of BROWSE_LABEL_LAYER_CANDIDATES) {
    if (getLayer(id)) return id;
  }
  return undefined;
}

/** True when every network layer sits strictly under the first label layer. */
export function browseNetworkSitsBelowLabels(
  layerIds: readonly string[],
  networkIds: readonly string[] = [
    ...BROWSE_LIVE_STACK_BOTTOM_TO_TOP,
    ...BROWSE_OVERLAY_STACK_BOTTOM_TO_TOP,
  ]
): boolean {
  const labelId = browseNetworkBeforeLayerId(layerIds);
  if (!labelId) return false;
  const labelIdx = layerIds.indexOf(labelId);
  return networkIds.every((id) => {
    const i = layerIds.indexOf(id);
    return i >= 0 && i < labelIdx;
  });
}

export function browseStackOrderOk(
  presentBottomToTop: readonly string[],
  expectedBottomToTop: readonly string[]
): boolean {
  const ranks = new Map(expectedBottomToTop.map((id, i) => [id, i]));
  let last = -1;
  for (const id of presentBottomToTop) {
    const rank = ranks.get(id);
    if (rank == null) continue;
    if (rank < last) return false;
    last = rank;
  }
  return last >= 0;
}
