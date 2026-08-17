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
  pinsOff: string;
  pinsHud: string;
  join: string;
  joined: (title: string) => string;
  joinWithLink: string;
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
    "Einladen teilt den Link. Filter Alle, Privat, Öffentlich gilt auch hier. Pins nur im App-HUD.",
  pickTour: "Tour wählen",
  visPrivate: "Privat",
  visPublic: "Öffentlich",
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
  emptyPublic: "Keine öffentlichen Gruppen.",
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
  makePublic: "Öffentlich machen",
  pinsOff: "Pins aus",
  pinsHud: "Pins nur im HUD",
  join: "Beitreten",
  joined: (title) => `Dabei: ${title}`,
  joinWithLink: "Mit Link beitreten",
  joinField: "Einladungslink",
  joinHint:
    "Link aus WhatsApp oder Messages einfügen. Privat braucht den Token im Link — kein Code zum Abtippen.",
  joinEmpty: "Link fehlt.",
  joinInvalid: "Kein gültiger Einladungslink.",
  startLabel: "Start",
  startNow: "Jetzt",
  startIn1h: "In 1 h",
  startToday18: "Heute 18:00",
  startTomorrow10: "Morgen 10:00",
  durationLabel: "Dauer",
  pinsOn: "Pins im HUD an",
  collectionsHint:
    "Teilen geht nur mit freigegebenen oder Katalog-Touren. Private GPX bleibt draußen.",
  shareTitle: (title) => `Zusammen raus: ${title}`,
  shareMeet: (point) => `Treffpunkt: ${point}`,
  shareProfile: (url) => `Mein Platz-Profil: ${url}`,
  shareVisPublic:
    "Öffentlich: wer den Link hat, kann beitreten. Die Gruppe kann auf dem Platz unter Öffentlich stehen.",
  shareVisPrivate:
    "Privat: nur wer diesen Link hat, kann beitreten. Kein öffentliches Roster.",
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
    " — Join auf dem Gerät. Wer den Link hat, kann beitreten, solange die Gruppe offen ist.",
  stimmenTitle: "Stimmen",
  stimmenEmpty:
    "Noch keine Stimmen zu deinen Touren. Nach Freigabe können andere schreiben.",
  pending: "In Prüfung",
  collectionsTitle: "Sammlungen",
  collectionName: "Name der Sammlung",
  collectionCreate: "Anlegen",
  collectionCreated: "Sammlung angelegt",
  collectionEmpty: "Noch keine Sammlung.",
  collectionTours: (n) => `${n} Touren`,
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
    "Name + Start (Kartenmitte/GPS) — ohne erfundenen Track. GPX bleibt optional.",
  routeName: "Name der Route",
  startGps: "Start: GPS, falls erlaubt — sonst ohne Pin.",
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
  visibility: "Sichtbarkeit",
  shareOut: "Freigeben",
  privateNote: "Private Notiz",
  notePlaceholder: "Nur für dich — keine Stimme.",
  honestyCatalog:
    "Katalog-Tour ist schon öffentlich. Freigeben macht deine Akte teilbar — der Link zeigt Name und Stats, keinen privaten Extra-Track.",
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
    "Invite shares the link. Filter All, Private, Public applies here too. Pins only in the app HUD.",
  pickTour: "Pick a tour",
  visPrivate: "Private",
  visPublic: "Public",
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
  makePublic: "Make public",
  pinsOff: "Pins off",
  pinsHud: "Pins only in HUD",
  join: "Join",
  joined: (title) => `In: ${title}`,
  joinWithLink: "Join with a link",
  joinField: "Invite link",
  joinHint:
    "Paste the link from WhatsApp or Messages. Private groups need the token in the link — no code to type.",
  joinEmpty: "Link missing.",
  joinInvalid: "Not a valid invite link.",
  startLabel: "Start",
  startNow: "Now",
  startIn1h: "In 1 h",
  startToday18: "Today 18:00",
  startTomorrow10: "Tomorrow 10:00",
  durationLabel: "Duration",
  pinsOn: "Pins on in HUD",
  collectionsHint:
    "Sharing only includes released or catalogue tours. Private GPX stays out.",
  shareTitle: (title) => `Ride together: ${title}`,
  shareMeet: (point) => `Meeting point: ${point}`,
  shareProfile: (url) => `My Platz profile: ${url}`,
  shareVisPublic:
    "Public: whoever has the link can join. The group can sit on Platz under Public.",
  shareVisPrivate:
    "Private: only whoever has this link can join. No public roster.",
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
    " — Join on the device. Whoever has the link can join while the group is open.",
  stimmenTitle: "Stimmen",
  stimmenEmpty:
    "No Stimmen on your tours yet. After you share, others can write.",
  pending: "In review",
  collectionsTitle: "Collections",
  collectionName: "Collection name",
  collectionCreate: "Create",
  collectionCreated: "Collection created",
  collectionEmpty: "No collection yet.",
  collectionTours: (n) => `${n} tours`,
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
    "Name + start (map centre/GPS) — no invented track. GPX stays optional.",
  routeName: "Route name",
  startGps: "Start: GPS if allowed — otherwise no pin.",
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
  visibility: "Visibility",
  shareOut: "Share",
  privateNote: "Private note",
  notePlaceholder: "Just for you — not a Stimme.",
  honestyCatalog:
    "Catalogue tour is already public. Sharing makes your file shareable — the link shows name and stats, no extra private track.",
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
    "Inviter partage le lien. Le filtre Tous, Privé, Public s’applique ici aussi. Pins seulement dans le HUD de l’appli.",
  pickTour: "Choisir une sortie",
  visPrivate: "Privé",
  visPublic: "Public",
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
  makePublic: "Rendre public",
  pinsOff: "Pins off",
  pinsHud: "Pins seulement dans le HUD",
  join: "Rejoindre",
  joined: (title) => `Dedans : ${title}`,
  joinWithLink: "Rejoindre avec un lien",
  joinField: "Lien d’invitation",
  joinHint:
    "Colle le lien depuis WhatsApp ou Messages. Privé a besoin du jeton dans le lien — pas de code à taper.",
  joinEmpty: "Lien manquant.",
  joinInvalid: "Lien d’invitation invalide.",
  startLabel: "Départ",
  startNow: "Maintenant",
  startIn1h: "Dans 1 h",
  startToday18: "Aujourd’hui 18:00",
  startTomorrow10: "Demain 10:00",
  durationLabel: "Durée",
  pinsOn: "Pins on dans le HUD",
  collectionsHint:
    "Le partage ne prend que les sorties partagées ou catalogue. Le GPX privé reste dehors.",
  shareTitle: (title) => `Sortir ensemble : ${title}`,
  shareMeet: (point) => `Rendez-vous : ${point}`,
  shareProfile: (url) => `Mon profil Platz : ${url}`,
  shareVisPublic:
    "Public : qui a le lien peut rejoindre. Le groupe peut figurer sur Platz sous Public.",
  shareVisPrivate:
    "Privé : seulement qui a ce lien peut rejoindre. Pas de roster public.",
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
    " — Rejoindre sur l’appareil. Qui a le lien peut entrer tant que le groupe est ouvert.",
  stimmenTitle: "Stimmen",
  stimmenEmpty:
    "Pas encore de Stimmen sur tes sorties. Après partage, les autres peuvent écrire.",
  pending: "En relecture",
  collectionsTitle: "Collections",
  collectionName: "Nom de la collection",
  collectionCreate: "Créer",
  collectionCreated: "Collection créée",
  collectionEmpty: "Pas encore de collection.",
  collectionTours: (n) => `${n} sorties`,
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
    "Nom + départ (centre carte/GPS) — sans trace inventée. GPX reste optionnel.",
  routeName: "Nom de la route",
  startGps: "Départ : GPS si autorisé — sinon sans épingle.",
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
  visibility: "Visibilité",
  shareOut: "Partager",
  privateNote: "Note privée",
  notePlaceholder: "Rien que pour toi — pas une Stimme.",
  honestyCatalog:
    "La sortie catalogue est déjà publique. Partager rend ton dossier partageable — le lien montre nom et stats, pas de trace privée en plus.",
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
    "Invitare condivide il link. Il filtro Tutti, Privato, Pubblico vale anche qui. Pin solo nell’HUD dell’app.",
  pickTour: "Scegli un’uscita",
  visPrivate: "Privato",
  visPublic: "Pubblico",
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
  makePublic: "Rendi pubblico",
  pinsOff: "Pin off",
  pinsHud: "Pin solo nell’HUD",
  join: "Entra",
  joined: (title) => `Dentro: ${title}`,
  joinWithLink: "Entra con un link",
  joinField: "Link d’invito",
  joinHint:
    "Incolla il link da WhatsApp o Messages. Il privato serve il token nel link — niente codice da digitare.",
  joinEmpty: "Manca il link.",
  joinInvalid: "Link d’invito non valido.",
  startLabel: "Partenza",
  startNow: "Ora",
  startIn1h: "Tra 1 h",
  startToday18: "Oggi 18:00",
  startTomorrow10: "Domani 10:00",
  durationLabel: "Durata",
  pinsOn: "Pin on nell’HUD",
  collectionsHint:
    "Si condividono solo uscite condivise o di catalogo. Il GPX privato resta fuori.",
  shareTitle: (title) => `Uscire insieme: ${title}`,
  shareMeet: (point) => `Ritrovo: ${point}`,
  shareProfile: (url) => `Il mio profilo Platz: ${url}`,
  shareVisPublic:
    "Pubblico: chi ha il link può entrare. Il gruppo può stare sul Platz sotto Pubblico.",
  shareVisPrivate:
    "Privato: solo chi ha questo link può entrare. Niente roster pubblico.",
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
    " — Entra sul dispositivo. Chi ha il link può entrare finché il gruppo è aperto.",
  stimmenTitle: "Stimmen",
  stimmenEmpty:
    "Ancora nessuna Stimme sulle tue uscite. Dopo la condivisione gli altri possono scrivere.",
  pending: "In revisione",
  collectionsTitle: "Raccolte",
  collectionName: "Nome della raccolta",
  collectionCreate: "Crea",
  collectionCreated: "Raccolta creata",
  collectionEmpty: "Ancora nessuna raccolta.",
  collectionTours: (n) => `${n} uscite`,
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
    "Nome + partenza (centro mappa/GPS) — senza traccia inventata. GPX resta opzionale.",
  routeName: "Nome della route",
  startGps: "Partenza: GPS se permesso — altrimenti senza pin.",
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
  visibility: "Visibilità",
  shareOut: "Condividi",
  privateNote: "Nota privata",
  notePlaceholder: "Solo per te — non una Stimme.",
  honestyCatalog:
    "L’uscita catalogo è già pubblica. Condividere rende la tua pratica condivisibile — il link mostra nome e stats, nessuna traccia privata in più.",
  honestyTrack:
    "Condividere crea un link. Il link contiene una traccia semplificata (coordinate), non solo il nome. Tornare a privato toglie l’uscita dai filtri e salva la revoca sul server se sei dentro. Senza login vale solo in questo browser.",
  honestyNoTrack:
    "Condividere crea un link con nome e stats — senza traccia, perché non ne è salvata nessuna.",
  linkNoTrackLong:
    "Link senza traccia — troppo lungo per l’URL. Nome e stats, niente GPS.",
  linkHasTrack: "Il link contiene una traccia semplificata.",
  linkNoTrack: "Link senza traccia — nome e stats.",
};

const BY_LANG: Record<ChromeLang, PlatzCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
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
