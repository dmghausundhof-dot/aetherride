import { RadEmptyStage } from "@/components/garage/RadEmptyStage";
import { RadGlyph } from "@/components/garage/RadGlyph";

export function RadEmpty({
  title,
  hint,
  children,
}: {
  title: string;
  hint: string;
  children?: React.ReactNode;
}) {
  return (
    <section
      className="overflow-hidden rounded-2xl border border-dashed border-border bg-surface text-center"
      data-testid="rad-empty"
    >
      <RadEmptyStage heightClass="h-36" />
      <div className="px-6 pb-8 pt-3">
        <p className="flex items-center justify-center gap-2 text-lg font-extrabold">
          <RadGlyph name="stand" size={20} />
          {title}
        </p>
        <p className="mx-auto mt-2 max-w-md text-sm text-text-secondary">{hint}</p>
        {children}
      </div>
    </section>
  );
}
