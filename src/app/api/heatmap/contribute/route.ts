import { createClient } from "@supabase/supabase-js";
import { NextResponse } from "next/server";
import {
  cellsFromTrack,
  HEATMAP_K_THRESHOLD,
} from "@/lib/heatmap/cells";
import { createAuthedClient } from "@/lib/supabase/authed";

function admin() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY?.trim();
  if (!url || !key) return null;
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/**
 * POST /api/heatmap/contribute
 * Body: { cells?: string[], track?: {lat,lng}[], consent: true }
 * Stores user×cell without timestamps. Aggregation only via GET /api/heatmap.
 */
export async function POST(req: Request) {
  try {
    const supabase = await createAuthedClient(req);
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ error: "unauthorized" }, { status: 401 });
    }

    const body = (await req.json()) as {
      consent?: boolean;
      cells?: string[];
      track?: { lat: number; lng: number }[];
    };
    if (body.consent !== true) {
      return NextResponse.json(
        { error: "consent_required", message: "heatmap_contribution muss true sein." },
        { status: 403 }
      );
    }

    let cells = Array.isArray(body.cells)
      ? body.cells.filter((c) => typeof c === "string" && c.includes(":"))
      : [];
    if (cells.length === 0 && Array.isArray(body.track)) {
      cells = cellsFromTrack(body.track);
    }
    cells = [...new Set(cells)].slice(0, 400);
    if (cells.length === 0) {
      return NextResponse.json({ ok: true, upserted: 0 });
    }

    const sb = admin();
    if (!sb) {
      return NextResponse.json(
        {
          error: "store_unavailable",
          message: "SUPABASE_SERVICE_ROLE_KEY fehlt — Contribute nicht möglich.",
        },
        { status: 503 }
      );
    }

    const now = new Date().toISOString();
    const rows = cells.map((cell_id) => ({
      cell_id,
      user_id: user.id,
      updated_at: now,
    }));
    const { error } = await sb.from("heatmap_cells").upsert(rows, {
      onConflict: "cell_id,user_id",
    });
    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }
    return NextResponse.json({
      ok: true,
      upserted: rows.length,
      kThreshold: HEATMAP_K_THRESHOLD,
    });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "contribute failed" },
      { status: 500 }
    );
  }
}
