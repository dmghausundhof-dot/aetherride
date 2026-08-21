"use client";

import { Languages } from "lucide-react";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLangPreference } from "@/hooks/useChromeLang";
import {
  CHROME_LANGS,
  CHROME_LANG_NATIVE,
} from "@/lib/i18n/chromeLang";

export function ChromeLangPicker() {
  const copy = useHofCopy();
  const { override, setOverride } = useChromeLangPreference();
  const auto = override == null;

  return (
    <section className="rounded-2xl border border-border bg-surface p-4">
      <h3 className="mb-2 flex items-center gap-2 font-semibold">
        <Languages className="h-4 w-4 text-chrome" /> {copy.profileLanguage}
      </h3>
      <p className="mb-3 text-xs text-text-secondary">
        {copy.profileLanguageHint}
      </p>
      <div className="flex flex-wrap gap-2">
        <button
          type="button"
          onClick={() => setOverride(null)}
          className={chipClass(auto)}
        >
          {copy.profileLanguageAuto}
        </button>
        {CHROME_LANGS.map((code) => (
          <button
            key={code}
            type="button"
            lang={code}
            onClick={() => setOverride(code)}
            className={chipClass(!auto && override === code)}
          >
            {CHROME_LANG_NATIVE[code]}
          </button>
        ))}
      </div>
    </section>
  );
}

function chipClass(selected: boolean): string {
  return `rounded-full border px-3 py-1.5 text-sm font-semibold ${
    selected
      ? "border-chrome bg-chrome/15 text-chrome"
      : "border-border bg-surface-elevated text-text-secondary"
  }`;
}
