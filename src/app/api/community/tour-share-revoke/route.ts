/**
 * GET  /api/community/tour-share-revoke?routeId=&epoch=
 * POST /api/community/tour-share-revoke { routeId, epoch } (auth)
 *
 * Tabelle kann fehlen (501) — dann gilt nur lokaler Widerruf.
 */
import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";
import { createAdminClient } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

function validRouteId(id: string): boolean {
  return id.length >= 2 && id.length <= 120 && !id.includes("/");
}

export async function GET(req: Request) {
  const url = new URL(req.url);
  const routeId = url.searchParams.get("routeId")?.trim() || "";
  const epoch = Number(url.searchParams.get("epoch") ?? 0);
  if (!validRouteId(routeId)) {
    return NextResponse.json({ error: "invalid_id" }, { status: 400 });
  }
  try {
    const admin = createAdminClient();
    const q = admin
      .from("tour_share_revocations")
      .select("epoch")
      .eq("route_id", routeId);
    const { data, error } = Number.isFinite(epoch)
      ? await q.gte("epoch", epoch)
      : await q;
    if (error) {
      return NextResponse.json(
        { revoked: false, note: error.message },
        { status: 501 }
      );
    }
    const max = (data ?? []).reduce(
      (m, row) => Math.max(m, Number(row.epoch) || 0),
      0
    );
    const tokenEpoch = Number.isFinite(epoch) ? epoch : 0;
    return NextResponse.json({
      revoked: max > 0 && tokenEpoch <= max,
      epoch: max,
    });
  } catch {
    return NextResponse.json({ revoked: false, error: "unavailable" }, { status: 501 });
  }
}

export async function POST(req: Request) {
  try {
    const supabase = await createAuthedClient(req);
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ error: "unauthorized" }, { status: 401 });
    }
    const body = (await req.json()) as { routeId?: string; epoch?: number };
    const routeId = String(body.routeId ?? "").trim();
    const epoch = Number(body.epoch ?? 0);
    if (!validRouteId(routeId) || !Number.isFinite(epoch) || epoch < 1) {
      return NextResponse.json({ error: "invalid_payload" }, { status: 400 });
    }
    const { error } = await supabase.from("tour_share_revocations").upsert({
      route_id: routeId,
      epoch,
      owner_id: user.id,
    });
    if (error) {
      return NextResponse.json(
        { ok: false, error: "insert_failed", note: error.message },
        { status: 501 }
      );
    }
    return NextResponse.json({ ok: true, routeId, epoch });
  } catch {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }
}
