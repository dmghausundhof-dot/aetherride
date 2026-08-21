import type { ChatToolName } from "@/lib/ai/chat";
import type { ChromeLang } from "./chromeLang";

export type ChatSuggested = {
  label: string;
  query: string;
  tool: ChatToolName;
};

export type ChatCopy = {
  title: string;
  welcome: string;
  lockedRiding: string;
  hint: string;
  send: string;
  noAnswer: string;
  networkError: string;
  limitReached: string;
  limitFreeMore: string;
  limitTomorrow: string;
  quota: (used: string, limit: string, remaining: string) => string;
  quotaToday: (tier: string, used: number, limit: number, remaining?: number) => string;
  loginForCloud: string;
  tariffLine: (tier: string) => string;
  freeLimit: string;
  upgradePro: string;
  freeProFoot: string;
  checkedOnData: string;
  rideStats: (count: string, km: string, hm: string) => string;
  incompleteData: string;
  noBikeStand: string;
  noBikeCompat: string;
  noBikeSetup: string;
  noBikeRoute: string;
  noBikeShop: string;
  noSetups: string;
  rangeEbikeOnly: string;
  unknownTool: string;
  shopPaused: string;
  noRoutes: string;
  rideWindowNeedGps: string;
  rideWindowSport: string;
  garageStand: (names: string) => string;
  rangeAnswer: (
    low: string,
    high: string,
    whLow: string,
    whHigh: string,
    conf: string
  ) => string;
  watchNothing: string;
  inboxEmpty: string;
  inboxAsk: string;
  inboxOpen: string;
  inboxPlace: string;
  inboxSnooze: string;
  sevOverdue: string;
  sevSoon: string;
  sevInfo: string;
  sevNew: string;
  feedbackTitle: string;
  feedbackDetail: string;
  prompts: ChatSuggested[];
};

const DE: ChatCopy = {
  title: "Mehr fragen",
  welcome:
    "Frag nach dem, was ansteht, nach Rad, Setup, Reichweite, Routen oder Teilen. Zahlen kommen aus deinen App-Daten — nicht aus dem Chat-Modell.",
  lockedRiding: "Während der Fahrt ist Chat gesperrt.",
  hint: "Nachricht…",
  send: "Senden",
  noAnswer: "Keine Antwort.",
  networkError: "Netzwerkfehler",
  limitReached: "Limit erreicht.",
  limitFreeMore: "Pro unter Profil freischalten für mehr Antworten.",
  limitTomorrow: "Morgen wieder verfügbar.",
  quota: (used, limit, remaining) =>
    `Kontingent: ${used} / ${limit} · noch ${remaining}`,
  quotaToday: (tier, used, limit, remaining) =>
    `Kontingent (${tier}): ${used}/${limit} heute${
      remaining != null ? ` · ${remaining} übrig` : ""
    }`,
  loginForCloud: "Anmeldung für Cloud-KI nötig",
  tariffLine: (tier) => `Tarif: ${tier} — Tageslimits nach Anmeldung`,
  freeLimit: "Free-Limit ausgeschöpft.",
  upgradePro: "Pro upgraden",
  freeProFoot: "Free: 5/Tag · Pro: 50/Tag",
  checkedOnData: "Antwort anhand deiner Rad- und Fahrtdaten geprüft",
  rideStats: (count, km, hm) =>
    `Ride-Statistik: ${count} Fahrten, ${km} km, ${hm} hm — nur aus gespeicherten Rides.`,
  incompleteData:
    "Daten unvollständig — keine belastbare Antwort. Rad oder Fahrten prüfen.",
  noBikeStand: "Kein Rad am Stand — Daten fehlen.",
  noBikeCompat: "Kein aktives Rad — Kompatibilität nicht prüfbar.",
  noBikeSetup: "Kein Rad — Setup-Historie fehlt.",
  noBikeRoute: "Routensuche braucht ein aktives Rad.",
  noBikeShop: "Produktsuche braucht ein aktives Rad.",
  noSetups: "Keine Setup-Versionen vorhanden.",
  rangeEbikeOnly: "Reichweite nur für E-Bikes.",
  unknownTool: "Unbekanntes Werkzeug — Daten fehlen.",
  shopPaused: "Der Teile-Shop ist vorerst aus. Pflege und Setup bleiben am Rad.",
  noRoutes: "Keine Routen für diese Kategorie.",
  rideWindowNeedGps:
    "Standort setzen — dann sag ich, wann es heute trockener ist.",
  rideWindowSport: "Fenster nur für Gravel und MTB.",
  garageStand: (names) =>
    `An deinem Stand: ${names}. Aktive Komponenten und km stammen vom Rad.`,
  rangeAnswer: (low, high, whLow, whHigh, conf) =>
    `Reichweite ${low}–${high} km (${whLow}–${whHigh} Wh/km), Konfidenz ${conf}.`,
  watchNothing:
    "Gerade steht nichts an. Wartung, Verschleiß, Setup und Kompatibilität sind im grünen Bereich.",
  inboxEmpty:
    "Nichts steht an. Der Assistent schaut auf Wartung, Verschleiß, Setup und Kompatibilität.",
  inboxAsk: "Assistent fragen",
  inboxOpen: "Öffnen",
  inboxPlace: "Zur Stelle",
  inboxSnooze: "7 Tage still",
  sevOverdue: "Überfällig",
  sevSoon: "Bald",
  sevInfo: "Hinweis",
  sevNew: "neu",
  feedbackTitle: "Kurzes Feedback zur letzten Fahrt",
  feedbackDetail: "Drei Taps — der Assistent nutzt das für Setup-Hinweise.",
  prompts: [
    { label: "Was steht an?", query: "Was steht an?", tool: "watch" },
    {
      label: "Rad-Überblick",
      query: "Was steht an meinem Rad?",
      tool: "garage",
    },
    {
      label: "Reichweite",
      query: "Welche Reichweite habe ich mit aktuellem Akku?",
      tool: "range",
    },
    {
      label: "Setup-Historie",
      query: "Welche Setups hatte ich und was hat sich geändert?",
      tool: "setup_history",
    },
    {
      label: "Ride-Stats",
      query: "Zusammenfassung meiner letzten Rides",
      tool: "ride_stats",
    },
    {
      label: "Routen",
      query: "Welche Routen passen zu mir?",
      tool: "route_search",
    },
    {
      label: "Trockener Fenster",
      query: "Wann ist es heute trockener?",
      tool: "ride_window",
    },
    {
      label: "Verschleiß / Shop",
      query: "Brauche ich bald neue Verschleißteile?",
      tool: "product_search",
    },
  ],
};

const EN: ChatCopy = {
  title: "Ask more",
  welcome:
    "Ask what’s due, or about the bike, setup, range, routes, or parts. Numbers come from your app data — not from the chat model.",
  lockedRiding: "Chat is locked while riding.",
  hint: "Message…",
  send: "Send",
  noAnswer: "No answer.",
  networkError: "Network error",
  limitReached: "Limit reached.",
  limitFreeMore: "Unlock Pro under Profile for more replies.",
  limitTomorrow: "Available again tomorrow.",
  quota: (used, limit, remaining) =>
    `Quota: ${used} / ${limit} · ${remaining} left`,
  quotaToday: (tier, used, limit, remaining) =>
    `Quota (${tier}): ${used}/${limit} today${
      remaining != null ? ` · ${remaining} left` : ""
    }`,
  loginForCloud: "Sign-in needed for cloud AI",
  tariffLine: (tier) => `Plan: ${tier} — daily limits after sign-in`,
  freeLimit: "Free limit used up.",
  upgradePro: "Upgrade to Pro",
  freeProFoot: "Free: 5/day · Pro: 50/day",
  checkedOnData: "Reply checked against your bike and ride data",
  rideStats: (count, km, hm) =>
    `Ride stats: ${count} rides, ${km} km, ${hm} hm — stored rides only.`,
  incompleteData:
    "Data incomplete — no reliable answer. Check the bike or rides.",
  noBikeStand: "No bike at the stand — data missing.",
  noBikeCompat: "No active bike — compatibility can’t be checked.",
  noBikeSetup: "No bike — setup history missing.",
  noBikeRoute: "Route search needs an active bike.",
  noBikeShop: "Product search needs an active bike.",
  noSetups: "No setup versions yet.",
  rangeEbikeOnly: "Range is only for e-bikes.",
  unknownTool: "Unknown tool — data missing.",
  shopPaused: "The parts shop is off for now. Care and setup stay on the bike.",
  noRoutes: "No routes for this category.",
  rideWindowNeedGps:
    "Set a location — then I can say when today is drier.",
  rideWindowSport: "Windows only for gravel and MTB.",
  garageStand: (names) =>
    `At your stand: ${names}. Active parts and km come from the bike.`,
  rangeAnswer: (low, high, whLow, whHigh, conf) =>
    `Range ${low}–${high} km (${whLow}–${whHigh} Wh/km), confidence ${conf}.`,
  watchNothing:
    "Nothing due right now. Maintenance, wear, setup and compatibility look fine.",
  inboxEmpty:
    "Nothing due. The assistant watches maintenance, wear, setup and compatibility.",
  inboxAsk: "Ask the assistant",
  inboxOpen: "Open",
  inboxPlace: "Go there",
  inboxSnooze: "Quiet 7 days",
  sevOverdue: "Overdue",
  sevSoon: "Soon",
  sevInfo: "Note",
  sevNew: "new",
  feedbackTitle: "Quick feedback on the last ride",
  feedbackDetail: "Three taps — the assistant uses that for setup hints.",
  prompts: [
    { label: "What’s due?", query: "What’s due?", tool: "watch" },
    {
      label: "Bike",
      query: "What’s on my bike?",
      tool: "garage",
    },
    {
      label: "Range",
      query: "What range do I have with the current battery?",
      tool: "range",
    },
    {
      label: "Setups",
      query: "Which setups have I used, and what changed?",
      tool: "setup_history",
    },
    {
      label: "Rides",
      query: "Summary of my recent rides",
      tool: "ride_stats",
    },
    {
      label: "Routes",
      query: "Which routes fit me?",
      tool: "route_search",
    },
    {
      label: "Drier window",
      query: "When is it drier today?",
      tool: "ride_window",
    },
    {
      label: "Wear / shop",
      query: "Will I need wear parts soon?",
      tool: "product_search",
    },
  ],
};

const FR: ChatCopy = {
  title: "Demande plus",
  welcome:
    "Demande ce qui est dû, ou le vélo, setup, autonomie, itinéraires, pièces. Les chiffres viennent de tes données app — pas du modèle de chat.",
  lockedRiding: "Le chat est bloqué pendant la sortie.",
  hint: "Message…",
  send: "Envoyer",
  noAnswer: "Pas de réponse.",
  networkError: "Erreur réseau",
  limitReached: "Limite atteinte.",
  limitFreeMore: "Débloque Pro sous Profil pour plus de réponses.",
  limitTomorrow: "De nouveau demain.",
  quota: (used, limit, remaining) =>
    `Quota : ${used} / ${limit} · encore ${remaining}`,
  quotaToday: (tier, used, limit, remaining) =>
    `Quota (${tier}) : ${used}/${limit} aujourd’hui${
      remaining != null ? ` · ${remaining} restant` : ""
    }`,
  loginForCloud: "Connexion nécessaire pour l’IA cloud",
  tariffLine: (tier) => `Offre : ${tier} — limites du jour après connexion`,
  freeLimit: "Limite Free épuisée.",
  upgradePro: "Passer à Pro",
  freeProFoot: "Free : 5/jour · Pro : 50/jour",
  checkedOnData: "Réponse vérifiée sur tes données vélo/sortie",
  rideStats: (count, km, hm) =>
    `Stats sorties : ${count} sorties, ${km} km, ${hm} hm — uniquement les sorties enregistrées.`,
  incompleteData:
    "Données incomplètes — pas de réponse fiable. Vérifie le vélo ou les sorties.",
  noBikeStand: "Pas de vélo au stand — données manquantes.",
  noBikeCompat: "Pas de vélo actif — compatibilité non vérifiable.",
  noBikeSetup: "Pas de vélo — historique de setup manquant.",
  noBikeRoute: "La recherche d’itinéraire a besoin d’un vélo actif.",
  noBikeShop: "La recherche produit a besoin d’un vélo actif.",
  noSetups: "Aucune version de setup.",
  rangeEbikeOnly: "Autonomie seulement pour les VTTAE.",
  unknownTool: "Outil inconnu — données manquantes.",
  shopPaused: "La boutique pièces est en pause. Entretien et setup restent sur le vélo.",
  noRoutes: "Pas d’itinéraires pour cette catégorie.",
  rideWindowNeedGps:
    "Indique un lieu — ensuite je dis quand c’est plus sec aujourd’hui.",
  rideWindowSport: "Créneau seulement pour gravel et VTT.",
  garageStand: (names) =>
    `À ton stand : ${names}. Pièces actives et km viennent du vélo.`,
  rangeAnswer: (low, high, whLow, whHigh, conf) =>
    `Autonomie ${low}–${high} km (${whLow}–${whHigh} Wh/km), confiance ${conf}.`,
  watchNothing:
    "Rien n’est dû. Entretien, usure, setup et compatibilité sont au vert.",
  inboxEmpty:
    "Rien n’est dû. L’assistant surveille entretien, usure, setup et compatibilité.",
  inboxAsk: "Demander à l’assistant",
  inboxOpen: "Ouvrir",
  inboxPlace: "Y aller",
  inboxSnooze: "Silence 7 jours",
  sevOverdue: "En retard",
  sevSoon: "Bientôt",
  sevInfo: "Note",
  sevNew: "nouveau",
  feedbackTitle: "Court retour sur la dernière sortie",
  feedbackDetail: "Trois taps — l’assistant s’en sert pour le setup.",
  prompts: [
    {
      label: "Qu’est-ce qui est dû ?",
      query: "Qu’est-ce qui est dû ?",
      tool: "watch",
    },
    {
      label: "Vélo",
      query: "Qu’est-ce qu’il y a sur mon vélo ?",
      tool: "garage",
    },
    {
      label: "Autonomie",
      query: "Quelle autonomie avec la batterie actuelle ?",
      tool: "range",
    },
    {
      label: "Setups",
      query: "Quels setups j’ai eus et qu’est-ce qui a changé ?",
      tool: "setup_history",
    },
    {
      label: "Sorties",
      query: "Résumé de mes dernières sorties",
      tool: "ride_stats",
    },
    {
      label: "Itinéraires",
      query: "Quels itinéraires me collent ?",
      tool: "route_search",
    },
    {
      label: "Créneau plus sec",
      query: "Quand est-ce plus sec aujourd’hui ?",
      tool: "ride_window",
    },
    {
      label: "Usure / magasin",
      query: "Bientôt besoin de pièces d’usure ?",
      tool: "product_search",
    },
  ],
};

const IT: ChatCopy = {
  title: "Chiedi di più",
  welcome:
    "Chiedi cosa è in scadenza, o la bici, setup, autonomia, itinerari, pezzi. I numeri arrivano dai dati app — non dal modello di chat.",
  lockedRiding: "La chat è bloccata durante l’uscita.",
  hint: "Messaggio…",
  send: "Invia",
  noAnswer: "Nessuna risposta.",
  networkError: "Errore di rete",
  limitReached: "Limite raggiunto.",
  limitFreeMore: "Sblocca Pro sotto Profilo per più risposte.",
  limitTomorrow: "Di nuovo domani.",
  quota: (used, limit, remaining) =>
    `Quota: ${used} / ${limit} · ancora ${remaining}`,
  quotaToday: (tier, used, limit, remaining) =>
    `Quota (${tier}): ${used}/${limit} oggi${
      remaining != null ? ` · ${remaining} rimasti` : ""
    }`,
  loginForCloud: "Accesso necessario per l’IA cloud",
  tariffLine: (tier) => `Piano: ${tier} — limiti del giorno dopo l’accesso`,
  freeLimit: "Limite Free esaurito.",
  upgradePro: "Passa a Pro",
  freeProFoot: "Free: 5/giorno · Pro: 50/giorno",
  checkedOnData: "Risposta controllata sui dati bici/uscita",
  rideStats: (count, km, hm) =>
    `Statistiche uscite: ${count} uscite, ${km} km, ${hm} hm — solo uscite salvate.`,
  incompleteData:
    "Dati incompleti — nessuna risposta affidabile. Controlla bici o uscite.",
  noBikeStand: "Nessuna bici allo stand — dati mancanti.",
  noBikeCompat: "Nessuna bici attiva — compatibilità non verificabile.",
  noBikeSetup: "Nessuna bici — cronologia setup mancante.",
  noBikeRoute: "La ricerca itinerari serve una bici attiva.",
  noBikeShop: "La ricerca prodotti serve una bici attiva.",
  noSetups: "Nessuna versione di setup.",
  rangeEbikeOnly: "Autonomia solo per e-bike.",
  unknownTool: "Strumento sconosciuto — dati mancanti.",
  shopPaused: "Il negozio pezzi è in pausa. Cura e setup restano sulla bici.",
  noRoutes: "Nessun itinerario per questa categoria.",
  rideWindowNeedGps:
    "Imposta la posizione — poi dico quando oggi è più asciutto.",
  rideWindowSport: "Finestra solo per gravel e MTB.",
  garageStand: (names) =>
    `Al tuo stand: ${names}. Parti attive e km vengono dalla bici.`,
  rangeAnswer: (low, high, whLow, whHigh, conf) =>
    `Autonomia ${low}–${high} km (${whLow}–${whHigh} Wh/km), confidenza ${conf}.`,
  watchNothing:
    "Nulla in scadenza. Manutenzione, usura, setup e compatibilità sono a posto.",
  inboxEmpty:
    "Nulla in scadenza. L’assistente guarda manutenzione, usura, setup e compatibilità.",
  inboxAsk: "Chiedi all’assistente",
  inboxOpen: "Apri",
  inboxPlace: "Vai lì",
  inboxSnooze: "Silenzio 7 giorni",
  sevOverdue: "Scaduto",
  sevSoon: "Presto",
  sevInfo: "Nota",
  sevNew: "nuovo",
  feedbackTitle: "Feedback breve sull’ultima uscita",
  feedbackDetail: "Tre tap — l’assistente lo usa per il setup.",
  prompts: [
    {
      label: "Cosa è in scadenza?",
      query: "Cosa è in scadenza?",
      tool: "watch",
    },
    {
      label: "Bici",
      query: "Cosa c’è sulla mia bici?",
      tool: "garage",
    },
    {
      label: "Autonomia",
      query: "Che autonomia ho con la batteria attuale?",
      tool: "range",
    },
    {
      label: "Setup",
      query: "Quali setup ho avuto e cosa è cambiato?",
      tool: "setup_history",
    },
    {
      label: "Uscite",
      query: "Riassunto delle mie ultime uscite",
      tool: "ride_stats",
    },
    {
      label: "Itinerari",
      query: "Quali itinerari mi calzano?",
      tool: "route_search",
    },
    {
      label: "Finestra più asciutta",
      query: "Quando è più asciutto oggi?",
      tool: "ride_window",
    },
    {
      label: "Usura / negozio",
      query: "Presto mi servono consumabili?",
      tool: "product_search",
    },
  ],
};

const NL: ChatCopy = {
  title: "Meer vragen",
  welcome:
    "Vraag wat er aan de beurt is, of naar de fiets, setup, actieradius, routes of onderdelen. Cijfers komen uit je app-data — niet uit het chatmodel.",
  lockedRiding: "Tijdens de rit is chat geblokkeerd.",
  hint: "Bericht…",
  send: "Versturen",
  noAnswer: "Geen antwoord.",
  networkError: "Netwerkfout",
  limitReached: "Limiet bereikt.",
  limitFreeMore: "Pro onder Profiel vrijschakelen voor meer antwoorden.",
  limitTomorrow: "Morgen weer beschikbaar.",
  quota: (used, limit, remaining) =>
    `Quota: ${used} / ${limit} · nog ${remaining}`,
  quotaToday: (tier, used, limit, remaining) =>
    `Quota (${tier}): ${used}/${limit} vandaag${
      remaining != null ? ` · ${remaining} over` : ""
    }`,
  loginForCloud: "Aanmelden nodig voor cloud-AI",
  tariffLine: (tier) => `Tarief: ${tier} — daglimieten na aanmelden`,
  freeLimit: "Free-limiet opgebruikt.",
  upgradePro: "Upgraden naar Pro",
  freeProFoot: "Free: 5/dag · Pro: 50/dag",
  checkedOnData: "Antwoord gecontroleerd op je fiets- en ritdata",
  rideStats: (count, km, hm) =>
    `Ritstatistiek: ${count} ritten, ${km} km, ${hm} hm — alleen opgeslagen ritten.`,
  incompleteData:
    "Data onvolledig — geen betrouwbaar antwoord. Check fiets of ritten.",
  noBikeStand: "Geen fiets aan de stand — data ontbreekt.",
  noBikeCompat: "Geen actieve fiets — compatibiliteit niet te toetsen.",
  noBikeSetup: "Geen fiets — setupgeschiedenis ontbreekt.",
  noBikeRoute: "Routezoeken heeft een actieve fiets nodig.",
  noBikeShop: "Productzoeken heeft een actieve fiets nodig.",
  noSetups: "Nog geen setupversies.",
  rangeEbikeOnly: "Actieradius alleen voor e-bikes.",
  unknownTool: "Onbekend gereedschap — data ontbreekt.",
  shopPaused: "De onderdelenwinkel staat even uit. Zorg en setup blijven aan de fiets.",
  noRoutes: "Geen routes voor deze categorie.",
  rideWindowNeedGps:
    "Zet een locatie — dan zeg ik wanneer het vandaag droger is.",
  rideWindowSport: "Venster alleen voor gravel en MTB.",
  garageStand: (names) =>
    `Aan je stand: ${names}. Actieve delen en km komen van de fiets.`,
  rangeAnswer: (low, high, whLow, whHigh, conf) =>
    `Actieradius ${low}–${high} km (${whLow}–${whHigh} Wh/km), betrouwbaarheid ${conf}.`,
  watchNothing:
    "Niets aan de beurt. Onderhoud, slijtage, setup en compatibiliteit staan groen.",
  inboxEmpty:
    "Niets aan de beurt. De assistent kijkt naar onderhoud, slijtage, setup en compatibiliteit.",
  inboxAsk: "Assistent vragen",
  inboxOpen: "Openen",
  inboxPlace: "Naar de plek",
  inboxSnooze: "7 dagen stil",
  sevOverdue: "Te laat",
  sevSoon: "Binnenkort",
  sevInfo: "Hint",
  sevNew: "nieuw",
  feedbackTitle: "Korte feedback over de laatste rit",
  feedbackDetail: "Drie taps — de assistent gebruikt dat voor setup-hints.",
  prompts: [
    {
      label: "Wat is er aan de beurt?",
      query: "Wat is er aan de beurt?",
      tool: "watch",
    },
    {
      label: "Fiets",
      query: "Wat staat er aan mijn fiets?",
      tool: "garage",
    },
    {
      label: "Actieradius",
      query: "Welke actieradius heb ik met de huidige accu?",
      tool: "range",
    },
    {
      label: "Setups",
      query: "Welke setups had ik en wat is er veranderd?",
      tool: "setup_history",
    },
    {
      label: "Ritten",
      query: "Samenvatting van mijn laatste ritten",
      tool: "ride_stats",
    },
    {
      label: "Routes",
      query: "Welke routes passen bij mij?",
      tool: "route_search",
    },
    {
      label: "Droger venster",
      query: "Wanneer is het vandaag droger?",
      tool: "ride_window",
    },
    {
      label: "Slijtage / winkel",
      query: "Heb ik binnenkort nieuwe slijtdelen nodig?",
      tool: "product_search",
    },
  ],
};

const BY_LANG: Record<ChromeLang, ChatCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function chatCopy(lang: ChromeLang): ChatCopy {
  return BY_LANG[lang];
}
