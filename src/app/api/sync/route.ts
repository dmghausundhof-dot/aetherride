import { NextRequest, NextResponse } from "next/server";
import { getSessionFromCookies } from "@/lib/auth/serverSession";
import {
  getUserSyncStatus,
  loadUserSyncStore,
  opsSince,
  pushUserOps,
} from "@/lib/sync/serverStore";
import type { IncomingSyncOp } from "@/lib/sync/conflictMerge";

/**
 * F-ACC-002 Sync v2
 * POST: Push Ops + LWW-Merge + Pull seit `since`
 * GET: Status / Delta seit ?since=
 */

function normalizeOps(raw: unknown): IncomingSyncOp[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .map((o) => {
      const x = o as Record<string, unknown>;
      return {
        operation_id: String(x.operation_id ?? ""),
        entity: String(x.entity ?? ""),
        entity_id: String(x.entity_id ?? ""),
        op: (x.op as IncomingSyncOp["op"]) ?? "update",
        client_ts: String(x.client_ts ?? new Date().toISOString()),
        payload: x.payload,
      };
    })
    .filter((o) => o.operation_id && o.entity && o.entity_id);
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
      ops?: unknown[];
      since?: string | null;
    };
    const result = await pushUserOps(
      session.id,
      normalizeOps(body.ops),
      body.since
    );
    return NextResponse.json(
      {
        revision: result.revision,
        ackedIds: result.ackedIds,
        conflicts: result.conflicts,
        duplicates: result.duplicates,
        appliedCount: result.appliedCount,
        pulledOps: result.pulledOps,
        userId: session.id,
        note: result.note,
      },
      { status: 200 }
    );
  } catch (e) {
    console.error("[sync POST]", e);
    return NextResponse.json({ error: "Invalid sync payload" }, { status: 400 });
  }
}

export async function GET(req: NextRequest) {
  const session = await getSessionFromCookies();
  if (!session) {
    return NextResponse.json({
      status: "auth_required",
      note: "Anmeldung unter /login erforderlich",
      userId: null,
    });
  }
  const since = req.nextUrl.searchParams.get("since");
  const status = await getUserSyncStatus(session.id);
  const store = await loadUserSyncStore(session.id);
  const pulled = opsSince(store, since);
  return NextResponse.json({
    status: "authenticated",
    userId: session.id,
    ...status,
    pulledOps: since != null ? pulled : undefined,
    note: "GET ?since=revision für Delta-Pull",
  });
}
