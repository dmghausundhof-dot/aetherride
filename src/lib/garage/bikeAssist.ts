import type { BikeCategory } from "@/types";

/** Muskel vs. E-Bike — Parität zu Mobile `bike_assist.dart`. */
export type BikeAssistMode = "muscle" | "ebike";

export const MUSCLE_CATEGORIES: BikeCategory[] = [
  "mtb_trail",
  "mtb_am",
  "mtb_enduro",
  "dh",
  "gravel",
  "road",
  "urban",
  "hiking",
];

/** UI-Untertypen unter E-Bike (Web persistiert category + isEbike). */
export const EBIKE_CATEGORIES: BikeCategory[] = [
  "emtb",
  "etrekking",
  "gravel",
  "urban",
  "road",
];

export function assistModeFor(
  category: BikeCategory,
  isEbike = false
): BikeAssistMode {
  if (isEbike || category === "emtb" || category === "etrekking") {
    return "ebike";
  }
  return "muscle";
}

export function subtypeLabel(
  category: BikeCategory,
  mode: BikeAssistMode
): string {
  if (mode === "muscle") {
    const map: Record<BikeCategory, string> = {
      mtb_trail: "MTB Trail",
      mtb_am: "All-Mountain",
      mtb_enduro: "Enduro",
      dh: "Downhill",
      gravel: "Gravel",
      road: "Rennrad",
      urban: "Urban",
      emtb: "E-MTB",
      etrekking: "E-Trekking",
      hiking: "Wandern",
    };
    return map[category];
  }
  switch (category) {
    case "emtb":
      return "E-MTB";
    case "etrekking":
      return "E-Trekking";
    case "gravel":
      return "E-Gravel";
    case "urban":
      return "E-City";
    case "road":
      return "E-Road";
    default:
      return category;
  }
}

export function coerceCategory(
  current: BikeCategory,
  mode: BikeAssistMode
): BikeCategory {
  if (mode === "muscle") {
    if (current === "emtb") return "mtb_am";
    if (current === "etrekking") return "urban";
    return MUSCLE_CATEGORIES.includes(current) ? current : "mtb_am";
  }
  if (
    current === "mtb_trail" ||
    current === "mtb_am" ||
    current === "mtb_enduro" ||
    current === "dh"
  ) {
    return "emtb";
  }
  if (current === "hiking") return "etrekking";
  if (EBIKE_CATEGORIES.includes(current)) return current;
  return "emtb";
}

export function persistIsEbike(
  category: BikeCategory,
  mode: BikeAssistMode
): boolean {
  if (mode === "ebike") return true;
  return category === "emtb" || category === "etrekking";
}
