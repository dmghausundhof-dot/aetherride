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

type IntervalBike = Pick<Bike, "category" | "isEbike"> & {
  components?: Pick<
    Bike["components"][number],
    "slot" | "manufacturer" | "componentModelId" | "freeText" | "model"
  >[];
};

function installedBlob(
  bike: IntervalBike,
  slots?: ComponentSlot[]
): string {
  return (bike.components ?? [])
    .filter((c) => !slots || slots.includes(c.slot))
    .map(
      (c) =>
        `${c.manufacturer ?? ""} ${c.model ?? ""} ${c.componentModelId ?? ""} ${c.freeText ?? ""}`
    )
    .join(" ")
    .toLowerCase();
}

export function chainCheckKm(bike: IntervalBike): number {
  const e = isEbike(bike);
  if (bike.category === "dh") return 600;
  if (bike.category === "cargo") return 600;
  if (bike.category === "kids") return 800;
  const d = rideDisciplineOf(bike.category);
  if (d === "mtb") return e ? 700 : 1000;
  if (d === "road") return 1500;
  return e ? 1000 : 1200;
}

function motorOem(
  bike: IntervalBike
): "bosch" | "shimano" | "brose" | "yamaha" | "fazua" | "tq" | "mahle" | "dji" | "panasonic" | "unknown" {
  const b = installedBlob(bike, ["motor"]);
  if (!b.trim()) return "unknown";
  if (/bosch/.test(b)) return "bosch";
  if (/shimano|steps|ep801|ep800|ep600|\bep6\b|e6100/.test(b)) return "shimano";
  if (/brose|specialized-2-2|full power 2|turbo full power/.test(b)) return "brose";
  if (/yamaha|syncdrive/.test(b)) return "yamaha";
  if (/fazua/.test(b)) return "fazua";
  if (/\btq\b|hpr50|hpr60/.test(b)) return "tq";
  if (/mahle/.test(b)) return "mahle";
  if (/dji|avinox/.test(b)) return "dji";
  if (/panasonic/.test(b)) return "panasonic";
  return "unknown";
}

export function intervalTemplatesFor(bike: IntervalBike): IntervalTemplate[] {
  const e = isEbike(bike);
  const d = rideDisciplineOf(bike.category);
  const mtb = d === "mtb";
  const cargo = bike.category === "cargo";
  const kids = bike.category === "kids";
  const dh = bike.category === "dh";
  const forkBlob = installedBlob(bike, ["fork"]);
  const chainBlob = installedBlob(bike, ["chain"]);
  const brakeBlob = installedBlob(bike, ["brake_front", "brake_rear"]);
  const postBlob = installedBlob(bike, ["seatpost"]);
  const belt = /gates|riemen|belt|cdx/.test(chainBlob);
  const magura = /magura|royal.?blood/.test(brakeBlob);
  const foxFork = /\bfox\b/.test(forkBlob);
  const rockshoxFork = /rockshox|rock shox/.test(forkBlob);
  const ohlinsFork = /öhlins|ohlins/.test(forkBlob);
  const suntourFork = /suntour/.test(forkBlob);
  const dropper =
    mtb ||
    d === "gravel" ||
    cargo ||
    /dropper|reverb|transfer|manic|oneup|pnw|bikeyoke|loam/.test(postBlob);
  const wantsForkService =
    mtb ||
    foxFork ||
    rockshoxFork ||
    ohlinsFork ||
    suntourFork ||
    /marzocchi|manitou/.test(forkBlob);

  const padFront = dh
    ? 400
    : cargo
      ? 500
      : kids
        ? 1200
        : mtb
          ? e
            ? 800
            : 1000
          : d === "road"
            ? 3000
            : 2000;
  const tireKm = dh
    ? 800
    : cargo
      ? 2000
      : kids
        ? 2000
        : mtb
          ? 1500
          : d === "gravel"
            ? 3000
            : d === "road"
              ? 4000
              : 5000;
  const cassetteKm = belt ? 8000 : mtb ? 4000 : d === "road" ? 8000 : 6000;
  const bearingKm = cargo || mtb ? 4000 : 5000;
  const forkFullH = ohlinsFork
    ? 100
    : foxFork
      ? 125
      : rockshoxFork
        ? 200
        : suntourFork
          ? 100
          : 125;
  const forkLowerH = dh ? 40 : 50;

  const oem = motorOem(bike);
  const annualSource =
    oem === "bosch"
      ? "Bosch Händler — jährlich"
      : oem === "shimano"
        ? "Shimano STEPS Händler — jährlich"
        : oem === "brose"
          ? "Brose — mindestens 1×/Jahr"
          : oem === "yamaha"
            ? "Yamaha / Giant SyncDrive — jährlich"
            : oem === "fazua"
              ? "Fazua — jährlich"
              : oem === "tq"
                ? "TQ — 1000 km / 1 Jahr"
                : oem === "mahle"
                  ? "Mahle SmartBike — jährlich"
                  : oem === "dji"
                    ? "DJI Avinox — jährlich"
                    : oem === "panasonic"
                      ? "Panasonic GX — jährlich"
                      : e
                        ? "E-Bike Händler — jährlich"
                        : "Werkstatt-Schnitt 12 Monate";

  const list: IntervalTemplate[] = [
    {
      slot: "frame",
      label: e ? "Jährliche E-Bike-Inspektion" : "Jährliche Inspektion",
      intervalDays: 365,
      intervalKm: e ? (cargo ? 1000 : oem === "tq" ? 1000 : 1500) : undefined,
      bikeWide: true,
      sourceLabel: annualSource,
      sourceUrl:
        oem === "shimano"
          ? "https://bike.shimano.com/"
          : "https://www.bosch-ebike.com/en/service/dealer-service",
      sourceSpan:
        oem === "bosch" || oem === "unknown"
          ? "Bosch Erstcheck 300 km/4 Wochen, danach Händler"
          : oem === "brose"
            ? "Brose ≥1×/Jahr, kein Bosch-300-km-Takt"
            : undefined,
    },
  ];

  if (e && (oem === "bosch" || oem === "unknown")) {
    list.unshift({
      slot: "frame",
      label: "Erste E-Bike-Inspektion",
      intervalKm: 300,
      intervalDays: 28,
      bikeWide: true,
      sourceLabel: "Bosch Erstcheck ~300 km / 4 Wochen",
      sourceUrl: "https://www.bosch-ebike.com/en/service/dealer-service",
    });
  } else if (e && oem === "shimano") {
    list.unshift({
      slot: "frame",
      label: "Erste STEPS-Inspektion",
      intervalKm: 500,
      intervalDays: 90,
      bikeWide: true,
      sourceLabel: "Shimano STEPS Händler ~500 km / 90 Tage",
      sourceUrl: "https://bike.shimano.com/",
    });
  }

  if (belt) {
    list.push({
      slot: "chain",
      label: "Riemen prüfen (Risse, Spannung)",
      intervalKm: 5000,
      intervalDays: 365,
      bikeWide: true,
      sourceLabel: "Gates CDX — prüfen, nicht dehnen",
      sourceUrl: "https://www.gatescarbondrive.com/",
    });
  } else {
    list.push({
      slot: "chain",
      label: "Kettenverschleiß prüfen",
      intervalKm: chainCheckKm(bike),
      bikeWide: true,
      sourceLabel: "Park Tool 0,5 % Dehnung (11s+)",
      sourceUrl:
        "https://www.parktool.com/en-int/blog/repair-help/when-to-replace-a-chain-on-a-bicycle",
    });
  }

  list.push(
    {
      slot: "cassette",
      label: belt
        ? "Riemenscheibe / Nabe prüfen"
        : "Kassette prüfen (nach 2–3 Ketten)",
      intervalKm: cassetteKm,
      bikeWide: true,
      sourceLabel: belt ? "Gates / Enviolo" : "Park Tool / 2–3 Ketten",
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
      intervalDays: kids || bike.category === "folding" ? 180 : 120,
      sourceLabel: "Tubeless-Praxis 3–6 Monate",
    },
    {
      slot: "tire_rear",
      label: "Tubeless-Milch erneuern",
      intervalDays: kids || bike.category === "folding" ? 180 : 120,
      sourceLabel: "Tubeless-Praxis 3–6 Monate",
    },
    {
      slot: "headset",
      label: "Lager prüfen (Steuersatz/Naben/Tretlager)",
      intervalKm: bearingKm,
      intervalDays: bike.category === "folding" ? 180 : 365,
      bikeWide: true,
      sourceLabel: "Bike Gremlin / L'Atelier 6–12 Monate",
      sourceUrl:
        "https://bike.bikegremlin.com/19342/bicycle-maintenance-service-intervals/",
    },
    {
      slot: "brake_front",
      label: magura
        ? "Bremsen: Druckpunkt prüfen (Mineralöl)"
        : "Bremsen: Druckpunkt / Entlüften",
      intervalDays: magura ? 730 : 365,
      sourceLabel: magura
        ? "Magura Royal Blood — nur bei Schwamm"
        : "SRAM DOT ≥1×/Jahr; Magura nur bei Schwamm",
      sourceUrl: magura
        ? "https://www.magura.com/"
        : "https://support.sram.com/hc/en-us/articles/5927419450651-How-often-should-I-bleed-my-SRAM-DOT-brakes",
    }
  );

  if (e) {
    list.push({
      slot: "battery",
      label: "Akku-Check (Kontakte, Kapazität)",
      intervalDays: 365,
      bikeWide: true,
      sourceLabel: annualSource,
    });
  }

  if (wantsForkService) {
    list.push(
      {
        slot: "fork",
        label: "Gabel Lower-Leg Service",
        intervalHours: forkLowerH,
        sourceLabel: suntourFork
          ? "SR Suntour / Werkstatt 50 h"
          : "RockShox / Öhlins 50 h",
        sourceUrl:
          "https://support.rockshox.com/hc/en-us/articles/4412306753947-How-often-should-I-service-my-RockShox-product",
      },
      {
        slot: "fork",
        label: "Gabel Vollservice (Feder/Dämpfer)",
        intervalHours: forkFullH,
        intervalDays: 365,
        sourceLabel: foxFork
          ? "Fox 125 h / 1 Jahr"
          : rockshoxFork
            ? "RockShox Full 200 h"
            : ohlinsFork
              ? "Öhlins 100 h/Jahr"
              : suntourFork
                ? "SR Suntour 100 h (konservativ)"
                : "Fox 125 h / 1 Jahr (konservativ)",
        sourceUrl: "https://www.ridefoxaustralia.com.au/pages/service-intervals",
        sourceSpan: "RockShox Full 200 h · Öhlins 100 h/Jahr · Default nach OEM",
      }
    );
  }

  if (mtb) {
    list.push(
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
