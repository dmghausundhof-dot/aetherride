/**
 * Coverage copy — Hof voice. Online tiles ≠ offline city packs.
 */

export const KARTEN_PAGE = {
  kicker: "Abdeckung",
  title: "Wo die Karte liegt — und wo ein Loch ist.",
  description:
    "Online-Basemap in DACH, Frankreich, Alpen-Süd, Benelux, Norditalien, Katalonien/Pyrenäen und Südengland. Offline sind Stadt-Packs, keine Länderkarte.",
  lead: "Die Karte vor dem Tor ist kein Download von Europa. Online streamt MapLibre benannte Blätter. Offline lädst du Städte. Was fehlt, bleibt leer.",
  onlineTitle: "Online: sieben Blätter",
  onlineLead:
    "Mit Netz folgt die Karte dem Ausschnitt: das kleinste Blatt, das die Mitte trifft. Das sind Kacheln, kein Graph fürs ganze Land. Auf dem DACH-Blatt liegt das Radnetz — OSM-Radrouten (EuroVelo, national, regional), nicht jeder Pfad.",
  offlineTitle: "Offline: Städte, keine Länder",
  offlineLead:
    "In der App liegen Routing-Packs für Städte und Hausberge. Es gibt keine Komoot-Länderkarte und keine Hülle, die so tut.",
  holesTitle: "Löcher, ehrlich",
  holesLead:
    "Außerhalb der sieben Blätter bleibt die Fläche leer. Wir füllen sie nicht mit einem Fake-Globus.",
  holes: [
    "Skandinavien, Polen, Tschechien, der Balkan",
    "Iberien außer Katalonien/Pyrenäen — kein Spanien-Pack",
    "UK außer Südengland — kein Schottland, kein ganzes Königreich",
    "Italien südlich der Po-Ebene — Rom und der Süden fehlen",
    "Korsika, Irland, Übersee",
  ],
  splitNote:
    "Unter Regionen stehen Tour-Ideen mit Pin. Unter Karten steht, welches Blatt MapLibre wirklich streamt.",
  previewHint:
    "Tippe ein Blatt. Die Karte springt dorthin — derselbe Katalog wie in der App.",
  attributionNote:
    "Kartenmaterial: OpenStreetMap-Mitwirkende, aufbereitet mit Protomaps. Kein Google-Layer.",
} as const;

export function offlinePacksSentence(opts: {
  readyPacks: number | null;
  envelopeRegions: number;
}): string {
  const env = opts.envelopeRegions;
  if (opts.readyPacks != null && opts.readyPacks > 0) {
    const n = opts.readyPacks.toLocaleString("de-DE");
    return `${n} Stadt-Packs sind im Katalog ladbar. Dazu ${env.toLocaleString("de-DE")} benannte Flächen ohne Graph — dort bleibt die Karte online, es gibt nichts zum Herunterladen.`;
  }
  return `Stadt-Packs lädst du in der App aus dem Katalog. ${env.toLocaleString("de-DE")} benannte Flächen ohne Graph bleiben online — keine Länderhülle.`;
}
