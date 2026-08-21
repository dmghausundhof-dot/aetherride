/**
 * Deterministischer Assistenten-Monitor.
 * Kein LLM: Engines entscheiden, der Chat formuliert höchstens um.
 */

import { analyzePostRide } from "@/lib/ai/postRideAnalysis";
import { normalizeBikes, normalizeRides } from "@/lib/ai/normalize";
import { checkBikeCompatibility } from "@/lib/compatibility/engine";
import { buildMaintenanceAlerts } from "@/lib/home/maintenanceAlerts";
import type { RangeCalibration } from "@/lib/ebike/range";
import type {
  Bike,
  MaintenanceInterval,
  Ride,
  RideFeedback,
  RiderProfile,
} from "@/types";
import type { ChromeLang } from "@/lib/i18n/chromeLang";
import { chatCopy, type ChatCopy } from "@/lib/i18n/chatCopy";
import {
  postRideAnalysisCopy,
  type PostRideAnalysisCopy,
} from "@/lib/i18n/postRideAnalysisCopy";

export type CoachKind =
  | "maintenance"
  | "wear"
  | "compat"
  | "setup"
  | "range"
  | "feedback";

export type CoachSeverity = "info" | "due_soon" | "overdue";

export type CoachToolName =
  | "watch"
  | "garage"
  | "compat"
  | "setup_history"
  | "ride_stats"
  | "route_search"
  | "product_search"
  | "range";

export interface CoachNumber {
  value: number;
  unit: string;
  source: string;
}

export interface CoachNotice {
  id: string;
  kind: CoachKind;
  severity: CoachSeverity;
  title: string;
  detail: string;
  reasoning: string;
  href: string;
  bikeId?: string;
  tool: CoachToolName;
  query: string;
  fingerprint: string;
  numbers: CoachNumber[];
}

export interface CoachWatchInput {
  bikes: Bike[];
  rides: Ride[];
  intervals?: MaintenanceInterval[];
  profile: RiderProfile;
  calibration?: RangeCalibration | null;
  rideFeedbacks?: RideFeedback[];
  now?: Date;
}

const FEEDBACK_WINDOW_MS = 48 * 60 * 60 * 1000;
const MAX_NOTICES = 8;

function fingerprint(parts: string[]): string {
  return parts.join("|").slice(0, 180);
}

function rank(s: CoachSeverity): number {
  if (s === "overdue") return 0;
  if (s === "due_soon") return 1;
  return 2;
}

export function buildCoachWatch(input: CoachWatchInput): CoachNotice[] {
  const bikes = normalizeBikes(input.bikes);
  const rides = normalizeRides(input.rides);
  const intervals = input.intervals ?? [];
  const now = input.now ?? new Date();
  if (bikes.length === 0) return [];

  const notices: CoachNotice[] = [];

  for (const bike of bikes) {
    try {
      const alerts = buildMaintenanceAlerts({
        bike,
        rides: rides.filter((r) => !r.bikeId || r.bikeId === bike.id),
        intervals: intervals.filter((i) => i.bikeId === bike.id),
        max: 4,
      });
      for (const a of alerts) {
        const kind: CoachKind = a.id.startsWith("wear-") ? "wear" : "maintenance";
        notices.push({
          id: `maint:${bike.id}:${a.id}`,
          kind,
          severity: a.severity,
          title: a.title,
          detail: `${bike.name}: ${a.detail}`,
          reasoning: a.reasoning,
          href: "/garage?tab=maintenance",
          bikeId: bike.id,
          tool: kind === "wear" ? "product_search" : "garage",
          query: a.title,
          fingerprint: fingerprint([a.severity, a.title, a.detail]),
          numbers: [],
        });
      }
    } catch {
      /* unvollständige Garage */
    }

    try {
      const results = checkBikeCompatibility(bike).filter(
        (r) => r.verdict === "INCOMPATIBLE"
      );
      for (const r of results.slice(0, 2)) {
        const overdue = r.severity === "safety_critical";
        notices.push({
          id: `compat:${bike.id}:${r.ruleCode}`,
          kind: "compat",
          severity: overdue ? "overdue" : "due_soon",
          title: r.title,
          detail: r.explainDe,
          reasoning: `${r.ruleCode} · ${bike.name}`,
          href: "/garage",
          bikeId: bike.id,
          tool: "compat",
          query: `Passt ${r.title}?`,
          fingerprint: fingerprint([r.verdict, r.ruleCode, r.explainDe]),
          numbers: [],
        });
      }
    } catch {
      /* */
    }

    if (bike.isEbike) {
      const samples = input.calibration?.samples ?? 0;
      if (samples < 2) {
        notices.push({
          id: `range:${bike.id}:cal`,
          kind: "range",
          severity: "info",
          title: "Reichweite noch unsicher",
          detail: `${bike.name}: nach ein paar Fahrten mit SOC wird die Spanne enger.`,
          reasoning: `Kalibrierung ${samples} Sample(s) — Physikmodell ohne Selbstabgleich.`,
          href: "/chat",
          bikeId: bike.id,
          tool: "range",
          query: "Welche Reichweite habe ich mit aktuellem Akku?",
          fingerprint: fingerprint(["range", String(samples)]),
          numbers: [{ value: samples, unit: "", source: "range.samples" }],
        });
      }
    }
  }

  const last = [...rides].sort(
    (a, b) => new Date(b.startTime).getTime() - new Date(a.startTime).getTime()
  )[0];
  if (last) {
    const start = new Date(last.startTime).getTime();
    const age = now.getTime() - start;
    if (age >= 0 && age <= FEEDBACK_WINDOW_MS) {
      const fb = (input.rideFeedbacks ?? []).find((f) => f.rideId === last.id);
      if (!fb || fb.skipped) {
        notices.push({
          id: `feedback:${last.id}`,
          kind: "feedback",
          severity: "info",
          title: "Kurzes Feedback zur letzten Fahrt",
          detail: "Drei Taps — der Assistent nutzt das für Setup-Hinweise.",
          reasoning: "Post-Ride-Fenster 48 h, noch kein Feedback.",
          href: "/post-ride",
          bikeId: last.bikeId,
          tool: "setup_history",
          query: "Was hat sich am Setup nach der letzten Fahrt angeboten?",
          fingerprint: fingerprint(["feedback", last.id]),
          numbers: [{ value: 48, unit: "h", source: "feedback.window" }],
        });
      }

      const bike = last.bikeId
        ? bikes.find((b) => b.id === last.bikeId)
        : bikes[0];
      if (bike) {
        try {
          const current = bike.setups.find((s) => s.isCurrent);
          const analysis = analyzePostRide({
            ride: last,
            bike,
            setup: current,
            feedback: fb && !fb.skipped ? fb : undefined,
          });
          const sug = analysis.setupSuggestion;
          if (sug) {
            notices.push({
              id: `setup:${last.id}:${sug.adjusterKey ?? sug.title}`,
              kind: "setup",
              severity: sug.confidence === "high" ? "due_soon" : "info",
              title: sug.title,
              detail: sug.content,
              reasoning: sug.reasoning,
              href: "/post-ride",
              bikeId: bike.id,
              tool: "setup_history",
              query: sug.title,
              fingerprint: fingerprint([sug.title, sug.content]),
              numbers:
                sug.suggestedDelta != null
                  ? [
                      {
                        value: sug.suggestedDelta,
                        unit: "klicks",
                        source: "setup.delta",
                      },
                    ]
                  : [],
            });
          }
        } catch {
          /* */
        }
      }
    }
  }

  notices.sort((a, b) => rank(a.severity) - rank(b.severity));
  const seen = new Set<string>();
  const unique: CoachNotice[] = [];
  for (const n of notices) {
    if (seen.has(n.id)) continue;
    seen.add(n.id);
    unique.push(n);
    if (unique.length >= MAX_NOTICES) break;
  }
  return unique;
}

export function localizeCoachNotice(
  n: CoachNotice,
  lang: ChromeLang = "de"
): { title: string; detail: string } {
  const chat = chatCopy(lang);
  const analysis = postRideAnalysisCopy(lang);
  return localizeCoachNoticeWith(n, chat, analysis);
}

function localizeCoachNoticeWith(
  n: CoachNotice,
  chat: ChatCopy,
  analysis: PostRideAnalysisCopy
): { title: string; detail: string } {
  if (n.kind === "feedback") {
    return { title: chat.feedbackTitle, detail: chat.feedbackDetail };
  }
  if (n.kind === "setup") {
    if (n.title.includes("2 Klicks langsamer")) {
      return { title: analysis.sugReboundSlowTitle, detail: n.detail };
    }
    if (n.title.includes("2 Klicks schneller")) {
      return { title: analysis.sugReboundFastTitle, detail: n.detail };
    }
    if (/Luftdruck|air pressure|pression|pressione|luchtdruk/i.test(n.title)) {
      return { title: analysis.sugPressureTitle, detail: n.detail };
    }
  }
  return { title: n.title, detail: n.detail };
}

export function formulateCoachWatch(
  notices: CoachNotice[],
  lang: ChromeLang = "de"
): string {
  const chat = chatCopy(lang);
  const analysis = postRideAnalysisCopy(lang);
  if (notices.length === 0) return chat.watchNothing;
  const overdue = notices.filter((n) => n.severity === "overdue").length;
  const soon = notices.filter((n) => n.severity === "due_soon").length;
  const lines = notices.slice(0, 5).map((n) => {
    const loc = localizeCoachNoticeWith(n, chat, analysis);
    const tag =
      n.severity === "overdue"
        ? chat.sevOverdue
        : n.severity === "due_soon"
          ? chat.sevSoon
          : chat.sevInfo;
    return `${tag}: ${loc.title} — ${loc.detail}`;
  });
  const head =
    overdue > 0
      ? `${overdue} ${chat.sevOverdue.toLowerCase()}, ${soon} ${chat.sevSoon.toLowerCase()}.`
      : soon > 0
        ? `${soon} ${chat.sevSoon.toLowerCase()}.`
        : `${notices.length} ${chat.sevInfo}.`;
  return `${head} ${lines.join(" ")}`;
}
