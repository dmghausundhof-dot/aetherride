export type WeatherGlyphHint =
  | "dry_likely"
  | "damp_possible"
  | "wet_likely"
  | string
  | null
  | undefined;

export function weatherGlyphSrc(
  hint?: WeatherGlyphHint,
  offline = false
): string {
  if (offline) return "/weather/offline.svg";
  if (hint === "wet_likely") return "/weather/wet.svg";
  if (hint === "damp_possible") return "/weather/damp.svg";
  return "/weather/dry.svg";
}

export function WeatherGlyph({
  hint,
  offline = false,
  size = 16,
  className = "",
  alt = "",
}: {
  hint?: WeatherGlyphHint;
  offline?: boolean;
  size?: number;
  className?: string;
  alt?: string;
}) {
  return (
    <img
      src={weatherGlyphSrc(hint, offline)}
      alt={alt}
      width={size}
      height={size}
      className={className}
      draggable={false}
    />
  );
}
