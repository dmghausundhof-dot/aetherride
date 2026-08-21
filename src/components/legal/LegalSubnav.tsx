"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { LEGAL_NAV } from "@/lib/legal/legalNav";

export function LegalSubnav() {
  const pathname = usePathname();
  return (
    <nav
      aria-label="Rechtliches"
      className="mt-4 flex flex-wrap gap-2 border-b border-border pb-4"
    >
      {LEGAL_NAV.map((item) => {
        const active = pathname === item.href;
        return (
          <Link
            key={item.href}
            href={item.href}
            aria-current={active ? "page" : undefined}
            className={
              active
                ? "rounded-full bg-chrome px-3 py-1 text-xs font-semibold text-on-accent"
                : "rounded-full border border-border px-3 py-1 text-xs font-medium text-text-secondary hover:border-chrome/40 hover:text-foreground"
            }
          >
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}
