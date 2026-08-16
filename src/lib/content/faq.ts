/**
 * Public FAQ — rider-facing, no invented legal identity or store claims.
 */

export const FAQ_ITEMS: {
  id: string;
  q: string;
  a: string;
  links?: { href: string; label: string }[];
}[] = [
  {
    id: "was",
    q: "Was ist FlowLine?",
    a: "FlowLine ist Outdoor Cycling mit Hof: planen, pflegen, teilen im Browser — fahren in der App. Fünf Türen, kein Feed, keine zweite Kasse.",
    links: [
      { href: "/produkt", label: "Produktkarte" },
      { href: "/ueber", label: "Über FlowLine" },
    ],
  },
  {
    id: "web-app",
    q: "Was läuft im Browser, was in der App?",
    a: "Im Web: Hof, Karte, Planen, Platz, Werkstatt, Laden-Tür. In der App: Ride-HUD, Offline-Packs, GPS-Aufzeichnung, Sensoren und Uhr. Live-Navigation im Tab gibt es nicht.",
    links: [
      { href: "/guides/web-vs-app", label: "Guide: Web vs. App" },
      { href: "/download", label: "App" },
    ],
  },
  {
    id: "konto",
    q: "Brauche ich ein Konto?",
    a: "Nein. Der Hof bleibt lokal nutzbar. Ein Konto synchronisiert mit der App und schaltet Pro im Profil frei.",
    links: [{ href: "/anmelden", label: "Anmelden" }],
  },
  {
    id: "preise",
    q: "Was kostet Pro?",
    a: "Free plant und navigiert in der App. Pro kostet 6,99 €/Monat oder 59,99 €/Jahr — Multi-Bike, Bracketing, Reichweiten-Spannen, höhere Chat-Limits. Checkout im Profil (Stripe) bzw. Play Billing in Android. Kein Abo mitten in der Tour.",
    links: [{ href: "/pricing", label: "Preise" }],
  },
  {
    id: "community",
    q: "Gibt es eine Community / einen Feed?",
    a: "Community hängt an der Tour: Stimmen, Mappe-Links, Gruppen-Codes, optionales Public Profile. Es gibt keine Timeline auf dem Hof, kein Leaderboard und kein Live-GPS vor dem Tor.",
    links: [
      { href: "/community", label: "Community" },
      { href: "/library", label: "Platz" },
    ],
  },
  {
    id: "teilen",
    q: "Wie teile ich eine Tour oder eine Mappe?",
    a: "Per Link, nicht per Feed. Wer den Link hat, legt die Tour lokal in die Mappe — ohne Account-Zwang. Stimmen und Gruppen bleiben am Platz. Public Profiles sind Opt-in und tragen keine GPS-Spuren.",
    links: [
      { href: "/share", label: "Teilen" },
      { href: "/share/t/demo", label: "Beispiel-Tour" },
      { href: "/guides/teilen-per-link", label: "Guide: Teilen" },
    ],
  },
  {
    id: "shop",
    q: "Kann ich hier Ersatzteile kaufen?",
    a: "Der Laden ist eine Tür zu Shopify. Es gibt keinen zweiten Warenkorb und keine Kasse in FlowLine. Ohne hinterlegtes Impressum bleibt der Checkout gesperrt.",
    links: [
      { href: "/shop", label: "Laden" },
      { href: "/guides/laden-ohne-zweite-kasse", label: "Guide: Laden" },
      { href: "/legal/impressum", label: "Impressum" },
    ],
  },
  {
    id: "regionen",
    q: "Sind die Touren echte GPS-Spuren?",
    a: "Öffentliche Tour-Seiten sind redaktionelle Ideen mit Pin. Die Linie entsteht beim Planen über das Routing-Profil — keine garantierte GPX-Datei und keine Dummy-Alpen, wenn du in Hamburg stehst.",
    links: [
      { href: "/regions", label: "Regionen" },
      { href: "/discover", label: "Karte" },
    ],
  },
  {
    id: "daten",
    q: "Was passiert mit meinen Daten?",
    a: "Offline-First, DSGVO, Export im Profil. Stimmen ohne Track-Anhang. Public Profile nur mit Opt-in. Sync und Navigation bleiben frei.",
    links: [
      { href: "/legal/datenschutz", label: "Datenschutz" },
    ],
  },
  {
    id: "app-stores",
    q: "Wo lade ich die App?",
    a: "Store-Links stehen, sobald die Listings live sind. Bis dahin laufen Hof, Karte, Platz und Werkstatt im Browser. HUD, Offline und Sensoren kommen mit der nativen App.",
    links: [{ href: "/download", label: "App" }],
  },
  {
    id: "kontakt",
    q: "Wie erreiche ich euch?",
    a: "Per E-Mail. Name und ladungsfähige Anschrift stehen im Impressum, sobald sie hinterlegt sind — wir erfinden sie nicht.",
    links: [
      { href: "/kontakt", label: "Kontakt" },
      { href: "/legal/impressum", label: "Impressum" },
    ],
  },
];
