/**
 * Product chrome stays in hofNav.ts (Flutter parity).
 * Ride HUD is not a tab. Shop is a gateway from Bike, not a fifth tab.
 * Touren holds saved rides, tips and groups — not a community feed.
 */

export const HOF_NAV = [
  { id: "hof", href: "/home", label: "Start" },
  { id: "karte", href: "/discover", label: "Karte" },
  { id: "platz", href: "/library", label: "Touren" },
  { id: "werkstatt", href: "/garage", label: "Garage" },
] as const;

export type HofNavId = (typeof HOF_NAV)[number]["id"];

function pathIs(pathname: string, href: string): boolean {
  return pathname === href || pathname.startsWith(`${href}/`);
}

/**
 * Which of the four doors owns this app route.
 * Satellite pages (Profil, Chat, Shop, …) keep a parent selected —
 * native pushes those screens over the shell, so a door stays lit.
 */
export function hofDoorForPath(pathname: string): HofNavId | null {
  if (
    pathIs(pathname, "/discover") ||
    pathIs(pathname, "/planner")
  ) {
    return "karte";
  }
  if (pathIs(pathname, "/library")) return "platz";
  if (
    pathIs(pathname, "/garage") ||
    pathIs(pathname, "/shop") ||
    pathIs(pathname, "/checkout")
  ) {
    return "werkstatt";
  }
  if (
    pathIs(pathname, "/home") ||
    pathIs(pathname, "/profile") ||
    pathIs(pathname, "/chat") ||
    pathIs(pathname, "/privacy") ||
    pathIs(pathname, "/activities") ||
    pathIs(pathname, "/post-ride")
  ) {
    return "hof";
  }
  return null;
}

export function isHofNavActive(pathname: string, href: string): boolean {
  const door = hofDoorForPath(pathname);
  if (href === "/home") return door === "hof";
  if (href === "/discover") return door === "karte";
  if (href === "/library") return door === "platz";
  if (href === "/garage") return door === "werkstatt";
  return pathIs(pathname, href);
}
