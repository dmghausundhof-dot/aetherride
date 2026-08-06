/**
 * Professionelle Roadmap (F-ACC → Marktreife)
 * Gates G-0/G-1/G-2/G-5/A-06/A-08 bleiben ehrlich offen.
 *
 * 1–3 ✅ Auth + Sync LWW + Supabase E-Mail
 * 4 ✅ Postgres-Adapter (Supabase) + SQL-Migration — Env/Migration nötig
 * 5 Stripe · 6 G-4 · 7 Native Offline · 8 Legal · 9 OAuth zum Schluss
 */

export const PROFESSIONAL_ROADMAP_STEPS = [
  {
    id: 1,
    titleDe: "Benutzer-Login (E-Mail/Passwort + Session)",
    status: "done" as const,
  },
  {
    id: 2,
    titleDe: "Authentifizierter Sync + LWW + User-Ops-Store",
    status: "done" as const,
  },
  {
    id: 3,
    titleDe: "Supabase E-Mail/Passwort (OAuth vorbereitet, später)",
    status: "done" as const,
  },
  {
    id: 4,
    titleDe: "Persistenz Postgres (Supabase profiles + sync_*)",
    status: "done" as const,
  },
  {
    id: 5,
    titleDe: "Stripe Marketplace (bei Nachfrage)",
    status: "in_progress" as const,
  },
  {
    id: 6,
    titleDe: "G-4 Katalog ≥ Spec",
    status: "planned" as const,
  },
  {
    id: 7,
    titleDe: "Native Offline-PMTiles (nach G-0)",
    status: "planned" as const,
  },
  {
    id: 8,
    titleDe: "Legal/Gate Sign-offs",
    status: "planned" as const,
  },
  {
    id: 9,
    titleDe: "OAuth Google/Apple (zum Schluss)",
    status: "planned" as const,
  },
] as const;
