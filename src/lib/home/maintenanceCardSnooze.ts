/**
 * Home Wartungs-Card snooze (7 days). Never blocks Nav/Entdecken.
 * Client-only localStorage — free, no Pro gate.
 */

const STORAGE_KEY = "aetherride.maintenanceCard.snoozedUntil";
export const SNOOZE_EVENT = "aetherride-maint-snooze";

export const MAINTENANCE_CARD_SNOOZE_DAYS = 7;

function emitSnoozeChange() {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new Event(SNOOZE_EVENT));
}

export function getMaintenanceCardSnoozedUntil(): number | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return null;
    const ts = Number(raw);
    return Number.isFinite(ts) ? ts : null;
  } catch {
    return null;
  }
}

export function isMaintenanceCardSnoozed(now = Date.now()): boolean {
  const until = getMaintenanceCardSnoozedUntil();
  if (until == null) return false;
  return until > now;
}

export function snoozeMaintenanceCard(
  days = MAINTENANCE_CARD_SNOOZE_DAYS,
  now = Date.now()
): number {
  const until = now + days * 24 * 60 * 60 * 1000;
  if (typeof window !== "undefined") {
    try {
      window.localStorage.setItem(STORAGE_KEY, String(until));
    } catch {
      /* private mode */
    }
    emitSnoozeChange();
  }
  return until;
}

export function clearMaintenanceCardSnooze(): void {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.removeItem(STORAGE_KEY);
  } catch {
    /* ignore */
  }
  emitSnoozeChange();
}

/** Subscribe for useSyncExternalStore */
export function subscribeMaintenanceCardSnooze(onChange: () => void): () => void {
  if (typeof window === "undefined") return () => {};
  window.addEventListener(SNOOZE_EVENT, onChange);
  window.addEventListener("storage", onChange);
  return () => {
    window.removeEventListener(SNOOZE_EVENT, onChange);
    window.removeEventListener("storage", onChange);
  };
}
