/** UI chrome languages shipped in the Flutter ARB. APIs default to `de`. */
export type ChromeLang = "de" | "en" | "fr" | "it";

export function chromeLangFrom(raw?: string | null): ChromeLang {
  const s = (raw ?? "").trim().toLowerCase().replace("_", "-");
  if (s === "en" || s.startsWith("en-")) return "en";
  if (s === "fr" || s.startsWith("fr-")) return "fr";
  if (s === "it" || s.startsWith("it-")) return "it";
  return "de";
}

/** First matching chrome language in an Accept-Language header. Unknown tags skip. */
export function chromeLangFromAcceptLanguage(
  header?: string | null
): ChromeLang {
  if (!header?.trim()) return "de";
  const parts = header.split(",").map((p) => {
    const [tag, ...params] = p.trim().split(";");
    let q = 1;
    for (const param of params) {
      const m = param.trim().match(/^q=([0-9.]+)$/i);
      if (m) q = Number(m[1]);
    }
    return { tag: (tag ?? "").trim().toLowerCase().replace("_", "-"), q };
  });
  parts.sort((a, b) => b.q - a.q);
  for (const { tag } of parts) {
    if (!tag) continue;
    if (tag === "en" || tag.startsWith("en-")) return "en";
    if (tag === "fr" || tag.startsWith("fr-")) return "fr";
    if (tag === "it" || tag.startsWith("it-")) return "it";
    if (tag === "de" || tag.startsWith("de-")) return "de";
  }
  return "de";
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
    default:
      return "de-DE";
  }
}

export function valhallaLanguage(
  lang: ChromeLang
): "de-DE" | "en-US" | "fr-FR" | "it-IT" {
  switch (lang) {
    case "en":
      return "en-US";
    case "fr":
      return "fr-FR";
    case "it":
      return "it-IT";
    default:
      return "de-DE";
  }
}
