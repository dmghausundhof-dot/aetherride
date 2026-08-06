import { NextRequest, NextResponse } from "next/server";
import { buildSyncAckFromRequest } from "@/lib/sync/opsLog";

/**
 * F-ACC-002 Sync-Stub
 * Echo-Ack der Client-Ops — kein Multi-Device, keine Persistenz.
 * Produktion: Postgres + Conflict-Merge + echte Revision.
 */
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const ack = buildSyncAckFromRequest(body);
    return NextResponse.json(ack, { status: 200 });
  } catch {
    return NextResponse.json({ error: "Invalid sync payload" }, { status: 400 });
  }
}

export async function GET() {
  return NextResponse.json({
    status: "ready_stub",
    note: "POST /api/sync mit Ops-Array — Demo-Ack only",
  });
}
