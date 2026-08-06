"use client";

import { create } from "zustand";
import { persist } from "zustand/middleware";
import { v4 as uuidv4 } from "uuid";

export interface CartItem {
  id: string;
  productId: string;
  name: string;
  manufacturer: string;
  price: number;
  quantity: number;
  compatibilityMatch: boolean;
}

export interface Order {
  id: string;
  items: CartItem[];
  total: number;
  status: "pending" | "confirmed" | "shipped" | "delivered";
  createdAt: string;
  shippingAddress: {
    name: string;
    street: string;
    zip: string;
    city: string;
    country: string;
  };
  email: string;
}

interface CartState {
  items: CartItem[];
  orders: Order[];
  addItem: (item: Omit<CartItem, "id" | "quantity"> & { quantity?: number }) => void;
  removeItem: (id: string) => void;
  updateQuantity: (id: string, quantity: number) => void;
  clearCart: () => void;
  getTotal: () => number;
  placeOrder: (address: Order["shippingAddress"], email: string) => Order;
}

export const useCartStore = create<CartState>()(
  persist(
    (set, get) => ({
      items: [],
      orders: [],

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

      placeOrder: (address, email) => {
        const items = get().items;
        const total = get().getTotal();
        const order: Order = {
          id: uuidv4(),
          items: [...items],
          total,
          status: "confirmed",
          createdAt: new Date().toISOString(),
          shippingAddress: address,
          email,
        };
        set((s) => ({
          orders: [order, ...s.orders],
          items: [],
        }));
        return order;
      },
    }),
    { name: "aetherride-cart" }
  )
);
