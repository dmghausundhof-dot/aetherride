import type { BikeCategory } from "@/types";

/** Flutter BikeCategoryUx.shortLabel — Hof meta, not the long garage name. */
export function hofSportLabel(category: BikeCategory): string {
  const map: Record<BikeCategory, string> = {
    mtb_trail: "MTB Trail",
    mtb_am: "MTB",
    mtb_enduro: "Enduro",
    dh: "Downhill",
    gravel: "Gravel",
    road: "Rennrad",
    urban: "City",
    emtb: "E-MTB",
    etrekking: "E-Trekking",
    hiking: "Zu Fuß",
  };
  return map[category];
}
