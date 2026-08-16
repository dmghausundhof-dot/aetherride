/** Merge coverage + approved map_places + Stimme-Pins. No invented POIs. */

export type PlaceSource = "coverage" | "map_places" | "stimme" | "meet";

export type CommunityPlace = {
  id: string;
  name: string;
  kind: string;
  lat: number;
  lng: number;
  source: PlaceSource;
  tourId?: string;
  tip?: string;
  mapsUrl?: string;
};

const KIND_WIRE: Record<string, string> = {
  cafe: "cafe",
  bakery: "cafe",
  restaurant: "cafe",
  water: "water",
  drinking_water: "water",
  fountain: "water",
  viewpoint: "viewpoint",
  peak: "viewpoint",
  scenic: "viewpoint",
  shop: "shop",
  bike_shop: "shop",
  bicycle_store: "shop",
  repair: "repair",
  trailhead: "trailhead",
  parking: "trailhead",
  tip: "tip",
  highlight: "tip",
  meet: "meet",
  meeting: "meet",
};

export function normalizePlaceKind(raw: unknown): string {
  const k = String(raw ?? "")
    .trim()
    .toLowerCase()
    .replace(/-/g, "_");
  return KIND_WIRE[k] ?? "other";
}

export function isMissingMapPlacesTable(
  err: { code?: string; message?: string } | null | undefined
): boolean {
  if (!err) return false;
  return err.code === "42P01" || /map_places/i.test(err.message ?? "");
}

function keyOf(p: CommunityPlace): string {
  return `${p.lat.toFixed(4)}:${p.lng.toFixed(4)}:${normalizePlaceKind(p.kind)}`;
}

/** Coverage first, then DB, then Stimme, meet last. Same cell keeps first. */
export function mergeCommunityPlaces(input: {
  coverage?: CommunityPlace[];
  mapPlaces?: CommunityPlace[];
  stimmePins?: CommunityPlace[];
  meet?: CommunityPlace | null;
}): { places: CommunityPlace[]; honesty: string } {
  const seen = new Set<string>();
  const places: CommunityPlace[] = [];
  const push = (p: CommunityPlace | null | undefined) => {
    if (!p) return;
    const name = p.name.trim();
    if (!name) return;
    if (!Number.isFinite(p.lat) || !Number.isFinite(p.lng)) return;
    if (Math.abs(p.lat) > 90 || Math.abs(p.lng) > 180) return;
    const next: CommunityPlace = {
      ...p,
      name,
      kind: normalizePlaceKind(p.kind),
    };
    const k = keyOf(next);
    if (seen.has(k)) return;
    seen.add(k);
    places.push(next);
  };
  for (const p of input.coverage ?? []) push(p);
  for (const p of input.mapPlaces ?? []) push(p);
  for (const p of input.stimmePins ?? []) push(p);
  push(input.meet ?? null);
  return {
    places,
    honesty:
      places.length === 0
        ? "Keine Orte in diesem Ausschnitt."
        : `${places.length} Orte — Coverage, Stimmen und Treffpunkt, kein Demo.`,
  };
}

const COORD_RE = /(-?\d{1,3}\.\d+)\s*,\s*(-?\d{1,3}\.\d+)/;

/** Freitext „Parkplatz 49.41, 8.67“ oder nacktes Paar. Sonst kein Pin. */
export function parseMeetingLatLng(
  raw: string | null | undefined
): { lat: number; lng: number; label: string } | null {
  const t = String(raw ?? "").trim();
  if (!t) return null;
  const m = t.match(COORD_RE);
  if (!m) return null;
  const lat = Number(m[1]);
  const lng = Number(m[2]);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  if (Math.abs(lat) > 90 || Math.abs(lng) > 180) return null;
  const label = t.replace(COORD_RE, "").replace(/[@,]/g, " ").trim();
  return { lat, lng, label: label || "Treffpunkt" };
}
