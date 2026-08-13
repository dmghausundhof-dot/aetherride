import { NextResponse } from "next/server";
import { readOfflinePackFile } from "@/lib/routing/offlinePacks";

export const runtime = "nodejs";

type Ctx = { params: Promise<{ id: string; file: string }> };

const ALLOWED = new Set([
  "manifest.json",
  "offline_graph.json",
  "valhalla.json",
  "valhalla_tiles.tar",
  "bike-overlay.geojson",
  "bike-overlay.pmtiles",
]);

/** GET /api/offline/packs/:id/:file — pack artifact (graph, overlay, archive). */
export async function GET(req: Request, ctx: Ctx) {
  const { id, file: rawFile } = await ctx.params;
  const file = decodeURIComponent(rawFile);
  const base = file.split("/").pop() ?? file;
  const okName =
    ALLOWED.has(base) ||
    base.endsWith(".tar.gz") ||
    base.endsWith(".tar.zst") ||
    base.endsWith(".pmtiles") ||
    base.endsWith(".geojson");
  if (!okName || file.includes("..")) {
    return NextResponse.json({ error: "forbidden file" }, { status: 400 });
  }
  const found = await readOfflinePackFile(id, base);
  if (!found) {
    return NextResponse.json({ error: "file not found" }, { status: 404 });
  }
  const bytes = found.bytes;
  const range = req.headers.get("range");
  if (range && range.startsWith("bytes=")) {
    const spec = range.slice(6);
    const [a, b] = spec.split("-");
    const start = Math.max(0, Number(a || 0));
    const end = Math.min(bytes.length - 1, b ? Number(b) : bytes.length - 1);
    if (Number.isFinite(start) && Number.isFinite(end) && start <= end) {
      const slice = bytes.subarray(start, end + 1);
      return new NextResponse(new Uint8Array(slice), {
        status: 206,
        headers: {
          "Content-Type": found.contentType,
          "Content-Length": String(slice.length),
          "Content-Range": `bytes ${start}-${end}/${bytes.length}`,
          "Accept-Ranges": "bytes",
          "Cache-Control": "public, max-age=300",
        },
      });
    }
  }
  return new NextResponse(new Uint8Array(bytes), {
    status: 200,
    headers: {
      "Content-Type": found.contentType,
      "Content-Length": String(bytes.length),
      "Accept-Ranges": "bytes",
      "Cache-Control": "public, max-age=300",
    },
  });
}
