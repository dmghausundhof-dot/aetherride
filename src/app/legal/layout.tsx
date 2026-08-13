import { LandingHeader } from "@/components/landing/LandingHeader";
import { LandingFooter } from "@/components/landing/LandingFooter";
import { HOF_COPY } from "@/lib/home/hofCopy";

export default function LegalLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex min-h-screen flex-col">
      <LandingHeader />
      <main className="flex-1">
        <p className="mx-auto max-w-lg px-4 pt-8 text-[11px] font-bold tracking-wide text-chrome">
          {HOF_COPY.legalKicker}
        </p>
        {children}
      </main>
      <LandingFooter />
    </div>
  );
}
