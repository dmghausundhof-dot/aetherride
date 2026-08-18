import type { ReactNode } from "react";

const HUD_POS = {
  "top-left": "absolute left-3 top-3 z-10",
  "top-right": "absolute right-3 top-14 z-10",
  "bottom-left": "absolute bottom-10 left-3 z-10",
  "bottom-right": "absolute bottom-10 right-3 z-10",
} as const;

/** Glas-Rahmen um MapLibre — Vignette, Status, Legende. */
export function MapFrame({
  children,
  className = "",
  tall = false,
}: {
  children: ReactNode;
  className?: string;
  tall?: boolean;
}) {
  return (
    <div
      className={`relative overflow-hidden bg-[#d7e0d4] ${
        tall ? "min-h-[360px] lg:min-h-[560px]" : "min-h-[280px] sm:min-h-[360px]"
      } ${className}`}
    >
      {children}
      <div className="pointer-events-none absolute inset-x-0 top-0 h-16 bg-gradient-to-b from-black/25 to-transparent" />
      <div className="pointer-events-none absolute inset-x-0 bottom-0 h-28 bg-gradient-to-t from-black/40 to-transparent" />
    </div>
  );
}

export function MapHud({
  children,
  className = "",
  position = "top-left",
}: {
  children: ReactNode;
  className?: string;
  position?: keyof typeof HUD_POS;
}) {
  return (
    <div
      className={`${HUD_POS[position]} max-w-[min(22rem,calc(100%-1.5rem))] ${className}`}
    >
      <div className="rounded-2xl border border-white/15 bg-[#121215]/80 px-3.5 py-2.5 text-[11px] text-white shadow-lg backdrop-blur-md">
        {children}
      </div>
    </div>
  );
}
