import { NextResponse } from "next/server";
import { buildTrailforksPins } from "@/lib/geo/trailCondition";

/**
 * Trailforks Condition Layer (Attribution + Wetter-Proxy).
 * GET /api/trailforks?hint=dry_likely|damp_possible|wet_likely
 */
export async function GET(req: Request) {
  const url = new URL(req.url);
  const hint = url.searchParams.get("hint");
  const payload = buildTrailforksPins(hint);
  return NextResponse.json(payload);
}
