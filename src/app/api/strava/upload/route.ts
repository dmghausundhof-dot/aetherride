import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";
import {
  getValidStravaAccessToken,
  stravaConfigured,
} from "@/lib/strava/tokens";

type UploadBody = {
  name?: string;
  type?: string;
  sport_type?: string;
  start_date_local?: string;
  elapsed_time?: number;
  distance?: number;
  total_elevation_gain?: number;
  description?: string;
  /** GPX 1.1 XML — when present with ≥2 trkpt, uses Strava Uploads API */
  gpx?: string;
};

function gpxTrackPointCount(gpx: string): number {
  const matches = gpx.match(/<trkpt\b/gi);
  return matches?.length ?? 0;
}

/**
 * POST /api/strava/upload
 * Prefer GPX → Strava Uploads API; otherwise metadata Activity create.
 * Requires STRAVA_* + strava_connections row (after OAuth).
 */
export async function POST(req: Request) {
  if (!stravaConfigured()) {
    return NextResponse.json(
      {
        error: "not_configured",
        message: "STRAVA_CLIENT_ID/SECRET fehlen — kein Upload.",
      },
      { status: 503 }
    );
  }

  try {
    const supabase = await createAuthedClient(req);
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ error: "unauthorized" }, { status: 401 });
    }

    const access = await getValidStravaAccessToken(user.id);
    if (!access) {
      return NextResponse.json(
        {
          error: "not_connected",
          message: "Strava nicht verbunden — zuerst OAuth abschließen.",
        },
        { status: 409 }
      );
    }

    const body = (await req.json()) as UploadBody;
    const gpx = typeof body.gpx === "string" ? body.gpx.trim() : "";
    const trkpts = gpx ? gpxTrackPointCount(gpx) : 0;

    if (gpx && trkpts >= 2) {
      const form = new FormData();
      form.append(
        "file",
        new Blob([gpx], { type: "application/gpx+xml" }),
        "aetherride.gpx"
      );
      form.append("data_type", "gpx");
      form.append(
        "name",
        body.name?.trim() ||
          `AetherRide ${new Date().toISOString().slice(0, 10)}`
      );
      if (body.description?.trim()) {
        form.append("description", body.description.trim());
      }
      form.append(
        "activity_type",
        body.sport_type === "Ride" || body.type === "Ride"
          ? "ride"
          : "ride"
      );
      if (body.sport_type) {
        // Strava uploads accept activity_type; sport_type is activity create only
      }

      const uploadRes = await fetch(
        "https://www.strava.com/api/v3/uploads",
        {
          method: "POST",
          headers: { Authorization: `Bearer ${access}` },
          body: form,
        }
      );
      const text = await uploadRes.text();
      let json: unknown = null;
      try {
        json = JSON.parse(text);
      } catch {
        json = { raw: text };
      }
      if (!uploadRes.ok) {
        return NextResponse.json(
          {
            error: "strava_api",
            status: uploadRes.status,
            detail: json,
            message: "Strava GPX-Upload fehlgeschlagen",
          },
          { status: 502 }
        );
      }
      return NextResponse.json({
        ok: true,
        mode: "gpx_upload",
        upload: json,
        trackPoints: trkpts,
      });
    }

    const elapsed = Number(body.elapsed_time);
    if (!Number.isFinite(elapsed) || elapsed <= 0) {
      return NextResponse.json(
        {
          error: "elapsed_time required",
          message:
            gpx && trkpts < 2
              ? "Kein GPS-Track (≤1 Punkt) und keine gültige elapsed_time — Upload abgebrochen."
              : "elapsed_time required",
        },
        { status: 400 }
      );
    }

    const payload = {
      name:
        body.name?.trim() ||
        `AetherRide ${new Date().toISOString().slice(0, 10)}`,
      type: body.type || "Ride",
      sport_type: body.sport_type || "MountainBikeRide",
      start_date_local:
        body.start_date_local || new Date().toISOString(),
      elapsed_time: Math.round(elapsed),
      distance: Number(body.distance) || 0,
      total_elevation_gain: Number(body.total_elevation_gain) || 0,
      description:
        (body.description?.trim() || "Hochgeladen aus AetherRide") +
        (trkpts < 2
          ? " (nur Metadaten — kein GPS-Track in der App)."
          : ""),
    };

    const stravaRes = await fetch(
      "https://www.strava.com/api/v3/activities",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${access}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      }
    );

    const text = await stravaRes.text();
    let json: unknown = null;
    try {
      json = JSON.parse(text);
    } catch {
      json = { raw: text };
    }

    if (!stravaRes.ok) {
      return NextResponse.json(
        {
          error: "strava_api",
          status: stravaRes.status,
          detail: json,
        },
        { status: 502 }
      );
    }

    return NextResponse.json({
      ok: true,
      mode: "metadata",
      activity: json,
      warning:
        trkpts < 2
          ? "Nur Metadaten — kein GPX-Track mitgesendet."
          : undefined,
    });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "upload failed" },
      { status: 500 }
    );
  }
}
