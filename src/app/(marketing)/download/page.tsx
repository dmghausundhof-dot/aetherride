import Link from "next/link";
import { AppDownloadButtons } from "@/components/landing/AppDownloadButtons";
import { LandingFooter } from "@/components/landing/LandingFooter";
import { LandingHeader } from "@/components/landing/LandingHeader";
import { Smartphone, Map, WifiOff, Activity } from "lucide-react";
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
    body: "Bosch LDI, Sensor-Fusion und Live-Hints brauchen natives GPS und Bluetooth.",
  },
  {
    icon: Smartphone,
    title: "Aufzeichnung",
    body: "Zuverlässiges Ride-Recording auch bei gesperrtem Display.",
  },
];

export const metadata = {
  title: "App laden – AetherRide",
  description:
    "AetherRide für Android und iOS: Navigation, Offline und Sensoren. Der Hof bleibt im Browser.",
};

export default function DownloadPage() {
  return (
    <div className="flex min-h-screen flex-col">
      <LandingHeader />
      <main className="flex-1 px-4 py-16">
        <div className="mx-auto max-w-3xl text-center">
          <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
            Die App für unterwegs
          </h1>
          <p className="mt-4 text-lg text-text-secondary">
            Der Hof, die Karte und die Werkstatt laufen im Browser. Rausfahren
            mit HUD, Uhr koppeln und Sensoren — nur in der nativen App.
          </p>
          <div className="mt-10 flex justify-center">
            <AppDownloadButtons size="lg" />
          </div>
          <p className="mt-4 text-xs text-text-secondary">
            Navigation und Sensoren nur in der App. Hof, Karte und Werkstatt
            laufen im Web.
          </p>
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

        <div className="mx-auto mt-12 max-w-xl text-center">
          <Link
            href="/discover"
            className="text-sm font-semibold text-chrome hover:underline"
          >
            Zuerst die Karte im Web öffnen →
          </Link>
        </div>
      </main>
      <LandingFooter />
    </div>
  );
}
