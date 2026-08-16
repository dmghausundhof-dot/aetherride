import { LandingHeader } from "@/components/landing/LandingHeader";
import { LandingFooter } from "@/components/landing/LandingFooter";
import { LegalSubnav } from "@/components/legal/LegalSubnav";
import { LegalKicker } from "@/components/legal/LegalKicker";

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
          <LegalKicker />
          <LegalSubnav />
          {children}
        </div>
      </main>
      <LandingFooter />
    </div>
  );
}
