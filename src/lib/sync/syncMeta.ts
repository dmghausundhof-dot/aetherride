/** Gemeinsame Sync-Meta-Keys (vermeidet Zyklen opsLog ↔ syncStatus) */

export const LAST_FLUSH_KEY = "aetherride.sync.lastFlushAt";
export const CURSOR_KEY = "aetherride.sync.cursor";

export function bumpServerRevisionCursor(): string {
  const next = `rev_demo_${Date.now().toString(36)}`;
  if (typeof window !== "undefined") {
    localStorage.setItem(CURSOR_KEY, next);
  } else {
    memoryCursor = next;
  }
  return next;
}

export function setLastFlushAt(iso: string) {
  if (typeof window === "undefined") {
    memoryFlush = iso;
    return;
  }
  localStorage.setItem(LAST_FLUSH_KEY, iso);
}

export function getLastFlushAt(): string | null {
  if (typeof window === "undefined") return memoryFlush;
  try {
    return localStorage.getItem(LAST_FLUSH_KEY);
  } catch {
    return null;
  }
}

export function getServerRevisionCursor(): string | null {
  if (typeof window === "undefined") return memoryCursor;
  try {
    return localStorage.getItem(CURSOR_KEY);
  } catch {
    return null;
  }
}

let memoryCursor: string | null = null;
let memoryFlush: string | null = null;
