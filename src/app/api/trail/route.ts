import { NextResponse } from "next/server";
import { fetchTrailViewAlong, fetchTrailViewNear } from "@/lib/routing/trailView";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const honest = searchParams.get("honest") === "1";
  const alongRaw = searchParams.get("along");
  if (alongRaw) {
    const coords: [number, number][] = [];
    for (const part of alongRaw.split("|")) {
      const bits = part.split(",").map(Number);
      if (bits.length === 2 && bits.every((n) => Number.isFinite(n))) {
        coords.push([bits[0], bits[1]]);
      }
    }
    const result = await fetchTrailViewAlong(coords, { honest });
    return NextResponse.json(result);
  }
  const lat = Number(searchParams.get("lat") || 47.45);
  const lng = Number(searchParams.get("lng") || 12.15);
  const result = await fetchTrailViewNear(lat, lng);
  if (honest && result.usingDemo) {
    return NextResponse.json({
      photos: [],
      attribution: result.attribution,
      disclaimer: "Keine Mapillary-Bilder — Token fehlt oder leer.",
      usingDemo: false,
    });
  }
  return NextResponse.json(result);
}
