/**
 * Trailforks integration policy (S6).
 *
 * Trailforks has strong DH/Bikepark community data but share-alike /
 * free-access constraints that conflict with Pro paywall mirroring.
 *
 * Allowed without partnership:
 * - Deep-links / attribution to trailforks.com pages
 *
 * Requires Legal + written partnership (Gate-like):
 * - Bulk trail geometry mirror
 * - Status feeds behind authenticated Pro features
 *
 * Until then this module only exposes attribution helpers.
 */

export const TRAILFORKS_ATTRIBUTION =
  "Trail data © Trailforks contributors — share-alike; not mirrored in AetherRide Pro.";

export function trailforksRegionUrl(regionId: string | number): string {
  return `https://www.trailforks.com/region/${regionId}/`;
}

export function trailforksTrailUrl(trailId: string | number): string {
  return `https://www.trailforks.com/trails/${trailId}/`;
}

export type TrailforksIntegrationMode =
  | "attribution_only"
  | "partnership_pending"
  | "enabled";

export const trailforksMode: TrailforksIntegrationMode =
  (process.env.TRAILFORKS_MODE as TrailforksIntegrationMode) ||
  "attribution_only";
