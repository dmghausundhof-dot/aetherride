export function HofPageHeader({
  kicker,
  title,
  hint,
}: {
  kicker?: string;
  title: string;
  hint?: string;
}) {
  return (
    <div>
      {kicker ? (
        <p className="text-[11px] font-bold tracking-wide text-chrome">
          {kicker}
        </p>
      ) : null}
      <h1 className="mt-1 text-2xl font-extrabold tracking-tight lg:text-3xl">
        {title}
      </h1>
      {hint ? (
        <p className="mt-2 max-w-xl text-sm leading-relaxed text-text-secondary">
          {hint}
        </p>
      ) : null}
    </div>
  );
}
