/**
 * Web profile chrome. Headings follow Flutter ARB where keys exist.
 */
import type { ChromeLang } from "./chromeLang";
import { rideSportLabel } from "./rideSportLabel";

export type ProfileCopy = {
  account: string;
  sync: string;
  signOut: string;
  deleteAccount: string;
  status: string;
  local: string;
  syncFailed: string;
  checkoutFailed: string;
  billingFailed: string;
  portalFailed: string;
  deleteConfirmTitle: string;
  deleteConfirmBody: string;
  deleteTypeDelete: string;
  deleteAborted: string;
  remoteDeleted: string;
  remoteUnavailable: string;
  notSignedInLocal: string;
  remoteFailed: (detail: string) => string;
  serverUnreachable: string;
  localCleared: string;
  plan: string;
  planHint: string;
  current: string;
  commerceClosed: string;
  proMonth: string;
  proYear: string;
  managePortal: string;
  upgradeSignIn: string;
  styleAggressive: string;
  styleFlow: string;
  styleEfficient: string;
  styleExploring: string;
  skill: (n: number) => string;
  riderWeight: string;
  advancedShow: string;
  advancedHide: string;
  terrain: string;
  terrainS0: string;
  terrainS2: string;
  terrainS3: string;
  terrainGravel: string;
  brakeBeforeCorners: string;
  lateralG: string;
  impactsPerHour: string;
  jumpsPerRide: string;
  preferences: string;
  preferTechnical: string;
  preferFlow: string;
  preferSteep: string;
  eBikeAssist: string;
  rangeTitle: string;
  bikeFront: string;
  explainStyle: string;
  explainSkill: string;
  explainTechnical: string;
  explainFlow: string;
  explainSteep: string;
  explainAssist: string;
  explainWeight: string;
  explainTerrain: string;
  explainIndicators: string;
  publicTitle: string;
  publicHint: string;
  publicEnable: string;
  publicDisplayName: string;
  publicHandle: string;
  publicHandleHint: string;
  publicBio: string;
  publicRegion: string;
  publicRegionPh: string;
  publicSports: string;
  publicShowRides: string;
  publicView: (handle: string) => string;
  publicSaving: string;
  publicSynced: string;
  publicHandleMin: string;
  publicSignIn: string;
  publicInvalidHandle: string;
  publicServerLocal: string;
  publicSaved: (handle: string) => string;
  publicOffline: string;
  publicEditorial: string;
  publicMissingTitle: string;
  publicMissingHint: string;
  publicRidesAgg: (n: number) => string;
  publicNoHeatmap: string;
  publicStimmen: string;
  publicTour: string;
  sportMtb: string;
  sportEbike: string;
  sportTouring: string;
};

const DE: ProfileCopy = {
  account: "Konto",
  sync: "Sync",
  signOut: "Abmelden",
  deleteAccount: "Konto löschen",
  status: "Status",
  local: "lokal",
  syncFailed: "Sync fehlgeschlagen",
  checkoutFailed: "Checkout fehlgeschlagen",
  billingFailed: "Billing-Fehler",
  portalFailed: "Portal fehlgeschlagen",
  deleteConfirmTitle: "Konto löschen?",
  deleteConfirmBody:
    "Remote-Konto und lokale App-Daten werden entfernt. Exportiere vorher GPX/JSON unter Daten & Privatsphäre.",
  deleteTypeDelete: "Zum Bestätigen „DELETE“ eingeben:",
  deleteAborted: "Abgebrochen — Bestätigung war nicht DELETE.",
  remoteDeleted: "Remote-Konto gelöscht.",
  remoteUnavailable:
    "Remote-Löschung nicht verfügbar — nur lokale Daten werden entfernt.",
  notSignedInLocal: "Nicht angemeldet — nur lokale Daten werden entfernt.",
  remoteFailed: (detail) =>
    `Remote-Löschung fehlgeschlagen (${detail}) — lokal trotzdem gelöscht.`,
  serverUnreachable: "Server nicht erreichbar — nur lokale Daten werden entfernt.",
  localCleared:
    "Lokale Daten gelöscht. Export ggf. unter Privatsphäre nachholen.",
  plan: "Abo",
  planHint:
    "Free: 1 Rad, Basis. Pro: mehrere Räder, Varianten-Vergleich, Reichweite. Offline-Routing in der App — auf beiden Stufen. KI-Coach — 6,99 €/Mo oder 59,99 €/Jahr.",
  current: "Aktuell",
  commerceClosed:
    "Entwicklungsstand — Käufe sind gesperrt. Lokal kannst du die App weiter testen; es gibt kein öffentliches Abo.",
  proMonth: "Pro 6,99 €/Mo",
  proYear: "Pro 59,99 €/Jahr",
  managePortal: "Abo verwalten (Stripe Portal)",
  upgradeSignIn:
    "Zum Upgrade bitte anmelden. Ohne Konto bleibt Free lokal nutzbar.",
  styleAggressive: "Aggressiv",
  styleFlow: "Flow",
  styleEfficient: "Effizient",
  styleExploring: "Entdeckend",
  skill: (n) => `Können (${n} / 5)`,
  riderWeight: "Fahrergewicht (kg)",
  advancedShow: "Erweiterte Einstellungen (Terrain & Indikatoren)",
  advancedHide: "Erweiterte Einstellungen ausblenden",
  terrain: "Terrainanteil",
  terrainS0: "S0–S1 / easy",
  terrainS2: "S2",
  terrainS3: "S3+",
  terrainGravel: "Gravel/Straße",
  brakeBeforeCorners: "Bremsintensität vor Kurven",
  lateralG: "% Zeit > 0,4 g Quer",
  impactsPerHour: "Impacts / Stunde",
  jumpsPerRide: "Sprünge / Fahrt",
  preferences: "Präferenzen",
  preferTechnical: "Technisch",
  preferFlow: "Flow",
  preferSteep: "Steil",
  eBikeAssist: "E-Bike Assist-Präferenz (Logging)",
  rangeTitle: "Reichweiten-Kalibrierung",
  bikeFront: "vorn",
  explainStyle:
    "Abgeleitet aus Impact-Häufigkeit und Flow-Scores deiner Rides — jederzeit korrigierbar.",
  explainSkill:
    "Selbsteinschätzung 1–5; beeinflusst Routenvorschläge und Reichweite.",
  explainTechnical:
    "Gewichtet Routen mit höherem mtb:scale und rootigem Untergrund stärker.",
  explainFlow:
    "Bevorzugt flowige Trails und kompakte Oberflächen in Discover.",
  explainSteep: "Hebt Routen mit mehr Höhenmetern und steileren Rampen an.",
  explainAssist:
    "Nur Logging und Reichweiten-Kontext — keine Motorsteuerung.",
  explainWeight:
    "Für SAG-Vorlagen und Reichweite — lokal gespeichert, jederzeit änderbar.",
  explainTerrain:
    "Verteilung über Trail-Schwierigkeit / Oberfläche aus deiner Historie.",
  explainIndicators:
    "Bremsintensität, Querbeschleunigung, Impacts, Sprünge — erklärbar und korrigierbar.",
  publicTitle: "Öffentliches Profil",
  publicHint:
    "Opt-in. Handle an Stimmen, keine Tracks, kein Tab. Mit Konto liegt es auf dem Server, nicht nur in diesem Browser.",
  publicEnable: "Profil öffentlich schalten",
  publicDisplayName: "Anzeigename",
  publicHandle: "Handle",
  publicHandleHint: "Handle (a-z, 0-9, _)",
  publicBio: "Bio",
  publicRegion: "Region",
  publicRegionPh: "z. B. Baden-Württemberg",
  publicSports: "Disziplinen",
  publicShowRides: "Fahrtenzahl zeigen",
  publicView: (handle) => `Profil ansehen → /u/${handle}`,
  publicSaving: "Speichert…",
  publicSynced: "Mit dem Konto synchronisiert.",
  publicHandleMin: "Handle mindestens 3 Zeichen, dann speichert der Server.",
  publicSignIn: "Anmelden, damit das Profil auf anderen Geräten erscheint.",
  publicInvalidHandle: "Handle: a–z, 0–9, Unterstrich, 3–24 Zeichen.",
  publicServerLocal: "Server hat nicht gespeichert — lokal bleibt der Stand.",
  publicSaved: (handle) => `Gespeichert. Sichtbar unter /u/${handle}.`,
  publicOffline: "Netz fehlt — Stand bleibt in diesem Browser.",
  publicEditorial: "Editorial-Beispiel",
  publicMissingTitle: "Profil nicht öffentlich",
  publicMissingHint:
    "Dieses Handle ist nicht freigeschaltet oder existiert nicht. Public Profiles sind Opt-in und speichern keine Tracks.",
  publicRidesAgg: (n) => `${n} Fahrten (aggregiert, ohne Spur)`,
  publicNoHeatmap: "Keine Heatmaps, keine Roh-GPS-Daten auf diesem Profil.",
  publicStimmen: "Stimmen",
  publicTour: "Tour",
  sportMtb: "MTB",
  sportEbike: "E-Bike",
  sportTouring: "Touring",
};

const EN: ProfileCopy = {
  account: "Account",
  sync: "Sync",
  signOut: "Sign out",
  deleteAccount: "Delete account",
  status: "Status",
  local: "local",
  syncFailed: "Sync failed",
  checkoutFailed: "Checkout failed",
  billingFailed: "Billing error",
  portalFailed: "Portal failed",
  deleteConfirmTitle: "Delete account?",
  deleteConfirmBody:
    "Remote account and local app data will be removed. Export GPX/JSON under Data & privacy first.",
  deleteTypeDelete: "Type DELETE to confirm:",
  deleteAborted: "Cancelled — confirmation was not DELETE.",
  remoteDeleted: "Remote account deleted.",
  remoteUnavailable: "Remote delete unavailable — local data will be removed only.",
  notSignedInLocal: "Not signed in — local data will be removed only.",
  remoteFailed: (detail) =>
    `Remote delete failed (${detail}) — local data still deleted.`,
  serverUnreachable: "Server unreachable — local data will be removed only.",
  localCleared: "Local data deleted. Export under Privacy if you still need it.",
  plan: "Plan",
  planHint:
    "Free: 1 bike, basics. Pro: more bikes, variant compare, range. Offline routing in the app — both tiers. AI coach — €6.99/mo or €59.99/year.",
  current: "Current",
  commerceClosed:
    "Development build — purchases are off. You can keep testing locally; there is no public plan.",
  proMonth: "Pro €6.99/mo",
  proYear: "Pro €59.99/year",
  managePortal: "Manage plan (Stripe portal)",
  upgradeSignIn: "Sign in to upgrade. Without an account Free stays local.",
  styleAggressive: "Aggressive",
  styleFlow: "Flow",
  styleEfficient: "Efficient",
  styleExploring: "Exploring",
  skill: (n) => `Skill (${n} / 5)`,
  riderWeight: "Rider weight (kg)",
  advancedShow: "Advanced settings (terrain & indicators)",
  advancedHide: "Hide advanced settings",
  terrain: "Terrain mix",
  terrainS0: "S0–S1 / easy",
  terrainS2: "S2",
  terrainS3: "S3+",
  terrainGravel: "Gravel/road",
  brakeBeforeCorners: "Braking before corners",
  lateralG: "% time > 0.4 g lateral",
  impactsPerHour: "Impacts / hour",
  jumpsPerRide: "Jumps / ride",
  preferences: "Preferences",
  preferTechnical: "Technical",
  preferFlow: "Flow",
  preferSteep: "Steep",
  eBikeAssist: "E-bike assist preference (logging)",
  rangeTitle: "Range calibration",
  bikeFront: "front",
  explainStyle:
    "From impact rate and flow scores on your rides — correct anytime.",
  explainSkill: "Self-score 1–5; shapes route suggestions and range.",
  explainTechnical: "Weights routes with higher mtb:scale and rooty ground.",
  explainFlow: "Prefers flow trails and compact surfaces in Discover.",
  explainSteep: "Lifts routes with more climb and steeper ramps.",
  explainAssist: "Logging and range context only — no motor control.",
  explainWeight: "For sag templates and range — stored locally, change anytime.",
  explainTerrain: "Mix of trail difficulty / surface from your history.",
  explainIndicators:
    "Braking, lateral g, impacts, jumps — explainable and editable.",
  publicTitle: "Public profile",
  publicHint:
    "Opt-in. Handle on voices, no tracks, no tab. With an account it lives on the server, not only in this browser.",
  publicEnable: "Make profile public",
  publicDisplayName: "Display name",
  publicHandle: "Handle",
  publicHandleHint: "Handle (a-z, 0-9, _)",
  publicBio: "Bio",
  publicRegion: "Region",
  publicRegionPh: "e.g. Baden-Württemberg",
  publicSports: "Disciplines",
  publicShowRides: "Show ride count",
  publicView: (handle) => `View profile → /u/${handle}`,
  publicSaving: "Saving…",
  publicSynced: "Synced with the account.",
  publicHandleMin: "Handle needs 3 characters before the server stores it.",
  publicSignIn: "Sign in so the profile shows on other devices.",
  publicInvalidHandle: "Handle: a–z, 0–9, underscore, 3–24 characters.",
  publicServerLocal: "Server did not save — this browser keeps the stand.",
  publicSaved: (handle) => `Saved. Visible at /u/${handle}.`,
  publicOffline: "No network — the stand stays in this browser.",
  publicEditorial: "Editorial example",
  publicMissingTitle: "Profile is not public",
  publicMissingHint:
    "This handle is not enabled or does not exist. Public profiles are opt-in and store no tracks.",
  publicRidesAgg: (n) => `${n} rides (aggregated, no trace)`,
  publicNoHeatmap: "No heatmaps, no raw GPS on this profile.",
  publicStimmen: "Stimmen",
  publicTour: "Tour",
  sportMtb: "MTB",
  sportEbike: "E-bike",
  sportTouring: "Touring",
};

const FR: ProfileCopy = {
  account: "Compte",
  sync: "Sync",
  signOut: "Se déconnecter",
  deleteAccount: "Supprimer le compte",
  status: "Statut",
  local: "local",
  syncFailed: "Sync échoué",
  checkoutFailed: "Checkout échoué",
  billingFailed: "Erreur de facturation",
  portalFailed: "Portail échoué",
  deleteConfirmTitle: "Supprimer le compte ?",
  deleteConfirmBody:
    "Le compte distant et les données locales seront retirés. Exporte d’abord GPX/JSON sous Données & confidentialité.",
  deleteTypeDelete: "Pour confirmer, saisis DELETE :",
  deleteAborted: "Annulé — la confirmation n’était pas DELETE.",
  remoteDeleted: "Compte distant supprimé.",
  remoteUnavailable:
    "Suppression distante indisponible — seules les données locales seront retirées.",
  notSignedInLocal: "Pas connecté — seules les données locales seront retirées.",
  remoteFailed: (detail) =>
    `Suppression distante échouée (${detail}) — local quand même effacé.`,
  serverUnreachable:
    "Serveur injoignable — seules les données locales seront retirées.",
  localCleared:
    "Données locales effacées. Exporte sous Confidentialité si besoin.",
  plan: "Abo",
  planHint:
    "Free : 1 vélo, base. Pro : plusieurs vélos, comparaison, autonomie. Routing hors ligne dans l’app — les deux paliers. Coach IA — 6,99 €/mois ou 59,99 €/an.",
  current: "Actuel",
  commerceClosed:
    "Version de développement — pas d’achats. Tu peux tester en local ; pas d’abonnement public.",
  proMonth: "Pro 6,99 €/mois",
  proYear: "Pro 59,99 €/an",
  managePortal: "Gérer l’abo (portail Stripe)",
  upgradeSignIn:
    "Connecte-toi pour passer à Pro. Sans compte, Free reste local.",
  styleAggressive: "Agressif",
  styleFlow: "Flow",
  styleEfficient: "Efficace",
  styleExploring: "Exploration",
  skill: (n) => `Niveau (${n} / 5)`,
  riderWeight: "Poids rider (kg)",
  advancedShow: "Réglages avancés (terrain & indicateurs)",
  advancedHide: "Masquer les réglages avancés",
  terrain: "Part de terrain",
  terrainS0: "S0–S1 / easy",
  terrainS2: "S2",
  terrainS3: "S3+",
  terrainGravel: "Gravel/route",
  brakeBeforeCorners: "Freinage avant virages",
  lateralG: "% temps > 0,4 g latéral",
  impactsPerHour: "Impacts / heure",
  jumpsPerRide: "Sauts / sortie",
  preferences: "Préférences",
  preferTechnical: "Technique",
  preferFlow: "Flow",
  preferSteep: "Penté",
  eBikeAssist: "Préférence d’assistance VAE (journal)",
  rangeTitle: "Calibrage d’autonomie",
  bikeFront: "devant",
  explainStyle:
    "Issu du taux d’impacts et des scores flow — corrigeable à tout moment.",
  explainSkill: "Auto-évaluation 1–5 ; oriente suggestions et autonomie.",
  explainTechnical: "Poids les parcours à mtb:scale élevé et sol racineux.",
  explainFlow: "Préfère les trails flow et surfaces compactes dans Discover.",
  explainSteep: "Monte les parcours avec plus de dénivelé et de rampes.",
  explainAssist: "Journal et contexte d’autonomie — pas de commande moteur.",
  explainWeight:
    "Pour les gabarits SAG et l’autonomie — local, changeable à tout moment.",
  explainTerrain: "Répartition difficulté / surface d’après l’historique.",
  explainIndicators:
    "Freinage, g latéral, impacts, sauts — explicable et corrigeable.",
  publicTitle: "Profil public",
  publicHint:
    "Opt-in. Handle sur les voix, pas de traces, pas d’onglet. Avec un compte ça vit sur le serveur, pas seulement ici.",
  publicEnable: "Rendre le profil public",
  publicDisplayName: "Nom affiché",
  publicHandle: "Handle",
  publicHandleHint: "Handle (a-z, 0-9, _)",
  publicBio: "Bio",
  publicRegion: "Région",
  publicRegionPh: "ex. Bade-Wurtemberg",
  publicSports: "Disciplines",
  publicShowRides: "Afficher le nombre de sorties",
  publicView: (handle) => `Voir le profil → /u/${handle}`,
  publicSaving: "Enregistrement…",
  publicSynced: "Synchronisé avec le compte.",
  publicHandleMin: "Handle d’au moins 3 caractères, puis le serveur enregistre.",
  publicSignIn: "Connecte-toi pour que le profil apparaisse sur d’autres appareils.",
  publicInvalidHandle: "Handle : a–z, 0–9, underscore, 3–24 caractères.",
  publicServerLocal: "Le serveur n’a pas enregistré — le stand reste ici.",
  publicSaved: (handle) => `Enregistré. Visible sous /u/${handle}.`,
  publicOffline: "Pas de réseau — le stand reste dans ce navigateur.",
  publicEditorial: "Exemple éditorial",
  publicMissingTitle: "Profil pas public",
  publicMissingHint:
    "Ce handle n’est pas ouvert ou n’existe pas. Les profils publics sont opt-in et ne stockent pas de traces.",
  publicRidesAgg: (n) => `${n} sorties (agrégé, sans trace)`,
  publicNoHeatmap: "Pas de heatmap, pas de GPS brut sur ce profil.",
  publicStimmen: "Stimmen",
  publicTour: "Parcours",
  sportMtb: "VTT",
  sportEbike: "VAE",
  sportTouring: "Voyage",
};

const IT: ProfileCopy = {
  account: "Account",
  sync: "Sync",
  signOut: "Esci",
  deleteAccount: "Elimina account",
  status: "Stato",
  local: "locale",
  syncFailed: "Sync non riuscito",
  checkoutFailed: "Checkout non riuscito",
  billingFailed: "Errore di fatturazione",
  portalFailed: "Portale non riuscito",
  deleteConfirmTitle: "Eliminare l’account?",
  deleteConfirmBody:
    "Account remoto e dati locali verranno rimossi. Esporta prima GPX/JSON sotto Dati e privacy.",
  deleteTypeDelete: "Per confermare scrivi DELETE:",
  deleteAborted: "Annullato — la conferma non era DELETE.",
  remoteDeleted: "Account remoto eliminato.",
  remoteUnavailable:
    "Eliminazione remota non disponibile — verranno rimossi solo i dati locali.",
  notSignedInLocal: "Non collegato — verranno rimossi solo i dati locali.",
  remoteFailed: (detail) =>
    `Eliminazione remota fallita (${detail}) — locale comunque cancellato.`,
  serverUnreachable:
    "Server non raggiungibile — verranno rimossi solo i dati locali.",
  localCleared: "Dati locali cancellati. Esporta sotto Privacy se ti serve.",
  plan: "Abbonamento",
  planHint:
    "Free: 1 bici, base. Pro: più bici, confronto varianti, autonomia. Routing offline nell’app — entrambi i livelli. Coach IA — 6,99 €/mese o 59,99 €/anno.",
  current: "Attuale",
  commerceClosed:
    "Build di sviluppo — nessun acquisto. Puoi testare in locale; nessun abbonamento pubblico.",
  proMonth: "Pro 6,99 €/mese",
  proYear: "Pro 59,99 €/anno",
  managePortal: "Gestisci abbonamento (portale Stripe)",
  upgradeSignIn:
    "Accedi per passare a Pro. Senza account Free resta locale.",
  styleAggressive: "Aggressivo",
  styleFlow: "Flow",
  styleEfficient: "Efficiente",
  styleExploring: "Esplorazione",
  skill: (n) => `Livello (${n} / 5)`,
  riderWeight: "Peso rider (kg)",
  advancedShow: "Impostazioni avanzate (terreno e indicatori)",
  advancedHide: "Nascondi impostazioni avanzate",
  terrain: "Quota terreno",
  terrainS0: "S0–S1 / easy",
  terrainS2: "S2",
  terrainS3: "S3+",
  terrainGravel: "Gravel/strada",
  brakeBeforeCorners: "Frenata prima delle curve",
  lateralG: "% tempo > 0,4 g laterale",
  impactsPerHour: "Impatti / ora",
  jumpsPerRide: "Salti / uscita",
  preferences: "Preferenze",
  preferTechnical: "Tecnico",
  preferFlow: "Flow",
  preferSteep: "Ripido",
  eBikeAssist: "Preferenza assistenza e-bike (log)",
  rangeTitle: "Calibrazione autonomia",
  bikeFront: "davanti",
  explainStyle:
    "Da impatti e punteggi flow delle uscite — correggibile in qualsiasi momento.",
  explainSkill: "Autovalutazione 1–5; influenza percorsi e autonomia.",
  explainTechnical: "Pesa i percorsi con mtb:scale più alto e fondo radicato.",
  explainFlow: "Preferisce trail flow e superfici compatte in Discover.",
  explainSteep: "Alza i percorsi con più dislivello e rampe più ripide.",
  explainAssist: "Solo log e contesto autonomia — niente controllo motore.",
  explainWeight: "Per sag e autonomia — locale, modificabile quando vuoi.",
  explainTerrain: "Mix di difficoltà / superficie dalla tua storia.",
  explainIndicators:
    "Frenata, g laterale, impatti, salti — spiegabile e modificabile.",
  publicTitle: "Profilo pubblico",
  publicHint:
    "Opt-in. Handle sulle voci, niente tracce, niente scheda. Con un account vive sul server, non solo in questo browser.",
  publicEnable: "Rendi pubblico il profilo",
  publicDisplayName: "Nome visualizzato",
  publicHandle: "Handle",
  publicHandleHint: "Handle (a-z, 0-9, _)",
  publicBio: "Bio",
  publicRegion: "Regione",
  publicRegionPh: "es. Baden-Württemberg",
  publicSports: "Discipline",
  publicShowRides: "Mostra il numero di uscite",
  publicView: (handle) => `Vedi profilo → /u/${handle}`,
  publicSaving: "Salvataggio…",
  publicSynced: "Sincronizzato con l’account.",
  publicHandleMin: "Handle di almeno 3 caratteri, poi il server salva.",
  publicSignIn: "Accedi perché il profilo compaia su altri dispositivi.",
  publicInvalidHandle: "Handle: a–z, 0–9, underscore, 3–24 caratteri.",
  publicServerLocal: "Il server non ha salvato — lo stand resta qui.",
  publicSaved: (handle) => `Salvato. Visibile sotto /u/${handle}.`,
  publicOffline: "Niente rete — lo stand resta in questo browser.",
  publicEditorial: "Esempio editoriale",
  publicMissingTitle: "Profilo non pubblico",
  publicMissingHint:
    "Questo handle non è attivo o non esiste. I profili pubblici sono opt-in e non salvano tracce.",
  publicRidesAgg: (n) => `${n} uscite (aggregate, senza traccia)`,
  publicNoHeatmap: "Niente heatmap, niente GPS grezzo su questo profilo.",
  publicStimmen: "Stimmen",
  publicTour: "Percorso",
  sportMtb: "MTB",
  sportEbike: "E-bike",
  sportTouring: "Touring",
};

const NL: ProfileCopy = {
  account: "Account",
  sync: "Sync",
  signOut: "Uitloggen",
  deleteAccount: "Account verwijderen",
  status: "Status",
  local: "lokaal",
  syncFailed: "Sync mislukt",
  checkoutFailed: "Checkout mislukt",
  billingFailed: "Factureringsfout",
  portalFailed: "Portaal mislukt",
  deleteConfirmTitle: "Account verwijderen?",
  deleteConfirmBody:
    "Remote-account en lokale app-gegevens worden verwijderd. Exporteer eerst GPX/JSON onder Gegevens & privacy.",
  deleteTypeDelete: "Typ DELETE ter bevestiging:",
  deleteAborted: "Afgebroken — bevestiging was niet DELETE.",
  remoteDeleted: "Remote-account verwijderd.",
  remoteUnavailable:
    "Remote-verwijderen niet beschikbaar — alleen lokale gegevens gaan weg.",
  notSignedInLocal: "Niet aangemeld — alleen lokale gegevens gaan weg.",
  remoteFailed: (detail) =>
    `Remote-verwijderen mislukt (${detail}) — lokaal toch gewist.`,
  serverUnreachable: "Server onbereikbaar — alleen lokale gegevens gaan weg.",
  localCleared: "Lokale gegevens gewist. Exporteer onder Privacy als je ze nog nodig hebt.",
  plan: "Abonnement",
  planHint:
    "Free: 1 fiets, basis. Pro: meer fietsen, variantvergelijk, actieradius. Offline-routing in de app — beide niveaus. AI-coach — €6,99/mnd of €59,99/jaar.",
  current: "Huidig",
  commerceClosed:
    "Ontwikkelstand — aankopen uit. Lokaal kun je blijven testen; er is geen openbaar abonnement.",
  proMonth: "Pro €6,99/mnd",
  proYear: "Pro €59,99/jaar",
  managePortal: "Abonnement beheren (Stripe-portaal)",
  upgradeSignIn:
    "Log in om te upgraden. Zonder account blijft Free lokaal.",
  styleAggressive: "Agressief",
  styleFlow: "Flow",
  styleEfficient: "Efficiënt",
  styleExploring: "Ontdekken",
  skill: (n) => `Niveau (${n} / 5)`,
  riderWeight: "Rijdersgewicht (kg)",
  advancedShow: "Geavanceerde instellingen (terrein & indicatoren)",
  advancedHide: "Geavanceerde instellingen verbergen",
  terrain: "Terreinaandeel",
  terrainS0: "S0–S1 / easy",
  terrainS2: "S2",
  terrainS3: "S3+",
  terrainGravel: "Gravel/weg",
  brakeBeforeCorners: "Remmen voor bochten",
  lateralG: "% tijd > 0,4 g zijwaarts",
  impactsPerHour: "Impacts / uur",
  jumpsPerRide: "Sprongen / rit",
  preferences: "Voorkeuren",
  preferTechnical: "Technisch",
  preferFlow: "Flow",
  preferSteep: "Steil",
  eBikeAssist: "E-bike-ondersteuning (logging)",
  rangeTitle: "Actieradius-kalibratie",
  bikeFront: "voor",
  explainStyle:
    "Uit impactfrequentie en flow-scores van je ritten — altijd te corrigeren.",
  explainSkill: "Zelfscore 1–5; beïnvloedt routesuggesties en actieradius.",
  explainTechnical: "Weegt routes met hogere mtb:scale en wortelig terrein.",
  explainFlow: "Geeft de voorkeur aan flow-trails en compacte ondergrond in Discover.",
  explainSteep: "Tilt routes met meer hoogtemeters en steilere hellingen.",
  explainAssist: "Alleen logging en actieradius — geen motorsturing.",
  explainWeight: "Voor SAG-sjablonen en actieradius — lokaal, altijd te wijzigen.",
  explainTerrain: "Verdeling van trailmoeilijkheid / ondergrond uit je geschiedenis.",
  explainIndicators:
    "Remmen, zijwaartse g, impacts, sprongen — uitlegbaar en te corrigeren.",
  publicTitle: "Openbaar profiel",
  publicHint:
    "Opt-in. Handle bij Stimmen, geen tracks, geen tab. Met een account staat het op de server, niet alleen in deze browser.",
  publicEnable: "Profiel openbaar maken",
  publicDisplayName: "Weergavenaam",
  publicHandle: "Handle",
  publicHandleHint: "Handle (a-z, 0-9, _)",
  publicBio: "Bio",
  publicRegion: "Regio",
  publicRegionPh: "bijv. Baden-Württemberg",
  publicSports: "Disciplines",
  publicShowRides: "Rittaantal tonen",
  publicView: (handle) => `Profiel bekijken → /u/${handle}`,
  publicSaving: "Opslaan…",
  publicSynced: "Gesynchroniseerd met het account.",
  publicHandleMin: "Handle minstens 3 tekens, daarna slaat de server op.",
  publicSignIn: "Meld je aan zodat het profiel op andere apparaten verschijnt.",
  publicInvalidHandle: "Handle: a–z, 0–9, underscore, 3–24 tekens.",
  publicServerLocal: "Server heeft niet opgeslagen — de stand blijft hier.",
  publicSaved: (handle) => `Opgeslagen. Zichtbaar onder /u/${handle}.`,
  publicOffline: "Geen netwerk — de stand blijft in deze browser.",
  publicEditorial: "Redactioneel voorbeeld",
  publicMissingTitle: "Profiel is niet openbaar",
  publicMissingHint:
    "Dit handle is niet vrijgegeven of bestaat niet. Openbare profielen zijn opt-in en slaan geen tracks op.",
  publicRidesAgg: (n) => `${n} ritten (geaggregeerd, zonder spoor)`,
  publicNoHeatmap: "Geen heatmaps, geen ruwe GPS op dit profiel.",
  publicStimmen: "Stimmen",
  publicTour: "Tocht",
  sportMtb: "MTB",
  sportEbike: "E-bike",
  sportTouring: "Toeren",
};

const BY: Record<ChromeLang, ProfileCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function profileCopy(lang: ChromeLang = "de"): ProfileCopy {
  return BY[lang] ?? DE;
}

export function publicSportLabel(id: string, lang: ChromeLang): string {
  const c = profileCopy(lang);
  if (id === "mtb") return c.sportMtb;
  if (id === "ebike") return c.sportEbike;
  if (id === "touring") return c.sportTouring;
  return id;
}

/** Chip on public profile: bike category, then mtb/ebike/touring aliases. */
export function publicDisciplineLabel(id: string, lang: ChromeLang): string {
  const named = rideSportLabel(id, lang);
  if (named !== id) return named;
  return publicSportLabel(id, lang);
}
