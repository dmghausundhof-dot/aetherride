/**
 * Einfache Order-Persistenz für Stripe-Webhooks (File → später Postgres)
 */

import { promises as fs } from "fs";
import path from "path";

export interface StripeOrderRecord {
  id: string;
  stripeSessionId: string;
  paymentStatus: string;
  amountTotal: number | null;
  currency: string | null;
  customerEmail: string | null;
  userId: string | null;
  createdAt: string;
  raw?: unknown;
}

interface OrderDb {
  version: 1;
  orders: StripeOrderRecord[];
}

const ROOT = path.join(process.cwd(), "data");
const FILE = path.join(ROOT, "stripe-orders.json");

async function load(): Promise<OrderDb> {
  await fs.mkdir(ROOT, { recursive: true });
  try {
    const raw = await fs.readFile(FILE, "utf8");
    const parsed = JSON.parse(raw) as OrderDb;
    return parsed.orders ? parsed : { version: 1, orders: [] };
  } catch {
    return { version: 1, orders: [] };
  }
}

async function save(db: OrderDb): Promise<void> {
  await fs.mkdir(ROOT, { recursive: true });
  await fs.writeFile(FILE, JSON.stringify(db, null, 2), "utf8");
}

export async function recordStripeOrder(
  order: Omit<StripeOrderRecord, "id" | "createdAt"> & {
    id?: string;
    createdAt?: string;
  }
): Promise<StripeOrderRecord> {
  const db = await load();
  const existing = db.orders.find(
    (o) => o.stripeSessionId === order.stripeSessionId
  );
  if (existing) return existing;

  const full: StripeOrderRecord = {
    id: order.id ?? `ord_${Date.now().toString(36)}`,
    stripeSessionId: order.stripeSessionId,
    paymentStatus: order.paymentStatus,
    amountTotal: order.amountTotal,
    currency: order.currency,
    customerEmail: order.customerEmail,
    userId: order.userId,
    createdAt: order.createdAt ?? new Date().toISOString(),
    raw: order.raw,
  };
  db.orders.unshift(full);
  db.orders = db.orders.slice(0, 200);
  await save(db);
  return full;
}

export async function listStripeOrders(limit = 20): Promise<StripeOrderRecord[]> {
  const db = await load();
  return db.orders.slice(0, limit);
}

export async function findOrderBySession(
  sessionId: string
): Promise<StripeOrderRecord | null> {
  const db = await load();
  return db.orders.find((o) => o.stripeSessionId === sessionId) ?? null;
}
