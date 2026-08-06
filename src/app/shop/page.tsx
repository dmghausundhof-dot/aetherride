"use client";

import { ShoppingBag, CheckCircle2, ShoppingCart } from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import { useCartStore } from "@/store/useCartStore";
import Link from "next/link";

const products = [
  {
    id: "p1",
    name: "Fox 36 Factory Grip2 170mm",
    manufacturer: "Fox",
    category: "Gabel",
    price: 1249,
    match: true,
    reason: "Passt zu deiner Transition Spire (1.5″ Tapered, 170mm)",
  },
  {
    id: "p2",
    name: "Maxxis Assegai 29×2.5 WT MaxxGrip",
    manufacturer: "Maxxis",
    category: "Reifen",
    price: 89,
    match: true,
    reason: "Kompatibel mit deinem aktuellen Setup (Clearance ok)",
  },
  {
    id: "p3",
    name: "Bosch PowerTube 800 Wh",
    manufacturer: "Bosch",
    category: "Akku",
    price: 999,
    match: true,
    reason: "Offiziell kompatibel mit Performance Line CX Gen5",
  },
  {
    id: "p4",
    name: "Shimano XT M8120 4-Kolben",
    manufacturer: "Shimano",
    category: "Bremsen",
    price: 189,
    match: false,
    reason: "Prüfe Adapter für deinen Rahmen",
  },
  {
    id: "p5",
    name: "RockShox Super Deluxe Ultimate",
    manufacturer: "RockShox",
    category: "Dämpfer",
    price: 679,
    match: true,
    reason: "205×65 eye-to-eye kompatibel mit deinem Rahmen",
  },
];

export default function ShopPage() {
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const bikes = useAppStore((s) => s.bikes);
  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];
  const addItem = useCartStore((s) => s.addItem);
  const cartCount = useCartStore((s) => s.items.reduce((n, i) => n + i.quantity, 0));

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Shop</h1>
          <p className="text-sm text-text-secondary">
            KI- & Kompatibilitäts-basierte Empfehlungen
          </p>
        </div>
        <Link
          href="/checkout"
          className="relative flex h-11 w-11 items-center justify-center rounded-full bg-surface-elevated"
        >
          <ShoppingCart className="h-5 w-5" />
          {cartCount > 0 && (
            <span className="absolute -right-1 -top-1 flex h-5 w-5 items-center justify-center rounded-full bg-accent text-[10px] font-bold text-white">
              {cartCount}
            </span>
          )}
        </Link>
      </header>

      {activeBike && (
        <div className="rounded-xl bg-accent/10 border border-accent/30 px-3 py-2 text-sm">
          <span className="font-medium text-accent">Passt zu deinem Bike: </span>
          {activeBike.name}
        </div>
      )}

      <div className="flex flex-col gap-3">
        {products.map((p) => (
          <div key={p.id} className="rounded-2xl bg-surface border border-border p-4">
            <div className="flex items-start justify-between gap-3">
              <div className="flex-1">
                <div className="text-xs text-text-secondary uppercase tracking-wide">
                  {p.category} · {p.manufacturer}
                </div>
                <h3 className="font-semibold mt-0.5">{p.name}</h3>
                <div className="mt-1 tabular-nums text-lg font-bold text-accent">
                  {p.price.toLocaleString("de-DE")} €
                </div>
              </div>
              {p.match && (
                <div className="flex items-center gap-1 rounded-full bg-success/20 px-2 py-1 text-xs font-medium text-success">
                  <CheckCircle2 className="h-3.5 w-3.5" />
                  Passt
                </div>
              )}
            </div>
            <p className="mt-2 text-xs text-text-secondary">{p.reason}</p>
            <button
              onClick={() =>
                addItem({
                  productId: p.id,
                  name: p.name,
                  manufacturer: p.manufacturer,
                  price: p.price,
                  compatibilityMatch: p.match,
                })
              }
              className="mt-3 w-full rounded-xl bg-surface-elevated py-2.5 text-sm font-medium text-accent active:scale-[0.98]"
            >
              In den Warenkorb
            </button>
          </div>
        ))}
      </div>

      <div className="rounded-xl border border-dashed border-border p-4 text-center text-sm text-text-secondary">
        <ShoppingBag className="mx-auto mb-2 h-8 w-8 opacity-40" />
        Direkter Versand · Kompatibilitätsprüfung aktiv
      </div>
    </div>
  );
}
