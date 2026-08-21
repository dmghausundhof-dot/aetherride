import type { ChromeLang } from "./chromeLang";
import { chromeDateLocale } from "./chromeLang";
import { formatRideGroupDurationHours } from "@/lib/community/rideGroup";

/** Exact DE store notes — map in the UI, do not import the store here. */
const LOCAL_ONLY_DE =
  "Nicht eingeloggt — nur auf diesem Gerät. Join auf dem Server braucht Login.";
const ON_SERVER_DE = "Gruppe auf dem Server.";
const SERVER_TABLE_DE = "Server-Tabelle fehlt — nur lokal.";
const NEED_SIGNIN_DE =
  "Anmelden — sonst sieht der Freund die Gruppe nicht auf dem Server.";
const NEED_TOUR_DE =
  "Zuerst eine Tour wählen oder selbst planen.";
const WINDOW_EXTENDED_DE = "Fenster verlängert.";
const EXTEND_INVALID_DE = "Zeit liegt außerhalb des Rahmens.";
const PRIVATE_CODE_DE =
  "Privat — nur mit Einladungslink. Kein Code zum Abtippen.";
const JOIN_EXPIRED_DE = "Fenster zu — der Link gilt nicht mehr.";
const JOIN_CLOSED_DE = "Gruppe ist aufgelöst.";
const JOIN_NEED_LINK_DE = "Beitritt nur über den Einladungslink.";
const JOIN_HOST_DE = "Anmelden — sonst sieht der Host dich nicht.";
const JOIN_HOST_DE_ROLE = "Anmelden — sonst sieht der Gastgeber dich nicht.";
const JOIN_UNKNOWN_DE =
  "Kein offener Link. Ohne Login gilt nur dieser Speicher; sonst den Einladungslink einfügen.";
const JOIN_BAD_LINK_DE = "Einladungslink ungültig.";
const JOIN_CODE_LEN_DE = "Code hat 6 Zeichen.";
const LISTED_DE =
  "Auf dem Platz gelistet — wer den Link hat, kann beitreten.";
const LISTED_CODE_DE = "Auf dem Platz gelistet — Link oder Code reicht.";
const UNLISTED_DE = "Nur per Link — nicht auf dem Platz.";

export type PlatzCopy = {
  inviteHint: string;
  pickTour: string;
  pickMine: string;
  pickNearby: string;
  nearbyNeedGps: string;
  nearbyFromMap: string;
  planAsGroup: string;
  planAsGroupHint: string;
  groupCreateReady: string;
  visPrivate: string;
  visPublic: string;
  visAll: string;
  meetingPlaceholder: string;
  createGroup: string;
  needSignIn: string;
  needSharedTour: string;
  created: (note?: string | null) => string;
  localOnlyFoot: string;
  emptyPublic: string;
  emptyPrivate: string;
  emptyAll: string;
  host: string;
  guest: string;
  you: string;
  selfSuffix: string;
  along: (n: number) => string;
  onServer: string;
  onDevice: string;
  invite: string;
  dissolve: string;
  leave: string;
  copyLink: string;
  copyCode: string;
  copiedCode: string;
  copiedInvite: string;
  makePrivate: string;
  makePublic: string;
  listedNote: string;
  unlistedNote: string;
  pinsOff: string;
  pinsHud: string;
  shareInRide: string;
  pinsHint: string;
  joinPrivateCode: string;
  friendN: (n: number) => string;
  extendHour: string;
  extend30m: string;
  extend1h: string;
  extend2h: string;
  extendCustomEnd: string;
  extendCapHint: string;
  extendInvalid: string;
  windowExtended: string;
  join: string;
  joined: (title: string) => string;
  joinWithLink: string;
  joinLocalCta: string;
  joinUnsignedHint: string;
  joinSignInFirst: string;
  joinField: string;
  more: string;
  timeTapHint: string;
  shareLink: string;
  joinCodeField: string;
  joinHint: string;
  joinEmpty: string;
  joinInvalid: string;
  joinExpired: string;
  joinClosed: string;
  joinUnknown: string;
  startLabel: string;
  startNow: string;
  startIn1h: string;
  startToday18: string;
  startTomorrow10: string;
  startCustom: string;
  durationLabel: string;
  durationCustom: string;
  durationHoursHint: string;
  windowCapHint: string;
  pinsOn: string;
  collectionsHint: string;
  shareTitle: (title: string) => string;
  shareMeet: (point: string) => string;
  shareProfile: (url: string) => string;
  shareVisPublic: string;
  shareVisPrivate: string;
  whenClosed: (wd: string, hm: string) => string;
  whenToday: (hm: string, dur: string) => string;
  whenTomorrow: (hm: string, dur: string) => string;
  whenOther: (wd: string, hm: string, dur: string) => string;
  mappeEmpty: string;
  mappeEmptyTitle: string;
  noTrackLabel: string;
  loopTag: string;
  sourceImport: string;
  sourcePlanned: string;
  sourceRecorded: string;
  startAwayKm: (km: number) => string;
  mappeFilterEmpty: string;
  showAll: string;
  keepOnMap: string;
  showOnMap: string;
  removeFromMappe: string;
  shared: string;
  privateTour: string;
  openInApp: string;
  joinOnDevice: string;
  stimmenTitle: string;
  stimmenEmpty: string;
  stimmeUntitled: string;
  pending: string;
  collectionsTitle: string;
  collectionName: string;
  collectionCreate: string;
  collectionCreated: string;
  collectionEmpty: string;
  collectionTours: (n: number) => string;
  gpxNoTrack: string;
  gpxUnreadable: string;
  gpxImported: (name: string) => string;
  joinNotOnServer: (note: string) => string;
  joinOk: (title: string, note?: string | null) => string;
  shareCopied: string;
  share: string;
  shareEmpty: string;
  shareNoPublic: string;
  shareTooBig: string;
  shareRevoke: string;
  shareRevokeFail: string;
  localOnlyNote: string;
  onServerNote: string;
  serverTableNote: string;
  addRoute: string;
  keepRoute: string;
  keepName: string;
  lastRidden: (when: string) => string;
  renameTour: string;
  searchTours: string;
  sortRecent: string;
  sortDistance: string;
  sortName: string;
  inviteFriends: string;
  goRide: string;
  mappeKicker: string;
  addRouteHint: string;
  routeName: string;
  startGps: string;
  startNone: string;
  startFromGps: (coords: string) => string;
  startFromMap: (coords: string) => string;
  startPin: (lat: string, lng: string) => string;
  savedNamed: (name: string) => string;
  intoMappe: string;
  cancel: string;
  importGpx: string;
  tourKicker: string;
  catalogTag: string;
  riddenWith: (name: string) => string;
  trackLocal: string;
  noTrackMappe: string;
  inCollections: (names: string) => string;
  addToCollection: string;
  collectionAdded: string;
  visibility: string;
  shareOut: string;
  privateNote: string;
  notePlaceholder: string;
  honestyCatalog: string;
  honestyTrack: string;
  honestyNoTrack: string;
  linkNoTrackLong: string;
  linkHasTrack: string;
  linkNoTrack: string;
};

const DE: PlatzCopy = {
  inviteHint:
    "Einladen teilt den Link. Deine Gruppen bleiben — kein Feed. Freunde auf der Karte nur in der App, nach Opt-in.",
  pickTour: "Tour wählen",
  pickMine: "Meine Touren",
  pickNearby: "Touren in der Nähe",
  nearbyNeedGps:
    "Ohne Standort keine Touren in der Nähe — nimm eine eigene oder die letzte Karte.",
  nearbyFromMap: "Nähe von der letzten Karte, nicht vom GPS.",
  planAsGroup: "Eigene Tour als Gruppe planen",
  planAsGroupHint:
    "Route auf der Karte setzen, merken — danach liegt sie im Gruppen-Picker.",
  groupCreateReady: "Tour liegt bereit — Gruppe anlegen.",
  visPrivate: "Privat",
  visPublic: "Freigegeben",
  visAll: "Alle",
  meetingPlaceholder: "Treffpunkt (optional)",
  createGroup: "Gruppe anlegen",
  needSignIn:
    "Anmelden — sonst sieht der Freund die Gruppe nicht auf dem Server.",
  needSharedTour: "Zuerst eine Tour wählen oder selbst planen.",
  created: (note) =>
    `Gruppe angelegt — Einladen teilt den Link${note ? ` — ${note}` : ""}`,
  localOnlyFoot:
    " — sonst bleibt die Gruppe auf diesem Gerät. Der Freund sieht dich nicht.",
  emptyPublic: "Keine offenen Gruppen.",
  emptyPrivate: "Keine privaten Gruppen in diesem Filter.",
  emptyAll: "Noch keine Gruppe. Einladen teilt den Link.",
  host: "Gastgeber",
  guest: "Gast",
  you: "Du",
  selfSuffix: " · du",
  along: (n) => `${n} dabei`,
  onServer: "auf dem Server",
  onDevice: "nur auf diesem Gerät",
  invite: "Einladen",
  dissolve: "Auflösen",
  leave: "Verlassen",
  copyLink: "Link kopieren",
  copyCode: "Code kopieren",
  copiedCode: "Code kopiert. Offene Gruppe: damit beitreten.",
  copiedInvite:
    "Link kopiert. Wer ihn hat, kann beitreten, solange die Gruppe offen ist.",
  makePrivate: "Privat machen",
  makePublic: "Auf dem Platz listen",
  listedNote: "Auf dem Platz gelistet — Link oder Code reicht.",
  unlistedNote: "Nur per Link — nicht auf dem Platz.",
  pinsOff: "Freunde auf der Karte · aus",
  pinsHud: "Freunde nur während der Fahrt",
  shareInRide: "Teilen in der Fahrt",
  pinsHint: "Nur während der Fahrt, nicht auf der öffentlichen Karte.",
  joinPrivateCode:
    "Privat — nur mit Einladungslink. Kein Code zum Abtippen.",
  friendN: (n) => `Freund ${n}`,
  extendHour: "Fenster verlängern",
  extend30m: "+30 Min",
  extend1h: "+1 Stunde",
  extend2h: "+2 Stunden",
  extendCustomEnd: "Anderes Ende…",
  extendCapHint: "Maximal bis jetzt + 12 Stunden.",
  extendInvalid: "Zeit liegt außerhalb des Rahmens.",
  windowExtended: WINDOW_EXTENDED_DE,
  join: "Beitreten",
  joined: (title) => `Dabei: ${title}`,
  joinWithLink: "Verbinden",
  joinLocalCta: "Auf diesem Gerät merken",
  joinUnsignedHint: "Ohne Anmeldung sieht der Gastgeber dich nicht.",
  joinSignInFirst: "Anmelden — sonst sieht der Gastgeber dich nicht",
  joinField: "Link oder 6-stelliger Code",
  more: "Mehr",
  timeTapHint: "Tippen zum Ändern",
  shareLink: "Link teilen",
  joinCodeField: "Code",
  joinHint:
    "Link aus WhatsApp oder Messages einfügen — oder den 6-stelligen Code einer offenen Gruppe. Privat bleibt nur der Einladungslink.",
  joinEmpty: "Link oder Code fehlt.",
  joinInvalid: "Kein gültiger Link oder Code.",
  joinExpired: "Fenster zu — der Link gilt nicht mehr.",
  joinClosed: "Gruppe ist aufgelöst.",
  joinUnknown:
    "Kein offener Link. Ohne Login gilt nur dieser Speicher; sonst den Einladungslink einfügen.",
  startLabel: "Start",
  startNow: "Jetzt",
  startIn1h: "In 1 h",
  startToday18: "Heute 18:00",
  startTomorrow10: "Morgen 10:00",
  startCustom: "Andere Zeit…",
  durationLabel: "Dauer",
  durationCustom: "Andere…",
  durationHoursHint: "Stunden (0,25–12)",
  windowCapHint: "Start bis 14 Tage voraus. Dauer 15 Min bis 12 Stunden.",
  pinsOn: "Freunde auf der Karte · an",
  collectionsHint:
    "Anlegen in der Akte. Teilen nur mit freigegebenen oder Katalog-Touren — private GPX bleibt draußen.",
  shareTitle: (title) => `Zusammen raus: ${title}`,
  shareMeet: (point) => `Treffpunkt: ${point}`,
  shareProfile: (url) => `Mein Profil: ${url}`,
  shareVisPublic:
    "Freigegeben: Link oder Code reicht. Die Gruppe steht auf dem Platz und als Treffen-Pin auf der Karte.",
  shareVisPrivate:
    "Privat: nur wer diesen Link hat, kann beitreten. Nicht gelistet.",
  whenClosed: (wd, hm) => `zu — ${wd} ${hm}`,
  whenToday: (hm, dur) => `heute ${hm} · ${dur}`,
  whenTomorrow: (hm, dur) => `morgen ${hm} · ${dur}`,
  whenOther: (wd, hm, dur) => `${wd} ${hm} · ${dur}`,
  mappeEmpty: "Noch keine eigenen Touren — merken oder GPX importieren.",
  mappeEmptyTitle: "Noch keine Linie",
  noTrackLabel: "Kein Track",
  loopTag: "Runde",
  sourceImport: "Import",
  sourcePlanned: "Geplant",
  sourceRecorded: "Aufgezeichnet",
  startAwayKm: (km) => `${km} km entfernt`,
  mappeFilterEmpty: "Keine Touren in diesem Filter.",
  showAll: "Alle zeigen",
  keepOnMap: "Auf der Karte merken",
  showOnMap: "Auf Karte",
  removeFromMappe: "Aus der Mappe nehmen",
  shared: "freigegeben",
  privateTour: "privat",
  openInApp: "In der App öffnen",
  joinOnDevice:
    " — In der App merken. Ohne Anmeldung sieht der Gastgeber dich nicht.",
  stimmenTitle: "Stimmen",
  stimmenEmpty:
    "Noch keine Stimmen zu deinen Touren. Nach Freigabe können andere schreiben.",
  stimmeUntitled: "Stimme",
  pending: "In Prüfung",
  collectionsTitle: "Sammlungen",
  collectionName: "Name der Sammlung",
  collectionCreate: "Anlegen",
  collectionCreated: "Sammlung angelegt",
  collectionEmpty: "Noch keine Sammlung — in der Akte bei einer Tour anlegen.",
  collectionTours: (n) => (n === 1 ? "1 Tour" : `${n} Touren`),
  gpxNoTrack: "GPX ohne Track",
  gpxUnreadable: "GPX konnte nicht gelesen werden",
  gpxImported: (name) => `Importiert: ${name}`,
  joinNotOnServer: (note) =>
    `Nicht auf dem Server — ${note} Unter Profil anmelden, dann den Link nochmal öffnen. Sonst sieht der Gastgeber dich nicht.`,
  joinOk: (title, note) =>
    `Dabei: ${title}${note ? ` — ${note}` : ""}. Wer den Link hat, kann beitreten, solange die Gruppe offen ist.`,
  shareCopied: "Kopiert",
  share: "Teilen",
  shareEmpty: "Sammlung ist leer — zuerst Touren hinzufügen.",
  shareNoPublic:
    "Keine freigegebenen oder Katalog-Touren in der Sammlung. Private GPX bleibt draußen.",
  shareTooBig: "Sammlung zu groß für URL-Share — weniger Touren wählen.",
  shareRevoke: "Server-Link zurückziehen",
  shareRevokeFail: "Link konnte nicht zurückgezogen werden — eingeloggt?",
  localOnlyNote: LOCAL_ONLY_DE,
  onServerNote: ON_SERVER_DE,
  serverTableNote: SERVER_TABLE_DE,
  addRoute: "Route hinzufügen",
  keepRoute: "Merken",
  keepName: "Nur den Namen merken",
  lastRidden: (when) => `zuletzt ${when}`,
  renameTour: "Umbenennen",
  searchTours: "Tour suchen",
  sortRecent: "Zuletzt",
  sortDistance: "Länge",
  sortName: "Name",
  inviteFriends: "Freunde mitnehmen",
  goRide: "Losfahren",
  mappeKicker: "Mappe",
  addRouteHint:
    "Name merken, Start von GPS oder letzter Karte, sonst ohne Pin. GPX darunter — ohne erfundenen Track.",
  routeName: "Name der Route",
  startGps: "Start: GPS, falls erlaubt — sonst letzte Kartenmitte, sonst ohne Pin.",
  startNone: "Start: noch ohne Pin — GPS oder Karte öffnen.",
  startFromGps: (coords) => `Start: dein Standort (${coords})`,
  startFromMap: (coords) => `Start: letzte Kartenmitte (${coords})`,
  startPin: (lat, lng) => `Start: ${lat}°N, ${lng}°E`,
  savedNamed: (name) => `Gespeichert: ${name}`,
  intoMappe: "In die Mappe legen",
  cancel: "Abbrechen",
  importGpx: "GPX importieren",
  tourKicker: "Tour",
  catalogTag: "Katalog",
  riddenWith: (name) => `gefahren mit ${name}`,
  trackLocal: "Track liegt lokal. Sync zwischen deinen Geräten.",
  noTrackMappe: "Noch kein Track — nur der Eintrag in der Mappe.",
  inCollections: (names) => `In ${names}`,
  addToCollection: "Zu Sammlung",
  collectionAdded: "Zur Sammlung hinzugefügt",
  visibility: "Freigabe",
  shareOut: "Freigeben",
  privateNote: "Private Notiz",
  notePlaceholder: "Nur für dich — keine Stimme.",
  honestyCatalog:
    "Katalog-Tour ist schon freigegeben. Freigeben macht deine Tour teilbar — der Link zeigt Name und Stats, keinen privaten Extra-Track.",
  honestyTrack:
    "Freigeben erzeugt einen Link. Der Link enthält eine vereinfachte Spur (Koordinaten), nicht nur den Namen. Auf der Karte erscheint sie erst nach 3 Stimmen in 14 Tagen — sonst wieder privat. Zurück auf Privat nimmt die Tour aus Filtern und speichert den Widerruf auf dem Server, wenn du eingeloggt bist. Ohne Login gilt er nur in diesem Browser.",
  honestyNoTrack:
    "Freigeben erzeugt einen Link mit Name und Stats — ohne Track, weil keiner gespeichert ist.",
  linkNoTrackLong:
    "Link ohne Spur — zu lang für die URL. Name und Stats, kein GPS.",
  linkHasTrack: "Link enthält eine vereinfachte Spur.",
  linkNoTrack: "Link ohne Track — Name und Stats.",
};

const EN: PlatzCopy = {
  inviteHint:
    "Invite shares the link. Your groups stay — not a feed. Friends on the map only in the app, after opt-in.",
  pickTour: "Pick a tour",
  pickMine: "My tours",
  pickNearby: "Tours nearby",
  nearbyNeedGps:
    "Without a location there are no nearby tours — pick one of yours or the last map.",
  nearbyFromMap: "Nearby is from the last map, not GPS.",
  planAsGroup: "Plan my tour as a group",
  planAsGroupHint:
    "Set the route on the map, save it — then it shows in the group picker.",
  groupCreateReady: "Tour is ready — create the group.",
  visPrivate: "Private",
  visPublic: "Shared",
  visAll: "All",
  meetingPlaceholder: "Meeting point (optional)",
  createGroup: "Create group",
  needSignIn: "Sign in — otherwise your friend will not see the group on the server.",
  needSharedTour: "Pick a tour first, or plan your own.",
  created: (note) =>
    `Group created — invite shares the link${note ? ` — ${note}` : ""}`,
  localOnlyFoot:
    " — otherwise the group stays on this device. Your friend will not see you.",
  emptyPublic: "No public groups.",
  emptyPrivate: "No private groups in this filter.",
  emptyAll: "No group yet. Invite shares the link.",
  host: "Host",
  guest: "Guest",
  you: "You",
  selfSuffix: " · you",
  along: (n) => `${n} in`,
  onServer: "on the server",
  onDevice: "on this device only",
  invite: "Invite",
  dissolve: "Close",
  leave: "Leave",
  copyLink: "Copy link",
  copyCode: "Copy code",
  copiedCode: "Code copied. Listed group: join with it.",
  copiedInvite:
    "Link copied. Whoever has it can join while the group is open.",
  makePrivate: "Make private",
  makePublic: "List on Platz",
  listedNote: "Listed on Platz — link or code is enough.",
  unlistedNote: "Link only — not listed on Platz.",
  pinsOff: "Friends on the map · off",
  pinsHud: "Friends only while riding",
  shareInRide: "Share while riding",
  pinsHint: "Only while riding, not on the public map.",
  joinPrivateCode: "Private — invitation link only. No code to type.",
  friendN: (n) => `Friend ${n}`,
  extendHour: "Extend window",
  extend30m: "+30 min",
  extend1h: "+1 hour",
  extend2h: "+2 hours",
  extendCustomEnd: "Other end…",
  extendCapHint: "At most until now + 12 hours.",
  extendInvalid: "Time is outside the allowed range.",
  windowExtended: "Window extended.",
  join: "Join",
  joined: (title) => `In: ${title}`,
  joinWithLink: "Connect",
  joinLocalCta: "Save on this device",
  joinUnsignedHint: "Without signing in, the host cannot see you.",
  joinSignInFirst: "Sign in — otherwise the host cannot see you",
  joinField: "Link or 6-character code",
  more: "More",
  timeTapHint: "Tap to edit",
  shareLink: "Share link",
  joinCodeField: "Code",
  joinHint:
    "Paste the invitation link from WhatsApp or Messages, or type the 6-character code of a listed group. Private groups still need the invitation link.",
  joinEmpty: "Link or code missing.",
  joinInvalid: "Not a valid invite link or code.",
  joinExpired: "Window closed — the link is no longer valid.",
  joinClosed: "The group has been closed.",
  joinUnknown:
    "No open link. Without sign-in this stays on this device; otherwise paste the invitation link.",
  startLabel: "Start",
  startNow: "Now",
  startIn1h: "In 1 h",
  startToday18: "Today 18:00",
  startTomorrow10: "Tomorrow 10:00",
  startCustom: "Other time…",
  durationLabel: "Duration",
  durationCustom: "Other…",
  durationHoursHint: "Hours (0.25–12)",
  windowCapHint: "Start up to 14 days ahead. Duration 15 min to 12 hours.",
  pinsOn: "Friends on the map · on",
  collectionsHint:
    "Create in Tour. Sharing only includes released or catalogue tours — private GPX stays out.",
  shareTitle: (title) => `Ride together: ${title}`,
  shareMeet: (point) => `Meeting point: ${point}`,
  shareProfile: (url) => `My profile: ${url}`,
  shareVisPublic:
    "Shared: link or code is enough. The group is listed on Platz and as a meeting pin on Browse.",
  shareVisPrivate:
    "Private: only whoever has this link can join. Not listed publicly.",
  whenClosed: (wd, hm) => `closed — ${wd} ${hm}`,
  whenToday: (hm, dur) => `today ${hm} · ${dur}`,
  whenTomorrow: (hm, dur) => `tomorrow ${hm} · ${dur}`,
  whenOther: (wd, hm, dur) => `${wd} ${hm} · ${dur}`,
  mappeEmpty: "No tours yet — save one or import GPX.",
  mappeEmptyTitle: "No line yet",
  noTrackLabel: "No track",
  loopTag: "Loop",
  sourceImport: "Import",
  sourcePlanned: "Planned",
  sourceRecorded: "Recorded",
  startAwayKm: (km) => `${km} km away`,
  mappeFilterEmpty: "No tours in this filter.",
  showAll: "Show all",
  keepOnMap: "Save from the map",
  showOnMap: "Show on map",
  removeFromMappe: "Remove from the Mappe",
  shared: "shared",
  privateTour: "private",
  openInApp: "Open in the app",
  joinOnDevice:
    " — Save in the app. Without signing in, the host cannot see you.",
  stimmenTitle: "Stimmen",
  stimmenEmpty:
    "No Stimmen on your tours yet. After you share, others can write.",
  stimmeUntitled: "Voice",
  pending: "In review",
  collectionsTitle: "Collections",
  collectionName: "Collection name",
  collectionCreate: "Create",
  collectionCreated: "Collection created",
  collectionEmpty: "No collection yet — create one in Tour on a saved ride.",
  collectionTours: (n) => (n === 1 ? "1 tour" : `${n} tours`),
  gpxNoTrack: "GPX without a track",
  gpxUnreadable: "GPX could not be read",
  gpxImported: (name) => `Imported: ${name}`,
  joinNotOnServer: (note) =>
    `Not on the server — ${note} Sign in under Profile, then open the link again. Otherwise the host will not see you.`,
  joinOk: (title, note) =>
    `In: ${title}${note ? ` — ${note}` : ""}. Whoever has the link can join while the group is open.`,
  shareCopied: "Copied",
  share: "Share",
  shareEmpty: "Collection is empty — add tours first.",
  shareNoPublic:
    "No shared or catalogue tours in the collection. Private GPX stays out.",
  shareTooBig: "Collection too large for a URL share — pick fewer tours.",
  shareRevoke: "Revoke server link",
  shareRevokeFail: "Could not revoke the link — signed in?",
  localOnlyNote:
    "Not signed in — this device only. Joining on the server needs login.",
  onServerNote: "Group on the server.",
  serverTableNote: "Server table missing — local only.",
  addRoute: "Add a route",
  keepRoute: "Save",
  keepName: "Save the name only",
  lastRidden: (when) => `last ${when}`,
  renameTour: "Rename",
  searchTours: "Search tours",
  sortRecent: "Recent",
  sortDistance: "Length",
  sortName: "Name",
  inviteFriends: "Bring friends",
  goRide: "Let's ride",
  mappeKicker: "Mappe",
  addRouteHint:
    "Name + start (GPS, else last map centre, else no pin) — no invented track. GPX stays optional.",
  routeName: "Route name",
  startGps: "Start: GPS if allowed — else last map centre, else no pin.",
  startNone: "Start: no pin yet — open GPS or the map.",
  startFromGps: (coords) => `Start: your location (${coords})`,
  startFromMap: (coords) => `Start: last map centre (${coords})`,
  startPin: (lat, lng) => `Start: ${lat}°N, ${lng}°E`,
  savedNamed: (name) => `Saved: ${name}`,
  intoMappe: "Put into Die Mappe",
  cancel: "Cancel",
  importGpx: "Import GPX",
  tourKicker: "Tour",
  catalogTag: "Catalogue",
  riddenWith: (name) => `ridden with ${name}`,
  trackLocal: "Track is local. Sync between your devices.",
  noTrackMappe: "No track yet — only the entry in Die Mappe.",
  inCollections: (names) => `In ${names}`,
  addToCollection: "Add to collection",
  collectionAdded: "Added to collection",
  visibility: "Share",
  shareOut: "Share",
  privateNote: "Private note",
  notePlaceholder: "Just for you — not a Stimme.",
  honestyCatalog:
    "Catalogue tour is already shared. Sharing makes your tour shareable — the link shows name and stats, no extra private track.",
  honestyTrack:
    "Sharing creates a link. The link holds a simplified trace (coordinates), not just the name. It only appears on the map after 3 voices in 14 days — otherwise it goes private again. Back to private drops the tour from filters and stores the revoke on the server if you are signed in. Without login it only holds in this browser.",
  honestyNoTrack:
    "Sharing creates a link with name and stats — no track, because none is stored.",
  linkNoTrackLong:
    "Link without a trace — too long for the URL. Name and stats, no GPS.",
  linkHasTrack: "Link includes a simplified trace.",
  linkNoTrack: "Link without a track — name and stats.",
};

const FR: PlatzCopy = {
  inviteHint:
    "Inviter partage le lien. Tes groupes restent — pas un fil. Amis sur la carte seulement dans l’appli, après opt-in.",
  pickTour: "Choisir une sortie",
  pickMine: "Mes sorties",
  pickNearby: "Sorties à proximité",
  nearbyNeedGps:
    "Sans position, pas de sorties à proximité — prends une des tiennes ou la dernière carte.",
  nearbyFromMap: "Proximité d’après la dernière carte, pas le GPS.",
  planAsGroup: "Planifier ma sortie comme groupe",
  planAsGroupHint:
    "Trace la route sur la carte, enregistre-la — elle apparaît ensuite dans le sélecteur.",
  groupCreateReady: "La sortie est prête — crée le groupe.",
  visPrivate: "Privé",
  visPublic: "Partagé",
  visAll: "Tous",
  meetingPlaceholder: "Point de rendez-vous (optionnel)",
  createGroup: "Créer le groupe",
  needSignIn:
    "Connecte-toi — sinon ton ami ne verra pas le groupe sur le serveur.",
  needSharedTour: "Choisis d’abord une sortie, ou planifie la tienne.",
  created: (note) =>
    `Groupe créé — inviter partage le lien${note ? ` — ${note}` : ""}`,
  localOnlyFoot:
    " — sinon le groupe reste sur cet appareil. Ton ami ne te voit pas.",
  emptyPublic: "Pas de groupes publics.",
  emptyPrivate: "Pas de groupes privés dans ce filtre.",
  emptyAll: "Pas encore de groupe. Inviter partage le lien.",
  host: "Hôte",
  guest: "Invité",
  you: "Toi",
  selfSuffix: " · toi",
  along: (n) => `${n} avec`,
  onServer: "sur le serveur",
  onDevice: "seulement sur cet appareil",
  invite: "Inviter",
  dissolve: "Dissoudre",
  leave: "Quitter",
  copyLink: "Copier le lien",
  copyCode: "Copier le code",
  copiedCode: "Code copié. Groupe listé : on rejoint avec.",
  copiedInvite:
    "Lien copié. Qui l’a peut rejoindre tant que le groupe est ouvert.",
  makePrivate: "Rendre privé",
  makePublic: "Afficher sur le Platz",
  listedNote: "Listé sur Platz — lien ou code suffit.",
  unlistedNote: "Lien seulement — pas sur Platz.",
  pinsOff: "Amis sur la carte · off",
  pinsHud: "Amis seulement pendant la sortie",
  shareInRide: "Partager pendant la sortie",
  pinsHint: "Seulement pendant la sortie, pas sur la carte publique.",
  joinPrivateCode:
    "Privé — uniquement le lien d’invitation. Pas de code à taper.",
  friendN: (n) => `Ami ${n}`,
  extendHour: "Prolonger la fenêtre",
  extend30m: "+30 min",
  extend1h: "+1 heure",
  extend2h: "+2 heures",
  extendCustomEnd: "Autre fin…",
  extendCapHint: "Au plus jusqu’à maintenant + 12 heures.",
  extendInvalid: "L’heure est hors cadre.",
  windowExtended: "Fenêtre prolongée.",
  join: "Rejoindre",
  joined: (title) => `Dedans : ${title}`,
  joinWithLink: "Relier",
  joinLocalCta: "Garder sur cet appareil",
  joinUnsignedHint: "Sans connexion, l’hôte ne te voit pas.",
  joinSignInFirst: "Connecte-toi — sinon l’hôte ne te voit pas",
  joinField: "Lien ou code à 6 caractères",
  more: "Plus",
  timeTapHint: "Toucher pour modifier",
  shareLink: "Partager le lien",
  joinCodeField: "Code",
  joinHint:
    "Colle le lien d’invitation depuis WhatsApp ou Messages, ou saisis le code à 6 caractères d’un groupe listé. Privé a encore besoin du lien d’invitation.",
  joinEmpty: "Lien ou code manquant.",
  joinInvalid: "Lien ou code invalide.",
  joinExpired: "Fenêtre fermée — le lien n’est plus valable.",
  joinClosed: "Le groupe est dissous.",
  joinUnknown:
    "Pas de lien ouvert. Sans connexion ça reste sur cet appareil ; sinon colle le lien d’invitation.",
  startLabel: "Départ",
  startNow: "Maintenant",
  startIn1h: "Dans 1 h",
  startToday18: "Aujourd’hui 18:00",
  startTomorrow10: "Demain 10:00",
  startCustom: "Autre heure…",
  durationLabel: "Durée",
  durationCustom: "Autre…",
  durationHoursHint: "Heures (0,25–12)",
  windowCapHint: "Départ jusqu’à 14 jours. Durée 15 min à 12 heures.",
  pinsOn: "Amis sur la carte · on",
  collectionsHint:
    "Créer dans la fiche. Le partage ne prend que les sorties partagées ou catalogue — le GPX privé reste dehors.",
  shareTitle: (title) => `Sortir ensemble : ${title}`,
  shareMeet: (point) => `Rendez-vous : ${point}`,
  shareProfile: (url) => `Mon profil : ${url}`,
  shareVisPublic:
    "Partagé : lien ou code suffit. Le groupe est sur le Platz et comme pin de rendez-vous sur la carte.",
  shareVisPrivate:
    "Privé : seulement qui a ce lien peut rejoindre. Pas de listing public.",
  whenClosed: (wd, hm) => `fermé — ${wd} ${hm}`,
  whenToday: (hm, dur) => `aujourd’hui ${hm} · ${dur}`,
  whenTomorrow: (hm, dur) => `demain ${hm} · ${dur}`,
  whenOther: (wd, hm, dur) => `${wd} ${hm} · ${dur}`,
  mappeEmpty: "Pas encore de sorties — garder ou importer un GPX.",
  mappeEmptyTitle: "Pas encore de ligne",
  noTrackLabel: "Pas de trace",
  loopTag: "Boucle",
  sourceImport: "Import",
  sourcePlanned: "Planifiée",
  sourceRecorded: "Enregistré",
  startAwayKm: (km) => `${km} km jusqu’au départ`,
  mappeFilterEmpty: "Pas de sorties dans ce filtre.",
  showAll: "Tout afficher",
  keepOnMap: "Garder depuis la carte",
  showOnMap: "Sur la carte",
  removeFromMappe: "Retirer de la Mappe",
  shared: "partagé",
  privateTour: "privé",
  openInApp: "Ouvrir dans l’app",
  joinOnDevice:
    " — Garder dans l’app. Sans connexion, l’hôte ne te voit pas.",
  stimmenTitle: "Stimmen",
  stimmenEmpty:
    "Pas encore de Stimmen sur tes sorties. Après partage, les autres peuvent écrire.",
  stimmeUntitled: "Avis",
  pending: "En relecture",
  collectionsTitle: "Collections",
  collectionName: "Nom de la collection",
  collectionCreate: "Créer",
  collectionCreated: "Collection créée",
  collectionEmpty: "Pas encore de collection — crée-en une dans la fiche d’une sortie.",
  collectionTours: (n) => (n === 1 ? "1 sortie" : `${n} sorties`),
  gpxNoTrack: "GPX sans trace",
  gpxUnreadable: "GPX illisible",
  gpxImported: (name) => `Importé : ${name}`,
  joinNotOnServer: (note) =>
    `Pas sur le serveur — ${note} Connecte-toi sous Profil, puis rouvre le lien. Sinon l’hôte ne te voit pas.`,
  joinOk: (title, note) =>
    `Dedans : ${title}${note ? ` — ${note}` : ""}. Qui a le lien peut rejoindre tant que le groupe est ouvert.`,
  shareCopied: "Copié",
  share: "Partager",
  shareEmpty: "Collection vide — ajoute d’abord des sorties.",
  shareNoPublic:
    "Pas de sorties partagées ou catalogue dans la collection. Le GPX privé reste dehors.",
  shareTooBig: "Collection trop grande pour un partage URL — moins de sorties.",
  shareRevoke: "Retirer le lien serveur",
  shareRevokeFail: "Lien non retiré — connecté ?",
  localOnlyNote:
    "Pas connecté — cet appareil seulement. Rejoindre sur le serveur demande un login.",
  onServerNote: "Groupe sur le serveur.",
  serverTableNote: "Table serveur absente — local seulement.",
  addRoute: "Ajouter une route",
  keepRoute: "Garder",
  keepName: "Garder seulement le nom",
  lastRidden: (when) => `dernier ${when}`,
  renameTour: "Renommer",
  searchTours: "Chercher une sortie",
  sortRecent: "Récent",
  sortDistance: "Longueur",
  sortName: "Nom",
  inviteFriends: "Emmener des amis",
  goRide: "On y va",
  mappeKicker: "Mappe",
  addRouteHint:
    "Nom + départ (GPS, sinon dernier centre carte, sinon sans épingle) — sans trace inventée. GPX reste optionnel.",
  routeName: "Nom de la route",
  startGps: "Départ : GPS si autorisé — sinon dernier centre carte, sinon sans épingle.",
  startNone: "Départ : pas encore d’épingle — ouvre GPS ou la carte.",
  startFromGps: (coords) => `Départ : ta position (${coords})`,
  startFromMap: (coords) => `Départ : dernier centre carte (${coords})`,
  startPin: (lat, lng) => `Départ : ${lat}°N, ${lng}°E`,
  savedNamed: (name) => `Enregistré : ${name}`,
  intoMappe: "Mettre dans Die Mappe",
  cancel: "Annuler",
  importGpx: "Importer GPX",
  tourKicker: "Sortie",
  catalogTag: "Catalogue",
  riddenWith: (name) => `roulé avec ${name}`,
  trackLocal: "La trace est locale. Sync entre tes appareils.",
  noTrackMappe: "Pas encore de trace — seulement l’entrée dans Die Mappe.",
  inCollections: (names) => `Dans ${names}`,
  addToCollection: "Ajouter à une collection",
  collectionAdded: "Ajouté à la collection",
  visibility: "Partage",
  shareOut: "Partager",
  privateNote: "Note privée",
  notePlaceholder: "Rien que pour toi — pas une Stimme.",
  honestyCatalog:
    "La sortie catalogue est déjà partagée. Partager rend ta sortie partageable — le lien montre nom et stats, pas de trace privée en plus.",
  honestyTrack:
    "Partager crée un lien. Le lien contient une trace simplifiée (coordonnées), pas seulement le nom. Elle n'apparaît sur la carte qu'après 3 voix en 14 jours — sinon elle redevient privée. Revenir en privé retire la sortie des filtres et enregistre le retrait sur le serveur si tu es connecté. Sans login, ça ne vaut que dans ce navigateur.",
  honestyNoTrack:
    "Partager crée un lien avec nom et stats — sans trace, parce qu’aucune n’est enregistrée.",
  linkNoTrackLong:
    "Lien sans trace — trop long pour l’URL. Nom et stats, pas de GPS.",
  linkHasTrack: "Le lien contient une trace simplifiée.",
  linkNoTrack: "Lien sans trace — nom et stats.",
};

const IT: PlatzCopy = {
  inviteHint:
    "Invitare condivide il link. I tuoi gruppi restano — non un feed. Amici sulla mappa solo nell’app, dopo opt-in.",
  pickTour: "Scegli un’uscita",
  pickMine: "Le mie uscite",
  pickNearby: "Uscite vicine",
  nearbyNeedGps:
    "Senza posizione niente uscite vicine — prendi una tua o l’ultima mappa.",
  nearbyFromMap: "Vicino è dall’ultima mappa, non dal GPS.",
  planAsGroup: "Pianifica la mia uscita come gruppo",
  planAsGroupHint:
    "Imposta il percorso sulla mappa, salvalo — poi compare nel selettore.",
  groupCreateReady: "Uscita pronta — crea il gruppo.",
  visPrivate: "Privato",
  visPublic: "Condiviso",
  visAll: "Tutti",
  meetingPlaceholder: "Punto d’incontro (opzionale)",
  createGroup: "Crea gruppo",
  needSignIn:
    "Accedi — altrimenti l’amico non vede il gruppo sul server.",
  needSharedTour: "Scegli prima un’uscita, o pianificane una tua.",
  created: (note) =>
    `Gruppo creato — invitare condivide il link${note ? ` — ${note}` : ""}`,
  localOnlyFoot:
    " — altrimenti il gruppo resta su questo dispositivo. L’amico non ti vede.",
  emptyPublic: "Nessun gruppo pubblico.",
  emptyPrivate: "Nessun gruppo privato in questo filtro.",
  emptyAll: "Ancora nessun gruppo. Invitare condivide il link.",
  host: "Organizzatore",
  guest: "Ospite",
  you: "Tu",
  selfSuffix: " · tu",
  along: (n) => `${n} con`,
  onServer: "sul server",
  onDevice: "solo su questo dispositivo",
  invite: "Invita",
  dissolve: "Sciogli",
  leave: "Esci",
  copyLink: "Copia link",
  copyCode: "Copia codice",
  copiedCode: "Codice copiato. Gruppo in elenco: entra con quello.",
  copiedInvite:
    "Link copiato. Chi ce l’ha può entrare finché il gruppo è aperto.",
  makePrivate: "Rendi privato",
  makePublic: "Mostra sul Platz",
  listedNote: "In elenco sul Platz — bastano link o codice.",
  unlistedNote: "Solo link — non sul Platz.",
  pinsOff: "Amici sulla mappa · off",
  pinsHud: "Amici solo in uscita",
  shareInRide: "Condividi in uscita",
  pinsHint: "Solo in uscita, non sulla mappa pubblica.",
  joinPrivateCode: "Privato — solo il link di invito. Niente codice da copiare.",
  friendN: (n) => `Amico ${n}`,
  extendHour: "Prolunga finestra",
  extend30m: "+30 min",
  extend1h: "+1 ora",
  extend2h: "+2 ore",
  extendCustomEnd: "Altra fine…",
  extendCapHint: "Al massimo fino a adesso + 12 ore.",
  extendInvalid: "Orario fuori dal limite.",
  windowExtended: "Finestra prolungata.",
  join: "Entra",
  joined: (title) => `Dentro: ${title}`,
  joinWithLink: "Collega",
  joinLocalCta: "Tieni su questo dispositivo",
  joinUnsignedHint: "Senza accesso l’host non ti vede.",
  joinSignInFirst: "Accedi — altrimenti l’host non ti vede",
  joinField: "Link o codice a 6 caratteri",
  more: "Altro",
  timeTapHint: "Tocca per modificare",
  shareLink: "Condividi link",
  joinCodeField: "Codice",
  joinHint:
    "Incolla il link di invito da WhatsApp o Messages, oppure il codice a 6 caratteri di un gruppo in elenco. Il privato serve ancora il link di invito.",
  joinEmpty: "Manca link o codice.",
  joinInvalid: "Link o codice non valido.",
  joinExpired: "Finestra chiusa — il link non vale più.",
  joinClosed: "Il gruppo è stato chiuso.",
  joinUnknown:
    "Nessun link aperto. Senza accesso resta su questo dispositivo; altrimenti incolla il link di invito.",
  startLabel: "Partenza",
  startNow: "Ora",
  startIn1h: "Tra 1 h",
  startToday18: "Oggi 18:00",
  startTomorrow10: "Domani 10:00",
  startCustom: "Altro orario…",
  durationLabel: "Durata",
  durationCustom: "Altro…",
  durationHoursHint: "Ore (0,25–12)",
  windowCapHint: "Partenza fino a 14 giorni. Durata da 15 min a 12 ore.",
  pinsOn: "Amici sulla mappa · on",
  collectionsHint:
    "Crea nella scheda. Si condividono solo uscite condivise o di catalogo — il GPX privato resta fuori.",
  shareTitle: (title) => `Uscire insieme: ${title}`,
  shareMeet: (point) => `Ritrovo: ${point}`,
  shareProfile: (url) => `Il mio profilo: ${url}`,
  shareVisPublic:
    "Condiviso: bastano link o codice. Il gruppo è sul Platz e come pin di ritrovo sulla mappa.",
  shareVisPrivate:
    "Privato: solo chi ha questo link può entrare. Niente elenco pubblico.",
  whenClosed: (wd, hm) => `chiuso — ${wd} ${hm}`,
  whenToday: (hm, dur) => `oggi ${hm} · ${dur}`,
  whenTomorrow: (hm, dur) => `domani ${hm} · ${dur}`,
  whenOther: (wd, hm, dur) => `${wd} ${hm} · ${dur}`,
  mappeEmpty: "Ancora nessuna uscita — tieni o importa un GPX.",
  mappeEmptyTitle: "Ancora nessuna linea",
  noTrackLabel: "Nessuna traccia",
  loopTag: "Anello",
  sourceImport: "Import",
  sourcePlanned: "Pianificato",
  sourceRecorded: "Registrato",
  startAwayKm: (km) => `${km} km fino al via`,
  mappeFilterEmpty: "Nessuna uscita in questo filtro.",
  showAll: "Mostra tutti",
  keepOnMap: "Segna sulla mappa",
  showOnMap: "Sulla mappa",
  removeFromMappe: "Togli dalla Mappe",
  shared: "condiviso",
  privateTour: "privato",
  openInApp: "Apri nell’app",
  joinOnDevice:
    " — Tieni nell’app. Senza accesso l’host non ti vede.",
  stimmenTitle: "Stimmen",
  stimmenEmpty:
    "Ancora nessuna Stimme sulle tue uscite. Dopo la condivisione gli altri possono scrivere.",
  stimmeUntitled: "Voce",
  pending: "In revisione",
  collectionsTitle: "Raccolte",
  collectionName: "Nome della raccolta",
  collectionCreate: "Crea",
  collectionCreated: "Raccolta creata",
  collectionEmpty: "Ancora nessuna raccolta — creala nella scheda di un’uscita.",
  collectionTours: (n) => (n === 1 ? "1 uscita" : `${n} uscite`),
  gpxNoTrack: "GPX senza traccia",
  gpxUnreadable: "GPX illeggibile",
  gpxImported: (name) => `Importato: ${name}`,
  joinNotOnServer: (note) =>
    `Non sul server — ${note} Accedi sotto Profilo, poi riapri il link. Altrimenti l’host non ti vede.`,
  joinOk: (title, note) =>
    `Dentro: ${title}${note ? ` — ${note}` : ""}. Chi ha il link può entrare finché il gruppo è aperto.`,
  shareCopied: "Copiato",
  share: "Condividi",
  shareEmpty: "Raccolta vuota — aggiungi prima le uscite.",
  shareNoPublic:
    "Nessuna uscita condivisa o catalogo nella raccolta. Il GPX privato resta fuori.",
  shareTooBig: "Raccolta troppo grande per uno share URL — meno uscite.",
  shareRevoke: "Revoca link server",
  shareRevokeFail: "Link non revocato — sei dentro?",
  localOnlyNote:
    "Non connesso — solo questo dispositivo. Entrare sul server richiede il login.",
  onServerNote: "Gruppo sul server.",
  serverTableNote: "Tabella server assente — solo locale.",
  addRoute: "Aggiungi una route",
  keepRoute: "Tieni",
  keepName: "Tieni solo il nome",
  lastRidden: (when) => `ultimo ${when}`,
  renameTour: "Rinomina",
  searchTours: "Cerca un percorso",
  sortRecent: "Recenti",
  sortDistance: "Lunghezza",
  sortName: "Nome",
  inviteFriends: "Porta gli amici",
  goRide: "Si parte",
  mappeKicker: "Mappe",
  addRouteHint:
    "Nome + partenza (GPS, altrimenti ultimo centro mappa, altrimenti senza pin) — senza traccia inventata. GPX resta opzionale.",
  routeName: "Nome della route",
  startGps: "Partenza: GPS se permesso — altrimenti ultimo centro mappa, altrimenti senza pin.",
  startNone: "Partenza: ancora senza pin — apri GPS o la mappa.",
  startFromGps: (coords) => `Partenza: la tua posizione (${coords})`,
  startFromMap: (coords) => `Partenza: ultimo centro mappa (${coords})`,
  startPin: (lat, lng) => `Partenza: ${lat}°N, ${lng}°E`,
  savedNamed: (name) => `Salvato: ${name}`,
  intoMappe: "Metti in Die Mappe",
  cancel: "Annulla",
  importGpx: "Importa GPX",
  tourKicker: "Uscita",
  catalogTag: "Catalogo",
  riddenWith: (name) => `percorsa con ${name}`,
  trackLocal: "La traccia è locale. Sync tra i tuoi dispositivi.",
  noTrackMappe: "Ancora nessuna traccia — solo la voce in Die Mappe.",
  inCollections: (names) => `In ${names}`,
  addToCollection: "Aggiungi alla raccolta",
  collectionAdded: "Aggiunto alla raccolta",
  visibility: "Condivisione",
  shareOut: "Condividi",
  privateNote: "Nota privata",
  notePlaceholder: "Solo per te — non una Stimme.",
  honestyCatalog:
    "L’uscita catalogo è già condivisa. Condividere rende la tua uscita condivisibile — il link mostra nome e stats, nessuna traccia privata in più.",
  honestyTrack:
    "Condividere crea un link. Il link contiene una traccia semplificata (coordinate), non solo il nome. Compare sulla mappa solo dopo 3 voci in 14 giorni — altrimenti torna privata. Tornare a privato toglie l’uscita dai filtri e salva la revoca sul server se sei dentro. Senza login vale solo in questo browser.",
  honestyNoTrack:
    "Condividere crea un link con nome e stats — senza traccia, perché non ne è salvata nessuna.",
  linkNoTrackLong:
    "Link senza traccia — troppo lungo per l’URL. Nome e stats, niente GPS.",
  linkHasTrack: "Il link contiene una traccia semplificata.",
  linkNoTrack: "Link senza traccia — nome e stats.",
};

const NL: PlatzCopy = {
  inviteHint:
    "Uitnodigen deelt de link. Je groepen blijven — geen feed. Vrienden op de kaart alleen in de app, na opt-in.",
  pickTour: "Tocht kiezen",
  pickMine: "Mijn tochten",
  pickNearby: "Tochten in de buurt",
  nearbyNeedGps:
    "Zonder locatie geen tochten in de buurt — kies een eigen of de laatste kaart.",
  nearbyFromMap: "Buurt van de laatste kaart, niet van gps.",
  planAsGroup: "Eigen tocht als groep plannen",
  planAsGroupHint:
    "Zet de route op de kaart, bewaar hem — daarna staat hij in de kiezer.",
  groupCreateReady: "Tocht staat klaar — groep aanmaken.",
  visPrivate: "Privé",
  visPublic: "Gedeeld",
  visAll: "Alle",
  meetingPlaceholder: "Trefpunt (optioneel)",
  createGroup: "Groep aanmaken",
  needSignIn:
    "Aanmelden — anders ziet je vriend de groep niet op de server.",
  needSharedTour: "Kies eerst een tocht, of plan er zelf een.",
  created: (note) =>
    `Groep aangemaakt — uitnodigen deelt de link${note ? ` — ${note}` : ""}`,
  localOnlyFoot:
    " — anders blijft de groep op dit apparaat. Je vriend ziet je niet.",
  emptyPublic: "Geen open groepen.",
  emptyPrivate: "Geen privégroepen in dit filter.",
  emptyAll: "Nog geen groep. Uitnodigen deelt de link.",
  host: "Host",
  guest: "Gast",
  you: "Jij",
  selfSuffix: " · jij",
  along: (n) => `${n} mee`,
  onServer: "op de server",
  onDevice: "alleen op dit apparaat",
  invite: "Uitnodigen",
  dissolve: "Opheffen",
  leave: "Verlaten",
  copyLink: "Link kopiëren",
  copyCode: "Code kopiëren",
  copiedCode: "Code gekopieerd. Open groep: daarmee meedoen.",
  copiedInvite:
    "Link gekopieerd. Wie hem heeft, kan meedoen zolang de groep open is.",
  makePrivate: "Privé maken",
  makePublic: "Op Platz zetten",
  listedNote: "Op Platz gezet — link of code volstaat.",
  unlistedNote: "Alleen via link — niet op Platz.",
  pinsOff: "Vrienden op de kaart · uit",
  pinsHud: "Vrienden alleen tijdens de rit",
  shareInRide: "Delen tijdens de rit",
  pinsHint: "Alleen tijdens de rit, niet op de openbare kaart.",
  joinPrivateCode:
    "Privé — alleen de uitnodigingslink. Geen code om over te typen.",
  friendN: (n) => `Vriend ${n}`,
  extendHour: "Venster verlengen",
  extend30m: "+30 min",
  extend1h: "+1 uur",
  extend2h: "+2 uur",
  extendCustomEnd: "Ander einde…",
  extendCapHint: "Maximaal tot nu + 12 uur.",
  extendInvalid: "Tijd valt buiten het kader.",
  windowExtended: "Venster verlengd.",
  join: "Meedoen",
  joined: (title) => `Erbij: ${title}`,
  joinWithLink: "Verbinden",
  joinLocalCta: "Op dit apparaat onthouden",
  joinUnsignedHint: "Zonder aanmelden ziet de host je niet.",
  joinSignInFirst: "Aanmelden — anders ziet de host je niet",
  joinField: "Link of 6-tekencode",
  more: "Meer",
  timeTapHint: "Tik om te wijzigen",
  shareLink: "Link delen",
  joinCodeField: "Code",
  joinHint:
    "Plak de uitnodigingslink uit WhatsApp of Berichten, of typ de 6-tekencode van een open groep. Privé heeft nog de uitnodigingslink nodig.",
  joinEmpty: "Link of code ontbreekt.",
  joinInvalid: "Geen geldige link of code.",
  joinExpired: "Venster dicht — de link geldt niet meer.",
  joinClosed: "De groep is opgeheven.",
  joinUnknown:
    "Geen open link. Zonder login blijft dit op dit apparaat; anders de uitnodigingslink plakken.",
  startLabel: "Start",
  startNow: "Nu",
  startIn1h: "Over 1 h",
  startToday18: "Vandaag 18:00",
  startTomorrow10: "Morgen 10:00",
  startCustom: "Andere tijd…",
  durationLabel: "Duur",
  durationCustom: "Anders…",
  durationHoursHint: "Uren (0,25–12)",
  windowCapHint: "Start tot 14 dagen vooruit. Duur 15 min tot 12 uur.",
  pinsOn: "Vrienden op de kaart · aan",
  collectionsHint:
    "Aanmaken in het dossier. Delen alleen met gedeelde of catalogustochten — privé-GPX blijft buiten.",
  shareTitle: (title) => `Samen eruit: ${title}`,
  shareMeet: (point) => `Trefpunt: ${point}`,
  shareProfile: (url) => `Mijn profiel: ${url}`,
  shareVisPublic:
    "Gedeeld: link of code volstaat. De groep staat op Platz en als trefpunt-pin op de kaart.",
  shareVisPrivate:
    "Privé: alleen wie deze link heeft, kan meedoen. Niet openbaar gezet.",
  whenClosed: (wd, hm) => `dicht — ${wd} ${hm}`,
  whenToday: (hm, dur) => `vandaag ${hm} · ${dur}`,
  whenTomorrow: (hm, dur) => `morgen ${hm} · ${dur}`,
  whenOther: (wd, hm, dur) => `${wd} ${hm} · ${dur}`,
  mappeEmpty: "Nog geen tochten — bewaren of GPX importeren.",
  mappeEmptyTitle: "Nog geen lijn",
  noTrackLabel: "Geen track",
  loopTag: "Ronde",
  sourceImport: "Import",
  sourcePlanned: "Gepland",
  sourceRecorded: "Opgenomen",
  startAwayKm: (km) => `${km} km naar de start`,
  mappeFilterEmpty: "Geen tochten in dit filter.",
  showAll: "Alles tonen",
  keepOnMap: "Op de kaart bewaren",
  showOnMap: "Toon op de kaart",
  removeFromMappe: "Uit Die Mappe halen",
  shared: "gedeeld",
  privateTour: "privé",
  openInApp: "Openen in de app",
  joinOnDevice:
    " — In de app onthouden. Zonder aanmelden ziet de host je niet.",
  stimmenTitle: "Stimmen",
  stimmenEmpty:
    "Nog geen Stimmen bij je tochten. Na delen kunnen anderen schrijven.",
  stimmeUntitled: "Stem",
  pending: "In beoordeling",
  collectionsTitle: "Verzamelingen",
  collectionName: "Naam van de verzameling",
  collectionCreate: "Aanmaken",
  collectionCreated: "Verzameling aangemaakt",
  collectionEmpty:
    "Nog geen verzameling — in het dossier bij een tocht aanmaken.",
  collectionTours: (n) => (n === 1 ? "1 tocht" : `${n} tochten`),
  gpxNoTrack: "GPX zonder track",
  gpxUnreadable: "GPX kon niet worden gelezen",
  gpxImported: (name) => `Geïmporteerd: ${name}`,
  joinNotOnServer: (note) =>
    `Niet op de server — ${note} Onder Profiel aanmelden, daarna de link opnieuw openen. Anders ziet de host je niet.`,
  joinOk: (title, note) =>
    `Erbij: ${title}${note ? ` — ${note}` : ""}. Wie de link heeft, kan meedoen zolang de groep open is.`,
  shareCopied: "Gekopieerd",
  share: "Delen",
  shareEmpty: "Verzameling is leeg — eerst tochten toevoegen.",
  shareNoPublic:
    "Geen gedeelde of catalogustocht in de verzameling. Privé-GPX blijft buiten.",
  shareTooBig: "Verzameling te groot voor URL-share — minder tochten kiezen.",
  shareRevoke: "Server-link intrekken",
  shareRevokeFail: "Link kon niet worden ingetrokken — aangemeld?",
  localOnlyNote:
    "Niet aangemeld — alleen op dit apparaat. Meedoen op de server vraagt login.",
  onServerNote: "Groep op de server.",
  serverTableNote: "Servertabel ontbreekt — alleen lokaal.",
  addRoute: "Route toevoegen",
  keepRoute: "Bewaren",
  keepName: "Alleen de naam bewaren",
  lastRidden: (when) => `laatst ${when}`,
  renameTour: "Hernoemen",
  searchTours: "Tocht zoeken",
  sortRecent: "Recent",
  sortDistance: "Lengte",
  sortName: "Naam",
  inviteFriends: "Vrienden meenemen",
  goRide: "Rijden maar",
  mappeKicker: "Mappe",
  addRouteHint:
    "Naam + start (GPS, anders laatste kaartmidden, anders zonder pin) — zonder verzonnen track. GPX blijft optioneel.",
  routeName: "Naam van de route",
  startGps:
    "Start: GPS als toegestaan — anders laatste kaartmidden, anders zonder pin.",
  startNone: "Start: nog zonder pin — GPS of kaart openen.",
  startFromGps: (coords) => `Start: jouw locatie (${coords})`,
  startFromMap: (coords) => `Start: laatste kaartmidden (${coords})`,
  startPin: (lat, lng) => `Start: ${lat}°N, ${lng}°E`,
  savedNamed: (name) => `Opgeslagen: ${name}`,
  intoMappe: "In Die Mappe leggen",
  cancel: "Annuleren",
  importGpx: "GPX importeren",
  tourKicker: "Tocht",
  catalogTag: "Catalogus",
  riddenWith: (name) => `gereden met ${name}`,
  trackLocal: "Track ligt lokaal. Sync tussen je apparaten.",
  noTrackMappe: "Nog geen track — alleen het item in Die Mappe.",
  inCollections: (names) => `In ${names}`,
  addToCollection: "Naar verzameling",
  collectionAdded: "Aan verzameling toegevoegd",
  visibility: "Delen",
  shareOut: "Delen",
  privateNote: "Privénotitie",
  notePlaceholder: "Alleen voor jou — geen Stimme.",
  honestyCatalog:
    "Catalogustocht is al gedeeld. Delen maakt jouw tocht deelbaar — de link toont naam en stats, geen extra privé-track.",
  honestyTrack:
    "Delen maakt een link. De link bevat een vereenvoudigd spoor (coördinaten), niet alleen de naam. Op de kaart komt hij pas na 3 stemmen in 14 dagen — anders weer privé. Terug naar privé haalt de tocht uit filters en bewaart de intrekking op de server als je bent aangemeld. Zonder login geldt het alleen in deze browser.",
  honestyNoTrack:
    "Delen maakt een link met naam en stats — zonder track, omdat er geen is opgeslagen.",
  linkNoTrackLong:
    "Link zonder spoor — te lang voor de URL. Naam en stats, geen GPS.",
  linkHasTrack: "Link bevat een vereenvoudigd spoor.",
  linkNoTrack: "Link zonder track — naam en stats.",
};

const BY_LANG: Record<ChromeLang, PlatzCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function platzCopy(lang: ChromeLang): PlatzCopy {
  return BY_LANG[lang];
}

const NOTE_MAP: Record<string, "localOnlyNote" | "onServerNote" | "serverTableNote"> =
  {
    [LOCAL_ONLY_DE]: "localOnlyNote",
    [ON_SERVER_DE]: "onServerNote",
    [SERVER_TABLE_DE]: "serverTableNote",
  };

/** Map known DE store notes/errors to chrome. Unknown strings stay as-is. */
export function platzNote(
  raw: string | null | undefined,
  lang: ChromeLang,
): string {
  if (!raw) return "";
  const g = platzCopy(lang);
  const noteKey = NOTE_MAP[raw];
  if (noteKey) return g[noteKey];
  if (raw === NEED_SIGNIN_DE) return g.needSignIn;
  if (raw === NEED_TOUR_DE) return g.needSharedTour;
  if (raw === LISTED_DE || raw === LISTED_CODE_DE) return g.listedNote;
  if (raw === UNLISTED_DE) return g.unlistedNote;
  if (raw === WINDOW_EXTENDED_DE) return g.windowExtended;
  if (raw === EXTEND_INVALID_DE) return g.extendInvalid;
  if (raw === PRIVATE_CODE_DE) return g.joinPrivateCode;
  if (raw.startsWith("Privat — nur mit Einladungslink")) {
    return g.joinPrivateCode;
  }
  if (raw === JOIN_EXPIRED_DE || raw.startsWith("Fenster zu")) {
    return g.joinExpired;
  }
  if (raw === JOIN_CLOSED_DE) return g.joinClosed;
  if (raw === JOIN_NEED_LINK_DE || raw === JOIN_BAD_LINK_DE) {
    return g.joinPrivateCode;
  }
  if (raw === JOIN_HOST_DE || raw === JOIN_HOST_DE_ROLE) return g.joinSignInFirst;
  if (raw === JOIN_UNKNOWN_DE || raw === JOIN_CODE_LEN_DE) return g.joinUnknown;
  return raw;
}

export function formatPlatzGroupWhen(
  startIso: string,
  endIso: string,
  lang: ChromeLang,
  now = new Date(),
  timeZone = "Europe/Berlin",
): string {
  const g = platzCopy(lang);
  const start = new Date(startIso);
  const end = new Date(endIso);
  if (!Number.isFinite(start.getTime()) || !Number.isFinite(end.getTime())) {
    return "";
  }
  const hours = (end.getTime() - start.getTime()) / 3_600_000;
  const dur = formatRideGroupDurationHours(hours, lang === "en" ? "." : ",");
  const locale = chromeDateLocale(lang);
  const fmt = new Intl.DateTimeFormat(locale, {
    timeZone,
    weekday: "short",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
  const parts = Object.fromEntries(
    fmt.formatToParts(start).map((p) => [p.type, p.value]),
  );
  const wd = (parts.weekday || "").replace(".", "");
  const hm = `${parts.hour || "00"}:${parts.minute || "00"}`;
  if (now.getTime() > end.getTime()) return g.whenClosed(wd, hm);
  const dayFmt = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  const nowDay = dayFmt.format(now);
  const startDay = dayFmt.format(start);
  const tomorrowDay = dayFmt.format(
    new Date(now.getTime() + 24 * 60 * 60 * 1000),
  );
  if (startDay === nowDay) return g.whenToday(hm, dur);
  if (startDay === tomorrowDay) return g.whenTomorrow(hm, dur);
  return g.whenOther(wd, hm, dur);
}

export function platzShareHonesty(
  catalog: boolean,
  hasTrack: boolean,
  lang: ChromeLang,
): string {
  const g = platzCopy(lang);
  if (catalog && !hasTrack) return g.honestyCatalog;
  if (hasTrack) return g.honestyTrack;
  return g.honestyNoTrack;
}
