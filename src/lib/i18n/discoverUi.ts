import {
  DEMO_ROUTING_NOTICE,
  UNVERIFIED_ROUTING_NOTICE,
} from "@/lib/routing/routingStatus";
import {
  HONESTY_CYCLEWAY_DE,
  HONESTY_FARM_MID_DE,
  HONESTY_FARM_TAIL_DE,
  HONESTY_ROAD_DE,
} from "@/lib/routing/graphhopperHints";
import type { ChromeLang } from "./chromeLang";
import { discoverCopy } from "./discoverCopy";
import { osmSurfaceLabel } from "@/lib/routing/osmSurfaceLabel";

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
  heatmapOffline: "Wo viele fahren: offline",
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
  honestyRoad: string;
  honestyCycleway: string;
  honestyFarmTail: string;
  honestyFarmMid: string;
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
  swapStartEnd: string;
  addStop: string;
  closeLoop: string;
  viaN: (n: number) => string;
  nextPickStart: string;
  nextPickEnd: string;
  nextPickVia: string;
  loopClosed: string;
  computingRoute: string;
  computeRoute: string;
  statLength: string;
  statDuration: string;
  statAscent: string;
  statSurface: string;
  elevTitle: string;
  onMapPlace: string;
  viaAddr: string;
  routingAdapts: string;
  recently: string;
  backToGps: string;
  mapArea: string;
  tapLineVia: string;
  lastDestChip: (name: string) => string;
  lastDestChipGeneric: string;
  lastDestUndo: string;
  planUndo: string;
  planRedo: string;
  planLineCoach: string;
  planLineCoachOk: string;
  planMapSteep: string;
  planMapUnknown: string;
  planStopSetHint: string;
  placeOnRoute: string;
  lastDestApplied: string;
  endSetComputing: string;
  setEndCta: string;
  closeLoopHint: string;
  browserPlanOnly: string;
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
  aroundYouCta: string;
  aroundYouAnother: string;
  aroundYouLoop: string;
  aroundYouHint: string;
  aroundYouBusy: string;
  aroundYouFail: string;
  aroundYouSport: string;
  aroundYouNeedGps: string;
  aroundYouOffline: string;
  aroundYouUncertain: string;
  aroundYouUncertainShort: string;
  aroundYouStats: (km: string, min: number) => string;
  aroundYouReasonDuration: (got: number, want: number) => string;
  aroundYouReasonSurface: (surface: string) => string;
  aroundYouReasonOsm: string;
  previewEngine: (line: string) => string;
  savePreview: string;
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
  mappeShowAll: string;
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
  offlineMapsChip: string;
  savedLink: string;
  heatCold: (k: number) => string;
  heatConsent: (k: number) => string;
  heatConsentBefore: string;
  heatConsentAfter: (k: number) => string;
  privacyLink: string;
  heatOwn: string;
  heatSection: string;
  heatCell: string;
  heatSegments: (n: number) => string;
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
  osmOptional: "OSM · ~60-Min-Rundkurse — Rad optional",
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
    "Vorschläge und Zeit gerade gedrosselt — kurz warten oder sparsam planen.",
  honestyRoad:
    "Route folgt überwiegend Straßen — Trail auf der Karte antippen und anhängen.",
  honestyCycleway:
    "Wenig eigener Radweg — Live-Strecke oft auf der Fahrbahn.",
  honestyFarmTail:
    "Kein Weg bis zum Pin — Ziel liegt an der Straße.",
  honestyFarmMid:
    "Teile der Route folgen Feldwegen — Ziel näher an eine Straße setzen.",
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
  startMyPos: "Mein Standort",
  swapStartEnd: "Start und Ziel tauschen",
  addStop: "Zwischenstopp",
  closeLoop: "Zurück zum Start",
  viaN: (n) => `Via ${n}`,
  nextPickStart: "Nächster Punkt: Start — Karte tippen oder Adresse",
  nextPickEnd: "Nächster Punkt: Ziel — Karte tippen oder Adresse",
  nextPickVia: "Jetzt Karte tippen — Zwischenstopp setzen.",
  loopClosed: "Rundkurs",
  computingRoute: "Route passt sich an…",
  computeRoute: "Route berechnen",
  statLength: "Länge",
  statDuration: "Dauer",
  statAscent: "Aufstieg",
  statSurface: "Untergrund",
  elevTitle: "Höhenprofil",
  onMapPlace: "Punkt auf der Karte",
  viaAddr: "Zwischenstopp",
  routingAdapts: "Route passt sich an…",
  recently: "Zuletzt",
  backToGps: "Zurück zu GPS",
  mapArea: "Kartenausschnitt",
  tapLineVia:
    "Linie oder die Punkte darauf ziehen: Zwischenstopp. Tipp daneben zieht durch. Höhenprofil tippen: Stopp. Alt-Klick oder Halten: neues Ziel.",
  lastDestChip: (name) => `Letztes Ziel: ${name}`,
  lastDestChipGeneric: "Letztes Ziel wiederholen",
  lastDestUndo: "Rückgängig",
  planUndo: "Rückgängig",
  planRedo: "Wiederholen",
  planLineCoach: "Linie oder die Scheiben ziehen — Zwischenstopp. Halten oder Alt-Klick: neues Ziel.",
  planLineCoachOk: "Verstanden",
  planMapSteep: "Steil",
  planMapUnknown: "Unbekannt",
  planStopSetHint: "Stopp gesetzt. Punkt ziehen: Strecke biegen.",
  placeOnRoute: "In die Route",
  lastDestApplied: "Letztes Ziel übernommen.",
  endSetComputing: "Ziel gesetzt — Route wird berechnet",
  setEndCta: "Ziel setzen",
  closeLoopHint: "Runde: Ziel wird der Start.",
  browserPlanOnly: "Die App führt. Hier planst du nur.",
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
    `Mit ${bike} nicht auf diesen Trail. Rad am Stand wechseln — nicht heimlich als MTB routen.`,
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
  aroundYouCta: "Hier rundherum",
  aroundYouAnother: "Andere Runde",
  aroundYouLoop: "Rundkurs um dich · OSM-Wege",
  aroundYouHint:
    "Rundkurs auf OSM-Wegen — kein Trailforks-Trail",
  aroundYouBusy: "Runde wird gelegt…",
  aroundYouFail:
    "Keine geschlossene Runde hier — Ort oder Dauer ändern.",
  aroundYouSport:
    "Rundkurs-Generator für Gravel, Rennrad, City und E-Trekking.",
  aroundYouNeedGps: "Standort setzen — dann Runde um dich.",
  aroundYouOffline: "Rundkurs-Generator braucht Netz.",
  aroundYouUncertain: "Länge ungefähr — etwa ±12 %",
  aroundYouUncertainShort: "±12 %",
  aroundYouStats: (km, min) => `${km} km · ${min} min`,
  aroundYouReasonDuration: (got, want) => `Dauer ${got} min · Ziel ${want} min`,
  aroundYouReasonSurface: (surface) => `Überwiegend ${surface}`,
  aroundYouReasonOsm: "OSM-Wege — kein Trailforks-Trail",
  previewEngine: (line) => `${line} · Vorschau`,
  savePreview: "Merken",
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
  mappeShowAll: "Alle zeigen",
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
    `In Planen: ${name} — Ziel auf der Karte oder als Adresse setzen (kein Track).`,
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
  variantUnpaved: "Mehr Schotter",
  variantValhallaOnly:
    "Weniger hm und mehr Schotter nur mit Live-Strecke — du siehst die geplante Linie.",
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
  offlineMapsHint: "Offline-Routing lädst du in der App. Hier vormerken geht über ",
  offlineMapsAfter: ".",
  offlineMapsChip: "Routing",
  savedLink: "Gespeichert",
  heatCold: (k) =>
    `Noch wenig, wo viele fahren (erst ab ${k}) — eigene Fahrten und mehr Fahrer füllen die Karte.`,
  heatConsent: (k) =>
    `Eigene Beiträge unter Privatsphäre aktivieren. Abschnitte (erst ab ${k}) sind sichtbar, sobald genug Fahrer da sind.`,
  heatConsentBefore: "Eigene Beiträge unter ",
  heatConsentAfter: (k) =>
    ` aktivieren. Abschnitte (erst ab ${k}) sind sichtbar, sobald genug Fahrer da sind.`,
  privacyLink: "Privatsphäre",
  heatOwn: "Eigene Fahrt",
  heatSection: "Abschnitt",
  heatCell: "Wo viele fahren",
  heatSegments: (n) => `${n} Abschnitte, wo viele fahren`,
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
    "Live-Routing vom GPS oder der Kartenmitte — Vorschau, merken oder in der App fahren.",
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
  packsTitle: "Routing-Packs",
  packsLead:
    "Nur gebaute Packs sind ladbar. Der Routing-Graph wird in der App aktiviert — nicht im Browser. Die Übersichtskarte ist extra und groß.",
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
    "Suggestions and times are limited — wait a bit or plan sparingly.",
  honestyRoad:
    "Route mostly follows roads — tap a trail on the map and attach it.",
  honestyCycleway:
    "Little dedicated bike path — the live route often stays on the road.",
  honestyFarmTail:
    "No path all the way to the pin — destination is on the street.",
  honestyFarmMid:
    "Parts of the route follow farm tracks — set the destination closer to a street.",
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
  startMyPos: "My location",
  swapStartEnd: "Swap start and destination",
  addStop: "Add stop",
  closeLoop: "Return to start",
  viaN: (n) => `Via ${n}`,
  nextPickStart: "Next: start — tap the map or type an address",
  nextPickEnd: "Next: destination — tap the map or type an address",
  nextPickVia: "Tap the map now to place a stop.",
  loopClosed: "Loop",
  computingRoute: "Updating route…",
  computeRoute: "Compute route",
  statLength: "Length",
  statDuration: "Duration",
  statAscent: "Ascent",
  statSurface: "Surface",
  elevTitle: "Elevation",
  onMapPlace: "Point on the map",
  viaAddr: "Stop",
  routingAdapts: "Updating route…",
  recently: "Recent",
  backToGps: "Back to GPS",
  mapArea: "Map area",
  tapLineVia:
    "Tap or drag the line or its discs for a stop. A tap beside it pulls the route through. Tap the elevation profile: stop. Alt-click or hold: new finish.",
  lastDestChip: (name) => `Last destination: ${name}`,
  lastDestChipGeneric: "Repeat last destination",
  lastDestUndo: "Undo",
  planUndo: "Undo",
  planRedo: "Redo",
  planLineCoach: "Drag the line or its discs for a stop. Hold or Alt-click: new destination.",
  planLineCoachOk: "Got it",
  planMapSteep: "Steep",
  planMapUnknown: "Unknown",
  planStopSetHint: "Stop added. Drag the disc to reshape.",
  placeOnRoute: "Include on route",
  lastDestApplied: "Last destination applied.",
  endSetComputing: "End set — computing the route",
  setEndCta: "Set destination",
  closeLoopHint: "Loop: destination becomes start.",
  browserPlanOnly: "The app navigates. This page only plans.",
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
    `Not with ${bike} on this trail. Switch bikes at the stand — don't secretly MTB-route.`,
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
  aroundYouCta: "Around you",
  aroundYouAnother: "Another loop",
  aroundYouLoop: "Loop around you · OSM ways",
  aroundYouHint: "Loop on OSM ways — not a Trailforks trail",
  aroundYouBusy: "Laying a loop…",
  aroundYouFail: "No closed loop here — change place or duration.",
  aroundYouSport:
    "Loop generator for gravel, road, city and e-trekking.",
  aroundYouNeedGps: "Set a location — then a loop around you.",
  aroundYouOffline: "Loop generator needs a network.",
  aroundYouUncertain: "Length is approximate — about ±12%",
  aroundYouUncertainShort: "±12%",
  aroundYouStats: (km, min) => `${km} km · ${min} min`,
  aroundYouReasonDuration: (got, want) =>
    `Duration ${got} min · target ${want} min`,
  aroundYouReasonSurface: (surface) => `Mostly ${surface}`,
  aroundYouReasonOsm: "OSM ways — not a Trailforks trail",
  previewEngine: (line) => `${line} · preview`,
  savePreview: "Save",
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
  mappeShowAll: "Show all",
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
  heatmapOffline: "Where many ride: offline",
  demoRegion: (name) => `Demo region: ${name}`,
  demoRegionLoops: (name) => `Demo region: ${name} · 60 min loops`,
  noHits: (q) => `No hits for “${q}”`,
  geocodeFailHttp: (status) => `Address search failed (${status})`,
  inPlanNamed: (name) => `In Plan: ${name} — start/finish editable`,
  inPlanNeedEnd: (name) =>
    `In Plan: ${name} — set finish on the map or as an address (no track).`,
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
  variantValhallaOnly:
    "Flatter and more gravel need a live route — this is the planned line.",
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
  offlineMapsHint: "You load offline routing in the app. Bookmark here via ",
  offlineMapsAfter: ".",
  offlineMapsChip: "Routing",
  savedLink: "Saved",
  heatCold: (k) =>
    `Little of where many ride yet (from ${k} up) — your rides and more riders fill the map.`,
  heatConsent: (k) =>
    `Turn on your traces under Privacy. Sections (from ${k} up) still show once enough riders are there.`,
  heatConsentBefore: "Turn on your traces under ",
  heatConsentAfter: (k) =>
    `. Sections (from ${k} up) still show once enough riders are there.`,
  privacyLink: "Privacy",
  heatOwn: "Own ride",
  heatSection: "Segment",
  heatCell: "Where many ride",
  heatSegments: (n) => `${n} stretches where many ride`,
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
    "Live routing from GPS or map centre — preview, then save, or ride in the app.",
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
  packsTitle: "Routing packs",
  packsLead:
    "Only built packs can download. You activate the routing graph in the app — not in the browser. The overview map is a separate, large download.",
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
    "Suggestions et durées limitées — attends un peu ou planifie avec parcimonie.",
  honestyRoad:
    "L’itinéraire suit surtout la route — touche un sentier sur la carte et accroche-le.",
  honestyCycleway:
    "Peu de piste cyclable — la route live reste souvent sur la chaussée.",
  honestyFarmTail:
    "Pas de chemin jusqu’à l’épingle — l’arrivée est sur la route.",
  honestyFarmMid:
    "Des parties de l’itinéraire suivent des chemins agricoles — place l’arrivée plus près d’une route.",
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
  startMyPos: "Ma position",
  swapStartEnd: "Inverser départ et arrivée",
  addStop: "Arrêt",
  closeLoop: "Retour au départ",
  viaN: (n) => `Via ${n}`,
  nextPickStart: "Suivant : départ — tape la carte ou une adresse",
  nextPickEnd: "Suivant : arrivée — tape la carte ou une adresse",
  nextPickVia: "Tape la carte maintenant pour l’arrêt.",
  loopClosed: "Boucle",
  computingRoute: "L’itinéraire s’adapte…",
  computeRoute: "Calculer la route",
  statLength: "Distance",
  statDuration: "Durée",
  statAscent: "Dénivelé",
  statSurface: "Revêtement",
  elevTitle: "Profil altimétrique",
  onMapPlace: "Point sur la carte",
  viaAddr: "Arrêt",
  routingAdapts: "L’itinéraire s’adapte…",
  recently: "Récents",
  backToGps: "Retour au GPS",
  mapArea: "Zone de la carte",
  tapLineVia:
    "Touche ou glisse la ligne ou ses points pour un stop. Un tap à côté tire l’itinéraire. Tape le profil altimétrique : arrêt. Alt-clic ou maintien : nouvelle arrivée.",
  lastDestChip: (name) => `Dernière arrivée : ${name}`,
  lastDestChipGeneric: "Répéter la dernière arrivée",
  lastDestUndo: "Annuler",
  planUndo: "Annuler",
  planRedo: "Rétablir",
  planLineCoach: "Glisse la ligne ou les disques pour un arrêt. Maintiens ou Alt-clic : nouvelle arrivée.",
  planLineCoachOk: "Compris",
  planMapSteep: "Raide",
  planMapUnknown: "Inconnu",
  planStopSetHint: "Arrêt ajouté. Glisse le point pour ajuster.",
  placeOnRoute: "Inclure dans l’itinéraire",
  lastDestApplied: "Dernière arrivée reprise.",
  endSetComputing: "Arrivée posée — calcul de la route",
  setEndCta: "Indique l’arrivée",
  closeLoopHint: "Boucle : l’arrivée redevient le départ.",
  browserPlanOnly: "L’app guide. Ici tu ne fais que planifier.",
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
    `Pas avec un ${bike} sur ce trail. Change de vélo au stand — pas de routage VTT caché.`,
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
  aroundYouCta: "Autour de toi",
  aroundYouAnother: "Autre boucle",
  aroundYouLoop: "Boucle autour de toi · chemins OSM",
  aroundYouHint:
    "Boucle sur chemins OSM — pas un sentier Trailforks",
  aroundYouBusy: "Boucle en cours…",
  aroundYouFail:
    "Pas de boucle fermée ici — change de lieu ou de durée.",
  aroundYouSport:
    "Générateur de boucle pour gravel, route, ville et e-trekking.",
  aroundYouNeedGps: "Pose un lieu — puis une boucle autour de toi.",
  aroundYouOffline: "Le générateur de boucle a besoin du réseau.",
  aroundYouUncertain: "Longueur approx. — environ ±12 %",
  aroundYouUncertainShort: "±12 %",
  aroundYouStats: (km, min) => `${km} km · ${min} min`,
  aroundYouReasonDuration: (got, want) => `Durée ${got} min · visée ${want} min`,
  aroundYouReasonSurface: (surface) => `Surtout ${surface}`,
  aroundYouReasonOsm: "Chemins OSM — pas un sentier Trailforks",
  previewEngine: (line) => `${line} · aperçu`,
  savePreview: "Garder",
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
  mappeShowAll: "Tout afficher",
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
  heatmapOffline: "Là où on roule : hors ligne",
  demoRegion: (name) => `Région démo : ${name}`,
  demoRegionLoops: (name) => `Région démo : ${name} · boucles 60 min`,
  noHits: (q) => `Aucun résultat pour « ${q} »`,
  geocodeFailHttp: (status) => `Recherche d’adresse échouée (${status})`,
  inPlanNamed: (name) => `Dans Planifier : ${name} — départ/arrivée éditables`,
  inPlanNeedEnd: (name) =>
    `Dans Planifier : ${name} — pose l’arrivée sur la carte ou en adresse (pas de trace).`,
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
  variantValhallaOnly:
    "Moins de dénivelé et plus de graviers uniquement avec la route live.",
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
  offlineMapsHint: "Tu charges le routage hors ligne dans l’app. Marquer ici via ",
  offlineMapsAfter: ".",
  offlineMapsChip: "Routage",
  savedLink: "Enregistré",
  heatCold: (k) =>
    `Encore peu, là où on roule (dès ${k}) — tes sorties et plus de riders remplissent la carte.`,
  heatConsent: (k) =>
    `Active tes traces sous Confidentialité. Les sections (dès ${k}) restent visibles dès qu’il y a assez de riders.`,
  heatConsentBefore: "Active tes traces sous ",
  heatConsentAfter: (k) =>
    `. Les sections (dès ${k}) restent visibles dès qu’il y a assez de riders.`,
  privacyLink: "Confidentialité",
  heatOwn: "Ton ride",
  heatSection: "Segment",
  heatCell: "Là où on roule",
  heatSegments: (n) => `${n} tronçons là où on roule`,
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
    "Routing live depuis le GPS ou le centre carte — aperçu, puis garder, ou rouler dans l’app.",
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
  packsTitle: "Packs de routage",
  packsLead:
    "Seuls les packs construits se téléchargent. Le graphe de routage s’active dans l’app, pas dans le navigateur. La carte d’ensemble est un téléchargement à part.",
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
    "Suggerimenti e tempi limitati — aspetta un po’ o pianifica con parsimonia.",
  honestyRoad:
    "Il percorso segue soprattutto la strada — tocca un trail sulla mappa e aggancialo.",
  honestyCycleway:
    "Poco percorso ciclabile — la route live resta spesso sulla carreggiata.",
  honestyFarmTail:
    "Nessun sentiero fino al pin — l’arrivo è sulla strada.",
  honestyFarmMid:
    "Parti del percorso seguono strade agricole — metti l’arrivo più vicino a una strada.",
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
  startMyPos: "La mia posizione",
  swapStartEnd: "Inverti partenza e arrivo",
  addStop: "Fermata",
  closeLoop: "Torna alla partenza",
  viaN: (n) => `Via ${n}`,
  nextPickStart: "Prossimo: partenza — tocca la mappa o un indirizzo",
  nextPickEnd: "Prossimo: arrivo — tocca la mappa o un indirizzo",
  nextPickVia: "Tocca la mappa ora per la fermata.",
  tapLineVia:
    "Tocca o trascina la linea o i dischi per una sosta. Un tap accanto tira il percorso. Tocca il profilo altimetrico: sosta. Alt-clic o tieni premuto: nuovo arrivo.",
  loopClosed: "Anello",
  computingRoute: "Il percorso si adatta…",
  computeRoute: "Calcola route",
  statLength: "Lunghezza",
  statDuration: "Durata",
  statAscent: "Salita",
  statSurface: "Superficie",
  elevTitle: "Profilo altimetrico",
  onMapPlace: "Punto sulla mappa",
  viaAddr: "Fermata",
  routingAdapts: "Il percorso si adatta…",
  recently: "Recenti",
  backToGps: "Torna al GPS",
  mapArea: "Area della mappa",
  lastDestChip: (name) => `Ultima destinazione: ${name}`,
  lastDestChipGeneric: "Ripeti l’ultima destinazione",
  lastDestUndo: "Annulla",
  planUndo: "Annulla",
  planRedo: "Ripeti",
  planLineCoach: "Trascina la linea o i dischi per una sosta. Tieni o Alt-clic: nuovo arrivo.",
  planLineCoachOk: "Capito",
  planMapSteep: "Ripido",
  planMapUnknown: "Sconosciuto",
  planStopSetHint: "Fermata aggiunta. Trascina il punto per adattare.",
  placeOnRoute: "Includi nel percorso",
  lastDestApplied: "Ultima destinazione applicata.",
  endSetComputing: "Arrivo impostato — calcolo del percorso",
  setEndCta: "Imposta l’arrivo",
  closeLoopHint: "Anello: l’arrivo torna la partenza.",
  browserPlanOnly: "L’app guida. Qui pianifichi soltanto.",
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
    `Non con ${bike} su questo trail. Cambia bici allo stand — niente routing MTB nascosto.`,
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
  aroundYouCta: "Intorno a te",
  aroundYouAnother: "Altro anello",
  aroundYouLoop: "Anello intorno a te · vie OSM",
  aroundYouHint: "Anello su vie OSM — non un trail Trailforks",
  aroundYouBusy: "Anello in corso…",
  aroundYouFail:
    "Nessun anello chiuso qui — cambia luogo o durata.",
  aroundYouSport:
    "Generatore di anelli per gravel, strada, città ed e-trekking.",
  aroundYouNeedGps: "Imposta un luogo — poi un anello intorno a te.",
  aroundYouOffline: "Il generatore di anelli serve la rete.",
  aroundYouUncertain: "Lunghezza approssimativa — circa ±12 %",
  aroundYouUncertainShort: "±12 %",
  aroundYouStats: (km, min) => `${km} km · ${min} min`,
  aroundYouReasonDuration: (got, want) => `Durata ${got} min · obiettivo ${want} min`,
  aroundYouReasonSurface: (surface) => `Prevalentemente ${surface}`,
  aroundYouReasonOsm: "Vie OSM — non un trail Trailforks",
  previewEngine: (line) => `${line} · anteprima`,
  savePreview: "Salva",
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
  mappeShowAll: "Mostra tutti",
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
  heatmapOffline: "Dove si gira: offline",
  demoRegion: (name) => `Regione demo: ${name}`,
  demoRegionLoops: (name) => `Regione demo: ${name} · anelli 60 min`,
  noHits: (q) => `Nessun risultato per «${q}»`,
  geocodeFailHttp: (status) => `Ricerca indirizzo fallita (${status})`,
  inPlanNamed: (name) => `In Pianifica: ${name} — partenza/arrivo modificabili`,
  inPlanNeedEnd: (name) =>
    `In Pianifica: ${name} — imposta l’arrivo sulla mappa o come indirizzo (niente traccia).`,
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
  variantValhallaOnly:
    "Meno dislivello e più ghiaia solo con la route live.",
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
  offlineMapsHint: "Carichi il routing offline nell’app. Segna qui via ",
  offlineMapsAfter: ".",
  offlineMapsChip: "Routing",
  savedLink: "Salvato",
  heatCold: (k) =>
    `Ancora poco, dove si gira (da ${k} in su) — le tue uscite e più rider riempiono la mappa.`,
  heatConsent: (k) =>
    `Attiva le tue tracce sotto Privacy. Le sezioni (da ${k} in su) restano visibili quando ci sono abbastanza rider.`,
  heatConsentBefore: "Attiva le tue tracce sotto ",
  heatConsentAfter: (k) =>
    `. Le sezioni (da ${k} in su) restano visibili quando ci sono abbastanza rider.`,
  privacyLink: "Privacy",
  heatOwn: "Tuo ride",
  heatSection: "Segmento",
  heatCell: "Dove si gira",
  heatSegments: (n) => `${n} tratti dove si gira`,
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
    "Routing live da GPS o centro mappa — anteprima, poi salva, o pedala nell’app.",
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
  packsTitle: "Pack di routing",
  packsLead:
    "Si scaricano solo i pack già costruiti. Il grafo di routing si attiva nell’app, non nel browser. La mappa d’insieme è un download a parte.",
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

const NL: DiscoverUi = {
  ...EN,
  osmOptional: "OSM · lussen ~60 min — fiets optioneel",
  hereBtn: "Hier",
  placeEllipsis: "Plaats…",
  heatmapPrefix: "Populair: ",
  heatmapOwn: " · Je sporen onder Privacy",
  time: "Tijd",
  nearbyTitle: (profile) => `Bij jou · ${profile}`,
  nearbyLiveHint:
    "Live-route vanaf GPS of kaartmidden — MTB, Gravel, Weg, City of E-Bike.",
  loopActiveHint:
    "Lus aan — live-suggesties alleen echte lussen (onder). Geen heen-en-terug-pads (bijv. “60 min · Noord”).",
  suggestions: (min, profile) => `Suggesties · ${min} min · ${profile}`,
  computing: "Berekenen…",
  quickTimeout: "Live-suggesties te laat — seeds blijven zichtbaar.",
  retry: "Opnieuw",
  noLive: "Geen live-suggesties — seeds onderaan, sta locatie toe of ",
  openPlan: "Plannen openen",
  recompute: "Opnieuw berekenen",
  moreOption: "Andere optie",
  ghMinuteLimit:
    "Suggesties en tijden beperkt — even wachten of spaarzaam plannen.",
  honestyRoad:
    "Route volgt vooral wegen — tik een trail op de kaart en hang die aan.",
  honestyCycleway:
    "Weinig eigen fietspad — de live-route blijft vaak op de rijbaan.",
  honestyFarmTail:
    "Geen pad tot de pin — het doel ligt aan de straat.",
  honestyFarmMid:
    "Delen van de route volgen landwegen — zet het doel dichter bij een straat.",
  sixtyTitle: "Lussen ~60 min",
  sixtyLead:
    "Tempelhofer, Rhein-Neckar en after-work-lussen — los van live-routing.",
  noLoopsNearby: "Geen lussen in de buurt",
  noHonestHere:
    "Geen eerlijke lussen (start≈finish) hier — kies een demo-stad of verander plaats. Geen A→B-vultochten.",
  changePlaceBtn: "Plaats wijzigen",
  demoCity: "Demo-stad",
  planHint: "Zoek een adres of tik op de kaart",
  start: "Start",
  end: "Finish",
  startAddr: "Startadres",
  endAddr: "Finishadres",
  addrPlaceholder: "bijv. Wiesloch",
  search: "Zoeken",
  tapStart: "Tik start",
  tapVia: "+ Via",
  tapEnd: "Tik finish",
  startAbbr: "S",
  endAbbr: "F",
  startMyPos: "Mijn locatie",
  swapStartEnd: "Wissel start en bestemming",
  addStop: "Stop",
  closeLoop: "Terug naar start",
  viaN: (n) => `Via ${n}`,
  nextPickStart: "Volgende: start — tik op de kaart of typ een adres",
  nextPickEnd: "Volgende: bestemming — tik op de kaart of typ een adres",
  nextPickVia: "Tik nu op de kaart voor de stop.",
  loopClosed: "Lus",
  computingRoute: "Route past zich aan…",
  computeRoute: "Route berekenen",
  statLength: "Lengte",
  statDuration: "Duur",
  statAscent: "Stijging",
  statSurface: "Ondergrond",
  elevTitle: "Hoogteprofiel",
  onMapPlace: "Punt op de kaart",
  viaAddr: "Stop",
  routingAdapts: "Route past zich aan…",
  recently: "Recent",
  backToGps: "Terug naar GPS",
  mapArea: "Kaartuitsnede",
  tapLineVia:
    "Tik of sleep de lijn of de schijven voor een stop. Tik ernaast trekt de route door. Tik het hoogteprofiel: stop. Alt-klik of vasthouden: nieuw doel.",
  lastDestChip: (name) => `Laatste doel: ${name}`,
  lastDestChipGeneric: "Laatste doel herhalen",
  lastDestUndo: "Ongedaan maken",
  planUndo: "Ongedaan maken",
  planRedo: "Opnieuw",
  planLineCoach: "Sleep de lijn of de schijven voor een stop. Vasthouden of Alt-klik: nieuw doel.",
  planLineCoachOk: "Begrepen",
  planMapSteep: "Steil",
  planMapUnknown: "Onbekend",
  planStopSetHint: "Stop gezet. Sleep het punt om bij te sturen.",
  placeOnRoute: "Op de route",
  lastDestApplied: "Laatste doel overgenomen.",
  endSetComputing: "Einde gezet — route berekenen",
  setEndCta: "Zet bestemming",
  closeLoopHint: "Ronde: bestemming wordt start.",
  browserPlanOnly: "De app navigeert. Hier plan je alleen.",
  waysNearby: "Paden in de buurt",
  overlay: "Overlay",
  osmLoading: "OSM-paden laden…",
  osmError: "OSM-paden nu niet bereikbaar — later opnieuw.",
  osmEmpty: "Geen OSM-paden in dit beeld — verschuif of zoom de kaart.",
  show: "Tonen",
  append: "Toevoegen",
  intoNav: "Naar navi",
  attachApproach: "Aanrijden / toevoegen",
  approachByCar: "Met de auto naar het trail",
  approachOnFoot: "Te voet naar de ingang",
  atTrailStart: "Ik ben bij de start",
  trailGravityHint:
    "DH: auto of te voet naar de bovenste ingang. De afdaling volgt het trail, niet de weg.",
  trailUnsuitable: (bike) =>
    `Niet met ${bike} op dit trail. Wissel aan de stand — niet stiekem als MTB routen.`,
  difficultyOpen: "open",
  rangeLine: (lo, hi) => `Bereik ${lo}–${hi} km`,
  fromLocation: (n, farther) =>
    farther
      ? `Vanaf locatie (${n} · +${farther} verder)`
      : `Vanaf locatie (${n})`,
  sortedByYou: "je positie",
  sortedByMap: "kaartmidden",
  sortedNear: (who) => `Gesorteerd op afstand tot ${who}`,
  offlineFallback:
    "Offline-fallback: Berlijn 60 min lussen (incl. Tempelhofer), catalogus leeg.",
  noToursFilter: "Geen tocht met deze filters",
  loosenLoop:
    "Alleen echte lussen (start≈finish) — geen A→B als vulling. Filters ruimer of plaats wijzigen.",
  loosenOrPlan: "Filters ruimer of planner openen.",
  loopFilterOff: "Lusfilter uit",
  aroundYouCta: "Hier rondom",
  aroundYouAnother: "Andere lus",
  aroundYouLoop: "Lus om je heen · OSM-wegen",
  aroundYouHint: "Lus over OSM-wegen — geen Trailforks-trail",
  aroundYouBusy: "Lus wordt gelegd…",
  aroundYouFail: "Geen gesloten lus hier — wijzig plaats of duur.",
  aroundYouSport:
    "Lusgenerator voor gravel, race, stad en e-trekking.",
  aroundYouNeedGps: "Zet een locatie — dan een lus om je heen.",
  aroundYouOffline: "Lusgenerator heeft netwerk nodig.",
  aroundYouUncertain: "Lengte ongeveer — zo’n ±12 %",
  aroundYouUncertainShort: "±12 %",
  aroundYouStats: (km, min) => `${km} km · ${min} min`,
  aroundYouReasonDuration: (got, want) => `Duur ${got} min · doel ${want} min`,
  aroundYouReasonSurface: (surface) => `Vooral ${surface}`,
  aroundYouReasonOsm: "OSM-wegen — geen Trailforks-trail",
  previewEngine: (line) => `${line} · voorbeeld`,
  savePreview: "Bewaren",
  fartherRegions: (n) => `Meer regio's (${n})`,
  outdooractive: (n) => `Outdooractive (${n})`,
  googlePois: (n) =>
    `${n} Google-POIs (Laden) · Powered by Google · geen Google-kaartlaag`,
  noOa: "Geen OA-tochten in deze kaartregio.",
  example: "Voorbeeld",
  trailforks: (n) => `Trailforks (${n})`,
  tfFallback: "Attribution — geen geometrie-spiegel.",
  mappeHeading: "Die Mappe",
  mappeEmpty:
    "Nog niets opgeslagen — voeg een route toe, bewaar een tocht of GPX.",
  mappeFilterEmpty:
    "Geen tochten in dit filter. Privé blijft onder Privé / Alle.",
  mappeShowAll: "Alles tonen",
  importGpx: "GPX importeren",
  withTrack: "met track",
  importTag: "Import",
  shared: "gedeeld",
  privateTour: "privé",
  remove: "Verwijderen",
  plusCollection: "+ Collectie",
  collectionsTitle: "Collecties",
  collectionsLead: "Lokale mappen — geen social feed.",
  namePlaceholder: "Naam",
  create: "Aanmaken",
  noCollection: "Nog geen collectie.",
  routesCount: (n) => `${n} routes`,
  close: "Sluiten",
  tapFor: (what) => `Tik op de kaart voor ${what}`,
  cancel: "Annuleren",
  saveAria: "Opslaan",
  fromHereStart: "Hier starten (hybrid snap)",
  preview: "Voorbeeld",
  fromHere: "Vanaf hier",
  intoPlan: "Naar Plannen",
  locDeep: "Locatie: deep link",
  locWaitOrTap: "Locatie ophalen… — of tik een plaats",
  locGps: "Locatie: GPS",
  locDeepGps: "Locatie: deep link (GPS beschikbaar)",
  locNoneDemo: "Locatie niet beschikbaar — demo-stad of adres",
  locDeniedDemo: "Locatie geweigerd — kies een demo-stad of zoek een adres",
  locNoneAddr: "Locatie niet beschikbaar — zoek een adres of kies een demo-stad",
  locDeniedAddr: "Locatie geweigerd — zoek een adres of kies een demo-stad",
  locGpsCentered: "Locatie: GPS — kaart gecentreerd",
  locWait: "Locatie ophalen…",
  calcSlow: "Berekenen te traag — ~60 min seeds onderaan, of opnieuw.",
  noQuick: "Geen snelle routes — seeds onderaan of planner.",
  rateLimit: "Routinglimiet — benaderingen getoond. Later opnieuw berekenen.",
  quickFail: "Snelle routing mislukt — seeds onderaan, of opnieuw.",
  gpxBad: "GPX ongeldig of te weinig punten",
  geocodeFail: "Adreszoeken mislukt",
  savedLoaded: "Opgeslagen route geladen",
  needStartEnd: "Route niet berekend — zet start en finish.",
  pinOnly: "Alleen pin — geen track. In Plannen + finish, of live-routing.",
  hybridFail: "Hybrid snap mislukt",
  trailFail: "Trail kon niet worden verbonden",
  searchStart: "Adres zoeken — start zetten",
  changePlace: "Plaats wijzigen — stad of adres zoeken",
  heatmapOffline: "Waar velen rijden: offline",
  demoRegion: (name) => `Demo-regio: ${name}`,
  demoRegionLoops: (name) => `Demo-regio: ${name} · 60 min lussen`,
  noHits: (q) => `Geen treffers voor „${q}“`,
  geocodeFailHttp: (status) => `Adreszoeken mislukt (${status})`,
  inPlanNamed: (name) => `In Plannen: ${name} — start/finish bewerkbaar`,
  inPlanNeedEnd: (name) =>
    `In Plannen: ${name} — zet finish op de kaart of als adres (geen track).`,
  waypointStart: (label) => `Start: ${label}`,
  waypointEnd: (label) => `Finish: ${label}`,
  gpxImported: (name, km) => `GPX geïmporteerd: ${name} · ${km} km`,
  hybridStats: (km, min) => `Hybrid · ${km} km · ${min} min`,
  trailInserted: (name) => `${name} ingevoegd`,
  demoRouting:
    "Routes gebruiken demo-geometrie — live-routing is niet geconfigureerd.",
  unverifiedRouting:
    "Routing-sleutel gezet — live nog niet geverifieerd. Bij fouten, demo-geometrie.",
  pinMyPos: "Mijn positie",
  pinDeepLink: "Deep-link plaats",
  pinHere: "Hier",
  pinStartMap: "Start (kaart)",
  pinEndMap: "Finish (kaart)",
  pinTourStart: "Tochtstart",
  pinTourEnd: "Tochtfinish",
  pinTourPlace: "Tochtplaats",
  plannedRoute: "Geplande route",
  fromHereLabel: (name) => `${name} (vanaf hier)`,
  ideaLabel: (name) => `${name} (idee)`,
  planLabel: (name) => `${name} (plan)`,
  surfaceAsphalt: "Asfalt",
  surfaceSchotter: "Grind",
  surfaceNatur: "Natuurpad",
  surfaceGras: "Gras",
  surfaceHolz: "Hout",
  hwyPath: "Pad",
  hwyTrack: "Bosweg",
  hwyCycle: "Fietspad",
  hwyBridle: "Ruiterpad",
  hwyFoot: "Voetpad",
  tourIdea: "Tochtidee · geometrie wordt gerouteerd bij plannen",
  away: (km) => `~${km} km verder · `,
  loopRound: "⟲ Lus",
  pointAb: "A→B",
  because: "Omdat: ",
  details: "Details",
  pageLink: "Pagina",
  unsaveAria: "Opgeslagen verwijderen",
  save: "Opslaan",
  saved: "Opgeslagen",
  startInApp: "Starten in app",
  variantPlanned: "Zoals gepland",
  variantFlatter: "Minder hm",
  variantUnpaved: "Meer onverhard",
  variantValhallaOnly:
    "Minder hm en meer grind alleen met live-route — dit is de geplande lijn.",
  openNativeApp: "Openen in de app",
  placeKind: (kind) =>
    kind === "cafe"
      ? "Café"
      : kind === "water"
        ? "Water"
        : kind === "shop"
          ? "Winkel"
          : kind === "repair"
            ? "Werkplaats"
            : kind === "viewpoint"
              ? "Uitzicht"
              : "Plaats",
  overview: "Overzicht",
  popular: "Populair",
  photos: "Foto's",
  elevation: "Hoogte",
  match: "Match",
  pinIdea: "Idee",
  pinOnlyHint:
    "Alleen pin — geen opgeslagen track. Live-routing, Plannen of GPX voor een echte lijn.",
  whySuggestion: "Waarom deze suggestie?",
  rangeSpan: (lo, hi) => `Bereik ${lo}–${hi} km`,
  rangeTight: " — krap voor deze tocht",
  rangeOk: " — past",
  rangeTour: (km, conf) => `Tocht ${km} km · ${conf} betrouwbaarheid`,
  rangeProTitle: "Bereikprognose · Pro",
  rangeProBody: "Toont de spanne tegen de tochtvraag.",
  unlockPro: "Pro onder Profiel ontgrendelen →",
  offlineMapsHint: "Offline-routing laad je in de app. Hier merken via ",
  offlineMapsAfter: ".",
  offlineMapsChip: "Routing",
  savedLink: "Opgeslagen",
  heatCold: (k) =>
    `Nog weinig, waar velen rijden (vanaf ${k}) — je ritten en meer rijders vullen de kaart.`,
  heatConsent: (k) =>
    `Zet je sporen aan onder Privacy. Segmenten (vanaf ${k}) blijven zichtbaar als er genoeg rijders zijn.`,
  heatConsentBefore: "Zet je sporen aan onder ",
  heatConsentAfter: (k) =>
    `. Segmenten (vanaf ${k}) blijven zichtbaar als er genoeg rijders zijn.`,
  privacyLink: "Privacy",
  heatOwn: "Eigen rit",
  heatSection: "Segment",
  heatCell: "Waar velen rijden",
  heatSegments: (n) => `${n} stukken waar velen rijden`,
  riders: (n, pct) => `${n} rijders · intensiteit ${pct} %`,
  noSegments: "Geen zichtbare segmenten in dit beeld.",
  heading: (deg) => `Kijkrichting ${deg}°`,
  demoPhotos: "Voorbeeldfoto's — live-foto's vragen Mapillary-toegang (ops).",
  noPhotos: "Geen trail-foto's in de buurt.",
  elevMissing:
    "Hoogteprofiel nog niet beschikbaar — geen schatting als vulling.",
  publicTour: "Openbare tochtpagina →",
  openPlanner: "In de planner openen →",
  gapElev: (km) => ` · ${km} km zonder hoogtedata`,
  surfaceTitle: "Ondergrond",
  difficultyTitle: "Moeilijkheid",
  estimate: "Schatting",
  elevEst: (hm) => `Hoogteschatting ca. ${hm} hm`,
  elevProfile: (hm) => `Hoogteprofiel ca. ${hm} hm`,
  fromHereTitle: "Route vanaf hier",
  fromHereHint:
    "Live-routing vanaf GPS of kaartmidden — voorbeeld, daarna bewaren, of rijden in de app.",
  needCenter: "Locatie of kaartmidden ontbreekt",
  stretch: "Traject",
  compute: "Berekenen",
  inApp: "In app",
  noHonestEngine:
    "Geen echte lus — engine gaf A→B (start≠finish). Opnieuw of seeds gebruiken.",
  savedEngine: (line) => `${line} · opgeslagen`,
  routingFail: "Routing mislukt",
  roundKm: (km) => `Lus ${km} km`,
  tourKm: (km) => `Tocht ${km} km`,
  packsTitle: "Routing-packs",
  packsLead:
    "Alleen gebouwde packs zijn te laden. De routing-graaf activeer je in de app, niet in de browser. De overzichtskaart is extra en groot.",
  packsCatalog: "Catalogus…",
  packsEmpty: "Geen packs in de catalogus — region-build lokaal uitvoeren.",
  packsUnreachable: "Offline-catalogus niet bereikbaar.",
  packsNone: "Geen packs beschikbaar.",
  packsNotBuilt: "Nog niet gebouwd",
  packsDownload: (name) => `Offline-pack ${name} downloaden`,
  packsStarted: (name) =>
    `${name}: download gestart. Activeren alleen in de mobile app (offline-sheet).`,
  packsFail: "Download mislukt",
  packsLoad: "Laden",
  packsStub: "Stub",
  back: "Terug",
  tourIdeaLive:
    "Tochtidee — lijn live berekenen bij plannen of starten",
};

const BY_LANG: Record<ChromeLang, DiscoverUi> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
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

/** Backend names that must not reach rider chrome. Outdooractive stays. */
const ENGINE_STATUS_TAIL =
  /\s·\s(?:graphhopper|valhalla|osrm|openrouteservice|ors)$/i;

function stripEngineStatusTail(raw: string): string {
  return raw.replace(ENGINE_STATUS_TAIL, "");
}

/** Map stored DE status to chrome. Tour names stay; engine tails are stripped. */
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
  const planEndMap = raw.match(
    /^In Planen: (.+) — Ziel auf der Karte oder als Adresse setzen \(kein Track\)\.$/,
  );
  if (planEndMap) return d.inPlanNeedEnd(planEndMap[1]);
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
  return stripEngineStatusTail(
    raw
      .replaceAll(HONESTY_ROAD_DE, d.honestyRoad)
      .replaceAll(HONESTY_CYCLEWAY_DE, d.honestyCycleway)
      .replaceAll(HONESTY_FARM_TAIL_DE, d.honestyFarmTail)
      .replaceAll(HONESTY_FARM_MID_DE, d.honestyFarmMid),
  );
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

export function discoverOsmSurfaceLabel(
  raw: string | null | undefined,
  lang: ChromeLang,
): string {
  const d = discoverUi(lang);
  return osmSurfaceLabel(raw, {
    asphalt: d.surfaceAsphalt,
    gravel: d.surfaceSchotter,
    trail: d.surfaceNatur,
  });
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
