import { HOF_COPY } from "./hofCopy";

export type HofTrailHint = "wet_likely" | "damp_possible" | "dry_likely";

export function hofSkyLine(
  trailHint: string | null | undefined,
  tempC: number | null | undefined
): string {
  if (tempC == null || !Number.isFinite(tempC)) return HOF_COPY.skyUnknown;
  const temp = String(Math.round(tempC));
  if (trailHint === "wet_likely") return HOF_COPY.skyWet(temp);
  if (trailHint === "damp_possible") return HOF_COPY.skyDamp(temp);
  return HOF_COPY.skyDry(temp);
}

export function isSkyWet(trailHint: string | null | undefined): boolean {
  return trailHint === "wet_likely";
}
