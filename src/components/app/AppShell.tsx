"use client";

import { usePathname } from "next/navigation";
import { AppHeader } from "./AppHeader";
import { HofThresholdNav } from "./HofThresholdNav";

/** App-Bereiche mit Hof-Chrome (kein Ride-Tab). */
const APP_PREFIXES = [
  "/home",
  "/garage",
  "/discover",
  "/planner",
  "/library",
  "/activities",
  "/shop",
  "/profile",
  "/post-ride",
  "/checkout",
  "/chat",
  "/privacy",
];

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const isAppRoute = APP_PREFIXES.some(
    (p) => pathname === p || pathname.startsWith(p + "/")
  );

  // /ride ist bewusst ohne App-Chrome — eigenständige App-CTA-Seite
  if (pathname === "/ride" || pathname.startsWith("/ride/")) {
    return <>{children}</>;
  }

  if (!isAppRoute) {
    return <>{children}</>;
  }

  return (
    <div className="flex min-h-screen flex-col bg-background">
      {/* md+: Top-Nav. Mobile: kein AppBar — wie Native Hof, nur Tabs. */}
      <AppHeader />
      <main className="flex-1 pb-[var(--hof-tab-h)] pt-[var(--safe-top)] md:pb-0 md:pt-0">
        {children}
      </main>
      <HofThresholdNav />
    </div>
  );
}
