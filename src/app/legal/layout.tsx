import { LandingHeader } from "@/components/landing/LandingHeader";
import { LandingFooter } from "@/components/landing/LandingFooter";
import { LegalSubnav } from "@/components/legal/LegalSubnav";
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
        <div className="mx-auto max-w-2xl px-4 pb-16 pt-8 sm:px-6">
          <p className="text-[11px] font-bold tracking-wide text-chrome">
            {HOF_COPY.legalKicker}
          </p>
          <LegalSubnav />
          {children}
        </div>
      </main>
      <LandingFooter />
    </div>
  );
}
