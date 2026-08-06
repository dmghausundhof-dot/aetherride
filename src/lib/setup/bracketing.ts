import type { BracketingRun, BracketingSeries } from "@/types/garage";

/**
 * F-SET-003 Bracketing-Auswertung
 * Effekt belegt nur wenn |Δ| > 1,5 × gepoolte SD und n ≥ 2 je Konfiguration.
 */

export interface ConfigStats {
  value: number;
  n: number;
  meanTime: number;
  meanFlow: number;
  meanImpact: number;
  meanSubjective: number;
  sdTime: number;
  sdFlow: number;
}

function mean(xs: number[]): number {
  if (xs.length === 0) return 0;
  return xs.reduce((a, b) => a + b, 0) / xs.length;
}

function sampleSd(xs: number[]): number {
  if (xs.length < 2) return 0;
  const m = mean(xs);
  const v = xs.reduce((s, x) => s + (x - m) ** 2, 0) / (xs.length - 1);
  return Math.sqrt(v);
}

export function groupRunsByConfig(runs: BracketingRun[]): Map<number, BracketingRun[]> {
  const map = new Map<number, BracketingRun[]>();
  for (const r of runs) {
    const list = map.get(r.configValue) ?? [];
    list.push(r);
    map.set(r.configValue, list);
  }
  return map;
}

export function statsForConfig(value: number, runs: BracketingRun[]): ConfigStats {
  const times = runs.map((r) => r.segmentTimeSec);
  const flows = runs.map((r) => r.flowScore);
  const impacts = runs.map((r) => r.impactHardness);
  const subs = runs.map((r) => r.subjectiveRating);
  return {
    value,
    n: runs.length,
    meanTime: mean(times),
    meanFlow: mean(flows),
    meanImpact: mean(impacts),
    meanSubjective: mean(subs),
    sdTime: sampleSd(times),
    sdFlow: sampleSd(flows),
  };
}

function pooledSd(a: ConfigStats, b: ConfigStats, key: "sdTime" | "sdFlow"): number {
  const n1 = a.n;
  const n2 = b.n;
  if (n1 + n2 <= 2) return 0;
  const s1 = a[key];
  const s2 = b[key];
  return Math.sqrt(((n1 - 1) * s1 ** 2 + (n2 - 1) * s2 ** 2) / (n1 + n2 - 2));
}

export interface BracketingEvaluation {
  noProvenDifference: boolean;
  provenBestValue?: number;
  summary: string;
  ready: boolean;
  missingRuns: { value: number; have: number; need: number }[];
  comparisons: {
    a: number;
    b: number;
    metric: string;
    delta: number;
    threshold: number;
    proven: boolean;
  }[];
}

/** Composite-Score: höher = besser (Flow↑, Zeit↓, Impact↓, Subjective↑) */
function composite(s: ConfigStats): number {
  return (
    s.meanFlow * 0.35 +
    s.meanSubjective * 20 * 0.25 +
    (1 / Math.max(1, s.meanTime)) * 100 * 0.2 +
    (10 - Math.min(10, s.meanImpact)) * 10 * 0.2
  );
}

export function evaluateBracketingSeries(series: BracketingSeries): BracketingEvaluation {
  const grouped = groupRunsByConfig(series.runs);
  const values = Array.from(grouped.keys()).sort((a, b) => a - b);
  const missingRuns: BracketingEvaluation["missingRuns"] = [];

  // Erwartete Konfigurationen aus Range
  const expected: number[] = [];
  for (let v = series.rangeFrom; v <= series.rangeTo + 1e-9; v += series.step) {
    expected.push(Math.round(v * 1000) / 1000);
  }

  for (const v of expected) {
    const have = grouped.get(v)?.length ?? 0;
    if (have < 2) missingRuns.push({ value: v, have, need: 2 });
  }

  if (missingRuns.length > 0 || values.length < 2) {
    return {
      noProvenDifference: false,
      summary:
        missingRuns.length > 0
          ? `Noch nicht auswertbar: pro Konfiguration mind. 2 Durchgänge nötig. Fehlt: ${missingRuns
              .map((m) => `${m.value} (${m.have}/2)`)
              .join(", ")}`
          : "Mindestens zwei verschiedene Konfigurationen mit je ≥ 2 Runs nötig.",
      ready: false,
      missingRuns,
      comparisons: [],
    };
  }

  const stats = values.map((v) => statsForConfig(v, grouped.get(v)!));
  const comparisons: BracketingEvaluation["comparisons"] = [];
  let anyProven = false;

  for (let i = 0; i < stats.length; i++) {
    for (let j = i + 1; j < stats.length; j++) {
      const a = stats[i];
      const b = stats[j];
      // Spec: |Δ| > 1,5× gepoolte SD. Zusätzlich Mindest-Effektgröße,
      // damit numerisches Rauschen bei SD≈0 keinen „Beweis“ erzeugt (Blindtest).
      const sdFlow = pooledSd(a, b, "sdFlow");
      const deltaFlow = Math.abs(a.meanFlow - b.meanFlow);
      const thrFlow = Math.max(1.5 * sdFlow, 1.0);
      const provenFlow = a.n >= 2 && b.n >= 2 && deltaFlow > thrFlow;

      const sdTime = pooledSd(a, b, "sdTime");
      const deltaTime = Math.abs(a.meanTime - b.meanTime);
      const thrTime = Math.max(1.5 * sdTime, 0.5);
      const provenTime = a.n >= 2 && b.n >= 2 && deltaTime > thrTime;

      comparisons.push({
        a: a.value,
        b: b.value,
        metric: "flow",
        delta: deltaFlow,
        threshold: thrFlow,
        proven: provenFlow,
      });
      comparisons.push({
        a: a.value,
        b: b.value,
        metric: "time",
        delta: deltaTime,
        threshold: thrTime,
        proven: provenTime,
      });
      if (provenFlow || provenTime) anyProven = true;
    }
  }

  if (!anyProven) {
    return {
      noProvenDifference: true,
      summary:
        "Kein belegbarer Unterschied — die Lauf-zu-Lauf-Streuung übersteigt die gemessenen Differenzen (|Δ| ≤ 1,5× gepoolte SD). Das ist ein gültiges Ergebnis (F-SET-003).",
      ready: true,
      missingRuns: [],
      comparisons,
    };
  }

  const ranked = [...stats].sort((a, b) => composite(b) - composite(a));
  const best = ranked[0];

  return {
    noProvenDifference: false,
    provenBestValue: best.value,
    summary: `Belegbare Unterschiede vorhanden. Beste Konfiguration für ${series.parameter}: ${best.value} ${series.unit} (höherer Flow / bessere Segmentzeit bei ausreichender Effektstärke).`,
    ready: true,
    missingRuns: [],
    comparisons,
  };
}

/** Blindtest-Helfer: zwei identische Configs → sollte „kein Unterschied“ ergeben */
export function blindTestIdenticalSetups(
  runsA: BracketingRun[],
  runsB: BracketingRun[]
): boolean {
  const series: BracketingSeries = {
    id: "blind",
    bikeId: "x",
    setupId: "x",
    parameter: "fork.rebound",
    unit: "clicks",
    rangeFrom: 6,
    rangeTo: 8,
    step: 2,
    referenceSegmentLabel: "test",
    status: "open",
    runs: [
      ...runsA.map((r) => ({ ...r, configValue: 6 })),
      ...runsB.map((r) => ({ ...r, configValue: 8 })),
    ],
    createdAt: new Date().toISOString(),
  };
  const result = evaluateBracketingSeries(series);
  return result.ready && !!result.noProvenDifference;
}
