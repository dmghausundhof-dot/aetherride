import { chromeLangFrom, type ChromeLang } from "./chromeLang";

export function chatLangFromBody(raw: unknown): ChromeLang {
  return chromeLangFrom(typeof raw === "string" ? raw : "");
}

function noneWord(lang: ChromeLang): string {
  switch (lang) {
    case "en":
      return "none";
    case "fr":
      return "aucun";
    case "it":
      return "nessuno";
    default:
      return "keine";
  }
}

/** Exact DE system prompt from the live Grok call. */
export function chatSystemPrompt(
  lang: ChromeLang,
  whitelist: string,
  facts: string,
): string {
  const none = noneWord(lang);
  const w = whitelist || none;
  const f = facts || none;
  switch (lang) {
    case "en":
      return `You are the FlowLine AI coach. You ONLY rephrase the given engine results.
Rules: Invent NO numbers. Use only these whitelist numbers: ${w}.
Facts: ${f}.
Facts may be in German; reply in English.
Reply briefly in English (max 3 sentences). No new metrics.`;
    case "fr":
      return `Tu es le coach IA FlowLine. Tu reformules UNIQUEMENT les résultats moteur donnés.
Règles : n’invente AUCUN chiffre. Utilise uniquement ces chiffres whitelist : ${w}.
Faits : ${f}.
Les faits peuvent être en allemand ; réponds en français.
Réponds brièvement en français (max 3 phrases). Pas de nouvelles métriques.`;
    case "it":
      return `Sei il coach IA FlowLine. Riformuli SOLO i risultati del motore.
Regole: non inventare NESSUN numero. Usa solo questi numeri whitelist: ${w}.
Fatti: ${f}.
I fatti possono essere in tedesco; rispondi in italiano.
Rispondi brevemente in italiano (max 3 frasi). Niente nuove metriche.`;
    default:
      return `Du bist FlowLine KI-Coach. Du formulierst NUR die gegebenen Engine-Ergebnisse um.
Regeln: Erfinde KEINE Zahlen. Verwende ausschließlich diese Whitelist-Zahlen: ${w}.
Fakten: ${f}.
Antwort kurz auf Deutsch (max 3 Sätze). Keine neuen Metriken.`;
  }
}

export function chatUserMessage(
  lang: ChromeLang,
  query: string,
  rawAnswer: string,
): string {
  switch (lang) {
    case "en":
      return `User question: ${query}\nEngine raw answer: ${rawAnswer}`;
    case "fr":
      return `Question : ${query}\nRéponse brute du moteur : ${rawAnswer}`;
    case "it":
      return `Domanda: ${query}\nRisposta grezza del motore: ${rawAnswer}`;
    default:
      return `Nutzerfrage: ${query}\nEngine-Rohantwort: ${rawAnswer}`;
  }
}
