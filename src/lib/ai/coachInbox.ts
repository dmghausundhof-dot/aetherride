/**
 * In-App-Postfach für Coach-Hinweise.
 * Snooze 7 Tage; bei geändertem Fingerprint (z. B. bald → überfällig) wieder ungelesen.
 */

import type { CoachNotice } from "@/lib/ai/coachWatch";

export const COACH_SNOOZE_DAYS = 7;

export interface CoachMeta {
  snoozedUntil?: string;
  readFingerprint?: string;
}

export interface CoachInboxItem extends CoachNotice {
  unread: boolean;
}

export function isSnoozed(meta: CoachMeta | undefined, now: Date): boolean {
  if (!meta?.snoozedUntil) return false;
  const t = Date.parse(meta.snoozedUntil);
  return Number.isFinite(t) && t > now.getTime();
}

export function mergeCoachInbox(
  notices: CoachNotice[],
  meta: Record<string, CoachMeta>,
  now = new Date()
): CoachInboxItem[] {
  const items: CoachInboxItem[] = [];
  for (const n of notices) {
    const prev = meta[n.id];
    if (isSnoozed(prev, now)) continue;
    const unread = !prev?.readFingerprint || prev.readFingerprint !== n.fingerprint;
    items.push({ ...n, unread });
  }
  return items;
}

export function snoozeMeta(
  meta: Record<string, CoachMeta>,
  notice: Pick<CoachNotice, "id" | "fingerprint">,
  days = COACH_SNOOZE_DAYS,
  now = new Date()
): Record<string, CoachMeta> {
  const until = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);
  return {
    ...meta,
    [notice.id]: {
      ...meta[notice.id],
      snoozedUntil: until.toISOString(),
      readFingerprint: notice.fingerprint,
    },
  };
}

export function markReadMeta(
  meta: Record<string, CoachMeta>,
  notices: Pick<CoachNotice, "id" | "fingerprint">[]
): Record<string, CoachMeta> {
  const next = { ...meta };
  for (const n of notices) {
    next[n.id] = {
      ...next[n.id],
      readFingerprint: n.fingerprint,
    };
  }
  return next;
}

export function unreadCoachCount(items: CoachInboxItem[]): number {
  return items.filter((i) => i.unread).length;
}

export function pruneCoachMeta(
  meta: Record<string, CoachMeta>,
  notices: CoachNotice[]
): Record<string, CoachMeta> {
  const keep = new Set(notices.map((n) => n.id));
  const next: Record<string, CoachMeta> = {};
  for (const [id, row] of Object.entries(meta)) {
    if (keep.has(id) || row.snoozedUntil) next[id] = row;
  }
  return next;
}
