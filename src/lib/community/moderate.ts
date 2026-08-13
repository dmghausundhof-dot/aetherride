/**
 * Community moderation — rules first, then optional Grok/xAI.
 *
 * Policy:
 * - Reviews: auto-reject (rules/AI), auto-approve only if AI is highly
 *   confident and labels are clean; otherwise stay pending for a human.
 * - Photos: auto-reject unsafe content; never auto-approve (queue).
 */

export type ModerationKind = "review" | "photo";
export type ModerationAction = "approved" | "rejected" | "pending";
export type ModerationSource = "ai" | "human" | "rule";

export type ModerationInput = {
  kind: ModerationKind;
  text: string;
  rating?: number;
  imageUrl?: string | null;
};

export type ModerationResult = {
  action: ModerationAction;
  source: ModerationSource;
  confidence: number;
  labels: string[];
  note: string;
  model?: string;
};

const REJECT_RE =
  /\b(nazi|hitler|holocaust.?leug|kinderporn|child\s*porn|csam|nigger|nigga|faggot|hurensohn|fotze|kill\s+yourself|kys)\b/i;

export function applyTextRules(text: string): ModerationResult | null {
  const t = text.trim();
  if (t.length > 2000) {
    return {
      action: "rejected",
      source: "rule",
      confidence: 1,
      labels: ["too_long"],
      note: "Text länger als 2000 Zeichen",
    };
  }
  const urls = t.match(/https?:\/\//gi) ?? [];
  if (urls.length >= 4) {
    return {
      action: "rejected",
      source: "rule",
      confidence: 0.95,
      labels: ["spam"],
      note: "Zu viele Links",
    };
  }
  if (REJECT_RE.test(t)) {
    return {
      action: "rejected",
      source: "rule",
      confidence: 0.99,
      labels: ["hate"],
      note: "Regel-Treffer (Hass/illegal)",
    };
  }
  if (/(.)\1{12,}/.test(t)) {
    return {
      action: "rejected",
      source: "rule",
      confidence: 0.9,
      labels: ["spam"],
      note: "Wiederholungs-Spam",
    };
  }
  return null;
}

export function parseAiVerdict(raw: string): {
  action: "approved" | "rejected" | "review";
  confidence: number;
  labels: string[];
  note: string;
} | null {
  const jsonStart = raw.indexOf("{");
  const jsonEnd = raw.lastIndexOf("}");
  if (jsonStart < 0 || jsonEnd <= jsonStart) return null;
  try {
    const parsed = JSON.parse(raw.slice(jsonStart, jsonEnd + 1)) as {
      action?: unknown;
      confidence?: unknown;
      labels?: unknown;
      note?: unknown;
    };
    const action =
      parsed.action === "approved" ||
      parsed.action === "rejected" ||
      parsed.action === "review"
        ? parsed.action
        : null;
    if (!action) return null;
    const confidence = Number(parsed.confidence);
    const labels = Array.isArray(parsed.labels)
      ? parsed.labels.filter((x): x is string => typeof x === "string").slice(0, 8)
      : [];
    return {
      action,
      confidence: Number.isFinite(confidence)
        ? Math.min(1, Math.max(0, confidence))
        : 0.5,
      labels,
      note: typeof parsed.note === "string" ? parsed.note.slice(0, 400) : "",
    };
  } catch {
    return null;
  }
}

const UNSAFE_LABELS = new Set([
  "hate",
  "sexual",
  "csam",
  "violence",
  "pii",
  "scam",
  "spam",
]);

export function decideModeration(
  kind: ModerationKind,
  rules: ModerationResult | null,
  ai: ReturnType<typeof parseAiVerdict>,
  model?: string
): ModerationResult {
  if (rules?.action === "rejected") return rules;

  if (!ai) {
    return {
      action: "pending",
      source: "rule",
      confidence: 0,
      labels: rules?.labels?.length ? rules.labels : ["needs_human"],
      note: "Kein AI-Verdikt — wartet auf menschliche Prüfung",
    };
  }

  const unsafe = ai.labels.some((l) => UNSAFE_LABELS.has(l.toLowerCase()));

  if (ai.action === "rejected" && ai.confidence >= 0.8) {
    return {
      action: "rejected",
      source: "ai",
      confidence: ai.confidence,
      labels: ai.labels,
      note: ai.note || "AI reject",
      model,
    };
  }

  if (unsafe && ai.confidence >= 0.7) {
    return {
      action: "rejected",
      source: "ai",
      confidence: ai.confidence,
      labels: ai.labels,
      note: ai.note || "Unsicherer Inhalt",
      model,
    };
  }

  // Photos: never auto-approve — queue even if AI likes the landscape.
  if (kind === "photo") {
    return {
      action: "pending",
      source: "ai",
      confidence: ai.confidence,
      labels: ai.labels.length ? ai.labels : ["needs_human"],
      note: ai.note || "Foto wartet auf Freigabe",
      model,
    };
  }

  if (ai.action === "approved" && ai.confidence >= 0.9 && !unsafe) {
    return {
      action: "approved",
      source: "ai",
      confidence: ai.confidence,
      labels: ai.labels.length ? ai.labels : ["ok"],
      note: ai.note || "AI approve",
      model,
    };
  }

  return {
    action: "pending",
    source: "ai",
    confidence: ai.confidence,
    labels: ai.labels.length ? ai.labels : ["needs_human"],
    note: ai.note || "Unsicher — menschliche Prüfung",
    model,
  };
}

const SYSTEM_PROMPT =
  "Du moderierst AetherRide Tour-Community (Fahrrad, DE/EN). " +
  "Antworte NUR mit JSON: " +
  '{"action":"approved"|"rejected"|"review","confidence":0-1,"labels":[],"note":"kurz"}. ' +
  "Labels aus: ok, hate, sexual, csam, violence, spam, scam, pii, off_topic. " +
  "Reject: Hass, Sexualisierung, Minderjährige, Betrug, massenhaft PII. " +
  "Approved: normale Tour-Kommentare, Kritik an Trails, sachliche Hinweise. " +
  "Review wenn unsicher. Keine Tracks/GPS in Texten verlangen.";

export async function callModerationModel(input: ModerationInput): Promise<{
  verdict: ReturnType<typeof parseAiVerdict>;
  model: string;
} | null> {
  const key = process.env.XAI_API_KEY;
  if (!key) return null;
  const hasImage = Boolean(input.imageUrl);
  const model = hasImage
    ? process.env.XAI_VISION_MODEL || "grok-2-vision-1212"
    : process.env.XAI_MODEL || "grok-3-mini";

  const userText =
    `Art: ${input.kind}\n` +
    (input.rating != null ? `Sterne: ${input.rating}\n` : "") +
    `Text: ${input.text || "(leer)"}\n`;

  const userContent: unknown = hasImage
    ? [
        { type: "text", text: userText },
        {
          type: "image_url",
          image_url: { url: input.imageUrl },
        },
      ]
    : userText;

  const res = await fetch("https://api.x.ai/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      temperature: 0,
      max_tokens: 220,
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: userContent },
      ],
    }),
    signal: AbortSignal.timeout(12_000),
  });
  if (!res.ok) {
    console.error("[community/moderate]", res.status, await res.text());
    return null;
  }
  const data = (await res.json()) as {
    choices?: { message?: { content?: string } }[];
  };
  const raw = data?.choices?.[0]?.message?.content?.trim() ?? "";
  return { verdict: parseAiVerdict(raw), model };
}

export async function moderateContent(
  input: ModerationInput
): Promise<ModerationResult> {
  const rules = applyTextRules(input.text);
  if (rules?.action === "rejected") return rules;
  try {
    const ai = await callModerationModel(input);
    return decideModeration(input.kind, rules, ai?.verdict ?? null, ai?.model);
  } catch (e) {
    console.error("[community/moderate] fail", e);
    return decideModeration(input.kind, rules, null);
  }
}
