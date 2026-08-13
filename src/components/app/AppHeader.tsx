"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useMemo } from "react";
import { HOF_NAV, isHofNavActive } from "@/lib/nav/hofNav";
import { useHofTitle } from "@/hooks/useHofTitle";
import { HOF_COPY } from "@/lib/home/hofCopy";
import { getFleetMaintenanceDueCount } from "@/lib/maintenance/summary";
import { cn } from "@/lib/utils";
import { useAppStore } from "@/store/useAppStore";

export function AppHeader() {
  const pathname = usePathname();
  const hofTitle = useHofTitle();
  const bikes = useAppStore((s) => s.bikes);
  const intervals = useAppStore((s) => s.maintenanceIntervals);

  const dueTotal = useMemo(
    () => getFleetMaintenanceDueCount(bikes, intervals).dueTotal,
    [bikes, intervals]
  );

  return (
    <header className="hof-safe-header sticky top-0 z-50 border-b border-border bg-background/90 backdrop-blur">
      <div className="mx-auto flex h-14 items-center justify-between gap-3 px-4 lg:h-16 lg:px-6">
        <Link
          href="/home"
          className="text-lg font-bold tracking-tight text-foreground"
        >
          Aether<span className="text-chrome">Ride</span>
        </Link>

        <nav className="hidden items-center gap-1 md:flex" aria-label="Der Hof">
          {HOF_NAV.map((item) => {
            const isActive = isHofNavActive(pathname, item.href);
            const label = item.id === "hof" ? hofTitle : item.label;
            const showMaintBadge = item.id === "werkstatt" && dueTotal > 0;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  "relative rounded-lg px-3 py-2 text-sm font-semibold transition lg:px-4",
                  isActive
                    ? "text-chrome"
                    : "text-text-secondary hover:text-foreground"
                )}
              >
                {label}
                {isActive ? (
                  <span
                    className="absolute inset-x-3 -bottom-0.5 h-[1.5px] rounded-full bg-chrome lg:inset-x-4"
                    aria-hidden
                  />
                ) : null}
                {showMaintBadge && (
                  <span
                    className="absolute right-0.5 top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-error px-0.5 text-[9px] font-bold text-white"
                    aria-label={`${dueTotal} Wartungen fällig`}
                    data-testid="garage-nav-badge"
                  >
                    {dueTotal > 9 ? "9+" : dueTotal}
                  </span>
                )}
              </Link>
            );
          })}
        </nav>

        <Link
          href="/profile"
          className="text-sm font-medium text-text-secondary hover:text-chrome"
        >
          {HOF_COPY.profile}
        </Link>
      </div>
    </header>
  );
}
