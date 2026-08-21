"use client";

import {
  createContext,
  useCallback,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import {
  applyDocumentLang,
  CHROME_LANG_CHANGED,
  readStoredChromeLangOverride,
  resolveChromeLang,
  writeChromeLangOverride,
  type ChromeLang,
} from "@/lib/i18n/chromeLang";

export type ChromeLangPreference = {
  lang: ChromeLang;
  override: ChromeLang | null;
  setOverride: (lang: ChromeLang | null) => void;
};

export const ChromeLangContext = createContext<ChromeLangPreference>({
  lang: "de",
  override: null,
  setOverride: () => undefined,
});

export function ChromeLangProvider({
  initialLang,
  initialOverride = null,
  children,
}: {
  initialLang: ChromeLang;
  initialOverride?: ChromeLang | null;
  children: ReactNode;
}) {
  const [lang, setLang] = useState<ChromeLang>(initialLang);
  const [override, setOverrideState] = useState<ChromeLang | null>(
    initialOverride
  );

  const applyResolved = useCallback(() => {
    const nextOverride = readStoredChromeLangOverride();
    const next = resolveChromeLang({
      override: nextOverride,
      languages:
        typeof navigator !== "undefined" ? navigator.languages : undefined,
      language:
        typeof navigator !== "undefined" ? navigator.language : undefined,
    });
    setOverrideState(nextOverride);
    setLang(next);
    applyDocumentLang(next);
  }, []);

  useEffect(() => {
    applyResolved();
    window.addEventListener(CHROME_LANG_CHANGED, applyResolved);
    window.addEventListener("storage", applyResolved);
    return () => {
      window.removeEventListener(CHROME_LANG_CHANGED, applyResolved);
      window.removeEventListener("storage", applyResolved);
    };
  }, [applyResolved]);

  const setOverride = useCallback((next: ChromeLang | null) => {
    writeChromeLangOverride(next);
    const resolved = resolveChromeLang({
      override: next,
      languages: navigator.languages,
      language: navigator.language,
    });
    setOverrideState(next);
    setLang(resolved);
    applyDocumentLang(resolved);
  }, []);

  const value = useMemo(
    () => ({ lang, override, setOverride }),
    [lang, override, setOverride]
  );

  return (
    <ChromeLangContext.Provider value={value}>
      {children}
    </ChromeLangContext.Provider>
  );
}
