"use client";

import { useState } from "react";
import {
  JURISDICTIONS,
  type AccessFinding,
  type JurisdictionId,
} from "@/lib/routing/accessRights";

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
  const relevant = findings.filter(
    (f) => f.severity === "block" || f.severity === "warn" || (more && f.severity === "info")
  );

  return (
    <section className="rounded-2xl border border-border bg-surface p-4">
      <div className="mb-2 flex items-start justify-between gap-2">
        <div>
          <h3 className="font-semibold">Wegerecht</h3>
          <p className="text-[11px] text-text-secondary">
            F-NAV-001.1 · zurückhaltend · Gate G-5 offen
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
        <div className="mt-3 rounded-lg bg-surface-elevated p-2 text-[11px] text-text-secondary">
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
          <p className="mt-1">Keine Rechtsberatung. Beschilderung vor Ort hat Vorrang.</p>
        </div>
      )}
    </section>
  );
}
