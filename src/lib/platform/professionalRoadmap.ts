/**
 * Professionelle Roadmap (F-ACC → Marktreife)
 * Gates G-0/G-1/G-2/G-5/A-06/A-08 bleiben ehrlich offen.
 * G-4 Mengen-Ziel erreicht. Offline-PMTiles: Prep done, Download nach G-0.
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
    titleDe: "Stripe Checkout (Demand-Gate + Session/Webhook)",
    status: "done" as const,
  },
  {
    id: 6,
    titleDe: "G-4 Katalog ≥ 3000 Komponentenmodelle",
    status: "done" as const,
  },
  {
    id: 7,
    titleDe: "Offline-PMTiles Prep (Download blockiert bis G-0)",
    status: "done" as const,
  },
  {
    id: 8,
    titleDe: "Legal/Gate Sign-offs",
    status: "in_progress" as const,
  },
  {
    id: 9,
    titleDe: "OAuth Google/Apple (zum Schluss)",
    status: "planned" as const,
  },
] as const;
