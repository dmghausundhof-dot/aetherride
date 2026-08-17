import type { HeatmapResult, HeatSegment } from "@/lib/routing/heatmaps";
import { trimTrackForHeatmap } from "@/lib/routing/heatmaps";
import { HEATMAP_K_THRESHOLD } from "@/lib/heatmap/cells";

export type HeatmapBbox = {
  west: number;
  south: number;
  east: number;
  north: number;
};

export type HeatmapContributeResult = {
  upserted: number;
  message: string;
  ok: boolean;
};

/**
 * POST /api/heatmap/contribute — trimmed track cells (login + consent required).
 * Mirrors mobile heatmap_client.contributeHeatmapTrack.
 */
export async function contributeHeatmapTrack(input: {
  track: { lat: number; lng: number }[];
  privacyZones: { lat: number; lng: number; radiusM: number }[];
}): Promise<HeatmapContributeResult> {
  const trimmed = trimTrackForHeatmap(input.track, input.privacyZones);
  if (trimmed.length < 4) {
    return {
      upserted: 0,
      ok: false,
      message: "Wo viele fahren: zu wenig Spur nach Privatbereich",
    };
  }
  const points = trimmed
    .filter(
      (p) =>
        Number.isFinite(p.lat) &&
        Number.isFinite(p.lng) &&
        !(Math.abs(p.lat) < 1e-6 && Math.abs(p.lng) < 1e-6)
    )
    .map((p) => ({ lat: p.lat, lng: p.lng }));
  if (points.length < 4) {
    return {
      upserted: 0,
      ok: false,
      message: "Wo viele fahren: keine gültigen GPS-Punkte",
    };
  }

  try {
    const res = await fetch("/api/heatmap/contribute", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({ consent: true, track: points }),
    });
    if (res.status === 401) {
      return {
        upserted: 0,
        ok: false,
        message: "Wo viele fahren: Anmelden nötig für den Beitrag",
      };
    }
    if (!res.ok) {
      let detail = `HTTP ${res.status}`;
      try {
        const m = (await res.json()) as { message?: string; error?: string };
        detail = m.message || m.error || detail;
      } catch {
        /* ignore */
      }
      return {
        upserted: 0,
        ok: false,
        message: `Wo viele fahren: Beitrag fehlgeschlagen (${detail})`,
      };
    }
    const m = (await res.json()) as { upserted?: number };
    const n = typeof m.upserted === "number" ? m.upserted : 0;
    if (n <= 0) {
      return {
        upserted: 0,
        ok: false,
        message: "Wo viele fahren: keine neuen Zellen (bereits beigetragen?)",
      };
    }
    return {
      upserted: n,
      ok: true,
      message: `Wo viele fahren: ${n} Zellen beigetragen (sichtbar erst ab ${HEATMAP_K_THRESHOLD}).`,
    };
  } catch (e) {
    return {
      upserted: 0,
      ok: false,
      message: `Wo viele fahren: offline (${e instanceof Error ? e.message : "Netzwerk"})`,
    };
  }
}

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
        m.attribution ?? "© OpenStreetMap · FlowLine k≥5 Aggregate",
      disclaimer:
        m.disclaimer ??
        `Wo viele fahren (erst ab ${m.kThreshold ?? HEATMAP_K_THRESHOLD}), anonym, ohne Zeitstempel.`,
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
