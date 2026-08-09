/**
 * ~110m grid cells for privacy-preserving heatmap contribution (no timestamps).
 */
export function heatmapCellId(lat: number, lng: number): string {
  const la = Math.round(lat * 1000) / 1000;
  const ln = Math.round(lng * 1000) / 1000;
  return `${la.toFixed(3)}:${ln.toFixed(3)}`;
}

export function parseHeatmapCellId(
  id: string
): { lat: number; lng: number } | null {
  const [a, b] = id.split(":");
  const lat = Number(a);
  const lng = Number(b);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  return { lat, lng };
}

export const HEATMAP_K_THRESHOLD = 5;

/** Deduplicate cells from a trimmed track (lat/lng points). */
export function cellsFromTrack(
  track: { lat: number; lng: number }[],
  maxCells = 400
): string[] {
  const set = new Set<string>();
  for (const p of track) {
    if (!Number.isFinite(p.lat) || !Number.isFinite(p.lng)) continue;
    set.add(heatmapCellId(p.lat, p.lng));
    if (set.size >= maxCells) break;
  }
  return [...set];
}
