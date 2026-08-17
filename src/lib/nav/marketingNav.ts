/**
 * Public website IA — not the four Hof doors.
 * Product chrome stays in hofNav.ts (Flutter parity).
 */

export const MARKETING_NAV = [
  { href: "/produkt", label: "Produkt" },
  { href: "/karten", label: "Karten" },
  { href: "/regions", label: "Regionen" },
  { href: "/guides", label: "Guides" },
  { href: "/community", label: "Community" },
  { href: "/pricing", label: "Preise" },
  { href: "/download", label: "App" },
] as const;

export type MarketingNavHref = (typeof MARKETING_NAV)[number]["href"];

export function isMarketingNavActive(pathname: string, href: string): boolean {
  return pathname === href || pathname.startsWith(`${href}/`);
}

/** First-run overlay must not block SEO, legal, share or auth. */
export function isPublicMarketingPath(pathname: string): boolean {
  if (pathname === "/" || pathname === "") return true;
  if (pathname === "/privacy" || pathname.startsWith("/privacy/")) return true;
  if (pathname === "/checkout" || pathname.startsWith("/checkout/")) return true;
  if (pathname === "/community" || pathname.startsWith("/community/")) {
    return !pathname.startsWith("/community/moderation");
  }
  const prefixes = [
    "/produkt",
    "/karten",
    "/anmelden",
    "/pricing",
    "/download",
    "/guides",
    "/regions",
    "/tours",
    "/legal",
    "/share",
    "/open",
    "/faq",
    "/ueber",
    "/kontakt",
  ];
  if (pathname === "/u" || pathname.startsWith("/u/")) return true;
  return prefixes.some((p) => pathname === p || pathname.startsWith(`${p}/`));
}

export function safeAppNextPath(raw: string | null | undefined): string {
  if (!raw) return "/home";
  if (!raw.startsWith("/") || raw.startsWith("//") || raw.includes("://")) {
    return "/home";
  }
  return raw;
}
