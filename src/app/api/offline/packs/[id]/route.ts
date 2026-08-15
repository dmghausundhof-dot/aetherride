import { NextResponse } from "next/server";
import {
  applyPackCdn,
  fetchPublishedManifest,
  listKnownPackIds,
  manifestHasFileEntries,
  readOfflineManifest,
} from "@/lib/routing/offlinePacks";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
export const revalidate = 0;

type Ctx = { params: Promise<{ id: string }> };

/** GET /api/offline/packs/:id — region pack manifest (SHA-256, CDN hints). */
export async function GET(_req: Request, ctx: Ctx) {
  const { id } = await ctx.params;
  const local = await readOfflineManifest(id);
  const withCdn = local ? applyPackCdn(id, local) : null;
  if (withCdn && manifestHasFileEntries(withCdn)) {
    return NextResponse.json(withCdn, {
      headers: { "Cache-Control": "public, max-age=60" },
    });
  }
  const published = await fetchPublishedManifest(id);
  if (published) {
    return NextResponse.json(published, {
      headers: { "Cache-Control": "public, max-age=60" },
    });
  }
  if (withCdn) {
    return NextResponse.json(withCdn, {
      headers: { "Cache-Control": "public, max-age=60" },
    });
  }
  return NextResponse.json(
    {
      error: "pack not found",
      known: await listKnownPackIds(),
    },
    { status: 404 },
  );
}
