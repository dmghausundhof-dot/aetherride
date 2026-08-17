/**
 * Soft-fit Filter Contract (S-PART) — unverändert / collection-tag-basiert.
 *
 * Product tags (Shopify):
 *   slot:<key>              z. B. slot:brake_pads, slot:grips, slot:fluid, slot:chain
 *   magura_shape:7|8
 *   pad:shape-7|8
 *   caliper:mt5|mt7|mt*     (* = Wildcard)
 *   size:S|L
 *   shift_compat:<token>
 *
 * Query params (/shop/parts):
 *   slot   — browse slot (gleiche Keys wie Shop-Browse wo sinnvoll)
 *   bike   — Bike-Id (Kontext)
 *   fit    — "bike" | "all"  (bike = Soft-Fit gegen aktives Bike bevorzugen)
 *
 * Soft: Produkte ohne relevantes Soft-Fit-Tag bleiben sichtbar.
 * Strikte Inkompatibilität nur bei widersprüchlichen gesetzten Tags.
 */

import type { Bike, BikeComponent, ComponentModel, ComponentSlot } from "@/types";

export type SoftFitSize = "S" | "L";
export type MaguraShape = "7" | "8";

export type SoftFitTags = {
  /** Normalized slot keys from tags, e.g. brake_pads, grips, fluid */
  slots: string[];
  maguraShape?: MaguraShape;
  padShape?: MaguraShape;
  calipers: string[];
  size?: SoftFitSize;
  shiftCompat: string[];
  raw: string[];
};

export type SoftFitContext = {
  bikeId: string;
  bikeName: string;
  maguraShape?: MaguraShape;
  calipers: string[];
  size?: SoftFitSize;
  shiftCompat: string[];
  /** Slots present on the bike (installed) — for hints only */
  installedSlots: ComponentSlot[];
};

export type SoftFitVerdict = "passt" | "pruefen" | "universal";

const SLOT_TAG_ALIASES: Record<string, string> = {
  brake_pads: "brake_pads",
  brake_pads_front: "brake_pads",
  brake_pads_rear: "brake_pads",
  belaege: "brake_pads",
  pads: "brake_pads",
  grips: "grips",
  griffe: "grips",
  fluid: "fluid",
  brake_fluid: "fluid",
  oel: "fluid",
  chain: "chain",
  kette: "chain",
  cassette: "cassette",
  kassette: "cassette",
  tire: "tire",
  tire_front: "tire",
  tire_rear: "tire",
  reifen: "tire",
  bar_tape: "bar_tape",
  lenkerband: "bar_tape",
  rear_shock: "shock",
  shock: "shock",
  seatpost: "seatpost",
  dropper: "seatpost",
};

/** Browse chips for /shop/parts — slot filter contract */
export const PARTS_BROWSE_SLOTS: { slot: string; label: string }[] = [
  { slot: "all", label: "Alle" },
  { slot: "brake_pads", label: "Beläge" },
  { slot: "grips", label: "Griffe" },
  { slot: "fluid", label: "Fluid" },
  { slot: "chain", label: "Kette" },
  { slot: "tire", label: "Reifen" },
  { slot: "cassette", label: "Kassette" },
  { slot: "bar_tape", label: "Lenkerband" },
];

export function normalizePartsSlot(slot: string | null | undefined): string {
  if (!slot || slot === "all") return "all";
  if (slot === "brake_pads_front" || slot === "brake_pads_rear") {
    return "brake_pads";
  }
  if (slot === "tire_front" || slot === "tire_rear") return "tire";
  return SLOT_TAG_ALIASES[slot] ?? slot;
}

export function parseSoftFitTags(tags: string[]): SoftFitTags {
  const slots = new Set<string>();
  const calipers = new Set<string>();
  const shiftCompat = new Set<string>();
  let maguraShape: MaguraShape | undefined;
  let padShape: MaguraShape | undefined;
  let size: SoftFitSize | undefined;

  for (const raw of tags) {
    const tag = raw.trim();
    const lower = tag.toLowerCase();

    const slotMatch = /^slot:(.+)$/i.exec(tag);
    if (slotMatch) {
      const key = normalizePartsSlot(slotMatch[1].trim().toLowerCase());
      if (key !== "all") slots.add(key);
      continue;
    }

    const magura = /^magura_shape:([78])$/i.exec(tag);
    if (magura) {
      maguraShape = magura[1] as MaguraShape;
      continue;
    }

    const pad = /^pad:shape-([78])$/i.exec(tag);
    if (pad) {
      padShape = pad[1] as MaguraShape;
      continue;
    }

    const cal = /^caliper:(.+)$/i.exec(tag);
    if (cal) {
      calipers.add(cal[1].trim().toLowerCase());
      continue;
    }

    const sizeMatch = /^size:([sl])$/i.exec(tag);
    if (sizeMatch) {
      size = sizeMatch[1].toUpperCase() as SoftFitSize;
      continue;
    }

    const shift = /^shift_compat:(.+)$/i.exec(tag);
    if (shift) {
      shiftCompat.add(shift[1].trim().toLowerCase());
      continue;
    }

    // Heuristic fallbacks from free-form tags
    if (lower.includes("7.p") || lower === "shape-7") padShape = padShape ?? "7";
    if (lower.includes("8.p") || lower === "shape-8") padShape = padShape ?? "8";
  }

  return {
    slots: [...slots],
    maguraShape,
    padShape,
    calipers: [...calipers],
    size,
    shiftCompat: [...shiftCompat],
    raw: tags,
  };
}

/** Magura MT5/MT7/Trail → 8.P; MT2/MT4/MT6/MT8 → 7.P */
export function maguraShapeFromCaliperModel(model: string): MaguraShape | undefined {
  const m = model.toUpperCase();
  if (/8\.P/.test(m)) return "8";
  if (/7\.P/.test(m)) return "7";
  // MT5 / MT7 / MT Trail → shape 8 (before MT8 digit match)
  if (/\bMT\s*TRAIL\b/.test(m) || /\bMTTRAIL\b/.test(m)) return "8";
  if (/\bMT\s*5\b/.test(m) || /\bMT5\b/.test(m)) return "8";
  if (/\bMT\s*7\b/.test(m) || /\bMT7\b/.test(m)) return "8";
  if (/\bMT\s*[2468]\b/.test(m) || /\bMT[2468]\b/.test(m)) return "7";
  return undefined;
}

export function caliperTagFromModel(model: string): string | undefined {
  const m = model.toUpperCase().replace(/\s+/g, "");
  const match = /MT(\d+|TRAIL)/.exec(m);
  if (!match) return undefined;
  return `mt${match[1].toLowerCase()}`;
}

function shiftCompatFromModel(model: string, manufacturer: string): string[] {
  const out: string[] = [];
  const blob = `${manufacturer} ${model}`.toLowerCase();
  if (/shimano|deore|xt|xtr|slx|ultegra|105/.test(blob)) out.push("shimano");
  if (/sram|eagle|gx|xx|x0|force|rival|red/.test(blob)) out.push("sram");
  if (/rohloff/.test(blob)) out.push("rohloff");
  if (/enviolo|nuvinci/.test(blob)) out.push("enviolo");
  return out;
}

export function softFitContextFromBike(
  bike: Bike,
  resolveModel?: (id: string) => ComponentModel | undefined
): SoftFitContext {
  const active = bike.components.filter((c) => !c.removedAt);
  const calipers = new Set<string>();
  const shiftCompat = new Set<string>();
  let maguraShape: MaguraShape | undefined;
  let size: SoftFitSize | undefined;

  for (const c of active) {
    applyComponentToContext(c, resolveModel, {
      calipers,
      shiftCompat,
      setMagura: (s) => {
        maguraShape = maguraShape ?? s;
      },
      setSize: (s) => {
        size = size ?? s;
      },
    });
  }

  return {
    bikeId: bike.id,
    bikeName: bike.name,
    maguraShape,
    calipers: [...calipers],
    size,
    shiftCompat: [...shiftCompat],
    installedSlots: active.map((c) => c.slot),
  };
}

function applyComponentToContext(
  c: BikeComponent,
  resolveModel: ((id: string) => ComponentModel | undefined) | undefined,
  sink: {
    calipers: Set<string>;
    shiftCompat: Set<string>;
    setMagura: (s: MaguraShape) => void;
    setSize: (s: SoftFitSize) => void;
  }
) {
  const model = c.componentModelId
    ? resolveModel?.(c.componentModelId)
    : undefined;
  const modelName = model?.model ?? c.model ?? c.freeText ?? "";
  const manufacturer = model?.manufacturer ?? c.manufacturer ?? "";

  if (c.slot === "brake_front" || c.slot === "brake_rear") {
    const shape = maguraShapeFromCaliperModel(modelName);
    if (shape) sink.setMagura(shape);
    const cal = caliperTagFromModel(modelName);
    if (cal) sink.calipers.add(cal);
  }

  if (c.slot === "brake_pads_front" || c.slot === "brake_pads_rear") {
    const shape = maguraShapeFromCaliperModel(modelName);
    if (shape) sink.setMagura(shape);
  }

  if (c.slot === "grips") {
    const sizeAttr = model?.attributes.find((a) => a.key === "size");
    const v = (sizeAttr?.valueEnum || sizeAttr?.valueText || "").toUpperCase();
    if (v === "S" || v === "L") sink.setSize(v);
    // Ergon GP1: S often for smaller hands — leave unset if unknown
  }

  if (
    c.slot === "rear_derailleur" ||
    c.slot === "shifter" ||
    c.slot === "cassette" ||
    c.slot === "chain"
  ) {
    for (const t of shiftCompatFromModel(modelName, manufacturer)) {
      sink.shiftCompat.add(t);
    }
  }
}

function caliperMatches(productCals: string[], bikeCals: string[]): boolean | null {
  if (productCals.length === 0 || bikeCals.length === 0) return null;
  for (const pc of productCals) {
    if (pc === "mt*" || pc === "*") return true;
    if (bikeCals.includes(pc)) return true;
    // mt* wildcard prefix: caliper:mt*
    if (pc.endsWith("*")) {
      const prefix = pc.slice(0, -1);
      if (bikeCals.some((b) => b.startsWith(prefix))) return true;
    }
  }
  return false;
}

export function softFitVerdict(
  tags: SoftFitTags,
  ctx: SoftFitContext | null
): SoftFitVerdict {
  if (!ctx) return "universal";

  const productShape = tags.maguraShape ?? tags.padShape;
  let constrained = false;
  let ok = true;

  if (productShape && ctx.maguraShape) {
    constrained = true;
    if (productShape !== ctx.maguraShape) ok = false;
  }

  const cal = caliperMatches(tags.calipers, ctx.calipers);
  if (cal !== null) {
    constrained = true;
    if (!cal) ok = false;
  }

  if (tags.size && ctx.size) {
    constrained = true;
    if (tags.size !== ctx.size) ok = false;
  }

  if (tags.shiftCompat.length && ctx.shiftCompat.length) {
    constrained = true;
    const hit = tags.shiftCompat.some((s) => ctx.shiftCompat.includes(s));
    if (!hit) ok = false;
  }

  if (!constrained) return "universal";
  return ok ? "passt" : "pruefen";
}

export function productMatchesSlotFilter(
  tags: SoftFitTags,
  productType: string,
  slotFilter: string
): boolean {
  const slot = normalizePartsSlot(slotFilter);
  if (slot === "all") return true;
  if (tags.slots.includes(slot)) return true;

  const type = productType.toLowerCase();
  if (slot === "brake_pads" && /belag|pad|brake\s*pad/.test(type)) return true;
  if (slot === "grips" && /griff|grip|handlebar\s*grip/.test(type)) return true;
  if (slot === "fluid" && /fluid|öl|oil|mineral/.test(type)) return true;
  if (slot === "chain" && /kette|chain/.test(type)) return true;
  if (slot === "tire" && /reifen|tire|tyre/.test(type)) return true;
  if (slot === "cassette" && /kassette|cassette|sprocket/.test(type)) return true;
  if (slot === "bar_tape" && /band|tape|lenkerband/.test(type)) return true;

  // Title/tag heuristic when slot tag missing: look in raw tags
  const blob = tags.raw.join(" ").toLowerCase();
  if (slot === "brake_pads" && /belag|pad|7\.p|8\.p|magura_shape|pad:shape/.test(blob)) {
    return true;
  }
  if (slot === "grips" && /grip|ergon|gp1|size:[sl]/.test(blob)) return true;
  if (slot === "fluid" && /fluid|mineral|dot/.test(blob)) return true;

  // If product declares other slots explicitly, exclude; if no slot tags, keep in "all" only
  if (tags.slots.length > 0) return false;
  // Untagged products: show only under "all"
  return false;
}

export function productMatchesSoftFitFilter(
  tags: SoftFitTags,
  ctx: SoftFitContext | null,
  fitMode: "bike" | "all"
): boolean {
  if (fitMode === "all" || !ctx) return true;
  const verdict = softFitVerdict(tags, ctx);
  // Soft: hide only clear mismatches when fit=bike
  return verdict !== "pruefen";
}

export function softFitChipLabel(verdict: SoftFitVerdict, slotLabel?: string): string {
  if (verdict === "passt") {
    return slotLabel ? `passt · ${slotLabel}` : "passt";
  }
  if (verdict === "pruefen") return "prüfen";
  return slotLabel ? slotLabel : "universal";
}
