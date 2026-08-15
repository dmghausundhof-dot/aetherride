import { NextResponse } from "next/server";
import {
  filterToursByBbox,
  normalizeOutdooractivePayload,
  type OutdooractiveTour,
} from "@/lib/geo/outdooractive";

/**
 * Outdooractive Data API — nur Live-Touren, keine Demo-Fallbacks.
 * GET /api/outdooractive?q=&bbox=&type=&lat=&lon=
 */
export async function GET(req: Request) {
  const url = new URL(req.url);
  const q = url.searchParams.get("q");
  const type = url.searchParams.get("type") || "tour";
  let bbox = url.searchParams.get("bbox");
  const lat = url.searchParams.get("lat");
  const lon = url.searchParams.get("lon");
  if (!bbox && lat && lon) {
    const la = Number(lat);
    const lo = Number(lon);
    if (Number.isFinite(la) && Number.isFinite(lo)) {
      // ~±130 km — mehr DACH-Treffer um den Standort, ohne EU-weit zu spammen.
      const d = 1.2;
      bbox = `${lo - d},${la - d},${lo + d},${la + d}`;
    }
  }

  const key = process.env.OUTDOORACTIVE_API_KEY?.trim();
  const project = process.env.OUTDOORACTIVE_PROJECT_KEY?.trim();
  if (!key || !project) {
    return NextResponse.json({
      provider: "outdooractive",
      role: "enrichment_eu",
      configured: false,
      usingDemoFallback: false,
      tours: [],
      bbox,
      warning: "Outdooractive nicht konfiguriert",
    });
  }

  const base = `https://api-oa.com/api/v2/project/${project}`;
  const listParams = new URLSearchParams({ type, key, limit: "60" });
  if (q) listParams.set("q", q);

  try {
    let listRes = await fetch(`${base}/search?${listParams}`, {
      next: { revalidate: 1800 },
    });
    if (!listRes.ok) {
      listRes = await fetch(`${base}/contents?${listParams}`, {
        next: { revalidate: 1800 },
      });
    }
    if (!listRes.ok) {
      return NextResponse.json({
        provider: "outdooractive",
        configured: true,
        usingDemoFallback: false,
        tours: [],
        bbox,
        warning: `Outdooractive list ${listRes.status}`,
      });
    }
    const listJson = (await listRes.json()) as {
      answer?: { contents?: { id?: string | number }[] };
    };
    const ids = (listJson.answer?.contents ?? [])
      .map((c) => c.id)
      .filter((id): id is string | number => id != null && `${id}`.length > 0)
      .slice(0, 48);

    if (ids.length === 0) {
      return NextResponse.json({
        provider: "outdooractive",
        configured: true,
        usingDemoFallback: false,
        tours: [],
        bbox,
        warning: "Outdooractive: keine Treffer",
      });
    }

    const details: unknown[] = [];
    for (let i = 0; i < ids.length; i += 8) {
      const chunk = ids.slice(i, i + 8);
      const part = await Promise.all(
        chunk.map(async (id) => {
          const r = await fetch(`${base}/contents/${id}?key=${key}`, {
            next: { revalidate: 3600 },
          });
          if (!r.ok) return null;
          return r.json();
        }),
      );
      details.push(...part);
    }

    const tours: OutdooractiveTour[] = [];
    for (const raw of details) {
      if (!raw) continue;
      tours.push(
        ...normalizeOutdooractivePayload(raw, q).map((t) => ({
          ...t,
          source: "outdooractive" as const,
        })),
      );
    }

    const byId = new Map<string, OutdooractiveTour>();
    for (const t of tours) {
      if (t.source === "demo") continue;
      byId.set(t.id, t);
    }

    let liveNear = bbox
      ? filterToursByBbox([...byId.values()], bbox)
      : [...byId.values()];

    if (liveNear.length === 0 && bbox) {
      const parts = bbox.split(",").map(Number);
      if (parts.length >= 4 && parts.every(Number.isFinite)) {
        const cx = (parts[0] + parts[2]) / 2;
        const cy = (parts[1] + parts[3]) / 2;
        liveNear = [...byId.values()]
          .map((t) => {
            const c = t.center ?? t.geometry?.[0];
            if (!c) return null;
            const dist = Math.hypot(c[0] - cx, c[1] - cy);
            return dist <= 2.2 ? { t, dist } : null;
          })
          .filter((x): x is { t: OutdooractiveTour; dist: number } => x != null)
          .sort((a, b) => a.dist - b.dist)
          .map((x) => x.t)
          .slice(0, 24);
      }
    }

    return NextResponse.json({
      provider: "outdooractive",
      role: "enrichment_eu",
      configured: true,
      usingDemoFallback: false,
      query: q,
      bbox,
      tours: liveNear,
      attribution:
        "Daten © Outdooractive — Enrichment, keine Routing-Wahrheit",
      warning:
        liveNear.length === 0
          ? "Keine Outdooractive-Touren in der Nähe"
          : undefined,
    });
  } catch {
    return NextResponse.json({
      provider: "outdooractive",
      configured: true,
      usingDemoFallback: false,
      tours: [],
      bbox,
      warning: "Outdooractive nicht erreichbar",
    });
  }
}
