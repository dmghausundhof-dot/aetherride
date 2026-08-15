/** German Hof chrome — matches Flutter app_de.arb. Title stays country-based. */

export const HOF_COPY = {
  profile: "Profil",
  rideOut: "Rausfahren",
  rideOutAgain: "Noch mal raus",
  openBike: "Rad öffnen",
  parkBike: "Rad abstellen",
  rideWithoutBike: "Ohne Rad fahren",
  atGate: "vor dem Tor",
  emptyStand: "Leerer Stand",
  skyUnknown: "Himmel unbekannt",
  noHonestLoop: "Kein ehrlicher Trail-Rundkurs",
  notYetOut: "noch nicht draußen",
  justBack: "gerade reingekommen",
  atHof: "am Hof",
  noBikeHere: "Kein Rad steht hier",
  openTours: "Touren öffnen",
  yourWatch: "Deine Uhr",
  watchHint:
    "Fitnesstracking am Fahrer — nicht am Rad. Koppeln geht in der App, nicht im Browser.",
  watchOpenApp: "In der App koppeln",
  watchBar: "Uhr in der App koppeln",
  workshopCscBar: "Radsensor in der App koppeln",
  workshopSensorUnpaired: "Radsensor nicht verbunden",
  careInWorkshop: (label: string) => `${label} — in der Werkstatt`,
  bringForward: (name: string) => `${name} nach vorn`,
  sinceOneDay: "seit 1 Tag",
  sinceDays: (days: number) => `seit ${days} Tagen`,
  loopDuration: (minutes: number) => `⟲ ${minutes} min`,
  communityNotes: (count: number) => `${count} Stimmen zu dieser Runde`,
  skyDry: (temp: string) => `${temp}° · eher trocken`,
  skyDamp: (temp: string) => `${temp}° · feucht möglich`,
  skyWet: (temp: string) => `${temp}° · Regen · Trails eher nass`,

  justRide: "Einfach fahren",
  showTours: "Touren anzeigen",
  mapChoiceHint:
    "Ohne Touren losfahren, oder Touren auf der Karte zeigen.",
  mapJustRideHint:
    "Im Browser bleibt die Karte. GPS-HUD, Navigation und Aufzeichnung laufen in der App.",
  mapKicker: "Vor dem Tor",
  mapTitle: "Karte",
  mapEmptyLoops: "Keine Rundkurse in der Nähe",
  mapEmptyLoopsHint:
    "Nur echte Loops (Start≈Ziel) — keine A→B-Touren als Füllung. Ort ändern oder in der App fahren.",
  mapLoading: "Karte wird geladen…",
  mapSheetNear: "In der Nähe",
  mapSheetPlan: "Planen",
  mapSheetTours: "Touren",
  inTheApp: "In der App",

  workshopKicker: "Das Rad",
  workshopTitle: "Werkstatt",
  workshopHint:
    "Ein Stall für den Bewohner. Bereit, Heute, Am Rad, Sensor. Die Uhr bleibt am Fahrer.",
  workshopEmpty: "Die Box ist leer",
  workshopEmptyHint:
    "Name und Typ reichen. Der Katalog ist Suche — Serienteile nur wenn du sie übernimmst.",
  workshopAdd: "Rad abstellen",
  workshopTabBox: "Die Box",
  workshopZoneReady: "Bereit",
  workshopZoneToday: "Heute",
  workshopZoneOnBike: "Am Rad",
  workshopZoneSensor: "Sensor",
  workshopMore: "Mehr am Rad",
  workshopAddAnother: "Weiteres Rad",
  workshopLoading: "Werkstatt wird geladen…",
  workshopTabOverview: "Übersicht",
  workshopTabParts: "Komponenten",
  workshopTabSetups: "Setup",
  workshopTabCare: "Wartung",
  workshopBikes: "Deine Räder",
  workshopNoWatch:
    "Kein Uhren-Koppeln im Browser. Sensoren am Rad, wenn sie wirklich da sind.",

  shopKicker: "Über den Hof",
  shopTitle: "Der Laden",
  shopHint:
    "Hier wohnt das Rad nicht. Ehrliche Teile und Merch im Shopify-Shop — Kauf und Kasse dort, nicht auf dieser Seite.",
  shopGo: "Zum Shop",
  shopForYourBike: "Für dein Rad",
  shopForYourBikeHint: (name: string) =>
    `Ersatzteile passend zu ${name} — Kategorie und Laufrad. Keine erfundenen SKUs.`,
  shopForYourBikeEmpty:
    "Stell ein Rad in der Werkstatt ab — dann öffnen wir die passenden Teile im Shop.",
  shopMerch: "Merchandise",
  shopMerchHint:
    "Kleidung und Kleinzeug. Unabhängig vom Rad, nie nach Fit gefiltert.",
  shopLockedTitle: "Online Store gesperrt",
  shopLockedBody:
    "Der Shopify-Shop ist passwortgeschützt (Inhaber-Vorschau). Der Link führt zur Passwort-Seite — kein stiller Dead End, aber kein öffentlicher Checkout.",
  shopLockedOpen: "Trotzdem öffnen (Passwort-Seite)",
  shopLockedCatalog:
    "Kein In-App-Katalog. Kasse nur bei Shopify.",
  shopCheckoutElsewhere: "Checkout nur bei Shopify, nicht auf aetherride.app.",
  shopProductMissing: "Dieses Produkt liegt nicht im Laden.",
  shopBack: "Zurück zum Laden",

  profileKicker: "Du",
  profileTitle: "Profil",
  profileHint:
    "Konto und Fahrstil. Nach dem Anmelden stehst du am Hof — kein Sync-Theater mit der nativen App.",
  profileArrive: "Am Hof ankommen",
  profileLocalOnly:
    "Supabase fehlt — lokale Nutzung ohne Cloud. Die App sync’t nicht still mit.",
  profileWelcome: "Angemeldet. Der Stand wartet.",
  profileBikesAtStand: "Räder am Stand",
  profileNoKpi: "Keine Streaks, keine erfundenen Kilometer.",

  legalKicker: "Rechtliches",
  notFoundTitle: "Diese Tür gibt es nicht",
  notFoundHint:
    "Leerer Stand. Zurück zum Hof, oder eine der fünf Türen.",
  rideBridgeTitle: "Die Straße ist die App",
  rideBridgeHint:
    "Live-GPS, Offline-Karten, Sensoren und Hintergrund-Aufzeichnung laufen nur nativ — nicht im Browser.",
  rideBackToMap: "Zurück zur Karte",
  downloadTitle: "Die App für unterwegs",
  downloadHint:
    "Der Hof, die Karte und die Werkstatt laufen im Browser. Rausfahren mit HUD — nur in der App.",
  activitiesTitle: "Was reinkam",
  activitiesHint:
    "Fahrten aus der App. Aufzeichnung bleibt nativ — hier nur, was wirklich da ist.",
  activitiesEmpty: "Noch keine Rückkehr.",
  activitiesEmptyHint:
    "Fahrten entstehen in der App. Kein Fake-Kalender, keine 0-km-Woche.",
  libraryKicker: "Platz",
  libraryTitle: "Platz",
  libraryHint:
    "Deine Touren, Stimmen und Gruppen. Dieselben Touren wie auf der Karte.",
  libraryMappe: "Die Mappe",
  tafelKicker: "Die Tafel",
  akteMein: "Mein",
  akteStimmen: "Stimmen",
  stimmenPrivateHint:
    "Noch privat — nach Freigabe können andere kommentieren.",
  plannerKicker: "Karte",
  plannerTitle: "Planen",
  plannerHint:
    "Dieselbe Tür wie die Karte. Navigation startet in der App.",
  checkoutTitle: "Kasse ist der Laden",
  checkoutHint:
    "Kein Warenkorb in FlowLine. Kauf und Kasse liegen bei Shopify.",
  chatHint:
    "Power-User. Kein Feed auf dem Hof. Die Werkstatt bleibt die Werkstatt.",
  coachBell: "Hinweise",
  coachTafel: (n: number) =>
    n === 1 ? "1 Hinweis vom Assistenten" : `${n} Hinweise vom Assistenten`,
  privacyKicker: "Du",
  privacyTitle: "Daten & Privatsphäre",
  privacyHint:
    "Export, Zonen, Familie. Kein Tracking-Theater — nur was wirklich da ist.",
  postRideKicker: "Zurück am Hof",
  postRideTitle: "Was reinkam",
  postRideHint:
    "Analyse nach der Fahrt. Aufzeichnung bleibt in der App — hier nur ehrliche Zahlen.",

  togetherOut: "Zusammen raus",
  groupAtGate: "Gruppe vor dem Tor",
  groupLiveNavHint:
    "Alle in der Gruppe auf dem Navi — nur in der App, nur während der Fahrt, nur mit Opt-in. Nicht auf der Karte vor dem Tor.",
} as const;
