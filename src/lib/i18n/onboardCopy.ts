/**
 * First-run sheet. Titles follow Flutter onboard* ARB.
 */
import type { BikeCategory } from "@/types";
import type { ChromeLang } from "./chromeLang";

export type OnboardCopy = {
  welcome: string;
  howYouRide: string;
  yourWeight: string;
  sportHint: string;
  weightHint: string;
  chosen: (label: string) => string;
  next: string;
  skip: string;
  later: string;
  blurbs: Partial<Record<BikeCategory, string>>;
};

const DE: OnboardCopy = {
  welcome: "Willkommen",
  howYouRide: "Wie fährst du?",
  yourWeight: "Dein Gewicht",
  sportHint: "Damit Routen und Setup zu dir passen.",
  weightHint: "Für SAG-Vorlagen und Reichweite — nur lokal, jederzeit änderbar.",
  chosen: (label) => `Gewählt: ${label}`,
  next: "Weiter",
  skip: "Überspringen",
  later: "Später einrichten",
  blurbs: {
    urban: "Alltag & Pendeln",
    gravel: "Schotter & Distanz",
    road: "Asphalt & Tempo",
    mtb_am: "Trails & Touren",
    mtb_enduro: "Steil & technisch",
    emtb: "Trail mit Assist",
    etrekking: "Touren mit Assist",
  },
};

const EN: OnboardCopy = {
  welcome: "Welcome",
  howYouRide: "How do you ride?",
  yourWeight: "Your weight",
  sportHint: "So routes and setup fit you.",
  weightHint: "For sag templates and range — local only, change anytime.",
  chosen: (label) => `Chosen: ${label}`,
  next: "Next",
  skip: "Skip",
  later: "Set up later",
  blurbs: {
    urban: "Everyday & commute",
    gravel: "Gravel & distance",
    road: "Tarmac & pace",
    mtb_am: "Trails & tours",
    mtb_enduro: "Steep & technical",
    emtb: "Trail with assist",
    etrekking: "Tours with assist",
  },
};

const FR: OnboardCopy = {
  welcome: "Bienvenue",
  howYouRide: "Comment tu roules ?",
  yourWeight: "Ton poids",
  sportHint: "Pour que parcours et setup te correspondent.",
  weightHint:
    "Pour les gabarits SAG et l’autonomie — local seulement, changeable à tout moment.",
  chosen: (label) => `Choisi : ${label}`,
  next: "Suivant",
  skip: "Passer",
  later: "Configurer plus tard",
  blurbs: {
    urban: "Quotidien & pendulaire",
    gravel: "Gravier & distance",
    road: "Asphalte & allure",
    mtb_am: "Trails & tours",
    mtb_enduro: "Penté et technique",
    emtb: "Trail avec assistance",
    etrekking: "Tours avec assistance",
  },
};

const IT: OnboardCopy = {
  welcome: "Benvenuto",
  howYouRide: "Come pedali?",
  yourWeight: "Il tuo peso",
  sportHint: "Perché percorsi e setup ti stiano.",
  weightHint: "Per sag e autonomia — solo locale, modificabile quando vuoi.",
  chosen: (label) => `Scelto: ${label}`,
  next: "Avanti",
  skip: "Salta",
  later: "Configura più tardi",
  blurbs: {
    urban: "Quotidiano e pendolare",
    gravel: "Ghiaia e distanza",
    road: "Asfalto e ritmo",
    mtb_am: "Trail e tour",
    mtb_enduro: "Ripido e tecnico",
    emtb: "Trail con assistenza",
    etrekking: "Tour con assistenza",
  },
};

const NL: OnboardCopy = {
  welcome: "Welkom",
  howYouRide: "Hoe rij je?",
  yourWeight: "Jouw gewicht",
  sportHint: "Zodat routes en setup bij je passen.",
  weightHint: "Voor SAG-sjablonen en actieradius — alleen lokaal, altijd te wijzigen.",
  chosen: (label) => `Gekozen: ${label}`,
  next: "Volgende",
  skip: "Overslaan",
  later: "Later instellen",
  blurbs: {
    urban: "Dagelijks & woon-werk",
    gravel: "Grind & afstand",
    road: "Asfalt & tempo",
    mtb_am: "Trails & tochten",
    mtb_enduro: "Steil & technisch",
    emtb: "Trail met ondersteuning",
    etrekking: "Tochten met ondersteuning",
  },
};

const BY: Record<ChromeLang, OnboardCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function onboardCopy(lang: ChromeLang = "de"): OnboardCopy {
  return BY[lang] ?? DE;
}
