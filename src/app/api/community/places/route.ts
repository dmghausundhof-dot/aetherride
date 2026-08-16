/**
 * GET /api/community/places?lat=&lng=&tourId=&west=&south=&east=&north=
 *
 * Approved map_places + Stimme-Pins der Tour. Coverage bleibt beim Client.
 * Tabelle fehlt → stub=true, leere Liste, ehrliche Copy.
 */
import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import {
  isMissingMapPlacesTable,
  mergeCommunityPlaces,
  normalizePlaceKind,
  type CommunityPlace,
} from "@/lib/community/placesMerger";

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

function bboxAround(lat: number, lng: number, km = 8) {
  const dLat = km / 111;
  const dLng = km / (111 * Math.max(0.2, Math.cos((lat * Math.PI) / 180)));
  return {
    west: lng - dLng,
    south: lat - dLat,
    east: lng + dLng,
    north: lat + dLat,
  };
}

function numParam(raw: string | null): number | null {
  if (raw == null || raw === "") return null;
  const n = Number(raw);
  return Number.isFinite(n) ? n : null;
}

export async function GET(req: Request) {
  const url = new URL(req.url);
  const lat = numParam(url.searchParams.get("lat"));
  const lng = numParam(
    url.searchParams.get("lng") ?? url.searchParams.get("lon")
  );
  const tourId = (url.searchParams.get("tourId") || "").trim();
  if (lat == null || lng == null) {
    return NextResponse.json({ error: "lat_lng_required" }, { status: 400 });
  }
  if (Math.abs(lat) > 90 || Math.abs(lng) > 180) {
    return NextResponse.json({ error: "invalid_lat_lng" }, { status: 400 });
  }
  const around = bboxAround(lat, lng);
  const west = numParam(url.searchParams.get("west")) ?? around.west;
  const south = numParam(url.searchParams.get("south")) ?? around.south;
  const east = numParam(url.searchParams.get("east")) ?? around.east;
  const north = numParam(url.searchParams.get("north")) ?? around.north;

  const client = sb();
  if (!client) {
    const merged = mergeCommunityPlaces({});
    return NextResponse.json({
      places: merged.places,
      stub: true,
      honesty: "Orte-Cloud nicht konfiguriert — Coverage auf dem Gerät.",
    });
  }

  let stub = false;
  const mapPlaces: CommunityPlace[] = [];
  const { data: rows, error } = await client
    .from("map_places")
    .select("id, source, kind, name, lat, lng, tour_id, tip")
    .eq("status", "approved")
    .gte("lat", south)
    .lte("lat", north)
    .gte("lng", west)
    .lte("lng", east)
    .limit(80);

  if (error) {
    stub = isMissingMapPlacesTable(error);
  } else {
    for (const row of rows ?? []) {
      const r = row as Record<string, unknown>;
      const id = String(r.id || "").trim();
      const name = String(r.name || "").trim();
      const plat = Number(r.lat);
      const plng = Number(r.lng);
      if (!id || !name || !Number.isFinite(plat) || !Number.isFinite(plng)) {
        continue;
      }
      mapPlaces.push({
        id,
        name,
        kind: normalizePlaceKind(r.kind),
        lat: plat,
        lng: plng,
        source: "map_places",
        tourId: r.tour_id ? String(r.tour_id) : undefined,
        tip: r.tip ? String(r.tip) : undefined,
      });
    }
  }

  const stimmePins: CommunityPlace[] = [];
  if (tourId) {
    let reviews = await client
      .from("tour_reviews")
      .select("id, tour_id, tags, pin_lat, pin_lng, body")
      .eq("tour_id", tourId)
      .eq("status", "approved")
      .not("pin_lat", "is", null)
      .limit(40);
    if (reviews.error) {
      reviews = await client
        .from("tour_reviews")
        .select("id, tour_id, tags, body")
        .eq("tour_id", tourId)
        .eq("status", "approved")
        .limit(40);
    }
    if (!reviews.error) {
      for (const row of reviews.data ?? []) {
        const r = row as Record<string, unknown>;
        const plat = Number(r.pin_lat);
        const plng = Number(r.pin_lng);
        if (!Number.isFinite(plat) || !Number.isFinite(plng)) continue;
        const tags = Array.isArray(r.tags) ? r.tags.map(String) : [];
        const name = tags[0] || String(r.body || "").trim().slice(0, 32) || "Stimme";
        stimmePins.push({
          id: `stimme-${r.id}`,
          name,
          kind: "tip",
          lat: plat,
          lng: plng,
          source: "stimme",
          tourId,
          tip: String(r.body || "").slice(0, 200),
        });
      }
    }
  }

  const merged = mergeCommunityPlaces({ mapPlaces, stimmePins });
  return NextResponse.json({
    places: merged.places,
    stub,
    honesty: stub
      ? "Nur Coverage-Orte — Community-Tabelle noch nicht da."
      : merged.honesty,
  });
}
