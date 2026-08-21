/**
 * Run: npx tsx src/lib/garage/bikeValueStrip.test.ts
 */
import assert from "node:assert/strict";
import {
  formatStripCount,
  formatStripDate,
  planStripService,
} from "./bikeValueStrip";

const labels = {
  appointmentCaption: "Termin",
  careCaption: "Pflege",
  dueNow: "Jetzt",
  dash: "—",
};

assert.equal(formatStripCount(0, "—"), "—");
assert.equal(formatStripCount(-3, "—"), "—");
assert.equal(formatStripCount(1240, "—"), "1240");
assert.equal(formatStripCount(0, "—", 1), "—");
assert.equal(formatStripCount(42.5, "—", 1), "42.5");
assert.equal(formatStripDate("2026-09-12"), "12.09.2026");

const appt = planStripService({
  ...labels,
  appointmentLabel: "12.09.2026",
  intervalStatus: "overdue",
  intervalRemaining: "Kette",
});
assert.equal(appt.kind, "appointment");
assert.equal(appt.caption, "Termin");
assert.equal(appt.value, "12.09.2026");

const overdue = planStripService({
  ...labels,
  intervalStatus: "overdue",
});
assert.equal(overdue.kind, "care");
assert.equal(overdue.caption, "Pflege");
assert.equal(overdue.value, "Jetzt");

const soon = planStripService({
  ...labels,
  intervalStatus: "due_soon",
  intervalRemaining: "180 km · 12 Tage",
});
assert.equal(soon.value, "180 km");
assert.equal(soon.caption, "Pflege");

const empty = planStripService({ ...labels });
assert.equal(empty.kind, "empty");
assert.equal(empty.value, "—");
assert.equal(empty.caption, "Termin");

console.log("bikeValueStrip.test.ts OK");
