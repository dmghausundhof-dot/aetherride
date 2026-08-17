/**
 * Four destinations — same IA as Flutter HofThresholdNav.
 * Ride HUD is not a tab. Shop is a gateway from the workshop, not a fifth tab.
 * Platz orchestrates Mappe/Stimmen — not a Community feed.
 */

export const HOF_NAV = [
  { id: "hof", href: "/home", label: "Der Hof" },
  { id: "karte", href: "/discover", label: "Karte" },
  { id: "platz", href: "/library", label: "Platz" },
  { id: "werkstatt", href: "/garage", label: "Werkstatt" },
] as const;

export type HofNavId = (typeof HOF_NAV)[number]["id"];

export function isHofNavActive(pathname: string, href: string): boolean {
  if (href === "/home") return pathname === "/home";
  if (href === "/garage") {
    return (
      pathname === "/garage" ||
      pathname.startsWith("/garage/") ||
      pathname === "/shop" ||
      pathname.startsWith("/shop/")
    );
  }
  return pathname === href || pathname.startsWith(`${href}/`);
}
