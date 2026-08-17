import type { HofNavId } from "@/lib/nav/hofNav";
import type { MarketingNavHref } from "@/lib/nav/marketingNav";
import type { ChromeLang } from "./chromeLang";

type HofDoorId = Exclude<HofNavId, "hof">;

type WebChrome = {
  marketingNav: Record<MarketingNavHref, string>;
  hofNav: Record<HofDoorId, string>;
  toHof: string;
  toWebsite: string;
  arriveAtHof: string;
  signIn: string;
  menuOpen: string;
  menuClose: string;
  websiteAria: string;
  footerWebsite: string;
  footerMore: string;
  footerLegal: string;
  footerTagline: string;
  footerLegalLine: string;
  aboutFlowLine: string;
  faq: string;
  share: string;
  sampleProfile: string;
  screensFlows: string;
  webVsApp: string;
  whatCameIn: string;
  dataPrivacy: string;
  imprint: string;
  privacyPolicy: string;
  terms: string;
  withdrawal: string;
  contact: string;
  plan: string;
  start: string;
  notFoundTitle: string;
  notFoundHint: string;
  marketingNotFoundTitle: string;
  marketingNotFoundHint: string;
  maintenanceDue: (n: number) => string;
  newStimmenPlatz: string;
  profile: string;
  fourDoors: string;
  tabOf: (index: number, count: number) => string;
  emptyStand: string;
  discoverApp: string;
  loadApp: string;
  loadAppStore: string;
  loadPlayStore: string;
  loading: string;
  anmeldenLocal: string;
  stillToHof: string;
};

const DE: WebChrome = {
  marketingNav: {
    "/produkt": "Produkt",
    "/karten": "Karten",
    "/regions": "Regionen",
    "/guides": "Guides",
    "/community": "Community",
    "/pricing": "Preise",
    "/download": "App",
  },
  hofNav: {
    karte: "Karte",
    platz: "Platz",
    werkstatt: "Werkstatt",
  },
  toHof: "Zum Hof",
  toWebsite: "Zur Website",
  arriveAtHof: "Am Hof ankommen",
  signIn: "Anmelden",
  menuOpen: "Menü öffnen",
  menuClose: "Menü schließen",
  websiteAria: "Website",
  footerWebsite: "Website",
  footerMore: "Mehr",
  footerLegal: "Rechtliches",
  footerTagline: "Das Rad wohnt hier. Du kommst zurück.",
  footerLegalLine: "Offline-First · DSGVO · Web ist der Hof, die App fährt.",
  aboutFlowLine: "Über FlowLine",
  faq: "FAQ",
  share: "Teilen",
  sampleProfile: "Beispiel-Profil",
  screensFlows: "Screens & Abläufe",
  webVsApp: "Web vs. App",
  whatCameIn: "Was reinkam",
  dataPrivacy: "Daten & Privatsphäre",
  imprint: "Impressum",
  privacyPolicy: "Datenschutz",
  terms: "AGB",
  withdrawal: "Widerruf",
  contact: "Kontakt",
  plan: "Planen",
  start: "Start",
  notFoundTitle: "Diese Tür gibt es nicht",
  notFoundHint: "Leerer Stand. Zurück zum Hof, oder eine der vier Türen.",
  marketingNotFoundTitle: "Diese Seite gibt es nicht",
  marketingNotFoundHint:
    "Kein Feed, keine Füll-Route. Zurück zur Website oder zum Hof.",
  maintenanceDue: (n) => `${n} Wartungen fällig`,
  newStimmenPlatz: "Neue Stimmen auf dem Platz",
  profile: "Profil",
  fourDoors: "Vier Türen",
  tabOf: (index, count) => `Tab ${index} von ${count}`,
  emptyStand: "Leerer Stand",
  discoverApp: "App entdecken",
  loadApp: "App laden",
  loadAppStore: "Im App Store laden",
  loadPlayStore: "Bei Google Play laden",
  loading: "Laden…",
  anmeldenLocal: "Ohne Konto geht der Hof lokal.",
  stillToHof: "Trotzdem zum Hof",
};

const EN: WebChrome = {
  marketingNav: {
    "/produkt": "Product",
    "/karten": "Maps",
    "/regions": "Regions",
    "/guides": "Guides",
    "/community": "Community",
    "/pricing": "Pricing",
    "/download": "App",
  },
  hofNav: {
    karte: "Map",
    platz: "Platz",
    werkstatt: "Workshop",
  },
  toHof: "To Home",
  toWebsite: "To the website",
  arriveAtHof: "Arrive at the yard",
  signIn: "Sign in",
  menuOpen: "Open menu",
  menuClose: "Close menu",
  websiteAria: "Website",
  footerWebsite: "Website",
  footerMore: "More",
  footerLegal: "Legal",
  footerTagline: "The bike lives here. You come back.",
  footerLegalLine: "Offline-first · GDPR · Web is Home, the app rides.",
  aboutFlowLine: "About FlowLine",
  faq: "FAQ",
  share: "Share",
  sampleProfile: "Sample profile",
  screensFlows: "Screens & flows",
  webVsApp: "Web vs. App",
  whatCameIn: "What came in",
  dataPrivacy: "Data & privacy",
  imprint: "Imprint",
  privacyPolicy: "Privacy",
  terms: "Terms",
  withdrawal: "Withdrawal",
  contact: "Contact",
  plan: "Plan",
  start: "Home",
  notFoundTitle: "This door does not exist",
  notFoundHint: "Empty stand. Back to Home, or one of the four doors.",
  marketingNotFoundTitle: "This page does not exist",
  marketingNotFoundHint:
    "No feed, no filler route. Back to the website or to Home.",
  maintenanceDue: (n) => `${n} services due`,
  newStimmenPlatz: "New Stimmen on Platz",
  profile: "Profile",
  fourDoors: "Four doors",
  tabOf: (index, count) => `Tab ${index} of ${count}`,
  emptyStand: "Empty stand",
  discoverApp: "Discover the app",
  loadApp: "Get the app",
  loadAppStore: "Download on the App Store",
  loadPlayStore: "Get it on Google Play",
  loading: "Loading…",
  anmeldenLocal: "Without an account, Home still works locally.",
  stillToHof: "To Home anyway",
};

const FR: WebChrome = {
  marketingNav: {
    "/produkt": "Produit",
    "/karten": "Cartes",
    "/regions": "Régions",
    "/guides": "Guides",
    "/community": "Community",
    "/pricing": "Prix",
    "/download": "App",
  },
  hofNav: {
    karte: "Carte",
    platz: "Platz",
    werkstatt: "Atelier",
  },
  toHof: "Vers Home",
  toWebsite: "Vers le site",
  arriveAtHof: "Arriver",
  signIn: "Se connecter",
  menuOpen: "Ouvrir le menu",
  menuClose: "Fermer le menu",
  websiteAria: "Site",
  footerWebsite: "Site",
  footerMore: "Plus",
  footerLegal: "Mentions",
  footerTagline: "Le vélo habite ici. Tu reviens.",
  footerLegalLine: "Offline-first · RGPD · Le web est Home, l'app roule.",
  aboutFlowLine: "À propos de FlowLine",
  faq: "FAQ",
  share: "Partager",
  sampleProfile: "Profil exemple",
  screensFlows: "Écrans et parcours",
  webVsApp: "Web vs. App",
  whatCameIn: "Ce qui est rentré",
  dataPrivacy: "Données et vie privée",
  imprint: "Mentions légales",
  privacyPolicy: "Confidentialité",
  terms: "CGV",
  withdrawal: "Rétractation",
  contact: "Contact",
  plan: "Planifier",
  start: "Accueil",
  notFoundTitle: "Cette porte n'existe pas",
  notFoundHint: "Stand vide. Retour à Home, ou une des quatre portes.",
  marketingNotFoundTitle: "Cette page n'existe pas",
  marketingNotFoundHint:
    "Pas de feed, pas de route de remplissage. Retour au site ou à Home.",
  maintenanceDue: (n) => `${n} entretiens dus`,
  newStimmenPlatz: "Nouvelles Stimmen sur le Platz",
  profile: "Profil",
  fourDoors: "Quatre portes",
  tabOf: (index, count) => `Onglet ${index} sur ${count}`,
  emptyStand: "Emplacement vide",
  discoverApp: "Découvrir l'app",
  loadApp: "Télécharger l'app",
  loadAppStore: "Télécharger dans l'App Store",
  loadPlayStore: "Télécharger sur Google Play",
  loading: "Chargement…",
  anmeldenLocal: "Sans compte, Home reste utilisable en local.",
  stillToHof: "Quand même vers Home",
};

const IT: WebChrome = {
  marketingNav: {
    "/produkt": "Prodotto",
    "/karten": "Carte",
    "/regions": "Regioni",
    "/guides": "Guide",
    "/community": "Community",
    "/pricing": "Prezzi",
    "/download": "App",
  },
  hofNav: {
    karte: "Mappa",
    platz: "Platz",
    werkstatt: "Officina",
  },
  toHof: "Verso Home",
  toWebsite: "Al sito",
  arriveAtHof: "Arriva al cortile",
  signIn: "Accedi",
  menuOpen: "Apri il menu",
  menuClose: "Chiudi il menu",
  websiteAria: "Sito",
  footerWebsite: "Sito",
  footerMore: "Altro",
  footerLegal: "Legale",
  footerTagline: "La bici vive qui. Tu torni.",
  footerLegalLine: "Offline-first · GDPR · Il web è Home, l'app pedala.",
  aboutFlowLine: "Su FlowLine",
  faq: "FAQ",
  share: "Condividi",
  sampleProfile: "Profilo esempio",
  screensFlows: "Schermate e flussi",
  webVsApp: "Web vs. App",
  whatCameIn: "Cosa è rientrato",
  dataPrivacy: "Dati e privacy",
  imprint: "Impressum",
  privacyPolicy: "Privacy",
  terms: "Termini",
  withdrawal: "Recesso",
  contact: "Contatto",
  plan: "Pianifica",
  start: "Inizio",
  notFoundTitle: "Questa porta non esiste",
  notFoundHint: "Stand vuoto. Torna a Home, o una delle quattro porte.",
  marketingNotFoundTitle: "Questa pagina non esiste",
  marketingNotFoundHint:
    "Niente feed, niente percorso di riempimento. Torna al sito o a Home.",
  maintenanceDue: (n) => `${n} manutenzioni in scadenza`,
  newStimmenPlatz: "Nuove Stimmen sul Platz",
  profile: "Profilo",
  fourDoors: "Quattro porte",
  tabOf: (index, count) => `Scheda ${index} di ${count}`,
  emptyStand: "Posto vuoto",
  discoverApp: "Scopri l'app",
  loadApp: "Scarica l'app",
  loadAppStore: "Scarica sull'App Store",
  loadPlayStore: "Scarica su Google Play",
  loading: "Caricamento…",
  anmeldenLocal: "Senza account, Home resta usabile in locale.",
  stillToHof: "Comunque verso Home",
};

const BY_LANG: Record<ChromeLang, WebChrome> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
};

export function webChrome(lang: ChromeLang): WebChrome {
  return BY_LANG[lang];
}
