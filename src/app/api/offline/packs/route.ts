import { NextResponse } from "next/server";
import {
  fetchPublishedCatalog,
  listKnownPackIds,
  mergeCatalogPreferReady,
  readOfflineManifest,
  sortCatalogPacks,
  toCatalogRow,
} from "@/lib/routing/offlinePacks";

/**
 * GET /api/offline/packs — Katalog verfügbarer Region-Packs.
 * Production: Storage `catalog.json` (CDN) wins over git stubs without dist/.
 */
export async function GET() {
  const ids = await listKnownPackIds();
  const local = [];
  for (const id of ids) {
    const m = await readOfflineManifest(id);
    local.push(await toCatalogRow(id, m));
  }
  const published = await fetchPublishedCatalog();
  const packs = mergeCatalogPreferReady(local, published);
  return NextResponse.json({
    packs: sortCatalogPacks(packs),
    attribution: "FlowLine Offline Region Packs",
  });
}
