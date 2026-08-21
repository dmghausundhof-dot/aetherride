"use client";

import { mapPinSvg, routePinSrc } from "@/lib/map/mapPinSvg";

/** Same start / finish / via mark as the map markers. */
export function PlanPinMark({
  kind,
  label,
}: {
  kind: "start" | "finish" | "via";
  label?: string;
}) {
  const color = kind === "start" ? "#2E7D32" : "#FF6A00";
  const src = routePinSrc(kind, color);
  const svg = mapPinSvg(kind, color);
  return (
    <span className="relative grid h-7 w-7 shrink-0 place-items-center">
      {src ? (
        <img
          src={src}
          alt=""
          width={kind === "via" ? 28 : 22}
          height={28}
          className="pointer-events-none object-contain"
          draggable={false}
        />
      ) : (
        <span
          className="pointer-events-none grid place-items-center [&>svg]:block"
          dangerouslySetInnerHTML={{ __html: svg }}
        />
      )}
      {kind === "via" && label ? (
        <span className="pointer-events-none absolute text-[10px] font-extrabold leading-none text-[#1F1F1F]">
          {label}
        </span>
      ) : null}
    </span>
  );
}
