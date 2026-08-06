/** Gemeinsame Sync-Meta-Keys (vermeidet Zyklen opsLog ↔ syncStatus) */

export const LAST_FLUSH_KEY = "aetherride.sync.lastFlushAt";
export const CURSOR_KEY = "aetherride.sync.cursor";
export const CONFLICTS_KEY = "aetherride.sync.lastConflicts";
export const PULLED_KEY = "aetherride.sync.lastPulledCount";

export function bumpServerRevisionCursor(): string {
  const next = `rev_demo_${Date.now().toString(36)}`;
  setServerRevisionCursor(next);
  return next;
}

export function setLastFlushAt(iso: string) {
  if (typeof window === "undefined") {
    memoryFlush = iso;
    return;
  }
  localStorage.setItem(LAST_FLUSH_KEY, iso);
}

/** Alias — Client-Flush nutzt denselben Cursor wie Server-Ack */
export function setLastSyncAt(iso: string) {
  setLastFlushAt(iso);
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

export function setServerRevisionCursor(revision: string) {
  if (typeof window === "undefined") {
    memoryCursor = revision;
    return;
  }
  localStorage.setItem(CURSOR_KEY, revision);
}

export function markConflicts(count: number) {
  if (typeof window === "undefined") {
    memoryConflicts = count;
    return;
  }
  localStorage.setItem(CONFLICTS_KEY, String(count));
}

export function getLastConflictCount(): number {
  if (typeof window === "undefined") return memoryConflicts;
  try {
    return Number(localStorage.getItem(CONFLICTS_KEY) || "0") || 0;
  } catch {
    return 0;
  }
}

export function setPulledCount(count: number) {
  if (typeof window === "undefined") {
    memoryPulled = count;
    return;
  }
  localStorage.setItem(PULLED_KEY, String(count));
}

export function getPulledServerOps(): number {
  if (typeof window === "undefined") return memoryPulled;
  try {
    return Number(localStorage.getItem(PULLED_KEY) || "0") || 0;
  } catch {
    return 0;
  }
}

let memoryCursor: string | null = null;
let memoryFlush: string | null = null;
let memoryConflicts = 0;
let memoryPulled = 0;
