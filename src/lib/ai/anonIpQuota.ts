/**
 * Soft rate-limit for anonymous chat (deterministic fallback only).
 * In-memory — resets on cold start; enough to curb abuse on a single instance.
 */

type Bucket = { day: string; count: number };

const buckets = new Map<string, Bucket>();

function todayUtc(): string {
  return new Date().toISOString().slice(0, 10);
}

export function clientIpFromRequest(req: Request): string {
  const xf = req.headers.get("x-forwarded-for");
  if (xf) {
    const first = xf.split(",")[0]?.trim();
    if (first) return first;
  }
  const real = req.headers.get("x-real-ip")?.trim();
  if (real) return real;
  return "unknown";
}

/** Returns true if under limit after increment; false if already at/over limit. */
export function consumeAnonIpQuota(
  ip: string,
  limit = Number(process.env.CHAT_LIMIT_ANON_DAY || 5)
): { ok: boolean; used: number; limit: number } {
  const day = todayUtc();
  const key = `${ip}|${day}`;
  const cur = buckets.get(key);
  if (!cur || cur.day !== day) {
    buckets.set(key, { day, count: 1 });
    return { ok: true, used: 1, limit };
  }
  if (cur.count >= limit) {
    return { ok: false, used: cur.count, limit };
  }
  cur.count += 1;
  return { ok: true, used: cur.count, limit };
}
