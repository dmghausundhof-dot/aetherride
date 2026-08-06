"use client";

import { create } from "zustand";
import { persist } from "zustand/middleware";
import { v4 as uuidv4 } from "uuid";
import type { CompatibilityVerdict } from "@/types";

export interface CartItem {
  id: string;
  productId: string;
  name: string;
  manufacturer: string;
  price: number;
  quantity: number;
  compatibilityMatch: boolean;
  verdict?: CompatibilityVerdict;
  affiliateUrl?: string;
  merchantName?: string;
}

/** Affiliate-Weiterleitung statt In-App-Zahlung (F-SHP-003) */
export interface AffiliateRedirect {
  id: string;
  items: CartItem[];
  createdAt: string;
  merchantName: string;
  affiliateUrl: string;
}

interface CartState {
  items: CartItem[];
  redirects: AffiliateRedirect[];
  addItem: (
    item: Omit<CartItem, "id" | "quantity"> & { quantity?: number }
  ) => void;
  removeItem: (id: string) => void;
  updateQuantity: (id: string, quantity: number) => void;
  clearCart: () => void;
  getTotal: () => number;
  /** @deprecated Spec: kein In-App-Checkout — nutze recordAffiliateRedirect */
  placeOrder: (
    address: {
      name: string;
      street: string;
      zip: string;
      city: string;
      country: string;
    },
    email: string
  ) => { id: string };
  recordAffiliateRedirect: (item: CartItem) => AffiliateRedirect;
}

export const useCartStore = create<CartState>()(
  persist(
    (set, get) => ({
      items: [],
      redirects: [],

      addItem: (item) => {
        set((s) => {
          const existing = s.items.find((i) => i.productId === item.productId);
          if (existing) {
            return {
              items: s.items.map((i) =>
                i.productId === item.productId
                  ? { ...i, quantity: i.quantity + (item.quantity || 1) }
                  : i
              ),
            };
          }
          return {
            items: [
              ...s.items,
              { ...item, id: uuidv4(), quantity: item.quantity || 1 },
            ],
          };
        });
      },

      removeItem: (id) =>
        set((s) => ({ items: s.items.filter((i) => i.id !== id) })),

      updateQuantity: (id, quantity) =>
        set((s) => ({
          items: s.items.map((i) =>
            i.id === id ? { ...i, quantity: Math.max(1, quantity) } : i
          ),
        })),

      clearCart: () => set({ items: [] }),

      getTotal: () =>
        get().items.reduce((sum, i) => sum + i.price * i.quantity, 0),

      placeOrder: () => {
        // Spec: kein Zahlungsverkehr — leerer Stub für alte Aufrufe
        return { id: uuidv4() };
      },

      recordAffiliateRedirect: (item) => {
        const redirect: AffiliateRedirect = {
          id: uuidv4(),
          items: [item],
          createdAt: new Date().toISOString(),
          merchantName: item.merchantName || "Partner",
          affiliateUrl: item.affiliateUrl || "#",
        };
        set((s) => ({
          redirects: [redirect, ...s.redirects].slice(0, 50),
          items: s.items.filter((i) => i.productId !== item.productId),
        }));
        return redirect;
      },
    }),
    { name: "aetherride-cart" }
  )
);
