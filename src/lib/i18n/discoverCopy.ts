import type { RoutingProfile } from "@/lib/routing/profiles";
import type {
  ElevationChip,
  ScaleChip,
  SportFilter,
  SurfaceKey,
} from "@/lib/routing/routeFilters";
import type { ChromeLang } from "./chromeLang";

export type DiscoverCopy = {
  timeWindow: string;
  minutes: (n: number) => string;
  sportPref: string;
  loop: string;
  mappe: string;
  reset: string;
  searchHint: string;
  planRouteCta: string;
  filter: string;
  distance: string;
  aroundKm: (km: number) => string;
  showTours: (n: number) => string;
  catalogTours: (n: number) => string;
  toursNearby: (n: number) => string;
  oaCount: (n: number) => string;
  visAll: string;
  visPrivate: string;
  visPublic: string;
  sport: Record<SportFilter, string>;
  dist: (km: number) => string;
  elevFlat: string;
  elevHilly: string;
  elevAlpine: string;
  surface: Record<SurfaceKey, string>;
  diffAny: string;
  diffEasy: string;
  diffMid: string;
  diffHard: string;
  diffGravelMid: string;
  diffGravelHard: string;
  diffRoadEasy: string;
  diffRoadMid: string;
};

const DE: DiscoverCopy = {
  timeWindow: "Zeitfenster · ",
  minutes: (n) => `${n} min`,
  sportPref: "Disziplin (Präferenz)",
  loop: "Rundkurs",
  mappe: "Mappe",
  reset: "Zurücksetzen",
  searchHint: "Ort oder Tour",
  planRouteCta: "Navigieren",
  filter: "Filter",
  distance: "Distanz",
  aroundKm: (km) => `in ${km} km`,
  showTours: (n) => (n === 1 ? "1 Tour zeigen" : `${n} Touren zeigen`),
  catalogTours: (n) => (n === 1 ? "Katalog 1 Tour" : `Katalog ${n} Touren`),
  toursNearby: (n) =>
    n === 1 ? "1 Tour in der Nähe" : `${n} Touren in der Nähe`,
  oaCount: (n) => (n === 1 ? "1 Tour in der Nähe" : `${n} Touren in der Nähe`),
  visAll: "Alle",
  visPrivate: "Privat",
  visPublic: "Freigegeben",
  sport: {
    all: "Alle",
    road: "Rennrad",
    gravel: "Gravel",
    mtb: "MTB",
    urban: "City",
    ebike: "E-MTB",
    touring: "Touring",
    hiking: "Wandern",
  },
  dist: (km) => `≤ ${km} km`,
  elevFlat: "< 400 hm",
  elevHilly: "400–1100",
  elevAlpine: "1100+ hm",
  surface: {
    asphalt: "Asphalt",
    gravel: "Schotter",
    trail: "Trail",
    mixed: "Gemischt",
  },
  diffAny: "Alle",
  diffEasy: "Leicht",
  diffMid: "Mittel",
  diffHard: "Anspruchsvoll",
  diffGravelMid: "Gemischt",
  diffGravelHard: "Rau",
  diffRoadEasy: "Entspannt",
  diffRoadMid: "Sportlich",
};

const EN: DiscoverCopy = {
  timeWindow: "Time window · ",
  minutes: (n) => `${n} min`,
  sportPref: "Discipline (preference)",
  loop: "Loop",
  mappe: "Die Mappe",
  reset: "Reset",
  searchHint: "Place or tour",
  planRouteCta: "Navigate",
  filter: "Filter",
  distance: "Distance",
  aroundKm: (km) => `within ${km} km`,
  showTours: (n) => (n === 1 ? "Show 1 tour" : `Show ${n} tours`),
  catalogTours: (n) => (n === 1 ? "Catalog 1 tour" : `Catalog ${n} tours`),
  toursNearby: (n) => (n === 1 ? "1 tour nearby" : `${n} tours nearby`),
  oaCount: (n) => (n === 1 ? "1 tour nearby" : `${n} tours nearby`),
  visAll: "All",
  visPrivate: "Private",
  visPublic: "Shared",
  sport: {
    all: "All",
    road: "Road",
    gravel: "Gravel",
    mtb: "MTB",
    urban: "City",
    ebike: "E-MTB",
    touring: "Touring",
    hiking: "Hiking",
  },
  dist: (km) => `≤ ${km} km`,
  elevFlat: "< 400 hm",
  elevHilly: "400–1100",
  elevAlpine: "1100+ hm",
  surface: {
    asphalt: "Asphalt",
    gravel: "Gravel",
    trail: "Trail",
    mixed: "Mixed",
  },
  diffAny: "All",
  diffEasy: "Easy",
  diffMid: "Mid",
  diffHard: "Hard",
  diffGravelMid: "Mixed",
  diffGravelHard: "Rough",
  diffRoadEasy: "Easy",
  diffRoadMid: "Sporty",
};

const FR: DiscoverCopy = {
  timeWindow: "Fenêtre · ",
  minutes: (n) => `${n} min`,
  sportPref: "Discipline (préférence)",
  loop: "Boucle",
  mappe: "Die Mappe",
  reset: "Réinitialiser",
  searchHint: "Lieu ou tour",
  planRouteCta: "Naviguer",
  filter: "Filtres",
  distance: "Distance",
  aroundKm: (km) => `dans ${km} km`,
  showTours: (n) => (n === 1 ? "Afficher 1 tour" : `Afficher ${n} tours`),
  catalogTours: (n) =>
    n === 1 ? "Catalogue 1 tour" : `Catalogue ${n} tours`,
  toursNearby: (n) =>
    n === 1 ? "1 tour à proximité" : `${n} tours à proximité`,
  oaCount: (n) =>
    n === 1
      ? "Outdooractive 1 tour · OSM/traces suivent"
      : `Outdooractive ${n} tours · OSM/traces suivent`,
  visAll: "Tous",
  visPrivate: "Privé",
  visPublic: "Partagé",
  sport: {
    all: "Tous",
    road: "Route",
    gravel: "Gravel",
    mtb: "MTB",
    urban: "City",
    ebike: "E-MTB",
    touring: "Touring",
    hiking: "Rando",
  },
  dist: (km) => `≤ ${km} km`,
  elevFlat: "< 400 hm",
  elevHilly: "400–1100",
  elevAlpine: "1100+ hm",
  surface: {
    asphalt: "Asphalte",
    gravel: "Graviers",
    trail: "Trail",
    mixed: "Mixte",
  },
  diffAny: "Tous",
  diffEasy: "Facile",
  diffMid: "Moyen",
  diffHard: "Exigeant",
  diffGravelMid: "Mixte",
  diffGravelHard: "Rugueux",
  diffRoadEasy: "Tranquille",
  diffRoadMid: "Sportif",
};

const IT: DiscoverCopy = {
  timeWindow: "Finestra · ",
  minutes: (n) => `${n} min`,
  sportPref: "Disciplina (preferenza)",
  loop: "Anello",
  mappe: "Die Mappe",
  reset: "Azzera",
  searchHint: "Luogo o tour",
  planRouteCta: "Naviga",
  filter: "Filtri",
  distance: "Distanza",
  aroundKm: (km) => `entro ${km} km`,
  showTours: (n) => (n === 1 ? "Mostra 1 tour" : `Mostra ${n} tour`),
  catalogTours: (n) => (n === 1 ? "Catalogo 1 tour" : `Catalogo ${n} tour`),
  toursNearby: (n) =>
    n === 1 ? "1 tour nelle vicinanze" : `${n} tour nelle vicinanze`,
  oaCount: (n) => (n === 1 ? "1 tour qui vicino" : `${n} tour qui vicino`),
  visAll: "Tutti",
  visPrivate: "Privato",
  visPublic: "Condiviso",
  sport: {
    all: "Tutti",
    road: "Corsa",
    gravel: "Gravel",
    mtb: "MTB",
    urban: "City",
    ebike: "E-MTB",
    touring: "Touring",
    hiking: "Escursione",
  },
  dist: (km) => `≤ ${km} km`,
  elevFlat: "< 400 hm",
  elevHilly: "400–1100",
  elevAlpine: "1100+ hm",
  surface: {
    asphalt: "Asfalto",
    gravel: "Ghiaia",
    trail: "Trail",
    mixed: "Misto",
  },
  diffAny: "Tutti",
  diffEasy: "Facile",
  diffMid: "Medio",
  diffHard: "Impegnativo",
  diffGravelMid: "Misto",
  diffGravelHard: "Ruvido",
  diffRoadEasy: "Tranquillo",
  diffRoadMid: "Sportivo",
};

const NL: DiscoverCopy = {
  timeWindow: "Tijdvenster · ",
  minutes: (n) => `${n} min`,
  sportPref: "Discipline (voorkeur)",
  loop: "Lus",
  mappe: "Die Mappe",
  reset: "Resetten",
  searchHint: "Plaats of tocht",
  planRouteCta: "Navigeren",
  filter: "Filter",
  distance: "Afstand",
  aroundKm: (km) => `binnen ${km} km`,
  showTours: (n) => (n === 1 ? "1 tocht tonen" : `${n} tochten tonen`),
  catalogTours: (n) => (n === 1 ? "Catalogus 1 tocht" : `Catalogus ${n} tochten`),
  toursNearby: (n) =>
    n === 1 ? "1 tocht in de buurt" : `${n} tochten in de buurt`,
  oaCount: (n) => (n === 1 ? "1 tocht in de buurt" : `${n} tochten in de buurt`),
  visAll: "Alle",
  visPrivate: "Privé",
  visPublic: "Gedeeld",
  sport: {
    all: "Alle",
    road: "Weg",
    gravel: "Gravel",
    mtb: "MTB",
    urban: "City",
    ebike: "E-MTB",
    touring: "Touring",
    hiking: "Wandelen",
  },
  dist: (km) => `≤ ${km} km`,
  elevFlat: "< 400 hm",
  elevHilly: "400–1100",
  elevAlpine: "1100+ hm",
  surface: {
    asphalt: "Asfalt",
    gravel: "Grind",
    trail: "Trail",
    mixed: "Gemengd",
  },
  diffAny: "Alle",
  diffEasy: "Licht",
  diffMid: "Middel",
  diffHard: "Zwaar",
  diffGravelMid: "Gemengd",
  diffGravelHard: "Ruw",
  diffRoadEasy: "Relaxed",
  diffRoadMid: "Sportief",
};

const BY_LANG: Record<ChromeLang, DiscoverCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function discoverCopy(lang: ChromeLang): DiscoverCopy {
  return BY_LANG[lang];
}

/** Same ids as difficultyOptionsForProfile; labels follow chrome. */
export function discoverDifficulty(
  profile: RoutingProfile,
  lang: ChromeLang,
): { id: ScaleChip; label: string }[] {
  const d = discoverCopy(lang);
  const mtbLike =
    profile === "mtb_allmountain" ||
    profile === "mtb_enduro" ||
    profile === "downhill" ||
    profile === "emtb";
  if (mtbLike || profile === "hiking") {
    return [
      { id: "any", label: d.diffAny },
      { id: "easy", label: d.diffEasy },
      { id: "mid", label: d.diffMid },
      { id: "hard", label: d.diffHard },
    ];
  }
  if (profile === "gravel") {
    return [
      { id: "any", label: d.diffAny },
      { id: "easy", label: d.diffEasy },
      { id: "mid", label: d.diffGravelMid },
      { id: "hard", label: d.diffGravelHard },
    ];
  }
  if (profile === "urban" || profile === "road" || profile === "ebike") {
    return [
      { id: "any", label: d.diffAny },
      { id: "easy", label: d.diffRoadEasy },
      { id: "mid", label: d.diffRoadMid },
      { id: "hard", label: d.diffHard },
    ];
  }
  return [
    { id: "any", label: d.diffAny },
    { id: "easy", label: d.diffEasy },
    { id: "mid", label: d.diffMid },
    { id: "hard", label: d.diffHard },
  ];
}

export function discoverElevationLabel(
  id: ElevationChip,
  lang: ChromeLang,
): string {
  const d = discoverCopy(lang);
  if (id === "flat") return d.elevFlat;
  if (id === "hilly") return d.elevHilly;
  if (id === "alpine") return d.elevAlpine;
  return d.diffAny;
}
