/**
 * Browser-Client (Client Components)
 */

import { createBrowserClient } from "@supabase/ssr";
import {
  getSupabaseAnonKey,
  getSupabaseUrl,
  isSupabaseConfigured,
} from "./config";

export function createSupabaseBrowserClient() {
  if (!isSupabaseConfigured()) {
    throw new Error("Supabase nicht konfiguriert (URL/Anon-Key fehlen).");
  }
  return createBrowserClient(getSupabaseUrl()!, getSupabaseAnonKey()!);
}
