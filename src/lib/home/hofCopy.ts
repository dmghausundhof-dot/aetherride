/** Hof product chrome. Title stays country-based. DE matches Flutter ARB where keys exist. */
import type { ChromeLang } from "@/lib/i18n/chromeLang";

export type HofCopy = {
  profile: string;
  rideOut: string;
  rideOutAgain: string;
  openBike: string;
  parkBike: string;
  rideWithoutBike: string;
  atGate: string;
  emptyStand: string;
  skyUnknown: string;
  gpsUnknown: string;
  noHonestLoop: string;
  gateWetClosed: string;
  notYetOut: string;
  justBack: string;
  lastRideNoGps: string;
  whatCameIn: string;
  atHof: string;
  noBikeHere: string;
  openTours: string;
  yourWatch: string;
  sinceOneDay: string;
  justRide: string;
  showTours: string;
  mapChoiceHint: string;
  gateAwayNear: string;
  mapTitle: string;
  workshopTitle: string;
  workshopAdd: string;
  workshopAddAnother: string;
  shopKicker: string;
  shopTitle: string;
  shopGo: string;
  shopForYourBike: string;
  shopPartsForBike: string;
  shopLookupInShop: string;
  shopForYourBikeEmpty: string;
  shopMerch: string;
  shopMerchHint: string;
  shopLockedTitle: string;
  shopSearchHint: string;
  shopFeatured: string;
  shopOpenProduct: string;
  shopAllParts: string;
  privacyTitle: string;
  libraryTitle: string;
  libraryMappe: string;
  tafelKicker: string;
  tafelHint: string;
  togetherOut: string;
  watchHint: string;
  watchOpenApp: string;
  watchBar: string;
  workshopCscBar: string;
  workshopSensorUnpaired: string;
  mapJustRideHint: string;
  mapKicker: string;
  mapEmptyLoops: string;
  mapEmptyLoopsHint: string;
  mapLoading: string;
  mapSheetNear: string;
  mapSheetPlan: string;
  mapSheetTours: string;
  inTheApp: string;
  workshopKicker: string;
  workshopHint: string;
  workshopEmpty: string;
  workshopEmptyHint: string;
  workshopAddBasicHint: string;
  workshopAddCatalog: string;
  workshopAddCatalogHint: string;
  workshopAddPlaceholder: string;
  workshopAddPlaceholderHint: string;
  workshopTabBox: string;
  workshopZoneReady: string;
  workshopZoneToday: string;
  workshopLater: string;
  workshopZoneOnBike: string;
  workshopZoneSensor: string;
  workshopMore: string;
  workshopLoading: string;
  workshopTabOverview: string;
  workshopTabParts: string;
  workshopTabSetups: string;
  workshopTabCare: string;
  workshopBikes: string;
  workshopNoWatch: string;
  careFallback: string;
  shopHint: string;
  shopPausedTitle: string;
  shopPausedHint: string;
  shopLockedBody: string;
  shopLockedOpen: string;
  shopLockedCatalog: string;
  shopLockedBanner: string;
  shopLockedPasswordNote: string;
  shopLockedMissingUrl: string;
  shopNoImage: string;
  shopGuideHow: string;
  shopCancel: string;
  shopExternalLink: string;
  shopNetworkError: string;
  shopProductUnavailable: string;
  shopCheckoutElsewhere: string;
  shopProductMissing: string;
  shopBack: string;
  shopCyclingParts: string;
  shopFeaturedBikes: string;
  shopDetails: string;
  shopCatalogFailed: string;
  shopRetry: string;
  shopOpenInApp: string;
  shopFitOnly: string;
  shopFitAllBikes: string;
  shopFitBannerAll: string;
  shopOpenInBrowser: string;
  shopZumHaendler: string;
  shopMerchantDisclosure: string;
  shopCatalogEmpty: string;
  shopReplaceHint: string;
  shopShelfEmpty: string;
  profileKicker: string;
  profileTitle: string;
  profileHint: string;
  profileArrive: string;
  profileLocalOnly: string;
  profileWelcome: string;
  profileBikesAtStand: string;
  profileNoKpi: string;
  legalKicker: string;
  notFoundTitle: string;
  notFoundHint: string;
  rideBridgeTitle: string;
  rideBridgeHint: string;
  ridePlannedKicker: string;
  rideBackToMap: string;
  downloadTitle: string;
  downloadHint: string;
  activitiesTitle: string;
  activitiesHint: string;
  activitiesEmpty: string;
  activitiesEmptyHint: string;
  libraryKicker: string;
  libraryHint: string;
  akteMein: string;
  akteStimmen: string;
  stimmenPrivateHint: string;
  plannerKicker: string;
  plannerTitle: string;
  plannerHint: string;
  checkoutTitle: string;
  checkoutHint: string;
  chatHint: string;
  coachBell: string;
  privacyKicker: string;
  privacyHint: string;
  postRideKicker: string;
  postRideTitle: string;
  postRideHint: string;
  groupAtGate: string;
  groupLiveNavHint: string;
  signedIn: string;
  agoMinutes: (n: number | string) => string;
  agoHours: (n: number | string) => string;
  packMissing: (n: number | string) => string;
  careInWorkshop: (n: number | string) => string;
  bringForward: (n: number | string) => string;
  sinceDays: (n: number | string) => string;
  loopDuration: (n: number | string) => string;
  gateAwayKm: (n: number | string) => string;
  skyDry: (n: number | string) => string;
  skyDamp: (n: number | string) => string;
  skyWet: (n: number | string) => string;
  shopForYourBikeHint: (n: number | string) => string;
  shopFitBanner: (n: number | string) => string;
  communityNotes: (n: number | string) => string;
  coachTafel: (n: number | string) => string;
  coachUnread: (n: number | string) => string;
};

const DE: HofCopy = {
  profile: "Profil",
  rideOut: "Rausfahren",
  rideOutAgain: "Noch mal raus",
  openBike: "Rad öffnen",
  parkBike: "Rad abstellen",
  rideWithoutBike: "Ohne Rad fahren",
  atGate: "vor dem Tor",
  emptyStand: "Leerer Stand",
  skyUnknown: "Himmel unbekannt",
  gpsUnknown: "Kein Standort — Himmel und Tor warten auf GPS.",
  noHonestLoop: "Kein ehrlicher Trail-Rundkurs",
  gateWetClosed: "Trails nass — kein ehrlicher Asphalt-Rundkurs in der Nähe",
  notYetOut: "noch nicht draußen",
  justBack: "gerade reingekommen",
  lastRideNoGps: "ohne GPS-Track — kein erfundener Verlauf",
  whatCameIn: "Was reinkam",
  atHof: "am Hof",
  noBikeHere: "Kein Rad steht hier",
  openTours: "Touren öffnen",
  yourWatch: "Deine Uhr",
  sinceOneDay: "seit 1 Tag",
  justRide: "Einfach fahren",
  showTours: "Touren anzeigen",
  mapChoiceHint: "Ohne Touren losfahren, oder Touren auf der Karte zeigen.",
  gateAwayNear: "unter 1 km",
  mapTitle: "Karte",
  workshopTitle: "Werkstatt",
  workshopAdd: "Rad anlegen",
  workshopAddAnother: "Weiteres Rad",
  shopKicker: "Über den Hof",
  shopTitle: "Der Laden",
  shopGo: "Zum Shop",
  shopForYourBike: "Für dein Rad",
  shopPartsForBike: "Teile für dein Rad",
  shopLookupInShop: "Im Laden nachschlagen",
  shopForYourBikeEmpty: "Stell ein Rad in der Werkstatt ab — dann öffnen wir die passenden Teile im Shop.",
  shopMerch: "Kleidung",
  shopMerchHint: "Kleidung und Kleinzeug. Unabhängig vom Rad, nie nach Fit gefiltert.",
  shopLockedTitle: "Shop draußen noch zu",
  shopSearchHint: "Teile, Marken, Specs…",
  shopFeatured: "Passende Teile",
  shopOpenProduct: "Im Shop öffnen",
  shopAllParts: "Alle Teile",
  privacyTitle: "Daten & Privatsphäre",
  libraryTitle: "Platz",
  libraryMappe: "Die Mappe",
  tafelKicker: "Die Tafel",
  tafelHint: "Eine Stimme oder eine Gruppe — kein Feed.",
  togetherOut: "Zusammen raus",
  watchHint: "Puls nur mit echtem Sensor.",
  watchOpenApp: "In der App koppeln",
  watchBar: "Uhr in der App koppeln",
  workshopCscBar: "Radsensor in der App koppeln",
  workshopSensorUnpaired: "Radsensor nicht verbunden",
  mapJustRideHint: "Im Browser bleibt die Karte. GPS-HUD, Navigation und Aufzeichnung laufen in der App.",
  mapKicker: "Vor dem Tor",
  mapEmptyLoops: "Keine Rundkurse in der Nähe",
  mapEmptyLoopsHint: "Nur echte Loops (Start≈Ziel) — keine A→B-Touren als Füllung. Ort ändern oder in der App fahren.",
  mapLoading: "Karte wird geladen…",
  mapSheetNear: "In der Nähe",
  mapSheetPlan: "Planen",
  mapSheetTours: "Touren",
  inTheApp: "In der App",
  workshopKicker: "Das Rad",
  workshopHint: "Dein Rad wohnt hier. Name und Typ reichen. Pflege kommt, wenn du willst.",
  workshopEmpty: "Noch kein Rad hier",
  workshopEmptyHint: "Name und Typ reichen. Der Katalog ist Suche — Serienteile nur wenn du sie übernimmst.",
  workshopAddBasicHint: "Name und Typ — jeder kann das",
  workshopAddCatalog: "Katalog suchen",
  workshopAddCatalogHint: "Modell finden, Kit optional",
  workshopAddPlaceholder: "Platzhalter",
  workshopAddPlaceholderHint: "Ohne Teile — Track via Touren",
  workshopTabBox: "Die Box",
  workshopZoneReady: "Bereit",
  workshopZoneToday: "Heute",
  workshopLater: "Später",
  workshopZoneOnBike: "Am Rad",
  workshopZoneSensor: "Sensor",
  workshopMore: "Mehr am Rad",
  workshopLoading: "Werkstatt wird geladen…",
  workshopTabOverview: "Übersicht",
  workshopTabParts: "Komponenten",
  workshopTabSetups: "Setup",
  workshopTabCare: "Wartung",
  workshopBikes: "Deine Räder",
  workshopNoWatch: "Sensoren am Rad koppeln geht in der App. Die Uhr bleibt beim Fahren.",
  careFallback: "Pflege",
  shopHint: "Hier wohnt das Rad nicht. FlowLine zeigt Teile — kaufen tust du beim Händler, nicht hier. Shopify-Kasse ist vorerst aus.",
  shopPausedTitle: "Der Laden pausiert",
  shopPausedHint:
    "Der Laden ist vorerst zu. Die Werkstatt bleibt — Rad, Setup und Wartung.",
  shopLockedBody: "Der Shop draußen ist noch nicht öffentlich — der Link kann auf ein Passwort treffen. Kasse bleibt bei Shopify, nicht hier.",
  shopLockedOpen: "Trotzdem öffnen (Passwort-Seite)",
  shopLockedCatalog: "Katalog in FlowLine. Kasse nur bei Shopify.",
  shopLockedBanner: "Shop draußen noch zu",
  shopLockedPasswordNote:
    "Katalog kann in FlowLine stehen. Store-Passwort wird nicht ausgeliefert.",
  shopLockedMissingUrl: "Storefront-URL fehlt — Tür bleibt ehrlich zu.",
  shopNoImage: "Kein Bild",
  shopGuideHow: "Wie der Laden funktioniert",
  shopCancel: "Zurück",
  shopExternalLink: "Externer Händler-Link",
  shopNetworkError: "Netzwerkfehler.",
  shopProductUnavailable: "Produkt nicht verfügbar",
  shopCheckoutElsewhere: "Der Händler ist Verkäufer und Vertragspartner — nicht FlowLine.",
  shopProductMissing: "Dieses Produkt liegt nicht im Laden.",
  shopBack: "Zurück zum Laden",
  shopCyclingParts: "Teile",
  shopCatalogFailed:
    "Katalog gerade nicht erreichbar. Versuche es später noch einmal.",
  shopRetry: "Erneut laden",
  shopFitOnly: "Nur passende",
  shopFitAllBikes: "Alle Räder",
  shopFitBannerAll: "Teile passend zu deinen Rädern",
  shopCatalogEmpty:
    "Noch keine Teile im Regal.",
  shopReplaceHint:
    "Ersatz — FlowLine filtert nach deinem Rad, ohne SKUs zu erfinden.",
  shopFeaturedBikes: "Räder im Laden",
  shopDetails: "Details",
  shopOpenInApp: "Im Laden ansehen",
  shopOpenInBrowser: "Im Browser öffnen",
  shopZumHaendler: "Beim Händler kaufen",
  shopMerchantDisclosure:
    "Verkäufer ist der Händler (Bike24, bike-components, bike-discount) — nicht FlowLine.",
  shopShelfEmpty: "Keine Teile zu dieser Suche.",
  profileKicker: "Du",
  profileTitle: "Profil",
  profileHint: "Konto und Fahrstil. Nach dem Anmelden stehst du am Hof — kein Sync-Theater mit der nativen App.",
  profileArrive: "Am Hof ankommen",
  profileLocalOnly: "Supabase fehlt — lokale Nutzung ohne Cloud. Die App sync’t nicht still mit.",
  profileWelcome: "Angemeldet. Der Stand wartet.",
  profileBikesAtStand: "Räder am Stand",
  profileNoKpi: "Keine Streaks, keine erfundenen Kilometer.",
  legalKicker: "Rechtliches",
  notFoundTitle: "Diese Tür gibt es nicht",
  notFoundHint: "Leerer Stand. Zurück zum Hof, oder eine der vier Türen.",
  rideBridgeTitle: "Die Straße ist die App",
  rideBridgeHint: "Live-GPS, Offline-Karten, Sensoren und Hintergrund-Aufzeichnung laufen nur nativ — nicht im Browser.",
  ridePlannedKicker: "Geplante Tour",
  rideBackToMap: "Zurück zur Karte",
  downloadTitle: "Die App für unterwegs",
  downloadHint: "Der Hof, die Karte und die Werkstatt laufen im Browser. Rausfahren mit HUD — nur in der App.",
  activitiesTitle: "Was reinkam",
  activitiesHint: "Fahrten aus der App. Aufzeichnung bleibt nativ — hier nur, was wirklich da ist.",
  activitiesEmpty: "Noch keine Rückkehr.",
  activitiesEmptyHint: "Fahrten entstehen in der App. Kein Fake-Kalender, keine 0-km-Woche.",
  libraryKicker: "Platz",
  libraryHint: "Touren merken, kurz schreiben, Freunde per Link mitnehmen — dieselben Touren wie auf der Karte.",
  akteMein: "Freigeben",
  akteStimmen: "Stimmen",
  stimmenPrivateHint: "Noch privat — nach Freigabe können andere kommentieren.",
  plannerKicker: "Karte",
  plannerTitle: "Planen",
  plannerHint: "Dieselbe Tür wie die Karte. Navigation startet in der App.",
  checkoutTitle: "Kasse ist der Laden",
  checkoutHint: "Kein Warenkorb in FlowLine. Kauf liegt beim Händler, nicht hier.",
  chatHint: "Power-User. Kein Feed auf dem Hof. Die Werkstatt bleibt die Werkstatt.",
  coachBell: "Hinweise",
  privacyKicker: "Du",
  privacyHint: "Export, Zonen, Familie. Kein Tracking-Theater — nur was wirklich da ist.",
  postRideKicker: "Zurück am Hof",
  postRideTitle: "Was reinkam",
  postRideHint: "Analyse nach der Fahrt. Aufzeichnung bleibt in der App — hier nur ehrliche Zahlen.",
  groupAtGate: "Gruppe vor dem Tor",
  groupLiveNavHint: "Alle in der Gruppe auf dem Navi — nur in der App, nur während der Fahrt, nur mit Opt-in. Nicht auf der Karte vor dem Tor.",
  signedIn: "Angemeldet",
  agoMinutes: (n) => "vor " + String(n) + " min",
  agoHours: (n) => "vor " + String(n) + " Std.",
  packMissing: (n) => "Pack für " + String(n) + " fehlt",
  careInWorkshop: (n) => String(n) + " — in der Werkstatt",
  bringForward: (n) => String(n) + " nach vorn",
  sinceDays: (n) => "seit " + String(n) + " Tagen",
  loopDuration: (n) => "⟲ " + String(n) + " min",
  gateAwayKm: (n) => String(n) + " km",
  skyDry: (n) => String(n) + "° · eher trocken",
  skyDamp: (n) => String(n) + "° · feucht möglich",
  skyWet: (n) => String(n) + "° · Regen · Trails eher nass",
  shopForYourBikeHint: (n) => "Ersatzteile passend zu " + String(n) + " — Kategorie und Laufrad. Keine erfundenen SKUs.",
  shopFitBanner: (n) => "Teile passend zu " + String(n),
  communityNotes: (n) => (n === 1 ? "1 Stimme zu dieser Runde" : `${n} Stimmen zu dieser Runde`),
  coachTafel: (n) => (n === 1 ? "1 Hinweis vom Assistenten" : `${n} Hinweise vom Assistenten`),
  coachUnread: (n) => (n === 1 ? "1 neu" : `${n} neu`),
};

const EN: HofCopy = {
  profile: "Profile",
  rideOut: "Ride out",
  rideOutAgain: "Ride out again",
  openBike: "Open bike",
  parkBike: "Park the bike",
  rideWithoutBike: "Ride without a bike",
  atGate: "at the gate",
  emptyStand: "Empty stand",
  skyUnknown: "Sky unknown",
  gpsUnknown: "No location — sky and gate wait for GPS.",
  noHonestLoop: "No honest trail loop",
  gateWetClosed: "Trails wet — no honest paved loop nearby",
  notYetOut: "not out yet",
  justBack: "just back",
  lastRideNoGps: "no GPS track — nothing invented",
  whatCameIn: "What came in",
  atHof: "at the stand",
  noBikeHere: "No bike here",
  openTours: "Open tours",
  yourWatch: "Your watch",
  sinceOneDay: "1 day",
  justRide: "Just ride",
  showTours: "Show tours",
  mapChoiceHint: "Ride without a route, or show tours on the map.",
  gateAwayNear: "under 1 km",
  mapTitle: "Map",
  workshopTitle: "Workshop",
  workshopAdd: "Add a bike",
  workshopAddAnother: "Another bike",
  shopKicker: "Across the yard",
  shopTitle: "The shop",
  shopGo: "Open shop",
  shopForYourBike: "For your bike",
  shopPartsForBike: "Parts for your bike",
  shopLookupInShop: "Look up in the shop",
  shopForYourBikeEmpty: "Park a bike in the workshop — then we open matching parts in the shop.",
  shopMerch: "Apparel",
  shopMerchHint: "Apparel and small goods. Never filtered by bike fit.",
  shopLockedTitle: "Shop still closed outside",
  shopSearchHint: "Search parts, brands, specs…",
  shopFeatured: "Matching parts",
  shopOpenProduct: "Open in shop",
  shopAllParts: "All parts",
  privacyTitle: "Data & privacy",
  libraryTitle: "Platz",
  libraryMappe: "Die Mappe",
  tafelKicker: "Die Tafel",
  tafelHint: "One voice or one group — not a feed.",
  togetherOut: "Ride together",
  watchHint: "Heart rate only with a real sensor.",
  watchOpenApp: "Pair in the app",
  watchBar: "Pair the watch in the app",
  workshopCscBar: "Pair the bike sensor in the app",
  workshopSensorUnpaired: "Bike sensor not connected",
  mapJustRideHint: "The map stays in the browser. GPS HUD, navigation and recording run in the app.",
  mapKicker: "At the gate",
  mapEmptyLoops: "No loops nearby",
  mapEmptyLoopsHint: "Real loops only (start≈finish) — no A→B filler tours. Change place or ride in the app.",
  mapLoading: "Loading map…",
  mapSheetNear: "Nearby",
  mapSheetPlan: "Plan",
  mapSheetTours: "Tours",
  inTheApp: "In the app",
  workshopKicker: "The bike",
  workshopHint: "Your bike lives here. Name and type are enough. Care comes when you want it.",
  workshopEmpty: "No bike here yet",
  workshopEmptyHint: "Name and type are enough. The catalog is search — stock parts only if you take them.",
  workshopAddBasicHint: "Name and type — anyone can do this",
  workshopAddCatalog: "Search catalog",
  workshopAddCatalogHint: "Find a model, kit optional",
  workshopAddPlaceholder: "Placeholder",
  workshopAddPlaceholderHint: "No parts — track via Tours",
  workshopTabBox: "Die Box",
  workshopZoneReady: "Ready",
  workshopZoneToday: "Today",
  workshopLater: "Later",
  workshopZoneOnBike: "On the bike",
  workshopZoneSensor: "Sensor",
  workshopMore: "More on the bike",
  workshopLoading: "Loading workshop…",
  workshopTabOverview: "Overview",
  workshopTabParts: "Components",
  workshopTabSetups: "Setup",
  workshopTabCare: "Service",
  workshopBikes: "Your bikes",
  workshopNoWatch: "Pairing sensors on the bike is in the app. The watch stays for the ride.",
  careFallback: "Care",
  shopHint: "The bike does not live here. FlowLine shows parts — you buy at the merchant, not here. Shopify checkout is off for now.",
  shopPausedTitle: "The shop is paused",
  shopPausedHint:
    "The shop is closed for now. The workshop stays — bike, setup and service.",
  shopLockedBody: "The shop outside is not public yet — the link may hit a password. Checkout stays on Shopify, not here.",
  shopLockedOpen: "Open anyway (password page)",
  shopLockedCatalog: "Catalog in FlowLine. Checkout only on Shopify.",
  shopLockedBanner: "Shop still closed outside",
  shopLockedPasswordNote:
    "The catalog can live in FlowLine. The store password is not shipped.",
  shopLockedMissingUrl: "Storefront URL missing — the door stays honest.",
  shopNoImage: "No image",
  shopGuideHow: "How the shop works",
  shopCancel: "Back",
  shopExternalLink: "External merchant link",
  shopNetworkError: "Network error.",
  shopProductUnavailable: "Product unavailable",
  shopCheckoutElsewhere: "The merchant is the seller and contract partner — not FlowLine.",
  shopProductMissing: "This product is not in the shop.",
  shopBack: "Back to the shop",
  shopCyclingParts: "Parts",
  shopFeaturedBikes: "Bikes in the shop",
  shopDetails: "Details",
  shopCatalogFailed: "Catalog unreachable right now. Try again later.",
  shopRetry: "Reload",
  shopOpenInApp: "View in the shop",
  shopFitOnly: "Fit only",
  shopFitAllBikes: "All bikes",
  shopFitBannerAll: "Parts that fit your bikes",
  shopOpenInBrowser: "Open in the browser",
  shopZumHaendler: "Buy from the merchant",
  shopMerchantDisclosure:
    "The merchant (Bike24, bike-components, bike-discount) is the seller — not FlowLine.",
  shopCatalogEmpty: "No parts on the shelf yet.",
  shopReplaceHint: "Spares — FlowLine filters by your bike, without inventing SKUs.",
  shopShelfEmpty: "No parts for this search.",
  profileKicker: "You",
  profileTitle: "Profile",
  profileHint: "Account and riding style. After sign-in you stand at Home — no sync theatre with the native app.",
  profileArrive: "Arrive at the yard",
  profileLocalOnly: "Supabase missing — local use without cloud. The app does not silently sync.",
  profileWelcome: "Signed in. The stand is waiting.",
  profileBikesAtStand: "Bikes at the stand",
  profileNoKpi: "No streaks, no invented kilometres.",
  legalKicker: "Legal",
  notFoundTitle: "This door does not exist",
  notFoundHint: "Empty stand. Back to Home, or one of the four doors.",
  rideBridgeTitle: "The road is the app",
  rideBridgeHint: "Live GPS, offline maps, sensors and background recording run native only — not in the browser.",
  ridePlannedKicker: "Planned tour",
  rideBackToMap: "Back to the map",
  downloadTitle: "The app for the road",
  downloadHint: "Home, map and workshop run in the browser. Ride out with HUD — only in the app.",
  activitiesTitle: "What came in",
  activitiesHint: "Rides from the app. Recording stays native — here only what is really there.",
  activitiesEmpty: "No return yet.",
  activitiesEmptyHint: "Rides happen in the app. No fake calendar, no 0 km week.",
  libraryKicker: "Platz",
  libraryHint: "Keep tours, leave a short note, bring friends by link — the same tours as on the map.",
  akteMein: "Share",
  akteStimmen: "Stimmen",
  stimmenPrivateHint: "Still private — after you share, others can comment.",
  plannerKicker: "Map",
  plannerTitle: "Plan",
  plannerHint: "The same door as the map. Navigation starts in the app.",
  checkoutTitle: "Checkout is the shop",
  checkoutHint: "No cart in FlowLine. You buy at the merchant, not here.",
  chatHint: "Power user. No feed at Home. The workshop stays the workshop.",
  coachBell: "Notes",
  privacyKicker: "You",
  privacyHint: "Export, zones, family. No tracking theatre — only what is really there.",
  postRideKicker: "Back at Home",
  postRideTitle: "What came in",
  postRideHint: "Analysis after the ride. Recording stays in the app — honest numbers only here.",
  groupAtGate: "Group at the gate",
  groupLiveNavHint: "Everyone in the group on nav — only in the app, only during the ride, only with opt-in. Not on the map at the gate.",
  signedIn: "Signed in",
  agoMinutes: (n) => String(n) + " min ago",
  agoHours: (n) => String(n) + " h ago",
  packMissing: (n) => "No pack for " + String(n),
  careInWorkshop: (n) => String(n) + " — in the workshop",
  bringForward: (n) => "Bring " + String(n) + " forward",
  sinceDays: (n) => String(n) + " days",
  loopDuration: (n) => "⟲ " + String(n) + " min",
  gateAwayKm: (n) => String(n) + " km",
  skyDry: (n) => String(n) + "° · rather dry",
  skyDamp: (n) => String(n) + "° · damp possible",
  skyWet: (n) => String(n) + "° · rain · trails likely wet",
  shopForYourBikeHint: (n) => "Parts that fit " + String(n) + " — category and wheel size. No invented SKUs.",
  shopFitBanner: (n) => "Parts that fit " + String(n),
  communityNotes: (n) => (n === 1 ? "1 Stimme on this loop" : `${n} Stimmen on this loop`),
  coachTafel: (n) => (n === 1 ? "1 note from the assistant" : `${n} notes from the assistant`),
  coachUnread: (n) => (n === 1 ? "1 new" : `${n} new`),
};

const FR: HofCopy = {
  profile: "Profil",
  rideOut: "Sortir",
  rideOutAgain: "Ressortir",
  openBike: "Ouvrir le vélo",
  parkBike: "Garer le vélo",
  rideWithoutBike: "Rouler sans vélo",
  atGate: "devant le portail",
  emptyStand: "Emplacement vide",
  skyUnknown: "Ciel inconnu",
  gpsUnknown: "Pas de position — ciel et portail attendent le GPS.",
  noHonestLoop: "Pas de vraie boucle trail",
  gateWetClosed: "Trails mouillés — pas de vraie boucle asphaltée à proximité",
  notYetOut: "pas encore dehors",
  justBack: "vient de rentrer",
  lastRideNoGps: "sans trace GPS — rien d'inventé",
  whatCameIn: "Ce qui est rentré",
  atHof: "au stand",
  noBikeHere: "Aucun vélo ici",
  openTours: "Ouvrir les tours",
  yourWatch: "Ta montre",
  sinceOneDay: "depuis 1 jour",
  justRide: "Juste rouler",
  showTours: "Afficher les tours",
  mapChoiceHint: "Pars sans itinéraire, ou affiche les tours sur la carte.",
  gateAwayNear: "moins d’1 km",
  mapTitle: "Carte",
  workshopTitle: "Atelier",
  workshopAdd: "Ajouter un vélo",
  workshopAddAnother: "Autre vélo",
  shopKicker: "De l'autre côté de la cour",
  shopTitle: "Le magasin",
  shopGo: "Vers le magasin",
  shopForYourBike: "Pour ton vélo",
  shopPartsForBike: "Pièces pour ton vélo",
  shopLookupInShop: "Chercher dans le magasin",
  shopForYourBikeEmpty: "Gare un vélo dans l'atelier — ensuite on ouvre les pièces qui collent, dans le magasin.",
  shopMerch: "Vêtements",
  shopMerchHint: "Vêtements et petites choses. Jamais filtrés selon le vélo.",
  shopLockedTitle: "Magasin encore fermé dehors",
  shopSearchHint: "Pièces, marques, specs…",
  shopFeatured: "Pièces qui collent",
  shopOpenProduct: "Ouvrir dans le magasin",
  shopAllParts: "Toutes les pièces",
  privacyTitle: "Données & confidentialité",
  libraryTitle: "Platz",
  libraryMappe: "Die Mappe",
  tafelKicker: "Die Tafel",
  tafelHint: "Une voix ou un groupe — pas de fil.",
  togetherOut: "Sortir ensemble",
  watchHint: "Pouls seulement avec un vrai capteur.",
  watchOpenApp: "Appairer dans l'app",
  watchBar: "Appairer la montre dans l'app",
  workshopCscBar: "Appairer le capteur vélo dans l'app",
  workshopSensorUnpaired: "Capteur vélo non connecté",
  mapJustRideHint: "La carte reste dans le navigateur. HUD GPS, navigation et enregistrement tournent dans l'app.",
  mapKicker: "Devant le portail",
  mapEmptyLoops: "Pas de boucles à proximité",
  mapEmptyLoopsHint: "Seulement de vraies boucles (départ≈arrivée) — pas de tours A→B pour remplir. Change de lieu ou roule dans l'app.",
  mapLoading: "Chargement de la carte…",
  mapSheetNear: "À proximité",
  mapSheetPlan: "Planifier",
  mapSheetTours: "Tours",
  inTheApp: "Dans l'app",
  workshopKicker: "Le vélo",
  workshopHint: "Ton vélo habite ici. Nom et type suffisent. L'entretien vient quand tu veux.",
  workshopEmpty: "Pas encore de vélo ici",
  workshopEmptyHint: "Nom et type suffisent. Le catalogue est une recherche — pièces de série seulement si tu les prends.",
  workshopAddBasicHint: "Nom et type — tout le monde peut le faire",
  workshopAddCatalog: "Chercher dans le catalogue",
  workshopAddCatalogHint: "Trouver un modèle, kit optionnel",
  workshopAddPlaceholder: "Placeholder",
  workshopAddPlaceholderHint: "Sans pièces — trace via Tours",
  workshopTabBox: "Die Box",
  workshopZoneReady: "Prêt",
  workshopZoneToday: "Aujourd'hui",
  workshopLater: "Plus tard",
  workshopZoneOnBike: "Sur le vélo",
  workshopZoneSensor: "Capteur",
  workshopMore: "Plus sur le vélo",
  workshopLoading: "Chargement de l'atelier…",
  workshopTabOverview: "Aperçu",
  workshopTabParts: "Composants",
  workshopTabSetups: "Setup",
  workshopTabCare: "Entretien",
  workshopBikes: "Tes vélos",
  workshopNoWatch: "Appairer les capteurs sur le vélo se fait dans l'app. La montre reste pour la sortie.",
  careFallback: "Entretien",
  shopHint: "Le vélo n'habite pas ici. FlowLine montre des pièces — tu achètes chez le revendeur, pas ici. La caisse Shopify est coupée pour l’instant.",
  shopPausedTitle: "Le magasin est en pause",
  shopPausedHint:
    "Shopify et le magasin de pièces sont coupés pour l’instant. L’atelier reste — vélo, setup et entretien sans caisse.",
  shopLockedBody: "Le magasin dehors n'est pas encore public — le lien peut tomber sur un mot de passe. La caisse reste chez Shopify, pas ici.",
  shopLockedOpen: "Ouvrir quand même (page mot de passe)",
  shopLockedCatalog: "Catalogue dans FlowLine. Caisse seulement chez Shopify.",
  shopLockedBanner: "Magasin encore fermé dehors",
  shopLockedPasswordNote:
    "Le catalogue peut vivre dans FlowLine. Le mot de passe du store n’est pas livré.",
  shopLockedMissingUrl: "URL Storefront manquante — la porte reste honnête.",
  shopNoImage: "Pas d’image",
  shopGuideHow: "Comment le magasin marche",
  shopCancel: "Retour",
  shopExternalLink: "Lien revendeur externe",
  shopNetworkError: "Erreur réseau.",
  shopProductUnavailable: "Produit indisponible",
  shopCheckoutElsewhere: "Le revendeur est vendeur et partenaire contractuel — pas FlowLine.",
  shopProductMissing: "Ce produit n'est pas dans le magasin.",
  shopBack: "Retour au magasin",
  shopCyclingParts: "Pièces",
  shopFeaturedBikes: "Vélos dans le magasin",
  shopDetails: "Détails",
  shopCatalogFailed: "Catalogue injoignable pour l'instant. Réessaie plus tard.",
  shopRetry: "Recharger",
  shopOpenInApp: "Voir dans le magasin",
  shopFitOnly: "Seulement ce qui colle",
  shopFitAllBikes: "Tous les vélos",
  shopFitBannerAll: "Pièces qui vont à tes vélos",
  shopOpenInBrowser: "Ouvrir dans le navigateur",
  shopZumHaendler: "Acheter chez le revendeur",
  shopMerchantDisclosure:
    "Le revendeur (Bike24, bike-components, bike-discount) est le vendeur — pas FlowLine.",
  shopCatalogEmpty: "Pas encore de pièces en rayon.",
  shopReplaceHint: "Rechange — FlowLine filtre selon ton vélo, sans inventer de SKU.",
  shopShelfEmpty: "Aucune pièce pour cette recherche.",
  profileKicker: "Toi",
  profileTitle: "Profil",
  profileHint: "Compte et style. Après connexion tu es à Home — pas de théâtre de sync avec l'app native.",
  profileArrive: "Arriver",
  profileLocalOnly: "Supabase manque — usage local sans cloud. L'app ne synchronise pas en silence.",
  profileWelcome: "Connecté. Le stand attend.",
  profileBikesAtStand: "Vélos au stand",
  profileNoKpi: "Pas de streaks, pas de kilomètres inventés.",
  legalKicker: "Mentions",
  notFoundTitle: "Cette porte n'existe pas",
  notFoundHint: "Stand vide. Retour à Home, ou une des quatre portes.",
  rideBridgeTitle: "La route, c'est l'app",
  rideBridgeHint: "GPS live, cartes hors-ligne, capteurs et enregistrement en arrière-plan tournent seulement en natif — pas dans le navigateur.",
  ridePlannedKicker: "Tour prévu",
  rideBackToMap: "Retour à la carte",
  downloadTitle: "L'app pour la route",
  downloadHint: "Home, carte et atelier tournent dans le navigateur. Sortir avec HUD — seulement dans l'app.",
  activitiesTitle: "Ce qui est rentré",
  activitiesHint: "Sorties depuis l'app. L'enregistrement reste natif — ici seulement ce qui est vraiment là.",
  activitiesEmpty: "Pas encore de retour.",
  activitiesEmptyHint: "Les sorties naissent dans l'app. Pas de calendrier fake, pas de semaine à 0 km.",
  libraryKicker: "Platz",
  libraryHint: "Garder des sorties, écrire court, emmener des amis par lien — les mêmes tours que sur la carte.",
  akteMein: "Partager",
  akteStimmen: "Stimmen",
  stimmenPrivateHint: "Encore privé — après partage, les autres peuvent commenter.",
  plannerKicker: "Carte",
  plannerTitle: "Planifier",
  plannerHint: "La même porte que la carte. La navigation démarre dans l'app.",
  checkoutTitle: "La caisse, c'est le magasin",
  checkoutHint: "Pas de panier dans FlowLine. L'achat est chez le revendeur, pas ici.",
  chatHint: "Power-user. Pas de feed à Home. L'atelier reste l'atelier.",
  coachBell: "Notes",
  privacyKicker: "Toi",
  privacyHint: "Export, zones, famille. Pas de théâtre de tracking — seulement ce qui est vraiment là.",
  postRideKicker: "De retour à Home",
  postRideTitle: "Ce qui est rentré",
  postRideHint: "Analyse après la sortie. L'enregistrement reste dans l'app — ici seulement des chiffres honnêtes.",
  groupAtGate: "Groupe devant le portail",
  groupLiveNavHint: "Tout le groupe sur la nav — seulement dans l'app, seulement pendant la sortie, seulement avec opt-in. Pas sur la carte devant le portail.",
  signedIn: "Connecté",
  agoMinutes: (n) => "il y a " + String(n) + " min",
  agoHours: (n) => "il y a " + String(n) + " h",
  packMissing: (n) => "Pas de pack pour " + String(n),
  careInWorkshop: (n) => String(n) + " — dans l'atelier",
  bringForward: (n) => "Mettre " + String(n) + " devant",
  sinceDays: (n) => "depuis " + String(n) + " jours",
  loopDuration: (n) => "⟲ " + String(n) + " min",
  gateAwayKm: (n) => String(n) + " km",
  skyDry: (n) => String(n) + "° · plutôt sec",
  skyDamp: (n) => String(n) + "° · humidité possible",
  skyWet: (n) => String(n) + "° · pluie · trails plutôt mouillés",
  shopForYourBikeHint: (n) => "Pièces qui vont à " + String(n) + " — catégorie et roue. Pas de SKU inventés.",
  shopFitBanner: (n) => "Pièces qui vont à " + String(n),
  communityNotes: (n) => (n === 1 ? "1 Stimme sur cette boucle" : `${n} Stimmen sur cette boucle`),
  coachTafel: (n) => (n === 1 ? "1 note de l'assistant" : `${n} notes de l'assistant`),
  coachUnread: (n) => (n === 1 ? "1 nouveau" : `${n} nouveaux`),
};

const IT: HofCopy = {
  profile: "Profilo",
  rideOut: "Esci",
  rideOutAgain: "Esci di nuovo",
  openBike: "Apri la bici",
  parkBike: "Parcheggia la bici",
  rideWithoutBike: "Pedala senza bici",
  atGate: "davanti al cancello",
  emptyStand: "Posto vuoto",
  skyUnknown: "Cielo sconosciuto",
  gpsUnknown: "Nessuna posizione — cielo e cancello aspettano il GPS.",
  noHonestLoop: "Nessun anello trail onesto",
  gateWetClosed: "Trail bagnati — nessun anello asfaltato onesto qui vicino",
  notYetOut: "non ancora fuori",
  justBack: "appena rientrato",
  lastRideNoGps: "senza traccia GPS — niente di inventato",
  whatCameIn: "Cosa è rientrato",
  atHof: "al posto",
  noBikeHere: "Nessuna bici qui",
  openTours: "Apri i tour",
  yourWatch: "Il tuo orologio",
  sinceOneDay: "da 1 giorno",
  justRide: "Pedala e basta",
  showTours: "Mostra i tour",
  mapChoiceHint: "Parti senza itinerario, o mostra i tour sulla mappa.",
  gateAwayNear: "meno di 1 km",
  mapTitle: "Mappa",
  workshopTitle: "Officina",
  workshopAdd: "Aggiungi una bici",
  workshopAddAnother: "Altra bici",
  shopKicker: "Dall'altra parte del cortile",
  shopTitle: "Il negozio",
  shopGo: "Al negozio",
  shopForYourBike: "Per la tua bici",
  shopPartsForBike: "Pezzi per la tua bici",
  shopLookupInShop: "Cerca nel negozio",
  shopForYourBikeEmpty: "Parcheggia una bici in officina — poi apriamo i pezzi che calzano, nel negozio.",
  shopMerch: "Abbigliamento",
  shopMerchHint: "Abbigliamento e oggettistica. Mai filtrati sulla bici.",
  shopLockedTitle: "Negozio ancora chiuso fuori",
  shopSearchHint: "Pezzi, marche, specs…",
  shopFeatured: "Pezzi che calzano",
  shopOpenProduct: "Apri nel negozio",
  shopAllParts: "Tutti i pezzi",
  privacyTitle: "Dati e privacy",
  libraryTitle: "Platz",
  libraryMappe: "Die Mappe",
  tafelKicker: "Die Tafel",
  tafelHint: "Una voce o un gruppo — non un feed.",
  togetherOut: "Uscire insieme",
  watchHint: "Battito solo con un vero sensore.",
  watchOpenApp: "Accoppia nell'app",
  watchBar: "Accoppia l'orologio nell'app",
  workshopCscBar: "Accoppia il sensore bici nell'app",
  workshopSensorUnpaired: "Sensore bici non collegato",
  mapJustRideHint: "La mappa resta nel browser. HUD GPS, navigazione e registrazione girano nell'app.",
  mapKicker: "Davanti al cancello",
  mapEmptyLoops: "Nessun anello qui vicino",
  mapEmptyLoopsHint: "Solo anelli veri (partenza≈arrivo) — niente tour A→B di riempimento. Cambia luogo o pedala nell'app.",
  mapLoading: "Caricamento mappa…",
  mapSheetNear: "Nelle vicinanze",
  mapSheetPlan: "Pianifica",
  mapSheetTours: "Tour",
  inTheApp: "Nell'app",
  workshopKicker: "La bici",
  workshopHint: "La tua bici vive qui. Nome e tipo bastano. La cura arriva quando vuoi.",
  workshopEmpty: "Ancora nessuna bici qui",
  workshopEmptyHint: "Nome e tipo bastano. Il catalogo è ricerca — pezzi di serie solo se li prendi.",
  workshopAddBasicHint: "Nome e tipo — chiunque può farlo",
  workshopAddCatalog: "Cerca nel catalogo",
  workshopAddCatalogHint: "Trova un modello, kit opzionale",
  workshopAddPlaceholder: "Segnaposto",
  workshopAddPlaceholderHint: "Senza pezzi — traccia via Tour",
  workshopTabBox: "Die Box",
  workshopZoneReady: "Pronto",
  workshopZoneToday: "Oggi",
  workshopLater: "Più tardi",
  workshopZoneOnBike: "Sulla bici",
  workshopZoneSensor: "Sensore",
  workshopMore: "Altro sulla bici",
  workshopLoading: "Caricamento officina…",
  workshopTabOverview: "Panoramica",
  workshopTabParts: "Componenti",
  workshopTabSetups: "Setup",
  workshopTabCare: "Manutenzione",
  workshopBikes: "Le tue bici",
  workshopNoWatch: "Accoppiare i sensori sulla bici si fa nell'app. L'orologio resta per l'uscita.",
  careFallback: "Cura",
  shopHint: "La bici non vive qui. FlowLine mostra pezzi — compri dal rivenditore, non qui. La cassa Shopify è spenta per ora.",
  shopPausedTitle: "Il negozio è in pausa",
  shopPausedHint:
    "Shopify e il negozio pezzi sono spenti per ora. L’officina resta — bici, setup e manutenzione senza cassa.",
  shopLockedBody: "Il negozio fuori non è ancora pubblico — il link può finire su una password. La cassa resta su Shopify, non qui.",
  shopLockedOpen: "Apri lo stesso (pagina password)",
  shopLockedCatalog: "Catalogo in FlowLine. Cassa solo su Shopify.",
  shopLockedBanner: "Negozio ancora chiuso fuori",
  shopLockedPasswordNote:
    "Il catalogo può stare in FlowLine. La password dello store non viene consegnata.",
  shopLockedMissingUrl: "URL Storefront mancante — la porta resta onesta.",
  shopNoImage: "Nessuna immagine",
  shopGuideHow: "Come funziona il negozio",
  shopCancel: "Indietro",
  shopExternalLink: "Link rivenditore esterno",
  shopNetworkError: "Errore di rete.",
  shopProductUnavailable: "Prodotto non disponibile",
  shopCheckoutElsewhere: "Il rivenditore è venditore e contraente — non FlowLine.",
  shopProductMissing: "Questo prodotto non è nel negozio.",
  shopBack: "Torna al negozio",
  shopCyclingParts: "Pezzi",
  shopFeaturedBikes: "Bici nel negozio",
  shopDetails: "Dettagli",
  shopCatalogFailed: "Catalogo irraggiungibile al momento. Riprova più tardi.",
  shopRetry: "Ricarica",
  shopOpenInApp: "Vedi nel negozio",
  shopFitOnly: "Solo ciò che calza",
  shopFitAllBikes: "Tutte le bici",
  shopFitBannerAll: "Pezzi che stanno alle tue bici",
  shopOpenInBrowser: "Apri nel browser",
  shopZumHaendler: "Compra dal rivenditore",
  shopMerchantDisclosure:
    "Il rivenditore (Bike24, bike-components, bike-discount) è il venditore — non FlowLine.",
  shopCatalogEmpty: "Ancora nessun pezzo in scaffale.",
  shopReplaceHint: "Ricambi — FlowLine filtra sulla tua bici, senza inventare SKU.",
  shopShelfEmpty: "Nessun pezzo per questa ricerca.",
  profileKicker: "Tu",
  profileTitle: "Profilo",
  profileHint: "Account e stile. Dopo l'accesso stai a Home — niente teatro di sync con l'app nativa.",
  profileArrive: "Arriva al cortile",
  profileLocalOnly: "Supabase manca — uso locale senza cloud. L'app non sincronizza in silenzio.",
  profileWelcome: "Accesso fatto. Lo stand aspetta.",
  profileBikesAtStand: "Bici allo stand",
  profileNoKpi: "Niente streak, niente chilometri inventati.",
  legalKicker: "Legale",
  notFoundTitle: "Questa porta non esiste",
  notFoundHint: "Stand vuoto. Torna a Home, o una delle quattro porte.",
  rideBridgeTitle: "La strada è l'app",
  rideBridgeHint: "GPS live, mappe offline, sensori e registrazione in background girano solo in nativo — non nel browser.",
  ridePlannedKicker: "Tour pianificato",
  rideBackToMap: "Torna alla mappa",
  downloadTitle: "L'app per la strada",
  downloadHint: "Home, mappa e officina girano nel browser. Esci con HUD — solo nell'app.",
  activitiesTitle: "Cosa è rientrato",
  activitiesHint: "Uscite dall'app. La registrazione resta nativa — qui solo ciò che c'è davvero.",
  activitiesEmpty: "Ancora nessun ritorno.",
  activitiesEmptyHint: "Le uscite nascono nell'app. Niente calendario finto, niente settimana a 0 km.",
  libraryKicker: "Platz",
  libraryHint: "Tenere uscite, scrivere breve, portare amici col link — gli stessi tour che sulla mappa.",
  akteMein: "Condividi",
  akteStimmen: "Stimmen",
  stimmenPrivateHint: "Ancora privato — dopo la condivisione gli altri possono commentare.",
  plannerKicker: "Mappa",
  plannerTitle: "Pianifica",
  plannerHint: "La stessa porta della mappa. La navigazione parte nell'app.",
  checkoutTitle: "La cassa è il negozio",
  checkoutHint: "Niente carrello in FlowLine. L'acquisto è dal rivenditore, non qui.",
  chatHint: "Power user. Niente feed a Home. L'officina resta l'officina.",
  coachBell: "Note",
  privacyKicker: "Tu",
  privacyHint: "Export, zone, famiglia. Niente teatro di tracking — solo ciò che c'è davvero.",
  postRideKicker: "Di nuovo a Home",
  postRideTitle: "Cosa è rientrato",
  postRideHint: "Analisi dopo l'uscita. La registrazione resta nell'app — qui solo numeri onesti.",
  groupAtGate: "Gruppo davanti al cancello",
  groupLiveNavHint: "Tutto il gruppo sul navi — solo nell'app, solo durante l'uscita, solo con opt-in. Non sulla mappa davanti al cancello.",
  signedIn: "Accesso fatto",
  agoMinutes: (n) => String(n) + " min fa",
  agoHours: (n) => String(n) + " h fa",
  packMissing: (n) => "Manca il pack per " + String(n),
  careInWorkshop: (n) => String(n) + " — in officina",
  bringForward: (n) => "Porta avanti " + String(n),
  sinceDays: (n) => "da " + String(n) + " giorni",
  loopDuration: (n) => "⟲ " + String(n) + " min",
  gateAwayKm: (n) => String(n) + " km",
  skyDry: (n) => String(n) + "° · piuttosto secco",
  skyDamp: (n) => String(n) + "° · umido possibile",
  skyWet: (n) => String(n) + "° · pioggia · trail piuttosto bagnati",
  shopForYourBikeHint: (n) => "Pezzi che stanno a " + String(n) + " — categoria e ruota. Niente SKU inventati.",
  shopFitBanner: (n) => "Pezzi che stanno a " + String(n),
  communityNotes: (n) => (n === 1 ? "1 Stimme su questo anello" : `${n} Stimmen su questo anello`),
  coachTafel: (n) => (n === 1 ? "1 nota dall'assistente" : `${n} note dall'assistente`),
  coachUnread: (n) => (n === 1 ? "1 nuovo" : `${n} nuovi`),
};

const BY_LANG: Record<ChromeLang, HofCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
};

export function hofCopy(lang: ChromeLang = "de"): HofCopy {
  return BY_LANG[lang];
}

/** German fallback — metadata, tests, first paint. */
export const HOF_COPY = hofCopy("de");
