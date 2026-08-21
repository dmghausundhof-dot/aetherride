/** UI chrome languages shipped in the Flutter ARB. APIs default to `de`. */
export type ChromeLang = "de" | "en" | "fr" | "it" | "nl";

export const CHROME_LANGS: readonly ChromeLang[] = [
  "de",
  "en",
  "fr",
  "it",
  "nl",
];

/** Native names — chips stay in the language they name. */
export const CHROME_LANG_NATIVE: Record<ChromeLang, string> = {
  de: "Deutsch",
  en: "English",
  fr: "Français",
  it: "Italiano",
  nl: "Nederlands",
};

/** Cookie + localStorage. This browser only — the app has no locale field. */
export const CHROME_LANG_COOKIE = "aetherride.chromeLang";

export const CHROME_LANG_CHANGED = "aetherride-chrome-lang";

export function chromeLangFrom(raw?: string | null): ChromeLang {
  const s = (raw ?? "").trim().toLowerCase().replace("_", "-");
  if (s === "en" || s.startsWith("en-")) return "en";
  if (s === "fr" || s.startsWith("fr-")) return "fr";
  if (s === "it" || s.startsWith("it-")) return "it";
  if (s === "nl" || s.startsWith("nl-")) return "nl";
  return "de";
}

/** Exact chrome code, or null (device/auto). Unknown strings are not German. */
export function chromeLangOverrideFrom(
  raw?: string | null
): ChromeLang | null {
  const s = (raw ?? "").trim().toLowerCase();
  if ((CHROME_LANGS as readonly string[]).includes(s)) {
    return s as ChromeLang;
  }
  return null;
}

/** First matching chrome language in an Accept-Language header. Unknown tags skip. */
export function chromeLangFromAcceptLanguage(
  header?: string | null
): ChromeLang {
  if (!header?.trim()) return "de";
  const parts = header.split(",").map((p, i) => {
    const [tag, ...params] = p.trim().split(";");
    let q = 1;
    for (const param of params) {
      const m = param.trim().match(/^q=([0-9.]+)$/i);
      if (m) q = Number(m[1]);
    }
    return {
      tag: (tag ?? "").trim().toLowerCase().replace("_", "-"),
      q,
      i,
    };
  });
  parts.sort((a, b) => b.q - a.q || a.i - b.i);
  for (const { tag } of parts) {
    if (!tag) continue;
    if (tag === "en" || tag.startsWith("en-")) return "en";
    if (tag === "fr" || tag.startsWith("fr-")) return "fr";
    if (tag === "it" || tag.startsWith("it-")) return "it";
    if (tag === "nl" || tag.startsWith("nl-")) return "nl";
    if (tag === "de" || tag.startsWith("de-")) return "de";
  }
  return "de";
}

/** `navigator.languages` first, then `navigator.language`. */
export function chromeLangFromNavigator(
  nav?: { language?: string; languages?: readonly string[] } | null
): ChromeLang {
  if (!nav) return "de";
  if (nav.languages && nav.languages.length > 0) {
    return chromeLangFromAcceptLanguage(Array.from(nav.languages).join(","));
  }
  return chromeLangFrom(nav.language);
}

/**
 * Override (this browser) wins. Then the language list / Accept-Language.
 * Unknown tags skip, like `chromeLangFromAcceptLanguage`.
 */
export function resolveChromeLang(opts?: {
  override?: string | null;
  acceptLanguage?: string | null;
  languages?: readonly string[];
  language?: string | null;
}): ChromeLang {
  const over = chromeLangOverrideFrom(opts?.override);
  if (over) return over;
  if (opts?.languages && opts.languages.length > 0) {
    return chromeLangFromAcceptLanguage(opts.languages.join(","));
  }
  if (opts?.acceptLanguage) {
    return chromeLangFromAcceptLanguage(opts.acceptLanguage);
  }
  if (opts?.language) return chromeLangFrom(opts.language);
  return "de";
}

function readDocumentCookie(name: string): string | null {
  if (typeof document === "undefined") return null;
  const parts = document.cookie.split(";");
  for (const part of parts) {
    const trimmed = part.trim();
    const eq = trimmed.indexOf("=");
    if (eq < 0) continue;
    if (trimmed.slice(0, eq) !== name) continue;
    return decodeURIComponent(trimmed.slice(eq + 1));
  }
  return null;
}

export function readStoredChromeLangOverride(): ChromeLang | null {
  if (typeof window === "undefined") return null;
  try {
    const fromLs = chromeLangOverrideFrom(
      localStorage.getItem(CHROME_LANG_COOKIE)
    );
    if (fromLs) return fromLs;
  } catch {
    /* private mode */
  }
  return chromeLangOverrideFrom(readDocumentCookie(CHROME_LANG_COOKIE));
}

function writeChromeLangCookie(lang: ChromeLang | null): void {
  if (typeof document === "undefined") return;
  if (lang) {
    document.cookie = `${CHROME_LANG_COOKIE}=${lang}; Path=/; Max-Age=31536000; SameSite=Lax`;
    return;
  }
  document.cookie = `${CHROME_LANG_COOKIE}=; Path=/; Max-Age=0; SameSite=Lax`;
}

export function writeChromeLangOverride(lang: ChromeLang | null): void {
  try {
    if (typeof localStorage !== "undefined") {
      if (lang) localStorage.setItem(CHROME_LANG_COOKIE, lang);
      else localStorage.removeItem(CHROME_LANG_COOKIE);
    }
  } catch {
    /* private mode */
  }
  writeChromeLangCookie(lang);
  if (typeof window !== "undefined") {
    window.dispatchEvent(new Event(CHROME_LANG_CHANGED));
  }
}

export function resolvedChromeLang(): ChromeLang {
  const override = readStoredChromeLangOverride();
  if (typeof navigator === "undefined") {
    return resolveChromeLang({ override });
  }
  return resolveChromeLang({
    override,
    languages: navigator.languages,
    language: navigator.language,
  });
}

export function applyDocumentLang(lang: ChromeLang): void {
  if (typeof document === "undefined") return;
  document.documentElement.lang = lang;
}

export function chromeOgLocale(lang: ChromeLang): string {
  switch (lang) {
    case "en":
      return "en_US";
    case "fr":
      return "fr_FR";
    case "it":
      return "it_IT";
    case "nl":
      return "nl_NL";
    default:
      return "de_DE";
  }
}

/** BCP 47 tag for dates in chrome UI. Catalog names stay German. */
export function chromeDateLocale(lang: ChromeLang): string {
  switch (lang) {
    case "en":
      return "en-GB";
    case "fr":
      return "fr-FR";
    case "it":
      return "it-IT";
    case "nl":
      return "nl-NL";
    default:
      return "de-DE";
  }
}

export function valhallaLanguage(
  lang: ChromeLang
): "de-DE" | "en-US" | "fr-FR" | "it-IT" | "nl-NL" {
  switch (lang) {
    case "en":
      return "en-US";
    case "fr":
      return "fr-FR";
    case "it":
      return "it-IT";
    case "nl":
      return "nl-NL";
    default:
      return "de-DE";
  }
}
