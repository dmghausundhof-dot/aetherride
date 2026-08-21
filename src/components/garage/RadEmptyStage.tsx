import { cn } from "@/lib/utils";

/** Leerer Stand — gestricheltes Rad, ohne kaputtes Bild. */
export function RadEmptyStage({
  heightClass = "h-36",
  className,
}: {
  heightClass?: string;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "relative flex items-center justify-center overflow-hidden bg-[#121215]",
        heightClass,
        className
      )}
    >
      <svg
        viewBox="0 0 240 140"
        width="240"
        height="140"
        className="h-full w-auto max-w-[92%]"
        aria-hidden
      >
        <g fill="none" stroke="#7A8B73" strokeWidth="2.2" strokeLinecap="round">
          <path d="M48 74 V108" />
          <path d="M192 74 V108" />
          <path d="M48 76 H192" />
        </g>
        <circle cx="48" cy="74" r="3.2" fill="#E57532" />
        <circle cx="192" cy="74" r="3.2" fill="#E57532" />
        <g
          fill="none"
          stroke="#FF6A00"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeDasharray="4 5"
        >
          <circle cx="86" cy="84" r="17" />
          <circle cx="154" cy="84" r="17" />
          <path d="M86 84 L108 54 L138 54 L154 84" />
          <path d="M108 54 L120 84" />
          <path d="M138 54 L120 84" />
          <path d="M108 54 L100 42 H90" />
        </g>
      </svg>
    </div>
  );
}
