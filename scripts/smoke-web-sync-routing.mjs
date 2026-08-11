#!/usr/bin/env node
/**
 * Smoke: Routing, Tour-Geometrie, Geocode, Sync-Auth, Health.
 * Usage: node scripts/smoke-web-sync-routing.mjs [baseUrl]
 * Exit 0 = alle kritischen Checks grün (Sync 401 ohne Login ist OK).
 */
const base = (process.argv[2] || "http://127.0.0.1:3000").replace(/\/$/, "");

const results = [];

async function check(name, fn) {
  const t0 = Date.now();
  try {
    const detail = await fn();
    results.push({ name, ok: true, ms: Date.now() - t0, detail });
    console.log(`OK  ${name} (${Date.now() - t0}ms)`, detail ?? "");
  } catch (e) {
    results.push({
      name,
      ok: false,
      ms: Date.now() - t0,
      detail: e instanceof Error ? e.message : String(e),
    });
    console.error(`FAIL ${name}:`, e instanceof Error ? e.message : e);
  }
}

await check("health", async () => {
  const r = await fetch(`${base}/api/health`);
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return await r.json().catch(() => r.status);
});

await check("routing/status?probe=1", async () => {
  const r = await fetch(`${base}/api/routing/status?probe=1`);
  const j = await r.json();
  if (!r.ok) throw new Error(JSON.stringify(j));
  return {
    engine: j.engine,
    configured: j.configured,
    liveVerified: j.liveVerified,
    probe: j.probe,
  };
});

await check("tours/geometry (heidelberg)", async () => {
  const r = await fetch(
    `${base}/api/tours/geometry?id=${encodeURIComponent("r-heidelberg-city")}`
  );
  const j = await r.json();
  if (!r.ok) throw new Error(JSON.stringify(j).slice(0, 200));
  const n = j.geometry?.coordinates?.length ?? 0;
  if (n < 2) throw new Error("no geometry");
  return { engine: j.engine, pts: n, km: (j.distanceM / 1000).toFixed(1) };
});

await check("tours/geometry near GPS", async () => {
  const r = await fetch(
    `${base}/api/tours/geometry?lat=48.0&lng=7.85&profile=road&mode=loop&distanceKm=20`
  );
  const j = await r.json();
  if (!r.ok) throw new Error(JSON.stringify(j).slice(0, 200));
  const n = j.geometry?.coordinates?.length ?? 0;
  if (n < 2) throw new Error("no near geometry");
  return { engine: j.engine, pts: n, shape: j.shape };
});

await check("geocode Freiburg", async () => {
  const r = await fetch(`${base}/api/geocode?q=${encodeURIComponent("Freiburg")}`);
  const j = await r.json();
  if (!r.ok) throw new Error(JSON.stringify(j).slice(0, 200));
  const hits = j.hits ?? [];
  if (!hits.length) throw new Error("no hits");
  return { n: hits.length, first: hits[0]?.label?.slice(0, 40) };
});

await check("osm-routes near Freiburg", async () => {
  const r = await fetch(`${base}/api/osm-routes?lat=47.99&lon=7.85&radiusKm=15`);
  const j = await r.json();
  if (!r.ok) throw new Error(JSON.stringify(j).slice(0, 200));
  return { n: (j.routes ?? []).length, warning: j.warning };
});

await check("sync without auth (401 or 503)", async () => {
  const r = await fetch(`${base}/api/sync`);
  // 401 = login needed; 503 = Supabase env missing locally
  if (r.status !== 401 && r.status !== 503) {
    throw new Error(`expected 401|503, got ${r.status}`);
  }
  const j = await r.json().catch(() => ({}));
  return { status: r.status, error: j.error };
});

await check("sitemap", async () => {
  const r = await fetch(`${base}/sitemap.xml`);
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  const t = await r.text();
  if (!t.includes("tours/")) throw new Error("no tours in sitemap");
  return { bytes: t.length };
});

await check("ops/env-check", async () => {
  const r = await fetch(`${base}/api/ops/env-check`);
  const j = await r.json();
  if (!r.ok) throw new Error(JSON.stringify(j).slice(0, 200));
  return {
    ok: j.ok,
    engine: j.checks?.routing?.engine,
    supabase: j.checks?.supabasePublic,
    stores: j.checks?.stores?.hasLinks,
  };
});

await check("well-known assetlinks", async () => {
  const r = await fetch(`${base}/.well-known/assetlinks.json`);
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  const j = await r.json();
  if (!Array.isArray(j) || !j[0]?.target?.package_name) {
    throw new Error("invalid assetlinks");
  }
  return { package: j[0].target.package_name };
});

await check("well-known apple-app-site-association", async () => {
  const r = await fetch(`${base}/.well-known/apple-app-site-association`);
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  const j = await r.json();
  if (!j.applinks?.details?.length) throw new Error("no applinks details");
  return { apps: j.applinks.details.length };
});

const failed = results.filter((x) => !x.ok);
console.log("\n---");
console.log(
  failed.length
    ? `SMOKE FAIL ${failed.length}/${results.length}`
    : `SMOKE OK ${results.length}/${results.length}`
);
process.exit(failed.length ? 1 : 0);
