/**
 * POST /api/community/collections — create short link (auth).
 * GET  /api/community/collections?id= — public payload.
 */
import { NextResponse } from "next/server";
import { randomBytes } from "crypto";
import { createAuthedClient } from "@/lib/supabase/authed";
import { createAdminClient } from "@/lib/supabase/admin";
import type { SharedCollectionPayload } from "@/lib/community/types";

export const dynamic = "force-dynamic";

function shortId() {
  return randomBytes(5).toString("base64url").replace(/[^a-zA-Z0-9]/g, "x").slice(0, 8);
}

function validPayload(raw: unknown): SharedCollectionPayload | null {
  if (!raw || typeof raw !== "object") return null;
  const p = raw as SharedCollectionPayload;
  if (p.v !== 1 || typeof p.name !== "string" || !Array.isArray(p.routeIds)) {
    return null;
  }
  if (p.routeIds.length < 1 || p.routeIds.length > 40) return null;
  return {
    v: 1,
    name: String(p.name).slice(0, 80),
    description: p.description ? String(p.description).slice(0, 280) : undefined,
    routeIds: p.routeIds.map(String).slice(0, 40),
    routeNames: Array.isArray(p.routeNames)
      ? p.routeNames.map(String).slice(0, 40)
      : [],
    authorLabel: String(p.authorLabel || "Rider").slice(0, 80),
    authorHandle: p.authorHandle
      ? String(p.authorHandle).slice(0, 24)
      : undefined,
    createdAt: p.createdAt || new Date().toISOString(),
  };
}

export async function GET(req: Request) {
  const id = new URL(req.url).searchParams.get("id")?.trim() || "";
  if (!/^[a-zA-Z0-9]{6,12}$/.test(id)) {
    return NextResponse.json({ error: "invalid_id" }, { status: 400 });
  }
  try {
    const admin = createAdminClient();
    const { data, error } = await admin
      .from("shared_collections")
      .select("short_id, payload, created_at")
      .eq("short_id", id)
      .maybeSingle();
    if (error) {
      return NextResponse.json(
        { error: "query_failed", note: error.message },
        { status: 501 }
      );
    }
    if (!data) return NextResponse.json({ collection: null }, { status: 404 });
    return NextResponse.json({
      id: data.short_id,
      payload: data.payload,
      createdAt: data.created_at,
    });
  } catch {
    return NextResponse.json({ error: "unavailable" }, { status: 501 });
  }
}

export async function DELETE(req: Request) {
  const id = new URL(req.url).searchParams.get("id")?.trim() || "";
  if (!/^[a-zA-Z0-9]{6,12}$/.test(id)) {
    return NextResponse.json({ error: "invalid_id" }, { status: 400 });
  }
  try {
    const supabase = await createAuthedClient(req);
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ error: "unauthorized" }, { status: 401 });
    }
    const { data, error } = await supabase
      .from("shared_collections")
      .delete()
      .eq("short_id", id)
      .eq("owner_id", user.id)
      .select("short_id")
      .maybeSingle();
    if (error) {
      return NextResponse.json(
        { error: "delete_failed", note: error.message },
        { status: 501 }
      );
    }
    if (!data) {
      return NextResponse.json({ error: "not_found" }, { status: 404 });
    }
    return NextResponse.json({ ok: true, id });
  } catch {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
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
    const payload = validPayload(body.payload ?? body);
    if (!payload) {
      return NextResponse.json({ error: "invalid_payload" }, { status: 400 });
    }
    let id = shortId();
    for (let i = 0; i < 5; i++) {
      const { error } = await supabase.from("shared_collections").insert({
        short_id: id,
        owner_id: user.id,
        payload,
      });
      if (!error) {
        return NextResponse.json({ ok: true, id, path: `/share/c/${id}` });
      }
      if (error.code === "23505") {
        id = shortId();
        continue;
      }
      return NextResponse.json(
        { error: "insert_failed", note: error.message },
        { status: 501 }
      );
    }
    return NextResponse.json({ error: "id_collision" }, { status: 500 });
  } catch {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }
}
