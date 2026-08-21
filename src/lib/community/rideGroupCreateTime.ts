/**
 * Web-Create-Sheet Zeit: eine Zeile, Tap öffnet Presets + Andere Zeit/Dauer.
 * Caps wie App/Policy: 15 Min–12 h, Start ≤14 Tage.
 */

import {
  parseRideGroupWindow,
  RIDE_GROUP_STARTS_AT_MAX_DAYS,
} from "./rideGroup";

export type CreateStartPreset = "now" | "1h" | "18" | "10" | "custom";

export function toDateTimeLocalValue(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

export function startOfLocalDay(now = new Date()): Date {
  return new Date(now.getFullYear(), now.getMonth(), now.getDate());
}

export function createStartMax(now = new Date()): Date {
  return new Date(
    now.getTime() + RIDE_GROUP_STARTS_AT_MAX_DAYS * 24 * 60 * 60 * 1000,
  );
}

export function startFromPreset(
  preset: Exclude<CreateStartPreset, "custom">,
  now = new Date(),
): Date {
  if (preset === "1h") return new Date(now.getTime() + 60 * 60 * 1000);
  if (preset === "18") {
    const today18 = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 18);
    return today18.getTime() > now.getTime()
      ? today18
      : new Date(today18.getTime() + 24 * 60 * 60 * 1000);
  }
  if (preset === "10") {
    return new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 10);
  }
  return now;
}

/** Wie App: DateTime-Picker startet bei jetzt + 1 h. */
export function defaultCustomStart(now = new Date()): Date {
  return new Date(now.getTime() + 60 * 60 * 1000);
}

export function parseCreateDurationHours(raw: string): number | null {
  const t = raw.trim().replace(",", ".");
  if (!t) return null;
  const n = Number(t);
  return Number.isFinite(n) ? n : null;
}

export function formatCreateCustomStartChip(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${pad(d.getDate())}.${pad(d.getMonth() + 1)}. ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

export function resolveCreateStart(input: {
  startPreset: CreateStartPreset;
  customStartLocal?: string;
  now?: Date;
}): Date {
  const now = input.now ?? new Date();
  if (input.startPreset !== "custom") {
    return startFromPreset(input.startPreset, now);
  }
  const raw = input.customStartLocal?.trim();
  if (raw) {
    const parsed = new Date(raw);
    if (Number.isFinite(parsed.getTime())) return parsed;
  }
  return now;
}

export function resolveCreateWindow(input: {
  startPreset: CreateStartPreset;
  customStartLocal?: string;
  durationIsCustom: boolean;
  durationH: number;
  durationCustomRaw?: string;
  now?: Date;
}): ReturnType<typeof parseRideGroupWindow> {
  const now = input.now ?? new Date();
  const start = resolveCreateStart({
    startPreset: input.startPreset,
    customStartLocal: input.customStartLocal,
    now,
  });
  const hours = input.durationIsCustom
    ? parseCreateDurationHours(input.durationCustomRaw ?? "")
    : input.durationH;
  if (hours == null) return { error: "invalid_duration" };
  return parseRideGroupWindow({
    startsAt: start.toISOString(),
    durationHours: hours,
    now,
  });
}
