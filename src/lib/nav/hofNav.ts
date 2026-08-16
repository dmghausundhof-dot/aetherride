/**
 * Five destinations — same IA as Flutter HofThresholdNav.
 * Ride HUD is not a tab. Shop is a gateway page, not a rebuilt catalog.
 * Platz orchestrates Mappe/Stimmen — not a Community feed.
 */

export const HOF_NAV = [
  { id: "hof", href: "/home", label: "Der Hof" },
  { id: "karte", href: "/discover", label: "Karte" },
  { id: "platz", href: "/library", label: "Platz" },
  { id: "werkstatt", href: "/garage", label: "Werkstatt" },
  { id: "shop", href: "/shop", label: "Laden" },
] as const;

export type HofNavId = (typeof HOF_NAV)[number]["id"];

export function isHofNavActive(pathname: string, href: string): boolean {
  if (href === "/home") return pathname === "/home";
  return pathname === href || pathname.startsWith(`${href}/`);
}
