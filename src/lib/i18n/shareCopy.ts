import type { ChromeLang } from "./chromeLang";

export type ShareCopy = {
  kicker: string;
  title: string;
  lead: string;
  tourTitle: string;
  tourBody: string;
  openSampleTour: string;
  mappeTitle: string;
  mappeBody: string;
  openSampleMappe: string;
  step1Before: string;
  step1Regions: string;
  step1Mid: string;
  step1After: string;
  step2: string;
  step3: string;
  foot: string;
  guideShare: string;
  invalid: string;
  invalidTour: string;
  invalidCollection: string;
  howToShare: string;
  toPlatz: string;
  demoLink: string;
  sharedTour: string;
  by: (author: string) => string;
  trackInLink: string;
  catalogNoTrack: string;
  nameStatsOnly: string;
  openCatalog: string;
  inMappe: string;
  adoptMappe: string;
  savesTour: string;
  savesCollection: string;
  loadingCollection: string;
  demoMappe: string;
  sharedCollection: string;
  toursNoGps: (n: number) => string;
  open: string;
  sharedSuffix: (name: string) => string;
};

const DE: ShareCopy = {
  kicker: "Teilen",
  title: "Link statt Feed",
  lead: "Wer den Link hat, kann die Tour in die eigene Mappe legen. Es gibt keine Timeline und keine stillen GPS-Anhänge.",
  tourTitle: "Tour-Link",
  tourBody:
    "Eine Tour, Name und Stats. Eine Spur nur, wenn sie bewusst im Link steckt — sonst bleibt’s Pin und Katalog.",
  openSampleTour: "Beispiel-Tour öffnen →",
  mappeTitle: "Mappe",
  mappeBody:
    "Mehrere Katalog-Touren als Sammlung. Immer ohne Tracks. Anlegen auf dem Platz.",
  openSampleMappe: "Beispiel-Mappe öffnen →",
  step1Before: "Tour auf der",
  step1Regions: "Regionen-Seite",
  step1Mid: "oder im",
  step1After: " öffnen.",
  step2: "Link kopieren. Der Empfänger braucht kein Konto.",
  step3: "Übernehmen legt die Tour lokal in diesem Browser in die Mappe.",
  foot: "Gruppen und Stimmen bleiben am Platz. Public Profiles sind Opt-in.",
  guideShare: "Guide: Teilen",
  invalid: "Link ungültig",
  invalidTour:
    "Die geteilte Tour konnte nicht gelesen werden. Kein Feed, kein stiller Track.",
  invalidCollection: "Die geteilte Sammlung konnte nicht gelesen werden.",
  howToShare: "So teilen",
  toPlatz: "Zum Platz",
  demoLink: "Beispiel-Link",
  sharedTour: "Geteilte Tour",
  by: (author) => `Von ${author}`,
  trackInLink: "Der Link enthält eine vereinfachte Spur.",
  catalogNoTrack: "Kein Extra-Track im Link — Katalog-Tour, schon freigegeben.",
  nameStatsOnly: "Nur Name und Stats im Link — kein GPS-Track.",
  openCatalog: "Im Katalog öffnen",
  inMappe: "In der Mappe",
  adoptMappe: "In die Mappe übernehmen",
  savesTour: "Speichert die Tour lokal in diesem Browser.",
  savesCollection: "Speichert die Sammlung lokal in diesem Browser.",
  loadingCollection: "Sammlung wird geladen …",
  demoMappe: "Beispiel-Mappe",
  sharedCollection: "Geteilte Sammlung",
  toursNoGps: (n) => `${n} Touren · ohne GPS-Tracks`,
  open: "Öffnen",
  sharedSuffix: (name) => `${name} (geteilt)`,
};

const EN: ShareCopy = {
  kicker: "Share",
  title: "A link, not a feed",
  lead: "Whoever has the link can put the tour into their own Mappe. There is no timeline and no silent GPS attachments.",
  tourTitle: "Tour link",
  tourBody:
    "One tour, name and stats. A trace only if it is deliberately in the link — otherwise it stays pin and catalogue.",
  openSampleTour: "Open sample tour →",
  mappeTitle: "Mappe",
  mappeBody:
    "Several catalogue tours as a collection. Always without tracks. Create it on Platz.",
  openSampleMappe: "Open sample Mappe →",
  step1Before: "Open a tour on the",
  step1Regions: "regions page",
  step1Mid: "or on",
  step1After: ".",
  step2: "Copy the link. The recipient needs no account.",
  step3: "Adopt puts the tour into Die Mappe locally in this browser.",
  foot: "Groups and Stimmen stay on Platz. Public profiles are opt-in.",
  guideShare: "Guide: Share",
  invalid: "Invalid link",
  invalidTour:
    "The shared tour could not be read. No feed, no silent track.",
  invalidCollection: "The shared collection could not be read.",
  howToShare: "How to share",
  toPlatz: "To Platz",
  demoLink: "Sample link",
  sharedTour: "Shared tour",
  by: (author) => `From ${author}`,
  trackInLink: "The link contains a simplified trace.",
  catalogNoTrack: "No extra track in the link — catalogue tour, already shared.",
  nameStatsOnly: "Only name and stats in the link — no GPS track.",
  openCatalog: "Open in catalogue",
  inMappe: "In Die Mappe",
  adoptMappe: "Add to Die Mappe",
  savesTour: "Saves the tour locally in this browser.",
  savesCollection: "Saves the collection locally in this browser.",
  loadingCollection: "Loading collection…",
  demoMappe: "Sample Mappe",
  sharedCollection: "Shared collection",
  toursNoGps: (n) => `${n} tours · no GPS tracks`,
  open: "Open",
  sharedSuffix: (name) => `${name} (shared)`,
};

const FR: ShareCopy = {
  kicker: "Partager",
  title: "Un lien, pas un fil",
  lead: "Qui a le lien peut mettre la sortie dans sa propre Mappe. Pas de fil, pas de pièces GPS silencieuses.",
  tourTitle: "Lien de sortie",
  tourBody:
    "Une sortie, nom et stats. Une trace seulement si elle est volontairement dans le lien — sinon ça reste épingle et catalogue.",
  openSampleTour: "Ouvrir une sortie exemple →",
  mappeTitle: "Mappe",
  mappeBody:
    "Plusieurs sorties catalogue en collection. Toujours sans traces. À créer sur Platz.",
  openSampleMappe: "Ouvrir une Mappe exemple →",
  step1Before: "Ouvre une sortie sur la",
  step1Regions: "page régions",
  step1Mid: "ou sur",
  step1After: ".",
  step2: "Copie le lien. Le destinataire n’a pas besoin de compte.",
  step3: "Reprendre met la sortie dans Die Mappe, en local dans ce navigateur.",
  foot: "Groupes et Stimmen restent sur Platz. Les profils publics sont opt-in.",
  guideShare: "Guide : Partager",
  invalid: "Lien invalide",
  invalidTour:
    "La sortie partagée n’a pas pu être lue. Pas de fil, pas de trace silencieuse.",
  invalidCollection: "La collection partagée n’a pas pu être lue.",
  howToShare: "Comment partager",
  toPlatz: "Vers Platz",
  demoLink: "Lien exemple",
  sharedTour: "Sortie partagée",
  by: (author) => `De ${author}`,
  trackInLink: "Le lien contient une trace simplifiée.",
  catalogNoTrack: "Pas de trace extra dans le lien — sortie catalogue, déjà partagée.",
  nameStatsOnly: "Seulement nom et stats dans le lien — pas de trace GPS.",
  openCatalog: "Ouvrir dans le catalogue",
  inMappe: "Dans Die Mappe",
  adoptMappe: "Mettre dans Die Mappe",
  savesTour: "Enregistre la sortie en local dans ce navigateur.",
  savesCollection: "Enregistre la collection en local dans ce navigateur.",
  loadingCollection: "Collection en cours de chargement…",
  demoMappe: "Mappe exemple",
  sharedCollection: "Collection partagée",
  toursNoGps: (n) => `${n} sorties · sans traces GPS`,
  open: "Ouvrir",
  sharedSuffix: (name) => `${name} (partagé)`,
};

const IT: ShareCopy = {
  kicker: "Condividi",
  title: "Un link, non un feed",
  lead: "Chi ha il link può mettere l’uscita nella propria Mappe. Niente timeline e niente allegati GPS silenziosi.",
  tourTitle: "Link uscita",
  tourBody:
    "Un’uscita, nome e stats. Una traccia solo se sta volutamente nel link — altrimenti resta pin e catalogo.",
  openSampleTour: "Apri uscita esempio →",
  mappeTitle: "Mappe",
  mappeBody:
    "Più uscite catalogo come raccolta. Sempre senza tracce. Si crea sul Platz.",
  openSampleMappe: "Apri Mappe esempio →",
  step1Before: "Apri un’uscita sulla",
  step1Regions: "pagina regioni",
  step1Mid: "o sul",
  step1After: ".",
  step2: "Copia il link. Il destinatario non serve un account.",
  step3: "Prendi mette l’uscita in Die Mappe, in locale in questo browser.",
  foot: "Gruppi e Stimmen restano sul Platz. I profili pubblici sono opt-in.",
  guideShare: "Guida: Condividi",
  invalid: "Link non valido",
  invalidTour:
    "L’uscita condivisa non si è potuta leggere. Niente feed, niente traccia silenziosa.",
  invalidCollection: "La raccolta condivisa non si è potuta leggere.",
  howToShare: "Come condividere",
  toPlatz: "Al Platz",
  demoLink: "Link esempio",
  sharedTour: "Uscita condivisa",
  by: (author) => `Da ${author}`,
  trackInLink: "Il link contiene una traccia semplificata.",
  catalogNoTrack: "Nessuna traccia extra nel link — uscita catalogo, già condivisa.",
  nameStatsOnly: "Solo nome e stats nel link — nessuna traccia GPS.",
  openCatalog: "Apri nel catalogo",
  inMappe: "In Die Mappe",
  adoptMappe: "Metti in Die Mappe",
  savesTour: "Salva l’uscita in locale in questo browser.",
  savesCollection: "Salva la raccolta in locale in questo browser.",
  loadingCollection: "Raccolta in caricamento…",
  demoMappe: "Mappe esempio",
  sharedCollection: "Raccolta condivisa",
  toursNoGps: (n) => `${n} uscite · senza tracce GPS`,
  open: "Apri",
  sharedSuffix: (name) => `${name} (condiviso)`,
};

const NL: ShareCopy = {
  kicker: "Delen",
  title: "Een link, geen feed",
  lead: "Wie de link heeft, kan de tocht in de eigen Mappe leggen. Er is geen timeline en geen stille GPS-bijlagen.",
  tourTitle: "Tochtlink",
  tourBody:
    "Eén tocht, naam en stats. Een trace alleen als die bewust in de link zit — anders blijft het pin en catalogus.",
  openSampleTour: "Voorbeeldtocht openen →",
  mappeTitle: "Mappe",
  mappeBody:
    "Meerdere catalogustochten als collectie. Altijd zonder tracks. Aanmaken op Platz.",
  openSampleMappe: "Voorbeeld-Mappe openen →",
  step1Before: "Open een tocht op de",
  step1Regions: "regiopagina",
  step1Mid: "of op",
  step1After: ".",
  step2: "Kopieer de link. De ontvanger heeft geen account nodig.",
  step3: "Overnemen legt de tocht lokaal in deze browser in Die Mappe.",
  foot: "Groepen en Stimmen blijven op Platz. Publieke profielen zijn opt-in.",
  guideShare: "Guide: Delen",
  invalid: "Link ongeldig",
  invalidTour:
    "De gedeelde tocht kon niet worden gelezen. Geen feed, geen stille track.",
  invalidCollection: "De gedeelde collectie kon niet worden gelezen.",
  howToShare: "Zo deel je",
  toPlatz: "Naar Platz",
  demoLink: "Voorbeeldlink",
  sharedTour: "Gedeelde tocht",
  by: (author) => `Van ${author}`,
  trackInLink: "De link bevat een vereenvoudigde trace.",
  catalogNoTrack: "Geen extra track in de link — catalogustocht, al gedeeld.",
  nameStatsOnly: "Alleen naam en stats in de link — geen GPS-track.",
  openCatalog: "In de catalogus openen",
  inMappe: "In Die Mappe",
  adoptMappe: "In Die Mappe leggen",
  savesTour: "Slaat de tocht lokaal op in deze browser.",
  savesCollection: "Slaat de collectie lokaal op in deze browser.",
  loadingCollection: "Collectie wordt geladen…",
  demoMappe: "Voorbeeld-Mappe",
  sharedCollection: "Gedeelde collectie",
  toursNoGps: (n) => `${n} tochten · zonder GPS-tracks`,
  open: "Openen",
  sharedSuffix: (name) => `${name} (gedeeld)`,
};

const BY_LANG: Record<ChromeLang, ShareCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function shareCopy(lang: ChromeLang): ShareCopy {
  return BY_LANG[lang];
}
