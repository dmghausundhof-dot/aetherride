import { ChromeGlyph, type ChromeMarkName } from "@/components/chrome/ChromeGlyph";
import { RadNavMark } from "@/components/garage/RadNavMark";

const DOORS: Array<ChromeMarkName | "rad"> = [
  "hof",
  "karte",
  "platz",
  "rad",
  "shop",
];

/** Homepage / Produkt — Rad-Tür trägt die Stand-Marke, nicht den Schraubenschlüssel. */
export function DoorIcon({
  index,
  className = "h-5 w-5 text-sage",
}: {
  index: number;
  className?: string;
}) {
  const mark = DOORS[index] ?? "shop";
  if (mark === "rad") return <RadNavMark className={className} />;
  return <ChromeGlyph name={mark} size={20} current className={className} />;
}
