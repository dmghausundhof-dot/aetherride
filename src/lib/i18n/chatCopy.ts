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
  prompts: ChatSuggested[];
};

const DE: ChatCopy = {
  title: "Mehr fragen",
  welcome:
    "Frag nach dem, was ansteht, nach Garage, Setup, Reichweite, Routen oder Teilen. Zahlen kommen aus deinen App-Daten — nicht aus dem Chat-Modell.",
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
  checkedOnData: "Antwort anhand deiner Garage-/Ride-Daten geprüft",
  prompts: [
    { label: "Was steht an?", query: "Was steht an?", tool: "watch" },
    {
      label: "Garage-Überblick",
      query: "Was steckt in meiner Garage?",
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
      label: "Verschleiß / Shop",
      query: "Brauche ich bald neue Verschleißteile?",
      tool: "product_search",
    },
  ],
};

const EN: ChatCopy = {
  title: "Ask more",
  welcome:
    "Ask what’s due, or about garage, setup, range, routes, or parts. Numbers come from your app data — not from the chat model.",
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
  checkedOnData: "Reply checked against your garage/ride data",
  prompts: [
    { label: "What’s due?", query: "What’s due?", tool: "watch" },
    {
      label: "Garage",
      query: "What’s in my garage?",
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
      label: "Wear / shop",
      query: "Will I need wear parts soon?",
      tool: "product_search",
    },
  ],
};

const FR: ChatCopy = {
  title: "Demande plus",
  welcome:
    "Demande ce qui est dû, ou garage, setup, autonomie, itinéraires, pièces. Les chiffres viennent de tes données app — pas du modèle de chat.",
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
  checkedOnData: "Réponse vérifiée sur tes données garage/sortie",
  prompts: [
    {
      label: "Qu’est-ce qui est dû ?",
      query: "Qu’est-ce qui est dû ?",
      tool: "watch",
    },
    {
      label: "Garage",
      query: "Qu’est-ce qu’il y a dans mon garage ?",
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
      label: "Usure / magasin",
      query: "Bientôt besoin de pièces d’usure ?",
      tool: "product_search",
    },
  ],
};

const IT: ChatCopy = {
  title: "Chiedi di più",
  welcome:
    "Chiedi cosa è in scadenza, o garage, setup, autonomia, itinerari, pezzi. I numeri arrivano dai dati app — non dal modello di chat.",
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
  checkedOnData: "Risposta controllata sui dati garage/uscita",
  prompts: [
    {
      label: "Cosa è in scadenza?",
      query: "Cosa è in scadenza?",
      tool: "watch",
    },
    {
      label: "Garage",
      query: "Cosa c’è nel mio garage?",
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
      label: "Usura / negozio",
      query: "Presto mi servono consumabili?",
      tool: "product_search",
    },
  ],
};

const NL: ChatCopy = {
  title: "Meer vragen",
  welcome:
    "Vraag wat er aan de beurt is, of naar garage, setup, actieradius, routes of onderdelen. Cijfers komen uit je app-data — niet uit het chatmodel.",
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
  checkedOnData: "Antwoord gecontroleerd op je garage-/ritdata",
  prompts: [
    {
      label: "Wat is er aan de beurt?",
      query: "Wat is er aan de beurt?",
      tool: "watch",
    },
    {
      label: "Garage",
      query: "Wat zit er in mijn garage?",
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
