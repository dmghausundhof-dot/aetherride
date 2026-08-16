/**
 * Coverage copy — Hof voice. Online tiles ≠ offline city packs.
 */

export const KARTEN_PAGE = {
  kicker: "Abdeckung",
  title: "Wo die Karte liegt — und wo ein Loch ist.",
  description:
    "Online-Basemap in DACH, Frankreich, Alpen-Süd, Benelux, Nord- und Mitteitalien, Süditalien, Katalonien/Pyrenäen und Südengland. In DACH liegen Atlas und Wege für alle. Offline sind Stadt-Packs zum Routing, keine Länderkarte.",
  lead: "Die Karte vor dem Tor ist kein Download von Europa. Online streamt MapLibre benannte Blätter. In DACH siehst du das Radnetz und ab Zoom 12 Wege — nicht nur in zehn Städten. Offline lädst du Stadt-Packs zum Routing. Was fehlt, bleibt leer.",
  onlineTitle: "Online: neun Blätter",
  onlineLead:
    "Mit Netz folgt die Karte dem Ausschnitt: das kleinste Blatt, das die Mitte trifft. Das sind Kacheln, kein Graph fürs ganze Land. Auf jedem Blatt liegt das passende Radnetz — OSM-Radrouten (EuroVelo, national, regional), nicht das DACH-Netz über Paris. Ab Zoom 12 liegen OSM-Wege (Pfad, Radweg, Track) im ganzen DACH-Ausschnitt.",
  pathsNote:
    "Der Überblick endet bei Zoom 11: in den Kacheln gibt es keine Pfade. Signierte Radrouten liegen auf dem Blatt unter der Kamera. OSM-Wege streamen ab Zoom 12 überall im DACH-Blatt — Berlin, Wien, Zürich, Vaduz, nicht nur Heidelberg. Stadt-Packs bleiben dichter, wo sie existieren.",
  offlineTitle: "Offline: Städte, keine Länder",
  offlineLead:
    "In der App liegen Routing-Packs für Städte und Hausberge. Das ist Offline-Routing, kein Atlas-Download und keine Länderhülle. Es gibt keine 33 Länder-Downloads.",
  holesTitle: "Löcher, ehrlich",
  holesLead:
    "Außerhalb der neun Blätter bleibt die Fläche leer. Wir füllen sie nicht mit einem Fake-Globus.",
  holes: [
    "Skandinavien, Polen, der Balkan",
    "Iberien außer Katalonien/Pyrenäen — kein Spanien-Pack",
    "UK außer Südengland — kein Schottland, kein ganzes Königreich",
    "Sizilien, Sardinien, Korsika — kein Insel-Italien",
    "Irland, Übersee",
  ],
  splitNote:
    "Unter Regionen stehen Tour-Ideen mit Pin. Unter Karten steht, welches Blatt MapLibre wirklich streamt.",
  previewHint:
    "Tippe ein Blatt. Das Radnetz folgt dem Blatt; auf DACH zeigt Zoom 12 Wege im ganzen Ausschnitt.",
  waysHint:
    "Kein Overlay an dieser Stelle. OSM-Wege gibt es ab Zoom 12 auf dem DACH-Blatt. Das Radnetz folgt dem Blatt darunter.",
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
