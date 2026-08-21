"use client";

import { useHofCopy } from "@/hooks/useHofCopy";
import { formatStripCount } from "@/lib/garage/bikeValueStrip";

/** Four scannable numbers under the photo: km, hours, pressure, service. */
export function BikeValueStrip({
  km,
  hours,
  pressure,
  serviceLabel,
  serviceCaption,
  onKm,
  onHours,
  onPressure,
  onService,
}: {
  km: number;
  hours: number;
  pressure?: string | null;
  serviceLabel?: string | null;
  serviceCaption?: string | null;
  onKm?: () => void;
  onHours?: () => void;
  onPressure?: () => void;
  onService?: () => void;
}) {
  const copy = useHofCopy();
  const dash = copy.workshopStatDash;
  return (
    <div
      data-testid="bike-value-strip"
      className="grid grid-cols-4 divide-x divide-border border-b border-border"
    >
      <Cell
        testId="bike-value-km"
        label={copy.workshopStatKm}
        value={formatStripCount(km, dash)}
        dash={dash}
        prominent
        onTap={onKm}
      />
      <Cell
        testId="bike-value-hours"
        label={copy.workshopStatHours}
        value={formatStripCount(hours, dash, 1)}
        dash={dash}
        onTap={onHours}
      />
      <Cell
        testId="bike-value-pressure"
        label={copy.workshopStatPressure}
        value={pressure ?? dash}
        dash={dash}
        onTap={onPressure}
      />
      <Cell
        testId="bike-value-service"
        label={serviceCaption ?? copy.workshopStatService}
        value={serviceLabel ?? dash}
        dash={dash}
        onTap={onService}
      />
    </div>
  );
}

function Cell({
  testId,
  label,
  value,
  dash,
  prominent,
  onTap,
}: {
  testId: string;
  label: string;
  value: string;
  dash: string;
  prominent?: boolean;
  onTap?: () => void;
}) {
  const known = value !== dash;
  const body = (
    <>
      <span
        className={`max-w-full truncate text-[13px] font-extrabold leading-tight ${
          prominent ? "text-lg" : ""
        } ${known ? "text-text" : "text-text-secondary"}`}
      >
        {value}
      </span>
      <span className="mt-0.5 text-[10px] font-bold tracking-wide text-text-secondary">
        {label}
      </span>
    </>
  );
  const className =
    "flex min-h-11 w-full flex-col items-center justify-center px-1 py-2 text-center";
  if (onTap) {
    return (
      <button
        type="button"
        data-testid={testId}
        onClick={onTap}
        className={className}
        aria-label={`${label} ${value}`}
      >
        {body}
      </button>
    );
  }
  return (
    <div
      data-testid={testId}
      className={className}
      aria-label={`${label} ${value}`}
    >
      {body}
    </div>
  );
}
