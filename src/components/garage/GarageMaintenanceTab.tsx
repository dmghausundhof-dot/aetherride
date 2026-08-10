"use client";

import { History, Download } from "lucide-react";
import { evaluateIntervalDue } from "@/lib/maintenance/intervals";
import { forecastWear } from "@/lib/maintenance/wearPrediction";
import { slotLabel } from "@/lib/catalog/slots";
import type {
  Bike,
  Ride,
  MaintenanceInterval,
  MaintenanceLogEntry,
} from "@/types";

interface Props {
  selected: Bike;
  rides: Ride[];
  intervals: MaintenanceInterval[];
  logs: MaintenanceLogEntry[];
  costSum: number;
  markIntervalDone: (id: string) => void;
  exportReport: () => void;
}

export function GarageMaintenanceTab({
  selected,
  rides,
  intervals,
  logs,
  costSum,
  markIntervalDone,
  exportReport,
}: Props) {
  return (
            <div className="flex flex-col gap-4">
              <section>
                <h3 className="mb-2 font-semibold">Verschleißprognose</h3>
                <p className="mb-2 text-xs text-text-secondary">
                  Belastungsgewichtet · Spanne, nie Punktwert.
                </p>
                <div className="flex flex-col gap-2">
                  {forecastWear(selected, rides).map((f) => (
                    <div
                      key={f.kind}
                      className={`rounded-xl border p-3 text-sm ${
                        f.dueSoon
                          ? "border-warning/50 bg-warning/10"
                          : "border-border bg-surface"
                      }`}
                    >
                      <div className="font-medium">{f.label}</div>
                      <p className="mt-1 text-xs text-text-secondary">
                        {f.reasoning}
                      </p>
                      <p className="mt-1 text-[10px] text-text-secondary">
                        {f.sourceLabel}
                      </p>
                    </div>
                  ))}
                  {forecastWear(selected, rides).length === 0 && (
                    <p className="text-sm text-text-secondary">
                      Keine Verschleißteile mit Historie.
                    </p>
                  )}
                </div>
              </section>

              <section>
                <h3 className="mb-2 font-semibold">Fälligkeiten</h3>
                <div className="flex flex-col gap-2">
                  {intervals.map((interval) => {
                    const due = evaluateIntervalDue(
                      interval,
                      selected.totalOdometerKm,
                      selected.totalHours
                    );
                    return (
                      <div
                        key={interval.id}
                        className="rounded-xl border border-border bg-surface p-3"
                      >
                        <div className="flex items-start justify-between gap-2">
                          <div>
                            <div className="font-medium text-sm">
                              {interval.label}
                            </div>
                            <div className="text-xs text-text-secondary">
                              {slotLabel(interval.slot)} · {interval.sourceLabel}
                              {interval.overriddenByUser ? " · angepasst" : ""}
                            </div>
                            <div className="mt-1 text-xs">
                              {due.remainingLabel} · {due.progressPct}%
                              {due.status === "overdue" && (
                                <span className="text-error"> · überfällig</span>
                              )}
                              {due.status === "due_soon" && (
                                <span className="text-warning"> · bald</span>
                              )}
                            </div>
                          </div>
                          <button
                            type="button"
                            onClick={() => markIntervalDone(interval.id)}
                            className="rounded-lg bg-accent px-2 py-1 text-xs font-semibold text-white"
                          >
                            Erledigt
                          </button>
                        </div>
                        <div className="mt-2 h-1.5 overflow-hidden rounded-full bg-muted">
                          <div
                            className={`h-full ${
                              due.status === "overdue"
                                ? "bg-error"
                                : due.status === "due_soon"
                                  ? "bg-warning"
                                  : "bg-success"
                            }`}
                            style={{
                              width: `${Math.min(100, due.progressPct)}%`,
                            }}
                          />
                        </div>
                      </div>
                    );
                  })}
                  {intervals.length === 0 && (
                    <p className="text-sm text-text-secondary">
                      Keine Intervalle — Komponenten einbauen.
                    </p>
                  )}
                </div>
              </section>

              <section>
                <h3 className="mb-2 flex items-center justify-between gap-2 font-semibold">
                  <span className="inline-flex items-center gap-2">
                    <History className="h-4 w-4 text-accent" />
                    Wartungslog
                  </span>
                  <button
                    type="button"
                    onClick={exportReport}
                    className="inline-flex items-center gap-1 text-xs font-medium text-accent"
                  >
                    <Download className="h-3.5 w-3.5" /> Report
                  </button>
                </h3>
                {costSum > 0 && (
                  <p className="mb-2 text-xs text-text-secondary">
                    Kosten gesamt: {costSum.toFixed(2)} €
                  </p>
                )}
                <div className="flex flex-col gap-2">
                  {logs.map((log) => (
                    <div
                      key={log.id}
                      className="rounded-xl border border-border bg-surface p-3 text-sm"
                    >
                      <div className="font-medium">{log.activity}</div>
                      <div className="text-xs text-text-secondary">
                        {log.date} ·{" "}
                        {log.performer === "workshop" ? "Werkstatt" : "Eigen"}
                        {log.odometerKm !== undefined
                          ? ` · ${log.odometerKm.toFixed(0)} km`
                          : ""}
                        {log.costEur !== undefined
                          ? ` · ${log.costEur} €`
                          : ""}
                      </div>
                      {log.notes && (
                        <p className="mt-1 text-xs text-text-secondary">
                          {log.notes}
                        </p>
                      )}
                    </div>
                  ))}
                  {logs.length === 0 && (
                    <p className="text-sm text-text-secondary">Noch kein Log.</p>
                  )}
                </div>
              </section>

              <p className="text-xs text-text-secondary">
                Defaults u. a. RockShox 50 h Lower Leg / 200 h Full, Kette prüfen
                ~1000 km, Tubeless-Milch ~120 Tage.
              </p>
            </div>
  );
}
