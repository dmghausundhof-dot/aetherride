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
    slots = [...slots, ...gravelRoad];
    // Gravel/Road oft ohne Gabel-Fahrwerk im klassischen Sinn – Slot bleibt, kann Free-Text sein
  }

  if (category === "emtb" || category === "etrekking") {
    slots = [...slots, ...ebike];
    if (category === "etrekking" && !slots.includes("rear_shock")) {
      // Soft-Trekking kann Hardtail sein
    }
  }

  return Array.from(new Set(slots));
}

export function slotLabel(slot: ComponentSlot): string {
  const map: Record<ComponentSlot, string> = {
    frame: "Rahmen",
    fork: "Gabel",
    rear_shock: "Dämpfer",
    headset: "Steuersatz",
    stem: "Vorbau",
    handlebar: "Lenker",
    grips: "Griffe",
    seatpost: "Sattelstütze",
    saddle: "Sattel",
    front_hub: "Nabe vorne",
    rear_hub: "Nabe hinten",
    front_rim: "Felge vorne",
    rear_rim: "Felge hinten",
    tire_front: "Reifen vorne",
    tire_rear: "Reifen hinten",
    tire_insert_front: "Insert vorne",
    tire_insert_rear: "Insert hinten",
    cassette: "Kassette",
    chain: "Kette",
    crankset: "Kurbel",
    chainring: "Kettenblatt",
    rear_derailleur: "Schaltwerk",
    shifter: "Schalthebel",
    front_derailleur: "Umwerfer",
    bottom_bracket: "Innenlager",
    brake_front: "Bremse vorne",
    brake_rear: "Bremse hinten",
    rotor_front: "Bremsscheibe vorne",
    rotor_rear: "Bremsscheibe hinten",
    brake_pads_front: "Bremsbeläge vorne",
    brake_pads_rear: "Bremsbeläge hinten",
    pedals: "Pedale",
    bar_tape: "Lenkerband",
    motor: "Motor",
    battery: "Akku",
    display: "Display/Remote",
    hiking_shoes: "Schuhe",
    hiking_pack: "Rucksack",
    hiking_poles: "Stöcke",
  };
  return map[slot] ?? slot;
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

export function bikeCategoryLabel(category: BikeCategory): string {
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
