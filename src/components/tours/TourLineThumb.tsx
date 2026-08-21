"use client";

import { fitTourLine, TOUR_LINE_SIZE } from "@/lib/tours/tourLine";
import { MappeGlyph } from "@/components/tours/MappeGlyph";

export function TourLineThumb({
  coordinates,
  label,
  noTrackLabel,
  size = 80,
  wide = false,
}: {
  coordinates: ReadonlyArray<ArrayLike<number>>;
  label: string;
  noTrackLabel: string;
  size?: number;
  /** Full-width strip (Akte). Square thumb is the default list mark. */
  wide?: boolean;
}) {
  const fit = fitTourLine(
    coordinates,
    wide ? 128 : TOUR_LINE_SIZE,
    wide ? 64 : TOUR_LINE_SIZE,
    wide ? 10 : 8,
  );
  const w = wide ? size * 2.2 : size;
  const h = wide ? Math.round(size * 0.72) : size;
  const boxStyle = wide
    ? { width: "100%" as const, height: h }
    : { width: w, height: h };

  if (!fit) {
    return (
      <div
        className={`relative overflow-hidden rounded-2xl bg-background ${wide ? "" : "shrink-0"}`}
        style={boxStyle}
        aria-label={noTrackLabel}
      >
        <img
          src="/tours/no-track.svg"
          alt=""
          width={w}
          height={h}
          className="h-full w-full object-cover"
          draggable={false}
        />
      </div>
    );
  }

  const vb = wide ? "0 0 128 64" : "0 0 64 64";
  return (
    <div
      className={`relative overflow-hidden rounded-2xl bg-background ${wide ? "" : "shrink-0"}`}
      style={boxStyle}
      aria-label={label}
    >
      <img
        src="/tours/thumb-ground.svg"
        alt=""
        className="absolute inset-0 h-full w-full object-cover"
        draggable={false}
      />
      <svg
        viewBox={vb}
        className="relative h-full w-full"
        aria-hidden
      >
        <path
          d={fit.d}
          fill="none"
          stroke="#7A8B73"
          strokeWidth={wide ? 5.2 : 5}
          strokeLinecap="round"
          strokeLinejoin="round"
          opacity="0.38"
        />
        <path
          d={fit.d}
          fill="none"
          stroke="#FF6A00"
          strokeWidth={wide ? 2.8 : 2.5}
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <circle cx={fit.start.x} cy={fit.start.y} r={wide ? 4.2 : 3.6} fill="#FF6A00" />
        <circle cx={fit.start.x} cy={fit.start.y} r={wide ? 1.8 : 1.5} fill="#F4F1EC" />
        {fit.loop ? null : (
          <>
            <circle cx={fit.end.x} cy={fit.end.y} r={wide ? 3.2 : 2.8} fill="#F2F2F2" />
            <circle cx={fit.end.x} cy={fit.end.y} r={wide ? 1.4 : 1.2} fill="#121215" />
          </>
        )}
      </svg>
      {fit.loop ? (
        <span
          className={`absolute bottom-1 rounded-full bg-background/80 p-0.5 ${wide ? "left-1" : "right-1"}`}
        >
          <MappeGlyph name="loop" size={12} />
        </span>
      ) : null}
    </div>
  );
}

/** Bis zu drei echte Spuren, leicht versetzt — kein erfundenes Bild. */
export function MappeTrackStack({
  tracks,
  label,
  noTrackLabel,
  size = 56,
  extraCount = 0,
}: {
  tracks: ReadonlyArray<ReadonlyArray<ArrayLike<number>>>;
  label: string;
  noTrackLabel: string;
  size?: number;
  extraCount?: number;
}) {
  const real = tracks.filter((t) => t.length >= 2).slice(0, 3);
  if (real.length === 0) return null;
  if (real.length === 1 && extraCount <= 0) {
    return (
      <TourLineThumb
        coordinates={real[0]!}
        label={label}
        noTrackLabel={noTrackLabel}
        size={size}
        wide
      />
    );
  }
  const offset = 5;
  const h = Math.round(size * 0.72);
  const extra = (real.length - 1) * offset;
  return (
    <div className="relative" style={{ height: h + extra }}>
      {real.map((_, rev) => {
        const i = real.length - 1 - rev;
        const coords = real[i]!;
        return (
        <div
          key={i}
          className="absolute overflow-hidden"
          style={{
            left: i * offset,
            right: (real.length - 1 - i) * offset,
            top: i * offset,
            height: h,
            opacity: i === 0 ? 1 : 0.62,
          }}
        >
          <TourLineThumb
            coordinates={coords}
            label={label}
            noTrackLabel={noTrackLabel}
            size={size}
            wide
          />
        </div>
        );
      })}
      {extraCount > 0 ? (
        <span className="absolute bottom-1.5 right-2 rounded-full bg-background/85 px-1.5 py-0.5 text-[10px] font-semibold tabular-nums">
          +{extraCount}
        </span>
      ) : null}
    </div>
  );
}
