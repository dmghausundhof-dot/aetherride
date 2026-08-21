"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useMemo } from "react";
import { FlowLineWordmark } from "@/components/brand/FlowLineWordmark";
import { HofCornerTools } from "@/components/app/HofCornerTools";
import { HOF_NAV, isHofNavActive } from "@/lib/nav/hofNav";
import { useHofTitle } from "@/hooks/useHofTitle";
import { useChromeLang } from "@/hooks/useChromeLang";
import { webChrome } from "@/lib/i18n/webChrome";
import { getFleetMaintenanceDueCount } from "@/lib/maintenance/summary";
import { stimmenTourIdOf } from "@/lib/tours/routeVisibility";
import { cn } from "@/lib/utils";
import { useAppStore } from "@/store/useAppStore";
import { useCommunityStore } from "@/store/useCommunityStore";
import { useRideGroupStore } from "@/store/useRideGroupStore";

export function AppHeader() {
  const pathname = usePathname();
  const hofTitle = useHofTitle();
  const copy = webChrome(useChromeLang());
  const bikes = useAppStore((s) => s.bikes);
  const intervals = useAppStore((s) => s.maintenanceIntervals);
  const savedRoutes = useAppStore((s) => s.savedRoutes);
  const myReviews = useCommunityStore((s) => s.myReviews);
  const inboxSeen = useRideGroupStore((s) => s.inboxSeen);

  const dueTotal = useMemo(
    () => getFleetMaintenanceDueCount(bikes, intervals).dueTotal,
    [bikes, intervals]
  );
  const platzUnseen = useMemo(() => {
    const inbox = myReviews.filter((r) =>
      savedRoutes.some((s) => stimmenTourIdOf(s) === r.tourId)
    );
    const listing = savedRoutes.filter(
      (s) => s.listing === "candidate" || s.listing === "reverted"
    ).length;
    return inbox.length + listing > inboxSeen;
  }, [myReviews, savedRoutes, inboxSeen]);

  return (
    <header className="hof-safe-header sticky top-0 z-50 hidden border-b border-border bg-background/90 backdrop-blur md:block">
      <div className="mx-auto flex h-14 items-center justify-between gap-3 px-4 lg:h-16 lg:px-6">
        <Link
          href="/home"
          className="text-lg font-bold tracking-tight text-foreground"
        >
          <FlowLineWordmark className="text-lg font-bold tracking-tight text-foreground" markClassName="h-6 w-auto" />
        </Link>

        <nav className="hidden items-center gap-1 md:flex" aria-label={hofTitle}>
          {HOF_NAV.map((item) => {
            const isActive = isHofNavActive(pathname, item.href);
            const label = item.id === "hof" ? hofTitle : copy.hofNav[item.id];
            const showMaintBadge = item.id === "werkstatt" && dueTotal > 0;
            const showPlatzBadge = item.id === "platz" && platzUnseen;
            return (
              <Link
                key={item.href}
                href={item.href}
                aria-current={isActive ? "page" : undefined}
                className={cn(
                  "relative rounded-lg px-3 py-2 text-sm transition lg:px-4",
                  isActive
                    ? "font-bold text-chrome"
                    : "font-semibold text-text-secondary hover:text-foreground"
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
                    className="absolute right-0.5 top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-error px-0.5 text-[9px] font-bold text-foreground"
                    aria-label={copy.maintenanceDue(dueTotal)}
                    data-testid="garage-nav-badge"
                  >
                    {dueTotal > 9 ? "9+" : dueTotal}
                  </span>
                )}
                {showPlatzBadge && (
                  <span
                    className="absolute right-0.5 top-0.5 h-1.5 w-1.5 rounded-full bg-error"
                    aria-label={copy.newStimmenPlatz}
                    data-testid="platz-nav-badge"
                  />
                )}
              </Link>
            );
          })}
        </nav>

        <HofCornerTools includeTestIds={false} />
      </div>
    </header>
  );
}
