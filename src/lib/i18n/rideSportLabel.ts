import type { ChromeLang } from "./chromeLang";

const DE: Record<string, string> = {
  all_mountain: "All-Mountain",
  enduro: "Enduro",
  gravel: "Gravel",
  road: "Rennrad",
  e_mtb: "E-MTB",
  e_gravel: "E-Gravel",
  hiking: "Wandern",
  mtb_trail: "MTB Trail",
  mtb_am: "All-Mountain",
  mtb_enduro: "Enduro",
  dh: "Downhill",
  urban: "Urban",
  cargo: "Lastenrad",
  folding: "Faltrad",
  kids: "Kinderrad",
  emtb: "E-MTB",
  etrekking: "E-Trekking",
};

const EN: Record<string, string> = {
  ...DE,
  road: "Road",
  hiking: "Hiking",
  cargo: "Cargo bike",
  folding: "Folding bike",
  kids: "Kids bike",
};

const FR: Record<string, string> = {
  ...DE,
  road: "Route",
  hiking: "Rando",
  cargo: "Cargo",
  folding: "Pliant",
  kids: "Enfant",
  urban: "Ville",
};

const IT: Record<string, string> = {
  ...DE,
  road: "Corsa",
  hiking: "Trekking",
  cargo: "Cargo",
  folding: "Pieghevole",
  kids: "Bambino",
  urban: "Città",
};

const NL: Record<string, string> = {
  ...DE,
  road: "Racefiets",
  hiking: "Wandel",
  cargo: "Bakfiets",
  folding: "Vouwfiets",
  kids: "Kinderfiets",
  urban: "Stad",
};

const BY_LANG: Record<ChromeLang, Record<string, string>> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

/** Recap-Sportname — Discover-Filter sind gröber, hier der Ride-Typ. */
export function rideSportLabel(type: string, lang: ChromeLang): string {
  const map = BY_LANG[lang];
  return map[type] || DE[type] || type;
}
