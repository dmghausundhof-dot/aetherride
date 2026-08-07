import { NextResponse } from "next/server";
import {
  listKnownPackIds,
  readOfflineManifest,
} from "@/lib/routing/offlinePacks";

/**
 * GET /api/offline/packs — Katalog verfügbarer Region-Packs (IDs + Namen).
 * Artefakte selbst bleiben Ops/Docker; hier nur Manifest-Metadaten.
 */
export async function GET() {
  const ids = await listKnownPackIds();
  const packs = [];
  for (const id of ids) {
    const m = await readOfflineManifest(id);
    packs.push({
      id,
      name: m?.name ?? id,
      bbox: m?.bbox ?? null,
      builtAt: m?.builtAt ?? null,
      engines: m?.engines ?? null,
      hasManifest: Boolean(m),
    });
  }
  return NextResponse.json({
    packs,
    attribution: "AetherRide Offline Region Packs",
  });
}
