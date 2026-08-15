import type { Metadata } from "next";
import Link from "next/link";
import { Check, Minus } from "lucide-react";
import { AppDownloadButtons } from "@/components/landing/AppDownloadButtons";

export const metadata: Metadata = {
  title: "Preise – Free & Pro",
  description:
    "FlowLine Free und Pro: Touren und Planen für alle. Multi-Bike, Bracketing, Reichweite und Offline-Packs mit Pro.",
};

const rows: {
  feature: string;
  free: boolean | string;
  pro: boolean | string;
}[] = [
  { feature: "Karte & öffentliche Routen", free: true, pro: true },
  { feature: "Planen auf der Karte", free: true, pro: true },
  { feature: "Platz: Mappe, Stimmen, Gruppen", free: true, pro: true },
  { feature: "1 Rad in der Werkstatt", free: true, pro: true },
  { feature: "Mehrere Räder", free: false, pro: true },
  { feature: "Kompatibilität & Setup-Basis", free: true, pro: true },
  { feature: "Bracketing-Auswertung", free: false, pro: true },
  { feature: "E-Bike-Reichweite (Spanne)", free: false, pro: true },
  { feature: "Erweiterte Offline-Packs", free: false, pro: true },
  { feature: "KI-Chat (höheres Limit)", free: "5/Tag", pro: "50/Tag" },
  { feature: "App-Navigation & Sensoren", free: true, pro: true },
  { feature: "Shop-Gateway (Shopify)", free: true, pro: true },
];

function Cell({ value }: { value: boolean | string }) {
  if (typeof value === "string") {
    return <span className="text-sm font-medium">{value}</span>;
  }
  return value ? (
    <Check className="mx-auto h-5 w-5 text-success" aria-label="Enthalten" />
  ) : (
    <Minus className="mx-auto h-5 w-5 text-text-secondary" aria-label="Nicht enthalten" />
  );
}

export default function PricingPage() {
  return (
    <div className="px-4 py-14 sm:px-6">
      <div className="mx-auto max-w-4xl text-center">
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
          Free plant. Pro vertieft.
        </h1>
        <p className="mx-auto mt-4 max-w-2xl text-text-secondary">
          Touren entdecken und planen ist für alle da. Multi-Bike, Bracketing
          und ehrliche Reichweiten-Spannen sind Pro — Navigation läuft in der
          App auf beiden Stufen.
        </p>
      </div>

      <div className="mx-auto mt-12 grid max-w-4xl gap-6 md:grid-cols-2">
        <div className="rounded-2xl border border-border bg-surface p-6 text-left">
          <h2 className="text-xl font-bold">Free</h2>
          <p className="mt-1 text-3xl font-bold tabular-nums">0 €</p>
          <p className="mt-2 text-sm text-text-secondary">
            Touren, Planen, 1 Bike, App-Navigation
          </p>
          <Link
            href="/home"
            className="mt-6 inline-flex w-full items-center justify-center rounded-xl border border-border py-3 text-sm font-semibold"
          >
            Zum Hof
          </Link>
        </div>
        <div className="rounded-2xl border border-chrome/40 bg-chrome/10 p-6 text-left">
          <p className="text-xs font-semibold uppercase tracking-wide text-chrome">
            Empfohlen
          </p>
          <h2 className="mt-1 text-xl font-bold">Pro</h2>
          <p className="mt-1 text-3xl font-bold tabular-nums">
            6,99 €
            <span className="text-base font-normal text-text-secondary">
              /Mo
            </span>
          </p>
          <p className="text-sm text-text-secondary">
            oder 59,99 €/Jahr · Kündigung im Portal
          </p>
          <Link
            href="/anmelden?next=/profile"
            className="mt-6 inline-flex w-full items-center justify-center rounded-xl bg-chrome py-3 text-sm font-semibold text-background"
          >
            Pro freischalten
          </Link>
          <p className="mt-2 text-center text-[11px] text-text-secondary">
            Checkout im Profil (Stripe) · Play Billing in der Android-App
          </p>
        </div>
      </div>

      <div className="mx-auto mt-14 max-w-4xl overflow-x-auto rounded-2xl border border-border">
        <table className="w-full min-w-[320px] text-left text-sm">
          <thead>
            <tr className="border-b border-border bg-surface">
              <th className="px-4 py-3 font-semibold">Funktion</th>
              <th className="px-4 py-3 text-center font-semibold">Free</th>
              <th className="px-4 py-3 text-center font-semibold">Pro</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.feature} className="border-b border-border/80">
                <td className="px-4 py-3 text-text-secondary">{r.feature}</td>
                <td className="px-4 py-3 text-center">
                  <Cell value={r.free} />
                </td>
                <td className="px-4 py-3 text-center">
                  <Cell value={r.pro} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="mx-auto mt-14 max-w-xl text-center">
        <h2 className="text-lg font-semibold">App für unterwegs</h2>
        <p className="mt-2 text-sm text-text-secondary">
          Free und Pro navigieren in der nativen App — nicht im Browser.
        </p>
        <div className="mt-6 flex justify-center">
          <AppDownloadButtons size="lg" />
        </div>
        <p className="mt-6 text-xs text-text-secondary">
          Details zu Daten und Abo:{" "}
          <Link href="/legal/agb" className="text-chrome hover:underline">
            AGB
          </Link>
          {" · "}
          <Link href="/legal/widerruf" className="text-chrome hover:underline">
            Widerruf
          </Link>
          {" · "}
          <Link href="/legal/datenschutz" className="text-chrome hover:underline">
            Datenschutz
          </Link>
          {" · "}
          <Link href="/produkt" className="text-chrome hover:underline">
            Produkt
          </Link>
          {" · "}
          <Link href="/faq" className="text-chrome hover:underline">
            FAQ
          </Link>
        </p>
      </div>
    </div>
  );
}
