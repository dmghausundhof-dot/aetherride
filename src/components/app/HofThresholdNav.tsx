"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, Map, BookOpen } from "lucide-react";
import { RadNavMark } from "@/components/garage/RadNavMark";
import { HOF_NAV, isHofNavActive } from "@/lib/nav/hofNav";
import { useHofTitle } from "@/hooks/useHofTitle";
import { useChromeLang } from "@/hooks/useChromeLang";
import { webChrome } from "@/lib/i18n/webChrome";
import { cn } from "@/lib/utils";
import { getFleetMaintenanceDueCount } from "@/lib/maintenance/summary";
import { stimmenTourIdOf } from "@/lib/tours/routeVisibility";
import { useAppStore } from "@/store/useAppStore";
import { useCommunityStore } from "@/store/useCommunityStore";
import { useRideGroupStore } from "@/store/useRideGroupStore";
import { useMemo } from "react";

const ICONS = {
  hof: Home,
  karte: Map,
  platz: BookOpen,
} as const;

function HofTabMark({
  id,
  active,
}: {
  id: (typeof HOF_NAV)[number]["id"];
  active: boolean;
}) {
  if (id === "werkstatt") return <RadNavMark active={active} />;
  const Icon = ICONS[id];
  return (
    <Icon
      className="h-[22px] w-[22px]"
      strokeWidth={active ? 1.5 : 1.8}
      fill={active ? "currentColor" : "none"}
      aria-hidden
    />
  );
}

/**
 * Schwelle zum Hof — Haarlinie, Orange aktiv.
 * Lucide für Hof/Karte/Touren; Rad bekommt die Stand-Marke.
 */
export function HofThresholdNav() {
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
    <nav
      data-testid="hof-threshold-nav"
      className="hof-safe-tab fixed bottom-0 left-0 right-0 z-50 border-t border-border bg-background md:hidden"
      aria-label={hofTitle}
    >
      <div className="flex h-14 items-stretch">
        {HOF_NAV.map((item, i) => {
          const active = isHofNavActive(pathname, item.href);
          const label = item.id === "hof" ? hofTitle : copy.hofNav[item.id];
          const showDue = item.id === "werkstatt" && dueTotal > 0;
          const showPlatz = item.id === "platz" && platzUnseen;
          const tabOf = copy.tabOf(i + 1, HOF_NAV.length);
          return (
            <Link
              key={item.id}
              href={item.href}
              aria-current={active ? "page" : undefined}
              aria-label={`${label}, ${tabOf}`}
              className={cn(
                "relative flex flex-1 flex-col items-center justify-center gap-0.5 text-[11px] tracking-wide",
                active
                  ? "font-bold text-chrome"
                  : "font-semibold text-text-secondary"
              )}
            >
              <span className="relative">
                <HofTabMark id={item.id} active={active} />
                {showDue ? (
                  <span
                    className="absolute -right-2 -top-1 h-1.5 w-1.5 rounded-full bg-error"
                    aria-label={copy.maintenanceDue(dueTotal)}
                    data-testid="garage-tab-badge"
                  />
                ) : null}
                {showPlatz ? (
                  <span
                    className="absolute -right-2 -top-1 h-1.5 w-1.5 rounded-full bg-error"
                    aria-label={copy.newStimmenPlatz}
                    data-testid="platz-tab-badge"
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
