import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatDistance(meters: number): string {
  if (meters < 1000) return `${Math.round(meters)} m`;
  return `${(meters / 1000).toFixed(1)} km`;
}

export function formatDuration(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  if (h > 0) return `${h}:${m.toString().padStart(2, "0")}:${s.toString().padStart(2, "0")}`;
  return `${m}:${s.toString().padStart(2, "0")}`;
}

export function bikeTypeLabel(type: string): string {
  const map: Record<string, string> = {
    all_mountain: "All-Mountain",
    enduro: "Enduro",
    gravel: "Gravel",
    road: "Rennrad",
    e_mtb: "E-MTB",
    e_gravel: "E-Gravel",
    hiking: "Wandern",
  };
  return map[type] || type;
}

export function categoryLabel(cat: string): string {
  const map: Record<string, string> = {
    fork: "Gabel",
    shock: "Dämpfer",
    tire_front: "Reifen vorne",
    tire_rear: "Reifen hinten",
    wheelset: "Laufräder",
    drivetrain: "Antrieb",
    brakes: "Bremsen",
    cockpit: "Cockpit",
    saddle: "Sattel",
    motor: "Motor",
    battery: "Akku",
    display: "Display",
    other: "Sonstiges",
  };
  return map[cat] || cat;
}
