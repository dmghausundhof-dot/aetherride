export function PartsSkeleton({ count = 6 }: { count?: number }) {
  return (
    <div
      className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3"
      aria-busy="true"
      aria-label="Ersatzteile werden geladen"
    >
      {Array.from({ length: count }).map((_, i) => (
        <div
          key={i}
          className="overflow-hidden rounded-2xl border border-border bg-surface"
        >
          <div className="aspect-[4/3] animate-pulse bg-surface-elevated" />
          <div className="space-y-2 p-4">
            <div className="h-3 w-16 animate-pulse rounded bg-surface-elevated" />
            <div className="h-4 w-3/4 animate-pulse rounded bg-surface-elevated" />
            <div className="h-5 w-20 animate-pulse rounded bg-surface-elevated" />
            <div className="mt-3 h-10 w-full animate-pulse rounded-xl bg-surface-elevated" />
          </div>
        </div>
      ))}
    </div>
  );
}
