import { RAD_EMPTY_STAND_MARK, RAD_STAND_GROUND, RAD_STAND_HEADER } from "@/lib/garage/radMark";
import { cn } from "@/lib/utils";

/** Leerer Stand — dieselbe Bühne wie ein geparktes Rad, ohne Silhouette. */
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
        "relative overflow-hidden bg-[#121215]",
        heightClass,
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
        className="pointer-events-none absolute inset-x-0 bottom-0 h-16 bg-gradient-to-t from-[#E57532]/16 to-transparent"
      />
      <img
        src={RAD_EMPTY_STAND_MARK}
        alt=""
        width={240}
        height={140}
        className="relative mx-auto h-full w-auto max-w-[92%] object-contain"
        draggable={false}
      />
      <img
        src={RAD_STAND_HEADER}
        alt=""
        width={240}
        height={24}
        className="pointer-events-none absolute bottom-1 left-3 h-3.5 w-24"
        draggable={false}
      />
    </div>
  );
}
