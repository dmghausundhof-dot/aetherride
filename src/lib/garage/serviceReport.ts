import type { Bike, MaintenanceLogEntry, Ride } from "@/types";
import { bikeCategoryLabel, slotLabel } from "@/lib/catalog/slots";
import { getComponentModel, modelDisplayName } from "@/lib/catalog/components";
import { setupConditionLabel } from "@/lib/setup/conditionLabels";
import { bikeIdentityCopy } from "@/lib/i18n/bikeIdentityCopy";
import { chromeDateLocale, type ChromeLang } from "@/lib/i18n/chromeLang";
import { presentMaintActivity } from "@/lib/i18n/maintDomainCopy";
import { serviceReportCopy } from "@/lib/i18n/serviceReportCopy";

/** Text-Report für Werkstatt / Verkauf / Versicherung */
export function buildServiceReport(input: {
  bike: Bike;
  logs: MaintenanceLogEntry[];
  rides: Ride[];
  lang?: ChromeLang;
}): string {
  const { bike, logs, rides } = input;
  const lang = input.lang ?? "de";
  const loc = chromeDateLocale(lang);
  const id = bikeIdentityCopy(lang);
  const report = serviceReportCopy(lang);
  const comps = bike.components.filter((c) => !c.removedAt);
  const bikeRides = rides.filter((r) => r.bikeId === bike.id);
  const costSum = logs
    .filter((l) => l.bikeId === bike.id && l.costEur != null)
    .reduce((s, l) => s + (l.costEur ?? 0), 0);
  const current = bike.setups.find((s) => s.isCurrent);

  const lines: string[] = [
    report.title,
    report.created(new Date().toLocaleString(loc)),
    "",
    `${report.bike}: ${bike.name}`,
    `${report.category}: ${bikeCategoryLabel(bike.category, lang)}`,
    bike.year ? `${id.year}: ${bike.year}` : "",
    bike.frameSize ? `${id.frameSize}: ${bike.frameSize}` : "",
    bike.serialNumber ? `${id.serial}: ${bike.serialNumber}` : "",
    bike.color ? `${id.color}: ${bike.color}` : "",
    bike.weightKg != null ? `${id.weight}: ${bike.weightKg.toFixed(1)}` : "",
    bike.purchasedAt ? `${id.purchasedAt}: ${bike.purchasedAt}` : "",
    bike.purchasedFrom ? `${id.purchasedFrom}: ${bike.purchasedFrom}` : "",
    bike.purchasePriceEur != null
      ? `${id.price}: ${bike.purchasePriceEur.toFixed(0)} €`
      : "",
    bike.insuranceName ? `${id.insurance}: ${bike.insuranceName}` : "",
    bike.insurancePolicy ? `${id.policy}: ${bike.insurancePolicy}` : "",
    bike.keyNumber ? `${id.keyNumber}: ${bike.keyNumber}` : "",
    report.odometer(bike.totalOdometerKm.toFixed(0)),
    report.hours(bike.totalHours.toFixed(1)),
    report.rides(bikeRides.length),
    costSum > 0 ? report.cost(costSum.toFixed(2)) : "",
    "",
    report.parts,
  ];

  for (const c of comps) {
    const model = c.componentModelId
      ? getComponentModel(c.componentModelId)
      : undefined;
    const name = model
      ? modelDisplayName(model)
      : c.freeText || `${c.manufacturer ?? ""} ${c.model ?? ""}`.trim() || "—";
    lines.push(
      `• ${slotLabel(c.slot, lang)}: ${name} (${report.installed(
        new Date(c.installedAt).toLocaleDateString(loc)
      )})`
    );
  }

  if (current) {
    lines.push(
      "",
      report.setup,
      report.setupLine(
        current.label,
        setupConditionLabel(current.conditions, lang),
        current.version
      )
    );
    for (const v of current.values.slice(0, 12)) {
      lines.push(
        `  ${v.slot}.${v.adjusterKey}: ${v.valueNum}${v.unit === "clicks" ? " clk" : ` ${v.unit}`}`
      );
    }
  }

  const bikeLogs = logs.filter((l) => l.bikeId === bike.id).slice(0, 40);
  lines.push("", report.log);
  if (bikeLogs.length === 0) {
    lines.push(report.logEmpty);
  } else {
    for (const l of bikeLogs) {
      const who = l.performer === "workshop" ? report.workshop : report.self;
      lines.push(
        `• ${l.date}: ${presentMaintActivity(l.activity, lang)}${
          l.costEur != null ? ` · ${l.costEur} €` : ""
        } · ${who}`
      );
      if (l.notes) lines.push(`  ${l.notes}`);
    }
  }

  lines.push("", report.disclaimer);

  return lines.filter((l) => l !== "").join("\n");
}

export function downloadServiceReport(filename: string, content: string) {
  const blob = new Blob([content], { type: "text/plain;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
