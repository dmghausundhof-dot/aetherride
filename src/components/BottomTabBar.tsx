"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, Warehouse, Bike, Compass, ShoppingBag } from "lucide-react";
import { cn } from "@/lib/utils";
import { useCartStore } from "@/store/useCartStore";

const tabs = [
  { id: "home", href: "/", label: "Home", icon: Home },
  { id: "garage", href: "/garage", label: "Garage", icon: Warehouse },
  { id: "ride", href: "/ride", label: "Ride", icon: Bike, highlight: true },
  { id: "discover", href: "/discover", label: "Discover", icon: Compass },
  { id: "shop", href: "/shop", label: "Shop", icon: ShoppingBag },
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

          if (tab.highlight) {
            return (
              <Link
                key={tab.id}
                href={tab.href}
                className={cn(
                  "relative -mt-5 flex h-16 w-16 flex-col items-center justify-center rounded-full shadow-lg transition-all",
                  isActive
                    ? "bg-accent text-white scale-105"
                    : "bg-primary text-white hover:bg-primary/90"
                )}
              >
                <Icon className="h-7 w-7" strokeWidth={2.2} />
                <span className="mt-0.5 text-[10px] font-semibold">{tab.label}</span>
              </Link>
            );
          }

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
