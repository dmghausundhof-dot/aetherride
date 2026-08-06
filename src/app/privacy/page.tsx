"use client";

import { useMemo, useState } from "react";
import {
  Download,
  FileJson,
  Map as MapIcon,
  Shield,
  Users,
} from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import {
  downloadText,
  fullJsonExport,
  rideToGpx,
  rideToStravaActivityStub,
} from "@/lib/export/gpx";
import { downloadFit, rideToFit } from "@/lib/export/fit";
import {
  CONSENT_LABELS,
  type ConsentPurpose,
} from "@/lib/privacy/consents";
import Link from "next/link";
import {
  describePendingOps,
  getSyncClientState,
} from "@/lib/sync/syncStatus";
import { opsLogStats } from "@/lib/sync/opsLog";
import {
  attorneyPackageStatus,
  renderG5AttorneyBriefMarkdown,
} from "@/lib/routing/g5AttorneyBrief";
import { G5_LEGAL_REVIEW_PASSED } from "@/lib/routing/legalReview";
import {
  COUNSEL_FIRM_CANDIDATES,
  counselDispatchStatusLabel,
  getCounselDispatchMeta,
  markCounselPackageSentNow,
  clearCounselMarkedSent,
  renderG5CounselCoverLetter,
  renderG5CounselDispatchChecklistMarkdown,
} from "@/lib/routing/g5CounselDispatch";
import {
  A08_SIGNOFF,
  renderA08AttorneyBriefMarkdown,
  renderA08CoverLetter,
} from "@/lib/legal/a08CounselBrief";
import { A08_LEGAL_REVIEW_PASSED, a08StatusBadge } from "@/lib/legal/setupLiability";
import {
  A06_LEGAL_REVIEW_PASSED,
  A06_SIGNOFF,
  a06StatusBadge,
  renderA06AttorneyBriefMarkdown,
  renderA06CoverLetter,
} from "@/lib/legal/a06OdblBrief";
import {
  g2StudyStatusSummary,
  renderG2StudyPlanMarkdown,
} from "@/lib/sensor/g2StudyPlan";
import { G2_SUSPENSION_GATE_PASSED } from "@/lib/sensor/fni";
import {
  HUMAN_SIGN_GATES,
  legalSignoffPrepSummaryDe,
  listHumanGateAcks,
  recordHumanGateAck,
  renderLegalGateExportBundleMarkdown,
  renderUnifiedGateSignoffChecklistMarkdown,
} from "@/lib/legal/gateSignoffPrep";

export default function PrivacyExportPage() {
  const rides = useAppStore((s) => s.rides);
  const bikes = useAppStore((s) => s.bikes);
  const profile = useAppStore((s) => s.riderProfile);
  const consents = useAppStore((s) => s.consents);
  const setConsent = useAppStore((s) => s.setConsent);
  const privacyZones = useAppStore((s) => s.privacyZones);
  const addPrivacyZone = useAppStore((s) => s.addPrivacyZone);
  const removePrivacyZone = useAppStore((s) => s.removePrivacyZone);
  const familyRiders = useAppStore((s) => s.familyRiders);
  const addFamilyRider = useAppStore((s) => s.addFamilyRider);
  const activeFamilyRiderId = useAppStore((s) => s.activeFamilyRiderId);
  const setActiveFamilyRider = useAppStore((s) => s.setActiveFamilyRider);
  const assignSetupToRider = useAppStore((s) => s.assignSetupToRider);
  const authSession = useAppStore((s) => s.authSession);
  const signOutUserAsync = useAppStore((s) => s.signOutUserAsync);
  const continueLocal = useAppStore((s) => s.continueLocal);
  const requestDeleteAccount = useAppStore((s) => s.requestDeleteAccount);
  const confirmDeleteAccountLocal = useAppStore(
    (s) => s.confirmDeleteAccountLocal
  );
  const cancelDeleteAccount = useAppStore((s) => s.cancelDeleteAccount);
  const accountDeletion = useAppStore((s) => s.accountDeletion);
  const syncNow = useAppStore((s) => s.syncNow);

  const [riderName, setRiderName] = useState("");
  const [riderWeight, setRiderWeight] = useState(70);
  const [dispatchTick, setDispatchTick] = useState(0);
  const [ackTick, setAckTick] = useState(0);
  const lastRide = rides[0];
  const activeBike = bikes.find((b) => b.isActive) || bikes[0];
  const syncState = getSyncClientState(authSession.syncEnabled);
  const opsStats = opsLogStats();
  const pendingPreview = describePendingOps(3);
  const attorney = attorneyPackageStatus();
  const dispatch = useMemo(() => getCounselDispatchMeta(), [dispatchTick]);
  const humanAcks = useMemo(() => listHumanGateAcks(), [ackTick]);

  const jsonPreview = useMemo(
    () =>
      fullJsonExport({
        bikes,
        rides: rides.slice(0, 3),
        profile,
      }).slice(0, 400) + "…",
    [bikes, rides, profile]
  );

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header>
        <h1 className="text-2xl font-bold">Daten & Privatsphäre</h1>
        <p className="text-sm text-text-secondary">
          F-ACC-003/005/006/007 · Export · Zonen · Familie
        </p>
      </header>

      <section className="rounded-2xl border border-warning/40 bg-warning/10 p-4">
        <h3 className="mb-1 flex items-center gap-2 font-semibold">
          <Shield className="h-4 w-4" /> Legal / Gate Sign-offs (Prep)
        </h3>
        <p className="mb-2 text-xs text-text-secondary">
          {legalSignoffPrepSummaryDe()}
        </p>
        <p className="mb-3 text-[11px] text-warning">
          Human must sign — Checkliste/Bundle schließen keine Gates. Flags bleiben
          false.{" "}
          <Link href="/gates" className="font-medium text-accent underline">
            → Human-Gates-Arbeitsraum
          </Link>
        </p>
        <ul className="mb-3 space-y-1 text-[11px] text-text-secondary">
          {HUMAN_SIGN_GATES.map((g) => {
            const ack = humanAcks
              .filter((a) => a.gateId === g.id)
              .sort((a, b) => a.at.localeCompare(b.at))
              .at(-1);
            return (
              <li key={g.id} className="flex flex-wrap items-center gap-2">
                <span className="font-medium text-foreground">{g.id}</span>
                <span>· {g.flagName}=false</span>
                <span>· {g.ownerRoleDe}</span>
                {ack && (
                  <span className="text-accent">
                    · Ack {ack.kind}{" "}
                    {new Date(ack.at).toLocaleDateString("de-DE")}
                  </span>
                )}
                <button
                  type="button"
                  onClick={() => {
                    recordHumanGateAck(g.id, "pack_reviewed");
                    setAckTick((n) => n + 1);
                  }}
                  className="rounded border border-border px-1.5 py-0.5 text-[10px]"
                >
                  Pack gelesen
                </button>
                <button
                  type="button"
                  onClick={() => {
                    recordHumanGateAck(g.id, "sent_to_owner");
                    setAckTick((n) => n + 1);
                  }}
                  className="rounded border border-border px-1.5 py-0.5 text-[10px]"
                >
                  An Owner gesendet
                </button>
              </li>
            );
          })}
        </ul>
        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() =>
              downloadText(
                "aetherride-gate-signoff-checklist.md",
                renderUnifiedGateSignoffChecklistMarkdown(),
                "text/markdown;charset=utf-8"
              )
            }
            className="rounded-lg bg-accent px-3 py-1.5 text-xs font-medium text-white"
          >
            Unified Checklist (.md)
          </button>
          <button
            type="button"
            onClick={() =>
              downloadText(
                "aetherride-legal-gate-bundle.md",
                renderLegalGateExportBundleMarkdown(),
                "text/markdown;charset=utf-8"
              )
            }
            className="rounded-lg border border-border px-3 py-1.5 text-xs"
          >
            Volles Bundle (.md)
          </button>
        </div>
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 font-semibold">G-5 an echte Kanzlei</h3>
        <p className="mb-2 text-xs text-text-secondary">{attorney.summaryDe}</p>
        <p className="mb-2 text-[11px] text-text-secondary">
          Status:{" "}
          <span className="font-medium text-foreground">
            {counselDispatchStatusLabel(dispatch.status)}
          </span>
          {" · "}
          Gate G5 = {String(G5_LEGAL_REVIEW_PASSED)} · Sign-off offen:{" "}
          {attorney.pendingSignOff.join(", ")}
          {dispatch.markedSentAt
            ? ` · markiert versendet ${new Date(dispatch.markedSentAt).toLocaleString("de-DE")}`
            : ""}
        </p>
        <p className="mb-3 text-[11px] text-text-secondary">
          Kein Auto-Versand. Absender-Vorschlag: {dispatch.suggestedSenderName} (
          {dispatch.suggestedSenderEmail}).
        </p>
        <div className="mb-3 space-y-1 text-[11px] text-text-secondary">
          <p className="font-medium text-foreground">Kanzlei-Profile (Auswahl)</p>
          {COUNSEL_FIRM_CANDIDATES.map((c) => (
            <p key={c.id}>
              <span className="font-medium text-foreground">{c.focusDe}</span>
              {" — "}
              {c.searchHintDe}
            </p>
          ))}
        </div>
        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() =>
              downloadText(
                "aetherride-g5-anwalt-briefing.md",
                renderG5AttorneyBriefMarkdown(),
                "text/markdown;charset=utf-8"
              )
            }
            className="rounded-lg bg-accent px-3 py-1.5 text-xs font-medium text-white"
          >
            Briefing (.md)
          </button>
          <button
            type="button"
            onClick={() =>
              downloadText(
                "aetherride-g5-anschreiben.txt",
                renderG5CounselCoverLetter(),
                "text/plain;charset=utf-8"
              )
            }
            className="rounded-lg border border-border px-3 py-1.5 text-xs"
          >
            Anschreiben
          </button>
          <button
            type="button"
            onClick={() =>
              downloadText(
                "aetherride-g5-versand-checkliste.md",
                renderG5CounselDispatchChecklistMarkdown(),
                "text/markdown;charset=utf-8"
              )
            }
            className="rounded-lg border border-border px-3 py-1.5 text-xs"
          >
            Versand-Checkliste
          </button>
          <button
            type="button"
            onClick={() => {
              markCounselPackageSentNow();
              setDispatchTick((n) => n + 1);
            }}
            className="rounded-lg border border-warning/40 bg-warning/10 px-3 py-1.5 text-xs"
          >
            Als versendet markieren
          </button>
          {dispatch.markedSentAt && (
            <button
              type="button"
              onClick={() => {
                clearCounselMarkedSent();
                setDispatchTick((n) => n + 1);
              }}
              className="rounded-lg border border-border px-3 py-1.5 text-xs text-text-secondary"
            >
              Markierung löschen
            </button>
          )}
        </div>
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 font-semibold">A-08 an Legal (Setup-Haftung)</h3>
        <p className="mb-2 text-xs text-text-secondary">
          {a08StatusBadge()} · Gate A08 = {String(A08_LEGAL_REVIEW_PASSED)} ·
          mayClaim = {String(A08_SIGNOFF.mayClaimLegallyReviewed)}
        </p>
        <p className="mb-3 text-[11px] text-text-secondary">
          Mandat getrennt von G-5/A-06. Kein Auto-Versand.
        </p>
        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() =>
              downloadText(
                "aetherride-a08-anwalt-briefing.md",
                renderA08AttorneyBriefMarkdown(),
                "text/markdown;charset=utf-8"
              )
            }
            className="rounded-lg bg-accent px-3 py-1.5 text-xs font-medium text-white"
          >
            Briefing (.md)
          </button>
          <button
            type="button"
            onClick={() =>
              downloadText(
                "aetherride-a08-anschreiben.txt",
                renderA08CoverLetter(),
                "text/plain;charset=utf-8"
              )
            }
            className="rounded-lg border border-border px-3 py-1.5 text-xs"
          >
            Anschreiben
          </button>
        </div>
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 font-semibold">A-06 an Legal (ODbL / OSM)</h3>
        <p className="mb-2 text-xs text-text-secondary">
          {a06StatusBadge()} · Gate A06 = {String(A06_LEGAL_REVIEW_PASSED)} ·
          mayClaim = {String(A06_SIGNOFF.mayClaimOdblCleared)}
        </p>
        <p className="mb-3 text-[11px] text-text-secondary">
          Heatmaps & Ableitungen — Mandat getrennt von G-5/A-08.
        </p>
        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() =>
              downloadText(
                "aetherride-a06-anwalt-briefing.md",
                renderA06AttorneyBriefMarkdown(),
                "text/markdown;charset=utf-8"
              )
            }
            className="rounded-lg bg-accent px-3 py-1.5 text-xs font-medium text-white"
          >
            Briefing (.md)
          </button>
          <button
            type="button"
            onClick={() =>
              downloadText(
                "aetherride-a06-anschreiben.txt",
                renderA06CoverLetter(),
                "text/plain;charset=utf-8"
              )
            }
            className="rounded-lg border border-border px-3 py-1.5 text-xs"
          >
            Anschreiben
          </button>
        </div>
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 font-semibold">G-2 Validierungsstudienplan</h3>
        <p className="mb-2 text-xs text-text-secondary">
          {g2StudyStatusSummary()} · Gate G2 ={" "}
          {String(G2_SUSPENSION_GATE_PASSED)}
        </p>
        <p className="mb-3 text-[11px] text-text-secondary">
          Spec §7.5 — sieben Bestehenskriterien. Kein Fake-Pass.
        </p>
        <button
          type="button"
          onClick={() =>
            downloadText(
              "aetherride-g2-studienplan.md",
              renderG2StudyPlanMarkdown(),
              "text/markdown;charset=utf-8"
            )
          }
          className="rounded-lg bg-accent px-3 py-1.5 text-xs font-medium text-white"
        >
          Studienplan (.md)
        </button>
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <Shield className="h-4 w-4 text-accent" /> Konto (F-ACC-001/004)
        </h3>
        <p className="mb-2 text-xs text-text-secondary">
          {authSession.user
            ? `${authSession.user.displayName} · ${authSession.user.provider} · Sync ${
                authSession.syncEnabled ? "an" : "aus"
              }`
            : "Nicht angemeldet — lokale Nutzung möglich"}
        </p>
        <div className="flex flex-wrap gap-2">
          <Link
            href="/login"
            className="rounded-lg bg-accent px-3 py-1.5 text-xs font-medium text-white"
          >
            Anmelden / Registrieren
          </Link>
          <button
            type="button"
            onClick={() => continueLocal()}
            className="rounded-lg bg-surface-elevated px-3 py-1.5 text-xs"
          >
            Lokal
          </button>
          <button
            type="button"
            onClick={() => signOutUserAsync()}
            className="rounded-lg bg-surface-elevated px-3 py-1.5 text-xs"
          >
            Abmelden
          </button>
          <button
            type="button"
            onClick={async () => {
              const r = await syncNow();
              if (r.skipped) {
                alert(r.reason ?? "Sync übersprungen");
                return;
              }
              const parts = [
                `${r.flushed} Ops ack`,
                r.via === "server_v2" ? "Server v2" : r.via,
                r.conflicts ? `${r.conflicts} Konflikte (LWW)` : null,
                r.pulled ? `${r.pulled} gezogen` : null,
                r.revision ? `rev ${r.revision}` : null,
              ].filter(Boolean);
              alert(parts.join(" · "));
            }}
            className="rounded-lg bg-accent px-3 py-1.5 text-xs text-white"
          >
            Sync jetzt
          </button>
          <button
            type="button"
            onClick={() => {
              const req = requestDeleteAccount();
              if (!req) alert("Konto nötig für Löschung");
              else
                alert(
                  `Löschung beantragt — Wirkung bis ${new Date(
                    req.effectiveBy
                  ).toLocaleDateString("de-DE")} (≤30 Tage)`
                );
            }}
            className="rounded-lg border border-error/40 px-3 py-1.5 text-xs text-error"
          >
            Konto löschen
          </button>
        </div>
        <div className="mt-3 rounded-lg bg-surface-elevated p-2 text-[11px] text-text-secondary">
          <p className="font-medium text-foreground">Sync-Status (v2 · LWW)</p>
          <p>
            {syncState.note} · pending {opsStats.pending}/{opsStats.total}
            {syncState.lastFlushAt
              ? ` · letzter Flush ${new Date(syncState.lastFlushAt).toLocaleString("de-DE")}`
              : ""}
            {syncState.serverRevisionCursor
              ? ` · cursor ${syncState.serverRevisionCursor}`
              : ""}
            {syncState.lastConflicts > 0
              ? ` · Konflikte ${syncState.lastConflicts}`
              : ""}
            {syncState.lastPulled > 0
              ? ` · gezogen ${syncState.lastPulled}`
              : ""}
          </p>
          {pendingPreview.length > 0 && (
            <ul className="mt-1 list-inside list-disc">
              {pendingPreview.map((p) => (
                <li key={p}>{p}</li>
              ))}
            </ul>
          )}
        </div>
        {accountDeletion && (
          <div className="mt-2 space-y-2 rounded-lg border border-warning/40 bg-warning/10 p-2 text-[11px] text-warning">
            <p>
              Löschung {accountDeletion.status} · wirksam bis{" "}
              {new Date(accountDeletion.effectiveBy).toLocaleDateString("de-DE")}
              {accountDeletion.confirmationEmailSent
                ? " · E-Mail-Flag (kein Versand)"
                : ""}
            </p>
            <div className="flex flex-wrap gap-2">
              {accountDeletion.status === "pending" && (
                <button
                  type="button"
                  onClick={() => confirmDeleteAccountLocal()}
                  className="rounded border border-warning px-2 py-1 text-[10px]"
                >
                  Lokal bestätigen
                </button>
              )}
              {accountDeletion.status !== "cancelled" &&
                accountDeletion.status !== "completed" && (
                  <button
                    type="button"
                    onClick={() => cancelDeleteAccount()}
                    className="rounded border border-border px-2 py-1 text-[10px] text-text-secondary"
                  >
                    Abbrechen
                  </button>
                )}
            </div>
          </div>
        )}
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <Download className="h-4 w-4 text-accent" /> Export (Art. 20)
        </h3>
        <div className="flex flex-col gap-2">
          <button
            type="button"
            disabled={!lastRide}
            onClick={() => {
              if (!lastRide) return;
              const gpx = rideToGpx(lastRide, activeBike?.name);
              downloadText(
                `aetherride-${lastRide.id.slice(0, 8)}.gpx`,
                gpx,
                "application/gpx+xml"
              );
            }}
            className="rounded-xl bg-accent py-2.5 text-sm font-semibold text-white disabled:opacity-40"
          >
            Letzten Ride als GPX
          </button>
          <button
            type="button"
            disabled={!lastRide}
            onClick={() => {
              if (!lastRide) return;
              const fit = rideToFit(lastRide, { privacyZones });
              downloadFit(`aetherride-${lastRide.id.slice(0, 8)}.fit`, fit);
            }}
            className="rounded-xl border border-border py-2.5 text-sm font-semibold disabled:opacity-40"
          >
            Letzten Ride als FIT (Garmin SDK)
          </button>
          <button
            type="button"
            onClick={() => {
              const json = fullJsonExport({ bikes, rides, profile });
              downloadText(
                "aetherride-export.json",
                json,
                "application/json"
              );
            }}
            className="flex items-center justify-center gap-2 rounded-xl border border-border py-2.5 text-sm"
          >
            <FileJson className="h-4 w-4" /> JSON-Vollexport
          </button>
          <button
            type="button"
            disabled={!lastRide}
            onClick={() => {
              if (!lastRide) return;
              const stub = rideToStravaActivityStub(lastRide);
              downloadText(
                "strava-activity-stub.json",
                JSON.stringify(stub, null, 2),
                "application/json"
              );
            }}
            className="rounded-xl border border-border py-2.5 text-sm disabled:opacity-40"
          >
            Strava-Activity-Stub (ohne OAuth)
          </button>
          <button
            type="button"
            disabled={rides.length === 0}
            onClick={() => {
              const withTrack = rides.filter((r) => r.track && r.track.length >= 2);
              const list = withTrack.length > 0 ? withTrack : rides.slice(0, 10);
              const bikeName = (id: string) =>
                bikes.find((b) => b.id === id)?.name;
              const bundle = list
                .map(
                  (r, i) =>
                    `===== ${i + 1}. ${r.plannedRouteName ?? r.id.slice(0, 8)} =====\n` +
                    rideToGpx(r, bikeName(r.bikeId))
                )
                .join("\n\n");
              downloadText(
                "aetherride-rides-batch.gpx.txt",
                bundle,
                "text/plain;charset=utf-8"
              );
            }}
            className="rounded-xl border border-accent/40 bg-accent/10 py-2.5 text-sm font-medium disabled:opacity-40"
          >
            Alle Rides als GPX-Batch (kein Paywall)
          </button>
        </div>
        <pre className="mt-3 max-h-24 overflow-auto rounded-lg bg-surface-elevated p-2 text-[10px] text-text-secondary">
          {jsonPreview}
        </pre>
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <Shield className="h-4 w-4 text-accent" /> Einwilligungen
        </h3>
        {consents.map((c) => (
          <label
            key={c.purpose}
            className="mb-3 flex items-start gap-2 text-sm"
          >
            <input
              type="checkbox"
              className="mt-1"
              checked={c.granted}
              onChange={(e) =>
                setConsent(c.purpose as ConsentPurpose, e.target.checked)
              }
            />
            <span>
              <span className="font-medium">
                {CONSENT_LABELS[c.purpose].title}
              </span>
              <span className="mt-0.5 block text-[11px] text-text-secondary">
                {CONSENT_LABELS[c.purpose].description}
              </span>
              <span className="text-[10px] text-text-secondary">
                Policy {c.policyVersion} ·{" "}
                {new Date(c.updatedAt).toLocaleString("de-DE")}
              </span>
            </span>
          </label>
        ))}
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <MapIcon className="h-4 w-4 text-accent" /> Privatsphärenzonen
        </h3>
        <p className="mb-2 text-xs text-text-secondary">
          Tracks werden in diesen Radien für Heatmap/Export gekappt (Strava-Lehre).
        </p>
        {privacyZones.map((z) => (
          <div
            key={z.id}
            className="mb-2 flex items-center justify-between rounded-xl bg-surface-elevated px-3 py-2 text-sm"
          >
            <span>
              {z.label} · {z.radiusM} m · {z.lat.toFixed(3)}, {z.lng.toFixed(3)}
            </span>
            <button
              type="button"
              className="text-xs text-error"
              onClick={() => removePrivacyZone(z.id)}
            >
              Entfernen
            </button>
          </div>
        ))}
        <button
          type="button"
          onClick={() =>
            addPrivacyZone({
              label: "Arbeit",
              lat: 47.452,
              lng: 12.16,
              radiusM: 150,
            })
          }
          className="mt-1 text-sm text-accent"
        >
          + Demo-Zone „Arbeit“
        </button>
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <Users className="h-4 w-4 text-accent" /> Familien-Garage (P3)
        </h3>
        <p className="mb-2 text-xs text-text-secondary">
          Ein Bike, mehrere Fahrer mit eigenen Setups (F-ACC-007).
        </p>
        {familyRiders.map((r) => (
          <button
            key={r.id}
            type="button"
            onClick={() => setActiveFamilyRider(r.id)}
            className={`mb-2 w-full rounded-xl border px-3 py-2 text-left text-sm ${
              activeFamilyRiderId === r.id
                ? "border-accent bg-accent/10"
                : "border-border"
            }`}
          >
            {r.displayName} · {r.weightKg} kg · {r.setupIds.length} Setups
          </button>
        ))}
        <div className="mt-2 flex gap-2">
          <input
            value={riderName}
            onChange={(e) => setRiderName(e.target.value)}
            placeholder="Name"
            className="flex-1 rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
          />
          <input
            type="number"
            value={riderWeight}
            onChange={(e) => setRiderWeight(Number(e.target.value))}
            className="w-20 rounded-xl border border-border bg-surface-elevated px-2 py-2 text-sm"
          />
          <button
            type="button"
            onClick={() => {
              if (!riderName.trim()) return;
              const id = addFamilyRider(riderName.trim(), riderWeight);
              const setup = activeBike?.setups.find((s) => s.isCurrent);
              if (setup) assignSetupToRider(id, setup.id);
              setRiderName("");
            }}
            className="rounded-xl bg-accent px-3 text-sm font-medium text-white"
          >
            +
          </button>
        </div>
      </section>

      <Link href="/profile" className="text-center text-sm text-accent">
        ← Profil
      </Link>
    </div>
  );
}
