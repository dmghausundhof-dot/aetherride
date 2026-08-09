import type { HeatmapResult, HeatSegment } from "@/lib/routing/heatmaps";
import { HEATMAP_K_THRESHOLD } from "@/lib/heatmap/cells";

export type HeatmapBbox = {
  west: number;
  south: number;
  east: number;
  north: number;
};

/**
 * GET /api/heatmap — community segments already filtered to k≥threshold.
 * Returns null on network/5xx; empty result on cold start 200.
 */
export async function fetchCommunityHeatmap(
  bbox: HeatmapBbox,
  init?: RequestInit
): Promise<HeatmapResult | null> {
  const q = new URLSearchParams({
    west: String(bbox.west),
    south: String(bbox.south),
    east: String(bbox.east),
    north: String(bbox.north),
  });
  try {
    const res = await fetch(`/api/heatmap?${q}`, {
      headers: { Accept: "application/json" },
      ...init,
    });
    if (!res.ok) return null;
    const m = (await res.json()) as {
      segments?: {
        id?: string;
        uniqueUsers?: number;
        intensity?: number;
        coordinates?: [number, number][];
      }[];
      coldStart?: boolean;
      kThreshold?: number;
      attribution?: string;
      disclaimer?: string;
    };
    const segments: HeatSegment[] = [];
    for (const e of m.segments ?? []) {
      const coords = (e.coordinates ?? []).filter(
        (p): p is [number, number] =>
          Array.isArray(p) &&
          p.length >= 2 &&
          Number.isFinite(p[0]) &&
          Number.isFinite(p[1])
      );
      if (coords.length < 2) continue;
      segments.push({
        id: String(e.id ?? "c"),
        coordinates: coords,
        uniqueUsers: e.uniqueUsers ?? HEATMAP_K_THRESHOLD,
        intensity: e.intensity ?? 0.5,
        visible: true,
      });
    }
    return {
      segments,
      coldStart: m.coldStart === true || segments.length === 0,
      kThreshold: m.kThreshold ?? HEATMAP_K_THRESHOLD,
      attribution:
        m.attribution ?? "© OpenStreetMap · AetherRide k≥5 Aggregate",
      disclaimer:
        m.disclaimer ??
        `Community-Heatmap (k≥${m.kThreshold ?? HEATMAP_K_THRESHOLD}).`,
    };
  } catch {
    return null;
  }
}

/** BBox around a map center (degrees), similar to mobile Discover. */
export function bboxAround(
  lng: number,
  lat: number,
  dLng = 0.45,
  dLat = 0.35
): HeatmapBbox {
  return {
    west: lng - dLng,
    south: lat - dLat,
    east: lng + dLng,
    north: lat + dLat,
  };
}
