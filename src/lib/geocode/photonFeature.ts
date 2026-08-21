export type PhotonHit = {
  label: string;
  lat: number;
  lng: number;
  kind?: string;
  name?: string;
};

type PhotonFeature = {
  geometry?: { coordinates?: number[] };
  properties?: Record<string, unknown>;
};

function str(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

/** Photon search + reverse share the same Feature shape. */
export function photonHitFromFeature(
  feature: PhotonFeature | null | undefined
): PhotonHit | null {
  const coords = feature?.geometry?.coordinates;
  if (!coords || coords.length < 2) return null;
  const lng = coords[0];
  const lat = coords[1];
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  const p = feature?.properties ?? {};
  const name = str(p.name);
  const locality = str(p.city) || str(p.town) || str(p.village) || str(p.county);
  const parts = [
    name,
    str(p.street),
    str(p.housenumber),
    str(p.postcode),
    locality,
    str(p.state),
    str(p.country),
  ].filter(Boolean);
  const label = [...new Set(parts)].join(", ");
  if (!label) return null;
  return {
    label,
    lat,
    lng,
    kind: typeof p.type === "string" ? p.type : undefined,
    ...(name ? { name } : {}),
  };
}

export function photonHitsFromCollection(data: {
  features?: unknown[] | null;
}): PhotonHit[] {
  const hits: PhotonHit[] = [];
  for (const f of data.features ?? []) {
    if (!f || typeof f !== "object") continue;
    const hit = photonHitFromFeature(f as PhotonFeature);
    if (hit) hits.push(hit);
  }
  return hits;
}

const COORDS =
  /^\s*(-?\d+(?:\.\d+)?)\s*[,;]\s*(-?\d+(?:\.\d+)?)\s*$/;

export function looksLikeCoordinateLabel(label: string): boolean {
  return COORDS.test(label.trim());
}

export function isPlaceholderPlanLabel(
  label: string | undefined,
  placeholders: readonly string[]
): boolean {
  const t = (label ?? "").trim();
  if (!t) return true;
  if (looksLikeCoordinateLabel(t)) return true;
  if (placeholders.includes(t)) return true;
  if (/^via\s+\d+$/i.test(t)) return true;
  return false;
}
