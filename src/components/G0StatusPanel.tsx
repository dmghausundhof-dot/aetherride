"use client";

import {
  G0_DECISION,
  G0_NON_GOALS,
  G0_SPRINT0_PLAN,
  NATIVE_MODULE_MATRIX,
  g0StatusBadge,
  g0StatusShort,
  evaluateG0GoNoGo,
  isG0Closed,
} from "@/lib/platform/g0TeamSetup";
import {
  G0_WORKSHOP_AGENDA,
  g0WorkshopStatusSummary,
  renderG0WorkshopPackMarkdown,
  setG0WorkshopLocalNote,
} from "@/lib/platform/g0Workshop";
import {
  renderG0FacilitatorRunbookMarkdown,
  renderG0WorkshopIcsStub,
  renderG0WorkshopInviteText,
} from "@/lib/platform/g0WorkshopOps";
import { downloadText } from "@/lib/export/gpx";
import {
  g1StatusBadge,
  getG1OutreachMeta,
  markG1OutreachSentNow,
  clearG1OutreachMarkedSent,
  renderG1BoschCoverLetter,
  renderG1BoschOutreachMarkdown,
  G1_BOSCH_ACCESS_CLEARED,
} from "@/lib/ble/g1BoschOutreach";
import { useState } from "react";

export function G0StatusPanel({ compact = false }: { compact?: boolean }) {
  const closed = isG0Closed();
  const go = evaluateG0GoNoGo();
  const totalMin = G0_WORKSHOP_AGENDA.reduce((n, a) => n + a.minutes, 0);
  const [g1Tick, setG1Tick] = useState(0);
  const g1 = getG1OutreachMeta();
  void g1Tick;

  if (compact) {
    return (
      <p
        className={`rounded-lg px-2 py-1.5 text-[11px] ${
          closed
            ? "border border-success/30 bg-success/10"
            : "border border-warning/30 bg-warning/10"
        }`}
      >
        {g0StatusBadge()}: {g0StatusShort()}
      </p>
    );
  }

  return (
    <section className="rounded-2xl border border-border bg-surface p-4">
      <h3 className="font-semibold">Gate G-0 · Team-Setup</h3>
      <p className="mt-1 text-[11px] text-text-secondary">
        Spec §5.1 / §9.2 · vor Sprint 1 · {g0StatusBadge()}
      </p>
      <p
        className={`mt-2 rounded-lg px-2 py-1.5 text-xs ${
          closed
            ? "border border-success/30 bg-success/10"
            : "border border-warning/30 bg-warning/10"
        }`}
      >
        {g0StatusShort()}
      </p>
      <p className="mt-2 text-xs text-text-secondary">
        Workshop: {g0WorkshopStatusSummary()}
      </p>
      <p className="mt-2 text-xs text-text-secondary">
        Go/No-Go (aktuell): <span className="font-medium">{go.result}</span>
      </p>
      <ul className="mt-1 list-inside list-disc text-[11px] text-text-secondary">
        {go.reasons.map((r) => (
          <li key={r}>{r}</li>
        ))}
      </ul>

      <h4 className="mt-3 text-xs font-semibold">
        Decision-Workshop (~{totalMin} Min)
      </h4>
      <ol className="mt-1 list-inside list-decimal text-[11px] text-text-secondary">
        {G0_WORKSHOP_AGENDA.map((a) => (
          <li key={a.id}>
            {a.minutes}&apos; {a.titleDe}
          </li>
        ))}
      </ol>
      <div className="mt-2 flex flex-wrap gap-2">
        <button
          type="button"
          onClick={() =>
            downloadText(
              "aetherride-g0-workshop-pack.md",
              renderG0WorkshopPackMarkdown(),
              "text/markdown;charset=utf-8"
            )
          }
          className="rounded-lg bg-accent px-2 py-1 text-[10px] font-medium text-white"
        >
          Workshop-Pack (.md)
        </button>
        <button
          type="button"
          onClick={() =>
            downloadText(
              "aetherride-g0-einladung.txt",
              renderG0WorkshopInviteText(),
              "text/plain;charset=utf-8"
            )
          }
          className="rounded-lg border border-border px-2 py-1 text-[10px]"
        >
          Einladung
        </button>
        <button
          type="button"
          onClick={() =>
            downloadText(
              "aetherride-g0-facilitator.md",
              renderG0FacilitatorRunbookMarkdown(),
              "text/markdown;charset=utf-8"
            )
          }
          className="rounded-lg border border-border px-2 py-1 text-[10px]"
        >
          Facilitator
        </button>
        <button
          type="button"
          onClick={() =>
            downloadText(
              "aetherride-g0-workshop.ics",
              renderG0WorkshopIcsStub(),
              "text/calendar;charset=utf-8"
            )
          }
          className="rounded-lg border border-border px-2 py-1 text-[10px]"
        >
          ICS-Stub
        </button>
        <button
          type="button"
          onClick={() =>
            setG0WorkshopLocalNote(
              `termin_vorgemerkt:${new Date().toISOString()}`
            )
          }
          className="rounded-lg border border-border px-2 py-1 text-[10px]"
        >
          Termin lokal vormerken
        </button>
      </div>

      <h4 className="mt-3 text-xs font-semibold">G-1 parallel · Bosch LDI</h4>
      <p className="mt-1 text-[11px] text-text-secondary">
        {g1StatusBadge()} · Gate G1 = {String(G1_BOSCH_ACCESS_CLEARED)}
        {g1.markedSentAt
          ? ` · markiert ${new Date(g1.markedSentAt).toLocaleString("de-DE")}`
          : ""}
      </p>
      <div className="mt-2 flex flex-wrap gap-2">
        <button
          type="button"
          onClick={() =>
            downloadText(
              "aetherride-g1-bosch-outreach.md",
              renderG1BoschOutreachMarkdown(),
              "text/markdown;charset=utf-8"
            )
          }
          className="rounded-lg bg-accent px-2 py-1 text-[10px] font-medium text-white"
        >
          Outreach (.md)
        </button>
        <button
          type="button"
          onClick={() =>
            downloadText(
              "aetherride-g1-bosch-anschreiben.txt",
              renderG1BoschCoverLetter(),
              "text/plain;charset=utf-8"
            )
          }
          className="rounded-lg border border-border px-2 py-1 text-[10px]"
        >
          Anschreiben
        </button>
        <button
          type="button"
          onClick={() => {
            markG1OutreachSentNow();
            setG1Tick((n) => n + 1);
          }}
          className="rounded-lg border border-warning/40 bg-warning/10 px-2 py-1 text-[10px]"
        >
          Als versendet markieren
        </button>
        {g1.markedSentAt && (
          <button
            type="button"
            onClick={() => {
              clearG1OutreachMarkedSent();
              setG1Tick((n) => n + 1);
            }}
            className="rounded-lg border border-border px-2 py-1 text-[10px] text-text-secondary"
          >
            Markierung löschen
          </button>
        )}
      </div>

      <h4 className="mt-3 text-xs font-semibold">Checkliste</h4>
      <ul className="mt-1 space-y-1 text-[11px] text-text-secondary">
        {G0_DECISION.checklist.map((c) => (
          <li key={c.id}>
            {c.done ? "✓" : "○"} {c.label}
          </li>
        ))}
      </ul>

      <h4 className="mt-3 text-xs font-semibold">Native-Modul-Matrix</h4>
      <div className="mt-1 overflow-x-auto">
        <table className="w-full text-left text-[10px] text-text-secondary">
          <thead>
            <tr className="border-b border-border">
              <th className="py-1 pr-2">Modul</th>
              <th className="py-1 pr-2">Web</th>
              <th className="py-1">Owner</th>
            </tr>
          </thead>
          <tbody>
            {NATIVE_MODULE_MATRIX.map((row) => (
              <tr key={row.id} className="border-b border-border/50">
                <td className="py-1 pr-2 font-medium text-foreground">
                  {row.specModule}
                </td>
                <td className="py-1 pr-2">{row.webDemo}</td>
                <td className="py-1">{row.ownerRole}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h4 className="mt-3 text-xs font-semibold">Sprint-0 (ohne Fake-Flutter)</h4>
      <ul className="mt-1 list-inside list-disc text-[11px] text-text-secondary">
        {G0_SPRINT0_PLAN.map((p) => (
          <li key={p}>{p}</li>
        ))}
      </ul>
      <h4 className="mt-3 text-xs font-semibold">Non-Goals</h4>
      <ul className="mt-1 list-inside list-disc text-[11px] text-text-secondary">
        {G0_NON_GOALS.map((p) => (
          <li key={p}>{p}</li>
        ))}
      </ul>
    </section>
  );
}
