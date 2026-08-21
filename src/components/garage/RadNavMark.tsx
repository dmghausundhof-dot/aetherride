/** Tab-Marke für Rad — dieselbe Silhouette wie glyph-stand, currentColor. */
export function RadNavMark({
  active = false,
  className = "h-[22px] w-[22px]",
}: {
  active?: boolean;
  className?: string;
}) {
  return (
    <svg
      viewBox="0 0 24 24"
      className={className}
      fill={active ? "currentColor" : "none"}
      stroke="currentColor"
      strokeWidth={active ? 1.5 : 1.8}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
    >
      <circle cx="7.4" cy="16.2" r="3.4" />
      <circle cx="16.6" cy="16.2" r="3.4" />
      <path d="M7.4 16.2 L10.6 9.2 L15.2 9.2 L16.6 16.2" />
      <path d="M10.6 9.2 L12.2 16.2" />
      <path d="M10.6 9.2 L9.6 6.6 H7.8" />
    </svg>
  );
}
