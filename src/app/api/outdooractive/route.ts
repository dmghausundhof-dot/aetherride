import { NextResponse } from "next/server";
import {
  normalizeOutdooractivePayload,
  outdooractiveDemoResponse,
} from "@/lib/geo/outdooractive";

/**
 * Outdooractive Data API adapter (DACH enrichment — not routing truth).
 * GET /api/outdooractive?q=&bbox=&type=
 * Requires OUTDOORACTIVE_API_KEY + OUTDOORACTIVE_PROJECT_KEY — sonst Demo.
 */
export async function GET(req: Request) {
  const url = new URL(req.url);
  const q = url.searchParams.get("q");
  const bbox = url.searchParams.get("bbox");
  const type = url.searchParams.get("type") || "tour";

  const key = process.env.OUTDOORACTIVE_API_KEY;
  const project = process.env.OUTDOORACTIVE_PROJECT_KEY;
  if (!key || !project) {
    return NextResponse.json(outdooractiveDemoResponse(q));
  }

  const base = `https://api-oa.com/api/v2/project/${project}`;
  const params = new URLSearchParams({
    type,
    key,
  });
  if (q) params.set("q", q);
  if (bbox) params.set("bbox", bbox);

  const endpoint = `${base}/contents?${params}`;

  try {
    const res = await fetch(endpoint, { next: { revalidate: 3600 } });
    if (!res.ok) {
      const demo = outdooractiveDemoResponse(q);
      return NextResponse.json({
        ...demo,
        warning: `Outdooractive ${res.status} — Demo-Fallback`,
      });
    }
    const data = await res.json();
    const tours = normalizeOutdooractivePayload(data, q);
    const usingDemo = tours.length === 0;
    return NextResponse.json({
      provider: "outdooractive",
      role: "enrichment_dach",
      configured: true,
      usingDemoFallback: usingDemo,
      query: q,
      bbox,
      tours: usingDemo ? outdooractiveDemoResponse(q).tours : tours,
      attribution: "Daten © Outdooractive — Enrichment, keine Routing-Wahrheit",
      warning: usingDemo
        ? "API erreichbar, aber keine normalisierbaren Touren — Demo-Enrichment"
        : undefined,
    });
  } catch {
    return NextResponse.json({
      ...outdooractiveDemoResponse(q),
      configured: false,
      usingDemoFallback: true,
      warning: "Outdooractive nicht erreichbar — Demo-Fallback",
    });
  }
}
