"use client";

import { RadGlyph } from "@/components/garage/RadGlyph";
import { BracketingPanel } from "@/components/garage/BracketingPanel";
import { templatesForCategory } from "@/lib/setup/templates";
import {
  setupConditionLabel,
  setupConditionOptions,
} from "@/lib/setup/conditionLabels";
import { garageTabCopy } from "@/lib/i18n/garageTabCopy";
import { presentSetupTemplate } from "@/lib/i18n/setupTemplateCopy";
import { chromeDateLocale } from "@/lib/i18n/chromeLang";
import { useChromeLang } from "@/hooks/useChromeLang";
import type { Bike, SetupCondition } from "@/types";

interface Props {
  selected: Bike;
  setupLabel: string;
  setSetupLabel: (v: string) => void;
  setupCondition: SetupCondition;
  setSetupCondition: (v: SetupCondition) => void;
  createSetup: () => void;
  setCurrentSetup: (bikeId: string, setupId: string) => void;
  applySetupTemplate: (
    bikeId: string,
    templateId: string,
    lang?: import("@/lib/i18n/chromeLang").ChromeLang
  ) => void;
}

function formatSetupDate(iso: string, locale: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  return d.toLocaleDateString(locale, {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
}

export function GarageSetupsTab({
  selected,
  setupLabel,
  setSetupLabel,
  setupCondition,
  setSetupCondition,
  createSetup,
  setCurrentSetup,
  applySetupTemplate,
}: Props) {
  const lang = useChromeLang();
  const tab = garageTabCopy(lang);
  const dateLoc = chromeDateLocale(lang);
  const conditions = setupConditionOptions(lang);
  const sorted = [...selected.setups].sort((a, b) => b.version - a.version);

  return (
    <div className="flex flex-col gap-4">
      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-1 font-semibold">{tab.setupVersionsTitle}</h3>
        <p className="mb-3 text-xs text-text-secondary">
          {tab.setupVersionsHint}
        </p>

        <h4 className="mb-2 flex items-center gap-2 text-sm font-semibold">
          <RadGlyph name="setup" size={16} />
          {tab.setupNew}
        </h4>
        <p className="mb-2 text-xs text-text-secondary">
          {tab.setupNewHint}
        </p>
        <div className="flex flex-col gap-2">
          <input
            value={setupLabel}
            onChange={(e) => setSetupLabel(e.target.value)}
            placeholder={tab.setupNamePlaceholder}
            className="rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
          />
          <select
            value={setupCondition}
            onChange={(e) =>
              setSetupCondition(e.target.value as SetupCondition)
            }
            className="rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
          >
            {conditions.map((c) => (
              <option key={c.value} value={c.value}>
                {c.label}
              </option>
            ))}
          </select>
          <button
            type="button"
            onClick={createSetup}
            className="rounded-xl bg-accent py-2.5 text-sm font-semibold text-on-accent"
          >
            {tab.setupSave}
          </button>
        </div>
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 font-semibold">{tab.setupSaved}</h3>
        {sorted.length === 0 ? (
          <p className="text-xs text-text-secondary">
            {tab.setupEmpty}
          </p>
        ) : (
          <div className="flex flex-col gap-2">
            {sorted.map((setup) => (
              <button
                key={setup.id}
                type="button"
                onClick={() => setCurrentSetup(selected.id, setup.id)}
                className={`rounded-xl border p-3 text-left transition ${
                  setup.isCurrent
                    ? "border-accent bg-accent/10"
                    : "border-border bg-surface-elevated hover:border-accent/40"
                }`}
              >
                <div className="flex items-center justify-between gap-2">
                  <div className="font-medium">{setup.label}</div>
                  {setup.isCurrent ? (
                    <span className="rounded-full bg-accent px-2 py-0.5 text-[10px] font-semibold text-on-accent">
                      {tab.active}
                    </span>
                  ) : (
                    <span className="text-[11px] font-medium text-accent">
                      {tab.use}
                    </span>
                  )}
                </div>
                <p className="mt-1 text-xs text-text-secondary">
                  {[
                    tab.setupVersion(setup.version),
                    formatSetupDate(setup.createdAt, dateLoc),
                    setupConditionLabel(setup.conditions, lang),
                  ]
                    .filter(Boolean)
                    .join(" · ")}
                </p>
                <div className="mt-2 flex flex-wrap gap-1.5">
                  {setup.values.slice(0, 6).map((v) => (
                    <span
                      key={`${v.slot}.${v.adjusterKey}`}
                      className={`rounded bg-surface px-1.5 py-0.5 text-[11px] tabular-nums ${
                        v.outOfSpec ? "text-error" : "text-text-secondary"
                      }`}
                    >
                      {v.adjusterKey.split(".").pop()}: {v.valueNum}
                      {v.unit === "clicks" ? "" : ` ${v.unit}`}
                    </span>
                  ))}
                </div>
              </button>
            ))}
          </div>
        )}
      </section>

      <BracketingPanel bike={selected} />

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 font-semibold">{tab.setupTemplates}</h3>
        <p className="mb-2 text-xs text-text-secondary">
          {tab.setupTemplatesHint}
        </p>
        <div className="flex flex-col gap-2">
          {templatesForCategory(selected.category).map((tpl) => {
            const presented = presentSetupTemplate(tpl.id, lang, tpl);
            return (
            <button
              key={tpl.id}
              type="button"
              onClick={() => applySetupTemplate(selected.id, tpl.id, lang)}
              className="rounded-xl border border-border bg-surface-elevated p-3 text-left text-sm"
            >
              <div className="font-medium">{presented.label}</div>
              <div className="mt-1 text-[11px] text-warning">{presented.disclaimer}</div>
              <a
                href={tpl.sourceUrl}
                target="_blank"
                rel="noreferrer"
                className="mt-1 inline-block text-[11px] text-accent"
                onClick={(e) => e.stopPropagation()}
              >
                {tpl.sourceLabel}
              </a>
            </button>
            );
          })}
        </div>
      </section>
    </div>
  );
}
