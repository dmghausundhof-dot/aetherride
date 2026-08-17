/**
 * Map a point to the Valhalla tile region (offline pack id) that should serve it.
 * Tiles live under data/routing/dist/<id>/custom_files — one Geofabrik region each,
 * never planet / france-latest / germany-latest.
 */

export type ValhallaRegion = {
  id: string;
  name: string;
  /** west, south, east, north */
  bbox: [number, number, number, number];
  /** Relative Geofabrik path under europe/ — empty = Overpass clip only */
  geofabrik?: string;
};

/**
 * Priority: city packs first (dense), then country / Land envelopes.
 * Selection uses smallest covering bbox (area sort).
 * Keep in sync with data/routing/regions and docker-compose.valhalla.yml.
 */
export const VALHALLA_REGIONS: readonly ValhallaRegion[] = [
  // —— City / trail packs (dense, Overpass) ——
  {
    id: "schwarzwald-nord",
    name: "Schwarzwald Nord",
    bbox: [7.7, 47.8, 8.2, 48.15],
  },
  {
    id: "amsterdam",
    name: "Amsterdam",
    bbox: [4.75, 52.3, 5.02, 52.43],
  },
  {
    id: "utrecht",
    name: "Utrecht",
    bbox: [5.0, 52.0, 5.2, 52.15],
  },
  {
    id: "rotterdam",
    name: "Rotterdam",
    bbox: [4.35, 51.85, 4.6, 52.0],
  },
  {
    id: "den-haag",
    name: "Den Haag",
    bbox: [4.15, 52.0, 4.4, 52.15],
  },
  {
    id: "eindhoven",
    name: "Eindhoven",
    bbox: [5.35, 51.4, 5.55, 51.5],
  },
  {
    id: "groningen",
    name: "Groningen",
    bbox: [6.45, 53.15, 6.65, 53.3],
  },

  // —— Benelux ——
  {
    id: "nl-netherlands",
    name: "Niederlande",
    bbox: [3.2, 50.75, 7.25, 53.7],
    geofabrik: "netherlands-latest.osm.pbf",
  },
  {
    id: "be-belgium",
    name: "Belgien",
    bbox: [2.4, 49.45, 6.45, 51.55],
    geofabrik: "belgium-latest.osm.pbf",
  },

  // —— DE Länder (bboxes from data/routing/regions) ——
  {
    id: "de-saarland",
    name: "Saarland",
    bbox: [6.3, 49.1, 7.4, 49.65],
    geofabrik: "germany/saarland-latest.osm.pbf",
  },
  {
    id: "de-rlp",
    name: "Rheinland-Pfalz",
    bbox: [6.1, 48.95, 8.55, 50.95],
    geofabrik: "germany/rheinland-pfalz-latest.osm.pbf",
  },
  {
    id: "de-hessen",
    name: "Hessen",
    bbox: [7.75, 49.35, 10.3, 51.7],
    geofabrik: "germany/hessen-latest.osm.pbf",
  },
  {
    id: "de-thueringen",
    name: "Thüringen",
    bbox: [9.85, 50.2, 12.65, 51.65],
    geofabrik: "germany/thueringen-latest.osm.pbf",
  },
  {
    id: "de-sachsen",
    name: "Sachsen",
    bbox: [11.85, 50.17, 15.05, 51.7],
    geofabrik: "germany/sachsen-latest.osm.pbf",
  },
  {
    id: "de-baden-wuerttemberg",
    name: "Baden-Württemberg",
    bbox: [7.5, 47.53, 10.5, 49.8],
    geofabrik: "germany/baden-wuerttemberg-latest.osm.pbf",
  },
  {
    id: "de-nrw",
    name: "Nordrhein-Westfalen",
    bbox: [5.86, 50.3, 9.5, 52.55],
    geofabrik: "germany/nordrhein-westfalen-latest.osm.pbf",
  },
  {
    id: "de-sachsen-anhalt",
    name: "Sachsen-Anhalt",
    bbox: [10.5, 50.9, 13.25, 53.05],
    geofabrik: "germany/sachsen-anhalt-latest.osm.pbf",
  },
  {
    id: "de-schleswig-holstein",
    name: "Schleswig-Holstein",
    bbox: [8.3, 53.3, 11.4, 55.1],
    geofabrik: "germany/schleswig-holstein-latest.osm.pbf",
  },
  {
    id: "de-mecklenburg-vorpommern",
    name: "Mecklenburg-Vorpommern",
    bbox: [10.5, 53.05, 14.5, 54.7],
    geofabrik: "germany/mecklenburg-vorpommern-latest.osm.pbf",
  },
  {
    id: "de-brandenburg",
    name: "Brandenburg",
    bbox: [11.2, 51.3, 15.05, 53.6],
    geofabrik: "germany/brandenburg-latest.osm.pbf",
  },
  {
    id: "de-niedersachsen",
    name: "Niedersachsen",
    bbox: [6.6, 51.3, 11.65, 53.9],
    geofabrik: "germany/niedersachsen-latest.osm.pbf",
  },
  {
    id: "de-bayern",
    name: "Bayern",
    bbox: [8.97, 47.27, 13.84, 50.57],
    geofabrik: "germany/bayern-latest.osm.pbf",
  },

  // —— AT / CH key envelopes (geofabrik from region JSON) ——
  {
    id: "ch-zuerichsee",
    name: "Zürichsee / Zürcher Oberland",
    bbox: [8.25, 47.18, 9.05, 47.65],
    geofabrik: "switzerland-latest.osm.pbf",
  },
  {
    id: "ch-mittelland",
    name: "Schweizer Mittelland",
    bbox: [6.85, 46.72, 8.05, 47.35],
    geofabrik: "switzerland-latest.osm.pbf",
  },
  {
    id: "ch-genfersee",
    name: "Genfersee / Romandie",
    bbox: [5.96, 46.08, 7.25, 46.62],
    geofabrik: "switzerland-latest.osm.pbf",
  },
  {
    id: "at-tirol",
    name: "Tirol",
    bbox: [10.1, 46.62, 12.95, 47.78],
    geofabrik: "austria-latest.osm.pbf",
  },
  {
    id: "at-salzburg",
    name: "Land Salzburg",
    bbox: [12.05, 46.9, 13.85, 48.05],
    geofabrik: "austria-latest.osm.pbf",
  },
  {
    id: "at-niederoesterreich",
    name: "Niederösterreich",
    bbox: [14.4, 47.4, 17.17, 49.02],
    geofabrik: "austria-latest.osm.pbf",
  },

  // —— FR regional (Geofabrik france/*) ——
  {
    id: "fr-ile-de-france",
    name: "Île-de-France",
    bbox: [1.45, 48.12, 3.55, 49.25],
    geofabrik: "france/ile-de-france-latest.osm.pbf",
  },
  {
    id: "fr-nord-pas-de-calais",
    name: "Nord-Pas-de-Calais",
    bbox: [1.55, 50.0, 4.25, 51.1],
    geofabrik: "france/nord-pas-de-calais-latest.osm.pbf",
  },
  {
    id: "fr-bretagne",
    name: "Bretagne",
    bbox: [-5.15, 47.25, -1.0, 48.9],
    geofabrik: "france/bretagne-latest.osm.pbf",
  },
  {
    id: "fr-rhone-alpes",
    name: "Rhône-Alpes",
    bbox: [3.85, 44.1, 7.25, 46.4],
    geofabrik: "france/rhone-alpes-latest.osm.pbf",
  },
  {
    id: "fr-provence-alpes-cote-d-azur",
    name: "Provence-Alpes-Côte d'Azur",
    bbox: [4.2, 42.95, 7.75, 45.15],
    geofabrik: "france/provence-alpes-cote-d-azur-latest.osm.pbf",
  },

  // —— IT macro-regions (Geofabrik italy/*) ——
  {
    id: "it-nord-ovest",
    name: "Nord-Ovest",
    bbox: [6.6, 43.75, 10.6, 46.55],
    geofabrik: "italy/nord-ovest-latest.osm.pbf",
  },
  {
    id: "it-nord-est",
    name: "Nord-Est",
    bbox: [10.35, 43.7, 13.95, 47.1],
    geofabrik: "italy/nord-est-latest.osm.pbf",
  },
  {
    id: "it-centro",
    name: "Centro",
    bbox: [9.7, 41.2, 14.05, 44.5],
    geofabrik: "italy/centro-latest.osm.pbf",
  },
  {
    id: "it-sud",
    name: "Sud",
    bbox: [12.9, 37.9, 18.55, 42.15],
    geofabrik: "italy/sud-latest.osm.pbf",
  },
];

function pointIn(
  lng: number,
  lat: number,
  bbox: [number, number, number, number]
): boolean {
  return (
    lng >= bbox[0] && lat >= bbox[1] && lng <= bbox[2] && lat <= bbox[3]
  );
}

function area(bbox: [number, number, number, number]): number {
  return (bbox[2] - bbox[0]) * (bbox[3] - bbox[1]);
}

/** Smallest registered Valhalla region covering the point, or null. */
export function valhallaRegionForPoint(
  lng: number,
  lat: number
): ValhallaRegion | null {
  const hits = VALHALLA_REGIONS.filter((r) => pointIn(lng, lat, r.bbox));
  if (!hits.length) return null;
  hits.sort((a, b) => area(a.bbox) - area(b.bbox));
  return hits[0];
}

export function valhallaTilesCdnPath(regionId: string): string {
  return `${regionId}/valhalla_tiles.tar`;
}
