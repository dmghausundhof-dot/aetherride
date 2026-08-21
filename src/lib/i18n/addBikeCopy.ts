/**
 * Add-bike wizard chrome. Category tiles use bikeCategoryLabel.
 */
import type { ChromeLang } from "./chromeLang";

export type AddBikeCopy = {
  nameOptional: string;
  drive: string;
  muscle: string;
  ebike: string;
  type: string;
  freeOne: string;
  freeMore: string;
  addFailed: string;
};

const DE: AddBikeCopy = {
  nameOptional: "Name (optional)",
  drive: "Antrieb",
  muscle: "Muskel",
  ebike: "E-Bike",
  type: "Typ",
  freeOne: "Im Free-Tarif nur ein Rad. Pro unter Profil freischalten.",
  freeMore:
    "Im Free-Tarif bereits ein Rad. Weitere Räder sind Pro — unter Profil freischalten.",
  addFailed: "Anlegen fehlgeschlagen",
};

const EN: AddBikeCopy = {
  nameOptional: "Name (optional)",
  drive: "Drive",
  muscle: "Muscle",
  ebike: "E-bike",
  type: "Type",
  freeOne: "Free includes one bike. Unlock Pro under Profile.",
  freeMore:
    "Free already has one bike. More bikes are Pro — unlock under Profile.",
  addFailed: "Could not add the bike",
};

const FR: AddBikeCopy = {
  nameOptional: "Nom (optionnel)",
  drive: "Transmission",
  muscle: "Muscle",
  ebike: "VAE",
  type: "Type",
  freeOne: "Free n’a qu’un vélo. Débloque Pro sous Profil.",
  freeMore:
    "Free a déjà un vélo. Les autres sont Pro — débloque sous Profil.",
  addFailed: "Impossible d’ajouter le vélo",
};

const IT: AddBikeCopy = {
  nameOptional: "Nome (opzionale)",
  drive: "Trasmissione",
  muscle: "Muscolo",
  ebike: "E-bike",
  type: "Tipo",
  freeOne: "Free include una bici. Sblocca Pro sotto Profilo.",
  freeMore:
    "Free ha già una bici. Le altre sono Pro — sblocca sotto Profilo.",
  addFailed: "Impossibile aggiungere la bici",
};

const NL: AddBikeCopy = {
  nameOptional: "Naam (optioneel)",
  drive: "Aandrijving",
  muscle: "Spier",
  ebike: "E-bike",
  type: "Type",
  freeOne: "Free heeft één fiets. Ontgrendel Pro onder Profiel.",
  freeMore:
    "Free heeft al één fiets. Meer fietsen zijn Pro — ontgrendel onder Profiel.",
  addFailed: "Fiets toevoegen mislukt",
};

const BY: Record<ChromeLang, AddBikeCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function addBikeCopy(lang: ChromeLang = "de"): AddBikeCopy {
  return BY[lang] ?? DE;
}
