import { NextResponse } from "next/server";
import {
  normalizeOutdooractivePayload,
  outdooractiveDemoResponse,
  type OutdooractiveTour,
} from "@/lib/geo/outdooractive";

/**
 * Outdooractive Data API adapter (DACH enrichment — not routing truth).
 * GET /api/outdooractive?q=&bbox=&type=&lat=&lon=
 * List endpoint returns IDs only → hydrate via /contents/{id}.
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
      const d = 0.35;
      bbox = `${lo - d},${la - d},${lo + d},${la + d}`;
    }
  }

  const key = process.env.OUTDOORACTIVE_API_KEY?.trim();
  const project = process.env.OUTDOORACTIVE_PROJECT_KEY?.trim();
  if (!key || !project) {
    return NextResponse.json(outdooractiveDemoResponse(q));
  }

  const base = `https://api-oa.com/api/v2/project/${project}`;
  const listParams = new URLSearchParams({ type, key });
  if (q) listParams.set("q", q);
  if (bbox) listParams.set("bbox", bbox);

  try {
    const listRes = await fetch(`${base}/contents?${listParams}`, {
      next: { revalidate: 1800 },
    });
    if (!listRes.ok) {
      const demo = outdooractiveDemoResponse(q);
      return NextResponse.json({
        ...demo,
        configured: true,
        usingDemoFallback: true,
        warning: `Outdooractive list ${listRes.status} — Demo-Fallback`,
      });
    }
    const listJson = (await listRes.json()) as {
      answer?: { contents?: { id?: string | number }[] };
    };
    const ids = (listJson.answer?.contents ?? [])
      .map((c) => c.id)
      .filter((id): id is string | number => id != null && `${id}`.length > 0)
      .slice(0, 10);

    if (ids.length === 0) {
      return NextResponse.json({
        ...outdooractiveDemoResponse(q),
        configured: true,
        usingDemoFallback: true,
        warning: "Outdooractive: keine IDs in der Region — Demo-Enrichment",
      });
    }

    const details = await Promise.all(
      ids.map(async (id) => {
        const r = await fetch(`${base}/contents/${id}?key=${key}`, {
          next: { revalidate: 3600 },
        });
        if (!r.ok) return null;
        return r.json();
      })
    );

    const tours: OutdooractiveTour[] = [];
    for (const raw of details) {
      if (!raw) continue;
      const hydrated = normalizeOutdooractivePayload(raw, q);
      tours.push(...hydrated);
    }

    // Deduplicate by id
    const byId = new Map<string, OutdooractiveTour>();
    for (const t of tours) byId.set(t.id, t);
    const unique = [...byId.values()];
    const usingDemo = unique.length === 0;

    return NextResponse.json({
      provider: "outdooractive",
      role: "enrichment_dach",
      configured: true,
      usingDemoFallback: usingDemo,
      query: q,
      bbox,
      tours: usingDemo ? outdooractiveDemoResponse(q).tours : unique,
      attribution:
        "Daten © Outdooractive — Enrichment, keine Routing-Wahrheit",
      warning: usingDemo
        ? "API erreichbar, aber keine normalisierbaren Touren — Demo-Enrichment"
        : undefined,
    });
  } catch {
    return NextResponse.json({
      ...outdooractiveDemoResponse(q),
      configured: true,
      usingDemoFallback: true,
      warning: "Outdooractive nicht erreichbar — Demo-Fallback",
    });
  }
}
