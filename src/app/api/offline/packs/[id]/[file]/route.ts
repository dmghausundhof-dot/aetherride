import { NextResponse } from "next/server";
import { readOfflinePackFile } from "@/lib/routing/offlinePacks";

export const runtime = "nodejs";

type Ctx = { params: Promise<{ id: string; file: string }> };

const ALLOWED = new Set([
  "manifest.json",
  "offline_graph.json",
  "valhalla.json",
  "valhalla_tiles.tar",
]);

/** GET /api/offline/packs/:id/:file — pack artifact (graph, config, archive). */
export async function GET(_req: Request, ctx: Ctx) {
  const { id, file: rawFile } = await ctx.params;
  const file = decodeURIComponent(rawFile);
  const base = file.split("/").pop() ?? file;
  const okName =
    ALLOWED.has(base) ||
    base.endsWith(".tar.gz") ||
    base.endsWith(".tar.zst");
  if (!okName || file.includes("..")) {
    return NextResponse.json({ error: "forbidden file" }, { status: 400 });
  }
  const found = await readOfflinePackFile(id, base);
  if (!found) {
    return NextResponse.json({ error: "file not found" }, { status: 404 });
  }
  return new NextResponse(new Uint8Array(found.bytes), {
    status: 200,
    headers: {
      "Content-Type": found.contentType,
      "Content-Length": String(found.bytes.length),
      "Cache-Control": "public, max-age=300",
    },
  });
}
