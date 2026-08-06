"use client";

import { useState } from "react";
import {
  JURISDICTIONS,
  type AccessFinding,
  type JurisdictionId,
} from "@/lib/routing/accessRights";
import {
  g5StatusBadge,
  g5StatusShort,
  getLegalReview,
  isG5ClosedFor,
} from "@/lib/routing/legalReview";
import {
  attorneyPackageStatus,
  G5_ATTORNEY_MANDATE,
  G5_RULE_INVENTORY,
  renderG5AttorneyBriefMarkdown,
} from "@/lib/routing/g5AttorneyBrief";
import { downloadText } from "@/lib/export/gpx";

export function AccessRightsPanel({
  jurisdiction,
  onJurisdictionChange,
  findings,
  blocked,
  prefaceShort,
}: {
  jurisdiction: JurisdictionId;
  onJurisdictionChange: (j: JurisdictionId) => void;
  findings: AccessFinding[];
  blocked: boolean;
  prefaceShort?: string;
}) {
  const [more, setMore] = useState(false);
  const profile = JURISDICTIONS[jurisdiction];
  const review = getLegalReview(jurisdiction);
  const g5Closed = isG5ClosedFor(jurisdiction);
  const attorney = attorneyPackageStatus();
  const relevant = findings.filter(
    (f) => f.severity === "block" || f.severity === "warn" || (more && f.severity === "info")
  );

  return (
    <section className="rounded-2xl border border-border bg-surface p-4">
      <div className="mb-2 flex items-start justify-between gap-2">
        <div>
          <h3 className="font-semibold">Wegerecht</h3>
          <p className="text-[11px] text-text-secondary">
            F-NAV-001.1 · zurückhaltend · {g5StatusBadge(jurisdiction)}
          </p>
        </div>
        <button
          type="button"
          onClick={() => setMore((v) => !v)}
          className="rounded-lg border border-border px-2 py-1 text-[11px] font-medium"
        >
          {more ? "Weniger" : "Mehr"}
        </button>
      </div>

      <div className="mb-3 flex flex-wrap gap-1">
        {(["AT-7", "DE-BY"] as JurisdictionId[]).map((id) => (
          <button
            key={id}
            type="button"
            onClick={() => onJurisdictionChange(id)}
            className={`rounded-lg px-2 py-1 text-[10px] font-medium ${
              jurisdiction === id
                ? "bg-accent text-white"
                : "bg-surface-elevated text-text-secondary"
            }`}
          >
            {JURISDICTIONS[id].label}
          </button>
        ))}
        <span className="rounded-lg bg-surface-elevated px-2 py-1 text-[10px] text-text-secondary opacity-60">
          Weitere später
        </span>
      </div>

      <p className="mb-2 text-sm text-text-secondary">
        {prefaceShort ?? profile.prefaceShort}
      </p>

      <p
        className={`mb-2 rounded-lg px-2 py-1.5 text-[11px] ${
          g5Closed
            ? "border border-success/30 bg-success/10"
            : "border border-warning/30 bg-warning/10"
        }`}
      >
        {g5StatusShort(jurisdiction)}
      </p>

      {blocked && (
        <p className="mb-2 rounded-lg border border-error/40 bg-error/10 px-2 py-1.5 text-xs">
          Route enthält gesperrte Abschnitte — diese wurden entfernt. Ohne
          Alternative ggf. keine vollständige Route.
        </p>
      )}

      {relevant.length === 0 ? (
        <p className="text-xs text-text-secondary">
          Keine Sperr- oder Grauzonenhinweise in den Demo-Daten.
        </p>
      ) : (
        <ul className="space-y-2">
          {relevant.map((f) => (
            <li
              key={`${f.ruleId}-${f.edgeId}`}
              className={`rounded-lg px-2 py-1.5 text-xs ${
                f.severity === "block"
                  ? "border border-error/30 bg-error/10"
                  : f.severity === "warn"
                    ? "border border-warning/30 bg-warning/10"
                    : "bg-surface-elevated"
              }`}
            >
              <div className="font-medium">
                {f.severity === "block"
                  ? "Nicht geroutet"
                  : f.severity === "warn"
                    ? "Hinweis"
                    : "Info"}
                : {f.short}
              </div>
              {more && (
                <div className="mt-1 space-y-1 text-text-secondary">
                  <p>{f.more}</p>
                  <p className="text-[10px]">
                    Quellen:{" "}
                    {f.sources
                      .map((s) => (s.url ? `${s.label}` : s.label))
                      .join(" · ")}
                  </p>
                  {f.sources.some((s) => s.url) && (
                    <ul className="text-[10px]">
                      {f.sources
                        .filter((s) => s.url)
                        .map((s) => (
                          <li key={s.url}>
                            <a
                              href={s.url}
                              target="_blank"
                              rel="noreferrer"
                              className="text-accent underline"
                            >
                              {s.label}
                            </a>
                          </li>
                        ))}
                    </ul>
                  )}
                </div>
              )}
            </li>
          ))}
        </ul>
      )}

      {more && (
        <div className="mt-3 space-y-2 rounded-lg bg-surface-elevated p-2 text-[11px] text-text-secondary">
          <div>
            <p className="mb-1 font-medium text-foreground">Mehr Kontext</p>
            <p>{profile.prefaceMore}</p>
            <p className="mt-2">
              Fassung {profile.version}
              {profile.legalReviewedAt
                ? ` · geprüft ${profile.legalReviewedAt}`
                : " · Legal-Review ausstehend"}
              {" · "}
              nächste Prüfung geplant {profile.nextReviewDue}.
            </p>
            <p className="mt-1">
              Keine Rechtsberatung. Beschilderung vor Ort hat Vorrang.
            </p>
          </div>

          <div>
            <p className="mb-1 font-medium text-foreground">
              G-5 Review-Checkliste ({review.status})
            </p>
            <p>
              Entwurf: {review.draftAuthor} · {review.draftVersion}
              {review.legalReviewer
                ? ` · Legal: ${review.legalReviewer}`
                : " · Legal-Sign-off fehlt"}
            </p>
            {review.sources.length > 0 && (
              <ul className="mt-1 list-inside list-disc">
                {review.sources.map((s) => (
                  <li key={s.id}>
                    {s.url ? (
                      <a
                        href={s.url}
                        target="_blank"
                        rel="noreferrer"
                        className="text-accent underline"
                      >
                        {s.label}
                      </a>
                    ) : (
                      s.label
                    )}
                    {s.editorialCheckedAt
                      ? ` · redaktionell ${s.editorialCheckedAt}`
                      : " · Quelle offen"}
                  </li>
                ))}
              </ul>
            )}
            {review.openQuestions.length > 0 && (
              <div className="mt-2">
                <p className="font-medium text-foreground">Offene Legal-Fragen</p>
                <ul className="mt-1 list-inside list-disc">
                  {review.openQuestions.map((q) => (
                    <li key={q}>{q}</li>
                  ))}
                </ul>
              </div>
            )}
            <p className="mt-2">
              Launch-fähig: {review.launchEligible || g5Closed ? "ja" : "nein"}{" "}
              (A-07 / Launch-Kriterium #8).
            </p>
          </div>

          <div>
            <p className="mb-1 font-medium text-foreground">
              Anwalt-Paket G-5
            </p>
            <p>{attorney.summaryDe}</p>
            <p className="mt-1">
              Mandat: {G5_ATTORNEY_MANDATE.title}. Sign-off offen:{" "}
              {attorney.pendingSignOff.join(", ") || "—"}.
            </p>
            <p className="mt-1">
              Regelinventar: {G5_RULE_INVENTORY.length} Regeln zur Counsel-Prüfung
              · A-06/A-08 separat.
            </p>
            <button
              type="button"
              className="mt-2 rounded-lg border border-border px-2 py-1 text-[10px] font-medium text-foreground"
              onClick={() =>
                downloadText(
                  "aetherride-g5-anwalt-briefing.md",
                  renderG5AttorneyBriefMarkdown(),
                  "text/markdown;charset=utf-8"
                )
              }
            >
              Briefing als Markdown herunterladen
            </button>
          </div>
        </div>
      )}
    </section>
  );
}
