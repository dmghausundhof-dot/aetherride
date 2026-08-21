import type { RideTelemetry } from "./rideTelemetry";

/** Kurze Zeile für Peek/Slab — nur was der Track wirklich trägt. */
export function terrainCaption(
  telemetry: RideTelemetry,
  hm: string
): string | undefined {
  if (!telemetry.channels.elev) return undefined;
  const parts = [`${telemetry.climbM} ${hm}`];
  if (telemetry.descentM > 0) parts.push(`${telemetry.descentM} ${hm} ↓`);
  if (telemetry.maxGradePct != null) {
    const g = telemetry.maxGradePct;
    parts.push(`${g > 0 ? "+" : ""}${g.toFixed(0)} %`);
  }
  return parts.join(" · ");
}
