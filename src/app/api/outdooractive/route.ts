import { NextResponse } from "next/server";

/**
 * Outdooractive Data API adapter (DACH enrichment — not routing truth).
 * GET /api/outdooractive?q= or ?bbox=
 * Requires OUTDOORACTIVE_API_KEY + OUTDOORACTIVE_PROJECT_KEY.
 */
export async function GET(req: Request) {
  const key = process.env.OUTDOORACTIVE_API_KEY;
  const project = process.env.OUTDOORACTIVE_PROJECT_KEY;
  if (!key || !project) {
    return NextResponse.json(
      {
        error: "not_configured",
        hint: "Set OUTDOORACTIVE_API_KEY and OUTDOORACTIVE_PROJECT_KEY",
        role: "enrichment_only",
      },
      { status: 503 }
    );
  }

  const url = new URL(req.url);
  const q = url.searchParams.get("q");
  const type = url.searchParams.get("type") || "tour";

  const base = `https://api-oa.com/api/v2/project/${project}`;
  const endpoint = q
    ? `${base}/contents?type=${encodeURIComponent(type)}&key=${encodeURIComponent(key)}`
    : `${base}/contents?type=${encodeURIComponent(type)}&key=${encodeURIComponent(key)}`;

  const res = await fetch(endpoint, { next: { revalidate: 3600 } });
  if (!res.ok) {
    return NextResponse.json(
      { error: `outdooractive ${res.status}` },
      { status: 502 }
    );
  }
  const data = await res.json();
  return NextResponse.json({
    provider: "outdooractive",
    role: "enrichment_dach",
    query: q,
    data,
  });
}
