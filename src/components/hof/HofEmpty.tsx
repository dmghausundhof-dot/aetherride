import Link from "next/link";
import { HOF_NAV } from "@/lib/nav/hofNav";
import { HOF_COPY } from "@/lib/home/hofCopy";

export function HofEmpty({
  title,
  hint,
  showDoors = false,
}: {
  title: string;
  hint?: string;
  showDoors?: boolean;
}) {
  return (
    <section className="rounded-2xl border border-dashed border-border bg-surface px-5 py-10 text-center">
      <EmptyStandMark />
      <h2 className="mt-4 text-lg font-extrabold">{title}</h2>
      {hint ? (
        <p className="mx-auto mt-2 max-w-md text-sm text-text-secondary">
          {hint}
        </p>
      ) : null}
      {showDoors ? (
        <nav
          className="mt-6 flex flex-wrap justify-center gap-2"
          aria-label="Vier Türen"
        >
          {HOF_NAV.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="rounded-full border border-border px-3 py-1.5 text-xs font-semibold text-text-secondary hover:border-chrome hover:text-chrome"
            >
              {item.label}
            </Link>
          ))}
        </nav>
      ) : null}
      <p className="sr-only">{HOF_COPY.emptyStand}</p>
    </section>
  );
}

function EmptyStandMark() {
  return (
    <svg
      width="120"
      height="48"
      viewBox="0 0 120 48"
      aria-hidden
      className="mx-auto text-text-secondary"
    >
      <line x1="20" y1="40" x2="100" y2="40" stroke="currentColor" strokeWidth="2" />
      <line x1="60" y1="40" x2="60" y2="12" stroke="currentColor" strokeWidth="2" />
      <line x1="48" y1="12" x2="72" y2="12" stroke="currentColor" strokeWidth="2" />
    </svg>
  );
}
