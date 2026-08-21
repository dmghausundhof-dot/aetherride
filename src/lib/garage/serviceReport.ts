import type { Bike, MaintenanceLogEntry, Ride } from "@/types";
import { bikeCategoryLabel, slotLabel } from "@/lib/catalog/slots";
import { getComponentModel, modelDisplayName } from "@/lib/catalog/components";
import { setupConditionLabel } from "@/lib/setup/conditionLabels";

/** Text-Report für Werkstatt / Verkauf / Versicherung */
export function buildServiceReport(input: {
  bike: Bike;
  logs: MaintenanceLogEntry[];
  rides: Ride[];
}): string {
  const { bike, logs, rides } = input;
  const comps = bike.components.filter((c) => !c.removedAt);
  const bikeRides = rides.filter((r) => r.bikeId === bike.id);
  const costSum = logs
    .filter((l) => l.bikeId === bike.id && l.costEur != null)
    .reduce((s, l) => s + (l.costEur ?? 0), 0);
  const current = bike.setups.find((s) => s.isCurrent);

  const lines: string[] = [
    "FlowLine — Service-Report",
    `Erstellt: ${new Date().toLocaleString("de-DE")}`,
    "",
    `Bike: ${bike.name}`,
    `Kategorie: ${bikeCategoryLabel(bike.category)}`,
    bike.year ? `Jahr: ${bike.year}` : "",
    bike.frameSize ? `Rahmengröße: ${bike.frameSize}` : "",
    bike.serialNumber ? `Rahmennummer: ${bike.serialNumber}` : "",
    bike.color ? `Farbe: ${bike.color}` : "",
    bike.weightKg != null ? `Gewicht: ${bike.weightKg.toFixed(1)} kg` : "",
    bike.purchasedAt ? `Gekauft am: ${bike.purchasedAt}` : "",
    bike.purchasedFrom ? `Gekauft bei: ${bike.purchasedFrom}` : "",
    bike.purchasePriceEur != null
      ? `Kaufpreis: ${bike.purchasePriceEur.toFixed(0)} €`
      : "",
    bike.insuranceName ? `Versicherung: ${bike.insuranceName}` : "",
    bike.insurancePolicy ? `Police: ${bike.insurancePolicy}` : "",
    bike.keyNumber ? `Schlüsselnummer: ${bike.keyNumber}` : "",
    `Kilometerstand: ${bike.totalOdometerKm.toFixed(0)} km`,
    `Stunden: ${bike.totalHours.toFixed(1)} h`,
    `Rides erfasst: ${bikeRides.length}`,
    costSum > 0 ? `Wartungskosten gesamt: ${costSum.toFixed(2)} €` : "",
    "",
    "— Aktive Komponenten —",
  ];

  for (const c of comps) {
    const model = c.componentModelId
      ? getComponentModel(c.componentModelId)
      : undefined;
    const name = model
      ? modelDisplayName(model)
      : c.freeText || `${c.manufacturer ?? ""} ${c.model ?? ""}`.trim() || "—";
    lines.push(
      `• ${slotLabel(c.slot)}: ${name} (Einbau ${new Date(c.installedAt).toLocaleDateString("de-DE")})`
    );
  }

  if (current) {
    lines.push(
      "",
      "— Aktuelles Setup —",
      `„${current.label}“ · ${setupConditionLabel(current.conditions)} · v${current.version}`
    );
    for (const v of current.values.slice(0, 12)) {
      lines.push(
        `  ${v.slot}.${v.adjusterKey}: ${v.valueNum}${v.unit === "clicks" ? " clk" : ` ${v.unit}`}`
      );
    }
  }

  const bikeLogs = logs.filter((l) => l.bikeId === bike.id).slice(0, 40);
  lines.push("", "— Wartungslog —");
  if (bikeLogs.length === 0) {
    lines.push("(kein Eintrag)");
  } else {
    for (const l of bikeLogs) {
      lines.push(
        `• ${l.date}: ${l.activity}${l.costEur != null ? ` · ${l.costEur} €` : ""}${l.performer === "workshop" ? " · Werkstatt" : " · Eigen"}`
      );
      if (l.notes) lines.push(`  ${l.notes}`);
    }
  }

  lines.push(
    "",
    "Hinweis: Report aus lokalen App-Daten. Keine Garantie gegenüber Werkstatt/Versicherung."
  );

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
