/**
 * Redaktionelle Guides (SEO / Content-Hub) — Phase C.
 */

export type Guide = {
  slug: string;
  title: string;
  teaser: string;
  category: "planning" | "bike" | "ebike" | "setup" | "safety";
  readMin: number;
  /** Absätze (Markdown-light: plain text) */
  body: string[];
  relatedHrefs?: { href: string; label: string }[];
};

export const GUIDES: Guide[] = [
  {
    slug: "gravel-touren-planen",
    title: "Gravel-Touren planen: Belag, Profile und ehrliche Erwartungen",
    teaser:
      "Warum Gravel-Routing oft „halluziniert“ und wie du unter Planen mit Surface und Profilen bessere Touren baust.",
    category: "planning",
    readMin: 6,
    body: [
      "Gravel lebt von gemischten Oberflächen: Asphalt, Schotter, Forstwege. Viele Apps priorisieren Trails oder Straße zu stark — und schicken dich auf nicht existente Singletracks oder pure Autobahn-Alternativen.",
      "In FlowLine wählst du unter Planen das Profil „Gravel“. Das Routing bevorzugt tracks und unpaved, meidet aber harte MTB-Scales. Trotzdem: ohne Live-Engine (Demo-Modus) sind Linien Näherungen — prüfe kritische Abschnitte auf der Karte und speichere GPX.",
      "Tipp: plane am Desktop, speichere auf dem Platz, navigiere in der App. Für Mehrtages-Touren brich Etappen manuell (Start/Via/Ziel) und nutze flache Fernradwege als Backup.",
      "Community-Wunsch: transparente Surface-Layer und Warnungen statt stiller Umleitungen. Genau das ist unser Honesty-Ansatz — Demo klar labeln, Live-Status anzeigen.",
    ],
    relatedHrefs: [
      { href: "/planner", label: "Planen öffnen" },
      { href: "/discover?sport=gravel", label: "Gravel in Touren" },
      { href: "/regions/schwarzwald", label: "Region Schwarzwald" },
    ],
  },
  {
    slug: "rennrad-hoehenmeter",
    title: "Rennrad: Höhenmeter und Radwege realistisch einschätzen",
    teaser:
      "hm-Zahlen, Radinfrastruktur und warum flache Uferrouten und Kaiserstuhl-Runden unterschiedlich trainieren.",
    category: "planning",
    readMin: 5,
    body: [
      "Rennrad-Touren brauchen andere Filter als MTB: Asphaltanteil, Verkehr und kumulierte Höhenmeter zählen mehr als S-Skalen.",
      "Nutze unter Touren den Sport-Filter „Rennrad“ und Difficulty „Entspannt“ vs. „Sportlich“. Öffentliche Tour-Seiten zeigen Wetter und ein Höhenprofil — das Profil aus Metadaten ist eine Schätzung, bis du live routest.",
      "Bodensee-Südufer und Inn-Radweg eignen sich für lange, flache Tage. Kaiserstuhl und Alpenvorland liefern Intervalle. Speichere Varianten auf dem Platz und starte in der App.",
    ],
    relatedHrefs: [
      { href: "/discover?sport=road", label: "Rennrad Touren" },
      { href: "/tours/r-bodensee-road", label: "Bodensee-Tour" },
      { href: "/tours/idea-kaiserstuhl-road", label: "Kaiserstuhl" },
    ],
  },
  {
    slug: "ebike-reichweite",
    title: "E-Bike-Reichweite richtig einschätzen (Spannen, keine Punktwerte)",
    teaser:
      "Warum eine „80 km Anzeige“ lügt — und wie FlowLine mit Physik, Assist und Kalibrierung arbeitet.",
    category: "ebike",
    readMin: 7,
    body: [
      "Reichweite hängt von Gewicht, Wind, Temperatur, Höhenmetern, Reifendruck, Assist-Modus und Akkuzustand ab. Eine einzelne Kilometerzahl ist Marketing — seriöse Systeme zeigen Spannen.",
      "FlowLine Pro schätzt ein Band (kmLow–kmHigh) und kann sich über Rides kalibrieren. Bosch LDI liefert Live-SOC in der App — nicht im Browser.",
      "Plane anspruchsvolle Touren (z. B. E-MTB Alpin) mit Reserve: Ziel unter 70–80 % der oberen Spanne. Lade-Infrastruktur und Eco-Modi für den Rückweg mitdenken.",
      "Unter Touren siehst du bei E-Bikes Reichweiten-Hinweise zu Tour-Ideen. Navigation und Sensoren bleiben App-only.",
    ],
    relatedHrefs: [
      { href: "/pricing", label: "Pro & Reichweite" },
      { href: "/download", label: "App laden" },
      { href: "/garage", label: "E-Bike in der Werkstatt" },
    ],
  },
  {
    slug: "setup-koerpergewicht",
    title: "Setup nach Körpergewicht — ehrlich und als Ausgangspunkt",
    teaser:
      "OEM-Tabellen, SAG und Bracketing: wie du Federung einstellst, ohne Fake-Präzision.",
    category: "setup",
    readMin: 6,
    body: [
      "Druck und Rebound hängen vom Systemgewicht (Fahrer + Packs + Bike) und vom Federweg ab. Hersteller-Charts sind Startpunkte, keine Gesetze.",
      "In der Werkstatt findest du SAG-Hinweise und Setup-Versionen. Bracketing (Pro) vergleicht Serien systematisch — mit der Regel, dass „kein signifikanter Unterschied“ ehrlich angezeigt wird.",
      "Post-Ride-Feedback (≤3 Taps in der App) fließt in Vorschläge. Auf dem Desktop vertiefst du Setups und exportierst Service-Reports für die Werkstatt.",
    ],
    relatedHrefs: [
      { href: "/garage", label: "Werkstatt" },
      { href: "/pricing", label: "Pro für Bracketing" },
      { href: "/activities", label: "Aktivitäten" },
    ],
  },
  {
    slug: "wartung-intervalle",
    title: "Wartungsintervalle verständlich: Kette, Beläge, Gabel",
    teaser:
      "Kilometer vs. Stunden, Verschleißspannen und wann der Shop mit Kompat-Urteil hilft.",
    category: "bike",
    readMin: 5,
    body: [
      "Ketten: oft ab ~0,5 % Längung tauschen (Hersteller/Park Tool). Beläge: Restbelag und Geräusche. Gabel/Dämpfer: Service-Intervalle in Stunden oder Saisons.",
      "FlowLine speichert Intervalle pro Bike und warnt in der Werkstatt. Der Laden schlägt Ersatzteile vor — nur mit Consent und mit Kompatibilitäts-Urteil zum aktiven Bike.",
      "Road und City brauchen andere Schwerpunkte (Reifenpannen, Kette, Bremsen) als Enduro (Fahrwerk, Beläge, Reifen). Disziplin-Filter im Shop helfen.",
    ],
    relatedHrefs: [
      { href: "/garage?tab=maintenance", label: "Wartung" },
      { href: "/shop?job=replace", label: "Shop: ersetzen" },
    ],
  },
  {
    slug: "web-vs-app",
    title: "Website vs. App: was wo hingehört",
    teaser:
      "Komoot-Muster erklärt: Desktop plant, Smartphone navigiert — und warum der Browser kein GPS-Ride ist.",
    category: "safety",
    readMin: 4,
    body: [
      "Große Outdoor-Anbieter trennen klar: Web für Inspiration, SEO-Touren und Desktop-Planung; App für Offline, Turn-by-turn und Sensoren.",
      "FlowLine folgt dem: Touren, Planen, Tour-Seiten, Werkstatt und Platz im Browser. Live-Fahrt, BLE und Hintergrund-GPS nur nativ.",
      "Wenn du „Losfahren“ siehst, landest du auf der App-Bridge — speichere die Tour und öffne sie auf dem Gerät.",
    ],
    relatedHrefs: [
      { href: "/download", label: "App laden" },
      { href: "/produkt", label: "Produkt: Web vs. App" },
      { href: "/planner", label: "Planen" },
      { href: "/discover", label: "Karte" },
      { href: "/community", label: "Community / Platz" },
    ],
  },
  {
    slug: "hof-fuenf-tueren",
    title: "Der Hof: fünf Türen, kein Ride-Tab",
    teaser:
      "Warum FlowLine nicht wie ein Feed aussieht — und wozu Hof, Karte, Platz, Werkstatt und Laden da sind.",
    category: "safety",
    readMin: 4,
    body: [
      "Viele Rad-Apps stapeln Karten: Home, Explore, Activity, Club, Shop. FlowLine hat fünf Türen am Hof. Ride ist der oranger Knopf, nicht der sechste Tab.",
      "Der Hof ist der Stand: Himmel, eine Stunde vor dem Tor, Rausfahren. Die Karte zeigt Nähe und Planen. Der Platz hält Mappe, Stimmen und Gruppen. Die Werkstatt kennt das Rad. Der Laden ist die Tür zu Shopify — ohne zweite Kasse.",
      "Was im Browser fehlt, bleibt leer: kein Live-GPS, kein HUD, keine Dummy-Kilometer. Die App übernimmt Navigation, Offline und Sensoren.",
    ],
    relatedHrefs: [
      { href: "/home", label: "Zum Hof" },
      { href: "/produkt", label: "Produktkarte" },
      { href: "/ueber", label: "Über FlowLine" },
    ],
  },
  {
    slug: "platz-ohne-feed",
    title: "Platz statt Timeline: Stimmen, Mappe, Gruppen",
    teaser:
      "Community hängt an der Tour. Kein Feed auf dem Hof, keine Tracks in Kommentaren.",
    category: "safety",
    readMin: 4,
    body: [
      "Der Platz ist die Community-Tür. Dieselben Touren wie auf der Karte liegen in der Mappe. Stimmen sind Kurztext an der Tour — neu startet in Prüfung, Editorial ist gekennzeichnet.",
      "Sammlungen teilst du als Link. Wer den Link hat, legt die Touren in die eigene Mappe, ohne Account-Zwang. Gruppen laufen über Code vor dem Tor; Live-Pins gibt es nur im App-HUD und nur mit Opt-in.",
      "Public Profile ist bewusst: Handle, Sport, optional Fahrten — keine GPS-Spuren. Events und Clubs auf der Website sind redaktionell, kein RSVP-Fake.",
    ],
    relatedHrefs: [
      { href: "/library", label: "Zum Platz" },
      { href: "/community", label: "Community" },
      { href: "/guides/web-vs-app", label: "Web vs. App" },
    ],
  },
];

export function listGuides(): Guide[] {
  return GUIDES;
}

export function getGuide(slug: string): Guide | null {
  return GUIDES.find((g) => g.slug === slug) ?? null;
}

export function listGuideSlugs(): string[] {
  return GUIDES.map((g) => g.slug);
}

export const GUIDE_CATEGORY_LABEL: Record<Guide["category"], string> = {
  planning: "Planung",
  bike: "Bike & Wartung",
  ebike: "E-Bike",
  setup: "Setup",
  safety: "Plattform",
};
