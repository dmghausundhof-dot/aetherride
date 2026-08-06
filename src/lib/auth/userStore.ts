/**
 * Serverseitiger User-Store (File → später Postgres)
 * Nur in Node/Server Components / Route Handlers nutzen.
 */

import { promises as fs } from "fs";
import path from "path";
import { randomUUID } from "crypto";
import { hashPassword, verifyPassword } from "./password";

export interface StoredUser {
  id: string;
  email: string;
  displayName: string;
  passwordHash: string;
  provider: "email";
  createdAt: string;
  updatedAt: string;
  /** Soft-delete / DSGVO */
  deletedAt?: string | null;
}

interface UserDb {
  version: 1;
  users: StoredUser[];
}

const DATA_DIR = path.join(process.cwd(), "data");
const USERS_FILE = path.join(DATA_DIR, "users.json");

async function ensureDb(): Promise<UserDb> {
  await fs.mkdir(DATA_DIR, { recursive: true });
  try {
    const raw = await fs.readFile(USERS_FILE, "utf8");
    const parsed = JSON.parse(raw) as UserDb;
    if (!parsed.users) return { version: 1, users: [] };
    return parsed;
  } catch {
    const empty: UserDb = { version: 1, users: [] };
    await fs.writeFile(USERS_FILE, JSON.stringify(empty, null, 2), "utf8");
    return empty;
  }
}

async function saveDb(db: UserDb): Promise<void> {
  await fs.mkdir(DATA_DIR, { recursive: true });
  await fs.writeFile(USERS_FILE, JSON.stringify(db, null, 2), "utf8");
}

export function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

export async function findUserByEmail(
  email: string
): Promise<StoredUser | null> {
  const db = await ensureDb();
  const e = normalizeEmail(email);
  return (
    db.users.find((u) => u.email === e && !u.deletedAt) ?? null
  );
}

export async function findUserById(id: string): Promise<StoredUser | null> {
  const db = await ensureDb();
  return db.users.find((u) => u.id === id && !u.deletedAt) ?? null;
}

export async function createEmailUser(input: {
  email: string;
  password: string;
  displayName?: string;
}): Promise<StoredUser> {
  const email = normalizeEmail(input.email);
  const existing = await findUserByEmail(email);
  if (existing) {
    throw new Error("EMAIL_TAKEN");
  }
  const now = new Date().toISOString();
  const user: StoredUser = {
    id: `usr_${randomUUID().replace(/-/g, "").slice(0, 16)}`,
    email,
    displayName:
      input.displayName?.trim() || email.split("@")[0] || "Fahrer",
    passwordHash: await hashPassword(input.password),
    provider: "email",
    createdAt: now,
    updatedAt: now,
    deletedAt: null,
  };
  const db = await ensureDb();
  db.users.push(user);
  await saveDb(db);
  return user;
}

export async function authenticateEmail(
  email: string,
  password: string
): Promise<StoredUser | null> {
  const user = await findUserByEmail(email);
  if (!user) return null;
  const ok = await verifyPassword(password, user.passwordHash);
  return ok ? user : null;
}

export function publicUser(u: StoredUser) {
  return {
    id: u.id,
    email: u.email,
    displayName: u.displayName,
    provider: u.provider as "email",
    createdAt: u.createdAt,
  };
}
