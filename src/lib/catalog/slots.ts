import type { ChromeLang } from "@/lib/i18n/chromeLang";
import {
  localizedBikeCategoryLabel,
  localizedSlotLabel,
} from "@/lib/i18n/slotCopy";
import type { BikeCategory, ComponentSlot } from "@/types/garage";

/** Pflicht-Slots je Bike-Kategorie (F-GAR-002) */
export function requiredSlotsForCategory(category: BikeCategory): ComponentSlot[] {
  if (category === "hiking") {
    return ["hiking_shoes", "hiking_pack", "hiking_poles"];
  }

  const base: ComponentSlot[] = [
    "frame",
    "fork",
    "headset",
    "stem",
    "handlebar",
    "grips",
    "seatpost",
    "saddle",
    "front_hub",
    "rear_hub",
    "front_rim",
    "rear_rim",
    "tire_front",
    "tire_rear",
    "cassette",
    "chain",
    "crankset",
    "chainring",
    "rear_derailleur",
    "shifter",
    "bottom_bracket",
    "brake_front",
    "brake_rear",
    "rotor_front",
    "rotor_rear",
    "brake_pads_front",
    "brake_pads_rear",
    "pedals",
  ];

  const fully: ComponentSlot[] = ["rear_shock"];
  const gravelRoad: ComponentSlot[] = ["front_derailleur", "bar_tape"];
  const ebike: ComponentSlot[] = ["motor", "battery", "display"];

  let slots = [...base];

  if (
    category === "mtb_trail" ||
    category === "mtb_am" ||
    category === "mtb_enduro" ||
    category === "dh" ||
    category === "emtb"
  ) {
    slots = [...slots, ...fully];
  }

  if (category === "gravel" || category === "road") {
    slots = slots.filter((s) => s !== "grips");
    slots = [...slots, ...gravelRoad];
    // Dropbar: Lenkerband statt Griffe. 1x-Gravel lässt front_derailleur leer (N/A).
  }

  if (category === "emtb" || category === "etrekking" || category === "cargo") {
    slots = [...slots, ...ebike];
  }

  if (category === "cargo") {
    // Mid-Motor ersetzt das Tretlager; Nabe/Riemen statt Schaltwerk.
    slots = slots.filter((s) => s !== "rear_derailleur" && s !== "bottom_bracket");
    slots = [...slots, "light", "rack"];
  }

  if (category === "folding") {
    // Falträder oft Felgenbremse (Brompton, Tern Link D8) — keine Disc-Pflicht.
    slots = slots.filter(
      (s) =>
        s !== "rotor_front" &&
        s !== "rotor_rear" &&
        s !== "brake_pads_front" &&
        s !== "brake_pads_rear"
    );
  }

  if (category === "kids") {
    slots = [
      "frame",
      "fork",
      "headset",
      "stem",
      "handlebar",
      "grips",
      "seatpost",
      "saddle",
      "front_hub",
      "rear_hub",
      "front_rim",
      "rear_rim",
      "tire_front",
      "tire_rear",
      "cassette",
      "chain",
      "crankset",
      "chainring",
      "rear_derailleur",
      "shifter",
      "brake_front",
      "brake_rear",
      "pedals",
    ];
  }

  return Array.from(new Set(slots));
}

export function slotLabel(
  slot: ComponentSlot,
  lang: ChromeLang = "de"
): string {
  return localizedSlotLabel(slot, lang);
}

export function isSafetyCriticalSlot(slot: ComponentSlot): boolean {
  return [
    "frame",
    "fork",
    "headset",
    "stem",
    "handlebar",
    "seatpost",
    "front_hub",
    "rear_hub",
    "front_rim",
    "rear_rim",
    "tire_front",
    "tire_rear",
    "brake_front",
    "brake_rear",
    "rotor_front",
    "rotor_rear",
  ].includes(slot);
}

export function categoryToBikeType(
  category: BikeCategory
): import("@/types/garage").BikeType {
  switch (category) {
    case "mtb_am":
    case "mtb_trail":
      return "all_mountain";
    case "mtb_enduro":
    case "dh":
      return "enduro";
    case "gravel":
      return "gravel";
    case "road":
    case "urban":
    case "cargo":
    case "folding":
    case "kids":
      return "road";
    case "emtb":
      return "e_mtb";
    case "etrekking":
      return "e_gravel";
    case "hiking":
      return "hiking";
  }
}

export function bikeTypeToCategory(
  type: import("@/types/garage").BikeType
): BikeCategory {
  switch (type) {
    case "all_mountain":
      return "mtb_am";
    case "enduro":
      return "mtb_enduro";
    case "gravel":
      return "gravel";
    case "road":
      return "road";
    case "e_mtb":
      return "emtb";
    case "e_gravel":
      return "etrekking";
    case "hiking":
      return "hiking";
  }
}

export function bikeCategoryLabel(
  category: BikeCategory,
  lang: ChromeLang = "de"
): string {
  return localizedBikeCategoryLabel(category, lang);
}
