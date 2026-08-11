"use client";

import { usePathname } from "next/navigation";
import { AppHeader } from "./AppHeader";

/** App-Bereiche mit Desktop-Top-Nav (kein Ride-Tab, kein Mobile-Bottom-Nav). */
const APP_PREFIXES = [
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
  "/share",
  "/u",
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
      <AppHeader />
      <main className="flex-1">{children}</main>
    </div>
  );
}
