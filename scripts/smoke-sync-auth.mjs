#!/usr/bin/env node
/**
 * Sync smoke mit Login (optional).
 *
 * Env:
 *   SMOKE_BASE_URL=https://aetherride.vercel.app
 *   SMOKE_EMAIL=…
 *   SMOKE_PASSWORD=…
 *
 * Exit 0 = Login + GET/POST /api/sync ok (oder skip wenn keine Credentials).
 */
const base = (
  process.env.SMOKE_BASE_URL ||
  process.argv[2] ||
  "http://127.0.0.1:3010"
).replace(/\/$/, "");
const email = process.env.SMOKE_EMAIL || "";
const password = process.env.SMOKE_PASSWORD || "";

function log(ok, msg, extra) {
  console.log(`${ok ? "OK " : "FAIL"} ${msg}`, extra ?? "");
}

async function main() {
  // 1) env-check (ops-protected — 404 without secret is OK)
  const opsSecret = process.env.OPS_SECRET || process.env.CRON_SECRET || "";
  const envRes = await fetch(`${base}/api/ops/env-check`, {
    headers: opsSecret
      ? { Authorization: `Bearer ${opsSecret}`, Accept: "application/json" }
      : { Accept: "application/json" },
  });
  const envJ = await envRes.json().catch(() => ({}));
  if (envRes.status === 404 || envRes.status === 401) {
    log(true, "env-check protected", envRes.status);
  } else if (!envRes.ok) {
    log(false, "env-check", envRes.status);
    process.exit(1);
  } else {
    log(true, "env-check", {
      ok: envJ.ok,
      engine: envJ.checks?.routing?.engine,
      supabase: envJ.checks?.supabasePublic,
      hints: envJ.hints?.slice(0, 3),
    });
  }

  // 2) unauth sync
  const bare = await fetch(`${base}/api/sync`);
  if (bare.status !== 401 && bare.status !== 503) {
    log(false, "sync unauth", bare.status);
    process.exit(1);
  }
  log(true, "sync unauth", bare.status);

  if (!email || !password) {
    console.log(
      "\nSKIP auth sync — set SMOKE_EMAIL + SMOKE_PASSWORD for full test"
    );
    process.exit(0);
  }

  // 3) login
  const loginRes = await fetch(`${base}/api/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });
  const loginJ = await loginRes.json().catch(() => ({}));
  if (!loginRes.ok) {
    log(false, "login", loginJ.error || loginRes.status);
    process.exit(1);
  }
  // Cookie jar: Node fetch may not keep cookies; use token if returned
  const token =
    loginJ.access_token ||
    loginJ.session?.access_token ||
    loginJ.accessToken ||
    null;
  const cookie = loginRes.headers.getSetCookie?.() ?? [];
  const cookieHeader = cookie.map((c) => c.split(";")[0]).join("; ");

  const headers = { Accept: "application/json" };
  if (token) headers.Authorization = `Bearer ${token}`;
  if (cookieHeader) headers.Cookie = cookieHeader;

  // 4) GET sync
  const getRes = await fetch(`${base}/api/sync`, { headers });
  const getJ = await getRes.json().catch(() => ({}));
  if (getRes.status === 401) {
    log(
      false,
      "sync GET after login",
      "401 — Login liefert evtl. nur Cookie; Bearer prüfen"
    );
    process.exit(1);
  }
  if (!getRes.ok) {
    log(false, "sync GET", getJ.error || getRes.status);
    process.exit(1);
  }
  log(true, "sync GET", {
    hasPayload: Boolean(getJ.payload),
    updatedAt: getJ.updatedAt,
  });

  // 5) POST minimal push (merge identity only)
  const payload = {
    ...(getJ.payload && typeof getJ.payload === "object" ? getJ.payload : {}),
    payloadVersion: 2,
    updatedAt: new Date().toISOString(),
    _smoke: true,
  };
  const postRes = await fetch(`${base}/api/sync`, {
    method: "POST",
    headers: { ...headers, "Content-Type": "application/json" },
    body: JSON.stringify({
      payload,
      clientUpdatedAt: getJ.updatedAt ?? payload.updatedAt,
    }),
  });
  const postJ = await postRes.json().catch(() => ({}));
  if (postRes.status === 409) {
    log(true, "sync POST conflict (expected possible)", postJ.remoteUpdatedAt);
    process.exit(0);
  }
  if (!postRes.ok) {
    log(false, "sync POST", postJ.error || postRes.status);
    process.exit(1);
  }
  log(true, "sync POST", { updatedAt: postJ.updatedAt });
  console.log("\nSMOKE AUTH SYNC OK");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
