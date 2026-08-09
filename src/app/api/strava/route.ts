import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";
import { signStravaOAuthState } from "@/lib/strava/oauthState";
import { stravaConfigured } from "@/lib/strava/tokens";

/**
 * Strava OAuth start.
 * With Bearer/Cookie session: signed state binds tokens to user_id (Mobile+Web).
 * Without session: still returns authorize URL, but callback cannot store by user
 * (cookie-only connected flag) — prefer logged-in Connect.
 */
export async function GET(req: Request) {
  const clientId = process.env.STRAVA_CLIENT_ID?.trim();
  const configured = stravaConfigured();

  if (!configured) {
    return NextResponse.json({
      configured: false,
      connected: false,
      message:
        "Strava OAuth nicht konfiguriert — setze STRAVA_CLIENT_ID und STRAVA_CLIENT_SECRET. Export bis dahin: GPX/FIT unter Daten & Privatsphäre.",
    });
  }

  const url = new URL(req.url);
  const origin =
    process.env.NEXT_PUBLIC_APP_URL?.replace(/\/$/, "") ||
    `${url.protocol}//${url.host}`;
  const redirectUri = `${origin}/api/strava/callback`;
  const mobile =
    url.searchParams.get("mobile") === "1" ||
    url.searchParams.get("platform") === "mobile";

  let userId: string | null = null;
  try {
    const supabase = await createAuthedClient(req);
    const {
      data: { user },
    } = await supabase.auth.getUser();
    userId = user?.id ?? null;
  } catch {
    userId = null;
  }

  let state: string;
  try {
    if (userId) {
      state = signStravaOAuthState(userId, { mobile });
    } else {
      state = crypto.randomUUID();
    }
  } catch {
    return NextResponse.json(
      {
        configured: true,
        connected: false,
        error: "state_sign_failed",
        message: "STRAVA_CLIENT_SECRET fehlt für State-Signatur.",
      },
      { status: 503 }
    );
  }

  const authorize = new URL("https://www.strava.com/oauth/authorize");
  authorize.searchParams.set("client_id", clientId!);
  authorize.searchParams.set("response_type", "code");
  authorize.searchParams.set("redirect_uri", redirectUri);
  authorize.searchParams.set("approval_prompt", "auto");
  authorize.searchParams.set("scope", "activity:write,read");
  authorize.searchParams.set("state", state);

  const res = NextResponse.json({
    configured: true,
    authorizeUrl: authorize.toString(),
    redirectUri,
    requiresAuth: !userId,
    mobile,
    note: userId
      ? "Callback speichert Tokens unter deinem Account."
      : "Bitte einloggen — sonst kein geräteübergreifender Upload.",
  });
  res.cookies.set("strava_oauth_state", state, {
    httpOnly: true,
    sameSite: "lax",
    path: "/",
    maxAge: 600,
  });
  return res;
}
