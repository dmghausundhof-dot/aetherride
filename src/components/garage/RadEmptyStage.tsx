import { RAD_EMPTY_STAND } from "@/lib/garage/radMark";
import { cn } from "@/lib/utils";

/** Leerer Stand — die ausgelieferte Stand-Illustration, eine Datei. */
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
        src={RAD_EMPTY_STAND}
        alt=""
        width={240}
        height={140}
        className="h-full w-full object-cover"
        draggable={false}
      />
    </div>
  );
}
