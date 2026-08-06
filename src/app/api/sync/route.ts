import { NextRequest, NextResponse } from "next/server";
import { buildSyncAckFromRequest } from "@/lib/sync/opsLog";
import { getSessionFromCookies } from "@/lib/auth/serverSession";
import { promises as fs } from "fs";
import path from "path";

/**
 * F-ACC-002 Sync
 * Mit Session: Ops user-scoped auf Server ablegen (File-Stub).
 * Ohne Session: 401 — Sync erfordert Konto.
 * Produktion: Postgres + Conflict-Merge.
 */

async function persistUserOps(
  userId: string,
  body: { ops?: { operation_id: string }[]; since?: string | null }
) {
  const dir = path.join(process.cwd(), "data", "sync");
  await fs.mkdir(dir, { recursive: true });
  const file = path.join(dir, `${userId}.json`);
  let prev: { revisions: unknown[] } = { revisions: [] };
  try {
    prev = JSON.parse(await fs.readFile(file, "utf8")) as typeof prev;
  } catch {
    /* new */
  }
  const ack = buildSyncAckFromRequest(body);
  prev.revisions.push({
    at: new Date().toISOString(),
    since: body.since ?? null,
    ack,
    opCount: Array.isArray(body.ops) ? body.ops.length : 0,
  });
  prev.revisions = prev.revisions.slice(-50);
  await fs.writeFile(file, JSON.stringify(prev, null, 2), "utf8");
  return ack;
}

export async function POST(req: NextRequest) {
  try {
    const session = await getSessionFromCookies();
    if (!session) {
      return NextResponse.json(
        {
          error: "Sync erfordert Anmeldung (F-ACC-002)",
          code: "AUTH_REQUIRED",
        },
        { status: 401 }
      );
    }
    const body = (await req.json()) as {
      ops?: { operation_id: string }[];
      since?: string | null;
    };
    const ack = await persistUserOps(session.id, body);
    return NextResponse.json(
      { ...ack, userId: session.id, note: "User-scoped File-Persistenz (Stub)" },
      { status: 200 }
    );
  } catch {
    return NextResponse.json({ error: "Invalid sync payload" }, { status: 400 });
  }
}

export async function GET() {
  const session = await getSessionFromCookies();
  return NextResponse.json({
    status: session ? "authenticated" : "auth_required",
    note: session
      ? "POST /api/sync mit Session-Cookie"
      : "Anmeldung unter /login erforderlich",
    userId: session?.id ?? null,
  });
}
