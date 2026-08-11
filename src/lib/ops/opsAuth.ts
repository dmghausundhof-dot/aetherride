/**
 * Ops endpoint auth — fail-closed in production / Vercel when no secret.
 * Accepts OPS_SECRET or CRON_SECRET via Bearer or x-ops-secret.
 */

export function opsSecret(): string | null {
  const s =
    process.env.OPS_SECRET?.trim() || process.env.CRON_SECRET?.trim() || "";
  return s.length > 0 ? s : null;
}

/** True when the request may see ops JSON. */
export function authorizeOpsRequest(req: Request): boolean {
  const secret = opsSecret();
  if (secret) {
    const auth = req.headers.get("authorization");
    if (auth === `Bearer ${secret}`) return true;
    if (req.headers.get("x-ops-secret") === secret) return true;
    return false;
  }
  // No secret configured: allow only local/dev (never public Vercel/prod).
  const isProd =
    process.env.NODE_ENV === "production" || Boolean(process.env.VERCEL);
  return !isProd;
}
