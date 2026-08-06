/**
 * Passwort-Hashing (bcrypt) — Server-only
 */
import bcrypt from "bcryptjs";

const ROUNDS = 12;

export async function hashPassword(plain: string): Promise<string> {
  return bcrypt.hash(plain, ROUNDS);
}

export async function verifyPassword(
  plain: string,
  hash: string
): Promise<boolean> {
  return bcrypt.compare(plain, hash);
}

export function assertPasswordPolicy(plain: string): string | null {
  if (plain.length < 8) return "Mindestens 8 Zeichen.";
  if (!/[A-Za-z]/.test(plain) || !/[0-9]/.test(plain)) {
    return "Passwort braucht Buchstaben und Ziffern.";
  }
  return null;
}
