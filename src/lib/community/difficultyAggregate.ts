/**
 * Crowd difficulty vs catalog. Hidden until n≥5 — no invented consensus.
 */

export const DIFFICULTY_MIN_N = 5;

export type DifficultyCrowdLabel = "easier" | "as_marked" | "harder";

export type DifficultyCrowd = {
  n: number;
  mean: number | null;
  shown: boolean;
  label: DifficultyCrowdLabel | null;
};

export function parseDifficultyDelta(raw: unknown): number | null {
  if (typeof raw !== "number" && typeof raw !== "string") return null;
  if (typeof raw === "string" && raw.trim() === "") return null;
  const n = Number(raw);
  if (!Number.isFinite(n)) return null;
  const v = Math.round(n);
  if (v < -2 || v > 2) return null;
  return v;
}

export function aggregateDifficulty(
  deltas: unknown[],
  minN = DIFFICULTY_MIN_N
): DifficultyCrowd {
  const nums: number[] = [];
  for (const d of deltas) {
    const v = parseDifficultyDelta(d);
    if (v != null) nums.push(v);
  }
  const n = nums.length;
  if (n < minN) {
    return { n, mean: null, shown: false, label: null };
  }
  const mean = nums.reduce((a, b) => a + b, 0) / n;
  const label: DifficultyCrowdLabel =
    mean < -0.35 ? "easier" : mean > 0.35 ? "harder" : "as_marked";
  return { n, mean, shown: true, label };
}

export function parseDifficultyCrowd(raw: unknown): DifficultyCrowd {
  if (!raw || typeof raw !== "object") {
    return { n: 0, mean: null, shown: false, label: null };
  }
  const m = raw as Record<string, unknown>;
  const nRaw = Number(m.n);
  const n = Number.isFinite(nRaw) ? Math.max(0, Math.round(nRaw)) : 0;
  const shown = m.shown === true && n >= DIFFICULTY_MIN_N;
  const label: DifficultyCrowdLabel | null =
    m.label === "easier" || m.label === "as_marked" || m.label === "harder"
      ? m.label
      : null;
  const meanRaw = Number(m.mean);
  return {
    n,
    mean: shown && Number.isFinite(meanRaw) ? meanRaw : null,
    shown,
    label: shown ? label : null,
  };
}
