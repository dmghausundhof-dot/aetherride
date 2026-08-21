/**
 * Viewport-Feed für User-Touren im Listing-Gate.
 * Keine Polylines — nur Pins/Counts. Stub wenn die Tabelle fehlt.
 */
import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { createAuthedClient } from "@/lib/supabase/authed";
import { clampBbox } from "@/lib/coverage/osmLive";
import { LISTING_CONFIRM_K } from "@/lib/tours/tourListing";

export const dynamic = "force-dynamic";

function sb() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key =
    process.env.SUPABASE_SERVICE_ROLE_KEY ||
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) return null;
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function num(raw: string | null): number | null {
  if (raw == null || raw.trim() === "") return null;
  const n = Number(raw);
  return Number.isFinite(n) ? n : null;
}

export async function GET(req: Request) {
  const url = new URL(req.url);
  const west = num(url.searchParams.get("west"));
  const south = num(url.searchParams.get("south"));
  const east = num(url.searchParams.get("east"));
  const north = num(url.searchParams.get("north"));
  if (west == null || south == null || east == null || north == null) {
    return NextResponse.json({ error: "bbox_required" }, { status: 400 });
  }
  const bbox = clampBbox({ west, south, east, north });
  const client = sb();
  if (!client) {
    return NextResponse.json({
      tours: [],
      nearbyWaiting: 0,
      k: LISTING_CONFIRM_K,
      stub: true,
    });
  }
  const { data, error } = await client
    .from("tour_listings")
    .select("route_id, state, name, center_lng, center_lat, candidate_since")
    .in("state", ["candidate", "listed"])
    .gte("center_lng", bbox.west)
    .lte("center_lng", bbox.east)
    .gte("center_lat", bbox.south)
    .lte("center_lat", bbox.north)
    .limit(24);
  if (error) {
    return NextResponse.json({
      tours: [],
      nearbyWaiting: 0,
      k: LISTING_CONFIRM_K,
      stub: true,
    });
  }
  const tours = (data ?? []).map((row) => ({
    id: String(row.route_id ?? ""),
    name: String(row.name ?? ""),
    state: row.state === "listed" ? "listed" : "candidate",
    center: [Number(row.center_lng) || 0, Number(row.center_lat) || 0] as [
      number,
      number,
    ],
    candidateSince: row.candidate_since ?? null,
  }));
  const nearbyWaiting = tours.filter((t) => t.state === "candidate").length;
  return NextResponse.json({
    tours,
    nearbyWaiting,
    k: LISTING_CONFIRM_K,
    stub: false,
  });
}

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
      tourId?: string;
      kind?: string;
    };
    const tourId = String(body.tourId || "").trim();
    const kind = body.kind === "ride" ? "ride" : "stimme";
    if (!tourId) {
      return NextResponse.json({ error: "tourId_required" }, { status: 400 });
    }
    const { error } = await supabase.from("tour_listing_confirmations").upsert(
      {
        tour_id: tourId,
        rider_id: user.id,
        kind,
      },
      { onConflict: "tour_id,rider_id" }
    );
    if (error) {
      return NextResponse.json(
        { error: "insert_failed", note: error.message, stub: true },
        { status: 501 }
      );
    }
    return NextResponse.json({ ok: true, tourId, kind });
  } catch {
    return NextResponse.json(
      {
        error: "not_implemented",
        note: "Listing confirm needs login + tour_listings table.",
      },
      { status: 501 }
    );
  }
}
