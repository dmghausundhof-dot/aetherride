import { NextResponse } from "next/server";

/**
 * Open-Meteo weather proxy for ride planning / trail wetness heuristic (S6).
 * GET /api/weather?lat=&lon=
 */
export async function GET(req: Request) {
  const url = new URL(req.url);
  const lat = url.searchParams.get("lat");
  const lon = url.searchParams.get("lon") || url.searchParams.get("lng");
  if (!lat || !lon) {
    return NextResponse.json({ error: "lat,lon required" }, { status: 400 });
  }

  const api = new URL("https://api.open-meteo.com/v1/forecast");
  api.searchParams.set("latitude", lat);
  api.searchParams.set("longitude", lon);
  api.searchParams.set(
    "current",
    "temperature_2m,precipitation,weather_code,wind_speed_10m"
  );
  api.searchParams.set(
    "daily",
    "precipitation_sum,precipitation_probability_max"
  );
  api.searchParams.set("forecast_days", "3");
  api.searchParams.set("timezone", "auto");

  const res = await fetch(api.toString(), { next: { revalidate: 1800 } });
  if (!res.ok) {
    return NextResponse.json(
      { error: `open-meteo ${res.status}` },
      { status: 502 }
    );
  }
  const data = await res.json();
  const precip =
    data?.current?.precipitation ??
    data?.daily?.precipitation_sum?.[0] ??
    0;
  const trailHint =
    precip >= 5
      ? "wet_likely"
      : precip >= 1
        ? "damp_possible"
        : "dry_likely";

  return NextResponse.json({
    provider: "open-meteo",
    lat: Number(lat),
    lon: Number(lon),
    current: data.current,
    daily: data.daily,
    trailHint,
    attribution: "Weather data by Open-Meteo.com",
  });
}
