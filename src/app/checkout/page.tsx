"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useCartStore } from "@/store/useCartStore";
import { ArrowLeft, CheckCircle2, Trash2 } from "lucide-react";
import Link from "next/link";

export default function CheckoutPage() {
  const router = useRouter();
  const items = useCartStore((s) => s.items);
  const removeItem = useCartStore((s) => s.removeItem);
  const updateQuantity = useCartStore((s) => s.updateQuantity);
  const getTotal = useCartStore((s) => s.getTotal);
  const placeOrder = useCartStore((s) => s.placeOrder);

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [street, setStreet] = useState("");
  const [zip, setZip] = useState("");
  const [city, setCity] = useState("");
  const [done, setDone] = useState(false);
  const [orderId, setOrderId] = useState("");

  const total = getTotal();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (items.length === 0) return;
    const order = placeOrder(
      { name, street, zip, city, country: "DE" },
      email
    );
    setOrderId(order.id);
    setDone(true);

    // Optional: POST an Backend API
    fetch("/api/orders", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(order),
    }).catch(() => {});
  };

  if (done) {
    return (
      <div className="flex flex-col items-center gap-5 p-6 pt-16 text-center">
        <CheckCircle2 className="h-16 w-16 text-success" />
        <h1 className="text-2xl font-bold">Bestellung bestätigt</h1>
        <p className="text-text-secondary">
          Bestellnummer: <span className="font-mono text-accent">{orderId.slice(0, 8)}</span>
        </p>
        <p className="text-sm text-text-secondary max-w-xs">
          Du erhältst eine Bestätigung per E-Mail. Die Kompatibilitätsprüfung wurde durchgeführt.
        </p>
        <Link
          href="/shop"
          className="mt-4 rounded-xl bg-accent px-6 py-3 font-medium text-white"
        >
          Weiter einkaufen
        </Link>
        <Link href="/" className="text-sm text-text-secondary">
          Zurück zur Home
        </Link>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header className="flex items-center gap-3">
        <Link href="/shop" className="p-1">
          <ArrowLeft className="h-6 w-6" />
        </Link>
        <h1 className="text-xl font-bold">Checkout</h1>
      </header>

      {items.length === 0 ? (
        <div className="py-12 text-center text-text-secondary">
          <p>Warenkorb ist leer</p>
          <Link href="/shop" className="mt-3 inline-block text-accent">
            Zum Shop
          </Link>
        </div>
      ) : (
        <>
          {/* Cart Items */}
          <section className="flex flex-col gap-3">
            {items.map((item) => (
              <div
                key={item.id}
                className="flex items-center gap-3 rounded-xl bg-surface border border-border p-3"
              >
                <div className="flex-1">
                  <div className="font-medium text-sm">{item.name}</div>
                  <div className="text-xs text-text-secondary">{item.manufacturer}</div>
                  <div className="tabular-nums text-accent font-semibold mt-1">
                    {item.price.toLocaleString("de-DE")} €
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => updateQuantity(item.id, item.quantity - 1)}
                    className="h-8 w-8 rounded-lg bg-surface-elevated text-lg"
                  >
                    −
                  </button>
                  <span className="tabular-nums w-6 text-center">{item.quantity}</span>
                  <button
                    onClick={() => updateQuantity(item.id, item.quantity + 1)}
                    className="h-8 w-8 rounded-lg bg-surface-elevated text-lg"
                  >
                    +
                  </button>
                  <button
                    onClick={() => removeItem(item.id)}
                    className="ml-1 p-1.5 text-text-secondary"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </div>
            ))}
          </section>

          <div className="rounded-xl bg-surface-elevated p-3 flex justify-between font-semibold">
            <span>Summe</span>
            <span className="tabular-nums text-accent">
              {total.toLocaleString("de-DE")} €
            </span>
          </div>

          {/* Shipping Form */}
          <form onSubmit={handleSubmit} className="flex flex-col gap-3">
            <h3 className="font-semibold">Lieferadresse</h3>
            <input
              required
              placeholder="Name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="rounded-xl border border-border bg-surface px-4 py-3 text-sm outline-none focus:border-accent"
            />
            <input
              required
              type="email"
              placeholder="E-Mail"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="rounded-xl border border-border bg-surface px-4 py-3 text-sm outline-none focus:border-accent"
            />
            <input
              required
              placeholder="Straße & Hausnummer"
              value={street}
              onChange={(e) => setStreet(e.target.value)}
              className="rounded-xl border border-border bg-surface px-4 py-3 text-sm outline-none focus:border-accent"
            />
            <div className="flex gap-3">
              <input
                required
                placeholder="PLZ"
                value={zip}
                onChange={(e) => setZip(e.target.value)}
                className="w-28 rounded-xl border border-border bg-surface px-4 py-3 text-sm outline-none focus:border-accent"
              />
              <input
                required
                placeholder="Stadt"
                value={city}
                onChange={(e) => setCity(e.target.value)}
                className="flex-1 rounded-xl border border-border bg-surface px-4 py-3 text-sm outline-none focus:border-accent"
              />
            </div>

            <button
              type="submit"
              className="mt-2 rounded-xl bg-accent py-3.5 font-semibold text-white shadow-lg shadow-accent/25 active:scale-[0.98]"
            >
              Jetzt bestellen · {total.toLocaleString("de-DE")} €
            </button>
          </form>

          <p className="text-center text-xs text-text-secondary">
            Demo-Checkout · Keine echte Zahlung · DSGVO-konform speicherbar
          </p>
        </>
      )}
    </div>
  );
}
