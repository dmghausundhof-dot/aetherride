/**
 * Stripe checkout plan — no fake payment
 */
import { buildMarketplaceDraft } from "./marketplace";
import { planStripeCheckout } from "./stripeCheckout";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

const draft = buildMarketplaceDraft([
  { name: "Pads", priceEur: 40, qty: 1 },
]);
const blocked = planStripeCheckout(draft, { demandDocumented: false });
assert(blocked.status === "blocked_no_demand", "demand gate");
assert(blocked.sessionCreateShape == null, "no session");

const noKey = planStripeCheckout(draft, { demandDocumented: true });
assert(
  noKey.status === "not_configured" || noKey.status === "session_ready_shape",
  "configured or not"
);
if (!noKey.hasSecretKey) {
  assert(noKey.status === "not_configured", "no key");
  assert(noKey.sessionCreateShape == null, "no fake session");
}

console.log("stripeCheckout.test OK", { blocked: blocked.status });
