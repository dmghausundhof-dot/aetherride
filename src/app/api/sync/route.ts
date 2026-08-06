import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";

export async function GET(req: Request) {
  try {
    const supabase = await createAuthedClient(req);
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ error: "unauthorized" }, { status: 401 });
    }

    const { data, error } = await supabase
      .from("sync_snapshots")
      .select("payload, updated_at")
      .eq("user_id", user.id)
      .maybeSingle();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({
      payload: data?.payload ?? null,
      updatedAt: data?.updated_at ?? null,
    });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "sync failed" },
      { status: 500 }
    );
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

    const body = await req.json();
    const payload = body?.payload ?? body;
    const clientUpdatedAt =
      typeof body?.clientUpdatedAt === "string"
        ? body.clientUpdatedAt
        : typeof payload?.updatedAt === "string"
          ? payload.updatedAt
          : null;

    if (!payload || typeof payload !== "object") {
      return NextResponse.json({ error: "invalid payload" }, { status: 400 });
    }

    const { data: existing } = await supabase
      .from("sync_snapshots")
      .select("payload, updated_at")
      .eq("user_id", user.id)
      .maybeSingle();

    if (existing?.updated_at && clientUpdatedAt) {
      const remoteMs = new Date(existing.updated_at).getTime();
      const clientMs = new Date(clientUpdatedAt).getTime();
      if (
        Number.isFinite(remoteMs) &&
        Number.isFinite(clientMs) &&
        remoteMs > clientMs + 500
      ) {
        return NextResponse.json(
          {
            error: "conflict",
            code: "stale_client",
            remoteUpdatedAt: existing.updated_at,
            payload: existing.payload,
          },
          { status: 409 }
        );
      }
    }

    const now = new Date().toISOString();
    const row = {
      user_id: user.id,
      payload: {
        ...payload,
        updatedAt: now,
        payloadVersion:
          typeof payload.payloadVersion === "number"
            ? payload.payloadVersion
            : 1,
      },
      updated_at: now,
    };

    const { error } = await supabase.from("sync_snapshots").upsert(row, {
      onConflict: "user_id",
    });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ ok: true, updatedAt: now });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "sync failed" },
      { status: 500 }
    );
  }
}
