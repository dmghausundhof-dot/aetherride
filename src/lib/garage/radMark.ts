/**
 * FlowLine Rad-Stand — graphic marks for Die Box, chips and slots.
 * Same 24px line language as the Touren mappe glyphs.
 */
import type { DieBoxItemId, DieBoxReadiness } from "./dieBox";
import type { BikeCategory, ComponentSlot } from "@/types/garage";
import { SCHEMA_ASSET_PATH } from "./schema/anchors";
import { planBikeSchema } from "./schema/mapper";

export const RAD_MARKS = [
  "stand",
  "box",
  "ready",
  "almost",
  "unknown",
  "pressure",
  "sag",
  "travel",
  "chain",
  "brakes",
  "lights",
  "lock",
  "rack",
  "bags",
  "battery",
  "care",
  "identity",
  "parts",
  "setup",
  "add",
  "cockpit",
  "photo",
] as const;

export type RadMarkName = (typeof RAD_MARKS)[number];

export const RAD_MARK_SRC: Record<RadMarkName, string> = {
  stand: "/garage/glyph-stand.svg",
  box: "/garage/glyph-box.svg",
  ready: "/garage/glyph-ready.svg",
  almost: "/garage/glyph-almost.svg",
  unknown: "/garage/glyph-unknown.svg",
  pressure: "/garage/glyph-pressure.svg",
  sag: "/garage/glyph-sag.svg",
  travel: "/garage/glyph-travel.svg",
  chain: "/garage/glyph-chain.svg",
  brakes: "/garage/glyph-brakes.svg",
  lights: "/garage/glyph-lights.svg",
  lock: "/garage/glyph-lock.svg",
  rack: "/garage/glyph-rack.svg",
  bags: "/garage/glyph-bags.svg",
  battery: "/garage/glyph-battery.svg",
  care: "/garage/glyph-care.svg",
  identity: "/garage/glyph-identity.svg",
  parts: "/garage/glyph-parts.svg",
  setup: "/garage/glyph-setup.svg",
  add: "/garage/glyph-add.svg",
  cockpit: "/garage/glyph-cockpit.svg",
  photo: "/garage/glyph-photo.svg",
};

export const RAD_STAND_HEADER = "/garage/header-stand.svg";
export const RAD_STAND_GROUND = "/garage/stand-ground.svg";
export const RAD_EMPTY_STAND = "/garage/empty-stand.svg";
export const RAD_EMPTY_STAND_MARK = "/garage/empty-stand-mark.svg";
export const RAD_NO_PHOTO = "/garage/no-photo.svg";

const ITEM_MARK: Record<DieBoxItemId, RadMarkName> = {
  setActive: "stand",
  pressureUnknown: "pressure",
  sagUnknown: "sag",
  travelUnknown: "travel",
  chainTeach: "chain",
  lightsMissing: "lights",
  lockMissing: "lock",
  rackMissing: "rack",
  bagsMissing: "bags",
  brakesUnknown: "brakes",
  dueCare: "care",
  pairCsc: "battery",
  parkTrail: "setup",
};

const CHIP_MARK: Record<string, RadMarkName> = {
  Licht: "lights",
  Schloss: "lock",
  Träger: "rack",
  Taschen: "bags",
  Reifen: "pressure",
  Vario: "setup",
  Bremsen: "brakes",
  "Park | Trail": "setup",
  Federweg: "travel",
  CSC: "battery",
  SAG: "sag",
  Kette: "chain",
  Druck: "pressure",
  Cockpit: "cockpit",
  Ausweis: "identity",
};

export function radMarkForItem(id: DieBoxItemId): RadMarkName {
  return ITEM_MARK[id];
}

export function radMarkForReadiness(r: DieBoxReadiness): RadMarkName {
  if (r === "ready") return "ready";
  if (r === "almost") return "almost";
  return "unknown";
}

export function radMarkForChip(label: string): RadMarkName {
  const exact = CHIP_MARK[label];
  if (exact) return exact;
  if (/\d+\s*\/\s*.*mm/i.test(label) || /mm$/i.test(label.trim())) {
    return "travel";
  }
  if (/^(700c|650b|27\.5"|29"|27_5)$/i.test(label.trim())) {
    return "pressure";
  }
  return "parts";
}

export function radMarkForMeasure(
  kind: "pressure" | "sag" | "travel"
): RadMarkName {
  if (kind === "pressure") return "pressure";
  if (kind === "sag") return "sag";
  return "travel";
}

/** Category silhouette on the stand — same asset the Box and the Hof use. */
export function radSilhouetteSrc(input: {
  category: BikeCategory;
  isEbike?: boolean;
}): string {
  const schema = planBikeSchema({
    category: input.category,
    isEbike: input.isEbike,
  });
  if (input.category === "hiking") return "/garage/silhouettes/hiking.svg";
  return schema.template ? SCHEMA_ASSET_PATH[schema.template] : RAD_NO_PHOTO;
}

export function radMarkForSlot(slot: ComponentSlot): RadMarkName {
  switch (slot) {
    case "tire_front":
    case "tire_rear":
    case "tire_insert_front":
    case "tire_insert_rear":
      return "pressure";
    case "fork":
    case "rear_shock":
      return "sag";
    case "chain":
    case "cassette":
    case "chainring":
    case "crankset":
    case "front_derailleur":
    case "rear_derailleur":
      return "chain";
    case "brake_front":
    case "brake_rear":
    case "rotor_front":
    case "rotor_rear":
    case "brake_pads_front":
    case "brake_pads_rear":
      return "brakes";
    case "light":
      return "lights";
    case "lock":
      return "lock";
    case "rack":
      return "rack";
    case "bags":
      return "bags";
    case "battery":
    case "motor":
    case "display":
      return "battery";
    case "handlebar":
    case "stem":
    case "grips":
    case "bar_tape":
      return "cockpit";
    default:
      return "parts";
  }
}
