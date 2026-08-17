/**
 * Launch stage — fail-closed until an explicit launch.
 *
 * Vercel sets NODE_ENV=production on every deploy. That is not a launch.
 * Only NEXT_PUBLIC_APP_STAGE=launched opens checkout, Play-Verify, shop
 * default, and public indexing.
 *
 * Values: development | preview | launched
 */
export type AppStage = "development" | "preview" | "launched";

export const COMMERCE_CLOSED = {
  ok: false,
  error: "commerce_closed",
  message:
    "FlowLine ist im Entwicklungsstand. Es gibt kein öffentliches Angebot und keine Käufe.",
} as const;

function rawStage(): string {
  if (typeof process === "undefined") return "";
  return (
    process.env.NEXT_PUBLIC_APP_STAGE ||
    process.env.APP_STAGE ||
    ""
  )
    .trim()
    .toLowerCase();
}

export function appStage(): AppStage {
  const raw = rawStage();
  if (raw === "launched" || raw === "live") return "launched";
  if (raw === "preview" || raw === "staging") return "preview";
  return "development";
}

export function isAppLaunched(): boolean {
  return appStage() === "launched";
}

/** Stripe / Play / Marketplace — only after a real launch. */
export function isCommerceOpen(): boolean {
  return isAppLaunched();
}

/** Search engines may index only a launched public offer. */
export function isPublicIndexable(): boolean {
  return isAppLaunched();
}

export function isDevSurface(): boolean {
  return !isAppLaunched();
}
