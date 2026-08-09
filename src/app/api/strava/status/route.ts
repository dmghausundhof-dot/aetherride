import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";
import {
  getValidStravaAccessToken,
  stravaAdminClient,
  stravaConfigured,
} from "@/lib/strava/tokens";

/** GET /api/strava/status — connected for current user. */
export async function GET(req: Request) {
  if (!stravaConfigured()) {
    return NextResponse.json({
      configured: false,
      connected: false,
    });
  }
  try {
    const supabase = await createAuthedClient(req);
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({
        configured: true,
        connected: false,
        auth: false,
      });
    }
    const sb = stravaAdminClient();
    if (!sb) {
      return NextResponse.json({
        configured: true,
        connected: false,
        store: false,
      });
    }
    const { data } = await sb
      .from("strava_connections")
      .select("athlete_id, expires_at, updated_at")
      .eq("user_id", user.id)
      .maybeSingle();
    return NextResponse.json({
      configured: true,
      connected: Boolean(data),
      athleteId: data?.athlete_id ?? null,
      updatedAt: data?.updated_at ?? null,
    });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "status failed" },
      { status: 500 }
    );
  }
}
