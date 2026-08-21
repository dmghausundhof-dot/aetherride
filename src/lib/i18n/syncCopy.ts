/**
 * Web sync conflict chrome. Counts stay Bikes/Rides; Touren/Sammlungen map.
 */
import type { ChromeLang } from "./chromeLang";

export type SyncCopy = {
  title: string;
  hint: string;
  cloud: string;
  device: string;
  keepCloud: string;
  forceDevice: string;
  later: string;
  empty: string;
  tours: string;
  collections: string;
  pulled: (summary: string) => string;
  pushed: (summary: string) => string;
  current: string;
  conflict: string;
  solvedCloud: (summary: string) => string;
  solvedLocal: (when: string) => string;
  failed: string;
  resolveFailed: string;
};

const DE: SyncCopy = {
  title: "Sync-Konflikt",
  hint: "Cloud und dieses Gerät haben beide Änderungen. Wähle, welche Version gilt.",
  cloud: "Cloud",
  device: "Dieses Gerät",
  keepCloud: "Cloud behalten",
  forceDevice: "Gerät erzwingen",
  later: "Später",
  empty: "leer",
  tours: "Touren",
  collections: "Sammlungen",
  pulled: (s) => `Sync: Cloud übernommen (${s}).`,
  pushed: (s) => `Sync: Dieses Gerät hochgeladen (${s}).`,
  current: "Sync: bereits aktuell.",
  conflict: "Konflikt: Cloud und dieses Gerät haben unterschiedliche Stände.",
  solvedCloud: (s) => `Konflikt gelöst: Cloud behalten (${s}).`,
  solvedLocal: (when) =>
    `Konflikt gelöst: Gerät erzwungen hochgeladen (${when}).`,
  failed: "Sync fehlgeschlagen",
  resolveFailed: "Auflösung fehlgeschlagen",
};

const EN: SyncCopy = {
  title: "Sync conflict",
  hint: "Cloud and this device both changed. Pick which version stands.",
  cloud: "Cloud",
  device: "This device",
  keepCloud: "Keep cloud",
  forceDevice: "Force this device",
  later: "Later",
  empty: "empty",
  tours: "tours",
  collections: "collections",
  pulled: (s) => `Sync: took the cloud (${s}).`,
  pushed: (s) => `Sync: uploaded this device (${s}).`,
  current: "Sync: already current.",
  conflict: "Conflict: cloud and this device differ.",
  solvedCloud: (s) => `Conflict resolved: kept cloud (${s}).`,
  solvedLocal: (when) =>
    `Conflict resolved: forced this device up (${when}).`,
  failed: "Sync failed",
  resolveFailed: "Could not resolve",
};

const FR: SyncCopy = {
  title: "Conflit de sync",
  hint: "Le cloud et cet appareil ont tous les deux changé. Choisis quelle version compte.",
  cloud: "Cloud",
  device: "Cet appareil",
  keepCloud: "Garder le cloud",
  forceDevice: "Forcer cet appareil",
  later: "Plus tard",
  empty: "vide",
  tours: "parcours",
  collections: "collections",
  pulled: (s) => `Sync : cloud repris (${s}).`,
  pushed: (s) => `Sync : cet appareil envoyé (${s}).`,
  current: "Sync : déjà à jour.",
  conflict: "Conflit : le cloud et cet appareil diffèrent.",
  solvedCloud: (s) => `Conflit résolu : cloud gardé (${s}).`,
  solvedLocal: (when) =>
    `Conflit résolu : appareil forcé en ligne (${when}).`,
  failed: "Sync échoué",
  resolveFailed: "Résolution échouée",
};

const IT: SyncCopy = {
  title: "Conflitto di sync",
  hint: "Cloud e questo dispositivo hanno entrambi modifiche. Scegli quale versione vale.",
  cloud: "Cloud",
  device: "Questo dispositivo",
  keepCloud: "Tieni il cloud",
  forceDevice: "Forza questo dispositivo",
  later: "Più tardi",
  empty: "vuoto",
  tours: "percorsi",
  collections: "raccolte",
  pulled: (s) => `Sync: preso il cloud (${s}).`,
  pushed: (s) => `Sync: caricato questo dispositivo (${s}).`,
  current: "Sync: già aggiornato.",
  conflict: "Conflitto: cloud e questo dispositivo differiscono.",
  solvedCloud: (s) => `Conflitto risolto: tenuto il cloud (${s}).`,
  solvedLocal: (when) =>
    `Conflitto risolto: dispositivo forzato in upload (${when}).`,
  failed: "Sync non riuscito",
  resolveFailed: "Risoluzione non riuscita",
};

const NL: SyncCopy = {
  title: "Sync-conflict",
  hint: "Cloud en dit apparaat hebben allebei wijzigingen. Kies welke versie geldt.",
  cloud: "Cloud",
  device: "Dit apparaat",
  keepCloud: "Cloud houden",
  forceDevice: "Apparaat forceren",
  later: "Later",
  empty: "leeg",
  tours: "tochten",
  collections: "verzamelingen",
  pulled: (s) => `Sync: cloud overgenomen (${s}).`,
  pushed: (s) => `Sync: dit apparaat geüpload (${s}).`,
  current: "Sync: al actueel.",
  conflict: "Conflict: cloud en dit apparaat verschillen.",
  solvedCloud: (s) => `Conflict opgelost: cloud gehouden (${s}).`,
  solvedLocal: (when) =>
    `Conflict opgelost: apparaat geforceerd geüpload (${when}).`,
  failed: "Sync mislukt",
  resolveFailed: "Oplossen mislukt",
};

const BY: Record<ChromeLang, SyncCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function syncCopy(lang: ChromeLang = "de"): SyncCopy {
  return BY[lang] ?? DE;
}
