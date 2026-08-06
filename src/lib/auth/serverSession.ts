/**
 * HTTP-only JWT Session (F-ACC-001 Produktionsschicht)
 */

import { SignJWT, jwtVerify } from "jose";
import { cookies } from "next/headers";
import type { AuthUser } from "./session";

export const SESSION_COOKIE = "aetherride_session";

const DEFAULT_DEV_SECRET =
  "aetherride-dev-secret-change-me-in-production-32b";

function secretKey() {
  const s =
    process.env.AUTH_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    DEFAULT_DEV_SECRET;
  return new TextEncoder().encode(s);
}

export function isAuthSecretHardened(): boolean {
  const s = process.env.AUTH_SECRET || process.env.NEXTAUTH_SECRET;
  return Boolean(s && s.length >= 32);
}

export interface SessionClaims {
  sub: string;
  email: string;
  displayName: string;
  provider: "email";
}

export async function createSessionToken(
  user: SessionClaims,
  ttlSec = 60 * 60 * 24 * 14
): Promise<string> {
  return new SignJWT({
    email: user.email,
    displayName: user.displayName,
    provider: user.provider,
  })
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(user.sub)
    .setIssuedAt()
    .setExpirationTime(`${ttlSec}s`)
    .sign(secretKey());
}

export async function verifySessionToken(
  token: string
): Promise<SessionClaims | null> {
  try {
    const { payload } = await jwtVerify(token, secretKey());
    if (!payload.sub || typeof payload.email !== "string") return null;
    return {
      sub: payload.sub,
      email: payload.email,
      displayName:
        typeof payload.displayName === "string"
          ? payload.displayName
          : payload.email.split("@")[0],
      provider: "email",
    };
  } catch {
    return null;
  }
}

export async function setSessionCookie(token: string): Promise<void> {
  const jar = await cookies();
  jar.set(SESSION_COOKIE, token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: 60 * 60 * 24 * 14,
  });
}

export async function clearSessionCookie(): Promise<void> {
  const jar = await cookies();
  jar.set(SESSION_COOKIE, "", {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: 0,
  });
}

export async function getSessionFromCookies(): Promise<AuthUser | null> {
  const jar = await cookies();
  const token = jar.get(SESSION_COOKIE)?.value;
  if (!token) return null;
  const claims = await verifySessionToken(token);
  if (!claims) return null;
  return {
    id: claims.sub,
    email: claims.email,
    displayName: claims.displayName,
    provider: "email",
    createdAt: "",
  };
}

export function claimsToAuthUser(c: SessionClaims): AuthUser {
  return {
    id: c.sub,
    email: c.email,
    displayName: c.displayName,
    provider: "email",
    createdAt: "",
  };
}
