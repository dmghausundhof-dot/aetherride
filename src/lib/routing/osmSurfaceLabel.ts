/** Honest OSM surface → asphalt / gravel / trail. Unknown keys stay raw. */
export type OsmSurfaceGroup = "asphalt" | "gravel" | "trail";

const ASPHALT = new Set([
  "asphalt",
  "paved",
  "concrete",
  "paving_stones",
  "sett",
  "chipseal",
  "concrete:plates",
  "concrete:lanes",
]);

const GRAVEL = new Set([
  "gravel",
  "compacted",
  "fine_gravel",
  "pebblestone",
  "unpaved",
  "ground",
]);

const TRAIL = new Set([
  "dirt",
  "earth",
  "grass",
  "path",
  "trail",
  "root",
  "mud",
  "sand",
  "wood",
  "winter_road",
]);

export function osmSurfaceGroup(raw: string | null | undefined): OsmSurfaceGroup | null {
  const key = (raw ?? "").trim().toLowerCase();
  if (!key) return null;
  if (ASPHALT.has(key)) return "asphalt";
  if (GRAVEL.has(key)) return "gravel";
  if (TRAIL.has(key)) return "trail";
  return null;
}

export function osmSurfaceLabel(
  raw: string | null | undefined,
  labels: { asphalt: string; gravel: string; trail: string }
): string {
  const key = (raw ?? "").trim();
  if (!key) return "";
  const group = osmSurfaceGroup(key);
  if (group === "asphalt") return labels.asphalt;
  if (group === "gravel") return labels.gravel;
  if (group === "trail") return labels.trail;
  return key.replaceAll("_", " ");
}
