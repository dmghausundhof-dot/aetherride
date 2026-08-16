"use client";

import Image from "next/image";
import { useChromeLang } from "@/hooks/useChromeLang";
import { screenGalleryCopy } from "@/lib/i18n/screenGalleryCopy";

export function ScreenGallery({
  heading,
  hint,
}: {
  heading?: string;
  hint?: string;
}) {
  const copy = screenGalleryCopy(useChromeLang());
  return (
    <section className="px-4 py-16 sm:px-6">
      <div className="mx-auto max-w-6xl">
        <h2 className="text-2xl font-bold sm:text-3xl">{heading ?? copy.heading}</h2>
        <p className="mt-2 max-w-2xl text-sm text-text-secondary">
          {hint ?? copy.hint}
        </p>
        <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {copy.shots.map((shot) => (
            <figure
              key={shot.src}
              className="overflow-hidden rounded-2xl border border-border bg-surface"
            >
              <div className="relative aspect-[4/3] bg-background">
                <Image
                  src={shot.src}
                  alt={shot.alt}
                  fill
                  sizes="(min-width: 1024px) 33vw, (min-width: 640px) 50vw, 100vw"
                  className="object-cover object-top"
                />
              </div>
              <figcaption className="p-4">
                <p className="text-[11px] font-semibold uppercase tracking-wide text-text-secondary">
                  {shot.door}
                </p>
                <p className="mt-1 font-semibold">{shot.title}</p>
                <p className="mt-1 text-xs text-text-secondary">{shot.note}</p>
              </figcaption>
            </figure>
          ))}
        </div>
      </div>
    </section>
  );
}
