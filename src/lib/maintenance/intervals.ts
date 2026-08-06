import type { Bike, ComponentSlot, MaintenanceInterval } from "@/types/garage";

/**
 * Default-Wartungsintervalle aus Hersteller-/Industriepraxis:
 * - RockShox: Lower Leg 50 h, Full 100–200 h
 * - Fox: vergleichbare Stundenintervalle
 * - Kette: Verschleißprüfung ~1000 km / Wechsel ~0,5 % Dehnung
 * - Tubeless-Milch: 90–180 Tage
 * Quellen: RockShox FAQ, WatchMy.bike Lifespan Chart, Dirt Mountainbike
 */

export interface IntervalTemplate {
  slot: ComponentSlot;
  label: string;
  intervalKm?: number;
  intervalHours?: number;
  intervalDays?: number;
  sourceLabel: string;
  sourceUrl?: string;
}

export const DEFAULT_INTERVAL_TEMPLATES: IntervalTemplate[] = [
  {
    slot: "fork",
    label: "Gabel Lower-Leg Service",
    intervalHours: 50,
    sourceLabel: "RockShox Service FAQ",
    sourceUrl:
      "https://support.rockshox.com/hc/en-us/articles/4412306753947-How-often-should-I-service-my-RockShox-product",
  },
  {
    slot: "fork",
    label: "Gabel Vollservice (Feder/Dämpfer)",
    intervalHours: 200,
    sourceLabel: "RockShox / Fox Service Docs",
    sourceUrl: "https://www.sram.com/en/rockshox",
  },
  {
    slot: "rear_shock",
    label: "Dämpfer Air-Can Service",
    intervalHours: 50,
    sourceLabel: "RockShox Service FAQ",
    sourceUrl:
      "https://support.rockshox.com/hc/en-us/articles/4412306753947-How-often-should-I-service-my-RockShox-product",
  },
  {
    slot: "rear_shock",
    label: "Dämpfer Vollservice",
    intervalHours: 200,
    sourceLabel: "RockShox Deluxe/Super Deluxe",
    sourceUrl: "https://www.sram.com/en/rockshox",
  },
  {
    slot: "chain",
    label: "Kettenverschleiß prüfen",
    intervalKm: 1000,
    sourceLabel: "Park Tool / Industriepraxis 0,5 % Dehnung",
    sourceUrl: "https://watchmy.bike/blog/how-long-do-bike-parts-last",
  },
  {
    slot: "cassette",
    label: "Kassette prüfen (nach 2–3 Ketten)",
    intervalKm: 6000,
    sourceLabel: "Zero Friction / WatchMy.bike",
    sourceUrl: "https://watchmy.bike/blog/how-long-do-bike-parts-last",
  },
  {
    slot: "brake_pads_front",
    label: "Bremsbeläge vorne prüfen",
    intervalKm: 1500,
    sourceLabel: "Industriepraxis (verschleißabhängig)",
  },
  {
    slot: "brake_pads_rear",
    label: "Bremsbeläge hinten prüfen",
    intervalKm: 1200,
    sourceLabel: "Industriepraxis (verschleißabhängig)",
  },
  {
    slot: "tire_front",
    label: "Tubeless-Milch erneuern",
    intervalDays: 120,
    sourceLabel: "Tubeless-Praxis 3–6 Monate",
  },
  {
    slot: "tire_rear",
    label: "Tubeless-Milch erneuern",
    intervalDays: 120,
    sourceLabel: "Tubeless-Praxis 3–6 Monate",
  },
  {
    slot: "seatpost",
    label: "Dropper Lower-Post Service",
    intervalHours: 50,
    sourceLabel: "RockShox Reverb Interval",
    sourceUrl:
      "https://support.rockshox.com/hc/en-us/articles/4412306753947-How-often-should-I-service-my-RockShox-product",
  },
];

export function buildDefaultIntervals(
  bike: Bike,
  idFactory: () => string
): MaintenanceInterval[] {
  const installedSlots = new Set(
    bike.components.filter((c) => !c.removedAt).map((c) => c.slot)
  );
  return DEFAULT_INTERVAL_TEMPLATES.filter((t) => installedSlots.has(t.slot)).map(
    (t) => {
      const comp = bike.components.find((c) => c.slot === t.slot && !c.removedAt);
      return {
        id: idFactory(),
        bikeId: bike.id,
        slot: t.slot,
        bikeComponentId: comp?.id,
        label: t.label,
        intervalKm: t.intervalKm,
        intervalHours: t.intervalHours,
        intervalDays: t.intervalDays,
        lastDoneAt: comp?.installedAt,
        lastDoneOdometerKm: comp?.odometerKmAtInstall ?? 0,
        lastDoneHours: comp?.hoursAtInstall ?? 0,
        sourceLabel: t.sourceLabel,
        sourceUrl: t.sourceUrl,
        overriddenByUser: false,
      };
    }
  );
}

export type DueStatus = "ok" | "due_soon" | "overdue";

export interface DueInfo {
  status: DueStatus;
  progressPct: number;
  remainingLabel: string;
}

export function evaluateIntervalDue(
  interval: MaintenanceInterval,
  bikeOdometerKm: number,
  bikeHours: number,
  now = new Date()
): DueInfo {
  const ratios: number[] = [];
  const remainders: string[] = [];

  if (interval.intervalKm && interval.lastDoneOdometerKm !== undefined) {
    const used = bikeOdometerKm - interval.lastDoneOdometerKm;
    const ratio = used / interval.intervalKm;
    ratios.push(ratio);
    remainders.push(
      `${Math.max(0, Math.round(interval.intervalKm - used))} km`
    );
  }
  if (interval.intervalHours && interval.lastDoneHours !== undefined) {
    const used = bikeHours - interval.lastDoneHours;
    const ratio = used / interval.intervalHours;
    ratios.push(ratio);
    remainders.push(
      `${Math.max(0, Math.round(interval.intervalHours - used))} h`
    );
  }
  if (interval.intervalDays && interval.lastDoneAt) {
    const usedDays =
      (now.getTime() - new Date(interval.lastDoneAt).getTime()) /
      (1000 * 60 * 60 * 24);
    const ratio = usedDays / interval.intervalDays;
    ratios.push(ratio);
    remainders.push(
      `${Math.max(0, Math.round(interval.intervalDays - usedDays))} Tage`
    );
  }

  if (ratios.length === 0) {
    return { status: "ok", progressPct: 0, remainingLabel: "Kein Intervall" };
  }

  const progressPct = Math.min(100, Math.round(Math.max(...ratios) * 100));
  const status: DueStatus =
    progressPct >= 100 ? "overdue" : progressPct >= 80 ? "due_soon" : "ok";

  return {
    status,
    progressPct,
    remainingLabel: remainders.join(" · "),
  };
}
