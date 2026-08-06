/**
 * Professionelle Roadmap (F-ACC → Marktreife)
 * Schrittweise — Gates G-0/G-1/G-2/G-5/A-06/A-08 bleiben ehrlich offen.
 *
 * 1. ✅ Auth: E-Mail/Passwort + HTTP-only Session (dieser Slice)
 * 2. Sync: Ops an authentifizierten /api/sync + User-scoped Persistenz
 * 3. OAuth Apple/Google (Env-Keys nötig)
 * 4. Postgres statt File-User-Store
 * 5. Stripe Checkout (Demand + Keys)
 * 6. G-4 Katalog-Skalierung
 * 7. Native Offline (nach G-0)
 * 8. Legal/Gate Sign-offs (Mensch)
 */

export const PROFESSIONAL_ROADMAP_STEPS = [
  {
    id: 1,
    titleDe: "Benutzer-Login (E-Mail/Passwort + Session-Cookie)",
    status: "done" as const,
  },
  {
    id: 2,
    titleDe: "Authentifizierter Sync + serverseitige Ops",
    status: "in_progress" as const,
  },
  {
    id: 3,
    titleDe: "OAuth Apple/Google",
    status: "planned" as const,
  },
  {
    id: 4,
    titleDe: "Persistenz Postgres / Timescale",
    status: "planned" as const,
  },
  {
    id: 5,
    titleDe: "Stripe Marketplace (bei Nachfrage)",
    status: "planned" as const,
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
] as const;
