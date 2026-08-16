import { createClient } from "@supabase/supabase-js";
import { NextResponse } from "next/server";
import {
  HEATMAP_K_THRESHOLD,
  parseHeatmapCellId,
} from "@/lib/heatmap/cells";

function admin() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY?.trim();
  if (!url || !key) return null;
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/**
 * GET /api/heatmap?west=&south=&east=&north=
 * Returns only cells with uniqueUsers ≥ k (default 5). No user ids.
 */
export async function GET(req: Request) {
  const sb = admin();
  if (!sb) {
    return NextResponse.json(
      {
        segments: [],
        coldStart: true,
        kThreshold: HEATMAP_K_THRESHOLD,
        message: "Heatmap-Store nicht konfiguriert (Service Role).",
      },
      { status: 503 }
    );
  }

  const url = new URL(req.url);
  const west = Number(url.searchParams.get("west"));
  const south = Number(url.searchParams.get("south"));
  const east = Number(url.searchParams.get("east"));
  const north = Number(url.searchParams.get("north"));
  const hasBbox =
    [west, south, east, north].every((n) => Number.isFinite(n));

  const { data, error } = await sb
    .from("heatmap_cells")
    .select("cell_id, user_id");
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  const counts = new Map<string, number>();
  for (const row of data ?? []) {
    const id = row.cell_id as string;
    const parsed = parseHeatmapCellId(id);
    if (!parsed) continue;
    if (hasBbox) {
      if (
        parsed.lng < west ||
        parsed.lng > east ||
        parsed.lat < south ||
        parsed.lat > north
      ) {
        continue;
      }
    }
    counts.set(id, (counts.get(id) ?? 0) + 1);
  }

  const segments = [...counts.entries()]
    .filter(([, n]) => n >= HEATMAP_K_THRESHOLD)
    .map(([id, uniqueUsers]) => {
      const p = parseHeatmapCellId(id)!;
      const d = 0.0004;
      return {
        id: `cell-${id}`,
        uniqueUsers,
        intensity: Math.min(1, uniqueUsers / 20),
        coordinates: [
          [p.lng - d, p.lat - d],
          [p.lng + d, p.lat - d],
          [p.lng + d, p.lat + d],
          [p.lng - d, p.lat + d],
        ] as [number, number][],
      };
    });

  return NextResponse.json({
    segments,
    coldStart: segments.length < 3,
    kThreshold: HEATMAP_K_THRESHOLD,
    attribution: "© OpenStreetMap · FlowLine k≥5 Aggregate",
    disclaimer:
      segments.length === 0
        ? "Noch keine Heatmap-Segmente mit ≥5 Fahrern in diesem Ausschnitt."
        : `Heatmap (k≥${HEATMAP_K_THRESHOLD}), anonym, ohne Zeitstempel.`,
  });
}
