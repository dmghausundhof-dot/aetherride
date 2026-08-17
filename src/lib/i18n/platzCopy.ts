import type { ChromeLang } from "./chromeLang";
import { chromeDateLocale } from "./chromeLang";

/** Exact DE store notes — map in the UI, do not import the store here. */
const LOCAL_ONLY_DE =
  "Nicht eingeloggt — nur auf diesem Gerät. Join auf dem Server braucht Login.";
const ON_SERVER_DE = "Gruppe auf dem Server.";
const SERVER_TABLE_DE = "Server-Tabelle fehlt — nur lokal.";
const NEED_SIGNIN_DE =
  "Anmelden — sonst sieht der Freund die Gruppe nicht auf dem Server.";
const NEED_TOUR_DE =
  "Gruppe nur an freigegebener oder Katalog-Tour. Private GPX bleibt privat.";
const LISTED_DE =
  "Auf dem Platz gelistet — wer den Link hat, kann beitreten.";
const UNLISTED_DE = "Nur per Link — nicht auf dem Platz.";

export type PlatzCopy = {
  inviteHint: string;
  pickTour: string;
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
  copiedInvite: string;
  makePrivate: string;
  makePublic: string;
  listedNote: string;
  unlistedNote: string;
  pinsOff: string;
  pinsHud: string;
  pinsHint: string;
  join: string;
  joined: (title: string) => string;
  joinWithLink: string;
  joinLocalCta: string;
  joinUnsignedHint: string;
  joinField: string;
  joinHint: string;
  joinEmpty: string;
  joinInvalid: string;
  startLabel: string;
  startNow: string;
  startIn1h: string;
  startToday18: string;
  startTomorrow10: string;
  durationLabel: string;
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
  mappeFilterEmpty: string;
  shared: string;
  privateTour: string;
  openInApp: string;
  joinOnDevice: string;
  stimmenTitle: string;
  stimmenEmpty: string;
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
    "Einladen teilt den Link. Deine Gruppen bleiben. Freigegeben listet zusätzlich offene Gruppen auf dem Platz — kein Feed. Freunde auf der Karte nur in der App, nach Opt-in.",
  pickTour: "Tour wählen",
  visPrivate: "Privat",
  visPublic: "Freigegeben",
  visAll: "Alle",
  meetingPlaceholder: "Treffpunkt (optional)",
  createGroup: "Gruppe anlegen",
  needSignIn:
    "Anmelden — sonst sieht der Freund die Gruppe nicht auf dem Server.",
  needSharedTour:
    "Gruppe nur an freigegebener oder Katalog-Tour. Private GPX bleibt privat.",
  created: (note) =>
    `Gruppe angelegt — Einladen teilt den Link${note ? ` — ${note}` : ""}`,
  localOnlyFoot:
    " — sonst bleibt die Gruppe auf diesem Gerät. Der Freund sieht dich nicht.",
  emptyPublic: "Keine offenen Gruppen.",
  emptyPrivate: "Keine privaten Gruppen in diesem Filter.",
  emptyAll: "Noch keine Gruppe. Einladen teilt den Link.",
  host: "Host",
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
  copiedInvite:
    "Link kopiert. Wer ihn hat, kann beitreten, solange die Gruppe offen ist.",
  makePrivate: "Privat machen",
  makePublic: "Auf dem Platz listen",
  listedNote: "Auf dem Platz gelistet — wer den Link hat, kann beitreten.",
  unlistedNote: "Nur per Link — nicht auf dem Platz.",
  pinsOff: "Freunde auf der Karte · aus",
  pinsHud: "Freunde nur während der Fahrt",
  pinsHint: "Nur während der Fahrt, nicht auf der öffentlichen Karte.",
  join: "Beitreten",
  joined: (title) => `Dabei: ${title}`,
  joinWithLink: "Mit Link beitreten",
  joinLocalCta: "Auf diesem Gerät merken",
  joinUnsignedHint: "Ohne Anmeldung sieht der Host dich nicht.",
  joinField: "Einladungslink",
  joinHint:
    "Link aus WhatsApp oder Messages einfügen. Privat braucht den Einladungslink — kein Code zum Abtippen.",
  joinEmpty: "Link fehlt.",
  joinInvalid: "Kein gültiger Einladungslink.",
  startLabel: "Start",
  startNow: "Jetzt",
  startIn1h: "In 1 h",
  startToday18: "Heute 18:00",
  startTomorrow10: "Morgen 10:00",
  durationLabel: "Dauer",
  pinsOn: "Freunde auf der Karte · an",
  collectionsHint:
    "Anlegen unter Freigeben. Teilen nur mit freigegebenen oder Katalog-Touren — private GPX bleibt draußen.",
  shareTitle: (title) => `Zusammen raus: ${title}`,
  shareMeet: (point) => `Treffpunkt: ${point}`,
  shareProfile: (url) => `Mein Profil: ${url}`,
  shareVisPublic:
    "Freigegeben: wer den Link hat, kann beitreten. Die Gruppe kann unter Freigegeben stehen.",
  shareVisPrivate:
    "Privat: nur wer diesen Link hat, kann beitreten. Nicht gelistet.",
  whenClosed: (wd, hm) => `zu — ${wd} ${hm}`,
  whenToday: (hm, dur) => `heute ${hm} · ${dur}`,
  whenTomorrow: (hm, dur) => `morgen ${hm} · ${dur}`,
  whenOther: (wd, hm, dur) => `${wd} ${hm} · ${dur}`,
  mappeEmpty: "Noch keine eigenen Strecken — Route hinzufügen.",
  mappeFilterEmpty: "Keine Touren in diesem Filter.",
  shared: "freigegeben",
  privateTour: "privat",
  openInApp: "In der App öffnen",
  joinOnDevice:
    " — In der App merken. Ohne Anmeldung sieht der Host dich nicht.",
  stimmenTitle: "Stimmen",
  stimmenEmpty:
    "Noch keine Stimmen zu deinen Touren. Nach Freigabe können andere schreiben.",
  pending: "In Prüfung",
  collectionsTitle: "Sammlungen",
  collectionName: "Name der Sammlung",
  collectionCreate: "Anlegen",
  collectionCreated: "Sammlung angelegt",
  collectionEmpty: "Noch keine Sammlung — unter Freigeben bei einer Tour anlegen.",
  collectionTours: (n) => (n === 1 ? "1 Tour" : `${n} Touren`),
  gpxNoTrack: "GPX ohne Track",
  gpxUnreadable: "GPX konnte nicht gelesen werden",
  gpxImported: (name) => `Importiert: ${name}`,
  joinNotOnServer: (note) =>
    `Nicht auf dem Server — ${note} Unter Profil anmelden, dann den Link nochmal öffnen. Sonst sieht der Host dich nicht.`,
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
  addRouteHint:
    "Name + Start (GPS, sonst letzte Kartenmitte, sonst ohne Pin) — ohne erfundenen Track. GPX bleibt optional.",
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
    "Freigeben erzeugt einen Link. Der Link enthält eine vereinfachte Spur (Koordinaten), nicht nur den Namen. Zurück auf Privat nimmt die Tour aus Filtern und speichert den Widerruf auf dem Server, wenn du eingeloggt bist. Ohne Login gilt er nur in diesem Browser.",
  honestyNoTrack:
    "Freigeben erzeugt einen Link mit Name und Stats — ohne Track, weil keiner gespeichert ist.",
  linkNoTrackLong:
    "Link ohne Spur — zu lang für die URL. Name und Stats, kein GPS.",
  linkHasTrack: "Link enthält eine vereinfachte Spur.",
  linkNoTrack: "Link ohne Track — Name und Stats.",
};

const EN: PlatzCopy = {
  inviteHint:
    "Invite shares the link. Your groups stay. Shared also lists open groups on Platz — not a feed. Friends on the map only in the app, after opt-in.",
  pickTour: "Pick a tour",
  visPrivate: "Private",
  visPublic: "Shared",
  visAll: "All",
  meetingPlaceholder: "Meeting point (optional)",
  createGroup: "Create group",
  needSignIn: "Sign in — otherwise your friend will not see the group on the server.",
  needSharedTour:
    "Groups only on a shared or catalogue tour. Private GPX stays private.",
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
  copiedInvite:
    "Link copied. Whoever has it can join while the group is open.",
  makePrivate: "Make private",
  makePublic: "List on Platz",
  listedNote: "Listed on Platz — whoever has the link can join.",
  unlistedNote: "Link only — not listed on Platz.",
  pinsOff: "Friends on the map · off",
  pinsHud: "Friends only while riding",
  pinsHint: "Only while riding, not on the public map.",
  join: "Join",
  joined: (title) => `In: ${title}`,
  joinWithLink: "Join with a link",
  joinLocalCta: "Save on this device",
  joinUnsignedHint: "Without signing in, the host cannot see you.",
  joinField: "Invite link",
  joinHint:
    "Paste the link from WhatsApp or Messages. Private groups need the invitation link — no code to type.",
  joinEmpty: "Link missing.",
  joinInvalid: "Not a valid invite link.",
  startLabel: "Start",
  startNow: "Now",
  startIn1h: "In 1 h",
  startToday18: "Today 18:00",
  startTomorrow10: "Tomorrow 10:00",
  durationLabel: "Duration",
  pinsOn: "Friends on the map · on",
  collectionsHint:
    "Create under Share. Sharing only includes released or catalogue tours — private GPX stays out.",
  shareTitle: (title) => `Ride together: ${title}`,
  shareMeet: (point) => `Meeting point: ${point}`,
  shareProfile: (url) => `My profile: ${url}`,
  shareVisPublic:
    "Shared: whoever has the link can join. The group can sit under Shared.",
  shareVisPrivate:
    "Private: only whoever has this link can join. Not listed publicly.",
  whenClosed: (wd, hm) => `closed — ${wd} ${hm}`,
  whenToday: (hm, dur) => `today ${hm} · ${dur}`,
  whenTomorrow: (hm, dur) => `tomorrow ${hm} · ${dur}`,
  whenOther: (wd, hm, dur) => `${wd} ${hm} · ${dur}`,
  mappeEmpty: "No routes of your own yet — add a route.",
  mappeFilterEmpty: "No tours in this filter.",
  shared: "shared",
  privateTour: "private",
  openInApp: "Open in the app",
  joinOnDevice:
    " — Save in the app. Without signing in, the host cannot see you.",
  stimmenTitle: "Stimmen",
  stimmenEmpty:
    "No Stimmen on your tours yet. After you share, others can write.",
  pending: "In review",
  collectionsTitle: "Collections",
  collectionName: "Collection name",
  collectionCreate: "Create",
  collectionCreated: "Collection created",
  collectionEmpty: "No collection yet — create one under Share on a tour.",
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
    "Sharing creates a link. The link holds a simplified trace (coordinates), not just the name. Back to private drops the tour from filters and stores the revoke on the server if you are signed in. Without login it only holds in this browser.",
  honestyNoTrack:
    "Sharing creates a link with name and stats — no track, because none is stored.",
  linkNoTrackLong:
    "Link without a trace — too long for the URL. Name and stats, no GPS.",
  linkHasTrack: "Link includes a simplified trace.",
  linkNoTrack: "Link without a track — name and stats.",
};

const FR: PlatzCopy = {
  inviteHint:
    "Inviter partage le lien. Tes groupes restent. Partagé liste aussi les groupes ouverts sur le Platz — pas un fil. Amis sur la carte seulement dans l’appli, après opt-in.",
  pickTour: "Choisir une sortie",
  visPrivate: "Privé",
  visPublic: "Partagé",
  visAll: "Tous",
  meetingPlaceholder: "Point de rendez-vous (optionnel)",
  createGroup: "Créer le groupe",
  needSignIn:
    "Connecte-toi — sinon ton ami ne verra pas le groupe sur le serveur.",
  needSharedTour:
    "Groupe seulement sur une sortie partagée ou catalogue. Le GPX privé reste privé.",
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
  copiedInvite:
    "Lien copié. Qui l’a peut rejoindre tant que le groupe est ouvert.",
  makePrivate: "Rendre privé",
  makePublic: "Afficher sur le Platz",
  listedNote: "Listé sur Platz — qui a le lien peut rejoindre.",
  unlistedNote: "Lien seulement — pas sur Platz.",
  pinsOff: "Amis sur la carte · off",
  pinsHud: "Amis seulement pendant la sortie",
  pinsHint: "Seulement pendant la sortie, pas sur la carte publique.",
  join: "Rejoindre",
  joined: (title) => `Dedans : ${title}`,
  joinWithLink: "Rejoindre avec un lien",
  joinLocalCta: "Garder sur cet appareil",
  joinUnsignedHint: "Sans connexion, l’hôte ne te voit pas.",
  joinField: "Lien d’invitation",
  joinHint:
    "Colle le lien depuis WhatsApp ou Messages. Privé a besoin du lien d’invitation — pas de code à taper.",
  joinEmpty: "Lien manquant.",
  joinInvalid: "Lien d’invitation invalide.",
  startLabel: "Départ",
  startNow: "Maintenant",
  startIn1h: "Dans 1 h",
  startToday18: "Aujourd’hui 18:00",
  startTomorrow10: "Demain 10:00",
  durationLabel: "Durée",
  pinsOn: "Amis sur la carte · on",
  collectionsHint:
    "Créer sous Partager. Le partage ne prend que les sorties partagées ou catalogue — le GPX privé reste dehors.",
  shareTitle: (title) => `Sortir ensemble : ${title}`,
  shareMeet: (point) => `Rendez-vous : ${point}`,
  shareProfile: (url) => `Mon profil : ${url}`,
  shareVisPublic:
    "Partagé : qui a le lien peut rejoindre. Le groupe peut figurer sous Partagé.",
  shareVisPrivate:
    "Privé : seulement qui a ce lien peut rejoindre. Pas de listing public.",
  whenClosed: (wd, hm) => `fermé — ${wd} ${hm}`,
  whenToday: (hm, dur) => `aujourd’hui ${hm} · ${dur}`,
  whenTomorrow: (hm, dur) => `demain ${hm} · ${dur}`,
  whenOther: (wd, hm, dur) => `${wd} ${hm} · ${dur}`,
  mappeEmpty: "Pas encore de tes propres parcours — ajoute une route.",
  mappeFilterEmpty: "Pas de sorties dans ce filtre.",
  shared: "partagé",
  privateTour: "privé",
  openInApp: "Ouvrir dans l’app",
  joinOnDevice:
    " — Garder dans l’app. Sans connexion, l’hôte ne te voit pas.",
  stimmenTitle: "Stimmen",
  stimmenEmpty:
    "Pas encore de Stimmen sur tes sorties. Après partage, les autres peuvent écrire.",
  pending: "En relecture",
  collectionsTitle: "Collections",
  collectionName: "Nom de la collection",
  collectionCreate: "Créer",
  collectionCreated: "Collection créée",
  collectionEmpty: "Pas encore de collection — crée-en une sous Partager sur une sortie.",
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
    "Partager crée un lien. Le lien contient une trace simplifiée (coordonnées), pas seulement le nom. Revenir en privé retire la sortie des filtres et enregistre le retrait sur le serveur si tu es connecté. Sans login, ça ne vaut que dans ce navigateur.",
  honestyNoTrack:
    "Partager crée un lien avec nom et stats — sans trace, parce qu’aucune n’est enregistrée.",
  linkNoTrackLong:
    "Lien sans trace — trop long pour l’URL. Nom et stats, pas de GPS.",
  linkHasTrack: "Le lien contient une trace simplifiée.",
  linkNoTrack: "Lien sans trace — nom et stats.",
};

const IT: PlatzCopy = {
  inviteHint:
    "Invitare condivide il link. I tuoi gruppi restano. Condiviso elenca anche i gruppi aperti sul Platz — non un feed. Amici sulla mappa solo nell’app, dopo opt-in.",
  pickTour: "Scegli un’uscita",
  visPrivate: "Privato",
  visPublic: "Condiviso",
  visAll: "Tutti",
  meetingPlaceholder: "Punto d’incontro (opzionale)",
  createGroup: "Crea gruppo",
  needSignIn:
    "Accedi — altrimenti l’amico non vede il gruppo sul server.",
  needSharedTour:
    "Gruppo solo su un’uscita condivisa o catalogo. Il GPX privato resta privato.",
  created: (note) =>
    `Gruppo creato — invitare condivide il link${note ? ` — ${note}` : ""}`,
  localOnlyFoot:
    " — altrimenti il gruppo resta su questo dispositivo. L’amico non ti vede.",
  emptyPublic: "Nessun gruppo pubblico.",
  emptyPrivate: "Nessun gruppo privato in questo filtro.",
  emptyAll: "Ancora nessun gruppo. Invitare condivide il link.",
  host: "Host",
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
  copiedInvite:
    "Link copiato. Chi ce l’ha può entrare finché il gruppo è aperto.",
  makePrivate: "Rendi privato",
  makePublic: "Mostra sul Platz",
  listedNote: "In elenco sul Platz — chi ha il link può entrare.",
  unlistedNote: "Solo link — non sul Platz.",
  pinsOff: "Amici sulla mappa · off",
  pinsHud: "Amici solo in uscita",
  pinsHint: "Solo in uscita, non sulla mappa pubblica.",
  join: "Entra",
  joined: (title) => `Dentro: ${title}`,
  joinWithLink: "Entra con un link",
  joinLocalCta: "Tieni su questo dispositivo",
  joinUnsignedHint: "Senza accesso l’host non ti vede.",
  joinField: "Link d’invito",
  joinHint:
    "Incolla il link da WhatsApp o Messages. Il privato serve il link di invito — niente codice da digitare.",
  joinEmpty: "Manca il link.",
  joinInvalid: "Link d’invito non valido.",
  startLabel: "Partenza",
  startNow: "Ora",
  startIn1h: "Tra 1 h",
  startToday18: "Oggi 18:00",
  startTomorrow10: "Domani 10:00",
  durationLabel: "Durata",
  pinsOn: "Amici sulla mappa · on",
  collectionsHint:
    "Crea sotto Condividi. Si condividono solo uscite condivise o di catalogo — il GPX privato resta fuori.",
  shareTitle: (title) => `Uscire insieme: ${title}`,
  shareMeet: (point) => `Ritrovo: ${point}`,
  shareProfile: (url) => `Il mio profilo: ${url}`,
  shareVisPublic:
    "Condiviso: chi ha il link può entrare. Il gruppo può stare sotto Condiviso.",
  shareVisPrivate:
    "Privato: solo chi ha questo link può entrare. Niente elenco pubblico.",
  whenClosed: (wd, hm) => `chiuso — ${wd} ${hm}`,
  whenToday: (hm, dur) => `oggi ${hm} · ${dur}`,
  whenTomorrow: (hm, dur) => `domani ${hm} · ${dur}`,
  whenOther: (wd, hm, dur) => `${wd} ${hm} · ${dur}`,
  mappeEmpty: "Ancora nessun percorso tuo — aggiungi una route.",
  mappeFilterEmpty: "Nessuna uscita in questo filtro.",
  shared: "condiviso",
  privateTour: "privato",
  openInApp: "Apri nell’app",
  joinOnDevice:
    " — Tieni nell’app. Senza accesso l’host non ti vede.",
  stimmenTitle: "Stimmen",
  stimmenEmpty:
    "Ancora nessuna Stimme sulle tue uscite. Dopo la condivisione gli altri possono scrivere.",
  pending: "In revisione",
  collectionsTitle: "Raccolte",
  collectionName: "Nome della raccolta",
  collectionCreate: "Crea",
  collectionCreated: "Raccolta creata",
  collectionEmpty: "Ancora nessuna raccolta — creala sotto Condividi su un’uscita.",
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
    "Condividere crea un link. Il link contiene una traccia semplificata (coordinate), non solo il nome. Tornare a privato toglie l’uscita dai filtri e salva la revoca sul server se sei dentro. Senza login vale solo in questo browser.",
  honestyNoTrack:
    "Condividere crea un link con nome e stats — senza traccia, perché non ne è salvata nessuna.",
  linkNoTrackLong:
    "Link senza traccia — troppo lungo per l’URL. Nome e stats, niente GPS.",
  linkHasTrack: "Il link contiene una traccia semplificata.",
  linkNoTrack: "Link senza traccia — nome e stats.",
};

const NL: PlatzCopy = {
  inviteHint:
    "Uitnodigen deelt de link. Je groepen blijven. Gedeeld zet ook open groepen op Platz — geen feed. Vrienden op de kaart alleen in de app, na opt-in.",
  pickTour: "Tocht kiezen",
  visPrivate: "Privé",
  visPublic: "Gedeeld",
  visAll: "Alle",
  meetingPlaceholder: "Trefpunt (optioneel)",
  createGroup: "Groep aanmaken",
  needSignIn:
    "Aanmelden — anders ziet je vriend de groep niet op de server.",
  needSharedTour:
    "Groep alleen bij een gedeelde of catalogustocht. Privé-GPX blijft privé.",
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
  copiedInvite:
    "Link gekopieerd. Wie hem heeft, kan meedoen zolang de groep open is.",
  makePrivate: "Privé maken",
  makePublic: "Op Platz zetten",
  listedNote: "Op Platz gezet — wie de link heeft, kan meedoen.",
  unlistedNote: "Alleen via link — niet op Platz.",
  pinsOff: "Vrienden op de kaart · uit",
  pinsHud: "Vrienden alleen tijdens de rit",
  pinsHint: "Alleen tijdens de rit, niet op de openbare kaart.",
  join: "Meedoen",
  joined: (title) => `Erbij: ${title}`,
  joinWithLink: "Meedoen met een link",
  joinLocalCta: "Op dit apparaat onthouden",
  joinUnsignedHint: "Zonder aanmelden ziet de host je niet.",
  joinField: "Uitnodigingslink",
  joinHint:
    "Plak de link uit WhatsApp of Messages. Privé heeft de uitnodigingslink nodig — geen code om over te tikken.",
  joinEmpty: "Link ontbreekt.",
  joinInvalid: "Geen geldige uitnodigingslink.",
  startLabel: "Start",
  startNow: "Nu",
  startIn1h: "Over 1 h",
  startToday18: "Vandaag 18:00",
  startTomorrow10: "Morgen 10:00",
  durationLabel: "Duur",
  pinsOn: "Vrienden op de kaart · aan",
  collectionsHint:
    "Aanmaken onder Delen. Delen alleen met gedeelde of catalogustochten — privé-GPX blijft buiten.",
  shareTitle: (title) => `Samen eruit: ${title}`,
  shareMeet: (point) => `Trefpunt: ${point}`,
  shareProfile: (url) => `Mijn profiel: ${url}`,
  shareVisPublic:
    "Gedeeld: wie de link heeft, kan meedoen. De groep kan onder Gedeeld staan.",
  shareVisPrivate:
    "Privé: alleen wie deze link heeft, kan meedoen. Niet openbaar gezet.",
  whenClosed: (wd, hm) => `dicht — ${wd} ${hm}`,
  whenToday: (hm, dur) => `vandaag ${hm} · ${dur}`,
  whenTomorrow: (hm, dur) => `morgen ${hm} · ${dur}`,
  whenOther: (wd, hm, dur) => `${wd} ${hm} · ${dur}`,
  mappeEmpty: "Nog geen eigen routes — voeg een route toe.",
  mappeFilterEmpty: "Geen tochten in dit filter.",
  shared: "gedeeld",
  privateTour: "privé",
  openInApp: "Openen in de app",
  joinOnDevice:
    " — In de app onthouden. Zonder aanmelden ziet de host je niet.",
  stimmenTitle: "Stimmen",
  stimmenEmpty:
    "Nog geen Stimmen bij je tochten. Na delen kunnen anderen schrijven.",
  pending: "In beoordeling",
  collectionsTitle: "Verzamelingen",
  collectionName: "Naam van de verzameling",
  collectionCreate: "Aanmaken",
  collectionCreated: "Verzameling aangemaakt",
  collectionEmpty:
    "Nog geen verzameling — onder Delen bij een tocht aanmaken.",
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
    "Delen maakt een link. De link bevat een vereenvoudigd spoor (coördinaten), niet alleen de naam. Terug naar privé haalt de tocht uit filters en bewaart de intrekking op de server als je bent aangemeld. Zonder login geldt het alleen in deze browser.",
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
  if (raw === LISTED_DE) return g.listedNote;
  if (raw === UNLISTED_DE) return g.unlistedNote;
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
  const hours = Math.round((end.getTime() - start.getTime()) / 3_600_000);
  const dur = `${Math.max(1, hours)} h`;
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
