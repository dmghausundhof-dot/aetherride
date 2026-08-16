import type { BikeCategory } from "@/types";

/** Flutter Bike.categoryLabel — Hof meta, including Assist. */
export function hofSportLabel(
  category: BikeCategory,
  isEbike = false
): string {
  const electric =
    isEbike || category === "emtb" || category === "etrekking";
  if (electric) {
    if (
      category === "mtb_trail" ||
      category === "mtb_am" ||
      category === "mtb_enduro" ||
      category === "dh" ||
      category === "emtb"
    ) {
      return "E-MTB";
    }
    if (category === "etrekking") return "E-Trekking";
    if (category === "gravel") return "E-Gravel";
    if (category === "urban") return "E-City";
    if (category === "cargo") return "E-Lastenrad";
    if (category === "folding") return "E-Faltrad";
    if (category === "kids") return "E-Kinderrad";
    if (category === "road") return "E-Road";
  }
  const map: Record<BikeCategory, string> = {
    mtb_trail: "MTB Trail",
    mtb_am: "MTB",
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
    hiking: "Zu Fuß",
  };
  return map[category];
}
