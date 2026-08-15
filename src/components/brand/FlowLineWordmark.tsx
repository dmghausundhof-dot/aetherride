type FlowLineWordmarkProps = {
  className?: string;
  markClassName?: string;
  showMark?: boolean;
};

/** Flow + orange Line, optional mountain/wave mark. */
export function FlowLineWordmark({
  className = "text-lg font-bold tracking-tight text-foreground",
  markClassName = "h-6 w-6",
  showMark = true,
}: FlowLineWordmarkProps) {
  return (
    <span className={`inline-flex items-center gap-2 ${className}`}>
      {showMark ? <FlowLineMark className={markClassName} /> : null}
      <span>
        Flow<span className="text-accent">Line</span>
      </span>
    </span>
  );
}

export function FlowLineMark({ className = "h-6 w-6" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 64 64"
      className={className}
      aria-hidden
      fill="none"
    >
      <path
        d="M8 34 L22 14 L32 26 L44 12 L56 34"
        stroke="currentColor"
        strokeWidth="3.2"
        strokeLinejoin="round"
        strokeLinecap="round"
      />
      <path
        d="M6 40 C18 34, 28 46, 40 40 C50 35, 56 42, 58 44"
        stroke="#FF6A00"
        strokeWidth="3.2"
        strokeLinecap="round"
        fill="none"
      />
      <path
        d="M8 47 C20 41, 30 51, 42 45 C52 40, 56 47, 58 49"
        stroke="#7A8B73"
        strokeWidth="2.6"
        strokeLinecap="round"
        fill="none"
      />
      <path
        d="M10 54 C22 50, 32 56, 44 52 C52 49, 56 54, 58 55"
        stroke="#9CA3AF"
        strokeWidth="2"
        strokeLinecap="round"
        fill="none"
      />
    </svg>
  );
}
