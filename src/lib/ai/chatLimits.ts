/**
 * Free/Pro chat quotas — prevents Grok cost explosion (Spec 1.4 + cost control).
 */

export type ChatTier = "free" | "pro" | "anonymous";

export interface ChatLimits {
  day: number;
  month: number;
  maxTokensOut: number;
  maxInputChars: number;
}

function envInt(name: string, fallback: number): number {
  const v = process.env[name];
  if (!v) return fallback;
  const n = Number(v);
  return Number.isFinite(n) && n >= 0 ? n : fallback;
}

export function limitsForTier(tier: ChatTier): ChatLimits {
  if (tier === "pro") {
    return {
      day: envInt("CHAT_LIMIT_PRO_DAY", 50),
      month: envInt("CHAT_LIMIT_PRO_MONTH", 500),
      maxTokensOut: 800,
      maxInputChars: 2000,
    };
  }
  if (tier === "anonymous") {
    return {
      day: envInt("CHAT_LIMIT_ANON_DAY", 5),
      month: 5,
      maxTokensOut: 0,
      maxInputChars: 500,
    };
  }
  return {
    day: envInt("CHAT_LIMIT_FREE_DAY", 5),
    month: envInt("CHAT_LIMIT_FREE_MONTH", 40),
    maxTokensOut: 400,
    maxInputChars: 500,
  };
}

export function utcDay(d = new Date()): string {
  return d.toISOString().slice(0, 10);
}

export function utcMonthPrefix(d = new Date()): string {
  return d.toISOString().slice(0, 7);
}

export function dayResetAt(d = new Date()): string {
  const next = new Date(
    Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate() + 1)
  );
  return next.toISOString();
}
