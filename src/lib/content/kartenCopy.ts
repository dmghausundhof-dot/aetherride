/**
 * Coverage copy — Hof voice. Online tiles ≠ offline city packs.
 */

export const KARTEN_PAGE = {
  kicker: "Abdeckung",
  title: "Wo die Karte liegt — und wo ein Loch ist.",
  description:
    "Online-Basemap in DACH, Frankreich, Alpen-Süd, Benelux, Nord- und Mitteitalien, Süditalien, Katalonien/Pyrenäen und Südengland. Wege ab Zoom 10 in DACH, NL, BE und (wenn gebaut) FR/IT — Offline bleiben Stadt-Packs zum Routing.",
  lead: "Die Karte vor dem Tor ist kein Download von Europa. Online streamt MapLibre benannte Blätter. Ab Zoom 10 siehst du Radwege in DACH und den Benelux-Ländern, nicht nur Autobahn. Offline lädst du Stadt-Packs zum Routing. Was fehlt, bleibt leer.",
  onlineTitle: "Online: neun Blätter",
  onlineLead:
    "Mit Netz folgt die Karte dem Ausschnitt: das kleinste Blatt, das die Mitte trifft. Das sind Kacheln, kein Graph fürs ganze Land. Auf jedem Blatt liegt das passende Radnetz — OSM-Radrouten (EuroVelo, national, regional). Ab Zoom 10 liegen OSM-Wege (Pfad, Radweg, Track) in DACH und den Ländern Wege-Dateien (NL, BE, FR, IT), sobald sie auf dem CDN liegen.",
  pathsNote:
    "Der Überblick endet bei Zoom 11: in den Basemap-Kacheln gibt es keine Pfade. Signierte Radrouten liegen auf dem Blatt unter der Kamera. OSM-Wege streamen ab Zoom 10 aus den Länder-Dateien — Berlin, Amsterdam, Brüssel, Paris, Rom — und Stadt-Packs bleiben dichter, wo sie existieren. Asphalt, Schotter und Naturwege sind getrennt gefärbt, wenn OSM surface in der Overlay-Kachel liegt.",
  offlineTitle: "Offline: Städte, keine Länder",
  offlineLead:
    "In der App liegen Routing-Packs für Städte und Hausberge. Das ist Offline-Routing, kein Atlas-Download und keine Länderhülle. Envelope-Flächen ohne Graph bleiben online-only.",
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
    "Tippe ein Blatt. Das Radnetz folgt dem Blatt; ab Zoom 10 kommen Wege wo die Länder-Datei liegt.",
  waysHint:
    "Kein Stadt-Overlay hier. OSM-Wege ab Zoom 10 aus der Länder-Datei (DACH/NL/BE/FR/IT), sonst nur das Radnetz des Blatts.",
  attributionNote:
    "Kartenmaterial: OpenStreetMap-Mitwirkende, aufbereitet mit Protomaps. Relief: AWS Terrain / Mapzen. Kein Google-Layer.",
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
