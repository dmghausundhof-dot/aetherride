/**
 * Ops auth fail-closed contract.
 * Run: npx tsx src/lib/ops/opsAuth.test.ts
 */
import { authorizeOpsRequest, opsSecret } from "./opsAuth";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

const prev = {
  OPS_SECRET: process.env.OPS_SECRET,
  CRON_SECRET: process.env.CRON_SECRET,
  NODE_ENV: process.env.NODE_ENV,
  VERCEL: process.env.VERCEL,
};

function restore() {
  for (const [k, v] of Object.entries(prev)) {
    if (v === undefined) delete process.env[k];
    else process.env[k] = v;
  }
}

try {
  delete process.env.OPS_SECRET;
  delete process.env.CRON_SECRET;
  process.env.NODE_ENV = "production";
  process.env.VERCEL = "1";
  assert(opsSecret() === null, "no secret");
  assert(
    authorizeOpsRequest(new Request("https://example.com/api/ops/env-check")) ===
      false,
    "prod without secret → deny"
  );

  process.env.OPS_SECRET = "test-ops";
  assert(opsSecret() === "test-ops", "OPS_SECRET wins");
  assert(
    authorizeOpsRequest(
      new Request("https://example.com/x", {
        headers: { authorization: "Bearer test-ops" },
      })
    ) === true,
    "Bearer OK"
  );
  assert(
    authorizeOpsRequest(
      new Request("https://example.com/x", {
        headers: { "x-ops-secret": "test-ops" },
      })
    ) === true,
    "x-ops-secret OK"
  );
  assert(
    authorizeOpsRequest(new Request("https://example.com/x")) === false,
    "missing header → deny"
  );

  delete process.env.OPS_SECRET;
  delete process.env.VERCEL;
  process.env.NODE_ENV = "development";
  assert(
    authorizeOpsRequest(new Request("http://localhost/api/ops/env-check")) ===
      true,
    "local/dev without secret → allow"
  );

  console.log("opsAuth.test.ts OK");
} finally {
  restore();
}
