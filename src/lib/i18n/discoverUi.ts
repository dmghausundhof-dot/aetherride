import {
  DEMO_ROUTING_NOTICE,
  UNVERIFIED_ROUTING_NOTICE,
} from "@/lib/routing/routingStatus";
import type { ChromeLang } from "./chromeLang";
import { discoverCopy } from "./discoverCopy";

/** Exact DE status / pin strings stored in Discover state. */
export const DISCOVER_STATUS_DE = {
  locDeep: "Standort: Deep-Link",
  locWaitOrTap: "Standort wird ermittelt… — oder Ort tippen",
  locGps: "Standort: GPS",
  locDeepGps: "Standort: Deep-Link (GPS verfügbar)",
  locNoneDemo: "Standort nicht verfügbar — Demo-Stadt oder Adresse",
  locDeniedDemo:
    "Standort verweigert — Demo-Stadt wählen oder Adresse suchen",
  locNoneAddr:
    "Standort nicht verfügbar — Adresse suchen oder Demo-Stadt wählen",
  locDeniedAddr:
    "Standort verweigert — Adresse suchen oder Demo-Stadt wählen",
  locGpsCentered: "Standort: GPS — Karte zentriert",
  locWait: "Standort wird ermittelt…",
  calcSlow:
    "Berechnung zu langsam — ~60-Min Seeds unten, oder erneut versuchen.",
  noQuick: "Keine Quick-Routen — Seeds unten oder Planer nutzen.",
  rateLimit:
    "Routing-Limit erreicht — Näherungen angezeigt. Später neu berechnen.",
  quickFail:
    "Quick-Routing fehlgeschlagen — Seeds unten, oder erneut versuchen.",
  gpxBad: "GPX ungültig oder zu wenige Punkte",
  geocodeFail: "Adresssuche fehlgeschlagen",
  savedLoaded: "Gespeicherte Route geladen",
  needStartEnd:
    "Route konnte nicht berechnet werden — Start und Ziel setzen.",
  pinOnly:
    "Nur Ortspunkt — kein Track. In Planen + Ziel oder Live-Routing.",
  hybridFail: "Hybrid-Snap fehlgeschlagen",
  trailFail: "Trail konnte nicht verbunden werden",
  searchStart: "Adresse suchen — Start setzen",
  changePlace: "Ort ändern — Stadt oder Adresse suchen",
  heatmapOffline: "Heatmap offline",
  packsEmpty: "Keine Packs im Katalog — Region-Build lokal ausführen.",
  packsUnreachable: "Offline-Katalog nicht erreichbar.",
} as const;

export const DISCOVER_PIN_DE = {
  myPos: "Meine Position",
  deepLink: "Deep-Link Ort",
  here: "Hier",
  startMap: "Start (Karte)",
  endMap: "Ziel (Karte)",
  tourStart: "Tour-Start",
  tourEnd: "Tour-Ende",
  tourPlace: "Tour-Ort",
  planned: "Geplante Route",
} as const;

export type DiscoverUi = {
  osmOptional: string;
  hereBtn: string;
  placeEllipsis: string;
  heatmapPrefix: string;
  heatmapOwn: string;
  time: string;
  nearbyTitle: (profile: string) => string;
  nearbyLiveHint: string;
  loopActiveHint: string;
  suggestions: (min: number, profile: string) => string;
  computing: string;
  quickTimeout: string;
  retry: string;
  noLive: string;
  openPlan: string;
  recompute: string;
  moreOption: string;
  ghMinuteLimit: string;
  sixtyTitle: string;
  sixtyLead: string;
  noLoopsNearby: string;
  noHonestHere: string;
  changePlaceBtn: string;
  demoCity: string;
  planHint: string;
  start: string;
  end: string;
  startAddr: string;
  endAddr: string;
  addrPlaceholder: string;
  search: string;
  tapStart: string;
  tapVia: string;
  tapEnd: string;
  startAbbr: string;
  endAbbr: string;
  startMyPos: string;
  computingRoute: string;
  computeRoute: string;
  waysNearby: string;
  overlay: string;
  osmLoading: string;
  osmError: string;
  osmEmpty: string;
  show: string;
  append: string;
  intoNav: string;
  attachApproach: string;
  approachByCar: string;
  approachOnFoot: string;
  atTrailStart: string;
  trailGravityHint: string;
  trailUnsuitable: (bike: string) => string;
  difficultyOpen: string;
  rangeLine: (lo: number, hi: number) => string;
  fromLocation: (n: number, farther: number) => string;
  sortedByYou: string;
  sortedByMap: string;
  sortedNear: (who: string) => string;
  offlineFallback: string;
  noToursFilter: string;
  loosenLoop: string;
  loosenOrPlan: string;
  loopFilterOff: string;
  fartherRegions: (n: number) => string;
  outdooractive: (n: number) => string;
  googlePois: (n: number) => string;
  noOa: string;
  example: string;
  trailforks: (n: number) => string;
  tfFallback: string;
  mappeHeading: string;
  mappeEmpty: string;
  mappeFilterEmpty: string;
  importGpx: string;
  withTrack: string;
  importTag: string;
  shared: string;
  privateTour: string;
  remove: string;
  plusCollection: string;
  collectionsTitle: string;
  collectionsLead: string;
  namePlaceholder: string;
  create: string;
  noCollection: string;
  routesCount: (n: number) => string;
  close: string;
  tapFor: (what: string) => string;
  cancel: string;
  saveAria: string;
  fromHereStart: string;
  preview: string;
  fromHere: string;
  intoPlan: string;
  locDeep: string;
  locWaitOrTap: string;
  locGps: string;
  locDeepGps: string;
  locNoneDemo: string;
  locDeniedDemo: string;
  locNoneAddr: string;
  locDeniedAddr: string;
  locGpsCentered: string;
  locWait: string;
  calcSlow: string;
  noQuick: string;
  rateLimit: string;
  quickFail: string;
  gpxBad: string;
  geocodeFail: string;
  savedLoaded: string;
  needStartEnd: string;
  pinOnly: string;
  hybridFail: string;
  trailFail: string;
  searchStart: string;
  changePlace: string;
  heatmapOffline: string;
  demoRegion: (name: string) => string;
  demoRegionLoops: (name: string) => string;
  noHits: (q: string) => string;
  geocodeFailHttp: (status: string) => string;
  inPlanNamed: (name: string) => string;
  inPlanNeedEnd: (name: string) => string;
  waypointStart: (label: string) => string;
  waypointEnd: (label: string) => string;
  gpxImported: (name: string, km: string) => string;
  hybridStats: (km: string, min: string) => string;
  trailInserted: (name: string) => string;
  demoRouting: string;
  unverifiedRouting: string;
  pinMyPos: string;
  pinDeepLink: string;
  pinHere: string;
  pinStartMap: string;
  pinEndMap: string;
  pinTourStart: string;
  pinTourEnd: string;
  pinTourPlace: string;
  plannedRoute: string;
  fromHereLabel: (name: string) => string;
  ideaLabel: (name: string) => string;
  planLabel: (name: string) => string;
  surfaceAsphalt: string;
  surfaceSchotter: string;
  surfaceNatur: string;
  surfaceGras: string;
  surfaceHolz: string;
  hwyPath: string;
  hwyTrack: string;
  hwyCycle: string;
  hwyBridle: string;
  hwyFoot: string;
  tourIdea: string;
  away: (km: number) => string;
  loopRound: string;
  pointAb: string;
  because: string;
  details: string;
  pageLink: string;
  unsaveAria: string;
  save: string;
  saved: string;
  startInApp: string;
  variantPlanned: string;
  variantFlatter: string;
  variantUnpaved: string;
  variantValhallaOnly: string;
  openNativeApp: string;
  placeKind: (kind: string) => string;
  overview: string;
  popular: string;
  photos: string;
  elevation: string;
  match: string;
  pinIdea: string;
  pinOnlyHint: string;
  whySuggestion: string;
  rangeSpan: (lo: number, hi: number) => string;
  rangeTight: string;
  rangeOk: string;
  rangeTour: (km: number, conf: string) => string;
  rangeProTitle: string;
  rangeProBody: string;
  unlockPro: string;
  offlineMapsHint: string;
  offlineMapsAfter: string;
  savedLink: string;
  heatCold: (k: number) => string;
  heatConsent: (k: number) => string;
  heatConsentBefore: string;
  heatConsentAfter: (k: number) => string;
  privacyLink: string;
  heatOwn: string;
  heatSection: string;
  riders: (n: number, pct: string) => string;
  noSegments: string;
  heading: (deg: number) => string;
  demoPhotos: string;
  noPhotos: string;
  elevMissing: string;
  publicTour: string;
  openPlanner: string;
  gapElev: (km: string) => string;
  surfaceTitle: string;
  difficultyTitle: string;
  estimate: string;
  elevEst: (hm: number) => string;
  elevProfile: (hm: number) => string;
  fromHereTitle: string;
  fromHereHint: string;
  needCenter: string;
  stretch: string;
  compute: string;
  inApp: string;
  noHonestEngine: string;
  savedEngine: (line: string) => string;
  routingFail: string;
  roundKm: (km: number) => string;
  tourKm: (km: number) => string;
  packsTitle: string;
  packsLead: string;
  packsCatalog: string;
  packsEmpty: string;
  packsUnreachable: string;
  packsNone: string;
  packsNotBuilt: string;
  packsDownload: (name: string) => string;
  packsStarted: (name: string) => string;
  packsFail: string;
  packsLoad: string;
  packsStub: string;
  back: string;
  tourIdeaLive: string;
};

const DE: DiscoverUi = {
  osmOptional: "OSM · ~60-Min-Rundkurse — Bike optional",
  hereBtn: "Hier",
  placeEllipsis: "Ort…",
  heatmapPrefix: "Beliebt: ",
  heatmapOwn: " · Eigene Beiträge unter Privatsphäre",
  time: "Zeit",
  nearbyTitle: (profile) => `In deiner Nähe · ${profile}`,
  nearbyLiveHint:
    "Live-Route ab Standort oder Kartenmitte — MTB, Gravel, Rennrad, City oder E-Bike.",
  loopActiveHint:
    "Rundkurs aktiv — Live-Vorschläge nur echte Loops (unten). Keine Out-and-back-Pads (z. B. „60 min · Norden“).",
  suggestions: (min, profile) => `Vorschläge · ${min} min · ${profile}`,
  computing: "Berechne…",
  quickTimeout:
    "Live-Vorschläge nicht rechtzeitig — Seeds bleiben sichtbar.",
  retry: "Erneut versuchen",
  noLive: "Keine Live-Vorschläge — Seeds unten, Standort erlauben oder ",
  openPlan: "Planen öffnen",
  recompute: "Neu berechnen",
  moreOption: "Weitere Option",
  ghMinuteLimit:
    "GraphHopper-Minutenlimit — warte kurz oder nutze den Planer sparsam.",
  sixtyTitle: "~60 Min Rundkurse",
  sixtyLead:
    "Tempelhofer, Rhein-Neckar & kuratierte Feierabend-Loops — unabhängig vom Live-Routing.",
  noLoopsNearby: "Keine Rundkurse in der Nähe",
  noHonestHere:
    "Keine ehrlichen Loops (Start≈Ziel) hier — Demo-Stadt wählen oder Ort ändern. Keine A→B-Touren als Füllung.",
  changePlaceBtn: "Ort ändern",
  demoCity: "Demo-Stadt",
  planHint: "Adresse suchen oder auf die Karte tippen",
  start: "Start",
  end: "Ziel",
  startAddr: "Start-Adresse",
  endAddr: "Ziel-Adresse",
  addrPlaceholder: "z. B. Wiesloch",
  search: "Suchen",
  tapStart: "Start tippen",
  tapVia: "+ Via",
  tapEnd: "Ziel tippen",
  startAbbr: "S",
  endAbbr: "Z",
  startMyPos: "Start = meine Position",
  computingRoute: "Wird berechnet…",
  computeRoute: "Route berechnen",
  waysNearby: "Wege in der Nähe",
  overlay: "Overlay",
  osmLoading: "OSM-Wege werden geladen…",
  osmError: "OSM-Wege gerade nicht erreichbar — später erneut versuchen.",
  osmEmpty:
    "Keine OSM-Wege in diesem Ausschnitt — Karte verschieben oder zoomen.",
  show: "Anzeigen",
  append: "Anhängen",
  intoNav: "In Navi übernehmen",
  attachApproach: "Anfahrt / Anhängen",
  approachByCar: "Anfahrt mit Auto",
  approachOnFoot: "Zu Fuß zum Einstieg",
  atTrailStart: "Ich bin am Start",
  trailGravityHint:
    "DH: Auto oder zu Fuß zum oberen Einstieg. Die Abfahrt folgt dem Trail, nicht der Straße.",
  trailUnsuitable: (bike) =>
    `Mit ${bike} nicht auf diesen Trail. Garage wechseln — nicht heimlich als MTB routen.`,
  difficultyOpen: "offen",
  rangeLine: (lo, hi) => `Reichweite ${lo}–${hi} km`,
  fromLocation: (n, farther) =>
    farther
      ? `Vom Standort (${n} · +${farther} weiter)`
      : `Vom Standort (${n})`,
  sortedByYou: "deiner Position",
  sortedByMap: "Kartenmitte",
  sortedNear: (who) => `Sortiert nach Nähe zu ${who}`,
  offlineFallback:
    "Offline-Fallback: Berlin 60-Min Rundkurse (inkl. Tempelhofer), Katalog leer.",
  noToursFilter: "Keine Tour bei diesen Filtern",
  loosenLoop:
    "Nur echte Loops (Start≈Ziel) — keine A→B-Touren als Füllung. Filter lockern oder Ort ändern.",
  loosenOrPlan: "Filter lockern oder Planer öffnen.",
  loopFilterOff: "Rundkurs-Filter aus",
  fartherRegions: (n) => `Weitere Regionen (${n})`,
  outdooractive: (n) => `Outdooractive (${n})`,
  googlePois: (n) =>
    `${n} Google-POIs (Laden) · Powered by Google · kein Google-Kartenlayer`,
  noOa: "Keine OA-Touren in der Kartenregion.",
  example: "Beispiel",
  trailforks: (n) => `Trailforks (${n})`,
  tfFallback: "Attribution — kein Geometrie-Mirror.",
  mappeHeading: "Die Mappe",
  mappeEmpty:
    "Noch nichts gespeichert — Route hinzufügen, Tour speichern oder GPX.",
  mappeFilterEmpty:
    "Keine Touren in diesem Filter. Private bleiben in „Privat“ / „Alle“.",
  importGpx: "GPX importieren",
  withTrack: "mit Track",
  importTag: "Import",
  shared: "freigegeben",
  privateTour: "privat",
  remove: "Entfernen",
  plusCollection: "+ Sammlung",
  collectionsTitle: "Sammlungen",
  collectionsLead: "Lokale Ordner — kein Social-Feed.",
  namePlaceholder: "Name",
  create: "Anlegen",
  noCollection: "Noch keine Sammlung.",
  routesCount: (n) => `${n} Routen`,
  close: "Schließen",
  tapFor: (what) => `Tippe auf die Karte für ${what}`,
  cancel: "Abbrechen",
  saveAria: "Speichern",
  fromHereStart: "Von hier starten (Hybrid-Snap)",
  preview: "Vorschau",
  fromHere: "Von hier",
  intoPlan: "In Planen",
  locDeep: DISCOVER_STATUS_DE.locDeep,
  locWaitOrTap: DISCOVER_STATUS_DE.locWaitOrTap,
  locGps: DISCOVER_STATUS_DE.locGps,
  locDeepGps: DISCOVER_STATUS_DE.locDeepGps,
  locNoneDemo: DISCOVER_STATUS_DE.locNoneDemo,
  locDeniedDemo: DISCOVER_STATUS_DE.locDeniedDemo,
  locNoneAddr: DISCOVER_STATUS_DE.locNoneAddr,
  locDeniedAddr: DISCOVER_STATUS_DE.locDeniedAddr,
  locGpsCentered: DISCOVER_STATUS_DE.locGpsCentered,
  locWait: DISCOVER_STATUS_DE.locWait,
  calcSlow: DISCOVER_STATUS_DE.calcSlow,
  noQuick: DISCOVER_STATUS_DE.noQuick,
  rateLimit: DISCOVER_STATUS_DE.rateLimit,
  quickFail: DISCOVER_STATUS_DE.quickFail,
  gpxBad: DISCOVER_STATUS_DE.gpxBad,
  geocodeFail: DISCOVER_STATUS_DE.geocodeFail,
  savedLoaded: DISCOVER_STATUS_DE.savedLoaded,
  needStartEnd: DISCOVER_STATUS_DE.needStartEnd,
  pinOnly: DISCOVER_STATUS_DE.pinOnly,
  hybridFail: DISCOVER_STATUS_DE.hybridFail,
  trailFail: DISCOVER_STATUS_DE.trailFail,
  searchStart: DISCOVER_STATUS_DE.searchStart,
  changePlace: DISCOVER_STATUS_DE.changePlace,
  heatmapOffline: DISCOVER_STATUS_DE.heatmapOffline,
  demoRegion: (name) => `Demo-Region: ${name}`,
  demoRegionLoops: (name) => `Demo-Region: ${name} · 60 min Rundkurse`,
  noHits: (q) => `Keine Treffer für „${q}“`,
  geocodeFailHttp: (status) => `Adresssuche fehlgeschlagen (${status})`,
  inPlanNamed: (name) => `In Planen: ${name} — Start/Ziel editierbar`,
  inPlanNeedEnd: (name) =>
    `In Planen: ${name} — Ziel setzen, dann Route berechnen (kein Track).`,
  waypointStart: (label) => `Start: ${label}`,
  waypointEnd: (label) => `Ziel: ${label}`,
  gpxImported: (name, km) => `GPX importiert: ${name} · ${km} km`,
  hybridStats: (km, min) => `Hybrid · ${km} km · ${min} min`,
  trailInserted: (name) => `${name} eingefügt`,
  demoRouting: DEMO_ROUTING_NOTICE,
  unverifiedRouting: UNVERIFIED_ROUTING_NOTICE,
  pinMyPos: DISCOVER_PIN_DE.myPos,
  pinDeepLink: DISCOVER_PIN_DE.deepLink,
  pinHere: DISCOVER_PIN_DE.here,
  pinStartMap: DISCOVER_PIN_DE.startMap,
  pinEndMap: DISCOVER_PIN_DE.endMap,
  pinTourStart: DISCOVER_PIN_DE.tourStart,
  pinTourEnd: DISCOVER_PIN_DE.tourEnd,
  pinTourPlace: DISCOVER_PIN_DE.tourPlace,
  plannedRoute: DISCOVER_PIN_DE.planned,
  fromHereLabel: (name) => `${name} (von hier)`,
  ideaLabel: (name) => `${name} (Idee)`,
  planLabel: (name) => `${name} (Plan)`,
  surfaceAsphalt: "Asphalt",
  surfaceSchotter: "Schotter",
  surfaceNatur: "Naturweg",
  surfaceGras: "Gras",
  surfaceHolz: "Holz",
  hwyPath: "Pfad",
  hwyTrack: "Forstweg",
  hwyCycle: "Radweg",
  hwyBridle: "Reitweg",
  hwyFoot: "Fußweg",
  tourIdea: "Tour-Idee · Geometrie wird beim Planen geroutet",
  away: (km) => `~${km} km entfernt · `,
  loopRound: "⟲ Runde",
  pointAb: "A→B",
  because: "Weil: ",
  details: "Details",
  pageLink: "Seite",
  unsaveAria: "Gespeichert entfernen",
  save: "Speichern",
  saved: "Gespeichert",
  startInApp: "In App starten",
  variantPlanned: "Wie geplant",
  variantFlatter: "Weniger hm",
  variantUnpaved: "Mehr unpaved",
  variantValhallaOnly: "Varianten nur mit Live-Valhalla",
  openNativeApp: "In der App öffnen",
  placeKind: (kind) =>
    kind === "cafe"
      ? "Café"
      : kind === "water"
        ? "Quelle"
        : kind === "shop"
          ? "Laden"
          : kind === "repair"
            ? "Werkstatt"
            : kind === "viewpoint"
              ? "Blick"
              : "Ort",
  overview: "Überblick",
  popular: "Beliebt",
  photos: "Fotos",
  elevation: "Höhe",
  match: "Match",
  pinIdea: "Idee",
  pinOnlyHint:
    "Nur Ortspunkt — kein gespeicherter Track. Live-Routing, Planen oder GPX für eine echte Linie.",
  whySuggestion: "Warum dieser Vorschlag?",
  rangeSpan: (lo, hi) => `Reichweite ${lo}–${hi} km`,
  rangeTight: " — eng für diese Tour",
  rangeOk: " — passt",
  rangeTour: (km, conf) => `Tour ${km} km · ${conf} Konfidenz`,
  rangeProTitle: "Reichweitenprognose · Pro",
  rangeProBody: "Zeigt die Spanne gegen die Touranforderung.",
  unlockPro: "Pro unter Profil freischalten →",
  offlineMapsHint: "Offline-Karten lädst du in der App. Hier vormerken geht über ",
  offlineMapsAfter: ".",
  savedLink: "Gespeichert",
  heatCold: (k) =>
    `Noch wenig Heatmap-Daten (k≥${k}) — eigene Rides und mehr Fahrer füllen die Karte.`,
  heatConsent: (k) =>
    `Eigene Beiträge unter Privatsphäre aktivieren. Heatmap-Segmente (k≥${k}) sind trotzdem sichtbar, sobald genug Fahrer da sind.`,
  heatConsentBefore: "Eigene Beiträge unter ",
  heatConsentAfter: (k) =>
    ` aktivieren. Heatmap-Segmente (k≥${k}) sind trotzdem sichtbar, sobald genug Fahrer da sind.`,
  privacyLink: "Privatsphäre",
  heatOwn: "Eigene Ride",
  heatSection: "Abschnitt",
  riders: (n, pct) => `${n} Fahrer · Intensität ${pct} %`,
  noSegments: "Keine sichtbaren Segmente in diesem Ausschnitt.",
  heading: (deg) => `Blickrichtung ${deg}°`,
  demoPhotos: "Beispielbilder — Live-Fotos brauchen Mapillary-Zugang (Ops).",
  noPhotos: "Keine Trail-Fotos in der Nähe.",
  elevMissing: "Höhenprofil noch nicht verfügbar — keine Schätzung als Füllung.",
  publicTour: "Öffentliche Tour-Seite →",
  openPlanner: "Im Planer öffnen →",
  gapElev: (km) => ` · ${km} km ohne Höhendaten`,
  surfaceTitle: "Oberfläche",
  difficultyTitle: "Schwierigkeit",
  estimate: "Schätzung",
  elevEst: (hm) => `Höhenschätzung ca. ${hm} hm`,
  elevProfile: (hm) => `Höhenprofil ca. ${hm} hm`,
  fromHereTitle: "Route ab hier",
  fromHereHint:
    "Live-Routing vom GPS oder der Kartenmitte — speichern & in der App fahren.",
  needCenter: "Standort oder Kartenmitte fehlt",
  stretch: "Strecke",
  compute: "Berechnen",
  inApp: "In App",
  noHonestEngine:
    "Keine echte Runde — Engine lieferte A→B (Start≠Ziel). Bitte erneut oder Seeds nutzen.",
  savedEngine: (line) => `${line} · gespeichert`,
  routingFail: "Routing fehlgeschlagen",
  roundKm: (km) => `Runde ${km} km`,
  tourKm: (km) => `Tour ${km} km`,
  packsTitle: "Offline-Regionen",
  packsLead:
    "Nur gebaute Packs sind ladbar. Aktivierung (Routing + Kartenkacheln) läuft in der Android/iOS-App.",
  packsCatalog: "Katalog…",
  packsEmpty: "Keine Packs im Katalog — Region-Build lokal ausführen.",
  packsUnreachable: "Offline-Katalog nicht erreichbar.",
  packsNone: "Keine Packs verfügbar.",
  packsNotBuilt: "Noch nicht gebaut",
  packsDownload: (name) => `Offline-Pack ${name} herunterladen`,
  packsStarted: (name) =>
    `${name}: Download gestartet. Aktivierung nur in der Mobile-App (Offline-Sheet).`,
  packsFail: "Download fehlgeschlagen",
  packsLoad: "Laden",
  packsStub: "Stub",
  back: "Zurück",
  tourIdeaLive: "Tour-Idee — Strecke beim Planen oder Starten live berechnen",
};

const EN: DiscoverUi = {
  ...DE,
  osmOptional: "OSM · ~60 min loops — bike optional",
  hereBtn: "Here",
  placeEllipsis: "Place…",
  heatmapPrefix: "Popular: ",
  heatmapOwn: " · Your traces under Privacy",
  time: "Time",
  nearbyTitle: (profile) => `Near you · ${profile}`,
  nearbyLiveHint:
    "Live route from GPS or map centre — MTB, Gravel, Road, City or E-Bike.",
  loopActiveHint:
    "Loop on — live suggestions only real loops (below). No out-and-back pads (e.g. “60 min · North”).",
  suggestions: (min, profile) => `Suggestions · ${min} min · ${profile}`,
  computing: "Computing…",
  quickTimeout: "Live suggestions timed out — seeds stay visible.",
  retry: "Try again",
  noLive: "No live suggestions — seeds below, allow location or ",
  openPlan: "Open Plan",
  recompute: "Recompute",
  moreOption: "Another option",
  ghMinuteLimit:
    "GraphHopper minute limit — wait a bit or use the planner sparingly.",
  sixtyTitle: "~60 min loops",
  sixtyLead:
    "Tempelhofer, Rhein-Neckar and curated after-work loops — independent of live routing.",
  noLoopsNearby: "No loops nearby",
  noHonestHere:
    "No honest loops (start≈finish) here — pick a demo city or change place. No A→B filler tours.",
  changePlaceBtn: "Change place",
  demoCity: "Demo city",
  planHint: "Search an address or tap the map",
  start: "Start",
  end: "Finish",
  startAddr: "Start address",
  endAddr: "Finish address",
  addrPlaceholder: "e.g. Wiesloch",
  search: "Search",
  tapStart: "Tap start",
  tapVia: "+ Via",
  tapEnd: "Tap finish",
  startAbbr: "S",
  endAbbr: "F",
  startMyPos: "Start = my position",
  computingRoute: "Computing…",
  computeRoute: "Compute route",
  waysNearby: "Ways nearby",
  overlay: "Overlay",
  osmLoading: "Loading OSM ways…",
  osmError: "OSM ways unreachable right now — try again later.",
  osmEmpty: "No OSM ways in this view — pan or zoom the map.",
  show: "Show",
  append: "Append",
  intoNav: "Take into navi",
  attachApproach: "Approach / append",
  approachByCar: "Drive to the trail",
  approachOnFoot: "Walk to the entry",
  atTrailStart: "I'm at the start",
  trailGravityHint:
    "DH: drive or walk to the top entry. The descent follows the trail, not the road.",
  trailUnsuitable: (bike) =>
    `Not with ${bike} on this trail. Switch bikes in the garage — don't secretly MTB-route.`,
  difficultyOpen: "open",
  rangeLine: (lo, hi) => `Range ${lo}–${hi} km`,
  fromLocation: (n, farther) =>
    farther ? `From location (${n} · +${farther} farther)` : `From location (${n})`,
  sortedByYou: "your position",
  sortedByMap: "map centre",
  sortedNear: (who) => `Sorted by distance to ${who}`,
  offlineFallback:
    "Offline fallback: Berlin 60 min loops (incl. Tempelhofer), catalogue empty.",
  noToursFilter: "No tour with these filters",
  loosenLoop:
    "Real loops only (start≈finish) — no A→B filler. Loosen filters or change place.",
  loosenOrPlan: "Loosen filters or open the planner.",
  loopFilterOff: "Loop filter off",
  fartherRegions: (n) => `More regions (${n})`,
  outdooractive: (n) => `Outdooractive (${n})`,
  googlePois: (n) =>
    `${n} Google POIs (Laden) · Powered by Google · no Google map layer`,
  noOa: "No OA tours in this map region.",
  example: "Example",
  trailforks: (n) => `Trailforks (${n})`,
  tfFallback: "Attribution — no geometry mirror.",
  mappeHeading: "Die Mappe",
  mappeEmpty: "Nothing saved yet — add a route, save a tour or GPX.",
  mappeFilterEmpty:
    "No tours in this filter. Private ones stay under Private / All.",
  importGpx: "Import GPX",
  withTrack: "with track",
  importTag: "Import",
  shared: "shared",
  privateTour: "private",
  remove: "Remove",
  plusCollection: "+ Collection",
  collectionsTitle: "Collections",
  collectionsLead: "Local folders — no social feed.",
  namePlaceholder: "Name",
  create: "Create",
  noCollection: "No collection yet.",
  routesCount: (n) => `${n} routes`,
  close: "Close",
  tapFor: (what) => `Tap the map for ${what}`,
  cancel: "Cancel",
  saveAria: "Save",
  fromHereStart: "Start from here (hybrid snap)",
  preview: "Preview",
  fromHere: "From here",
  intoPlan: "Into Plan",
  locDeep: "Location: deep link",
  locWaitOrTap: "Getting location… — or tap a place",
  locGps: "Location: GPS",
  locDeepGps: "Location: deep link (GPS available)",
  locNoneDemo: "Location unavailable — demo city or address",
  locDeniedDemo: "Location denied — pick a demo city or search an address",
  locNoneAddr: "Location unavailable — search an address or pick a demo city",
  locDeniedAddr: "Location denied — search an address or pick a demo city",
  locGpsCentered: "Location: GPS — map centred",
  locWait: "Getting location…",
  calcSlow:
    "Compute too slow — ~60 min seeds below, or try again.",
  noQuick: "No quick routes — seeds below or use the planner.",
  rateLimit: "Routing limit hit — approximations shown. Recompute later.",
  quickFail: "Quick routing failed — seeds below, or try again.",
  gpxBad: "GPX invalid or too few points",
  geocodeFail: "Address search failed",
  savedLoaded: "Saved route loaded",
  needStartEnd: "Could not compute a route — set start and finish.",
  pinOnly: "Pin only — no track. In Plan add a finish, or live routing.",
  hybridFail: "Hybrid snap failed",
  trailFail: "Trail could not be connected",
  searchStart: "Search address — set start",
  changePlace: "Change place — search city or address",
  heatmapOffline: "Heatmap offline",
  demoRegion: (name) => `Demo region: ${name}`,
  demoRegionLoops: (name) => `Demo region: ${name} · 60 min loops`,
  noHits: (q) => `No hits for “${q}”`,
  geocodeFailHttp: (status) => `Address search failed (${status})`,
  inPlanNamed: (name) => `In Plan: ${name} — start/finish editable`,
  inPlanNeedEnd: (name) =>
    `In Plan: ${name} — set finish, then compute (no track).`,
  waypointStart: (label) => `Start: ${label}`,
  waypointEnd: (label) => `Finish: ${label}`,
  gpxImported: (name, km) => `GPX imported: ${name} · ${km} km`,
  hybridStats: (km, min) => `Hybrid · ${km} km · ${min} min`,
  trailInserted: (name) => `${name} inserted`,
  demoRouting: "Routes use demo geometry — live routing is not configured.",
  unverifiedRouting:
    "Routing key set — live not verified yet. On errors, demo geometry.",
  pinMyPos: "My position",
  pinDeepLink: "Deep-link place",
  pinHere: "Here",
  pinStartMap: "Start (map)",
  pinEndMap: "Finish (map)",
  pinTourStart: "Tour start",
  pinTourEnd: "Tour finish",
  pinTourPlace: "Tour place",
  plannedRoute: "Planned route",
  fromHereLabel: (name) => `${name} (from here)`,
  ideaLabel: (name) => `${name} (idea)`,
  planLabel: (name) => `${name} (plan)`,
  surfaceAsphalt: "Asphalt",
  surfaceSchotter: "Gravel",
  surfaceNatur: "Dirt",
  surfaceGras: "Grass",
  surfaceHolz: "Wood",
  hwyPath: "Path",
  hwyTrack: "Track",
  hwyCycle: "Cycleway",
  hwyBridle: "Bridleway",
  hwyFoot: "Footway",
  tourIdea: "Tour idea · geometry is routed when you plan",
  away: (km) => `~${km} km away · `,
  loopRound: "⟲ Loop",
  pointAb: "A→B",
  because: "Because: ",
  details: "Details",
  pageLink: "Page",
  unsaveAria: "Remove saved",
  save: "Save",
  saved: "Saved",
  startInApp: "Start in app",
  variantPlanned: "As planned",
  variantFlatter: "Less climb",
  variantUnpaved: "More unpaved",
  variantValhallaOnly: "Variants need live Valhalla",
  openNativeApp: "Open in the app",
  placeKind: (kind) =>
    kind === "cafe"
      ? "Café"
      : kind === "water"
        ? "Water"
        : kind === "shop"
          ? "Shop"
          : kind === "repair"
            ? "Repair"
            : kind === "viewpoint"
              ? "View"
              : "Place",
  overview: "Overview",
  popular: "Popular",
  photos: "Photos",
  elevation: "Elevation",
  match: "Match",
  pinIdea: "Idea",
  pinOnlyHint:
    "Pin only — no stored track. Live routing, Plan or GPX for a real line.",
  whySuggestion: "Why this suggestion?",
  rangeSpan: (lo, hi) => `Range ${lo}–${hi} km`,
  rangeTight: " — tight for this tour",
  rangeOk: " — fits",
  rangeTour: (km, conf) => `Tour ${km} km · ${conf} confidence`,
  rangeProTitle: "Range forecast · Pro",
  rangeProBody: "Shows the span against the tour demand.",
  unlockPro: "Unlock Pro under Profile →",
  offlineMapsHint: "You load offline maps in the app. Bookmark here via ",
  offlineMapsAfter: ".",
  savedLink: "Saved",
  heatCold: (k) =>
    `Little heatmap data yet (k≥${k}) — your rides and more riders fill the map.`,
  heatConsent: (k) =>
    `Turn on your traces under Privacy. Heatmap segments (k≥${k}) still show once enough riders are there.`,
  heatConsentBefore: "Turn on your traces under ",
  heatConsentAfter: (k) =>
    `. Heatmap segments (k≥${k}) still show once enough riders are there.`,
  privacyLink: "Privacy",
  heatOwn: "Own ride",
  heatSection: "Segment",
  riders: (n, pct) => `${n} riders · intensity ${pct} %`,
  noSegments: "No visible segments in this view.",
  heading: (deg) => `Heading ${deg}°`,
  demoPhotos: "Sample photos — live photos need Mapillary access (ops).",
  noPhotos: "No trail photos nearby.",
  elevMissing: "Elevation profile not available yet — no estimate as filler.",
  publicTour: "Public tour page →",
  openPlanner: "Open in planner →",
  gapElev: (km) => ` · ${km} km without elevation data`,
  surfaceTitle: "Surface",
  difficultyTitle: "Difficulty",
  estimate: "Estimate",
  elevEst: (hm) => `Elevation estimate ~${hm} hm`,
  elevProfile: (hm) => `Elevation profile ~${hm} hm`,
  fromHereTitle: "Route from here",
  fromHereHint:
    "Live routing from GPS or map centre — save and ride in the app.",
  needCenter: "Location or map centre missing",
  stretch: "Point to point",
  compute: "Compute",
  inApp: "In app",
  noHonestEngine:
    "No real loop — engine returned A→B (start≠finish). Try again or use seeds.",
  savedEngine: (line) => `${line} · saved`,
  routingFail: "Routing failed",
  roundKm: (km) => `Loop ${km} km`,
  tourKm: (km) => `Tour ${km} km`,
  packsTitle: "Offline regions",
  packsLead:
    "Only built packs can download. Activation (routing + tiles) runs in the Android/iOS app.",
  packsCatalog: "Catalogue…",
  packsEmpty: "No packs in the catalogue — run a region build locally.",
  packsUnreachable: "Offline catalogue unreachable.",
  packsNone: "No packs available.",
  packsNotBuilt: "Not built yet",
  packsDownload: (name) => `Download offline pack ${name}`,
  packsStarted: (name) =>
    `${name}: download started. Activation only in the mobile app (offline sheet).`,
  packsFail: "Download failed",
  packsLoad: "Download",
  packsStub: "Stub",
  back: "Back",
  tourIdeaLive: "Tour idea — compute the line live when you plan or start",
};

const FR: DiscoverUi = {
  ...EN,
  osmOptional: "OSM · boucles ~60 min — vélo optionnel",
  hereBtn: "Ici",
  placeEllipsis: "Lieu…",
  heatmapPrefix: "Populaire : ",
  heatmapOwn: " · Tes traces sous Confidentialité",
  time: "Temps",
  nearbyTitle: (profile) => `Près de toi · ${profile}`,
  nearbyLiveHint:
    "Route live depuis le GPS ou le centre carte — MTB, Gravel, Route, City ou E-Bike.",
  loopActiveHint:
    "Boucle active — suggestions live seulement de vraies boucles (en bas). Pas de pads aller-retour (p. ex. « 60 min · Nord »).",
  suggestions: (min, profile) => `Suggestions · ${min} min · ${profile}`,
  computing: "Calcul…",
  quickTimeout: "Suggestions live trop lentes — les seeds restent visibles.",
  retry: "Réessayer",
  noLive: "Pas de suggestions live — seeds en bas, autorise le lieu ou ",
  openPlan: "Ouvrir Planifier",
  recompute: "Recalculer",
  moreOption: "Autre option",
  ghMinuteLimit:
    "Limite minutes GraphHopper — attends un peu ou utilise le planificateur avec parcimonie.",
  sixtyTitle: "Boucles ~60 min",
  sixtyLead:
    "Tempelhofer, Rhein-Neckar et boucles after-work — indépendant du routing live.",
  noLoopsNearby: "Pas de boucles à proximité",
  noHonestHere:
    "Pas de vraies boucles (départ≈arrivée) ici — choisis une ville démo ou change de lieu. Pas de tours A→B pour remplir.",
  changePlaceBtn: "Changer de lieu",
  demoCity: "Ville démo",
  planHint: "Cherche une adresse ou tape la carte",
  start: "Départ",
  end: "Arrivée",
  startAddr: "Adresse de départ",
  endAddr: "Adresse d’arrivée",
  addrPlaceholder: "ex. Wiesloch",
  search: "Chercher",
  tapStart: "Taper départ",
  tapVia: "+ Via",
  tapEnd: "Taper arrivée",
  startAbbr: "D",
  endAbbr: "A",
  startMyPos: "Départ = ma position",
  computingRoute: "Calcul…",
  computeRoute: "Calculer la route",
  waysNearby: "Chemins à proximité",
  overlay: "Overlay",
  osmLoading: "Chemins OSM en chargement…",
  osmError: "Chemins OSM injoignables — réessaie plus tard.",
  osmEmpty: "Pas de chemins OSM dans cette vue — déplace ou zoome la carte.",
  show: "Afficher",
  append: "Ajouter",
  intoNav: "Prendre en navi",
  attachApproach: "Approche / ajouter",
  approachByCar: "Y aller en voiture",
  approachOnFoot: "À pied jusqu'à l'entrée",
  atTrailStart: "Je suis au départ",
  trailGravityHint:
    "DH : voiture ou à pied jusqu'à l'entrée haute. La descente suit le trail, pas la route.",
  trailUnsuitable: (bike) =>
    `Pas avec un ${bike} sur ce trail. Change de vélo au garage — pas de routage VTT caché.`,
  difficultyOpen: "ouvert",
  rangeLine: (lo, hi) => `Autonomie ${lo}–${hi} km`,
  fromLocation: (n, farther) =>
    farther
      ? `Depuis le lieu (${n} · +${farther} plus loin)`
      : `Depuis le lieu (${n})`,
  sortedByYou: "ta position",
  sortedByMap: "centre carte",
  sortedNear: (who) => `Trié par proximité de ${who}`,
  offlineFallback:
    "Repli hors ligne : boucles Berlin 60 min (dont Tempelhofer), catalogue vide.",
  noToursFilter: "Pas de sortie avec ces filtres",
  loosenLoop:
    "Seulement de vraies boucles (départ≈arrivée) — pas de A→B pour remplir. Desserrer les filtres ou changer de lieu.",
  loosenOrPlan: "Desserrer les filtres ou ouvrir le planificateur.",
  loopFilterOff: "Filtre boucle off",
  fartherRegions: (n) => `Autres régions (${n})`,
  outdooractive: (n) => `Outdooractive (${n})`,
  googlePois: (n) =>
    `${n} POI Google (Laden) · Powered by Google · pas de calque Google`,
  noOa: "Pas de tours OA dans cette région carte.",
  example: "Exemple",
  trailforks: (n) => `Trailforks (${n})`,
  tfFallback: "Attribution — pas de miroir de géométrie.",
  mappeHeading: "Die Mappe",
  mappeEmpty:
    "Rien d’enregistré — ajoute une route, sauve une sortie ou GPX.",
  mappeFilterEmpty:
    "Pas de sorties dans ce filtre. Les privées restent sous Privé / Tous.",
  importGpx: "Importer GPX",
  withTrack: "avec trace",
  importTag: "Import",
  shared: "partagé",
  privateTour: "privé",
  remove: "Retirer",
  plusCollection: "+ Collection",
  collectionsTitle: "Collections",
  collectionsLead: "Dossiers locaux — pas de fil social.",
  namePlaceholder: "Nom",
  create: "Créer",
  noCollection: "Pas encore de collection.",
  routesCount: (n) => `${n} routes`,
  close: "Fermer",
  tapFor: (what) => `Tape la carte pour ${what}`,
  cancel: "Annuler",
  saveAria: "Enregistrer",
  fromHereStart: "Partir d’ici (hybrid snap)",
  preview: "Aperçu",
  fromHere: "D’ici",
  intoPlan: "Dans Planifier",
  locDeep: "Lieu : deep link",
  locWaitOrTap: "Lieu en cours… — ou tape un endroit",
  locGps: "Lieu : GPS",
  locDeepGps: "Lieu : deep link (GPS dispo)",
  locNoneDemo: "Lieu indisponible — ville démo ou adresse",
  locDeniedDemo: "Lieu refusé — choisis une ville démo ou cherche une adresse",
  locNoneAddr: "Lieu indisponible — cherche une adresse ou une ville démo",
  locDeniedAddr: "Lieu refusé — cherche une adresse ou une ville démo",
  locGpsCentered: "Lieu : GPS — carte centrée",
  locWait: "Lieu en cours…",
  calcSlow:
    "Calcul trop lent — seeds ~60 min en bas, ou réessaie.",
  noQuick: "Pas de routes rapides — seeds en bas ou planificateur.",
  rateLimit: "Limite routing — approximations affichées. Recalcule plus tard.",
  quickFail: "Routing rapide échoué — seeds en bas, ou réessaie.",
  gpxBad: "GPX invalide ou trop peu de points",
  geocodeFail: "Recherche d’adresse échouée",
  savedLoaded: "Route enregistrée chargée",
  needStartEnd: "Route non calculée — pose départ et arrivée.",
  pinOnly: "Simple pin — pas de trace. Dans Planifier + arrivée, ou routing live.",
  hybridFail: "Hybrid snap échoué",
  trailFail: "Trail non connecté",
  searchStart: "Chercher une adresse — poser le départ",
  changePlace: "Changer de lieu — ville ou adresse",
  heatmapOffline: "Heatmap hors ligne",
  demoRegion: (name) => `Région démo : ${name}`,
  demoRegionLoops: (name) => `Région démo : ${name} · boucles 60 min`,
  noHits: (q) => `Aucun résultat pour « ${q} »`,
  geocodeFailHttp: (status) => `Recherche d’adresse échouée (${status})`,
  inPlanNamed: (name) => `Dans Planifier : ${name} — départ/arrivée éditables`,
  inPlanNeedEnd: (name) =>
    `Dans Planifier : ${name} — pose l’arrivée, puis calcule (pas de trace).`,
  waypointStart: (label) => `Départ : ${label}`,
  waypointEnd: (label) => `Arrivée : ${label}`,
  gpxImported: (name, km) => `GPX importé : ${name} · ${km} km`,
  hybridStats: (km, min) => `Hybrid · ${km} km · ${min} min`,
  trailInserted: (name) => `${name} inséré`,
  demoRouting:
    "Les routes utilisent une géométrie démo — routing live non configuré.",
  unverifiedRouting:
    "Clé routing posée — live pas encore vérifié. En cas d’erreur, géométrie démo.",
  pinMyPos: "Ma position",
  pinDeepLink: "Lieu deep-link",
  pinHere: "Ici",
  pinStartMap: "Départ (carte)",
  pinEndMap: "Arrivée (carte)",
  pinTourStart: "Départ de la sortie",
  pinTourEnd: "Arrivée de la sortie",
  pinTourPlace: "Lieu de la sortie",
  plannedRoute: "Route planifiée",
  fromHereLabel: (name) => `${name} (d’ici)`,
  ideaLabel: (name) => `${name} (idée)`,
  planLabel: (name) => `${name} (plan)`,
  surfaceAsphalt: "Asphalte",
  surfaceSchotter: "Graviers",
  surfaceNatur: "Chemin naturel",
  surfaceGras: "Herbe",
  surfaceHolz: "Bois",
  hwyPath: "Sentier",
  hwyTrack: "Piste forestière",
  hwyCycle: "Piste cyclable",
  hwyBridle: "Chemin équestre",
  hwyFoot: "Chemin piéton",
  tourIdea: "Idée de sortie · la géométrie se route au plan",
  away: (km) => `~${km} km · `,
  loopRound: "⟲ Boucle",
  pointAb: "A→B",
  because: "Parce que : ",
  details: "Détails",
  pageLink: "Page",
  unsaveAria: "Retirer l’enregistrement",
  save: "Enregistrer",
  saved: "Enregistré",
  startInApp: "Démarrer dans l’app",
  variantPlanned: "Comme prévu",
  variantFlatter: "Moins de dénivelé",
  variantUnpaved: "Plus de non bitumé",
  variantValhallaOnly: "Variantes seulement avec Valhalla live",
  openNativeApp: "Ouvrir dans l’app",
  placeKind: (kind) =>
    kind === "cafe"
      ? "Café"
      : kind === "water"
        ? "Eau"
        : kind === "shop"
          ? "Magasin"
          : kind === "repair"
            ? "Atelier"
            : kind === "viewpoint"
              ? "Vue"
              : "Lieu",
  overview: "Aperçu",
  popular: "Populaire",
  photos: "Photos",
  elevation: "Dénivelé",
  match: "Match",
  pinIdea: "Idée",
  pinOnlyHint:
    "Simple pin — pas de trace enregistrée. Routing live, Planifier ou GPX pour une vraie ligne.",
  whySuggestion: "Pourquoi cette suggestion ?",
  rangeSpan: (lo, hi) => `Autonomie ${lo}–${hi} km`,
  rangeTight: " — juste pour cette sortie",
  rangeOk: " — ça passe",
  rangeTour: (km, conf) => `Sortie ${km} km · confiance ${conf}`,
  rangeProTitle: "Prévision d’autonomie · Pro",
  rangeProBody: "Montre la fourchette contre la demande de la sortie.",
  unlockPro: "Débloquer Pro sous Profil →",
  offlineMapsHint: "Tu charges les cartes hors ligne dans l’app. Marquer ici via ",
  offlineMapsAfter: ".",
  savedLink: "Enregistré",
  heatCold: (k) =>
    `Peu de données heatmap (k≥${k}) — tes rides et plus de riders remplissent la carte.`,
  heatConsent: (k) =>
    `Active tes traces sous Confidentialité. Les segments heatmap (k≥${k}) restent visibles dès qu’il y a assez de riders.`,
  heatConsentBefore: "Active tes traces sous ",
  heatConsentAfter: (k) =>
    `. Les segments heatmap (k≥${k}) restent visibles dès qu’il y a assez de riders.`,
  privacyLink: "Confidentialité",
  heatOwn: "Ton ride",
  heatSection: "Segment",
  riders: (n, pct) => `${n} riders · intensité ${pct} %`,
  noSegments: "Pas de segments visibles dans cette vue.",
  heading: (deg) => `Direction ${deg}°`,
  demoPhotos: "Photos d’exemple — les photos live demandent Mapillary (ops).",
  noPhotos: "Pas de photos trail à proximité.",
  elevMissing:
    "Profil d’altitude pas encore dispo — pas d’estimation pour remplir.",
  publicTour: "Page sortie publique →",
  openPlanner: "Ouvrir dans le planificateur →",
  gapElev: (km) => ` · ${km} km sans données d’altitude`,
  surfaceTitle: "Surface",
  difficultyTitle: "Difficulté",
  estimate: "Estimation",
  elevEst: (hm) => `Estimation d’altitude ~${hm} hm`,
  elevProfile: (hm) => `Profil d’altitude ~${hm} hm`,
  fromHereTitle: "Route d’ici",
  fromHereHint:
    "Routing live depuis le GPS ou le centre carte — enregistrer et rouler dans l’app.",
  needCenter: "Lieu ou centre carte manquant",
  stretch: "Trajet",
  compute: "Calculer",
  inApp: "Dans l’app",
  noHonestEngine:
    "Pas de vraie boucle — l’engine a livré A→B (départ≠arrivée). Réessaie ou utilise les seeds.",
  savedEngine: (line) => `${line} · enregistré`,
  routingFail: "Routing échoué",
  roundKm: (km) => `Boucle ${km} km`,
  tourKm: (km) => `Sortie ${km} km`,
  packsTitle: "Régions hors ligne",
  packsLead:
    "Seuls les packs construits se téléchargent. L’activation (routing + tuiles) tourne dans l’app Android/iOS.",
  packsCatalog: "Catalogue…",
  packsEmpty: "Pas de packs au catalogue — lance un build région en local.",
  packsUnreachable: "Catalogue hors ligne injoignable.",
  packsNone: "Pas de packs disponibles.",
  packsNotBuilt: "Pas encore construit",
  packsDownload: (name) => `Télécharger le pack hors ligne ${name}`,
  packsStarted: (name) =>
    `${name} : téléchargement lancé. Activation seulement dans l’app mobile (feuille hors ligne).`,
  packsFail: "Téléchargement échoué",
  packsLoad: "Télécharger",
  packsStub: "Stub",
  back: "Retour",
  tourIdeaLive:
    "Idée de sortie — calcule la ligne en live quand tu planifies ou démarres",
};

const IT: DiscoverUi = {
  ...EN,
  osmOptional: "OSM · anelli ~60 min — bici opzionale",
  hereBtn: "Qui",
  placeEllipsis: "Luogo…",
  heatmapPrefix: "Popolare: ",
  heatmapOwn: " · Le tue tracce sotto Privacy",
  time: "Tempo",
  nearbyTitle: (profile) => `Vicino a te · ${profile}`,
  nearbyLiveHint:
    "Route live da GPS o centro mappa — MTB, Gravel, Corsa, City o E-Bike.",
  loopActiveHint:
    "Anello attivo — suggerimenti live solo anelli veri (sotto). Niente pad andata-ritorno (es. «60 min · Nord»).",
  suggestions: (min, profile) => `Suggerimenti · ${min} min · ${profile}`,
  computing: "Calcolo…",
  quickTimeout: "Suggerimenti live in ritardo — i seed restano visibili.",
  retry: "Riprova",
  noLive: "Nessun suggerimento live — seed sotto, consenti il luogo o ",
  openPlan: "Apri Pianifica",
  recompute: "Ricalcola",
  moreOption: "Altra opzione",
  ghMinuteLimit:
    "Limite minuti GraphHopper — aspetta un po’ o usa il planner con parsimonia.",
  sixtyTitle: "Anelli ~60 min",
  sixtyLead:
    "Tempelhofer, Rhein-Neckar e anelli after-work — indipendente dal routing live.",
  noLoopsNearby: "Nessun anello qui vicino",
  noHonestHere:
    "Nessun anello onesto (partenza≈arrivo) qui — scegli una città demo o cambia luogo. Niente tour A→B di riempimento.",
  changePlaceBtn: "Cambia luogo",
  demoCity: "Città demo",
  planHint: "Cerca un indirizzo o tocca la mappa",
  start: "Partenza",
  end: "Arrivo",
  startAddr: "Indirizzo di partenza",
  endAddr: "Indirizzo di arrivo",
  addrPlaceholder: "es. Wiesloch",
  search: "Cerca",
  tapStart: "Tocca partenza",
  tapVia: "+ Via",
  tapEnd: "Tocca arrivo",
  startAbbr: "P",
  endAbbr: "A",
  startMyPos: "Partenza = la mia posizione",
  computingRoute: "Calcolo…",
  computeRoute: "Calcola route",
  waysNearby: "Vie vicine",
  overlay: "Overlay",
  osmLoading: "Vie OSM in caricamento…",
  osmError: "Vie OSM non raggiungibili — riprova più tardi.",
  osmEmpty: "Nessuna via OSM in questa vista — sposta o zooma la mappa.",
  show: "Mostra",
  append: "Aggiungi",
  intoNav: "Prendi in navi",
  attachApproach: "Avvicinamento / aggiungi",
  approachByCar: "Arriva in auto",
  approachOnFoot: "A piedi all'ingresso",
  atTrailStart: "Sono al via",
  trailGravityHint:
    "DH: auto o a piedi all'ingresso in alto. La discesa segue il trail, non la strada.",
  trailUnsuitable: (bike) =>
    `Non con ${bike} su questo trail. Cambia bici in garage — niente routing MTB nascosto.`,
  difficultyOpen: "aperto",
  rangeLine: (lo, hi) => `Autonomia ${lo}–${hi} km`,
  fromLocation: (n, farther) =>
    farther
      ? `Dal luogo (${n} · +${farther} più lontano)`
      : `Dal luogo (${n})`,
  sortedByYou: "la tua posizione",
  sortedByMap: "centro mappa",
  sortedNear: (who) => `Ordinato per vicinanza a ${who}`,
  offlineFallback:
    "Fallback offline: anelli Berlino 60 min (incl. Tempelhofer), catalogo vuoto.",
  noToursFilter: "Nessuna uscita con questi filtri",
  loosenLoop:
    "Solo anelli veri (partenza≈arrivo) — niente A→B di riempimento. Allenta i filtri o cambia luogo.",
  loosenOrPlan: "Allenta i filtri o apri il planner.",
  loopFilterOff: "Filtro anello off",
  fartherRegions: (n) => `Altre regioni (${n})`,
  outdooractive: (n) => `Outdooractive (${n})`,
  googlePois: (n) =>
    `${n} POI Google (Laden) · Powered by Google · nessun layer Google`,
  noOa: "Nessun tour OA in questa regione mappa.",
  example: "Esempio",
  trailforks: (n) => `Trailforks (${n})`,
  tfFallback: "Attribution — niente specchio di geometria.",
  mappeHeading: "Die Mappe",
  mappeEmpty: "Ancora niente salvato — aggiungi una route, salva un’uscita o GPX.",
  mappeFilterEmpty:
    "Nessuna uscita in questo filtro. I privati restano sotto Privato / Tutti.",
  importGpx: "Importa GPX",
  withTrack: "con traccia",
  importTag: "Import",
  shared: "condiviso",
  privateTour: "privato",
  remove: "Rimuovi",
  plusCollection: "+ Raccolta",
  collectionsTitle: "Raccolte",
  collectionsLead: "Cartelle locali — niente feed social.",
  namePlaceholder: "Nome",
  create: "Crea",
  noCollection: "Ancora nessuna raccolta.",
  routesCount: (n) => `${n} route`,
  close: "Chiudi",
  tapFor: (what) => `Tocca la mappa per ${what}`,
  cancel: "Annulla",
  saveAria: "Salva",
  fromHereStart: "Parti da qui (hybrid snap)",
  preview: "Anteprima",
  fromHere: "Da qui",
  intoPlan: "In Pianifica",
  locDeep: "Luogo: deep link",
  locWaitOrTap: "Luogo in corso… — o tocca un posto",
  locGps: "Luogo: GPS",
  locDeepGps: "Luogo: deep link (GPS disponibile)",
  locNoneDemo: "Luogo non disponibile — città demo o indirizzo",
  locDeniedDemo: "Luogo negato — scegli una città demo o cerca un indirizzo",
  locNoneAddr: "Luogo non disponibile — cerca un indirizzo o una città demo",
  locDeniedAddr: "Luogo negato — cerca un indirizzo o una città demo",
  locGpsCentered: "Luogo: GPS — mappa centrata",
  locWait: "Luogo in corso…",
  calcSlow: "Calcolo troppo lento — seed ~60 min sotto, o riprova.",
  noQuick: "Nessuna route rapida — seed sotto o planner.",
  rateLimit: "Limite routing — mostrate approssimazioni. Ricalcola dopo.",
  quickFail: "Routing rapido fallito — seed sotto, o riprova.",
  gpxBad: "GPX non valido o troppi pochi punti",
  geocodeFail: "Ricerca indirizzo fallita",
  savedLoaded: "Route salvata caricata",
  needStartEnd: "Route non calcolata — imposta partenza e arrivo.",
  pinOnly: "Solo pin — niente traccia. In Pianifica + arrivo, o routing live.",
  hybridFail: "Hybrid snap fallito",
  trailFail: "Trail non collegato",
  searchStart: "Cerca indirizzo — imposta partenza",
  changePlace: "Cambia luogo — città o indirizzo",
  heatmapOffline: "Heatmap offline",
  demoRegion: (name) => `Regione demo: ${name}`,
  demoRegionLoops: (name) => `Regione demo: ${name} · anelli 60 min`,
  noHits: (q) => `Nessun risultato per «${q}»`,
  geocodeFailHttp: (status) => `Ricerca indirizzo fallita (${status})`,
  inPlanNamed: (name) => `In Pianifica: ${name} — partenza/arrivo modificabili`,
  inPlanNeedEnd: (name) =>
    `In Pianifica: ${name} — imposta l’arrivo, poi calcola (niente traccia).`,
  waypointStart: (label) => `Partenza: ${label}`,
  waypointEnd: (label) => `Arrivo: ${label}`,
  gpxImported: (name, km) => `GPX importato: ${name} · ${km} km`,
  hybridStats: (km, min) => `Hybrid · ${km} km · ${min} min`,
  trailInserted: (name) => `${name} inserito`,
  demoRouting:
    "Le route usano geometria demo — routing live non configurato.",
  unverifiedRouting:
    "Chiave routing impostata — live non ancora verificato. In errore, geometria demo.",
  pinMyPos: "La mia posizione",
  pinDeepLink: "Luogo deep-link",
  pinHere: "Qui",
  pinStartMap: "Partenza (mappa)",
  pinEndMap: "Arrivo (mappa)",
  pinTourStart: "Partenza uscita",
  pinTourEnd: "Arrivo uscita",
  pinTourPlace: "Luogo uscita",
  plannedRoute: "Route pianificata",
  fromHereLabel: (name) => `${name} (da qui)`,
  ideaLabel: (name) => `${name} (idea)`,
  planLabel: (name) => `${name} (piano)`,
  surfaceAsphalt: "Asfalto",
  surfaceSchotter: "Ghiaia",
  surfaceNatur: "Sterrato",
  surfaceGras: "Erba",
  surfaceHolz: "Legno",
  hwyPath: "Sentiero",
  hwyTrack: "Pista forestale",
  hwyCycle: "Pista ciclabile",
  hwyBridle: "Ippovia",
  hwyFoot: "Percorso pedonale",
  tourIdea: "Idea di uscita · la geometria si routea in pianificazione",
  away: (km) => `~${km} km · `,
  loopRound: "⟲ Anello",
  pointAb: "A→B",
  because: "Perché: ",
  details: "Dettagli",
  pageLink: "Pagina",
  unsaveAria: "Rimuovi salvato",
  save: "Salva",
  saved: "Salvato",
  startInApp: "Parti nell’app",
  variantPlanned: "Come previsto",
  variantFlatter: "Meno dislivello",
  variantUnpaved: "Più sterrato",
  variantValhallaOnly: "Varianti solo con Valhalla live",
  openNativeApp: "Apri nell’app",
  placeKind: (kind) =>
    kind === "cafe"
      ? "Caffè"
      : kind === "water"
        ? "Acqua"
        : kind === "shop"
          ? "Negozio"
          : kind === "repair"
            ? "Officina"
            : kind === "viewpoint"
              ? "Vista"
              : "Luogo",
  overview: "Panoramica",
  popular: "Popolare",
  photos: "Foto",
  elevation: "Dislivello",
  match: "Match",
  pinIdea: "Idea",
  pinOnlyHint:
    "Solo pin — nessuna traccia salvata. Routing live, Pianifica o GPX per una linea vera.",
  whySuggestion: "Perché questo suggerimento?",
  rangeSpan: (lo, hi) => `Autonomia ${lo}–${hi} km`,
  rangeTight: " — stretta per questa uscita",
  rangeOk: " — ci sta",
  rangeTour: (km, conf) => `Uscita ${km} km · confidenza ${conf}`,
  rangeProTitle: "Previsione autonomia · Pro",
  rangeProBody: "Mostra la forchetta contro la domanda dell’uscita.",
  unlockPro: "Sblocca Pro sotto Profilo →",
  offlineMapsHint: "Carichi le mappe offline nell’app. Segna qui via ",
  offlineMapsAfter: ".",
  savedLink: "Salvato",
  heatCold: (k) =>
    `Pochi dati heatmap (k≥${k}) — i tuoi ride e più rider riempiono la mappa.`,
  heatConsent: (k) =>
    `Attiva le tue tracce sotto Privacy. I segmenti heatmap (k≥${k}) restano visibili quando ci sono abbastanza rider.`,
  heatConsentBefore: "Attiva le tue tracce sotto ",
  heatConsentAfter: (k) =>
    `. I segmenti heatmap (k≥${k}) restano visibili quando ci sono abbastanza rider.`,
  privacyLink: "Privacy",
  heatOwn: "Tuo ride",
  heatSection: "Segmento",
  riders: (n, pct) => `${n} rider · intensità ${pct} %`,
  noSegments: "Nessun segmento visibile in questa vista.",
  heading: (deg) => `Direzione ${deg}°`,
  demoPhotos: "Foto di esempio — le foto live chiedono Mapillary (ops).",
  noPhotos: "Nessuna foto trail qui vicino.",
  elevMissing:
    "Profilo altimetrico non ancora disponibile — niente stima di riempimento.",
  publicTour: "Pagina uscita pubblica →",
  openPlanner: "Apri nel planner →",
  gapElev: (km) => ` · ${km} km senza dati di quota`,
  surfaceTitle: "Superficie",
  difficultyTitle: "Difficoltà",
  estimate: "Stima",
  elevEst: (hm) => `Stima quota ~${hm} hm`,
  elevProfile: (hm) => `Profilo quota ~${hm} hm`,
  fromHereTitle: "Route da qui",
  fromHereHint:
    "Routing live da GPS o centro mappa — salva e pedala nell’app.",
  needCenter: "Luogo o centro mappa mancante",
  stretch: "Tratta",
  compute: "Calcola",
  inApp: "Nell’app",
  noHonestEngine:
    "Nessun anello vero — l’engine ha dato A→B (partenza≠arrivo). Riprova o usa i seed.",
  savedEngine: (line) => `${line} · salvato`,
  routingFail: "Routing fallito",
  roundKm: (km) => `Anello ${km} km`,
  tourKm: (km) => `Uscita ${km} km`,
  packsTitle: "Regioni offline",
  packsLead:
    "Solo i pack costruiti si scaricano. L’attivazione (routing + tile) gira nell’app Android/iOS.",
  packsCatalog: "Catalogo…",
  packsEmpty: "Nessun pack in catalogo — esegui un build regione in locale.",
  packsUnreachable: "Catalogo offline non raggiungibile.",
  packsNone: "Nessun pack disponibile.",
  packsNotBuilt: "Non ancora costruito",
  packsDownload: (name) => `Scarica pack offline ${name}`,
  packsStarted: (name) =>
    `${name}: download avviato. Attivazione solo nell’app mobile (foglio offline).`,
  packsFail: "Download fallito",
  packsLoad: "Scarica",
  packsStub: "Stub",
  back: "Indietro",
  tourIdeaLive:
    "Idea di uscita — calcola la linea live quando pianifichi o parti",
};

const BY_LANG: Record<ChromeLang, DiscoverUi> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
};

export function discoverUi(lang: ChromeLang): DiscoverUi {
  return BY_LANG[lang];
}

const STATUS_KEY: Record<string, keyof DiscoverUi> = {
  [DISCOVER_STATUS_DE.locDeep]: "locDeep",
  [DISCOVER_STATUS_DE.locWaitOrTap]: "locWaitOrTap",
  [DISCOVER_STATUS_DE.locGps]: "locGps",
  [DISCOVER_STATUS_DE.locDeepGps]: "locDeepGps",
  [DISCOVER_STATUS_DE.locNoneDemo]: "locNoneDemo",
  [DISCOVER_STATUS_DE.locDeniedDemo]: "locDeniedDemo",
  [DISCOVER_STATUS_DE.locNoneAddr]: "locNoneAddr",
  [DISCOVER_STATUS_DE.locDeniedAddr]: "locDeniedAddr",
  [DISCOVER_STATUS_DE.locGpsCentered]: "locGpsCentered",
  [DISCOVER_STATUS_DE.locWait]: "locWait",
  [DISCOVER_STATUS_DE.calcSlow]: "calcSlow",
  [DISCOVER_STATUS_DE.noQuick]: "noQuick",
  [DISCOVER_STATUS_DE.rateLimit]: "rateLimit",
  [DISCOVER_STATUS_DE.quickFail]: "quickFail",
  [DISCOVER_STATUS_DE.gpxBad]: "gpxBad",
  [DISCOVER_STATUS_DE.geocodeFail]: "geocodeFail",
  [DISCOVER_STATUS_DE.savedLoaded]: "savedLoaded",
  [DISCOVER_STATUS_DE.needStartEnd]: "needStartEnd",
  [DISCOVER_STATUS_DE.pinOnly]: "pinOnly",
  [DISCOVER_STATUS_DE.hybridFail]: "hybridFail",
  [DISCOVER_STATUS_DE.trailFail]: "trailFail",
  [DISCOVER_STATUS_DE.searchStart]: "searchStart",
  [DISCOVER_STATUS_DE.changePlace]: "changePlace",
  [DISCOVER_STATUS_DE.heatmapOffline]: "heatmapOffline",
  [DISCOVER_STATUS_DE.packsEmpty]: "packsEmpty",
  [DISCOVER_STATUS_DE.packsUnreachable]: "packsUnreachable",
  [DEMO_ROUTING_NOTICE]: "demoRouting",
  [UNVERIFIED_ROUTING_NOTICE]: "unverifiedRouting",
};

const PIN_KEY: Record<string, keyof DiscoverUi> = {
  [DISCOVER_PIN_DE.myPos]: "pinMyPos",
  [DISCOVER_PIN_DE.deepLink]: "pinDeepLink",
  [DISCOVER_PIN_DE.here]: "pinHere",
  [DISCOVER_PIN_DE.startMap]: "pinStartMap",
  [DISCOVER_PIN_DE.endMap]: "pinEndMap",
  [DISCOVER_PIN_DE.tourStart]: "pinTourStart",
  [DISCOVER_PIN_DE.tourEnd]: "pinTourEnd",
  [DISCOVER_PIN_DE.tourPlace]: "pinTourPlace",
  [DISCOVER_PIN_DE.planned]: "plannedRoute",
};

/** Map stored DE status to chrome. Unknown (engine lines, tour names) stay. */
export function discoverStatus(
  raw: string | null | undefined,
  lang: ChromeLang,
): string {
  if (!raw) return "";
  const d = discoverUi(lang);
  const key = STATUS_KEY[raw];
  if (key) {
    const v = d[key];
    return typeof v === "string" ? v : raw;
  }
  const demoLoops = raw.match(/^Demo-Region: (.+) · 60 min Rundkurse$/);
  if (demoLoops) return d.demoRegionLoops(demoLoops[1]);
  const demo = raw.match(/^Demo-Region: (.+)$/);
  if (demo) return d.demoRegion(demo[1]);
  const hits = raw.match(/^Keine Treffer für [„"](.+)[“"]$/);
  if (hits) return d.noHits(hits[1]);
  const geoHttp = raw.match(/^Adresssuche fehlgeschlagen \((\d+)\)$/);
  if (geoHttp) return d.geocodeFailHttp(geoHttp[1]);
  const planEnd = raw.match(
    /^In Planen: (.+) — Ziel setzen, dann Route berechnen \(kein Track\)\.$/,
  );
  if (planEnd) return d.inPlanNeedEnd(planEnd[1]);
  const plan = raw.match(/^In Planen: (.+) — Start\/Ziel editierbar$/);
  if (plan) return d.inPlanNamed(plan[1]);
  const start = raw.match(/^Start: (.+)$/);
  if (start) return d.waypointStart(start[1]);
  const end = raw.match(/^Ziel: (.+)$/);
  if (end) return d.waypointEnd(end[1]);
  const gpx = raw.match(/^GPX importiert: (.+) · (.+) km$/);
  if (gpx) return d.gpxImported(gpx[1], gpx[2]);
  const hybrid = raw.match(/^Hybrid · (.+) km · (.+) min$/);
  if (hybrid) return d.hybridStats(hybrid[1], hybrid[2]);
  const inserted = raw.match(/^(.+) eingefügt$/);
  if (inserted) return d.trailInserted(inserted[1]);
  return raw;
}

export function discoverPinLabel(
  raw: string | null | undefined,
  lang: ChromeLang,
): string {
  if (!raw) return "";
  const d = discoverUi(lang);
  const key = PIN_KEY[raw];
  if (key) {
    const v = d[key];
    return typeof v === "string" ? v : raw;
  }
  return discoverDraftLabel(raw, lang);
}

export function discoverDraftLabel(raw: string, lang: ChromeLang): string {
  const d = discoverUi(lang);
  if (raw.endsWith(" (von hier)")) return d.fromHereLabel(raw.slice(0, -11));
  if (raw.endsWith(" (Idee)")) return d.ideaLabel(raw.slice(0, -7));
  if (raw.endsWith(" (Plan)")) return d.planLabel(raw.slice(0, -7));
  if (raw === DISCOVER_PIN_DE.planned) return d.plannedRoute;
  return raw;
}

const SURFACE_DE: Record<string, keyof DiscoverUi> = {
  Asphalt: "surfaceAsphalt",
  Schotter: "surfaceSchotter",
  Naturweg: "surfaceNatur",
  Gras: "surfaceGras",
  Holz: "surfaceHolz",
};

const HWY_DE: Record<string, keyof DiscoverUi> = {
  Pfad: "hwyPath",
  Forstweg: "hwyTrack",
  Radweg: "hwyCycle",
  Reitweg: "hwyBridle",
  Fußweg: "hwyFoot",
};

export function discoverMappedDe(
  raw: string | undefined,
  table: Record<string, keyof DiscoverUi>,
  lang: ChromeLang,
): string | undefined {
  if (!raw) return undefined;
  const key = table[raw];
  if (!key) return raw;
  const v = discoverUi(lang)[key];
  return typeof v === "string" ? v : raw;
}

export function discoverSurfaceLabel(
  raw: string | undefined,
  lang: ChromeLang,
): string | undefined {
  return discoverMappedDe(raw, SURFACE_DE, lang);
}

export function discoverHighwayLabel(
  raw: string | undefined,
  lang: ChromeLang,
): string | undefined {
  return discoverMappedDe(raw, HWY_DE, lang);
}

/** Visibility chip labels already live on discoverCopy. */
export function discoverVisLabel(
  id: "all_mine" | "private" | "shared",
  lang: ChromeLang,
): string {
  const f = discoverCopy(lang);
  if (id === "private") return f.visPrivate;
  if (id === "shared") return f.visPublic;
  return f.visAll;
}
