/**
 * Stripe checkout plan — no fake payment
 */
import { buildMarketplaceDraft } from "./marketplace";
import {
  isStripeDemandDocumented,
  planStripeCheckout,
  stripeEnvPresent,
} from "./stripeCheckout";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

const draft = buildMarketplaceDraft([
  { name: "Pads", priceEur: 40, qty: 1 },
]);

const blocked = planStripeCheckout(draft, { demandDocumented: false });
assert(blocked.status === "blocked_no_demand", "demand gate");
assert(blocked.sessionCreateShape == null, "no session");
assert(blocked.demandDocumented === false, "demand flag");

const withDemand = planStripeCheckout(draft, { demandDocumented: true });
if (!stripeEnvPresent().secret) {
  assert(withDemand.status === "not_configured", "no key");
  assert(withDemand.sessionCreateShape == null, "no fake session");
} else {
  assert(withDemand.status === "session_ready", "ready with key");
  assert(!!withDemand.sessionCreateShape, "shape present");
}

// Env default ohne Flag
assert(
  typeof isStripeDemandDocumented() === "boolean",
  "demand helper"
);

console.log("stripeCheckout.test OK", {
  blocked: blocked.status,
  withDemand: withDemand.status,
  demandEnv: isStripeDemandDocumented(),
});
