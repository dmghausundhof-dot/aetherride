/**
 * Über-Seite — Markengeschichte, ohne erfundene Biografien oder TMG-Adresse.
 */

export const ABOUT_STORY = {
  kicker: "Warum ein Hof",
  title: "Nicht noch eine Timeline auf zwei Rädern.",
  paragraphs: [
    "Die meisten Rad-Apps stapeln Karten: Explore, Club, Shop, Activity. Irgendwann ist die Startseite ein Feed, die Fahrt eine Statistik, das Rad ein SKU. FlowLine kehrt das um. Der Hof ist der Stand. Vier Türen. Ein oranger Knopf.",
    "Web ist der Schreibtisch: Touren finden, planen, das Rad pflegen, eine Mappe teilen. Die App ist die Fahrt: HUD, GPS im Hintergrund, Offline-Packs, Sensoren, Uhr. Was im Browser nicht zuverlässig geht, wird nicht als Live-GPS im Tab verkauft.",
    "Der Name sagt die Haltung: Flow für den Schnitt, Line für die Linie. Outdoor · Cycling · Flow. Kein Leaderboard, das dich in der Feierabendrunde bewertet. Kein Demo-Kilometer, der den Hof voll erscheinen lässt.",
  ],
} as const;

export const ABOUT_REFUSALS: { title: string; body: string }[] = [
  {
    title: "Kein Feed",
    body: "Community hängt an der Tour. Stimmen sind Kurztext. Sammlungen sind Links. Gruppen haben einen Code — Live-Pins nur im App-HUD, mit Opt-in.",
  },
  {
    title: "Keine zweite Kasse",
    body: "Der Laden ist vorerst aus. Die Werkstatt bleibt für Fit und Pflege. Wir erfinden keine Anschrift für einen Checkout.",
  },
  {
    title: "Keine Attrappe",
    body: "Leere Flächen bleiben leer. Store-Buttons erscheinen, wenn Listings live sind. Routing-Linien entstehen beim Planen, nicht als Dummy-Alpen in Hamburg.",
  },
];

export const ABOUT_STATUS = {
  title: "Wer wir sind — und was noch fehlt",
  body: "FlowLine wird von dmg hausundhof gebaut. Kontakt läuft über E-Mail. Name und ladungsfähige Anschrift stehen im Impressum, sobald sie hinterlegt sind — nicht früher, nicht erfunden. Bis dahin ist die Anbieterkennzeichnung nach TMG unvollständig, und der Marktplatz-Checkout bleibt gesperrt.",
} as const;
