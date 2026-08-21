"use client";

import Link from "next/link";
import type { PublicTour } from "@/lib/catalog/publicTours";
import {
  clubsForTour,
  eventsForTour,
  tourFunctionStates,
  tourHrefForEvent,
} from "@/lib/tours/tourFunctions";
import { catalogCopy } from "@/lib/i18n/catalogCopy";
import { useChromeLang } from "@/hooks/useChromeLang";

export function TourFunctionKit({ tour }: { tour: PublicTour }) {
  const copy = catalogCopy(useChromeLang());
  const states = tourFunctionStates(tour);
  const events = eventsForTour(tour.id);
  const clubs = clubsForTour(tour);

  return (
    <section className="rounded-2xl border border-border bg-surface p-4">
      <h2 className="text-sm font-semibold">{copy.tour.kitTitle}</h2>
      <p className="mt-1 text-xs text-text-secondary">{copy.tour.kitLead}</p>
      <ul className="mt-3 flex flex-wrap gap-1.5">
        {states.map((state) => (
          <li
            key={state.id}
            className={
              state.available
                ? "rounded-full bg-surface-elevated px-2.5 py-1 text-[11px]"
                : "rounded-full border border-dashed border-border px-2.5 py-1 text-[11px] text-text-secondary"
            }
          >
            {copy.tour.fn[state.id]}
          </li>
        ))}
      </ul>

      {events.length > 0 ? (
        <div className="mt-4 space-y-3">
          <h3 className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
            {copy.tour.eventTitle}
          </h3>
          <p className="text-[11px] text-text-secondary">{copy.tour.eventLead}</p>
          {events.map((event) => (
            <div key={event.id} className="rounded-xl border border-border bg-background/60 p-3">
              <p className="text-[11px] uppercase tracking-wide text-text-secondary">
                {event.sport} · {event.dateLabel}
              </p>
              <p className="mt-1 text-sm font-semibold">{event.title}</p>
              <p className="mt-1 text-xs text-text-secondary">{event.blurb}</p>
              <Link
                href={tourHrefForEvent(event)}
                className="mt-2 inline-block text-xs font-semibold text-chrome hover:underline"
              >
                {copy.tour.eventOpen}
              </Link>
            </div>
          ))}
        </div>
      ) : null}

      <div className="mt-4 rounded-xl border border-border bg-background/60 p-3">
        <h3 className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
          {copy.tour.groupTitle}
        </h3>
        <p className="mt-1 text-xs text-text-secondary">{copy.tour.groupBody}</p>
        <Link
          href="/library"
          className="mt-2 inline-block text-xs font-semibold text-chrome hover:underline"
        >
          {copy.tour.groupCta}
        </Link>
      </div>

      {clubs.length > 0 ? (
        <ul className="mt-3 space-y-1 text-[11px] text-text-secondary">
          {clubs.map((club) => (
            <li key={club.id}>
              {club.href ? (
                <Link href={club.href} className="hover:text-chrome hover:underline">
                  {club.name}
                </Link>
              ) : (
                club.name
              )}
            </li>
          ))}
        </ul>
      ) : null}
    </section>
  );
}
