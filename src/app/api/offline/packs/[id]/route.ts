import { NextResponse } from "next/server";
import {
  listKnownPackIds,
  readOfflineManifest,
} from "@/lib/routing/offlinePacks";

export const runtime = "nodejs";

type Ctx = { params: Promise<{ id: string }> };

/** GET /api/offline/packs/:id — region pack manifest (SHA-256, CDN hints). */
export async function GET(_req: Request, ctx: Ctx) {
  const { id } = await ctx.params;
  const manifest = await readOfflineManifest(id);
  if (!manifest) {
    return NextResponse.json(
      {
        error: "pack not found",
        known: listKnownPackIds(),
      },
      { status: 404 }
    );
  }
  const base =
    process.env.ROUTING_CDN_BASE?.replace(/\/$/, "") ||
    process.env.NEXT_PUBLIC_APP_URL?.replace(/\/$/, "") ||
    "";
  if (base && (!manifest.cdn || !manifest.cdn.baseUrl)) {
    manifest.cdn = {
      ...(manifest.cdn || {}),
      baseUrl: `${base}/api/offline/packs/${id}`,
    };
  }
  return NextResponse.json(manifest, {
    headers: { "Cache-Control": "public, max-age=60" },
  });
}
