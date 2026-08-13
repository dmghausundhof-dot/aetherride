"use client";

import { HOF_COPY } from "@/lib/home/hofCopy";

export function RideOutChoice({
  onJustRide,
  onShowTours,
}: {
  onJustRide: () => void;
  onShowTours: () => void;
}) {
  return (
    <div
      data-testid="hof-ride-out-choice"
      className="rounded-2xl border border-border bg-surface p-4"
    >
      <p className="text-[11px] font-bold tracking-wide text-text-secondary">
        {HOF_COPY.rideOut}
      </p>
      <p className="mt-1 text-sm text-text-secondary">
        {HOF_COPY.mapChoiceHint}
      </p>
      <div className="mt-3 grid gap-2 sm:grid-cols-2">
        <button
          type="button"
          onClick={onJustRide}
          className="rounded-xl bg-accent py-3 text-sm font-extrabold text-white hover:bg-accent-hover"
        >
          {HOF_COPY.justRide}
        </button>
        <button
          type="button"
          onClick={onShowTours}
          className="rounded-xl border border-border py-3 text-sm font-semibold hover:border-chrome hover:text-chrome"
        >
          {HOF_COPY.showTours}
        </button>
      </div>
      <p className="mt-2 text-[11px] text-text-secondary">
        {HOF_COPY.mapJustRideHint}
      </p>
    </div>
  );
}
