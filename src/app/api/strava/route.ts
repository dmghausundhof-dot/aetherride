import { NextResponse } from "next/server";

/**
 * Strava OAuth scaffold (Spec 8.6 P1).
 * Without STRAVA_CLIENT_ID/SECRET returns clear "not configured".
 * With credentials, returns authorize URL (token exchange = later ops).
 */
export async function GET(req: Request) {
  const clientId = process.env.STRAVA_CLIENT_ID?.trim();
  const clientSecret = process.env.STRAVA_CLIENT_SECRET?.trim();
  const configured = Boolean(clientId && clientSecret);

  if (!configured) {
    return NextResponse.json({
      configured: false,
      message:
        "Strava OAuth nicht konfiguriert — setze STRAVA_CLIENT_ID und STRAVA_CLIENT_SECRET. Bis dahin: Privacy → Strava-Payload-Stub.",
    });
  }

  const url = new URL(req.url);
  const origin =
    process.env.NEXT_PUBLIC_APP_URL?.replace(/\/$/, "") ||
    `${url.protocol}//${url.host}`;
  const redirectUri = `${origin}/api/strava/callback`;
  const authorize = new URL("https://www.strava.com/oauth/authorize");
  authorize.searchParams.set("client_id", clientId!);
  authorize.searchParams.set("response_type", "code");
  authorize.searchParams.set("redirect_uri", redirectUri);
  authorize.searchParams.set("approval_prompt", "auto");
  authorize.searchParams.set("scope", "activity:write,read");

  return NextResponse.json({
    configured: true,
    authorizeUrl: authorize.toString(),
    redirectUri,
    note: "Callback-Token-Austausch folgt — Developer App in Strava anlegen.",
  });
}
