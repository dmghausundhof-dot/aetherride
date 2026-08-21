import { RadNavMark } from "@/components/garage/RadNavMark";
import { RAD_STAND_GROUND, RAD_STAND_HEADER } from "@/lib/garage/radMark";
import { cn } from "@/lib/utils";

/** Leeres Shop-Foto — Stand-Boden, Marke, Schiene. */
export function ShopImageFallback({
  label,
  markClassName = "h-7 w-7",
  className,
}: {
  label?: string;
  markClassName?: string;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "relative flex h-full w-full flex-col items-center justify-center gap-1.5 overflow-hidden bg-[#121215] text-text-secondary",
        className
      )}
    >
      <img
        src={RAD_STAND_GROUND}
        alt=""
        className="absolute inset-0 h-full w-full object-cover"
        draggable={false}
      />
      <div
        aria-hidden
        className="pointer-events-none absolute inset-x-0 bottom-0 h-12 bg-gradient-to-t from-[#E57532]/16 to-transparent"
      />
      <RadNavMark
        className={cn("relative z-[1] shrink-0 text-[#818C7B]", markClassName)}
      />
      {label ? (
        <span className="relative z-[1] text-center text-[11px] leading-tight">
          {label}
        </span>
      ) : null}
      <img
        src={RAD_STAND_HEADER}
        alt=""
        width={240}
        height={24}
        className="pointer-events-none absolute bottom-1 left-2 h-2.5 w-16"
        draggable={false}
      />
    </div>
  );
}
