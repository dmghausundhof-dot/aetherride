/**
 * Garage → Teileshop Kompatibilität.
 *
 * Nur Felder, die Bike und Produkt wirklich haben:
 * Kategorie/Disziplin, Laufradgröße, E-Bike vs. analog, Schaltungsfamilie.
 * Keine erfundenen OEM-SKUs (kein Bosch-Teilenummern-Raten).
 *
 * Ohne Produkt-Constraint → universal (sichtbar, kein „passt zu …“-Claim).
 * Mehrere Garage-Bikes → Vereinigung (Teil passt zu mindestens einem Rad).
 */

import { bikeCategoryLabel } from "@/lib/catalog/slots";
import type { Bike, BikeCategory, ComponentModel, WheelSize } from "@/types";
import {
  parseSoftFitTags,
  softFitContextFromBike,
  softFitVerdict,
  type SoftFitContext,
  type SoftFitTags,
  type SoftFitVerdict,
} from "@/lib/shop/softFit";

export type SportFamily = "mtb" | "gravel" | "road" | "urban";
export type WheelNorm = "29" | "27.5" | "700c" | "650b";
export type EbikeMode = "any" | "only" | "no";
export type GarageFitKind = "match" | "universal" | "mismatch";

export type GarageBikeProfile = {
  id: string;
  name: string;
  brand?: string;
  model?: string;
  category: BikeCategory;
  categoryLabel: string;
  wheelSizes: WheelNorm[];
  isEbike: boolean;
  drivetrain: string[];
  families: SportFamily[];
};

export type GarageFitConstraint = {
  families: SportFamily[];
  wheelSizes: WheelNorm[];
  ebike: EbikeMode;
  drivetrain: string[];
};

export type GarageFitResult = {
  kind: GarageFitKind;
  compatible: boolean;
  matchedBikes: GarageBikeProfile[];
  /** z. B. "passt zu Canyon Grizl · 700c · Gravel" — nie bei universal */
  label: string | null;
};

const DRIVETRAIN_SLOTS = new Set([
  "cassette",
  "chain",
  "crankset",
  "chainring",
  "rear_derailleur",
  "shifter",
  "front_derailleur",
]);

const EBIKE_SLOTS = new Set(["motor", "battery", "display"]);

const FAMILY_ALIASES: Record<string, SportFamily> = {
  mtb: "mtb",
  mountainbike: "mtb",
  mountain: "mtb",
  trail: "mtb",
  enduro: "mtb",
  downhill: "mtb",
  dh: "mtb",
  am: "mtb",
  allmountain: "mtb",
  mtb_trail: "mtb",
  mtb_am: "mtb",
  mtb_enduro: "mtb",
  emtb: "mtb",
  gravel: "gravel",
  road: "road",
  rennrad: "road",
  race: "road",
  urban: "urban",
  city: "urban",
  trekking: "urban",
  etrekking: "urban",
  commuter: "urban",
  cargo: "urban",
  folding: "urban",
  kids: "urban",
};

export function isRideableGarageBike(category: BikeCategory): boolean {
  return category !== "hiking";
}

export function familiesFromBike(
  category: BikeCategory,
  isEbike: boolean
): SportFamily[] {
  const out = new Set<SportFamily>();
  switch (category) {
    case "mtb_trail":
    case "mtb_am":
    case "mtb_enduro":
    case "dh":
    case "emtb":
      out.add("mtb");
      break;
    case "gravel":
      out.add("gravel");
      break;
    case "road":
      out.add("road");
      break;
    case "urban":
    case "etrekking":
    case "cargo":
    case "folding":
    case "kids":
      out.add("urban");
      break;
    case "hiking":
      break;
  }
  if (isEbike && category === "gravel") out.add("gravel");
  return [...out];
}

export function normalizeWheel(
  raw: string | WheelSize | null | undefined
): WheelNorm | undefined {
  if (!raw) return undefined;
  const t = String(raw)
    .trim()
    .toLowerCase()
    .replace(/['"zoll]/g, "")
    .replace(/,/g, ".")
    .replace(/\s+/g, "");
  if (t === "29" || t === "29er" || t === "29x" || t === "29er") return "29";
  if (
    t === "27_5" ||
    t === "27.5" ||
    t === "275" ||
    t === "27.5er" ||
    t === "650b" ||
    t === "650"
  ) {
    if (t === "650b" || t === "650") return "650b";
    return "27.5";
  }
  if (t === "700c" || t === "700" || t === "28-622") return "700c";
  return undefined;
}

export function wheelLabel(w: WheelNorm): string {
  switch (w) {
    case "29":
      return "29\"";
    case "27.5":
      return "27.5\"";
    case "650b":
      return "650b";
    case "700c":
      return "700c";
  }
}

/** 27.5" und 650b sind dasselbe ISO-584-Maß. 29" ≠ 700c (Reifen/Einsatz). */
function wheelTokensMatch(product: WheelNorm[], bike: WheelNorm[]): boolean {
  if (product.length === 0 || bike.length === 0) return true;
  const expand = (w: WheelNorm): WheelNorm[] =>
    w === "27.5" || w === "650b" ? ["27.5", "650b"] : [w];
  const bikeSet = new Set(bike.flatMap(expand));
  return product.some((p) => expand(p).some((x) => bikeSet.has(x)));
}

export function inferDrivetrainTokens(
  manufacturer: string,
  model: string
): string[] {
  const blob = `${manufacturer} ${model}`.toLowerCase();
  const out: string[] = [];
  if (/shimano|deore|xt|xtr|slx|ultegra|dura-ace|\b105\b|grx|cues/.test(blob)) {
    out.push("shimano");
  }
  if (/sram|eagle|gx|xx|x0|force|rival|\bred\b/.test(blob)) {
    out.push("sram");
  }
  if (/rohloff/.test(blob)) out.push("rohloff");
  if (/enviolo|nuvinci/.test(blob)) out.push("enviolo");
  if (/campagnolo|chorus|record|super record|ekar/.test(blob)) {
    out.push("campagnolo");
  }
  return out;
}

function unique<T>(items: T[]): T[] {
  return [...new Set(items)];
}

export function profileFromBike(
  bike: Bike,
  resolveModel?: (id: string) => ComponentModel | undefined
): GarageBikeProfile | null {
  if (!isRideableGarageBike(bike.category)) return null;

  const isEbike =
    bike.isEbike || bike.category === "emtb" || bike.category === "etrekking";

  const wheels = unique(
    [
      normalizeWheel(bike.wheelSizeFront),
      normalizeWheel(bike.wheelSizeRear),
    ].filter((w): w is WheelNorm => Boolean(w))
  );

  const drivetrain = new Set<string>();
  for (const c of bike.components) {
    if (c.removedAt || !DRIVETRAIN_SLOTS.has(c.slot)) continue;
    const resolved = c.componentModelId
      ? resolveModel?.(c.componentModelId)
      : undefined;
    const mfr = resolved?.manufacturer ?? c.manufacturer ?? "";
    const mdl = resolved?.model ?? c.model ?? c.freeText ?? "";
    for (const t of inferDrivetrainTokens(mfr, mdl)) drivetrain.add(t);
  }

  return {
    id: bike.id,
    name: bike.name,
    category: bike.category,
    categoryLabel: bikeCategoryLabel(bike.category),
    wheelSizes: wheels,
    isEbike,
    drivetrain: [...drivetrain],
    families: familiesFromBike(bike.category, isEbike),
  };
}

export function profilesFromGarage(
  bikes: Bike[],
  resolveModel?: (id: string) => ComponentModel | undefined
): GarageBikeProfile[] {
  return bikes
    .map((b) => profileFromBike(b, resolveModel))
    .filter((p): p is GarageBikeProfile => p != null);
}

function parseFamilyToken(raw: string): SportFamily | undefined {
  const key = raw
    .trim()
    .toLowerCase()
    .replace(/-/g, "")
    .replace(/\s+/g, "");
  return FAMILY_ALIASES[key];
}

function parseTaggedFamilies(tags: string[]): SportFamily[] {
  const out = new Set<SportFamily>();
  for (const raw of tags) {
    const tag = raw.trim();
    const m =
      /^(?:category|cat|sport|discipline|fit):(.+)$/i.exec(tag) ??
      /^bike_type:(.+)$/i.exec(tag);
    if (!m) continue;
    const fam = parseFamilyToken(m[1]);
    if (fam) out.add(fam);
  }
  return [...out];
}

function parseTaggedWheels(tags: string[]): WheelNorm[] {
  const out = new Set<WheelNorm>();
  for (const raw of tags) {
    const m = /^(?:wheel|wheel_size|laufrad|iso):(.+)$/i.exec(raw.trim());
    if (!m) continue;
    const w = normalizeWheel(m[1]);
    if (w) out.add(w);
  }
  return [...out];
}

function parseTaggedEbike(tags: string[]): EbikeMode | undefined {
  let mode: EbikeMode | undefined;
  for (const raw of tags) {
    const tag = raw.trim().toLowerCase();
    if (tag === "analog" || tag === "muskel" || tag === "acoustic") {
      mode = "no";
      continue;
    }
    const m = /^(?:ebike|e-bike|e_bike)(?::(.+))?$/.exec(tag);
    if (!m) continue;
    const val = (m[1] || "yes").toLowerCase();
    if (val === "no" || val === "false" || val === "analog") mode = "no";
    else if (val === "only" || val === "exclusive") mode = "only";
    else mode = mode === "no" ? "no" : "any";
  }
  return mode;
}

function parseTaggedDrivetrain(tags: string[]): string[] {
  const out = new Set<string>();
  for (const raw of tags) {
    const m = /^(?:drivetrain|groupset|shift_compat):(.+)$/i.exec(raw.trim());
    if (!m) continue;
    const token = m[1].trim().toLowerCase();
    if (token) out.add(token);
  }
  return [...out];
}

function inferFamiliesFromText(blob: string): SportFamily[] {
  const out = new Set<SportFamily>();
  if (/\bgravel\b/.test(blob)) out.add("gravel");
  if (/\brennrad\b|\broad(?:bike|ie)?\b|\bcyclocross\b|\bcx\b/.test(blob)) {
    out.add("road");
  }
  if (
    /\b(?:e-?)?mtb\b|\bmountain\s*bike\b|\benduro\b|\bdownhill\b|\btrail\s*bike\b/.test(
      blob
    )
  ) {
    out.add("mtb");
  }
  if (/\bcity\b|\burban\b|\btrekking\b|\bcommuter\b|\btouring\b/.test(blob)) {
    out.add("urban");
  }
  return [...out];
}

function inferWheelsFromText(blob: string): WheelNorm[] {
  const out = new Set<WheelNorm>();
  if (/\b29\s*[x×]\s*\d/i.test(blob) || /\b29er\b/i.test(blob)) out.add("29");
  if (/\b27[.,]5\s*[x×]/i.test(blob) || /\b27[.,]5\s*(?:zoll|")/i.test(blob)) {
    out.add("27.5");
  }
  if (/\b650b\b/i.test(blob) || /\b\d{2}-584\b/.test(blob)) out.add("650b");
  if (/\b700c\b/i.test(blob) || /\b\d{2}-622\b/.test(blob)) out.add("700c");
  return [...out];
}

function inferEbikeFromText(
  blob: string,
  slotKey: string,
  productType: string
): EbikeMode | undefined {
  const type = `${slotKey} ${productType}`.toLowerCase();
  if (
    EBIKE_SLOTS.has(slotKey) ||
    /\b(akku|battery|motor|display|antriebseinheit)\b/.test(type)
  ) {
    return "only";
  }
  if (/nur\s+(?:für\s+)?e-?bikes?|e-?bike\s*only|ebike:only/.test(blob)) {
    return "only";
  }
  if (/\banalog\b|\bmuskel\b/.test(blob) && !/\be-?bike\b/.test(blob)) {
    return "no";
  }
  return undefined;
}

export function parseGarageFitConstraint(input: {
  tags?: string[];
  title?: string;
  productType?: string;
  slotKey?: string;
  description?: string;
}): GarageFitConstraint {
  const tags = input.tags ?? [];
  const slotKey = (input.slotKey ?? "").toLowerCase();
  const blob = [input.title, input.productType, input.description, tags.join(" ")]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();

  const taggedFamilies = parseTaggedFamilies(tags);
  const taggedWheels = parseTaggedWheels(tags);
  const taggedEbike = parseTaggedEbike(tags);
  const taggedDrive = parseTaggedDrivetrain(tags);

  const families =
    taggedFamilies.length > 0 ? taggedFamilies : inferFamiliesFromText(blob);
  const wheelSizes =
    taggedWheels.length > 0 ? taggedWheels : inferWheelsFromText(blob);
  const ebike =
    taggedEbike ?? inferEbikeFromText(blob, slotKey, input.productType ?? "") ?? "any";
  const drivetrain =
    taggedDrive.length > 0
      ? taggedDrive
      : inferDrivetrainTokens(input.title ?? "", input.productType ?? "");

  return { families, wheelSizes, ebike, drivetrain };
}

export function hasGarageFitConstraint(c: GarageFitConstraint): boolean {
  return (
    c.families.length > 0 ||
    c.wheelSizes.length > 0 ||
    c.ebike !== "any" ||
    c.drivetrain.length > 0
  );
}

export function bikeMatchesConstraint(
  bike: GarageBikeProfile,
  constraint: GarageFitConstraint
): boolean {
  if (constraint.ebike === "only" && !bike.isEbike) return false;
  if (constraint.ebike === "no" && bike.isEbike) return false;

  if (constraint.families.length > 0) {
    if (bike.families.length === 0) return false;
    const hit = constraint.families.some((f) => bike.families.includes(f));
    if (!hit) return false;
  }

  if (!wheelTokensMatch(constraint.wheelSizes, bike.wheelSizes)) return false;

  if (constraint.drivetrain.length > 0 && bike.drivetrain.length > 0) {
    const hit = constraint.drivetrain.some((d) => bike.drivetrain.includes(d));
    if (!hit) return false;
  }

  return true;
}

function displayName(bike: GarageBikeProfile): string {
  if (bike.brand && bike.model) return `${bike.brand} ${bike.model}`;
  return bike.name;
}

export function formatGarageFitLabel(bikes: GarageBikeProfile[]): string | null {
  if (bikes.length === 0) return null;
  if (bikes.length === 1) {
    const b = bikes[0];
    const parts = [displayName(b)];
    if (b.wheelSizes[0]) parts.push(wheelLabel(b.wheelSizes[0]));
    if (b.categoryLabel) parts.push(b.categoryLabel);
    return `passt zu ${parts.join(" · ")}`;
  }
  if (bikes.length === 2) {
    return `passt zu ${displayName(bikes[0])} und ${displayName(bikes[1])}`;
  }
  return `passt zu ${displayName(bikes[0])} und ${bikes.length - 1} weiteren`;
}

export function matchGarageFit(
  constraint: GarageFitConstraint,
  bikes: GarageBikeProfile[],
  selectedBikeId?: string | null
): GarageFitResult {
  const pool =
    selectedBikeId && selectedBikeId !== "all"
      ? bikes.filter((b) => b.id === selectedBikeId)
      : bikes;
  const usable = pool.filter((b) => b.families.length > 0);

  if (usable.length === 0) {
    return {
      kind: "universal",
      compatible: true,
      matchedBikes: [],
      label: null,
    };
  }

  if (!hasGarageFitConstraint(constraint)) {
    return {
      kind: "universal",
      compatible: true,
      matchedBikes: usable,
      label: null,
    };
  }

  const matched = usable.filter((b) => bikeMatchesConstraint(b, constraint));
  if (matched.length === 0) {
    return {
      kind: "mismatch",
      compatible: false,
      matchedBikes: [],
      label: null,
    };
  }
  return {
    kind: "match",
    compatible: true,
    matchedBikes: matched,
    label: formatGarageFitLabel(matched),
  };
}

export type GarageFitBikeInput = {
  profile: GarageBikeProfile;
  softCtx: SoftFitContext;
};

export function softFitInputsFromBikes(
  bikes: Bike[],
  resolveModel?: (id: string) => ComponentModel | undefined
): GarageFitBikeInput[] {
  const out: GarageFitBikeInput[] = [];
  for (const bike of bikes) {
    const profile = profileFromBike(bike, resolveModel);
    if (!profile) continue;
    out.push({
      profile,
      softCtx: softFitContextFromBike(bike, resolveModel),
    });
  }
  return out;
}

export function evaluatePartAgainstGarage(opts: {
  tags: string[];
  title: string;
  productType: string;
  slotKey?: string;
  description?: string;
  softFit?: SoftFitTags;
  bikes: GarageFitBikeInput[];
  selectedBikeId?: string | null;
  fitMode: "bike" | "all";
}): {
  garage: GarageFitResult;
  verdict: SoftFitVerdict;
  visible: boolean;
} {
  const constraint = parseGarageFitConstraint({
    tags: opts.tags,
    title: opts.title,
    productType: opts.productType,
    slotKey: opts.slotKey,
    description: opts.description,
  });
  const pool =
    opts.selectedBikeId && opts.selectedBikeId !== "all"
      ? opts.bikes.filter((b) => b.profile.id === opts.selectedBikeId)
      : opts.bikes;

  const softTags = opts.softFit ?? parseSoftFitTags(opts.tags);

  if (pool.length === 0) {
    const garage = matchGarageFit(constraint, [], null);
    return {
      garage,
      verdict: "universal",
      visible: true,
    };
  }

  const matchingInputs = pool.filter((b) => {
    if (!bikeMatchesConstraint(b.profile, constraint) && hasGarageFitConstraint(constraint)) {
      return false;
    }
    return softFitVerdict(softTags, b.softCtx) !== "pruefen";
  });

  const garage = matchGarageFit(
    constraint,
    pool.map((b) => b.profile),
    opts.selectedBikeId
  );

  let verdict: SoftFitVerdict = "universal";
  if (matchingInputs.length === 1) {
    verdict = softFitVerdict(softTags, matchingInputs[0].softCtx);
  } else if (matchingInputs.length > 1) {
    const vs = matchingInputs.map((b) => softFitVerdict(softTags, b.softCtx));
    if (vs.includes("passt")) verdict = "passt";
    else if (vs.every((v) => v === "universal")) verdict = "universal";
    else verdict = "passt";
  } else if (pool.length === 1) {
    verdict = softFitVerdict(softTags, pool[0].softCtx);
  }

  const visible =
    opts.fitMode === "all" || matchingInputs.length > 0 || pool.length === 0;

  const labelBikes = matchingInputs.map((b) => b.profile);
  const labeled: GarageFitResult =
    garage.kind === "match" || (matchingInputs.length > 0 && verdict === "passt")
      ? {
          kind: matchingInputs.length > 0 && hasGarageFitConstraint(constraint)
            ? "match"
            : verdict === "passt"
              ? "match"
              : garage.kind,
          compatible: matchingInputs.length > 0,
          matchedBikes: labelBikes,
          label:
            garage.label ??
            (verdict === "passt" ? formatGarageFitLabel(labelBikes) : null),
        }
      : garage;

  return { garage: labeled, verdict, visible };
}
