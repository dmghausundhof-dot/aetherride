/**
 * Public product map — screens, split, and workflows for the website.
 * Copy stays rider-facing (no spec IDs).
 */

export const PRODUCT_DOORS = [
  {
    href: "/home",
    title: "Der Hof",
    body: "Stand, Himmel, eine Stunde vor dem Tor. Ein Knopf — Rausfahren.",
  },
  {
    href: "/discover",
    title: "Karte",
    body: "OSM, Nähe-Rundkurse, Filter, Planen. Kein Google-Layer.",
  },
  {
    href: "/library",
    title: "Platz",
    body: "Deine Mappe, Stimmen, Gruppen. Dieselben Touren wie auf der Karte.",
  },
  {
    href: "/garage",
    title: "Werkstatt",
    body: "Rad abstellen, Setup, Pflege. Ersatzteile führen in den Laden.",
  },
  {
    href: "/shop",
    title: "Laden",
    body: "Tür zu Shopify. Kein zweiter Katalog, keine Kasse hier.",
  },
] as const;

export const WEB_SURFACES = [
  {
    title: "Hof, Karte, Planen",
    body: "Inspiration, Nähe-Loops, Desktop-Planer. Speichern in der Mappe.",
  },
  {
    title: "Werkstatt",
    body: "Räder, Komponenten, Setup, Wartung — auch ohne App.",
  },
  {
    title: "Platz",
    body: "GPX, Sammlungen, Stimmen, Gruppen-Codes. Teilen ohne Feed.",
  },
  {
    title: "Laden",
    body: "Passende Teile aus der Werkstatt. Checkout nur bei Shopify.",
  },
] as const;

export const APP_SURFACES = [
  {
    title: "Rausfahren",
    body: "Ride-HUD, Turn-by-turn, GPS im Hintergrund, gesperrtes Display.",
  },
  {
    title: "Offline",
    body: "Karten- und Routing-Packs ohne Netz. Im Browser nicht sinnvoll.",
  },
  {
    title: "Sensoren & Uhr",
    body: "BLE, CSC, Uhr am Fahrer. Koppeln nur nativ — nicht im Browser.",
  },
  {
    title: "Aufzeichnung",
    body: "Echte Fahrten entstehen in der App. Der Hof zeigt, was reinkam.",
  },
] as const;

export const WEB_APP_MATRIX: {
  feature: string;
  web: string;
  app: string;
}[] = [
  { feature: "Hof, Karte, Platz, Werkstatt", web: "voll", app: "voll" },
  { feature: "Tour planen & speichern", web: "voll", app: "voll" },
  { feature: "SEO-Touren & Regionen", web: "voll", app: "Deep Link" },
  { feature: "Live-Navigation / HUD", web: "Bridge zur App", app: "voll" },
  { feature: "Offline-Karten", web: "—", app: "Packs" },
  { feature: "GPS-Aufzeichnung", web: "nach Sync", app: "nativ" },
  { feature: "Sensoren, Uhr, BLE", web: "Hinweis", app: "koppeln" },
  { feature: "Laden / Kasse", web: "Gateway", app: "Gateway" },
  { feature: "Stimmen an der Tour", web: "voll", app: "voll" },
  { feature: "Mappe & Sammlungen teilen", web: "voll", app: "Deep Link" },
  { feature: "Gruppen / Zusammen raus", web: "Roster + Code", app: "HUD-Pins" },
  { feature: "Public Profile", web: "Opt-in", app: "Opt-in" },
];

export const JOURNEY = [
  {
    n: "1",
    title: "Ankommen",
    body: "Sport und Gewicht — oder überspringen. Kein Demo-Bike, kein Fake-Kilometer.",
  },
  {
    n: "2",
    title: "Rad am Stand",
    body: "In der Werkstatt abstellen — oder ohne Rad fahren.",
  },
  {
    n: "3",
    title: "Stunde vor dem Tor",
    body: "Die Karte zeigt echte Nähe-Rundkurse. Fehlt einer, bleibt das Tor leer.",
  },
  {
    n: "4",
    title: "Rausfahren",
    body: "Ein oranger Knopf. Navigation und Sensoren laufen in der App.",
  },
  {
    n: "5",
    title: "Wieder am Hof",
    body: "Was reinkam: Analyse, Setup-Hinweis, Wartung. Stimmen auf dem Platz.",
  },
] as const;

export const WORKFLOWS: {
  id: string;
  title: string;
  hint: string;
  steps: { label: string; href: string }[];
}[] = [
  {
    id: "first",
    title: "Erster Besuch",
    hint: "Website erzählt, der Hof nimmt auf.",
    steps: [
      { label: "Startseite", href: "/" },
      { label: "Produkt", href: "/produkt" },
      { label: "Anmelden", href: "/anmelden" },
      { label: "Der Hof", href: "/home" },
    ],
  },
  {
    id: "plan-ride",
    title: "Planen und fahren",
    hint: "Web plant. Die App fährt.",
    steps: [
      { label: "Karte", href: "/discover" },
      { label: "Planen", href: "/planner" },
      { label: "Platz / Mappe", href: "/library" },
      { label: "App-Brücke", href: "/ride" },
    ],
  },
  {
    id: "return",
    title: "Nach der Fahrt",
    hint: "Aufzeichnung bleibt nativ. Analyse darf im Browser liegen.",
    steps: [
      { label: "Was reinkam", href: "/activities" },
      { label: "Nach der Fahrt", href: "/post-ride" },
      { label: "Hof-Tafel", href: "/home" },
      { label: "Werkstatt", href: "/garage" },
    ],
  },
  {
    id: "garage-shop",
    title: "Pflege und Teile",
    hint: "Die Werkstatt kennt das Rad. Der Laden kassiert nicht.",
    steps: [
      { label: "Rad abstellen", href: "/garage?wizard=basic" },
      { label: "Wartung", href: "/garage?tab=maintenance" },
      { label: "Laden", href: "/shop" },
      { label: "Teile", href: "/shop/parts" },
    ],
  },
  {
    id: "platz",
    title: "Platz und Stimmen",
    hint: "Kein Feed auf dem Hof. Community hängt an der Tour.",
    steps: [
      { label: "Platz", href: "/library" },
      { label: "Tour-Seite", href: "/regions" },
      { label: "Community", href: "/community" },
      { label: "Profil", href: "/profile" },
    ],
  },
  {
    id: "pro",
    title: "Konto und Pro",
    hint: "Free plant. Pro vertieft. Navigation in der App auf beiden Stufen.",
    steps: [
      { label: "Anmelden", href: "/anmelden" },
      { label: "Preise", href: "/pricing" },
      { label: "Profil / Abo", href: "/profile" },
      { label: "Daten", href: "/privacy" },
    ],
  },
];

export const SCREEN_GROUPS: {
  title: string;
  hint: string;
  screens: { href: string; name: string; role: string }[];
}[] = [
  {
    title: "Öffentliche Website",
    hint: "Geschichte, SEO, Trust. Keine fünf App-Tabs in der Kopfzeile.",
    screens: [
      { href: "/", name: "Start", role: "Hero, Türen, Reise" },
      { href: "/produkt", name: "Produkt", role: "Screens und Abläufe" },
      { href: "/regions", name: "Regionen", role: "DACH-Ideen, Nähe" },
      { href: "/guides", name: "Guides", role: "Planung, Setup, E-Bike" },
      { href: "/community", name: "Community", role: "Events light, Platz" },
      { href: "/pricing", name: "Preise", role: "Free / Pro" },
      { href: "/download", name: "App", role: "Warum nativ" },
      { href: "/anmelden", name: "Anmelden", role: "Konto, dann Hof" },
      { href: "/faq", name: "FAQ", role: "Web, App, Preise" },
      { href: "/ueber", name: "Über", role: "Marke, fünf Türen" },
      { href: "/kontakt", name: "Kontakt", role: "E-Mail, kein Bot" },
    ],
  },
  {
    title: "Fünf Türen (Web-App)",
    hint: "Dieselbe IA wie in der nativen App. Ride ist kein Tab.",
    screens: [
      { href: "/home", name: "Der Hof", role: "Stand, Himmel, Tor" },
      { href: "/discover", name: "Karte", role: "OSM, Loops, Filter" },
      { href: "/planner", name: "Planen", role: "Start, Via, Ziel" },
      { href: "/library", name: "Platz", role: "Mappe, Stimmen, Gruppen" },
      { href: "/garage", name: "Werkstatt", role: "Box, Setup, Pflege" },
      { href: "/shop", name: "Laden", role: "Shopify-Tür" },
    ],
  },
  {
    title: "Fahrt und Rückkehr",
    hint: "HUD nur in der App. Web zeigt die Brücke und danach die Akte.",
    screens: [
      { href: "/ride", name: "App-Brücke", role: "Deep Link, keine Live-GPS" },
      { href: "/activities", name: "Was reinkam", role: "Liste nach Sync" },
      { href: "/post-ride", name: "Nach der Fahrt", role: "Feedback, Setup" },
    ],
  },
  {
    title: "Konto, Coach, Laden",
    hint: "Neben den Türen — erreichbar, nicht als Feed.",
    screens: [
      { href: "/profile", name: "Profil", role: "Konto, Fahrstil, Abo" },
      { href: "/privacy", name: "Daten", role: "Export, Zonen, Familie" },
      { href: "/chat", name: "Coach", role: "Power-User, Limits" },
      { href: "/shop/parts", name: "Teile", role: "Fit zur Werkstatt" },
      { href: "/checkout", name: "Kasse", role: "Verweis auf Shopify" },
    ],
  },
  {
    title: "Teilen und Rechtliches",
    hint: "Links ohne Account-Zwang. Legal ohne Overlay.",
    screens: [
      { href: "/share/t/demo", name: "Tour-Link", role: "In die Mappe" },
      { href: "/share/c/demo", name: "Sammlung", role: "Geteilte Mappe" },
      { href: "/legal/impressum", name: "Impressum", role: "Anbieter" },
      { href: "/legal/datenschutz", name: "Datenschutz", role: "DSGVO" },
      { href: "/legal/agb", name: "AGB", role: "Vertrag" },
      { href: "/legal/widerruf", name: "Widerruf", role: "Abo / Shop" },
    ],
  },
];
