"use client";

/**
 * Legacy mobile bottom nav — nicht mehr in der Web-Shell verdrahtet.
 * Navigation läuft über AppHeader (Desktop + Mobile-Menü).
 * Ride gehört ausschließlich in die native App (/ride = App-CTA).
 *
 * Behalten für ggf. WebView-Experimente; Import nur bewusst.
 * Garage-Badge: Dot/Count bei fälliger Wartung (T-WA-00).
 */
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useMemo } from "react";
import { Home, Warehouse, Compass, ShoppingBag, Smartphone } from "lucide-react";
import { cn } from "@/lib/utils";
import { getFleetMaintenanceDueCount } from "@/lib/maintenance/summary";
import { useAppStore } from "@/store/useAppStore";
import { useCartStore } from "@/store/useCartStore";

/** Multi-Sport Labels (Parität zur Flutter-App). */
const tabs = [
  { id: "home", href: "/home", label: "Home", icon: Home },
  { id: "garage", href: "/garage", label: "Garage", icon: Warehouse },
  { id: "discover", href: "/discover", label: "Touren", icon: Compass },
  { id: "shop", href: "/shop", label: "Teile", icon: ShoppingBag },
  { id: "app", href: "/download", label: "App", icon: Smartphone },
];

export function BottomTabBar() {
  const pathname = usePathname();
  const cartCount = useCartStore((s) =>
    s.items.reduce((n, i) => n + i.quantity, 0)
  );
  const bikes = useAppStore((s) => s.bikes);
  const intervals = useAppStore((s) => s.maintenanceIntervals);
  const dueTotal = useMemo(
    () => getFleetMaintenanceDueCount(bikes, intervals).dueTotal,
    [bikes, intervals]
  );

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 border-t border-border bg-surface/95 backdrop-blur-md pb-[env(safe-area-inset-bottom)]">
      <div className="mx-auto flex max-w-lg items-end justify-around px-2 pt-2 pb-2">
        {tabs.map((tab) => {
          const isActive =
            tab.href === "/home"
              ? pathname === "/home" || pathname === "/"
              : pathname.startsWith(tab.href);
          const Icon = tab.icon;
          const showShopBadge = tab.id === "shop" && cartCount > 0;
          const showGarageBadge = tab.id === "garage" && dueTotal > 0;
          const badgeCount = showShopBadge
            ? cartCount
            : showGarageBadge
              ? dueTotal
              : 0;
          const showBadge = showShopBadge || showGarageBadge;

          return (
            <Link
              key={tab.id}
              href={tab.href}
              className={cn(
                "relative flex flex-1 flex-col items-center justify-center gap-0.5 py-1 touch-target transition-colors",
                isActive ? "text-accent" : "text-text-secondary hover:text-foreground"
              )}
            >
              <span className="relative">
                <Icon className={cn("h-6 w-6", isActive && "stroke-[2.5]")} />
                {showBadge && (
                  <span
                    className={cn(
                      "absolute -right-2 -top-1 flex h-4 min-w-4 items-center justify-center rounded-full px-0.5 text-[9px] font-bold text-white",
                      showGarageBadge ? "bg-error" : "bg-accent"
                    )}
                    data-testid={
                      showGarageBadge ? "garage-tab-badge" : undefined
                    }
                    aria-label={
                      showGarageBadge
                        ? `${dueTotal} Wartungen fällig`
                        : undefined
                    }
                  >
                    {badgeCount > 9 ? "9+" : badgeCount}
                  </span>
                )}
              </span>
              <span className="text-[11px] font-medium">{tab.label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
