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
  homeTitle: string;
  homeHint: string;
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
  workshopTabBox: string;
  workshopZoneReady: string;
  workshopZoneToday: string;
  workshopLater: string;
  workshopZoneOnBike: string;
  workshopZoneSensor: string;
  workshopMore: string;
  workshopSchemaHint: string;
  workshopSchemaLegendOk: string;
  workshopSchemaLegendOpen: string;
  workshopSchemaLegendDue: string;
  workshopFamilyYou: string;
  workshopFamilyHint: string;
  workshopFamilyHintEmpty: string;
  workshopFamilyAdd: string;
  workshopFamilyName: string;
  workshopFamilyWeight: string;
  workshopSchemaMoreOnDots: string;
  workshopReceiptPhoto: string;
  workshopBoxAlmost: string;
  workshopBoxUnknown: string;
  workshopAddPart: string;
  workshopPartsEmpty: string;
  workshopMaintLog: string;
  workshopReport: string;
  workshopLoading: string;
  workshopTabOverview: string;
  workshopTabParts: string;
  workshopTabSetups: string;
  workshopTabCare: string;
  workshopStatKm: string;
  workshopStatHours: string;
  workshopStatPressure: string;
  workshopStatService: string;
  workshopStatDash: string;
  workshopStatDueNow: string;
  workshopStatCare: string;
  workshopStandTitle: string;
  workshopStandHint: string;
  workshopStandSave: string;
  workshopNextService: string;
  workshopNextServiceHint: string;
  workshopWearTitle: string;
  workshopWearHint: string;
  workshopWearEmpty: string;
  workshopDueTitle: string;
  workshopDueAdjusted: string;
  workshopDueOverdue: string;
  workshopDueSoon: string;
  workshopDueDone: string;
  workshopDueEmpty: string;
  workshopReceiptTitle: string;
  workshopReceiptPlaceholder: string;
  workshopReceiptAmount: string;
  workshopReceiptNote: string;
  workshopReceiptSaved: string;
  workshopReceiptSave: string;
  workshopPerformerWorkshop: string;
  workshopPerformerSelf: string;
  workshopMaintEmpty: string;
  workshopMaintDefaults: string;
  workshopMaintCost: (amount: string) => string;
  workshopStandStravaHint: string;
  workshopStandOpen: string;
  workshopPhotoRetake: string;
  workshopPhotoRetakeHint: string;
  workshopPhotoCropTitle: string;
  workshopPhotoCropHint: string;
  workshopPhotoCropSave: string;
  workshopPhotoRotate: string;
  workshopPhotoPlace: string;
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
  profileLanguage: string;
  profileLanguageHint: string;
  profileLanguageAuto: string;
  profileDisciplines: string;
  profileDisciplinesHint: string;
  profilePrimary: string;
  profileAlso: string;
  profileStyle: string;
  profileStyleIndicators: string;
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
  rideSurface: (surface: string) => string;
  rideSyncedHint: string;
  rideClearSelection: string;
  rideNoTrackHint: string;
  rideOpenPlanner: string;
  rideNoTourBefore: string;
  rideNoTourLink: string;
  rideNoTourAfter: string;
  rideDownloadApp: string;
  rideOpenAppDirect: string;
  rideOpenInApp: string;
  rideWebLinkToApp: string;
  rideContinueOnMap: string;
  rideContinueOnMapHint: string;
  rideWhyApp: string;
  rideWhyAppHint: string;
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
  parkBike: "Rad anlegen",
  rideWithoutBike: "Ohne Rad fahren",
  atGate: "vor dem Tor",
  emptyStand: "Leerer Stand",
  homeTitle: "Start",
  homeHint: "Dein Rad und ein Knopf: Losfahren. Kein Feed.",
  skyUnknown: "Himmel unbekannt",
  gpsUnknown: "Standort erlauben",
  noHonestLoop: "Keine Runde in der Nähe",
  gateWetClosed: "Trails nass — kein ehrlicher Asphalt-Rundkurs in der Nähe",
  notYetOut: "noch nicht draußen",
  justBack: "gerade reingekommen",
  lastRideNoGps: "ohne GPS-Track — kein erfundener Verlauf",
  whatCameIn: "Was reinkam",
  atHof: "am Hof",
  noBikeHere: "Kein Rad steht hier",
  openTours: "Touren auf der Karte",
  yourWatch: "Deine Uhr",
  sinceOneDay: "seit 1 Tag",
  justRide: "Einfach fahren",
  showTours: "Touren anzeigen",
  mapChoiceHint: "Ohne Touren losfahren, oder Touren auf der Karte zeigen.",
  gateAwayNear: "unter 1 km",
  mapTitle: "Karte",
  workshopTitle: "Rad",
  workshopAdd: "Rad anlegen",
  workshopAddAnother: "Weiteres Rad",
  shopKicker: "Über den Hof",
  shopTitle: "Der Laden",
  shopGo: "Zum Shop",
  shopForYourBike: "Für dein Rad",
  shopPartsForBike: "Teile für dein Rad",
  shopLookupInShop: "Im Laden nachschlagen",
  shopForYourBikeEmpty: "Lege ein Rad am Stand an — dann öffnen wir die passenden Teile im Shop.",
  shopMerch: "Kleidung",
  shopMerchHint: "Kleidung und Kleinzeug. Unabhängig vom Rad, nie nach Fit gefiltert.",
  shopLockedTitle: "Shop draußen noch zu",
  shopSearchHint: "Teile, Marken, Specs…",
  shopFeatured: "Passende Teile",
  shopOpenProduct: "Im Shop öffnen",
  shopAllParts: "Alle Teile",
  privacyTitle: "Daten & Privatsphäre",
  libraryTitle: "Touren",
  libraryMappe: "Die Mappe",
  tafelKicker: "Die Tafel",
  tafelHint: "Stimme, Gruppe oder Freigabe — kein Feed.",
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
  workshopEmpty: "Noch kein Rad am Stand",
  workshopEmptyHint: "Name und Typ reichen. Marke und Teile kannst du später ergänzen.",
  workshopTabBox: "Die Box",
  workshopZoneReady: "Bereit",
  workshopZoneToday: "Heute",
  workshopLater: "Später",
  workshopZoneOnBike: "Am Rad",
  workshopZoneSensor: "Sensor",
  workshopMore: "Mehr am Rad",
  workshopSchemaHint: "Tippe auf einen Punkt — eintragen oder ändern.",
  workshopSchemaLegendOk: "da",
  workshopSchemaLegendOpen: "offen",
  workshopSchemaLegendDue: "fällig",
  workshopFamilyYou: "Ich",
  workshopFamilyHint: "Gewicht und Setup für diesen Fahrer.",
  workshopFamilyHintEmpty: "Gewicht für Kind oder Partner — hier anlegen.",
  workshopFamilyAdd: "Fahrer anlegen",
  workshopFamilyName: "Name",
  workshopFamilyWeight: "kg",
  workshopSchemaMoreOnDots: "Weitere Lücken am Punkt.",
  workshopReceiptPhoto: "Foto der Rechnung",
  workshopBoxAlmost: "Fast bereit",
  workshopBoxUnknown: "Noch unklar",
  workshopAddPart: "Teil hinzufügen",
  workshopPartsEmpty:
    "Noch keine Teile. Katalog ist Suche — nichts muss vollständig sein.",
  workshopMaintLog: "Wartungslog",
  workshopReport: "Report",
  workshopLoading: "Rad wird geladen…",
  workshopTabOverview: "Übersicht",
  workshopTabParts: "Teile",
  workshopTabSetups: "Setup",
  workshopTabCare: "Wartung",
  workshopStatKm: "KM",
  workshopStatHours: "STD.",
  workshopStatPressure: "Druck",
  workshopStatService: "Termin",
  workshopStatDash: "—",
  workshopStatDueNow: "Jetzt",
  workshopStatCare: "Pflege",
  workshopStandTitle: "Kilometer & Stunden",
  workshopStandHint:
    "Stand vom Computer oder Tacho. Stunden rechnen wir nicht aus km.",
  workshopStandSave: "Stand übernehmen",
  workshopNextService: "Nächster Werkstatt-Termin",
  workshopNextServiceHint:
    "Gebuchtes Datum. Intervalle darunter sind Pflege, kein Termin.",
  workshopStandOpen: "Stand setzen",
  workshopStandStravaHint:
    "Automatischer Strava-Sync ist geplant — bis dahin derselbe Dialog wie unter dem Foto. Kein stiller Import.",
  workshopWearTitle: "Verschleißprognose",
  workshopWearHint: "Belastungsgewichtet · Spanne, nie Punktwert.",
  workshopWearEmpty: "Keine Verschleißteile mit Historie.",
  workshopDueTitle: "Fälligkeiten",
  workshopDueAdjusted: "angepasst",
  workshopDueOverdue: "überfällig",
  workshopDueSoon: "bald",
  workshopDueDone: "Erledigt",
  workshopDueEmpty: "Keine Intervalle — Komponenten einbauen.",
  workshopReceiptTitle: "Beleg merken",
  workshopReceiptPlaceholder: "Werkstatt, Teil, Garantie",
  workshopReceiptAmount: "Betrag €",
  workshopReceiptNote: "Notiz",
  workshopReceiptSaved: "Gespeichert",
  workshopReceiptSave: "Beleg merken",
  workshopPerformerWorkshop: "Werkstatt",
  workshopPerformerSelf: "Eigen",
  workshopMaintCost: (amount) => `Kosten gesamt: ${amount} €`,
  workshopMaintEmpty: "Noch kein Log.",
  workshopMaintDefaults:
    "Defaults u. a. RockShox 50 h Lower Leg / 200 h Full, Kette prüfen ~1000 km, Tubeless-Milch ~120 Tage.",
  workshopPhotoRetake: "Neu aufnehmen",
  workshopPhotoRetakeHint:
    "Das Foto füllt den Stand nicht. Neu aufnehmen, dann liegt das Rad auf der Schiene.",
  workshopPhotoCropTitle: "Rad auf den Stand legen",
  workshopPhotoCropHint:
    "Verschiebe das Bild, bis das Rad auf der Schiene sitzt.",
  workshopPhotoCropSave: "So legen",
  workshopPhotoRotate: "90° drehen",
  workshopPhotoPlace: "Auf den Stand legen",
  workshopBikes: "Deine Räder",
  workshopNoWatch: "Sensoren am Rad koppeln geht in der App. Die Uhr bleibt beim Fahren.",
  careFallback: "Pflege",
  shopHint: "Hier wohnt das Rad nicht. FlowLine zeigt Teile — kaufen tust du beim Händler, nicht hier. Shopify-Kasse ist vorerst aus.",
  shopPausedTitle: "Der Laden pausiert",
  shopPausedHint:
    "Der Laden ist vorerst zu. Das Rad bleibt — Setup und Wartung.",
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
  profileLanguage: "Sprache",
  profileLanguageHint:
    "Dieselben fünf Sprachen wie die App. Gerät folgt diesem Browser — nicht dem Handy.",
  profileLanguageAuto: "Gerät",
  profileDisciplines: "Deine Disziplinen",
  profileDisciplinesHint:
    "Vorlieben für Touren. Routing folgt dem aktiven Rad, nicht dieser Liste allein.",
  profilePrimary: "Haupt",
  profileAlso: "auch",
  profileStyle: "Fahrstil",
  profileStyleIndicators: "Fahrstil-Indikatoren",
  profileArrive: "Am Hof ankommen",
  profileLocalOnly: "Supabase fehlt — lokale Nutzung ohne Cloud. Die App sync’t nicht still mit.",
  profileWelcome: "Angemeldet. Der Stand wartet.",
  profileBikesAtStand: "Räder am Stand",
  profileNoKpi: "Keine Streaks, keine erfundenen Kilometer.",
  legalKicker: "Rechtliches",
  notFoundTitle: "Diese Tür gibt es nicht",
  notFoundHint: "Leerer Stand. Zurück zum Hof, oder eine der vier Türen.",
  rideBridgeTitle: "Die Straße ist die App",
  rideBridgeHint: "Live-GPS, Offline-Routing, Sensoren und Hintergrund-Aufzeichnung laufen nur nativ — nicht im Browser.",
  ridePlannedKicker: "Geplante Tour",
  rideBackToMap: "Zurück zur Karte",
  rideSurface: (surface) => `Belag: ${surface}`,
  rideSyncedHint:
    "Die Route ist in deinem Browser gemerkt. Nach dem Login in der App erscheint sie unter Karte bzw. als aktive Tour (Sync).",
  rideClearSelection: "Tour-Auswahl verwerfen",
  rideNoTrackHint: "Noch kein Track — zuerst Ziel setzen im Planer.",
  rideOpenPlanner: "Im Planer öffnen",
  rideNoTourBefore: "Noch keine Tour ausgewählt. Plane eine Route unter ",
  rideNoTourLink: "Karte",
  rideNoTourAfter: ", speichere sie und starte dann in der App.",
  rideDownloadApp: "App herunterladen",
  rideOpenAppDirect: "App direkt öffnen",
  rideOpenInApp: "In der App öffnen",
  rideWebLinkToApp: "Web-Link zur App",
  rideContinueOnMap: "Weiter auf der Karte",
  rideContinueOnMapHint: "OSM · Rundkurse · Planen",
  rideWhyApp: "Warum die App?",
  rideWhyAppHint: "Navigation, Offline, Sensoren",
  downloadTitle: "Die App für unterwegs",
  downloadHint: "Der Hof, die Karte und das Rad laufen im Browser. Rausfahren mit HUD — nur in der App.",
  activitiesTitle: "Was reinkam",
  activitiesHint: "Fahrten aus der App. Höhe und Neigung nur, wenn der Track sie trägt.",
  activitiesEmpty: "Noch keine Rückkehr.",
  activitiesEmptyHint: "Fahrten entstehen in der App. Kein Fake-Kalender, keine 0-km-Woche.",
  libraryKicker: "Platz",
  libraryHint: "Touren merken, Stimmen und Freunde an der Strecke — dieselben wie auf der Karte.",
  akteMein: "Akte",
  akteStimmen: "Stimmen",
  stimmenPrivateHint: "Noch privat — nach Freigabe können andere kommentieren.",
  plannerKicker: "Karte",
  plannerTitle: "Planen",
  plannerHint: "Dieselbe Tür wie die Karte. Navigation startet in der App.",
  checkoutTitle: "Kasse ist der Laden",
  checkoutHint: "Kein Warenkorb in FlowLine. Kauf liegt beim Händler, nicht hier.",
  chatHint: "Power-User. Kein Feed auf dem Hof. Das Rad bleibt das Rad.",
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
  careInWorkshop: (n) => String(n) + " — am Rad",
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
  parkBike: "Add a bike",
  rideWithoutBike: "Ride without a bike",
  atGate: "at the gate",
  emptyStand: "Empty stand",
  homeTitle: "Home",
  homeHint: "Your bike and one button: ride out. No feed.",
  skyUnknown: "Sky unknown",
  gpsUnknown: "Allow location",
  noHonestLoop: "No loop nearby",
  gateWetClosed: "Trails wet — no honest paved loop nearby",
  notYetOut: "not out yet",
  justBack: "just back",
  lastRideNoGps: "no GPS track — nothing invented",
  whatCameIn: "What came in",
  atHof: "at the stand",
  noBikeHere: "No bike here",
  openTours: "Tours on the map",
  yourWatch: "Your watch",
  sinceOneDay: "1 day",
  justRide: "Just ride",
  showTours: "Show tours",
  mapChoiceHint: "Ride without a route, or show tours on the map.",
  gateAwayNear: "under 1 km",
  mapTitle: "Map",
  workshopTitle: "Bike",
  workshopAdd: "Add a bike",
  workshopAddAnother: "Another bike",
  shopKicker: "Across the yard",
  shopTitle: "The shop",
  shopGo: "Open shop",
  shopForYourBike: "For your bike",
  shopPartsForBike: "Parts for your bike",
  shopLookupInShop: "Look up in the shop",
  shopForYourBikeEmpty: "Add a bike at the stand — then we open matching parts in the shop.",
  shopMerch: "Apparel",
  shopMerchHint: "Apparel and small goods. Never filtered by bike fit.",
  shopLockedTitle: "Shop still closed outside",
  shopSearchHint: "Search parts, brands, specs…",
  shopFeatured: "Matching parts",
  shopOpenProduct: "Open in shop",
  shopAllParts: "All parts",
  privacyTitle: "Data & privacy",
  libraryTitle: "Tours",
  libraryMappe: "Die Mappe",
  tafelKicker: "Die Tafel",
  tafelHint: "A voice, a group or a listing — not a feed.",
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
  workshopEmpty: "No bike at the stand yet",
  workshopEmptyHint: "Name and type are enough. Brand and parts can wait.",
  workshopTabBox: "Die Box",
  workshopZoneReady: "Ready",
  workshopZoneToday: "Today",
  workshopLater: "Later",
  workshopZoneOnBike: "On the bike",
  workshopZoneSensor: "Sensor",
  workshopMore: "More on the bike",
  workshopSchemaHint: "Tap a point — add or change the part.",
  workshopSchemaLegendOk: "on",
  workshopSchemaLegendOpen: "open",
  workshopSchemaLegendDue: "due",
  workshopFamilyYou: "Me",
  workshopFamilyHint: "Weight and setup for this rider.",
  workshopFamilyHintEmpty: "Weight for a kid or partner — add them here.",
  workshopFamilyAdd: "Add rider",
  workshopFamilyName: "Name",
  workshopFamilyWeight: "kg",
  workshopSchemaMoreOnDots: "More gaps on the dots.",
  workshopReceiptPhoto: "Photo of the invoice",
  workshopBoxAlmost: "Almost ready",
  workshopBoxUnknown: "Still unclear",
  workshopAddPart: "Add part",
  workshopPartsEmpty:
    "No parts yet. The catalog is search — nothing has to be complete.",
  workshopMaintLog: "Maintenance log",
  workshopReport: "Report",
  workshopLoading: "Loading bike…",
  workshopTabOverview: "Overview",
  workshopTabParts: "Parts",
  workshopTabSetups: "Setup",
  workshopTabCare: "Service",
  workshopStatKm: "KM",
  workshopStatHours: "HRS",
  workshopStatPressure: "Pressure",
  workshopStatService: "Service",
  workshopStatDash: "—",
  workshopStatDueNow: "Now",
  workshopStatCare: "Care",
  workshopStandTitle: "Kilometres & hours",
  workshopStandHint:
    "Reading from the computer or odometer. We do not invent hours from km.",
  workshopStandSave: "Save reading",
  workshopNextService: "Next workshop date",
  workshopNextServiceHint:
    "Booked date. Intervals below are care, not an appointment.",
  workshopStandOpen: "Set reading",
  workshopStandStravaHint:
    "Automatic Strava sync is planned — until then the same dialog as under the photo. No silent import.",
  workshopWearTitle: "Wear forecast",
  workshopWearHint: "Load-weighted · a range, never a point value.",
  workshopWearEmpty: "No wear parts with history.",
  workshopDueTitle: "Due items",
  workshopDueAdjusted: "adjusted",
  workshopDueOverdue: "overdue",
  workshopDueSoon: "soon",
  workshopDueDone: "Done",
  workshopDueEmpty: "No intervals — add components.",
  workshopReceiptTitle: "Save a receipt",
  workshopReceiptPlaceholder: "Shop, part, warranty",
  workshopReceiptAmount: "Amount €",
  workshopReceiptNote: "Note",
  workshopReceiptSaved: "Saved",
  workshopReceiptSave: "Save receipt",
  workshopPerformerWorkshop: "Workshop",
  workshopPerformerSelf: "Self",
  workshopMaintCost: (amount) => `Total cost: ${amount} €`,
  workshopMaintEmpty: "No log yet.",
  workshopMaintDefaults:
    "Defaults include RockShox 50 h lower leg / 200 h full, chain check ~1000 km, tubeless sealant ~120 days.",
  workshopPhotoRetake: "Retake",
  workshopPhotoRetakeHint:
    "This photo does not fill the stand. Retake so the bike sits on the rail.",
  workshopPhotoCropTitle: "Set the bike on the stand",
  workshopPhotoCropHint: "Drag the photo until the bike sits on the rail.",
  workshopPhotoCropSave: "Place it",
  workshopPhotoRotate: "Rotate 90°",
  workshopPhotoPlace: "Set on the stand",
  workshopBikes: "Your bikes",
  workshopNoWatch: "Pairing sensors on the bike is in the app. The watch stays for the ride.",
  careFallback: "Care",
  shopHint: "The bike does not live here. FlowLine shows parts — you buy at the merchant, not here. Shopify checkout is off for now.",
  shopPausedTitle: "The shop is paused",
  shopPausedHint:
    "The shop is closed for now. The bike stays — setup and service.",
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
  profileLanguage: "Language",
  profileLanguageHint:
    "The same five languages as the app. Device follows this browser — it does not sync from the phone.",
  profileLanguageAuto: "Device",
  profileDisciplines: "Your disciplines",
  profileDisciplinesHint:
    "Tour preferences. Routing follows the active bike, not this list alone.",
  profilePrimary: "Main",
  profileAlso: "also",
  profileStyle: "Riding style",
  profileStyleIndicators: "Style indicators",
  profileArrive: "Arrive at the yard",
  profileLocalOnly: "Supabase missing — local use without cloud. The app does not silently sync.",
  profileWelcome: "Signed in. The stand is waiting.",
  profileBikesAtStand: "Bikes at the stand",
  profileNoKpi: "No streaks, no invented kilometres.",
  legalKicker: "Legal",
  notFoundTitle: "This door does not exist",
  notFoundHint: "Empty stand. Back to Home, or one of the four doors.",
  rideBridgeTitle: "The road is the app",
  rideBridgeHint: "Live GPS, offline routing, sensors and background recording run native only — not in the browser.",
  ridePlannedKicker: "Planned tour",
  rideBackToMap: "Back to the map",
  rideSurface: (surface) => `Surface: ${surface}`,
  rideSyncedHint:
    "This route is saved in your browser. After signing in on the app it shows under Map or as the active tour (sync).",
  rideClearSelection: "Clear tour selection",
  rideNoTrackHint: "No track yet — set a finish in the planner first.",
  rideOpenPlanner: "Open planner",
  rideNoTourBefore: "No tour selected yet. Plan a route on the ",
  rideNoTourLink: "map",
  rideNoTourAfter: ", save it, then start in the app.",
  rideDownloadApp: "Download the app",
  rideOpenAppDirect: "Open the app directly",
  rideOpenInApp: "Open in the app",
  rideWebLinkToApp: "Web link to the app",
  rideContinueOnMap: "Continue on the map",
  rideContinueOnMapHint: "OSM · loops · plan",
  rideWhyApp: "Why the app?",
  rideWhyAppHint: "Navigation, offline, sensors",
  downloadTitle: "The app for the road",
  downloadHint: "Home, map and bike run in the browser. Ride out with HUD — only in the app.",
  activitiesTitle: "What came in",
  activitiesHint: "Rides from the app. Elevation and grade only when the track carries them.",
  activitiesEmpty: "No return yet.",
  activitiesEmptyHint: "Rides happen in the app. No fake calendar, no 0 km week.",
  libraryKicker: "Platz",
  libraryHint: "Keep tours, notes and friends on the route — the same as on the map.",
  akteMein: "Akte",
  akteStimmen: "Stimmen",
  stimmenPrivateHint: "Still private — after you share, others can comment.",
  plannerKicker: "Map",
  plannerTitle: "Plan",
  plannerHint: "The same door as the map. Navigation starts in the app.",
  checkoutTitle: "Checkout is the shop",
  checkoutHint: "No cart in FlowLine. You buy at the merchant, not here.",
  chatHint: "Power user. No feed at Home. The bike stays the bike.",
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
  careInWorkshop: (n) => String(n) + " — on the bike",
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
  parkBike: "Ajouter un vélo",
  rideWithoutBike: "Rouler sans vélo",
  atGate: "devant le portail",
  emptyStand: "Emplacement vide",
  homeTitle: "Accueil",
  homeHint: "Ton vélo et un bouton : sortir. Pas de fil.",
  skyUnknown: "Ciel inconnu",
  gpsUnknown: "Autoriser la position",
  noHonestLoop: "Pas de boucle à proximité",
  gateWetClosed: "Trails mouillés — pas de vraie boucle asphaltée à proximité",
  notYetOut: "pas encore dehors",
  justBack: "vient de rentrer",
  lastRideNoGps: "sans trace GPS — rien d'inventé",
  whatCameIn: "Ce qui est rentré",
  atHof: "au stand",
  noBikeHere: "Aucun vélo ici",
  openTours: "Tours sur la carte",
  yourWatch: "Ta montre",
  sinceOneDay: "depuis 1 jour",
  justRide: "Juste rouler",
  showTours: "Afficher les tours",
  mapChoiceHint: "Pars sans itinéraire, ou affiche les tours sur la carte.",
  gateAwayNear: "moins d’1 km",
  mapTitle: "Carte",
  workshopTitle: "Vélo",
  workshopAdd: "Ajouter un vélo",
  workshopAddAnother: "Autre vélo",
  shopKicker: "De l'autre côté de la cour",
  shopTitle: "Le magasin",
  shopGo: "Vers le magasin",
  shopForYourBike: "Pour ton vélo",
  shopPartsForBike: "Pièces pour ton vélo",
  shopLookupInShop: "Chercher dans le magasin",
  shopForYourBikeEmpty: "Ajoute un vélo au stand — ensuite on ouvre les pièces qui collent, dans le magasin.",
  shopMerch: "Vêtements",
  shopMerchHint: "Vêtements et petites choses. Jamais filtrés selon le vélo.",
  shopLockedTitle: "Magasin encore fermé dehors",
  shopSearchHint: "Pièces, marques, specs…",
  shopFeatured: "Pièces qui collent",
  shopOpenProduct: "Ouvrir dans le magasin",
  shopAllParts: "Toutes les pièces",
  privacyTitle: "Données & confidentialité",
  libraryTitle: "Parcours",
  libraryMappe: "Die Mappe",
  tafelKicker: "Die Tafel",
  tafelHint: "Une voix, un groupe ou une publication — pas de fil.",
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
  workshopEmpty: "Pas encore de vélo au stand",
  workshopEmptyHint: "Nom et type suffisent. Marque et pièces peuvent attendre.",
  workshopTabBox: "Die Box",
  workshopZoneReady: "Prêt",
  workshopZoneToday: "Aujourd'hui",
  workshopLater: "Plus tard",
  workshopZoneOnBike: "Sur le vélo",
  workshopZoneSensor: "Capteur",
  workshopMore: "Plus sur le vélo",
  workshopSchemaHint: "Touche un point — ajouter ou modifier.",
  workshopSchemaLegendOk: "là",
  workshopSchemaLegendOpen: "ouvert",
  workshopSchemaLegendDue: "dû",
  workshopFamilyYou: "Moi",
  workshopFamilyHint: "Poids et setup pour ce rider.",
  workshopFamilyHintEmpty: "Poids pour un enfant ou un partenaire — à ajouter ici.",
  workshopFamilyAdd: "Ajouter un rider",
  workshopFamilyName: "Nom",
  workshopFamilyWeight: "kg",
  workshopSchemaMoreOnDots: "Autres manques sur les points.",
  workshopReceiptPhoto: "Photo de la facture",
  workshopBoxAlmost: "Presque prêt",
  workshopBoxUnknown: "Encore flou",
  workshopAddPart: "Ajouter une pièce",
  workshopPartsEmpty:
    "Pas encore de pièces. Le catalogue est une recherche — rien n’a à être complet.",
  workshopMaintLog: "Journal d'entretien",
  workshopReport: "Rapport",
  workshopLoading: "Chargement du vélo…",
  workshopTabOverview: "Aperçu",
  workshopTabParts: "Pièces",
  workshopTabSetups: "Setup",
  workshopTabCare: "Entretien",
  workshopStatKm: "KM",
  workshopStatHours: "H",
  workshopStatPressure: "Pression",
  workshopStatService: "RDV",
  workshopStatDash: "—",
  workshopStatDueNow: "Maintenant",
  workshopStatCare: "Soin",
  workshopStandTitle: "Kilomètres et heures",
  workshopStandHint:
    "Relevé du compteur. On n'invente pas les heures à partir des km.",
  workshopStandSave: "Enregistrer",
  workshopNextService: "Prochain RDV atelier",
  workshopNextServiceHint:
    "Date réservée. Les intervalles en dessous sont l'entretien, pas un rendez-vous.",
  workshopStandOpen: "Enregistrer le relevé",
  workshopStandStravaHint:
    "La synchro Strava automatique est prévue — d'ici là le même dialogue que sous la photo. Pas d'import silencieux.",
  workshopWearTitle: "Prévision d'usure",
  workshopWearHint: "Pondéré par la charge · une plage, jamais une valeur ponctuelle.",
  workshopWearEmpty: "Pas de pièces d'usure avec historique.",
  workshopDueTitle: "Échéances",
  workshopDueAdjusted: "ajusté",
  workshopDueOverdue: "en retard",
  workshopDueSoon: "bientôt",
  workshopDueDone: "Fait",
  workshopDueEmpty: "Pas d'intervalles — ajoute des pièces.",
  workshopReceiptTitle: "Garder un justificatif",
  workshopReceiptPlaceholder: "Atelier, pièce, garantie",
  workshopReceiptAmount: "Montant €",
  workshopReceiptNote: "Note",
  workshopReceiptSaved: "Enregistré",
  workshopReceiptSave: "Garder le justificatif",
  workshopPerformerWorkshop: "Atelier",
  workshopPerformerSelf: "Soi-même",
  workshopMaintCost: (amount) => `Coût total : ${amount} €`,
  workshopMaintEmpty: "Pas encore de journal.",
  workshopMaintDefaults:
    "Defaults p. ex. RockShox 50 h lower leg / 200 h full, chaîne ~1000 km, liquide tubeless ~120 jours.",
  workshopPhotoRetake: "Reprendre",
  workshopPhotoRetakeHint:
    "La photo ne remplit pas le stand. Reprends pour poser le vélo sur le rail.",
  workshopPhotoCropTitle: "Poser le vélo sur le stand",
  workshopPhotoCropHint: "Glisse la photo jusqu'à ce que le vélo tienne sur le rail.",
  workshopPhotoCropSave: "Poser ainsi",
  workshopPhotoRotate: "Tourner 90°",
  workshopPhotoPlace: "Poser sur le stand",
  workshopBikes: "Tes vélos",
  workshopNoWatch: "Appairer les capteurs sur le vélo se fait dans l'app. La montre reste pour la sortie.",
  careFallback: "Entretien",
  shopHint: "Le vélo n'habite pas ici. FlowLine montre des pièces — tu achètes chez le revendeur, pas ici. La caisse Shopify est coupée pour l’instant.",
  shopPausedTitle: "Le magasin est en pause",
  shopPausedHint:
    "Shopify et le magasin de pièces sont coupés pour l’instant. Le vélo reste — setup et entretien sans caisse.",
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
  profileLanguage: "Langue",
  profileLanguageHint:
    "Les cinq langues de l'app. L'appareil suit ce navigateur — pas de sync depuis le téléphone.",
  profileLanguageAuto: "Appareil",
  profileDisciplines: "Tes disciplines",
  profileDisciplinesHint:
    "Préférences de tours. Le routing suit le vélo actif, pas seulement cette liste.",
  profilePrimary: "Principal",
  profileAlso: "aussi",
  profileStyle: "Style",
  profileStyleIndicators: "Indicateurs de style",
  profileArrive: "Arriver",
  profileLocalOnly: "Supabase manque — usage local sans cloud. L'app ne synchronise pas en silence.",
  profileWelcome: "Connecté. Le stand attend.",
  profileBikesAtStand: "Vélos au stand",
  profileNoKpi: "Pas de streaks, pas de kilomètres inventés.",
  legalKicker: "Mentions",
  notFoundTitle: "Cette porte n'existe pas",
  notFoundHint: "Stand vide. Retour à Home, ou une des quatre portes.",
  rideBridgeTitle: "La route, c'est l'app",
  rideBridgeHint: "GPS live, routage hors ligne, capteurs et enregistrement en arrière-plan tournent seulement en natif — pas dans le navigateur.",
  ridePlannedKicker: "Tour prévu",
  rideBackToMap: "Retour à la carte",
  rideSurface: (surface) => `Revêtement : ${surface}`,
  rideSyncedHint:
    "La route est mémorisée dans ton navigateur. Après connexion dans l'app, elle apparaît sous Carte ou comme tour active (sync).",
  rideClearSelection: "Annuler la sélection",
  rideNoTrackHint: "Pas encore de trace — indique d'abord l'arrivée dans le planificateur.",
  rideOpenPlanner: "Ouvrir le planificateur",
  rideNoTourBefore: "Aucune tour sélectionnée. Planifie une route sous ",
  rideNoTourLink: "Carte",
  rideNoTourAfter: ", enregistre-la, puis démarre dans l'app.",
  rideDownloadApp: "Télécharger l'app",
  rideOpenAppDirect: "Ouvrir l'app directement",
  rideOpenInApp: "Ouvrir dans l'app",
  rideWebLinkToApp: "Lien web vers l'app",
  rideContinueOnMap: "Continuer sur la carte",
  rideContinueOnMapHint: "OSM · boucles · planifier",
  rideWhyApp: "Pourquoi l'app ?",
  rideWhyAppHint: "Navigation, hors ligne, capteurs",
  downloadTitle: "L'app pour la route",
  downloadHint: "Home, carte et vélo tournent dans le navigateur. Sortir avec HUD — seulement dans l'app.",
  activitiesTitle: "Ce qui est rentré",
  activitiesHint: "Sorties depuis l’app. Altitude et pente seulement si la trace les porte.",
  activitiesEmpty: "Pas encore de retour.",
  activitiesEmptyHint: "Les sorties naissent dans l'app. Pas de calendrier fake, pas de semaine à 0 km.",
  libraryKicker: "Platz",
  libraryHint: "Garder des sorties, écrire court, emmener des amis par lien — les mêmes tours que sur la carte.",
  akteMein: "Akte",
  akteStimmen: "Stimmen",
  stimmenPrivateHint: "Encore privé — après partage, les autres peuvent commenter.",
  plannerKicker: "Carte",
  plannerTitle: "Planifier",
  plannerHint: "La même porte que la carte. La navigation démarre dans l'app.",
  checkoutTitle: "La caisse, c'est le magasin",
  checkoutHint: "Pas de panier dans FlowLine. L'achat est chez le revendeur, pas ici.",
  chatHint: "Power-user. Pas de feed à Home. Le vélo reste le vélo.",
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
  careInWorkshop: (n) => String(n) + " — au vélo",
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
  parkBike: "Aggiungi una bici",
  rideWithoutBike: "Pedala senza bici",
  atGate: "davanti al cancello",
  emptyStand: "Posto vuoto",
  homeTitle: "Home",
  homeHint: "La bici e un pulsante: esci. Niente feed.",
  skyUnknown: "Cielo sconosciuto",
  gpsUnknown: "Consenti posizione",
  noHonestLoop: "Nessun giro qui vicino",
  gateWetClosed: "Trail bagnati — nessun anello asfaltato onesto qui vicino",
  notYetOut: "non ancora fuori",
  justBack: "appena rientrato",
  lastRideNoGps: "senza traccia GPS — niente di inventato",
  whatCameIn: "Cosa è rientrato",
  atHof: "al posto",
  noBikeHere: "Nessuna bici qui",
  openTours: "Tour sulla mappa",
  yourWatch: "Il tuo orologio",
  sinceOneDay: "da 1 giorno",
  justRide: "Pedala e basta",
  showTours: "Mostra i tour",
  mapChoiceHint: "Parti senza itinerario, o mostra i tour sulla mappa.",
  gateAwayNear: "meno di 1 km",
  mapTitle: "Mappa",
  workshopTitle: "Bici",
  workshopAdd: "Aggiungi una bici",
  workshopAddAnother: "Altra bici",
  shopKicker: "Dall'altra parte del cortile",
  shopTitle: "Il negozio",
  shopGo: "Al negozio",
  shopForYourBike: "Per la tua bici",
  shopPartsForBike: "Pezzi per la tua bici",
  shopLookupInShop: "Cerca nel negozio",
  shopForYourBikeEmpty: "Aggiungi una bici allo stand — poi apriamo i pezzi che calzano, nel negozio.",
  shopMerch: "Abbigliamento",
  shopMerchHint: "Abbigliamento e oggettistica. Mai filtrati sulla bici.",
  shopLockedTitle: "Negozio ancora chiuso fuori",
  shopSearchHint: "Pezzi, marche, specs…",
  shopFeatured: "Pezzi che calzano",
  shopOpenProduct: "Apri nel negozio",
  shopAllParts: "Tutti i pezzi",
  privacyTitle: "Dati e privacy",
  libraryTitle: "Percorsi",
  libraryMappe: "Die Mappe",
  tafelKicker: "Die Tafel",
  tafelHint: "Una voce, un gruppo o una pubblicazione — non un feed.",
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
  workshopEmpty: "Ancora nessuna bici allo stand",
  workshopEmptyHint: "Nome e tipo bastano. Marca e pezzi possono aspettare.",
  workshopTabBox: "Die Box",
  workshopZoneReady: "Pronto",
  workshopZoneToday: "Oggi",
  workshopLater: "Più tardi",
  workshopZoneOnBike: "Sulla bici",
  workshopZoneSensor: "Sensore",
  workshopMore: "Altro sulla bici",
  workshopSchemaHint: "Tocca un punto — aggiungi o modifica.",
  workshopSchemaLegendOk: "c’è",
  workshopSchemaLegendOpen: "aperto",
  workshopSchemaLegendDue: "scaduto",
  workshopFamilyYou: "Io",
  workshopFamilyHint: "Peso e setup per questo rider.",
  workshopFamilyHintEmpty: "Peso per un bambino o un partner — aggiungilo qui.",
  workshopFamilyAdd: "Aggiungi rider",
  workshopFamilyName: "Nome",
  workshopFamilyWeight: "kg",
  workshopSchemaMoreOnDots: "Altre lacune sui punti.",
  workshopReceiptPhoto: "Foto della fattura",
  workshopBoxAlmost: "Quasi pronto",
  workshopBoxUnknown: "Ancora incerto",
  workshopAddPart: "Aggiungi pezzo",
  workshopPartsEmpty:
    "Ancora nessun pezzo. Il catalogo è una ricerca — niente deve essere completo.",
  workshopMaintLog: "Log manutenzione",
  workshopReport: "Report",
  workshopLoading: "Caricamento bici…",
  workshopTabOverview: "Panoramica",
  workshopTabParts: "Parti",
  workshopTabSetups: "Setup",
  workshopTabCare: "Manutenzione",
  workshopStatKm: "KM",
  workshopStatHours: "ORE",
  workshopStatPressure: "Pressione",
  workshopStatService: "Appunt.",
  workshopStatDash: "—",
  workshopStatDueNow: "Ora",
  workshopStatCare: "Cura",
  workshopStandTitle: "Chilometri e ore",
  workshopStandHint:
    "Lettura dal computer. Non inventiamo le ore dai km.",
  workshopStandSave: "Salva",
  workshopNextService: "Prossimo appuntamento",
  workshopNextServiceHint:
    "Data prenotata. Gli intervalli sotto sono cura, non un appuntamento.",
  workshopStandOpen: "Imposta lettura",
  workshopStandStravaHint:
    "La sync Strava automatica è prevista — fino ad allora lo stesso dialogo che sotto la foto. Nessun import silenzioso.",
  workshopWearTitle: "Previsione usura",
  workshopWearHint: "Ponderato sul carico · un intervallo, mai un punto.",
  workshopWearEmpty: "Nessun pezzo d'usura con cronologia.",
  workshopDueTitle: "Scadenze",
  workshopDueAdjusted: "modificato",
  workshopDueOverdue: "scaduto",
  workshopDueSoon: "presto",
  workshopDueDone: "Fatto",
  workshopDueEmpty: "Nessun intervallo — aggiungi componenti.",
  workshopReceiptTitle: "Salva scontrino",
  workshopReceiptPlaceholder: "Officina, pezzo, garanzia",
  workshopReceiptAmount: "Importo €",
  workshopReceiptNote: "Nota",
  workshopReceiptSaved: "Salvato",
  workshopReceiptSave: "Salva scontrino",
  workshopPerformerWorkshop: "Officina",
  workshopPerformerSelf: "In proprio",
  workshopMaintCost: (amount) => `Costo totale: ${amount} €`,
  workshopMaintEmpty: "Ancora nessun log.",
  workshopMaintDefaults:
    "Default tra cui RockShox 50 h lower leg / 200 h full, catena ~1000 km, liquido tubeless ~120 giorni.",
  workshopPhotoRetake: "Scatta di nuovo",
  workshopPhotoRetakeHint:
    "La foto non riempie lo stand. Scatta di nuovo, la bici sta sulla rotaia.",
  workshopPhotoCropTitle: "Metti la bici sullo stand",
  workshopPhotoCropHint: "Sposta la foto finché la bici sta sulla rotaia.",
  workshopPhotoCropSave: "Così",
  workshopPhotoRotate: "Ruota 90°",
  workshopPhotoPlace: "Metti sullo stand",
  workshopBikes: "Le tue bici",
  workshopNoWatch: "Accoppiare i sensori sulla bici si fa nell'app. L'orologio resta per l'uscita.",
  careFallback: "Cura",
  shopHint: "La bici non vive qui. FlowLine mostra pezzi — compri dal rivenditore, non qui. La cassa Shopify è spenta per ora.",
  shopPausedTitle: "Il negozio è in pausa",
  shopPausedHint:
    "Shopify e il negozio pezzi sono spenti per ora. La bici resta — setup e manutenzione senza cassa.",
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
  profileLanguage: "Lingua",
  profileLanguageHint:
    "Le cinque lingue dell'app. Il dispositivo segue questo browser — niente sync dal telefono.",
  profileLanguageAuto: "Dispositivo",
  profileDisciplines: "Le tue discipline",
  profileDisciplinesHint:
    "Preferenze per i tour. Il routing segue la bici attiva, non solo questa lista.",
  profilePrimary: "Principale",
  profileAlso: "anche",
  profileStyle: "Stile",
  profileStyleIndicators: "Indicatori di stile",
  profileArrive: "Arriva al cortile",
  profileLocalOnly: "Supabase manca — uso locale senza cloud. L'app non sincronizza in silenzio.",
  profileWelcome: "Accesso fatto. Lo stand aspetta.",
  profileBikesAtStand: "Bici allo stand",
  profileNoKpi: "Niente streak, niente chilometri inventati.",
  legalKicker: "Legale",
  notFoundTitle: "Questa porta non esiste",
  notFoundHint: "Stand vuoto. Torna a Home, o una delle quattro porte.",
  rideBridgeTitle: "La strada è l'app",
  rideBridgeHint: "GPS live, routing offline, sensori e registrazione in background girano solo in nativo — non nel browser.",
  ridePlannedKicker: "Tour pianificato",
  rideBackToMap: "Torna alla mappa",
  rideSurface: (surface) => `Superficie: ${surface}`,
  rideSyncedHint:
    "Il percorso è salvato nel browser. Dopo l'accesso in app compare sotto Mappa o come tour attivo (sync).",
  rideClearSelection: "Annulla selezione tour",
  rideNoTrackHint: "Ancora nessuna traccia — imposta prima l'arrivo nel planner.",
  rideOpenPlanner: "Apri il planner",
  rideNoTourBefore: "Nessun tour selezionato. Pianifica un percorso su ",
  rideNoTourLink: "Mappa",
  rideNoTourAfter: ", salvalo e poi parti dall'app.",
  rideDownloadApp: "Scarica l'app",
  rideOpenAppDirect: "Apri l'app direttamente",
  rideOpenInApp: "Apri nell'app",
  rideWebLinkToApp: "Link web all'app",
  rideContinueOnMap: "Continua sulla mappa",
  rideContinueOnMapHint: "OSM · anelli · pianifica",
  rideWhyApp: "Perché l'app?",
  rideWhyAppHint: "Navigazione, offline, sensori",
  downloadTitle: "L'app per la strada",
  downloadHint: "Home, mappa e bici girano nel browser. Esci con HUD — solo nell'app.",
  activitiesTitle: "Cosa è rientrato",
  activitiesHint: "Uscite dall’app. Quota e pendenza solo se la traccia le porta.",
  activitiesEmpty: "Ancora nessun ritorno.",
  activitiesEmptyHint: "Le uscite nascono nell'app. Niente calendario finto, niente settimana a 0 km.",
  libraryKicker: "Platz",
  libraryHint: "Tenere uscite, scrivere breve, portare amici col link — gli stessi tour che sulla mappa.",
  akteMein: "Akte",
  akteStimmen: "Stimmen",
  stimmenPrivateHint: "Ancora privato — dopo la condivisione gli altri possono commentare.",
  plannerKicker: "Mappa",
  plannerTitle: "Pianifica",
  plannerHint: "La stessa porta della mappa. La navigazione parte nell'app.",
  checkoutTitle: "La cassa è il negozio",
  checkoutHint: "Niente carrello in FlowLine. L'acquisto è dal rivenditore, non qui.",
  chatHint: "Power user. Niente feed a Home. La bici resta la bici.",
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
  careInWorkshop: (n) => String(n) + " — sulla bici",
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

const NL: HofCopy = {
  profile: "Profiel",
  rideOut: "Eruit",
  rideOutAgain: "Nog eens eruit",
  openBike: "Fiets openen",
  parkBike: "Fiets toevoegen",
  rideWithoutBike: "Rijden zonder fiets",
  atGate: "voor de poort",
  emptyStand: "Lege stand",
  homeTitle: "Start",
  homeHint: "Je fiets en één knop: eruit. Geen feed.",
  skyUnknown: "Hemel onbekend",
  gpsUnknown: "Locatie toestaan",
  noHonestLoop: "Geen ronde in de buurt",
  gateWetClosed: "Trails nat — geen eerlijke asfaltlus in de buurt",
  notYetOut: "nog niet buiten",
  justBack: "net binnen",
  lastRideNoGps: "zonder GPS-track — niets verzonnen",
  whatCameIn: "Wat er binnenkwam",
  atHof: "aan de stand",
  noBikeHere: "Geen fiets hier",
  openTours: "Tochten op de kaart",
  yourWatch: "Je horloge",
  sinceOneDay: "sinds 1 dag",
  justRide: "Gewoon rijden",
  showTours: "Tochten tonen",
  mapChoiceHint: "Rijd zonder route, of toon tochten op de kaart.",
  gateAwayNear: "onder 1 km",
  mapTitle: "Kaart",
  workshopTitle: "Fiets",
  workshopAdd: "Fiets toevoegen",
  workshopAddAnother: "Nog een fiets",
  shopKicker: "Over het erf",
  shopTitle: "De winkel",
  shopGo: "Naar de winkel",
  shopForYourBike: "Voor je fiets",
  shopPartsForBike: "Onderdelen voor je fiets",
  shopLookupInShop: "Opzoeken in de winkel",
  shopForYourBikeEmpty:
    "Voeg een fiets toe op de stand — dan openen we de passende onderdelen in de winkel.",
  shopMerch: "Kleding",
  shopMerchHint: "Kleding en klein spul. Nooit gefilterd op de fiets.",
  shopLockedTitle: "Winkel buiten nog dicht",
  shopSearchHint: "Onderdelen, merken, specs…",
  shopFeatured: "Passende onderdelen",
  shopOpenProduct: "Openen in de winkel",
  shopAllParts: "Alle onderdelen",
  privacyTitle: "Data & privacy",
  libraryTitle: "Tochten",
  libraryMappe: "Die Mappe",
  tafelKicker: "Die Tafel",
  tafelHint: "Een stem, een groep of een vrijgave — geen feed.",
  togetherOut: "Samen eruit",
  watchHint: "Hartslag alleen met een echte sensor.",
  watchOpenApp: "Koppelen in de app",
  watchBar: "Horloge koppelen in de app",
  workshopCscBar: "Fietsensor koppelen in de app",
  workshopSensorUnpaired: "Fietsensor niet verbonden",
  mapJustRideHint:
    "De kaart blijft in de browser. GPS-HUD, navigatie en opname lopen in de app.",
  mapKicker: "Voor de poort",
  mapEmptyLoops: "Geen lussen in de buurt",
  mapEmptyLoopsHint:
    "Alleen echte lussen (start≈finish) — geen A→B-tochten als vulling. Andere plek of in de app rijden.",
  mapLoading: "Kaart wordt geladen…",
  mapSheetNear: "In de buurt",
  mapSheetPlan: "Plannen",
  mapSheetTours: "Tochten",
  inTheApp: "In de app",
  workshopKicker: "De fiets",
  workshopHint:
    "Je fiets woont hier. Naam en type volstaan. Onderhoud komt als je wilt.",
  workshopEmpty: "Nog geen fiets aan de stand",
  workshopEmptyHint: "Naam en type volstaan. Merk en onderdelen kunnen later.",
  workshopTabBox: "Die Box",
  workshopZoneReady: "Klaar",
  workshopZoneToday: "Vandaag",
  workshopLater: "Later",
  workshopZoneOnBike: "Aan de fiets",
  workshopZoneSensor: "Sensor",
  workshopMore: "Meer op de fiets",
  workshopSchemaHint: "Tik op een punt — toevoegen of wijzigen.",
  workshopSchemaLegendOk: "er",
  workshopSchemaLegendOpen: "open",
  workshopSchemaLegendDue: "due",
  workshopFamilyYou: "Ik",
  workshopFamilyHint: "Gewicht en setup voor deze rijder.",
  workshopFamilyHintEmpty: "Gewicht voor kind of partner — hier aanmaken.",
  workshopFamilyAdd: "Rijder toevoegen",
  workshopFamilyName: "Naam",
  workshopFamilyWeight: "kg",
  workshopSchemaMoreOnDots: "Verdere gaten op de punten.",
  workshopReceiptPhoto: "Foto van de factuur",
  workshopBoxAlmost: "Bijna klaar",
  workshopBoxUnknown: "Nog onduidelijk",
  workshopAddPart: "Onderdeel toevoegen",
  workshopPartsEmpty:
    "Nog geen onderdelen. De catalogus is zoeken — niets hoeft compleet te zijn.",
  workshopMaintLog: "Onderhoudslog",
  workshopReport: "Rapport",
  workshopLoading: "Fiets wordt geladen…",
  workshopTabOverview: "Overzicht",
  workshopTabParts: "Onderdelen",
  workshopTabSetups: "Setup",
  workshopTabCare: "Onderhoud",
  workshopStatKm: "KM",
  workshopStatHours: "UREN",
  workshopStatPressure: "Druk",
  workshopStatService: "Beurt",
  workshopStatDash: "—",
  workshopStatDueNow: "Nu",
  workshopStatCare: "Zorg",
  workshopStandTitle: "Kilometers en uren",
  workshopStandHint:
    "Stand van computer of teller. Uren rekenen we niet uit km.",
  workshopStandSave: "Stand overnemen",
  workshopNextService: "Volgende werkplaatsafspraak",
  workshopNextServiceHint:
    "Geboekte datum. Intervallen eronder zijn onderhoud, geen afspraak.",
  workshopStandOpen: "Stand zetten",
  workshopStandStravaHint:
    "Automatische Strava-sync is gepland — tot die tijd dezelfde dialoog als onder de foto. Geen stille import.",
  workshopWearTitle: "Slijtageprognose",
  workshopWearHint: "Belastingsgewogen · een bereik, nooit een puntwaarde.",
  workshopWearEmpty: "Geen slijtagedelen met historie.",
  workshopDueTitle: "Vervallen",
  workshopDueAdjusted: "aangepast",
  workshopDueOverdue: "achterstallig",
  workshopDueSoon: "binnenkort",
  workshopDueDone: "Klaar",
  workshopDueEmpty: "Geen intervallen — onderdelen plaatsen.",
  workshopReceiptTitle: "Bon bewaren",
  workshopReceiptPlaceholder: "Werkplaats, onderdeel, garantie",
  workshopReceiptAmount: "Bedrag €",
  workshopReceiptNote: "Notitie",
  workshopReceiptSaved: "Opgeslagen",
  workshopReceiptSave: "Bon bewaren",
  workshopPerformerWorkshop: "Werkplaats",
  workshopPerformerSelf: "Zelf",
  workshopMaintCost: (amount) => `Kosten totaal: ${amount} €`,
  workshopMaintEmpty: "Nog geen log.",
  workshopMaintDefaults:
    "Defaults o.a. RockShox 50 h lower leg / 200 h full, ketting ~1000 km, tubeless-melk ~120 dagen.",
  workshopPhotoRetake: "Opnieuw maken",
  workshopPhotoRetakeHint:
    "De foto vult de stand niet. Maak opnieuw, dan staat de fiets op de rail.",
  workshopPhotoCropTitle: "Fiets op de stand zetten",
  workshopPhotoCropHint: "Verschuif de foto tot de fiets op de rail staat.",
  workshopPhotoCropSave: "Zo zetten",
  workshopPhotoRotate: "90° draaien",
  workshopPhotoPlace: "Op de stand zetten",
  workshopBikes: "Je fietsen",
  workshopNoWatch:
    "Sensoren aan de fiets koppelen gaat in de app. Het horloge blijft bij het rijden.",
  careFallback: "Onderhoud",
  shopHint:
    "De fiets woont hier niet. FlowLine toont onderdelen — kopen doe je bij de dealer, niet hier. Shopify-kassa staat voorlopig uit.",
  shopPausedTitle: "De winkel pauzeert",
  shopPausedHint:
    "De winkel is voorlopig dicht. De fiets blijft — setup en onderhoud.",
  shopLockedBody:
    "De winkel buiten is nog niet openbaar — de link kan op een wachtwoord stuiten. Kassa blijft bij Shopify, niet hier.",
  shopLockedOpen: "Toch openen (wachtwoordpagina)",
  shopLockedCatalog: "Catalogus in FlowLine. Kassa alleen bij Shopify.",
  shopLockedBanner: "Winkel buiten nog dicht",
  shopLockedPasswordNote:
    "Catalogus kan in FlowLine staan. Het store-wachtwoord wordt niet meegeleverd.",
  shopLockedMissingUrl: "Storefront-URL ontbreekt — de deur blijft eerlijk dicht.",
  shopNoImage: "Geen afbeelding",
  shopGuideHow: "Hoe de winkel werkt",
  shopCancel: "Terug",
  shopExternalLink: "Externe dealerlink",
  shopNetworkError: "Netwerkfout.",
  shopProductUnavailable: "Product niet beschikbaar",
  shopCheckoutElsewhere:
    "De dealer is verkoper en contractpartner — niet FlowLine.",
  shopProductMissing: "Dit product ligt niet in de winkel.",
  shopBack: "Terug naar de winkel",
  shopCyclingParts: "Onderdelen",
  shopFeaturedBikes: "Fietsen in de winkel",
  shopDetails: "Details",
  shopCatalogFailed: "Catalogus nu niet bereikbaar. Probeer later nog eens.",
  shopRetry: "Opnieuw laden",
  shopOpenInApp: "Bekijken in de winkel",
  shopFitOnly: "Alleen passende",
  shopFitAllBikes: "Alle fietsen",
  shopFitBannerAll: "Onderdelen passend bij je fietsen",
  shopOpenInBrowser: "Openen in de browser",
  shopZumHaendler: "Kopen bij de dealer",
  shopMerchantDisclosure:
    "Verkoper is de dealer (Bike24, bike-components, bike-discount) — niet FlowLine.",
  shopCatalogEmpty: "Nog geen onderdelen in het schap.",
  shopReplaceHint:
    "Reserve — FlowLine filtert op je fiets, zonder SKU's te verzinnen.",
  shopShelfEmpty: "Geen onderdelen bij deze zoekopdracht.",
  profileKicker: "Jij",
  profileTitle: "Profiel",
  profileHint:
    "Account en rijstijl. Na aanmelden sta je op Home — geen sync-theater met de native app.",
  profileLanguage: "Taal",
  profileLanguageHint:
    "De vijf talen van de app. Apparaat volgt deze browser — geen sync vanaf de telefoon.",
  profileLanguageAuto: "Apparaat",
  profileDisciplines: "Jouw disciplines",
  profileDisciplinesHint:
    "Voorkeuren voor tochten. Routing volgt de actieve fiets, niet alleen deze lijst.",
  profilePrimary: "Hoofd",
  profileAlso: "ook",
  profileStyle: "Rijstijl",
  profileStyleIndicators: "Stijlindicatoren",
  profileArrive: "Aankomen op het erf",
  profileLocalOnly:
    "Supabase ontbreekt — lokaal gebruik zonder cloud. De app synct niet stilletjes mee.",
  profileWelcome: "Aangemeld. De stand wacht.",
  profileBikesAtStand: "Fietsen aan de stand",
  profileNoKpi: "Geen streaks, geen verzonnen kilometers.",
  legalKicker: "Juridisch",
  notFoundTitle: "Deze deur bestaat niet",
  notFoundHint: "Lege stand. Terug naar Home, of een van de vier deuren.",
  rideBridgeTitle: "De weg is de app",
  rideBridgeHint:
    "Live-GPS, offline-routing, sensoren en achtergrondopname lopen alleen native — niet in de browser.",
  ridePlannedKicker: "Geplande tocht",
  rideBackToMap: "Terug naar de kaart",
  rideSurface: (surface) => `Ondergrond: ${surface}`,
  rideSyncedHint:
    "De route staat in je browser. Na inloggen in de app zie je hem onder Kaart of als actieve tocht (sync).",
  rideClearSelection: "Tourselectie wissen",
  rideNoTrackHint: "Nog geen track — zet eerst de finish in de planner.",
  rideOpenPlanner: "Planner openen",
  rideNoTourBefore: "Nog geen tocht gekozen. Plan een route onder ",
  rideNoTourLink: "Kaart",
  rideNoTourAfter: ", sla op en start dan in de app.",
  rideDownloadApp: "App downloaden",
  rideOpenAppDirect: "App direct openen",
  rideOpenInApp: "Openen in de app",
  rideWebLinkToApp: "Weblink naar de app",
  rideContinueOnMap: "Verder op de kaart",
  rideContinueOnMapHint: "OSM · rondes · plannen",
  rideWhyApp: "Waarom de app?",
  rideWhyAppHint: "Navigatie, offline, sensoren",
  downloadTitle: "De app onderweg",
  downloadHint:
    "Home, kaart en fiets lopen in de browser. Eruit met HUD — alleen in de app.",
  activitiesTitle: "Wat er binnenkwam",
  activitiesHint:
    "Ritten uit de app. Hoogte en helling alleen als het spoor ze draagt.",
  activitiesEmpty: "Nog geen terugkomst.",
  activitiesEmptyHint:
    "Ritten ontstaan in de app. Geen nepkalender, geen 0-km-week.",
  libraryKicker: "Platz",
  libraryHint:
    "Tochten onthouden, kort schrijven, vrienden meenemen via link — dezelfde tochten als op de kaart.",
  akteMein: "Akte",
  akteStimmen: "Stimmen",
  stimmenPrivateHint: "Nog privé — na delen kunnen anderen reageren.",
  plannerKicker: "Kaart",
  plannerTitle: "Plannen",
  plannerHint: "Dezelfde deur als de kaart. Navigatie start in de app.",
  checkoutTitle: "Kassa is de winkel",
  checkoutHint: "Geen winkelwagen in FlowLine. Kopen doe je bij de dealer, niet hier.",
  chatHint: "Power-user. Geen feed op Home. De fiets blijft de fiets.",
  coachBell: "Notities",
  privacyKicker: "Jij",
  privacyHint:
    "Export, zones, gezin. Geen tracking-theater — alleen wat er echt is.",
  postRideKicker: "Terug op Home",
  postRideTitle: "Wat er binnenkwam",
  postRideHint:
    "Analyse na de rit. Opname blijft in de app — hier alleen eerlijke cijfers.",
  groupAtGate: "Groep voor de poort",
  groupLiveNavHint:
    "Iedereen in de groep op de navi — alleen in de app, alleen tijdens de rit, alleen met opt-in. Niet op de kaart voor de poort.",
  signedIn: "Aangemeld",
  agoMinutes: (n) => String(n) + " min geleden",
  agoHours: (n) => String(n) + " h geleden",
  packMissing: (n) => "Geen pack voor " + String(n),
  careInWorkshop: (n) => String(n) + " — aan de fiets",
  bringForward: (n) => "Zet " + String(n) + " naar voren",
  sinceDays: (n) => "sinds " + String(n) + " dagen",
  loopDuration: (n) => "⟲ " + String(n) + " min",
  gateAwayKm: (n) => String(n) + " km",
  skyDry: (n) => String(n) + "° · eerder droog",
  skyDamp: (n) => String(n) + "° · vochtig mogelijk",
  skyWet: (n) => String(n) + "° · regen · trails eerder nat",
  shopForYourBikeHint: (n) =>
    "Onderdelen passend bij " + String(n) + " — categorie en wiel. Geen verzonnen SKU's.",
  shopFitBanner: (n) => "Onderdelen passend bij " + String(n),
  communityNotes: (n) =>
    n === 1 ? "1 Stimme bij deze ronde" : `${n} Stimmen bij deze ronde`,
  coachTafel: (n) =>
    n === 1 ? "1 notitie van de assistent" : `${n} notities van de assistent`,
  coachUnread: (n) => (n === 1 ? "1 nieuw" : `${n} nieuw`),
};

const BY_LANG: Record<ChromeLang, HofCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function hofCopy(lang: ChromeLang = "de"): HofCopy {
  return BY_LANG[lang];
}

/** German fallback — metadata, tests, first paint. */
export const HOF_COPY = hofCopy("de");
