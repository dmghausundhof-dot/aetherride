"use client";

import { usePathname } from "next/navigation";
import { AppHeader } from "./AppHeader";

const APP_PREFIXES = [
  "/garage",
  "/discover",
  "/shop",
  "/profile",
  "/post-ride",
  "/ride",
  "/checkout",
  "/chat",
];

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const isAppRoute = APP_PREFIXES.some(
    (p) => pathname === p || pathname.startsWith(p + "/")
  );

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
