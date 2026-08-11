"use client";

/**
 * Legacy mobile bottom nav — nicht mehr in der Web-Shell verdrahtet.
 * Navigation läuft über AppHeader (Desktop + Mobile-Menü).
 * Ride gehört ausschließlich in die native App (/ride = App-CTA).
 *
 * Behalten für ggf. WebView-Experimente; Import nur bewusst.
 */
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, Warehouse, Compass, ShoppingBag, Smartphone } from "lucide-react";
import { cn } from "@/lib/utils";
import { useCartStore } from "@/store/useCartStore";

/** Multi-Sport Labels (Parität zur Flutter-App). */
const tabs = [
  { id: "home", href: "/", label: "Home", icon: Home },
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

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 border-t border-border bg-surface/95 backdrop-blur-md pb-[env(safe-area-inset-bottom)]">
      <div className="mx-auto flex max-w-lg items-end justify-around px-2 pt-2 pb-2">
        {tabs.map((tab) => {
          const isActive =
            tab.href === "/"
              ? pathname === "/"
              : pathname.startsWith(tab.href);
          const Icon = tab.icon;
          const showBadge = tab.id === "shop" && cartCount > 0;

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
                  <span className="absolute -right-2 -top-1 flex h-4 min-w-4 items-center justify-center rounded-full bg-accent px-0.5 text-[9px] font-bold text-white">
                    {cartCount > 9 ? "9+" : cartCount}
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
