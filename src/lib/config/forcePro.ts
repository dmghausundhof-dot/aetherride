/**
 * Test/Dev: Tarif dauerhaft Pro.
 * - Development: an (abschalten mit NEXT_PUBLIC_FORCE_FREE=true)
 * - Production: nur mit NEXT_PUBLIC_FORCE_PRO=true
 */
export function forcePro(): boolean {
  if (process.env.NEXT_PUBLIC_FORCE_PRO === "true") return true;
  if (process.env.NEXT_PUBLIC_FORCE_FREE === "true") return false;
  return process.env.NODE_ENV === "development";
}

export function effectiveSubscriptionTier(
  tier: "free" | "pro" | null | undefined
): "free" | "pro" {
  if (forcePro()) return "pro";
  return tier === "pro" ? "pro" : "free";
}
