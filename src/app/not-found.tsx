import Link from "next/link";
import { HOF_COPY } from "@/lib/home/hofCopy";
import { HofEmpty } from "@/components/hof/HofEmpty";
import { MARKETING_NAV } from "@/lib/nav/marketingNav";

export default function NotFound() {
  return (
    <div className="hof-safe-page mx-auto flex min-h-dvh max-w-lg flex-col justify-center px-5 py-16">
      <HofEmpty
        title={HOF_COPY.notFoundTitle}
        hint={HOF_COPY.notFoundHint}
        showDoors
      />
      <div className="mt-6 flex flex-col gap-3">
        <Link
          href="/home"
          className="inline-flex h-12 items-center justify-center rounded-xl bg-chrome text-sm font-semibold text-background"
        >
          Zum Hof
        </Link>
        <Link
          href="/"
          className="inline-flex h-12 items-center justify-center rounded-xl border border-border text-sm font-semibold"
        >
          Zur Website
        </Link>
      </div>
      <nav
        className="mt-6 flex flex-wrap justify-center gap-3 text-xs font-semibold text-chrome"
        aria-label="Website"
      >
        {MARKETING_NAV.slice(0, 4).map((item) => (
          <Link key={item.href} href={item.href} className="hover:underline">
            {item.label}
          </Link>
        ))}
        <Link href="/faq" className="hover:underline">
          FAQ
        </Link>
      </nav>
    </div>
  );
}
