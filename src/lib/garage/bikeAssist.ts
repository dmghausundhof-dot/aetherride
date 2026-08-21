import type { BikeCategory, WheelSize } from "@/types";

/** Muskel vs. E-Bike — Parität zu Mobile `bike_assist.dart`. */
export type BikeAssistMode = "muscle" | "ebike";

export const MUSCLE_CATEGORIES: BikeCategory[] = [
  "urban",
  "cargo",
  "folding",
  "kids",
  "gravel",
  "road",
  "mtb_trail",
  "mtb_am",
  "mtb_enduro",
  "dh",
  "hiking",
];

/** UI-Untertypen unter E-Bike (Web persistiert category + isEbike). */
export const EBIKE_CATEGORIES: BikeCategory[] = [
  "etrekking",
  "urban",
  "cargo",
  "folding",
  "kids",
  "gravel",
  "road",
  "emtb",
];

export type CategoryPickGroupId = "everyday" | "tour" | "trail";

export type CategoryPickGroup = {
  id: CategoryPickGroupId;
  label: string;
  categories: BikeCategory[];
};

const EVERYDAY_MUSCLE: BikeCategory[] = ["urban", "cargo", "folding", "kids"];
const EVERYDAY_EBIKE: BikeCategory[] = [
  "etrekking",
  "urban",
  "cargo",
  "folding",
  "kids",
];
const TOUR: BikeCategory[] = ["gravel", "road"];
const TRAIL_MUSCLE: BikeCategory[] = [
  "mtb_trail",
  "mtb_am",
  "mtb_enduro",
  "dh",
  "hiking",
];
const TRAIL_EBIKE: BikeCategory[] = ["emtb"];

/** Kurze Typ-Liste beim Anlegen — Feinschnitt später in der Identität. */
export const ADD_MUSCLE: BikeCategory[] = [
  "urban",
  "gravel",
  "road",
  "mtb_am",
  "cargo",
  "folding",
];

export const ADD_EBIKE: BikeCategory[] = [
  "urban",
  "etrekking",
  "gravel",
  "road",
  "emtb",
  "cargo",
];

export function addCategories(mode: BikeAssistMode): BikeCategory[] {
  return mode === "ebike" ? ADD_EBIKE : ADD_MUSCLE;
}

/** Enduro/Trail/DH aus Onboarding markieren die MTB-Kachel. */
export function addTileSelected(
  tile: BikeCategory,
  current: BikeCategory,
  mode: BikeAssistMode
): boolean {
  if (tile === current) return true;
  if (mode === "muscle" && tile === "mtb_am") {
    return current === "mtb_trail" || current === "mtb_enduro" || current === "dh";
  }
  return false;
}

export function defaultWheelFor(category: BikeCategory): WheelSize {
  if (category === "gravel") return "650b";
  if (
    category === "urban" ||
    category === "road" ||
    category === "etrekking" ||
    category === "cargo" ||
    category === "folding" ||
    category === "kids"
  ) {
    return "700c";
  }
  return "29";
}

export function persistCategory(
  uiCategory: BikeCategory,
  mode: BikeAssistMode
): BikeCategory {
  if (mode === "muscle") {
    if (uiCategory === "emtb") return "mtb_am";
    if (uiCategory === "etrekking") return "urban";
    return uiCategory;
  }
  if (
    uiCategory === "mtb_trail" ||
    uiCategory === "mtb_am" ||
    uiCategory === "mtb_enduro" ||
    uiCategory === "dh"
  ) {
    return "emtb";
  }
  if (uiCategory === "hiking") return "etrekking";
  return uiCategory;
}

/** Anlegen: Alltag zuerst, Trail nicht als Default-Welt. */
export function categoryPickGroups(mode: BikeAssistMode): CategoryPickGroup[] {
  const allowed = new Set(
    mode === "ebike" ? EBIKE_CATEGORIES : MUSCLE_CATEGORIES
  );
  const take = (ids: BikeCategory[]) => ids.filter((c) => allowed.has(c));
  const groups: CategoryPickGroup[] = [
    { id: "everyday", label: "Alltag", categories: take(mode === "ebike" ? EVERYDAY_EBIKE : EVERYDAY_MUSCLE) },
    { id: "tour", label: "Tour", categories: take(TOUR) },
    { id: "trail", label: "Trail", categories: take(mode === "ebike" ? TRAIL_EBIKE : TRAIL_MUSCLE) },
  ];
  return groups.filter((g) => g.categories.length > 0);
}

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
      urban: "City",
      cargo: "Lastenrad",
      folding: "Faltrad",
      kids: "Kinderrad",
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
    case "cargo":
      return "E-Lastenrad";
    case "folding":
      return "E-Faltrad";
    case "kids":
      return "E-Kinderrad";
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
    return MUSCLE_CATEGORIES.includes(current) ? current : "urban";
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
  return "urban";
}

export function persistIsEbike(
  category: BikeCategory,
  mode: BikeAssistMode
): boolean {
  if (mode === "ebike") return true;
  return category === "emtb" || category === "etrekking";
}
