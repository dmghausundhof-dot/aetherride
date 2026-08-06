/**
 * Server-Client (Route Handlers / Server Components)
 */

import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import {
  getSupabaseAnonKey,
  getSupabaseUrl,
  isSupabaseConfigured,
} from "./config";

export async function createSupabaseServerClient() {
  if (!isSupabaseConfigured()) {
    throw new Error("Supabase nicht konfiguriert (URL/Anon-Key fehlen).");
  }
  const cookieStore = await cookies();
  return createServerClient(getSupabaseUrl()!, getSupabaseAnonKey()!, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet) {
        try {
          cookiesToSet.forEach(({ name, value, options }) => {
            cookieStore.set(name, value, options);
          });
        } catch {
          // Server Component ohne mutable cookies — Middleware refreshed Session
        }
      },
    },
  });
}
