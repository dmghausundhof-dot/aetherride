import { NextResponse } from "next/server";
import { getPublicTour } from "@/lib/catalog/publicTours";
import { computeTourGeometry } from "@/lib/routing/tourGeometry";

/**
 * GET /api/tours/:id/gpx — Live- oder Override-Geometrie als GPX-Download.
 */
export async function GET(
  _req: Request,
  ctx: { params: Promise<{ id: string }> }
) {
  const { id } = await ctx.params;
  const tour = getPublicTour(id);
  if (!tour) {
    return NextResponse.json({ error: "not_found" }, { status: 404 });
  }

  try {
    const forceLive =
      new URL(_req.url).searchParams.get("forceLive") === "1";
    const geo = await computeTourGeometry(id, undefined, { forceLive });
    const coords =
      geo?.geometry?.coordinates && geo.geometry.coordinates.length >= 2
        ? (geo.geometry.coordinates as [number, number][])
        : null;

    if (!coords) {
      return NextResponse.json(
        { error: "no_geometry", message: "Routing lieferte keine Linie" },
        { status: 502 }
      );
    }

    const trkpts = coords
      .map(
        ([lng, lat], i) =>
          `      <trkpt lat="${lat}" lon="${lng}"><name>${i === 0 ? "Start" : i === coords.length - 1 ? "Ende" : ""}</name></trkpt>`
      )
      .join("\n");

    const gpx = `<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="FlowLine" xmlns="http://www.topografix.com/GPX/1/1">
  <metadata>
    <name>${escapeXml(tour.name)}</name>
    <desc>${escapeXml(tour.summary)} · engine=${geo?.engine ?? "unknown"} · shape=${geo?.shape ?? ""}</desc>
    <time>${new Date().toISOString()}</time>
  </metadata>
  <trk>
    <name>${escapeXml(tour.name)}</name>
    <type>${tour.primaryCategory}</type>
    <trkseg>
${trkpts}
    </trkseg>
  </trk>
</gpx>`;

    return new NextResponse(gpx, {
      status: 200,
      headers: {
        "Content-Type": "application/gpx+xml; charset=utf-8",
        "Content-Disposition": `attachment; filename="aetherride-${id}.gpx"`,
        "Cache-Control": "public, max-age=1800",
      },
    });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "gpx failed" },
      { status: 502 }
    );
  }
}

function escapeXml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
