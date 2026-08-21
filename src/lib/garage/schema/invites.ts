/**
 * Open schema chips: due always, at most two empty invitations.
 * Frame is the bike — not a missing part. Quiet-fit slots stay off the chips.
 * Keep in sync with mobile/lib/domain/garage/schema_invites.dart
 */

export const SCHEMA_INVITE_OPEN_MAX = 2;

const SCHEMA_INVITE_SKIP = new Set([
  "frame",
  "headset",
  "front_hub",
  "front_rim",
  "rotor_front",
]);

export function schemaInviteSkips<T>(slot: T): boolean {
  return SCHEMA_INVITE_SKIP.has(String(slot));
}

/** Anatomy stays on the silhouette — quieter than an invitation. */
export function schemaHotspotQuiet<T>(
  slot: T,
  status: "ok" | "missing" | "maintenance"
): boolean {
  return schemaInviteSkips(slot) && status === "missing";
}

function openInviteSlots<T>(input: {
  hotspotSlots: T[];
  installed: Iterable<T>;
  due?: Iterable<T>;
}): T[] {
  const installed = new Set(input.installed);
  const dueSet = new Set(input.due ?? []);
  return input.hotspotSlots.filter(
    (s) => !installed.has(s) && !dueSet.has(s) && !schemaInviteSkips(s)
  );
}

export function schemaInviteSlots<T>(input: {
  hotspotSlots: T[];
  installed: Iterable<T>;
  due?: Iterable<T>;
  maxOpen?: number;
}): T[] {
  const dueSet = new Set(input.due ?? []);
  const maxOpen = input.maxOpen ?? SCHEMA_INVITE_OPEN_MAX;
  const dueShown = input.hotspotSlots.filter((s) => dueSet.has(s));
  return [...dueShown, ...openInviteSlots(input).slice(0, maxOpen)];
}

export function schemaHiddenOpenCount<T>(input: {
  hotspotSlots: T[];
  installed: Iterable<T>;
  due?: Iterable<T>;
  maxOpen?: number;
}): number {
  const maxOpen = input.maxOpen ?? SCHEMA_INVITE_OPEN_MAX;
  return Math.max(0, openInviteSlots(input).length - maxOpen);
}
