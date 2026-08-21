"use client";

import Link from "next/link";
import { HOF_NAV } from "@/lib/nav/hofNav";
import { useHofTitle } from "@/hooks/useHofTitle";
import { useChromeLang } from "@/hooks/useChromeLang";
import { webChrome } from "@/lib/i18n/webChrome";
import { RadEmptyStage } from "@/components/garage/RadEmptyStage";

export function HofEmpty({
  title,
  hint,
  showDoors = false,
}: {
  title: string;
  hint?: string;
  showDoors?: boolean;
}) {
  const hofTitle = useHofTitle();
  const copy = webChrome(useChromeLang());

  return (
    <section className="overflow-hidden rounded-2xl border border-dashed border-border bg-surface px-5 pb-10 pt-4 text-center">
      <div className="-mx-5 -mt-4 overflow-hidden">
        <RadEmptyStage heightClass="h-36" />
      </div>
      <h2 className="mt-4 text-lg font-extrabold">{title}</h2>
      {hint ? (
        <p className="mx-auto mt-2 max-w-md text-sm text-text-secondary">
          {hint}
        </p>
      ) : null}
      {showDoors ? (
        <nav
          className="mt-6 flex flex-wrap justify-center gap-2"
          aria-label={copy.fourDoors}
        >
          {HOF_NAV.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="rounded-full border border-border px-3 py-1.5 text-xs font-semibold text-text-secondary hover:border-chrome hover:text-chrome"
            >
              {item.id === "hof" ? hofTitle : copy.hofNav[item.id]}
            </Link>
          ))}
        </nav>
      ) : null}
      <p className="sr-only">{copy.emptyStand}</p>
    </section>
  );
}
