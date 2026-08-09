/**
 * Demo-/Seed-Inhalte nur außerhalb Production.
 * - Production: fail-closed (leer / kein Fake-Routing)
 * - Development/Test: an (abschalten mit ALLOW_DEMO_CONTENT=false)
 * - Explizit an: ALLOW_DEMO_CONTENT=true
 */
export function allowDemoContent(): boolean {
  if (process.env.ALLOW_DEMO_CONTENT === "true") return true;
  if (process.env.ALLOW_DEMO_CONTENT === "false") return false;
  return process.env.NODE_ENV !== "production";
}
