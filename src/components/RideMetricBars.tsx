/**
 * Einfache Visualisierung von Impacts und Flow aus Ride-Metriken (kein FNI).
 */
export function RideMetricBars({
  impactCount,
  distanceM,
  flowScore,
  gForcePeak,
  gForceRms,
}: {
  impactCount: number;
  distanceM: number;
  flowScore: number;
  gForcePeak: number;
  gForceRms: number;
}) {
  const km = Math.max(0.1, distanceM / 1000);
  const impactsPerKm = impactCount / km;
  // Normierung für Balken (Demo-Skalen)
  const impactPct = Math.min(100, Math.round((impactsPerKm / 6) * 100));
  const flowPct = Math.min(100, Math.max(0, Math.round(flowScore)));
  const peakPct = Math.min(100, Math.round((gForcePeak / 5) * 100));
  const rmsPct = Math.min(100, Math.round((gForceRms / 2) * 100));

  const rows = [
    { label: "Flow", value: `${flowScore}`, pct: flowPct, accent: true },
    {
      label: "Impacts / km",
      value: impactsPerKm.toFixed(1),
      pct: impactPct,
      accent: false,
    },
    { label: "Peak g", value: `${gForcePeak}`, pct: peakPct, accent: false },
    { label: "RMS g", value: `${gForceRms}`, pct: rmsPct, accent: false },
  ];

  return (
    <div className="space-y-2">
      {rows.map((r) => (
        <div key={r.label}>
          <div className="mb-0.5 flex justify-between text-xs">
            <span className="text-text-secondary">{r.label}</span>
            <span className="tabular-nums font-medium">{r.value}</span>
          </div>
          <div className="h-1.5 overflow-hidden rounded-full bg-surface-elevated">
            <div
              className={`h-full rounded-full ${
                r.accent ? "bg-chrome" : "bg-sage"
              }`}
              style={{ width: `${r.pct}%` }}
            />
          </div>
        </div>
      ))}
    </div>
  );
}
