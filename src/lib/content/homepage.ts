/**
 * Homepage copy — first-visit prose, not a sitemap dump.
 * No invented legal identity, store listings, or fake kilometers.
 */

export const HOME_INTRO = {
  kicker: "Was FlowLine ist",
  title: "Outdoor Cycling, ohne Timeline.",
  lead: "FlowLine ist die Anwendung für den Alltag zwischen Feierabendrunde und Wochenend-Etappe. Im Browser planst du, pflegst das Rad und teilst eine Mappe. In der App fährst du: HUD, GPS, Offline, Sensoren.",
  paragraphs: [
    "Der Hof ist der Stand — nicht ein Feed. Vier Türen: Hof, Karte, Platz, Werkstatt. Teile sitzen am Rad, nicht als fünfter Tab. Ride ist der orange Knopf, nicht der fünfte Reiter. Was fehlt, bleibt leer: keine Dummy-Kilometer, kein Leaderboard, keine zweite Kasse im Browser.",
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
    title: "Der Hof",
    kicker: "Der Stand",
    body: "Hier wohnt das Rad. Himmel, eine Stunde vor dem Tor, was reinkam. Keine KPI-Leiste, keine Stories. Rausfahren ist ein Knopf — danach übernimmt die App.",
  },
  {
    href: "/discover",
    title: "Karte",
    kicker: "Vor dem Tor",
    body: "OpenStreetMap und Protomaps, echte Nähe, Filter nach Sport. Du planst am Desktop: Start, Via, Ziel. Live-Navigation im Browser gibt es nicht — und wird nicht vorgetäuscht.",
  },
  {
    href: "/library",
    title: "Platz",
    kicker: "Community an der Tour",
    body: "Mappe, Stimmen, Einladungslinks. Teilen per Link, nicht per Timeline. Wer den Link hat, legt die Tour lokal ab — ohne Account-Zwang, ohne Track im Kommentar.",
  },
  {
    href: "/garage",
    title: "Werkstatt",
    kicker: "Das Rad",
    body: "Abstellen, Setup, Wartungsintervalle mit Quelle. Bracketing und Reichweiten-Spannen sind Pro. Teile schlägst du hier nach — passend zu Kassette, Kette, Belägen, Reifengröße. Der Laden ist die Tür zu Shopify, kein fünfter Tab und kein zweiter Warenkorb.",
  },
];

export const HOME_SPLIT = {
  kicker: "Zwei Oberflächen",
  title: "Web ist der Hof. Die App fährt.",
  webLead:
    "Inspiration, Planen, Pflege und Teilen gehören an den Schreibtisch. Der Browser darf leer bleiben, wo GPS und Sensoren hingehören.",
  appLead:
    "Unterwegs zählt ein gesperrtes Display, Stadt-Packs ohne Netz und eine Uhr am Fahrer. Dafür gibt es keine Web-Attrappe und keine Länderkarte.",
} as const;

export const HOME_MAPS = {
  kicker: "Auf der Karte",
  title: "Neun Blätter. Kein Europa-Download.",
  lead: "Online streamt die Karte aus benannten Regionen. In DACH liegen Atlas und Wege für alle, nicht nur für zehn Städte. Offline lädst du Stadt-Packs zum Routing, keine Länder. Wo kein Blatt liegt, bleibt ein Loch — nicht ein Fake-Globus.",
} as const;

export const HOME_TOURS = {
  kicker: "Vor dem Tor",
  title: "Ideen aus der Nähe, nicht aus dem Alpen-Stock.",
  lead: "Vier redaktionelle Touren als Einstieg — Hamburg Alster, Heidelberg, Schwarzwald Gravel, Bodensee. Es sind Ideen mit Pin, keine vermessenen Community-Tracks. Die Linie rechnest du unter Planen.",
} as const;

export const HOME_JOURNEY = {
  kicker: "Ablauf",
  title: "So kommst du raus — und wieder.",
  lead: "Ankommen, Rad am Stand, Stunde vor dem Tor, Rausfahren, zurück am Hof. Kein Onboarding-Theater, kein Demo-Bike, das Kilometer vorspielt.",
} as const;

export const HOME_VOICES = {
  kicker: "Stimmen",
  title: "An der Tour, nicht in einem Feed.",
  lead: "Editorial, klar gekennzeichnet. Kurztext ohne Track-Anhang. Neue Stimmen starten in Prüfung.",
} as const;

export const HOME_GUIDES = {
  kicker: "Guides",
  title: "Nachlesen, bevor du losfährst.",
  lead: "Planung, Reichweite, Setup, Hof und Teilen — ohne Affiliate-Clickbait. Was im Produkt fehlt, steht auch hier nicht als Versprechen.",
  slugs: [
    "web-vs-app",
    "platz-ohne-feed",
    "teilen-per-link",
    "laden-ohne-zweite-kasse",
    "gravel-touren-planen",
    "ebike-reichweite",
  ],
} as const;

export const HOME_FAQ_IDS = ["was", "fuer-wen", "web-app", "karten", "preise"] as const;

export const HOME_PRICING = {
  kicker: "Preise",
  title: "Free plant. Pro vertieft.",
  lead: "Karte, Planen, ein Rad, App-Navigation: frei. Multi-Bike, Bracketing, Reichweiten-Spannen und höhere Chat-Limits: Pro. Checkout im Profil, nicht mitten in der Tour. Store-Listings der App folgen, sobald sie live sind.",
  free: "0 € — Hof, Karte, Platz, ein Rad, Navigation in der App.",
  pro: "6,99 €/Monat oder 59,99 €/Jahr. Kündigung im Portal bzw. über Play.",
} as const;

export const HOME_HONESTY = {
  kicker: "Stand",
  title: "Vollwertig, wo es steht — leer, wo es fehlt.",
  lead: "Eine Homepage darf nicht so tun, als wäre der Marktplatz offen oder der Store schon gelistet. Deshalb der ehrliche Stand:",
  live: [
    "Hof, Karte, Planen, Platz, Werkstatt im Browser",
    "Online-Karte in DACH, Frankreich, Alpen-Süd, Benelux, Nord- und Mitteitalien, Süditalien, Katalonien/Pyrenäen, Südengland",
    "Redaktionelle Tour-Ideen vor allem in DACH — die Kartenblätter reichen weiter",
    "Stimmen, Mappe-Links, Editorial-Profile",
    "Free und Pro beschrieben, Checkout im Profil (Stripe)",
  ],
  notYet: [
    "Ladungsfähige Anschrift im Impressum — daher Shop-Checkout gesperrt",
    "App-Store- und Play-Listings — HUD und Sensoren kommen mit der nativen App",
    "Live-Partner-Buchung für Werkstätten — Interesse per E-Mail",
  ],
} as const;

export const HOME_CTA = {
  title: "Das Rad steht. Du kommst zurück.",
  body: "Öffne den Hof im Browser. Die App übernimmt Navigation, Offline und Uhr, sobald die Listings da sind — bis dahin bleibt der Stand ehrlich leer statt gefüllt.",
} as const;
