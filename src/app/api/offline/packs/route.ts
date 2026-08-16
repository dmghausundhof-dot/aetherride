import { NextResponse } from "next/server";
import { listMergedOfflineCatalog } from "@/lib/routing/offlinePacks";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
export const revalidate = 0;

/**
 * GET /api/offline/packs — Katalog verfügbarer Region-Packs.
 * Production: Storage `catalog.json` (CDN) wins over git stubs without dist/.
 */
export async function GET() {
  const packs = await listMergedOfflineCatalog();
  return NextResponse.json({
    packs,
    attribution: "FlowLine Offline Region Packs",
  });
}
