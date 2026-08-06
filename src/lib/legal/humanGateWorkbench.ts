/**
 * Human-Gate Workbench — Closure-Checklisten (localStorage only)
 *
 * HARD RULE: Setzt NIEMALS Master-Flags auf true.
 * G-0/G-1/G-2/G-5/A-06/A-08 bleiben false bis ein Mensch sie im Code setzt.
 */

import type { HumanSignGateId } from "./gateSignoffPrep";
import { HUMAN_SIGN_GATES } from "./gateSignoffPrep";
import { G0_MOBILE_STACK_CONFIRMED } from "@/lib/platform/g0TeamSetup";
import { renderG0WorkshopPackMarkdown } from "@/lib/platform/g0Workshop";
import {
  G1_BOSCH_ACCESS_CLEARED,
  renderG1BoschCoverLetter,
  renderG1BoschOutreachMarkdown,
} from "@/lib/ble/g1BoschOutreach";
import { G2_SUSPENSION_GATE_PASSED } from "@/lib/sensor/fni";
import { renderG2StudyPlanMarkdown } from "@/lib/sensor/g2StudyPlan";
import { G5_LEGAL_REVIEW_PASSED } from "@/lib/routing/legalReview";
import { renderG5AttorneyBriefMarkdown } from "@/lib/routing/g5AttorneyBrief";
import { renderG5CounselDispatchChecklistMarkdown } from "@/lib/routing/g5CounselDispatch";
import {
  A06_LEGAL_REVIEW_PASSED,
  renderA06AttorneyBriefMarkdown,
} from "@/lib/legal/a06OdblBrief";
import { A08_LEGAL_REVIEW_PASSED } from "@/lib/legal/setupLiability";
import { renderA08AttorneyBriefMarkdown } from "@/lib/legal/a08CounselBrief";

const LS_KEY = "aetherride.gates.closureChecklist.v1";

export interface ClosureItemDef {
  id: string;
  labelDe: string;
}

export interface GateWorkbenchDef {
  gateId: HumanSignGateId;
  flagName: string;
  flagValue: boolean;
  modulePath: string;
  ownerRoleDe: string;
  items: ClosureItemDef[];
  packDownloads: { filename: string; kind: string }[];
}

type ChecklistState = Record<string, Record<string, boolean>>;

function readState(): ChecklistState {
  if (typeof window === "undefined") return {};
  try {
    const raw = localStorage.getItem(LS_KEY);
    if (!raw) return {};
    const parsed = JSON.parse(raw) as ChecklistState;
    return parsed && typeof parsed === "object" ? parsed : {};
  } catch {
    return {};
  }
}

function writeState(state: ChecklistState) {
  if (typeof window === "undefined") return;
  localStorage.setItem(LS_KEY, JSON.stringify(state));
}

export const GATE_WORKBENCH: GateWorkbenchDef[] = [
  {
    gateId: "G-0",
    flagName: "G0_MOBILE_STACK_CONFIRMED",
    flagValue: G0_MOBILE_STACK_CONFIRMED,
    modulePath: "src/lib/platform/g0TeamSetup.ts",
    ownerRoleDe: "Tech-Lead / Product",
    items: [
      { id: "team-skills", labelDe: "Team-Skills (Sensor/BLE/FFI) bestätigt" },
      { id: "stack-choice", labelDe: "Stack gewählt (Flutter o. ä.)" },
      { id: "backend-lang", labelDe: "Backend-Sprache gewählt" },
      { id: "ffi-owner", labelDe: "FFI-Owner benannt" },
      { id: "workshop_held", labelDe: "Sprint-0-Workshop durchgeführt" },
      { id: "protocol_filed", labelDe: "Protokoll abgelegt" },
      { id: "non_goals_acked", labelDe: "Non-Goals (kein Fake-Flutter) bestätigt" },
      {
        id: "ready_for_code_flag",
        labelDe: "Bereit für Code-Flag (nur nach echtem GO)",
      },
    ],
    packDownloads: [
      { filename: "aetherride-g0-workshop-pack.md", kind: "g0_pack" },
    ],
  },
  {
    gateId: "G-1",
    flagName: "G1_BOSCH_ACCESS_CLEARED",
    flagValue: G1_BOSCH_ACCESS_CLEARED,
    modulePath: "src/lib/ble/g1BoschOutreach.ts",
    ownerRoleDe: "Partnerships / Legal",
    items: [
      { id: "outreach_drafted", labelDe: "Outreach-Paket finalisiert" },
      { id: "outreach_sent", labelDe: "An Bosch gesendet (markiert)" },
      { id: "terms_reviewed", labelDe: "AGB/Zugangskonditionen geprüft" },
      { id: "brand_guidelines_ok", labelDe: "Brand-Guidelines ok" },
      { id: "ticket_ref", labelDe: "Ticket-/Mandatsreferenz notiert" },
      {
        id: "ready_for_code_flag",
        labelDe: "Bereit für Code-Flag (nur nach Freigabe)",
      },
    ],
    packDownloads: [
      { filename: "aetherride-g1-bosch-outreach.md", kind: "g1_outreach" },
      { filename: "aetherride-g1-bosch-anschreiben.txt", kind: "g1_cover" },
    ],
  },
  {
    gateId: "G-2",
    flagName: "G2_SUSPENSION_GATE_PASSED",
    flagValue: G2_SUSPENSION_GATE_PASSED,
    modulePath: "src/lib/sensor/fni.ts",
    ownerRoleDe: "Fahrwerk / Sensorik",
    items: [
      { id: "bottom_out", labelDe: "Kriterium: Bottom-out" },
      { id: "fni_spearman", labelDe: "Kriterium: FNI Spearman" },
      { id: "fni_mount", labelDe: "Kriterium: Mount-Stabilität" },
      { id: "lean_mae", labelDe: "Kriterium: Lean MAE" },
      { id: "impact_kappa", labelDe: "Kriterium: Impact Kappa" },
      { id: "flow_icc", labelDe: "Kriterium: Flow ICC" },
      { id: "rec_fpr", labelDe: "Kriterium: Rec FPR" },
      { id: "report_filed", labelDe: "Validierungsbericht abgelegt" },
      {
        id: "ready_for_code_flag",
        labelDe: "Bereit für Code-Flag (alle Kriterien / Dark-Features)",
      },
    ],
    packDownloads: [
      { filename: "aetherride-g2-studienplan.md", kind: "g2_plan" },
    ],
  },
  {
    gateId: "G-5",
    flagName: "G5_LEGAL_REVIEW_PASSED",
    flagValue: G5_LEGAL_REVIEW_PASSED,
    modulePath: "src/lib/routing/legalReview.ts",
    ownerRoleDe: "Legal Counsel (Wegerecht)",
    items: [
      { id: "firm_selected", labelDe: "Kanzlei ausgewählt" },
      { id: "briefing_sent", labelDe: "Briefing versendet" },
      { id: "at7_opinion", labelDe: "Opinion AT-7 erhalten" },
      { id: "deby_opinion", labelDe: "Opinion DE-BY erhalten" },
      { id: "copy_edits", labelDe: "Copy-Edits eingearbeitet" },
      {
        id: "ready_for_code_flag",
        labelDe: "Bereit für Code-Flag (nur nach Opinion)",
      },
    ],
    packDownloads: [
      { filename: "aetherride-g5-anwalt-briefing.md", kind: "g5_brief" },
      { filename: "aetherride-g5-versand-checkliste.md", kind: "g5_dispatch" },
    ],
  },
  {
    gateId: "A-06",
    flagName: "A06_LEGAL_REVIEW_PASSED",
    flagValue: A06_LEGAL_REVIEW_PASSED,
    modulePath: "src/lib/legal/a06OdblBrief.ts",
    ownerRoleDe: "Legal Counsel (ODbL)",
    items: [
      { id: "inventory_reviewed", labelDe: "Dateninventar geprüft" },
      { id: "mandate_acked", labelDe: "Mandats-Scope bestätigt" },
      { id: "opinion_received", labelDe: "ODbL-Opinion erhalten" },
      { id: "attribution_updated", labelDe: "Attributionstexte aktualisiert" },
      {
        id: "ready_for_code_flag",
        labelDe: "Bereit für Code-Flag (nur nach Freigabe)",
      },
    ],
    packDownloads: [
      { filename: "aetherride-a06-odbl-brief.md", kind: "a06_brief" },
    ],
  },
  {
    gateId: "A-08",
    flagName: "A08_LEGAL_REVIEW_PASSED",
    flagValue: A08_LEGAL_REVIEW_PASSED,
    modulePath: "src/lib/legal/setupLiability.ts",
    ownerRoleDe: "Legal Counsel (Setup-Haftung)",
    items: [
      { id: "copy_reviewed", labelDe: "UI-Hinweistexte geprüft" },
      { id: "hard_limits_acked", labelDe: "Harte Grenzen mit Counsel abgestimmt" },
      { id: "opinion_received", labelDe: "Haftungs-Opinion erhalten" },
      { id: "onboarding_ux_ok", labelDe: "Onboarding-Acceptance UX ok" },
      {
        id: "ready_for_code_flag",
        labelDe: "Bereit für Code-Flag (nur nach Freigabe)",
      },
    ],
    packDownloads: [
      { filename: "aetherride-a08-setup-haftung.md", kind: "a08_brief" },
    ],
  },
];

export function getClosureItem(
  gateId: HumanSignGateId,
  itemId: string
): boolean {
  return Boolean(readState()[gateId]?.[itemId]);
}

export function setClosureItem(
  gateId: HumanSignGateId,
  itemId: string,
  value: boolean
): void {
  const state = readState();
  state[gateId] = { ...(state[gateId] ?? {}), [itemId]: value };
  writeState(state);
}

export function gateReadiness(
  gateId: HumanSignGateId
): { done: number; total: number; pct: number; allDone: boolean } {
  const def = GATE_WORKBENCH.find((g) => g.gateId === gateId);
  if (!def) return { done: 0, total: 0, pct: 0, allDone: false };
  const done = def.items.filter((i) => getClosureItem(gateId, i.id)).length;
  const total = def.items.length;
  return {
    done,
    total,
    pct: total ? Math.round((done / total) * 100) : 0,
    allDone: done === total && total > 0,
  };
}

export function workbenchSummaryDe(): string {
  const openFlags = GATE_WORKBENCH.filter((g) => !g.flagValue).map(
    (g) => g.gateId
  );
  const readyForCode = GATE_WORKBENCH.filter((g) =>
    getClosureItem(g.gateId, "ready_for_code_flag")
  ).map((g) => g.gateId);
  return `Human-Gates: Flags offen ${openFlags.join(", ") || "—"}. Lokal „bereit für Code“: ${readyForCode.join(", ") || "noch keine"} — Master-Flags unverändert false.`;
}

export function renderHumanGateWorkbenchMarkdown(): string {
  const lines: string[] = [
    "# AetherRide — Human Gate Workbench",
    "",
    `Erzeugt: ${new Date().toISOString()}`,
    "",
    "> **Human must sign.** localStorage-Checklisten schließen keine Gates.",
    "> Master-Flags nur manuell im Code nach echter Freigabe setzen.",
    "",
    workbenchSummaryDe(),
    "",
  ];
  for (const g of GATE_WORKBENCH) {
    const meta = HUMAN_SIGN_GATES.find((h) => h.id === g.gateId);
    const r = gateReadiness(g.gateId);
    lines.push(`## ${g.gateId} — \`${g.flagName}\` = \`${String(g.flagValue)}\``);
    lines.push(`- Owner: ${g.ownerRoleDe}`);
    lines.push(`- Modul: \`${g.modulePath}\``);
    lines.push(`- Readiness (lokal): ${r.done}/${r.total} (${r.pct}%)`);
    if (meta) {
      for (const step of meta.closureStepsDe) {
        lines.push(`- Closure: ${step}`);
      }
    }
    lines.push("");
    for (const item of g.items) {
      const checked = getClosureItem(g.gateId, item.id);
      lines.push(`- [${checked ? "x" : " "}] ${item.labelDe} (\`${item.id}\`)`);
    }
    lines.push("");
  }
  lines.push("## Regel");
  lines.push("");
  lines.push(
    "Auch wenn alle Checkboxen inkl. `ready_for_code_flag` gesetzt sind: Flag im Quellcode nur nach menschlicher Entscheidung ändern und per PR reviewen."
  );
  lines.push("");
  return lines.join("\n");
}

/** Pack-Inhalt für Download — ändert keine Flags */
export function resolvePackContent(kind: string): string | null {
  switch (kind) {
    case "g0_pack":
      return renderG0WorkshopPackMarkdown();
    case "g1_outreach":
      return renderG1BoschOutreachMarkdown();
    case "g1_cover":
      return renderG1BoschCoverLetter();
    case "g2_plan":
      return renderG2StudyPlanMarkdown();
    case "g5_brief":
      return renderG5AttorneyBriefMarkdown();
    case "g5_dispatch":
      return renderG5CounselDispatchChecklistMarkdown();
    case "a06_brief":
      return renderA06AttorneyBriefMarkdown();
    case "a08_brief":
      return renderA08AttorneyBriefMarkdown();
    case "workbench":
      return renderHumanGateWorkbenchMarkdown();
    default:
      return null;
  }
}

/** Für Tests: alle Master-Flags lesen */
export function assertMasterFlagsStillFalse(): boolean {
  return (
    G0_MOBILE_STACK_CONFIRMED === false &&
    G1_BOSCH_ACCESS_CLEARED === false &&
    G2_SUSPENSION_GATE_PASSED === false &&
    G5_LEGAL_REVIEW_PASSED === false &&
    A06_LEGAL_REVIEW_PASSED === false &&
    A08_LEGAL_REVIEW_PASSED === false
  );
}
