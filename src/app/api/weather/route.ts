import { NextResponse } from "next/server";
import { chromeLangFrom } from "@/lib/i18n/chromeLang";
import { fetchOpenMeteoWeather } from "@/lib/weather/openMeteoWeather";

/**
 * GET /api/weather?lat=&lon=&profile=&lang=
 * Open-Meteo: current + 72h hourly soil reservoir → trailHint
 * (dry_likely | damp_possible | wet_likely). Optional precip72hMm /
 * trailHintSource / rideWindow for Numeric-Guard — not shown on the
 * Hof sky line. rideWindow only for Gravel/MTB.
 */
export async function GET(req: Request) {
  const url = new URL(req.url);
  const lat = Number(url.searchParams.get("lat"));
  const lon = Number(
    url.searchParams.get("lon") || url.searchParams.get("lng")
  );
  if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
    return NextResponse.json({ error: "lat,lon required" }, { status: 400 });
  }
  const profile = url.searchParams.get("profile");
  const lang = chromeLangFrom(url.searchParams.get("lang"));

  try {
    const payload = await fetchOpenMeteoWeather({
      lat,
      lon,
      profile,
      lang,
    });
    return NextResponse.json(payload);
  } catch (e) {
    return NextResponse.json(
      {
        error: e instanceof Error ? e.message : "open-meteo failed",
      },
      { status: 502 }
    );
  }
}
