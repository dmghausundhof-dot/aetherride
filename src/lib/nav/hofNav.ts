/**
 * Product chrome stays in hofNav.ts (Flutter parity).
 * Ride HUD is not a tab. Shop is a gateway from Bike, not a fifth tab.
 * Touren holds saved rides, tips and groups — not a community feed.
 */

export const HOF_NAV = [
  { id: "hof", href: "/home", label: "Start" },
  { id: "karte", href: "/discover", label: "Karte" },
  { id: "platz", href: "/library", label: "Touren" },
  { id: "werkstatt", href: "/garage", label: "Rad" },
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
