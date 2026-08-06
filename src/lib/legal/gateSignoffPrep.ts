/**
 * Roadmap 8 — Legal/Gate Sign-off Prep
 *
 * Vereinheitlichte Checkliste + Markdown-Bundle für menschliche Sign-offs.
 * Setzt NIEMALS G-0/G-1/G-2/G-5/A-06/A-08 auf true.
 */

import { listGateStatuses, type GateStatusRow } from "@/lib/platform/gateStatus";
import { G0_MOBILE_STACK_CONFIRMED } from "@/lib/platform/g0TeamSetup";
import { renderG0WorkshopPackMarkdown } from "@/lib/platform/g0Workshop";
import { G1_BOSCH_ACCESS_CLEARED } from "@/lib/ble/g1BoschOutreach";
import { renderG1BoschOutreachMarkdown } from "@/lib/ble/g1BoschOutreach";
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

export type HumanSignGateId =
  | "G-0"
  | "G-1"
  | "G-2"
  | "G-5"
  | "A-06"
  | "A-08";

export interface HumanSignGateMeta {
  id: HumanSignGateId;
  ownerRoleDe: string;
  packHintDe: string;
  exportFiles: string[];
  closureStepsDe: string[];
  flagName: string;
  flagValue: boolean;
  requiresHumanSign: true;
}

const ACK_KEY = "aetherride.legal.humanAcks.v1";

export type HumanAckKind =
  | "pack_reviewed"
  | "sent_to_owner"
  | "awaiting_decision";

export interface HumanGateAck {
  gateId: HumanSignGateId;
  kind: HumanAckKind;
  at: string;
  note?: string;
}

export const HUMAN_SIGN_GATES: HumanSignGateMeta[] = [
  {
    id: "G-0",
    ownerRoleDe: "Tech-Lead / Product (Stack-Entscheidung)",
    packHintDe: "Workshop-Pack + Modul-Matrix",
    exportFiles: ["aetherride-g0-workshop-pack.md"],
    closureStepsDe: [
      "Workshop durchführen",
      "Stack (Flutter o. ä.) + Backend-Sprache festlegen",
      "G0_MOBILE_STACK_CONFIRMED nur nach echtem Team-GO setzen",
    ],
    flagName: "G0_MOBILE_STACK_CONFIRMED",
    flagValue: G0_MOBILE_STACK_CONFIRMED,
    requiresHumanSign: true,
  },
  {
    id: "G-1",
    ownerRoleDe: "Partnerships / Legal (Bosch LDI)",
    packHintDe: "Outreach + Cover Letter",
    exportFiles: [
      "aetherride-g1-bosch-outreach.md",
      "aetherride-g1-bosch-cover.md",
    ],
    closureStepsDe: [
      "Outreach an Bosch senden",
      "Zugang/AGB klären",
      "G1_BOSCH_ACCESS_CLEARED nur nach Freigabe setzen",
    ],
    flagName: "G1_BOSCH_ACCESS_CLEARED",
    flagValue: G1_BOSCH_ACCESS_CLEARED,
    requiresHumanSign: true,
  },
  {
    id: "G-2",
    ownerRoleDe: "Fahrwerk / Sensorik (Studienleitung)",
    packHintDe: "Studienplan §7.5",
    exportFiles: ["aetherride-g2-studienplan.md"],
    closureStepsDe: [
      "Sieben Bestehenskriterien erfüllen",
      "Validierungsbericht ablegen",
      "G2_SUSPENSION_GATE_PASSED nur nach Kriterien setzen",
    ],
    flagName: "G2_SUSPENSION_GATE_PASSED",
    flagValue: G2_SUSPENSION_GATE_PASSED,
    requiresHumanSign: true,
  },
  {
    id: "G-5",
    ownerRoleDe: "Legal Counsel (Wegerecht)",
    packHintDe: "Attorney Brief + Dispatch-Checkliste",
    exportFiles: [
      "aetherride-g5-attorney-brief.md",
      "aetherride-g5-counsel-dispatch.md",
    ],
    closureStepsDe: [
      "Briefing an Kanzlei senden",
      "Opinion einholen",
      "G5_LEGAL_REVIEW_PASSED nur nach Opinion setzen",
    ],
    flagName: "G5_LEGAL_REVIEW_PASSED",
    flagValue: G5_LEGAL_REVIEW_PASSED,
    requiresHumanSign: true,
  },
  {
    id: "A-06",
    ownerRoleDe: "Legal Counsel (ODbL / OSM)",
    packHintDe: "ODbL Briefing",
    exportFiles: ["aetherride-a06-odbl-brief.md"],
    closureStepsDe: [
      "Dateninventar prüfen",
      "ODbL-Opinion einholen",
      "A06_LEGAL_REVIEW_PASSED nur nach Freigabe setzen",
    ],
    flagName: "A06_LEGAL_REVIEW_PASSED",
    flagValue: A06_LEGAL_REVIEW_PASSED,
    requiresHumanSign: true,
  },
  {
    id: "A-08",
    ownerRoleDe: "Legal Counsel (Setup-Haftung)",
    packHintDe: "Haftungs-Briefing + UI-Texte",
    exportFiles: ["aetherride-a08-setup-haftung.md"],
    closureStepsDe: [
      "Hinweistexte prüfen/korrigieren",
      "Onboarding-Acceptance bewerten",
      "A08_LEGAL_REVIEW_PASSED nur nach Freigabe setzen",
    ],
    flagName: "A08_LEGAL_REVIEW_PASSED",
    flagValue: A08_LEGAL_REVIEW_PASSED,
    requiresHumanSign: true,
  },
];

export function allHumanGateFlagsStillOpen(): boolean {
  return HUMAN_SIGN_GATES.every((g) => g.flagValue === false);
}

function readAcks(): HumanGateAck[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = localStorage.getItem(ACK_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw) as HumanGateAck[];
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function writeAcks(acks: HumanGateAck[]) {
  if (typeof window === "undefined") return;
  localStorage.setItem(ACK_KEY, JSON.stringify(acks.slice(-100)));
}

/** Lokale Ack — ändert KEINE Master-Flags */
export function recordHumanGateAck(
  gateId: HumanSignGateId,
  kind: HumanAckKind,
  note?: string
): HumanGateAck {
  const ack: HumanGateAck = {
    gateId,
    kind,
    at: new Date().toISOString(),
    note,
  };
  const next = readAcks().filter(
    (a) => !(a.gateId === gateId && a.kind === kind)
  );
  next.push(ack);
  writeAcks(next);
  return ack;
}

export function listHumanGateAcks(): HumanGateAck[] {
  return readAcks();
}

export function clearHumanGateAcks(): void {
  writeAcks([]);
}

export function latestAckFor(
  gateId: HumanSignGateId,
  kind?: HumanAckKind
): HumanGateAck | null {
  const all = readAcks()
    .filter((a) => a.gateId === gateId && (!kind || a.kind === kind))
    .sort((a, b) => a.at.localeCompare(b.at));
  return all[all.length - 1] ?? null;
}

export function renderUnifiedGateSignoffChecklistMarkdown(): string {
  const rows = listGateStatuses();
  const lines: string[] = [
    "# AetherRide — Unified Gate Sign-off Checklist",
    "",
    `Erzeugt: ${new Date().toISOString()}`,
    "",
    "> **Human must sign.** Dieses Dokument schließt keine Gates.",
    "> Master-Flags bleiben `false`, bis ein Mensch sie im Code setzt.",
    "",
    "## Status (live)",
    "",
    "| Gate | Passed | Owner | Flag |",
    "|------|--------|-------|------|",
  ];

  for (const meta of HUMAN_SIGN_GATES) {
    const row = rows.find((r) => r.id === meta.id) as GateStatusRow | undefined;
    lines.push(
      `| ${meta.id} | **${String(row?.passed ?? meta.flagValue)}** | ${meta.ownerRoleDe} | \`${meta.flagName}\` = \`${String(meta.flagValue)}\` |`
    );
  }

  lines.push("", "## Closure steps", "");
  for (const meta of HUMAN_SIGN_GATES) {
    lines.push(`### ${meta.id} — ${meta.packHintDe}`);
    lines.push(`- Owner: ${meta.ownerRoleDe}`);
    lines.push(`- Requires human sign: **yes**`);
    lines.push(`- Exports: ${meta.exportFiles.map((f) => `\`${f}\``).join(", ")}`);
    for (const step of meta.closureStepsDe) {
      lines.push(`- [ ] ${step}`);
    }
    lines.push("");
  }

  lines.push("## Regel");
  lines.push("");
  lines.push(
    "Kein Auto-Close. Kein Fake-Pass. Nach Opinion/Workshop: Flag in der jeweiligen Moduldatei setzen und Review/PR."
  );
  lines.push("");
  return lines.join("\n");
}

export function renderLegalGateExportBundleMarkdown(): string {
  const parts: string[] = [
    "# AetherRide — Legal/Gate Export Bundle",
    "",
    `Erzeugt: ${new Date().toISOString()}`,
    "",
    "> Bundle zu Handakten. **Schließt keine Gates.**",
    `> Human flags still open: **${String(allHumanGateFlagsStillOpen())}**`,
    "",
    "---",
    "",
    "## 0) Unified Checklist",
    "",
    renderUnifiedGateSignoffChecklistMarkdown(),
    "",
    "---",
    "",
    "## G-0 Workshop Pack",
    "",
    renderG0WorkshopPackMarkdown(),
    "",
    "---",
    "",
    "## G-1 Bosch Outreach",
    "",
    renderG1BoschOutreachMarkdown(),
    "",
    "---",
    "",
    "## G-2 Studienplan",
    "",
    renderG2StudyPlanMarkdown(),
    "",
    "---",
    "",
    "## G-5 Attorney Brief",
    "",
    renderG5AttorneyBriefMarkdown(),
    "",
    "---",
    "",
    "## G-5 Counsel Dispatch Checklist",
    "",
    renderG5CounselDispatchChecklistMarkdown(),
    "",
    "---",
    "",
    "## A-06 ODbL Brief",
    "",
    renderA06AttorneyBriefMarkdown(),
    "",
    "---",
    "",
    "## A-08 Setup-Haftung Brief",
    "",
    renderA08AttorneyBriefMarkdown(),
    "",
  ];
  return parts.join("\n");
}

export function legalSignoffPrepSummaryDe(): string {
  const open = HUMAN_SIGN_GATES.filter((g) => !g.flagValue).map((g) => g.id);
  return `Legal/Gate Prep: ${open.length} Human-Gates offen (${open.join(", ")}) — Bundle/Checkliste bereit, keine Fake-Passes.`;
}
