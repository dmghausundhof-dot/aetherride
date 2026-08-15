import Link from "next/link";

export default function MarketingNotFound() {
  return (
    <div className="px-4 py-20 sm:px-6">
      <div className="mx-auto max-w-lg text-center">
        <p className="text-[11px] font-bold tracking-wide text-chrome">404</p>
        <h1 className="mt-2 text-3xl font-bold tracking-tight">
          Diese Seite gibt es nicht
        </h1>
        <p className="mt-3 text-sm text-text-secondary">
          Kein Feed, keine Füll-Route. Zurück zur Website oder zum Hof.
        </p>
        <div className="mt-8 flex flex-wrap justify-center gap-3">
          <Link
            href="/"
            className="inline-flex h-12 items-center rounded-xl bg-chrome px-6 text-sm font-semibold text-background"
          >
            Start
          </Link>
          <Link
            href="/regions"
            className="inline-flex h-12 items-center rounded-xl border border-border px-6 text-sm font-semibold"
          >
            Regionen
          </Link>
          <Link
            href="/faq"
            className="inline-flex h-12 items-center rounded-xl border border-border px-6 text-sm font-semibold"
          >
            FAQ
          </Link>
          <Link
            href="/home"
            className="inline-flex h-12 items-center rounded-xl border border-border px-6 text-sm font-semibold"
          >
            Zum Hof
          </Link>
        </div>
      </div>
    </div>
  );
}
