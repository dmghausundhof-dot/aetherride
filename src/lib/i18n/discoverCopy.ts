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
  visAll: "Alle",
  visPrivate: "Privat",
  visPublic: "Öffentlich",
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
  visAll: "All",
  visPrivate: "Private",
  visPublic: "Public",
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
  visAll: "Tous",
  visPrivate: "Privé",
  visPublic: "Public",
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
  visAll: "Tutti",
  visPrivate: "Privato",
  visPublic: "Pubblico",
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

const BY_LANG: Record<ChromeLang, DiscoverCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
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
