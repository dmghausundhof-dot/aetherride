"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, Map, Wrench, Store } from "lucide-react";
import { HOF_NAV, isHofNavActive } from "@/lib/nav/hofNav";
import { useHofTitle } from "@/hooks/useHofTitle";
import { cn } from "@/lib/utils";
import { getFleetMaintenanceDueCount } from "@/lib/maintenance/summary";
import { useAppStore } from "@/store/useAppStore";
import { useMemo } from "react";

const ICONS = {
  hof: Home,
  karte: Map,
  werkstatt: Wrench,
  shop: Store,
} as const;

/**
 * Schwelle zum Hof — Haarlinie, Mint aktiv, Orange bleibt Rausfahren.
 */
export function HofThresholdNav() {
  const pathname = usePathname();
  const hofTitle = useHofTitle();
  const bikes = useAppStore((s) => s.bikes);
  const intervals = useAppStore((s) => s.maintenanceIntervals);
  const dueTotal = useMemo(
    () => getFleetMaintenanceDueCount(bikes, intervals).dueTotal,
    [bikes, intervals]
  );

  return (
    <nav
      data-testid="hof-threshold-nav"
      className="hof-safe-tab fixed bottom-0 left-0 right-0 z-50 border-t border-border bg-background md:hidden"
      aria-label="Der Hof"
    >
      <div className="flex h-14 items-stretch">
        {HOF_NAV.map((item) => {
          const active = isHofNavActive(pathname, item.href);
          const Icon = ICONS[item.id];
          const label = item.id === "hof" ? hofTitle : item.label;
          const showDue = item.id === "werkstatt" && dueTotal > 0;
          return (
            <Link
              key={item.id}
              href={item.href}
              className={cn(
                "relative flex flex-1 flex-col items-center justify-center gap-0.5 text-[11px] font-semibold tracking-wide",
                active ? "text-chrome" : "text-text-secondary"
              )}
            >
              <span className="relative">
                <Icon className="h-[22px] w-[22px]" strokeWidth={active ? 2.4 : 1.8} />
                {showDue ? (
                  <span
                    className="absolute -right-2 -top-1 h-1.5 w-1.5 rounded-full bg-error"
                    aria-label={`${dueTotal} Wartungen fällig`}
                    data-testid="garage-tab-badge"
                  />
                ) : null}
              </span>
              <span
                className={cn(
                  "h-[1.5px] rounded-full transition-all",
                  active ? "w-3.5 bg-chrome" : "w-0 bg-transparent"
                )}
                aria-hidden
              />
              <span className="max-w-[4.8rem] truncate">{label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
