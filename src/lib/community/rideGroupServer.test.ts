/**
 * npx tsx src/lib/community/rideGroupServer.test.ts
 */
import assert from "node:assert/strict";
import {
  isMissingRideGroupTable,
  isRideGroupId,
  labelsByUserId,
  parsePresenceVisibility,
  profileDisplayLabel,
  rowToMember,
  rowToPresence,
  rowToRideGroup,
} from "./rideGroupServer";

assert.equal(profileDisplayLabel(null), "");
assert.equal(profileDisplayLabel({ enabled: false, display_name: "Luka" }), "");
assert.equal(
  profileDisplayLabel({ enabled: true, display_name: "Luka", handle: "luka" }),
  "Luka"
);
assert.equal(
  profileDisplayLabel({ enabled: true, display_name: "", handle: "luka" }),
  "@luka"
);
assert.equal(profileDisplayLabel({ enabled: true, display_name: "  " }), "");

const labels = labelsByUserId([
  { user_id: "u1", enabled: true, display_name: "Ada", handle: "ada" },
  { user_id: "u2", enabled: false, display_name: "Geheim" },
]);
assert.equal(labels.get("u1"), "Ada");
assert.equal(labels.get("u2"), "");

assert.equal(isMissingRideGroupTable({ code: "42P01" }), true);
assert.equal(
  isMissingRideGroupTable({ message: "relation ride_groups does not exist" }),
  true
);
assert.equal(isMissingRideGroupTable({ code: "42501" }), false);

const g = rowToRideGroup({
  id: "11111111-1111-1111-1111-111111111111",
  host_user_id: "host-1",
  saved_route_id: "r-bodensee-road",
  catalog_tour_id: "r-bodensee-road",
  title: "Bodensee",
  start_window_start: "2026-08-15T08:00:00.000Z",
  start_window_end: "2026-08-15T12:00:00.000Z",
  join_code: "K7M2NP",
  status: "open",
  live_pins_allowed: true,
  created_at: "2026-08-15T08:00:00.000Z",
});
assert.equal(g.onServer, true);
assert.equal(g.joinCode, "K7M2NP");
assert.equal(g.visibility, "private");
assert.equal(g.catalogTourId, "r-bodensee-road");

const m = rowToMember(
  {
    group_id: g.id,
    user_id: "u1",
    joined_at: "2026-08-15T08:00:00.000Z",
    live_opt_in: false,
  },
  ""
);
assert.equal(m.displayLabel, "");
assert.equal(m.userId, "u1");

assert.equal(isRideGroupId(g.id), true);
assert.equal(isRideGroupId("nope"), false);
assert.equal(parsePresenceVisibility("hidden_opt_out"), "hidden_opt_out");
assert.equal(parsePresenceVisibility("nope"), "hidden_offline");

const pin = rowToPresence({
  group_id: g.id,
  user_id: "u1",
  lat: 49.4,
  lng: 8.7,
  updated_at: "2026-08-16T08:00:00.000Z",
  visibility: "live",
});
assert.equal(pin.lat, 49.4);
assert.equal(pin.visibility, "live");
const hidden = rowToPresence({
  group_id: g.id,
  user_id: "u1",
  lat: 49.4,
  lng: 8.7,
  updated_at: "2026-08-16T08:00:00.000Z",
  visibility: "hidden_opt_out",
});
assert.equal(hidden.lat, undefined);

console.log("rideGroupServer ok");
