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
        d="M6 42 C18 36, 28 48, 40 42 C50 37, 56 44, 58 46"
        stroke="#FF6A00"
        strokeWidth="3.2"
        strokeLinecap="round"
        fill="none"
      />
      <path
        d="M8 50 C20 44, 30 54, 42 48 C52 43, 56 50, 58 52"
        stroke="#7A8B73"
        strokeWidth="2.4"
        strokeLinecap="round"
        fill="none"
      />
    </svg>
  );
}
