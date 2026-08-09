import { NextResponse } from "next/server";
import {
  filterToursByBbox,
  normalizeOutdooractivePayload,
  outdooractiveDemoResponse,
  type OutdooractiveTour,
} from "@/lib/geo/outdooractive";

/**
 * Outdooractive Data API adapter (DACH + Frankreich enrichment — not routing truth).
 * GET /api/outdooractive?q=&bbox=&type=&lat=&lon=
 *
 * Hinweis: Viele OA-Testprojekte liefern einen globalen ID-Katalog ohne
 * zuverlässigen Geo-Filter. Discover merged deshalb Live-Treffer nahe der
 * Karte mit Beispieltouren DACH+FR (klare „Beispiel“-Labels).
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
      const d = 0.8;
      bbox = `${lo - d},${la - d},${lo + d},${la + d}`;
    }
  }
  if (!bbox) {
    bbox = "7.2,47.5,9.0,48.6";
  }

  const demos = outdooractiveDemoResponse(q, bbox);
  const key = process.env.OUTDOORACTIVE_API_KEY?.trim();
  const project = process.env.OUTDOORACTIVE_PROJECT_KEY?.trim();
  if (!key || !project) {
    return NextResponse.json({ ...demos, bbox });
  }

  const base = `https://api-oa.com/api/v2/project/${project}`;
  const listParams = new URLSearchParams({ type, key, limit: "30" });
  if (q) listParams.set("q", q);

  try {
    // /search oft diverse IDs; /contents als Fallback
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
        ...demos,
        configured: true,
        usingDemoFallback: true,
        bbox,
        warning: `Outdooractive list ${listRes.status} — Beispiele DACH+FR`,
      });
    }
    const listJson = (await listRes.json()) as {
      answer?: { contents?: { id?: string | number }[] };
    };
    const ids = (listJson.answer?.contents ?? [])
      .map((c) => c.id)
      .filter((id): id is string | number => id != null && `${id}`.length > 0)
      .slice(0, 24);

    if (ids.length === 0) {
      return NextResponse.json({
        ...demos,
        configured: true,
        usingDemoFallback: true,
        bbox,
        warning: "Outdooractive: keine IDs — Beispiele DACH+FR",
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
        })
      );
      details.push(...part);
    }

    const tours: OutdooractiveTour[] = [];
    for (const raw of details) {
      if (!raw) continue;
      tours.push(...normalizeOutdooractivePayload(raw, q));
    }

    const byId = new Map<string, OutdooractiveTour>();
    for (const t of tours) byId.set(t.id, t);

    let liveNear = filterToursByBbox([...byId.values()], bbox);
    if (liveNear.length === 0) {
      const parts = bbox.split(",").map(Number);
      if (parts.length >= 4 && parts.every(Number.isFinite)) {
        const cx = (parts[0] + parts[2]) / 2;
        const cy = (parts[1] + parts[3]) / 2;
        liveNear = [...byId.values()]
          .map((t) => {
            const c = t.center ?? t.geometry?.[0];
            if (!c) return null;
            const dist = Math.hypot(c[0] - cx, c[1] - cy);
            return dist <= 1.5 ? { t, dist } : null;
          })
          .filter((x): x is { t: OutdooractiveTour; dist: number } => x != null)
          .sort((a, b) => a.dist - b.dist)
          .map((x) => x.t)
          .slice(0, 8);
      }
    }

    // Live-Treffer zuerst, dann Beispiele DACH+FR für Discover-Regionen
    const merged: OutdooractiveTour[] = [];
    const seen = new Set<string>();
    for (const t of liveNear) {
      if (seen.has(t.id)) continue;
      seen.add(t.id);
      merged.push(t);
    }
    for (const t of demos.tours) {
      if (seen.has(t.id)) continue;
      seen.add(t.id);
      merged.push(t);
    }

    const usingDemo = liveNear.length === 0;

    return NextResponse.json({
      provider: "outdooractive",
      role: "enrichment_eu",
      configured: true,
      usingDemoFallback: usingDemo,
      query: q,
      bbox,
      tours: merged,
      attribution:
        "Daten © Outdooractive — Enrichment, keine Routing-Wahrheit",
      warning: usingDemo
        ? "OA-Live ohne Regionaltreffer — Beispiele DACH + Frankreich"
        : liveNear.length < 3
          ? "Wenige OA-Live-Treffer — ergänzt um Beispiele DACH+FR"
          : undefined,
    });
  } catch {
    return NextResponse.json({
      ...demos,
      configured: true,
      usingDemoFallback: true,
      bbox,
      warning: "Outdooractive nicht erreichbar — Beispiele DACH+FR",
    });
  }
}
