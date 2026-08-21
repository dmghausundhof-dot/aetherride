import { Home, Map, BookOpen, Store, type LucideIcon } from "lucide-react";
import { RadNavMark } from "@/components/garage/RadNavMark";

const MARKS: Array<LucideIcon | "rad"> = [Home, Map, BookOpen, "rad", Store];

/** Homepage / Produkt — Rad-Tür trägt die Stand-Marke, nicht den Schraubenschlüssel. */
export function DoorIcon({
  index,
  className = "h-5 w-5 text-sage",
}: {
  index: number;
  className?: string;
}) {
  const mark = MARKS[index] ?? Store;
  if (mark === "rad") return <RadNavMark className={className} />;
  const Icon = mark;
  return <Icon className={className} />;
}
