import Image from "next/image";
import { SCREEN_GALLERY } from "@/lib/content/screenGallery";

export function ScreenGallery({
  heading = "So sieht FlowLine aus",
  hint = "Marke und Screens aus dem Design-System. Die fünf Türen bleiben: Hof, Karte, Platz, Werkstatt, Laden.",
}: {
  heading?: string;
  hint?: string;
}) {
  return (
    <section className="px-4 py-16 sm:px-6">
      <div className="mx-auto max-w-6xl">
        <h2 className="text-2xl font-bold sm:text-3xl">{heading}</h2>
        <p className="mt-2 max-w-2xl text-sm text-text-secondary">{hint}</p>
        <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {SCREEN_GALLERY.map((shot) => (
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
                <p className="text-[11px] font-semibold uppercase tracking-wide text-chrome">
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
