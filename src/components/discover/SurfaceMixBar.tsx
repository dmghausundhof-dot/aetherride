import { surfaceMixShares } from "@/lib/routing/elevationProfile";
import { osmSurfaceLabel } from "@/lib/routing/osmSurfaceLabel";

const TONE: Record<string, string> = {
  asphalt: "bg-[#5C6B73]",
  paved: "bg-[#5C6B73]",
  concrete: "bg-[#5C6B73]",
  gravel: "bg-[#C4A574]",
  compacted: "bg-[#C4A574]",
  fine_gravel: "bg-[#C4A574]",
  unpaved: "bg-[#7A8B73]",
  ground: "bg-[#7A8B73]",
  dirt: "bg-[#7A8B73]",
  earth: "bg-[#7A8B73]",
  path: "bg-[#7A8B73]",
  trail: "bg-[#7A8B73]",
};

function tone(key: string): string {
  return TONE[key] ?? "bg-chrome/70";
}

export function SurfaceMixBar({
  bands,
  asphalt = "Asphalt",
  gravel = "Schotter",
  trail = "Naturboden",
  labelOf,
}: {
  bands: { fromKm: number; toKm: number; surface: string | null }[];
  asphalt?: string;
  gravel?: string;
  trail?: string;
  labelOf?: (key: string) => string;
}) {
  const mix = surfaceMixShares(bands);
  if (mix.length === 0) return null;
  const name = (key: string) =>
    labelOf?.(key) ??
    osmSurfaceLabel(key, { asphalt, gravel, trail });
  return (
    <div className="flex flex-col gap-1">
      <div className="flex h-2 overflow-hidden rounded-full bg-border">
        {mix.map((s) => (
          <div
            key={s.key}
            className={`${tone(s.key)} h-full`}
            style={{ width: `${Math.max(2, s.share * 100)}%` }}
            title={`${name(s.key)} · ${(s.share * 100).toFixed(0)}%`}
          />
        ))}
      </div>
      <p className="text-[10px] text-text-secondary">
        {mix
          .slice(0, 3)
          .map((s) => `${name(s.key)} ${Math.round(s.share * 100)}%`)
          .join(" · ")}
      </p>
    </div>
  );
}
