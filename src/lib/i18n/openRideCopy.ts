/**
 * Universal-link landing. The road stays the app — no web turn-by-turn.
 */
import type { ChromeLang } from "./chromeLang";

export type OpenRideCopy = {
  title: string;
  handingTour: string;
  handingNav: string;
  openNow: string;
  notInstalled: string;
  loadInStore: string;
  continueInBrowser: string;
  continueCta: string;
  opening: string;
};

const DE: OpenRideCopy = {
  title: "App öffnen",
  handingTour: "Geplante Tour wird an die App übergeben…",
  handingNav: "Weiterleitung zur nativen Navigation…",
  openNow: "App jetzt öffnen",
  notInstalled: "App nicht installiert?",
  loadInStore: "Im Store laden:",
  continueInBrowser: "Im Browser fortfahren:",
  continueCta: "Im Browser fortfahren →",
  opening: "Öffne App…",
};

const EN: OpenRideCopy = {
  title: "Open the app",
  handingTour: "Handing the planned tour to the app…",
  handingNav: "Redirecting to native navigation…",
  openNow: "Open the app now",
  notInstalled: "App not installed?",
  loadInStore: "Get it from the store:",
  continueInBrowser: "Continue in the browser:",
  continueCta: "Continue in the browser →",
  opening: "Opening the app…",
};

const FR: OpenRideCopy = {
  title: "Ouvrir l’app",
  handingTour: "La sortie planifiée passe à l’app…",
  handingNav: "Redirection vers la navigation native…",
  openNow: "Ouvrir l’app maintenant",
  notInstalled: "App pas installée ?",
  loadInStore: "Télécharger dans le store :",
  continueInBrowser: "Continuer dans le navigateur :",
  continueCta: "Continuer dans le navigateur →",
  opening: "Ouverture de l’app…",
};

const IT: OpenRideCopy = {
  title: "Apri l’app",
  handingTour: "Il percorso pianificato passa all’app…",
  handingNav: "Reindirizzamento alla navigazione nativa…",
  openNow: "Apri l’app ora",
  notInstalled: "App non installata?",
  loadInStore: "Scaricala dallo store:",
  continueInBrowser: "Continua nel browser:",
  continueCta: "Continua nel browser →",
  opening: "Apertura dell’app…",
};

const NL: OpenRideCopy = {
  title: "App openen",
  handingTour: "Geplande tocht gaat naar de app…",
  handingNav: "Doorsturen naar native navigatie…",
  openNow: "App nu openen",
  notInstalled: "App niet geïnstalleerd?",
  loadInStore: "Download in de store:",
  continueInBrowser: "Verder in de browser:",
  continueCta: "Verder in de browser →",
  opening: "App openen…",
};

const BY: Record<ChromeLang, OpenRideCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function openRideCopy(lang: ChromeLang = "de"): OpenRideCopy {
  return BY[lang] ?? DE;
}
