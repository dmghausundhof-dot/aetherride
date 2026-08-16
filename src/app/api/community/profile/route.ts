import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";

export const dynamic = "force-dynamic";

const HANDLE_RE = /^[a-z0-9_]{3,24}$/;

const PROFILE_COLS =
  "handle, display_name, bio, sports, show_ride_count, show_preferred_sports, region_label, enabled";

export async function GET(req: Request) {
  const url = new URL(req.url);
  const handle = (url.searchParams.get("handle") || "").trim().toLowerCase();
  const supabase = await createAuthedClient(req);

  if (!handle) {
    try {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) {
        return NextResponse.json({ error: "unauthorized" }, { status: 401 });
      }
      const { data, error } = await supabase
        .from("public_profiles")
        .select(PROFILE_COLS)
        .eq("user_id", user.id)
        .maybeSingle();
      if (error) {
        return NextResponse.json(
          { error: "query_failed", note: error.message },
          { status: 501 }
        );
      }
      return NextResponse.json({ profile: data ?? null, me: true });
    } catch {
      return NextResponse.json({ error: "unauthorized" }, { status: 401 });
    }
  }

  const { data, error } = await supabase
    .from("public_profiles")
    .select(PROFILE_COLS)
    .eq("handle", handle)
    .eq("enabled", true)
    .maybeSingle();
  if (error) {
    return NextResponse.json(
      { error: "query_failed", note: error.message },
      { status: 501 }
    );
  }
  if (!data) return NextResponse.json({ profile: null }, { status: 404 });
  return NextResponse.json({ profile: data });
}

export async function PUT(req: Request) {
  try {
    const supabase = await createAuthedClient(req);
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ error: "unauthorized" }, { status: 401 });
    }
    const body = (await req.json()) as {
      handle?: string;
      displayName?: string;
      bio?: string;
      sports?: string[];
      showRideCount?: boolean;
      showPreferredSports?: boolean;
      regionLabel?: string;
      enabled?: boolean;
    };
    const handle = String(body.handle || "")
      .trim()
      .toLowerCase();
    if (!HANDLE_RE.test(handle)) {
      return NextResponse.json({ error: "invalid_handle" }, { status: 400 });
    }
    const row = {
      user_id: user.id,
      handle,
      display_name: String(body.displayName || "").slice(0, 80),
      bio: String(body.bio || "").slice(0, 280),
      sports: Array.isArray(body.sports)
        ? body.sports.map(String).slice(0, 8)
        : [],
      show_ride_count: Boolean(body.showRideCount),
      show_preferred_sports: body.showPreferredSports !== false,
      region_label: body.regionLabel
        ? String(body.regionLabel).slice(0, 80)
        : null,
      enabled: Boolean(body.enabled),
      updated_at: new Date().toISOString(),
    };
    const { error } = await supabase.from("public_profiles").upsert(row, {
      onConflict: "user_id",
    });
    if (error) {
      return NextResponse.json(
        { error: "upsert_failed", note: error.message },
        { status: 400 }
      );
    }
    return NextResponse.json({ ok: true, handle });
  } catch {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }
}
