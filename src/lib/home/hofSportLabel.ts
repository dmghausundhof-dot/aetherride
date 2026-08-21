import type { BikeCategory } from "@/types";
import type { ChromeLang } from "@/lib/i18n/chromeLang";

type SportMap = Record<BikeCategory, string>;

/** Flutter bikeCat* — Hof meta, including Assist. Engine names stay German. */
const CAT: Record<ChromeLang, SportMap> = {
  de: {
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
  },
  en: {
    mtb_trail: "MTB trail",
    mtb_am: "MTB",
    mtb_enduro: "Enduro",
    dh: "Downhill",
    gravel: "Gravel",
    road: "Road",
    urban: "City",
    cargo: "Cargo",
    folding: "Folding",
    kids: "Kids",
    emtb: "E-MTB",
    etrekking: "E-trekking",
    hiking: "On foot",
  },
  fr: {
    mtb_trail: "Trail VTT",
    mtb_am: "VTT",
    mtb_enduro: "Enduro",
    dh: "Descente",
    gravel: "Gravel",
    road: "Vélo de route",
    urban: "City",
    cargo: "Cargo",
    folding: "Pliant",
    kids: "Enfant",
    emtb: "VTTAE",
    etrekking: "E-trekking",
    hiking: "À pied",
  },
  it: {
    mtb_trail: "Trail MTB",
    mtb_am: "MTB",
    mtb_enduro: "Enduro",
    dh: "Downhill",
    gravel: "Gravel",
    road: "Bici da corsa",
    urban: "City",
    cargo: "Cargo",
    folding: "Pieghevole",
    kids: "Bambini",
    emtb: "E-MTB",
    etrekking: "E-trekking",
    hiking: "A piedi",
  },
  nl: {
    mtb_trail: "MTB trail",
    mtb_am: "MTB",
    mtb_enduro: "Enduro",
    dh: "Downhill",
    gravel: "Gravel",
    road: "Race",
    urban: "Stad",
    cargo: "Cargo",
    folding: "Vouwfiets",
    kids: "Kinderen",
    emtb: "E-MTB",
    etrekking: "E-trekking",
    hiking: "Te voet",
  },
};

const CAT_E: Record<ChromeLang, SportMap> = {
  de: {
    mtb_trail: "E-MTB",
    mtb_am: "E-MTB",
    mtb_enduro: "E-MTB",
    dh: "E-MTB",
    gravel: "E-Gravel",
    road: "E-Road",
    urban: "E-City",
    cargo: "E-Lastenrad",
    folding: "E-Faltrad",
    kids: "E-Kinderrad",
    emtb: "E-MTB",
    etrekking: "E-Trekking",
    hiking: "Zu Fuß",
  },
  en: {
    mtb_trail: "E-MTB",
    mtb_am: "E-MTB",
    mtb_enduro: "E-MTB",
    dh: "E-MTB",
    gravel: "E-gravel",
    road: "E-road",
    urban: "E-city",
    cargo: "E-cargo",
    folding: "E-folding",
    kids: "E-kids",
    emtb: "E-MTB",
    etrekking: "E-trekking",
    hiking: "On foot",
  },
  fr: {
    mtb_trail: "VTTAE",
    mtb_am: "VTTAE",
    mtb_enduro: "VTTAE",
    dh: "VTTAE",
    gravel: "E-gravel",
    road: "E-route",
    urban: "E-city",
    cargo: "E-cargo",
    folding: "E-pliant",
    kids: "E-enfant",
    emtb: "VTTAE",
    etrekking: "E-trekking",
    hiking: "À pied",
  },
  it: {
    mtb_trail: "E-MTB",
    mtb_am: "E-MTB",
    mtb_enduro: "E-MTB",
    dh: "E-MTB",
    gravel: "E-gravel",
    road: "E-road",
    urban: "E-city",
    cargo: "E-cargo",
    folding: "E-pieghevole",
    kids: "E-bambini",
    emtb: "E-MTB",
    etrekking: "E-trekking",
    hiking: "A piedi",
  },
  nl: {
    mtb_trail: "E-MTB",
    mtb_am: "E-MTB",
    mtb_enduro: "E-MTB",
    dh: "E-MTB",
    gravel: "E-gravel",
    road: "E-race",
    urban: "E-city",
    cargo: "E-cargo",
    folding: "E-vouw",
    kids: "E-kinderen",
    emtb: "E-MTB",
    etrekking: "E-trekking",
    hiking: "Te voet",
  },
};

/** Flutter Bike.categoryLabel — Hof meta, including Assist. */
export function hofSportLabel(
  category: BikeCategory,
  isEbike = false,
  lang: ChromeLang = "de"
): string {
  const electric =
    isEbike || category === "emtb" || category === "etrekking";
  const pack = electric ? CAT_E[lang] ?? CAT_E.de : CAT[lang] ?? CAT.de;
  return pack[category];
}

/** Name beim Anlegen ohne Spitzname: Kategorie, kein Fake „Mein Bike“. */
export function fallbackBikeName(
  category: BikeCategory,
  isEbike = false
): string {
  return hofSportLabel(category, isEbike, "de");
}

/** Gesetzter Name bleibt. Leer/Whitespace wird zur Kategorie. */
export function resolvedBikeName(
  name: string | undefined,
  category: BikeCategory,
  isEbike = false
): string {
  const trimmed = (name ?? "").trim();
  return trimmed || fallbackBikeName(category, isEbike);
}
