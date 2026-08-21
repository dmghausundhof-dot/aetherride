/** Zustand-Tags an einer Stimme. Unbekannte Werte fallen weg. */

/** Rider condition pills — wet / closed / busy. top/works are not conditions. */
export const STIMME_FORM_TAG_WIRES = ["nass", "zu", "viel_los"] as const;

/** Stored wires still parse historical top/works so old Stimmen stay readable. */
export const STIMME_TAG_WIRES = [
  ...STIMME_FORM_TAG_WIRES,
  "top",
  "baustelle",
] as const;

export type StimmeTagWire = (typeof STIMME_TAG_WIRES)[number];

const ALLOW = new Set<string>(STIMME_TAG_WIRES);
const MAX = 3;

export function parseStimmeTags(raw: unknown): StimmeTagWire[] {
  if (!Array.isArray(raw)) return [];
  const out: StimmeTagWire[] = [];
  const seen = new Set<string>();
  for (const e of raw) {
    const t = String(e ?? "")
      .trim()
      .toLowerCase()
      .replace(/\s+/g, "_");
    if (!ALLOW.has(t) || seen.has(t)) continue;
    seen.add(t);
    out.push(t as StimmeTagWire);
    if (out.length >= MAX) break;
  }
  return out;
}
