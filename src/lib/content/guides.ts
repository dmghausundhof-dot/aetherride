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
    title: "Der Hof: vier Türen, kein Ride-Tab",
    teaser:
      "Warum FlowLine nicht wie ein Feed aussieht — und wozu Hof, Karte, Platz und Werkstatt da sind.",
    category: "safety",
    readMin: 4,
    body: [
      "Viele Rad-Apps stapeln Karten: Home, Explore, Activity, Club, Shop. FlowLine hat vier Türen am Hof. Ride ist der orange Knopf, nicht der fünfte Tab. Der Laden ist keine Tür in der Leiste.",
      "Der Hof ist der Stand: Himmel, eine Stunde vor dem Tor, Rausfahren. Die Karte zeigt Nähe und Planen. Der Platz hält Mappe, Stimmen und Gruppen. Die Werkstatt kennt das Rad — und öffnet die Tür zu Shopify, wenn ein Teil zu diesem Rad passt.",
      "Was im Browser fehlt, bleibt leer: kein Live-GPS, kein HUD, keine Dummy-Kilometer. Die App übernimmt Navigation, Offline und Sensoren.",
    ],
    relatedHrefs: [
      { href: "/home", label: "Zum Hof" },
      { href: "/produkt", label: "Produktkarte" },
      { href: "/ueber", label: "Über FlowLine" },
      { href: "/guides/laden-ohne-zweite-kasse", label: "Der Laden" },
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
      { href: "/share", label: "Teilen" },
      { href: "/u/mara_road", label: "Beispiel-Profil" },
      { href: "/guides/teilen-per-link", label: "Guide: Teilen" },
    ],
  },
  {
    slug: "teilen-per-link",
    title: "Teilen per Link: Tour, Mappe, kein Feed",
    teaser:
      "Wer den Link hat, legt die Tour in die eigene Mappe. Kein Account-Zwang, keine stillen GPS-Anhänge.",
    category: "safety",
    readMin: 4,
    body: [
      "FlowLine teilt nicht über eine Timeline. Eine Tour oder eine Mappe wird zum Link. Wer ihn öffnet, kann die Idee lokal übernehmen — ohne Konto, ohne Follow, ohne Heatmap.",
      "Der Tour-Link trägt Name und Stats. Eine Spur steckt nur drin, wenn sie bewusst im Token liegt; Katalog-Beispiele bleiben Pin und Text. Die Mappe sammelt mehrere Katalog-Touren, immer ohne Tracks.",
      "Stimmen und Gruppen bleiben am Platz. Public Profiles sind Opt-in und speichern keine Roh-GPS-Daten. Live-Standort vor dem Tor gibt es nicht.",
    ],
    relatedHrefs: [
      { href: "/share", label: "So teilen" },
      { href: "/share/t/demo", label: "Beispiel-Tour" },
      { href: "/share/c/demo", label: "Beispiel-Mappe" },
      { href: "/community", label: "Community" },
    ],
  },
  {
    slug: "laden-ohne-zweite-kasse",
    title: "Der Laden: Tür zu Shopify, keine zweite Kasse",
    teaser:
      "Teile und Merch liegen hinter einer Tür. Kaufvertrag und Checkout entstehen bei Shopify — oder gar nicht, solange das Impressum fehlt.",
    category: "safety",
    readMin: 4,
    body: [
      "Der Laden ist keine fünfte Tür in der Leiste. Katalog und Fit kommen aus der Werkstatt, gebunden an Slot und Rad. Die Kasse liegt bei Shopify — es gibt keinen Warenkorb, der hier kassiert.",
      "Ohne hinterlegtes Impressum (Name und ladungsfähige Anschrift) bleibt der Checkout gesperrt. Das ist Absicht: wir erfinden keine TMG-Angaben, damit etwas „kaufen“ heißt.",
      "Merchandise wird nicht über den Fit zum Rad gefiltert. Ersatzteile schon: Kategorie und Laufrad zum abgestellten Rad, keine erfundenen SKUs. Store-Listings der App sind unabhängig davon und stehen, sobald sie live sind.",
    ],
    relatedHrefs: [
      { href: "/shop", label: "Zum Laden" },
      { href: "/garage", label: "Werkstatt" },
      { href: "/legal/impressum", label: "Impressum" },
      { href: "/produkt", label: "Produktkarte" },
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

export const GUIDE_CATEGORY_ORDER: Guide["category"][] = [
  "planning",
  "safety",
  "ebike",
  "setup",
  "bike",
];

export function listGuidesGrouped(): {
  category: Guide["category"];
  label: string;
  guides: Guide[];
}[] {
  return GUIDE_CATEGORY_ORDER.map((category) => ({
    category,
    label: GUIDE_CATEGORY_LABEL[category],
    guides: GUIDES.filter((g) => g.category === category),
  })).filter((group) => group.guides.length > 0);
}

function guidesFromSlugs(slugs: string[], limit: number): Guide[] {
  const seen = new Set<string>();
  const out: Guide[] = [];
  for (const slug of slugs) {
    const g = getGuide(slug);
    if (!g || seen.has(g.slug)) continue;
    seen.add(g.slug);
    out.push(g);
    if (out.length >= limit) break;
  }
  return out;
}

export function relatedGuidesForTour(input: {
  id: string;
  primaryCategory: string;
}): Guide[] {
  const sport = input.primaryCategory;
  const slugs: string[] = ["web-vs-app"];
  if (sport.includes("gravel")) slugs.push("gravel-touren-planen");
  else if (sport === "road") slugs.push("rennrad-hoehenmeter");
  else if (sport === "emtb" || sport === "etrekking") slugs.push("ebike-reichweite");
  else if (sport.startsWith("mtb") || sport === "dh") slugs.push("gravel-touren-planen");
  else slugs.push("hof-fuenf-tueren");
  slugs.push("platz-ohne-feed", "teilen-per-link");
  return guidesFromSlugs(slugs, 3);
}

export function relatedGuidesForRegion(sports: string[]): Guide[] {
  const slugs: string[] = [];
  if (sports.includes("road")) slugs.push("rennrad-hoehenmeter");
  if (sports.includes("gravel") || sports.includes("mtb")) {
    slugs.push("gravel-touren-planen");
  }
  if (sports.includes("ebike")) slugs.push("ebike-reichweite");
  slugs.push(
    "teilen-per-link",
    "platz-ohne-feed",
    "laden-ohne-zweite-kasse",
    "web-vs-app",
  );
  return guidesFromSlugs(slugs, 4);
}
