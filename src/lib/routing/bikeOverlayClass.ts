/**
 * OSM-Way → Bike-Overlay-Klasse.
 *
 * Honesty:
 * - S0–S3+ nur aus `mtb:scale` / `mtb:scale:imba` (nie aus `sac_scale`).
 * - Ungenannte path/track ohne Scale → `mtb_unrated` („offen / unbewertet“).
 * - `bicycle=no` / `mtb=no` → hidden.
 */

export type BikeOverlayClass =
  | "mtb"
  | "mtb_unrated"
  | "gravel"
  | "road"
  | "urban"
  | "hidden";

export type MtbScaleLabel = "S0" | "S1" | "S2" | "S3+";

export type OsmWayTags = Record<string, string | undefined | null>;

export type BikeOverlayClassification = {
  bikeClass: BikeOverlayClass;
  /** Nur gesetzt, wenn OSM wirklich `mtb:scale` / `mtb:scale:imba` hat. */
  mtbScale: MtbScaleLabel | null;
};

const PATH_TRACK = new Set(["path", "track", "bridleway"]);
const ROAD_LIKE = new Set([
  "primary",
  "secondary",
  "tertiary",
  "unclassified",
  "residential",
  "service",
]);
const PAVED = new Set([
  "asphalt",
  "paved",
  "concrete",
  "concrete:plates",
  "concrete:lanes",
  "chipseal",
]);
const GRAVEL_SURFACE = new Set([
  "unpaved",
  "compacted",
  "fine_gravel",
  "gravel",
  "pebblestone",
]);
const GRAVEL_TRACKTYPE = new Set(["grade2", "grade3", "grade4"]);
const CYCLEWAY_INFRA = new Set([
  "lane",
  "track",
  "share_busway",
  "opposite_lane",
  "opposite_track",
  "shared_lane",
]);

function tag(tags: OsmWayTags, key: string): string {
  const v = tags[key];
  return typeof v === "string" ? v.trim().toLowerCase() : "";
}

function isNo(v: string): boolean {
  return v === "no";
}

/**
 * Parse OSM MTB scale. Does **not** read `sac_scale`.
 * 3 and above collapse to S3+ (same as live `/api/osm-trails`, not silent "S3").
 */
export function parseOsmMtbScale(
  mtbScale?: string | null,
  mtbScaleImba?: string | null
): MtbScaleLabel | null {
  const raw = (mtbScale ?? "").trim() || (mtbScaleImba ?? "").trim();
  if (!raw) return null;
  const t = raw.toLowerCase();
  const head = t.replace(/^s/, "").replace(/[^0-9].*$/, "");
  if (t === "0" || t.startsWith("0") || t.startsWith("s0") || head === "0") {
    return "S0";
  }
  if (t === "1" || t.startsWith("1") || t.startsWith("s1") || head === "1") {
    return "S1";
  }
  if (t === "2" || t.startsWith("2") || t.startsWith("s2") || head === "2") {
    return "S2";
  }
  if (
    t === "3" ||
    t === "4" ||
    t === "5" ||
    t === "6" ||
    t.startsWith("s3") ||
    t.startsWith("s4") ||
    t.startsWith("s5") ||
    head === "3" ||
    head === "4" ||
    head === "5" ||
    head === "6"
  ) {
    return "S3+";
  }
  return null;
}

function isPaved(surface: string): boolean {
  return PAVED.has(surface);
}

function isGravelish(surface: string, tracktype: string): boolean {
  return GRAVEL_SURFACE.has(surface) || GRAVEL_TRACKTYPE.has(tracktype);
}

function cyclewayInfra(tags: OsmWayTags): boolean {
  for (const key of [
    "cycleway",
    "cycleway:left",
    "cycleway:right",
    "cycleway:both",
  ]) {
    const v = tag(tags, key);
    if (CYCLEWAY_INFRA.has(v)) return true;
  }
  return false;
}

export function classifyBikeWay(tags: OsmWayTags): BikeOverlayClassification {
  const bicycle = tag(tags, "bicycle");
  const mtb = tag(tags, "mtb");
  if (isNo(bicycle) || isNo(mtb)) {
    return { bikeClass: "hidden", mtbScale: null };
  }

  const highway = tag(tags, "highway");
  const surface = tag(tags, "surface");
  const tracktype = tag(tags, "tracktype");
  const mtbScale = parseOsmMtbScale(
    tags["mtb:scale"],
    tags["mtb:scale:imba"]
  );

  if (PATH_TRACK.has(highway) && mtbScale) {
    return { bikeClass: "mtb", mtbScale };
  }

  if (highway === "living_street") {
    return { bikeClass: "urban", mtbScale: null };
  }

  if (cyclewayInfra(tags) && ROAD_LIKE.has(highway)) {
    return { bikeClass: "urban", mtbScale: null };
  }

  if (highway === "cycleway") {
    if (isGravelish(surface, tracktype) && !isPaved(surface)) {
      return { bikeClass: "gravel", mtbScale: null };
    }
    return { bikeClass: "road", mtbScale: null };
  }

  if (
    (bicycle === "designated" || bicycle === "yes") &&
    isPaved(surface) &&
    ROAD_LIKE.has(highway)
  ) {
    return { bikeClass: "road", mtbScale: null };
  }

  if (isGravelish(surface, tracktype) && (PATH_TRACK.has(highway) || highway === "unclassified")) {
    return { bikeClass: "gravel", mtbScale: null };
  }

  if (PATH_TRACK.has(highway)) {
    return { bikeClass: "mtb_unrated", mtbScale: null };
  }

  if (
    highway === "footway" &&
    (bicycle === "yes" || bicycle === "designated")
  ) {
    return { bikeClass: "urban", mtbScale: null };
  }

  return { bikeClass: "hidden", mtbScale: null };
}

/** OSM cycle-network rank for route relations (icn > ncn > rcn > lcn). */
export type BikeRouteNetwork = "icn" | "ncn" | "rcn" | "lcn" | "mtb" | "";

export type BikeRouteClassification = BikeOverlayClassification & {
  network: BikeRouteNetwork;
};

function parseBikeRouteNetwork(
  networkRaw: string,
  refRaw: string,
  routeRaw: string
): BikeRouteNetwork {
  const n = networkRaw.toLowerCase();
  if (n.includes("icn")) return "icn";
  if (n.includes("ncn")) return "ncn";
  if (n.includes("rcn")) return "rcn";
  if (n.includes("lcn")) return "lcn";
  const ref = refRaw.toUpperCase().replace(/\s+/g, "");
  if (/^EV\d/.test(ref) || /^CDP/.test(ref) || /^D-?ROUTE/.test(ref)) {
    return "icn";
  }
  if (routeRaw === "mtb") return "mtb";
  return "";
}

/**
 * OSM route relation → overlay class.
 * Signed long-distance mesh: icn/ncn/rcn (+ EuroVelo ref). LCN is local clutter.
 */
export function classifyBikeRoute(tags: OsmWayTags): BikeRouteClassification {
  const route = tag(tags, "route");
  const network = parseBikeRouteNetwork(
    tag(tags, "network"),
    tag(tags, "ref"),
    route
  );
  if (route === "mtb" || network === "mtb") {
    return {
      bikeClass: "mtb",
      mtbScale: parseOsmMtbScale(tags["mtb:scale"], tags["mtb:scale:imba"]),
      network: "mtb",
    };
  }
  if (route !== "bicycle" && route !== "cycling") {
    return { bikeClass: "hidden", mtbScale: null, network: "" };
  }
  if (network === "lcn") {
    return { bikeClass: "urban", mtbScale: null, network: "lcn" };
  }
  if (network === "icn" || network === "ncn" || network === "rcn") {
    return { bikeClass: "road", mtbScale: null, network };
  }
  return { bikeClass: "hidden", mtbScale: null, network: "" };
}

/** Keep icn/ncn/rcn. LCN is local clutter; untagged MTB loops stay out. */
export function keepSignedCycleMesh(tags: OsmWayTags): boolean {
  const { bikeClass, network } = classifyBikeRoute(tags);
  if (bikeClass === "hidden") return false;
  return network === "icn" || network === "ncn" || network === "rcn";
}

/** Garage / routing profile → which overlay classes are “on” (others dim). */
export type BikeOverlayFamily = "mtb" | "gravel" | "road" | "urban";

export function overlayFamilyForBike(
  categoryOrProfile: string | null | undefined
): BikeOverlayFamily {
  const c = (categoryOrProfile ?? "").toLowerCase();
  if (
    c.includes("mtb") ||
    c === "dh" ||
    c === "downhill" ||
    c === "emtb" ||
    c === "mtb_trail" ||
    c === "mtb_am" ||
    c === "mtb_enduro" ||
    c === "mtb_allmountain"
  ) {
    return "mtb";
  }
  if (c.includes("gravel")) return "gravel";
  if (c === "urban" || c === "city" || c === "cargo" || c === "folding" || c === "kids") return "urban";
  if (c === "etrekking" || c === "ebike" || c === "ebike_tour") return "gravel";
  if (c === "hiking") return "mtb";
  return "road";
}

export function overlayClassesForFamily(
  family: BikeOverlayFamily
): BikeOverlayClass[] {
  switch (family) {
    case "mtb":
      return ["mtb", "mtb_unrated"];
    case "gravel":
      return ["gravel", "road"];
    case "road":
      return ["road", "urban"];
    case "urban":
      return ["urban", "road"];
  }
}

export const BIKE_OVERLAY_COLORS = {
  S0: "#4CAF50",
  S1: "#8BC34A",
  S2: "#FFC107",
  S3: "#E53935",
  unrated: "#90A4AE",
  gravel: "#C49A3C",
  road: "#1E88E5",
  urban: "#00897B",
} as const;

export const BIKE_OVERLAY_LEGEND_DE: {
  key: string;
  label: string;
  color: string;
  bikeClass: BikeOverlayClass;
}[] = [
  { key: "S0", label: "S0", color: BIKE_OVERLAY_COLORS.S0, bikeClass: "mtb" },
  { key: "S1", label: "S1", color: BIKE_OVERLAY_COLORS.S1, bikeClass: "mtb" },
  { key: "S2", label: "S2", color: BIKE_OVERLAY_COLORS.S2, bikeClass: "mtb" },
  { key: "S3+", label: "S3+", color: BIKE_OVERLAY_COLORS.S3, bikeClass: "mtb" },
  {
    key: "unrated",
    label: "unbewertet",
    color: BIKE_OVERLAY_COLORS.unrated,
    bikeClass: "mtb_unrated",
  },
  {
    key: "gravel",
    label: "Gravel",
    color: BIKE_OVERLAY_COLORS.gravel,
    bikeClass: "gravel",
  },
  {
    key: "road",
    label: "Radweg / Asphalt",
    color: BIKE_OVERLAY_COLORS.road,
    bikeClass: "road",
  },
  {
    key: "urban",
    label: "City",
    color: BIKE_OVERLAY_COLORS.urban,
    bikeClass: "urban",
  },
];

/** S0–S3+ nur bei MTB/Trail — nicht als permanente City-Legende. */
export function overlayLegendShowsSScale(family: BikeOverlayFamily): boolean {
  return family === "mtb";
}

export type OverlayLegendRow = {
  key: string;
  bikeClass: BikeOverlayClass;
};

/** Ausgeklappt: S-Skala nur bei MTB; City/Rennrad/Gravel ohne S0–S3+. */
export function overlayLegendRows(opts: {
  family: BikeOverlayFamily;
  expanded: boolean;
}): OverlayLegendRow[] {
  if (!opts.expanded) return [];
  if (overlayLegendShowsSScale(opts.family)) {
    return [
      { bikeClass: "mtb", key: "S0" },
      { bikeClass: "mtb", key: "S1" },
      { bikeClass: "mtb", key: "S2" },
      { bikeClass: "mtb", key: "S3+" },
      { bikeClass: "mtb_unrated", key: "unrated" },
    ];
  }
  switch (opts.family) {
    case "urban":
      return [
        { bikeClass: "urban", key: "urban" },
        { bikeClass: "road", key: "road" },
      ];
    case "road":
      return [
        { bikeClass: "road", key: "road" },
        { bikeClass: "urban", key: "urban" },
      ];
    case "gravel":
      return [
        { bikeClass: "gravel", key: "gravel" },
        { bikeClass: "road", key: "road" },
      ];
    default:
      return [];
  }
}

export function overlayLegendColor(key: string): string {
  switch (key) {
    case "S0":
      return BIKE_OVERLAY_COLORS.S0;
    case "S1":
      return BIKE_OVERLAY_COLORS.S1;
    case "S2":
      return BIKE_OVERLAY_COLORS.S2;
    case "S3+":
      return BIKE_OVERLAY_COLORS.S3;
    case "unrated":
      return BIKE_OVERLAY_COLORS.unrated;
    case "gravel":
      return BIKE_OVERLAY_COLORS.gravel;
    case "road":
      return BIKE_OVERLAY_COLORS.road;
    default:
      return BIKE_OVERLAY_COLORS.urban;
  }
}
