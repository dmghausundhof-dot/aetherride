/**
 * Homepage copy — rider-facing, one page, no store theater.
 * No invented legal identity, store listings, or fake kilometers.
 */

export const HOME_INTRO = {
  kicker: "Was FlowLine ist",
  title: "Outdoor Cycling, ohne Timeline.",
  lead: "FlowLine ist die Anwendung für den Alltag zwischen Feierabendrunde und Wochenend-Etappe. Im Browser planst du, pflegst das Rad und teilst eine Mappe. In der App fährst du: HUD, GPS, Offline-Routing, Sensoren.",
  paragraphs: [
    "Der Hof ist der Stand — nicht ein Feed. Vier Türen: Hof, Karte, Touren, Rad. Teile sitzen am Rad, nicht als fünfter Tab. Ride ist der orange Knopf, nicht der fünfte Reiter. Was fehlt, bleibt leer: keine Dummy-Kilometer, kein Leaderboard, keine zweite Kasse im Browser.",
    "Öffentliche Tour-Seiten sind redaktionelle Ideen mit Pin. Die Linie entsteht, wenn du planst — in Hamburg die Alster, nicht pauschal die Alpen. Community hängt an der Tour: Stimmen, Mappe-Links, Einladungslinks. Public Profiles nur mit Opt-in, ohne GPS-Spuren.",
  ],
} as const;

export const HOME_DISCIPLINES: {
  title: string;
  href: string;
  body: string;
}[] = [
  {
    title: "Rennrad",
    href: "/discover?sport=road",
    body: "Asphalt, Höhenmeter, flache Ufer. Filter und Nähe-Rundkurse auf der Karte — ohne Verkehr als Spiel.",
  },
  {
    title: "Gravel",
    href: "/discover?sport=gravel",
    body: "Forstwege und Mix. Das Profil „Gravel“ meidet harte Trails. Nach Regen bleibt’s ehrlich: rutschig ist rutschig.",
  },
  {
    title: "MTB",
    href: "/discover?sport=mtb",
    body: "S-Skalen statt Sterne-Inflation. Navigation in der App. Editorial-Ideen wie Königstuhl — keine erfundenen Downhill-GPX.",
  },
  {
    title: "E-Bike",
    href: "/guides/ebike-reichweite",
    body: "Reichweite als Spanne, nicht als Punkt. Assist und Kalibrierung in Pro. Bosch live nur nativ, nicht im Tab.",
  },
  {
    title: "Touring & City",
    href: "/discover?sport=urban",
    body: "Etappen, Pausenorte, Feierabend. Dieselben Touren in der Mappe wie auf der Karte — ohne zweite App für den Alltag.",
  },
];

export const HOME_DOOR_STORIES: {
  href: string;
  title: string;
  kicker: string;
  body: string;
}[] = [
  {
    href: "/home",
    title: "Start",
    kicker: "Losfahren",
    body: "Hier steht das Rad. Wetter, was reinkam, ein oranger Knopf. Keine KPI-Leiste, keine Stories. Losfahren startet die App — die Karte bleibt zum Planen.",
  },
  {
    href: "/discover",
    title: "Karte",
    kicker: "Entdecken oder Ziel",
    body: "OpenStreetMap und Protomaps, echte Nähe, Filter nach Sport. Du planst am Desktop: Start, Via, Ziel. Live-Navigation im Browser gibt es nicht — und wird nicht vorgetäuscht.",
  },
  {
    href: "/library",
    title: "Touren",
    kicker: "Gespeichert und geteilt",
    body: "Deine Strecken, Tipps, Einladungslinks. Teilen per Link, nicht per Timeline. Wer den Link hat, legt die Tour lokal ab — ohne Account-Zwang, ohne Track im Kommentar.",
  },
  {
    href: "/garage",
    title: "Garage",
    kicker: "Dieses Bike",
    body: "Anlegen, Setup, Wartungsintervalle mit Quelle. Bracketing und Reichweiten-Spannen. Der Laden ist zu — Closed Test bleibt frei.",
  },
];

export const HOME_SPLIT = {
  kicker: "Zwei Oberflächen",
  title: "Web pflanzt. Die App fährt.",
  webLead:
    "Inspiration, Planen, Pflege und Teilen gehören an den Schreibtisch. Der Browser darf leer bleiben, wo GPS und Sensoren hingehören.",
  appLead:
    "Unterwegs zählt ein gesperrtes Display, Offline-Routing ohne Netz und eine Uhr am Fahrer. Dafür gibt es keine Web-Attrappe und keine Länderkarte.",
} as const;

export const HOME_MAPS = {
  kicker: "Auf der Karte",
  title: "Löcher statt Fake-Globus.",
  lead: "Online streamt die Karte aus benannten Regionen. Offline lädst du Stadt-Packs zum Routing, keine Länder. Wo kein Blatt liegt, bleibt ein Loch — nicht ein gemaltes Europa.",
} as const;

export const HOME_TOURS = {
  kicker: "Tour-Ideen",
  title: "Heidelberg und Odenwald zuerst.",
  lead: "Redaktionelle Ideen mit Pin — Heidelberg, Odenwald, dann Schwarzwald. Keine vermessenen Community-Tracks. Die Linie rechnest du unter Planen.",
} as const;

export const HOME_JOURNEY = {
  kicker: "Ablauf",
  title: "So kommst du raus — und wieder.",
  lead: "Ankommen, Rad am Stand, Stunde vor dem Tor, Rausfahren, zurück am Hof. Kein Onboarding-Theater, kein Demo-Rad, das Kilometer vorspielt.",
} as const;

export const HOME_VOICES = {
  kicker: "Stimmen",
  title: "An der Tour, nicht in einem Feed.",
  lead: "Editorial, klar gekennzeichnet. Kurztext ohne Track-Anhang. Neue Stimmen starten in Prüfung.",
} as const;

export const HOME_GUIDES = {
  kicker: "Guides",
  title: "Nachlesen, bevor du losfährst.",
  lead: "Planung, Reichweite, Setup, Garage und Teilen — ohne Affiliate-Clickbait. Was im Produkt fehlt, steht auch hier nicht als Versprechen.",
  slugs: [
    "web-vs-app",
    "platz-ohne-feed",
    "teilen-per-link",
    "laden-ohne-zweite-kasse",
    "gravel-touren-planen",
    "ebike-reichweite",
  ],
} as const;

/** Homepage FAQ — three questions, no store theater. */
export const HOME_FAQ_IDS = ["was", "web-app", "shop"] as const;

export const HOME_PRICING = {
  kicker: "Preise",
  title: "Closed Test ist frei.",
  lead: "Kein öffentliches Angebot. Der Laden ist zu. Es gibt hier nichts zu kaufen.",
  free: "Closed Test — frei, lokal, ohne Kasse.",
  pro: "Kein Verkauf auf dieser Seite.",
} as const;

export const HOME_HONESTY = {
  kicker: "Stand",
  title: "Schon da. Noch nicht.",
  lead: "Closed Test, kein öffentliches Angebot. Was fehlt, bleibt leer.",
  live: [
    "Karte, Planen, Touren, Garage im Browser",
    "Online-Karte in DACH — Löcher dort, wo kein Blatt liegt",
    "Tour-Ideen um Heidelberg und den Odenwald",
    "Closed Test frei — keine Käufe",
  ],
  notYet: [
    "App-Store- und Play-Listings — HUD und Sensoren kommen mit der nativen App",
    "Laden und Checkout — zu, weil das Impressum noch keine ladungsfähige Anschrift hat",
    "Live-Partner-Buchung für Werkstätten",
  ],
} as const;

export const HOME_CTA = {
  title: "Das Rad steht. Du kommst zurück.",
  body: "Öffne die Karte im Browser. Die App übernimmt Navigation, Offline und Uhr, sobald die Listings da sind.",
} as const;

export const HOME_LEVERS: {
  title: string;
  body: string;
  href: string;
}[] = [
  {
    title: "Garage + Setup",
    href: "/garage",
    body: "Dein Bike, Federweg, Druck. Enduro steht neben Gravel und MTB — nicht hinter City.",
  },
  {
    title: "Ehrlich routen",
    href: "/discover",
    body: "mtb:scale statt Wetter-als-Zustand. Wo kein Weg liegt, bleibt ein Loch — keine Fake-Linie.",
  },
  {
    title: "Bosch als Spanne",
    href: "/guides/ebike-reichweite",
    body: "Reichweite als Intervall, kein Punkt. Live-Assist nur in der App, nicht als Web-Attrappe.",
  },
];

export const HOME_FAQ_INLINE: { q: string; a: string }[] = [
  {
    q: "Was ist FlowLine?",
    a: "Eine App für Garage, Karte und Touren. Im Browser planst du. In der App fährst du. Closed Test, frei, ohne Shop.",
  },
  {
    q: "Was läuft im Browser, was in der App?",
    a: "Web pflanzt: Karte, Planen, Garage, Tour-Ideen. Die App fährt: HUD, GPS, Offline-Routing, Sensoren. Live-Navigation im Tab gibt es nicht.",
  },
  {
    q: "Kann ich hier etwas kaufen?",
    a: "Nein. Der Laden ist zu. Closed Test bleibt frei — keine Preise, keine Kasse.",
  },
];

export const HOME_PRODUCT_SCREEN = {
  src: "/landing/screens/karte.jpg",
  alt: "FlowLine Karte mit orangener Linie",
  title: "Die Karte",
  caption: "Echte Nähe, Filter, Pin. Kein Fake-Globus und keine Design-Galerie.",
} as const;

export const HOME_BIKES_LINE =
  "Rennrad, Gravel, MTB, Enduro, E-Bike. City ist dabei — nicht die Leitidentität.";
