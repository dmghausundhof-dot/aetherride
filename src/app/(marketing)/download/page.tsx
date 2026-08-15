import Link from "next/link";
import { AppDownloadButtons } from "@/components/landing/AppDownloadButtons";
import { Smartphone, Map, WifiOff, Activity } from "lucide-react";
import { WEB_APP_MATRIX } from "@/lib/content/productMap";

const reasons = [
  {
    icon: Map,
    title: "Navigation",
    body: "Turn-by-turn und Karte während der Fahrt — stabil im Hintergrund.",
  },
  {
    icon: WifiOff,
    title: "Offline",
    body: "Karten und Routing-Packs ohne Netz. Im Browser nicht sinnvoll.",
  },
  {
    icon: Activity,
    title: "Sensoren & BLE",
    body: "Uhr und Radsensor am Fahrer bzw. am Rad. Koppeln nur nativ.",
  },
  {
    icon: Smartphone,
    title: "Aufzeichnung",
    body: "Zuverlässiges Ride-Recording auch bei gesperrtem Display.",
  },
];

export const metadata = {
  title: "App laden – FlowLine",
  description:
    "FlowLine für Android und iOS: Navigation, Offline und Sensoren. Der Hof bleibt im Browser.",
};

export default function DownloadPage() {
  return (
    <div className="px-4 py-16 sm:px-6">
      <div className="mx-auto max-w-3xl text-center">
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
          Die App für unterwegs
        </h1>
        <p className="mt-4 text-lg text-text-secondary">
          Der Hof, die Karte, der Platz und die Werkstatt laufen im Browser.
          Rausfahren mit HUD, Uhr koppeln und Sensoren — nur in der nativen App.
        </p>
        <div className="mt-10 flex justify-center">
          <AppDownloadButtons size="lg" />
        </div>
      </div>

      <div className="mx-auto mt-16 grid max-w-4xl gap-4 sm:grid-cols-2">
        {reasons.map((r) => (
          <div
            key={r.title}
            className="rounded-2xl border border-border bg-surface p-6 text-left"
          >
            <r.icon className="h-6 w-6 text-chrome" />
            <h2 className="mt-3 font-semibold">{r.title}</h2>
            <p className="mt-1 text-sm text-text-secondary">{r.body}</p>
          </div>
        ))}
      </div>

      <div className="mx-auto mt-16 max-w-4xl">
        <h2 className="text-xl font-bold">Web und App, ehrlich getrennt</h2>
        <div className="mt-6 overflow-x-auto rounded-2xl border border-border">
          <table className="w-full min-w-[420px] text-left text-sm">
            <thead>
              <tr className="border-b border-border bg-surface">
                <th className="px-4 py-3 font-semibold">Fläche</th>
                <th className="px-4 py-3 font-semibold">Web</th>
                <th className="px-4 py-3 font-semibold">App</th>
              </tr>
            </thead>
            <tbody>
              {WEB_APP_MATRIX.map((row) => (
                <tr key={row.feature} className="border-b border-border/80">
                  <td className="px-4 py-3 text-text-secondary">{row.feature}</td>
                  <td className="px-4 py-3">{row.web}</td>
                  <td className="px-4 py-3">{row.app}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="mx-auto mt-12 max-w-xl text-center">
        <Link
          href="/discover"
          className="text-sm font-semibold text-chrome hover:underline"
        >
          Zuerst die Karte im Web öffnen →
        </Link>
        <span className="mx-2 text-text-secondary">·</span>
        <Link
          href="/produkt"
          className="text-sm font-semibold text-chrome hover:underline"
        >
          Produktkarte →
        </Link>
      </div>
    </div>
  );
}
