import type { Bike, BikeCategory, ComponentSlot, MaintenanceInterval } from "@/types/garage";

/**
 * Intervalle aus Hersteller-/Werkstattquellen (Recherche 2026-08).
 * Defaults sind konservativ („prüfen lassen“), nicht „jetzt tauschen“.
 *
 * Kette: Park Tool 0,5 % bei 11s+ — km nur Prüf-Default.
 * https://www.parktool.com/en-int/blog/repair-help/when-to-replace-a-chain-on-a-bicycle
 * Fahrwerk: RockShox Lower 50 h / Full 200 h; Fox 125 h oder 1 Jahr; Öhlins 100 h/Jahr.
 * https://support.rockshox.com/hc/en-us/articles/4412306753947-How-often-should-I-service-my-RockShox-product
 * https://www.ridefoxaustralia.com.au/pages/service-intervals
 * E-Bike: Bosch Erstcheck ~300 km / 4 Wochen, Brose ≥1×/Jahr.
 * https://www.bosch-ebike.com/en/service/dealer-service
 */

export type RideDiscipline = "mtb" | "gravel" | "road" | "city";

export function rideDisciplineOf(category: BikeCategory): RideDiscipline {
  if (
    category === "mtb_trail" ||
    category === "mtb_am" ||
    category === "mtb_enduro" ||
    category === "dh" ||
    category === "emtb"
  ) {
    return "mtb";
  }
  if (category === "gravel") return "gravel";
  if (category === "road") return "road";
  return "city";
}

export interface IntervalTemplate {
  slot: ComponentSlot;
  label: string;
  intervalKm?: number;
  intervalHours?: number;
  intervalDays?: number;
  sourceLabel: string;
  sourceUrl?: string;
  sourceSpan?: string;
  bikeWide?: boolean;
}

function isEbike(bike: Pick<Bike, "category" | "isEbike">): boolean {
  return bike.isEbike || bike.category === "emtb" || bike.category === "etrekking";
}

export function chainCheckKm(bike: Pick<Bike, "category" | "isEbike">): number {
  const e = isEbike(bike);
  const d = rideDisciplineOf(bike.category);
  if (d === "mtb") return e ? 700 : 1000;
  if (d === "road") return 1500;
  return e ? 1000 : 1200;
}

export function intervalTemplatesFor(
  bike: Pick<Bike, "category" | "isEbike">
): IntervalTemplate[] {
  const e = isEbike(bike);
  const d = rideDisciplineOf(bike.category);
  const mtb = d === "mtb";
  const dropper = mtb || d === "gravel";
  const padFront = mtb ? (e ? 800 : 1000) : d === "road" ? 3000 : 2000;
  const tireKm = mtb ? 1500 : d === "gravel" ? 3000 : d === "road" ? 4000 : 5000;
  const cassetteKm = mtb ? 4000 : d === "road" ? 8000 : 6000;
  const bearingKm = mtb ? 4000 : 5000;

  const list: IntervalTemplate[] = [
    {
      slot: "frame",
      label: e ? "Jährliche E-Bike-Inspektion" : "Jährliche Inspektion",
      intervalDays: 365,
      intervalKm: e ? 1500 : undefined,
      bikeWide: true,
      sourceLabel: e
        ? "Bosch / Brose / Shimano STEPS — jährlich"
        : "Werkstatt-Schnitt 12 Monate",
      sourceUrl: "https://www.bosch-ebike.com/en/service/dealer-service",
    },
    {
      slot: "chain",
      label: "Kettenverschleiß prüfen",
      intervalKm: chainCheckKm(bike),
      bikeWide: true,
      sourceLabel: "Park Tool 0,5 % Dehnung (11s+)",
      sourceUrl:
        "https://www.parktool.com/en-int/blog/repair-help/when-to-replace-a-chain-on-a-bicycle",
    },
    {
      slot: "cassette",
      label: "Kassette prüfen (nach 2–3 Ketten)",
      intervalKm: cassetteKm,
      bikeWide: true,
      sourceLabel: "Park Tool / 2–3 Ketten",
    },
    {
      slot: "brake_pads_front",
      label: "Bremsbeläge vorne prüfen",
      intervalKm: padFront,
      bikeWide: true,
      sourceLabel: "WatchMy.bike / Industriepraxis",
      sourceUrl: "https://watchmy.bike/blog/brake-pads-when-to-replace",
    },
    {
      slot: "brake_pads_rear",
      label: "Bremsbeläge hinten prüfen",
      intervalKm: Math.round(padFront * 0.8),
      bikeWide: true,
      sourceLabel: "WatchMy.bike / Industriepraxis",
    },
    {
      slot: "tire_rear",
      label: "Reifen prüfen",
      intervalKm: tireKm,
      bikeWide: true,
      sourceLabel: "Schwalbe Laufleistung",
      sourceUrl: "https://www.schwalbe.com/en/technology-faq/tire-wear/",
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
      slot: "headset",
      label: "Lager prüfen (Steuersatz/Naben/Tretlager)",
      intervalKm: bearingKm,
      intervalDays: 365,
      bikeWide: true,
      sourceLabel: "Bike Gremlin / L'Atelier 6–12 Monate",
      sourceUrl:
        "https://bike.bikegremlin.com/19342/bicycle-maintenance-service-intervals/",
    },
    {
      slot: "brake_front",
      label: "Bremsen: Druckpunkt / Entlüften",
      intervalDays: 365,
      sourceLabel: "SRAM DOT ≥1×/Jahr; Magura nur bei Schwamm",
      sourceUrl:
        "https://support.sram.com/hc/en-us/articles/5927419450651-How-often-should-I-bleed-my-SRAM-DOT-brakes",
    },
  ];

  if (e) {
    list.push({
      slot: "battery",
      label: "Akku-Check (Kontakte, Kapazität)",
      intervalDays: 365,
      bikeWide: true,
      sourceLabel: "Bosch / Shimano STEPS jährlich",
    });
  }

  if (mtb) {
    list.push(
      {
        slot: "fork",
        label: "Gabel Lower-Leg Service",
        intervalHours: 50,
        sourceLabel: "RockShox / Öhlins 50 h",
        sourceUrl:
          "https://support.rockshox.com/hc/en-us/articles/4412306753947-How-often-should-I-service-my-RockShox-product",
      },
      {
        slot: "fork",
        label: "Gabel Vollservice (Feder/Dämpfer)",
        intervalHours: 125,
        intervalDays: 365,
        sourceLabel: "Fox 125 h / 1 Jahr (konservativ)",
        sourceUrl: "https://www.ridefoxaustralia.com.au/pages/service-intervals",
        sourceSpan: "RockShox Full 200 h · Öhlins 100 h/Jahr",
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
        intervalHours: 125,
        intervalDays: 365,
        sourceLabel: "Fox 125 h / 1 Jahr (konservativ)",
        sourceUrl: "https://www.ridefoxaustralia.com.au/pages/service-intervals",
      }
    );
  }

  if (dropper) {
    list.push({
      slot: "seatpost",
      label: "Dropper Lower-Post Service",
      intervalHours: 50,
      sourceLabel: "RockShox Reverb 50 h",
      sourceUrl:
        "https://support.rockshox.com/hc/en-us/articles/4412306753947-How-often-should-I-service-my-RockShox-product",
    });
  }

  return list;
}

/** MTB-Defaults — Abwärtskompatibilität. */
export const DEFAULT_INTERVAL_TEMPLATES: IntervalTemplate[] =
  intervalTemplatesFor({ category: "mtb_am", isEbike: false });

export function buildDefaultIntervals(
  bike: Bike,
  idFactory: () => string
): MaintenanceInterval[] {
  const installedSlots = new Set(
    bike.components.filter((c) => !c.removedAt).map((c) => c.slot)
  );
  return intervalTemplatesFor(bike)
    .filter((t) => t.bikeWide || installedSlots.has(t.slot))
    .map((t) => {
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
        lastDoneAt: comp?.installedAt ?? bike.purchasedAt ?? bike.createdAt,
        lastDoneOdometerKm: comp?.odometerKmAtInstall ?? 0,
        lastDoneHours: comp?.hoursAtInstall ?? 0,
        sourceLabel: t.sourceLabel,
        sourceUrl: t.sourceUrl,
        overriddenByUser: false,
      };
    });
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
  let remainingDays = 9999;

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
    remainingDays = Math.round(interval.intervalDays - usedDays);
    remainders.push(
      `${Math.max(0, Math.round(interval.intervalDays - usedDays))} Tage`
    );
  }

  if (ratios.length === 0) {
    return { status: "ok", progressPct: 0, remainingLabel: "Kein Intervall" };
  }

  const progressPct = Math.min(100, Math.round(Math.max(...ratios) * 100));
  const status: DueStatus =
    progressPct >= 100
      ? "overdue"
      : progressPct >= 90 || remainingDays <= 30
        ? "due_soon"
        : "ok";

  return {
    status,
    progressPct,
    remainingLabel: remainders.join(" · "),
  };
}
