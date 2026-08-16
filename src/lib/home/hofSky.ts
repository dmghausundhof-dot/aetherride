import { HOF_COPY, type HofCopy } from "./hofCopy";

export type HofTrailHint = "wet_likely" | "damp_possible" | "dry_likely";

export function hofSkyLine(
  trailHint: string | null | undefined,
  tempC: number | null | undefined,
  copy: Pick<HofCopy, "skyUnknown" | "skyWet" | "skyDamp" | "skyDry"> = HOF_COPY
): string {
  if (tempC == null || !Number.isFinite(tempC)) return copy.skyUnknown;
  const temp = String(Math.round(tempC));
  if (trailHint === "wet_likely") return copy.skyWet(temp);
  if (trailHint === "damp_possible") return copy.skyDamp(temp);
  return copy.skyDry(temp);
}

export function isSkyWet(trailHint: string | null | undefined): boolean {
  return trailHint === "wet_likely";
}
