type FlowLineWordmarkProps = {
  className?: string;
  markClassName?: string;
  showMark?: boolean;
  /** Official mark is charcoal on light; on dark Hof chrome use the light fill. */
  onDark?: boolean;
};

/** Flow + orange Line, optional official mountain/wave mark. */
export function FlowLineWordmark({
  className = "text-lg font-bold tracking-tight text-foreground",
  markClassName = "h-6 w-auto",
  showMark = true,
  onDark = true,
}: FlowLineWordmarkProps) {
  return (
    <span className={`inline-flex items-center gap-2 ${className}`}>
      {showMark ? (
        <FlowLineMark className={markClassName} onDark={onDark} />
      ) : null}
      <span>
        Flow<span className="text-accent">Line</span>
      </span>
    </span>
  );
}

export function FlowLineMark({
  className = "h-6 w-auto",
  onDark = true,
}: {
  className?: string;
  onDark?: boolean;
}) {
  return (
    // eslint-disable-next-line @next/next/no-img-element -- official vector from Logo und Bilder
    <img
      src={onDark ? "/brand/logo-mark-on-dark.svg" : "/brand/logo-mark.svg"}
      alt=""
      aria-hidden
      className={className}
    />
  );
}
