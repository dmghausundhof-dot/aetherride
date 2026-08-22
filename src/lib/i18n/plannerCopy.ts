import type { ChromeLang } from "./chromeLang";
import { discoverStatus } from "./discoverUi";

export const PLANNER_STATUS_DE = {
  geocodeFail: "Geocoding fehlgeschlagen",
  needStartEnd: "Start und Ziel setzen",
  noRoute: "Keine Route — Profil oder Punkte prüfen",
  inMappe: "In der Mappe",
  hitFallback: "Treffer",
} as const;

export type PlannerCopy = {
  tourIdeaLoaded: (name: string) => string;
  geocodeFail: string;
  needStartEnd: string;
  noRoute: string;
  inMappe: string;
  hitFallback: string;
  exploreLead: string;
  routingProfile: string;
  tourLead: string;
  addrSearch: string;
  ok: string;
  via: string;
  pickTap: (what: string) => string;
  navOffline: string;
};

const DE: PlannerCopy = {
  tourIdeaLoaded: (name) =>
    `Tour-Idee „${name}“ geladen — Start am Pin. Ziel tippen und berechnen.`,
  geocodeFail: PLANNER_STATUS_DE.geocodeFail,
  needStartEnd: PLANNER_STATUS_DE.needStartEnd,
  noRoute: PLANNER_STATUS_DE.noRoute,
  inMappe: PLANNER_STATUS_DE.inMappe,
  hitFallback: PLANNER_STATUS_DE.hitFallback,
  exploreLead: "Wohin? Start und Ziel setzen — die Tour entsteht.",
  routingProfile: "Bike",
  tourLead: "Wohin? Start und Ziel auf der Karte — die Tour entsteht.",
  addrSearch: "Adresse suchen…",
  ok: "OK",
  via: "Via",
  pickTap: (what) => `Karte tippen: ${what}`,
  navOffline: "Live-Navigation und Offline nur in der nativen App.",
};

const EN: PlannerCopy = {
  tourIdeaLoaded: (name) =>
    `Tour idea “${name}” loaded — start at the pin. Tap a finish and compute.`,
  geocodeFail: "Geocoding failed",
  needStartEnd: "Set start and finish",
  noRoute: "No route — check profile or points",
  inMappe: "In Die Mappe",
  hitFallback: "Result",
  exploreLead: "Where to? Set start and finish — the tour appears.",
  routingProfile: "Bike",
  tourLead: "Where to? Tap start and finish on the map — the tour appears.",
  addrSearch: "Search address…",
  ok: "OK",
  via: "Via",
  pickTap: (what) => `Tap the map: ${what}`,
  navOffline: "Live navigation and offline only in the native app.",
};

const FR: PlannerCopy = {
  tourIdeaLoaded: (name) =>
    `Idée de sortie « ${name} » chargée — départ au pin. Tape l’arrivée et calcule.`,
  geocodeFail: "Géocodage échoué",
  needStartEnd: "Pose départ et arrivée",
  noRoute: "Pas de route — vérifie le profil ou les points",
  inMappe: "Dans Die Mappe",
  hitFallback: "Résultat",
  exploreLead: "Où aller ? Départ et arrivée — la sortie apparaît.",
  routingProfile: "Vélo",
  tourLead: "Où aller ? Départ et arrivée sur la carte — la sortie apparaît.",
  addrSearch: "Chercher une adresse…",
  ok: "OK",
  via: "Via",
  pickTap: (what) => `Tape la carte : ${what}`,
  navOffline: "Navigation live et hors ligne seulement dans l’app native.",
};

const IT: PlannerCopy = {
  tourIdeaLoaded: (name) =>
    `Idea di uscita «${name}» caricata — partenza al pin. Tocca l’arrivo e calcola.`,
  geocodeFail: "Geocoding fallito",
  needStartEnd: "Imposta partenza e arrivo",
  noRoute: "Nessuna route — controlla profilo o punti",
  inMappe: "In Die Mappe",
  hitFallback: "Risultato",
  exploreLead: "Dove? Partenza e arrivo — il tour compare.",
  routingProfile: "Bici",
  tourLead: "Dove? Tocca partenza e arrivo sulla mappa — il tour compare.",
  addrSearch: "Cerca indirizzo…",
  ok: "OK",
  via: "Via",
  pickTap: (what) => `Tocca la mappa: ${what}`,
  navOffline: "Navigazione live e offline solo nell’app nativa.",
};

const NL: PlannerCopy = {
  tourIdeaLoaded: (name) =>
    `Tochtidee „${name}“ geladen — start bij de pin. Tik het doel en bereken.`,
  geocodeFail: "Geocoding mislukt",
  needStartEnd: "Zet start en finish",
  noRoute: "Geen route — check profiel of punten",
  inMappe: "In Die Mappe",
  hitFallback: "Resultaat",
  exploreLead: "Waarheen? Start en finish — de tocht verschijnt.",
  routingProfile: "Fiets",
  tourLead: "Waarheen? Tik start en finish op de kaart — de tocht verschijnt.",
  addrSearch: "Adres zoeken…",
  ok: "OK",
  via: "Via",
  pickTap: (what) => `Tik op de kaart: ${what}`,
  navOffline: "Live-navigatie en offline alleen in de native app.",
};

const BY_LANG: Record<ChromeLang, PlannerCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function plannerCopy(lang: ChromeLang): PlannerCopy {
  return BY_LANG[lang];
}

export function plannerStatus(
  raw: string | null | undefined,
  lang: ChromeLang,
): string {
  if (!raw) return "";
  const p = plannerCopy(lang);
  if (raw === PLANNER_STATUS_DE.geocodeFail) return p.geocodeFail;
  if (raw === PLANNER_STATUS_DE.needStartEnd) return p.needStartEnd;
  if (raw === PLANNER_STATUS_DE.noRoute) return p.noRoute;
  if (raw === PLANNER_STATUS_DE.inMappe) return p.inMappe;
  const idea = raw.match(
    /^Tour-Idee [„"](.+)[“"] geladen — Start am Pin\. Ziel tippen und berechnen\.$/,
  );
  if (idea) return p.tourIdeaLoaded(idea[1]);
  return discoverStatus(raw, lang);
}
