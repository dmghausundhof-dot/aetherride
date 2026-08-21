/**
 * Run: npx tsx src/lib/community/rideGroupCreateTime.test.ts
 */
import assert from "node:assert/strict";
import {
  createStartMax,
  defaultCustomStart,
  formatCreateCustomStartChip,
  parseCreateDurationHours,
  resolveCreateWindow,
  startFromPreset,
  startOfLocalDay,
  toDateTimeLocalValue,
} from "./rideGroupCreateTime";

const now = new Date("2026-08-19T09:30:00+02:00");

function testPresets() {
  assert.equal(startFromPreset("now", now).getTime(), now.getTime());
  assert.equal(
    startFromPreset("1h", now).getTime(),
    now.getTime() + 60 * 60 * 1000,
  );
  const today18 = startFromPreset("18", now);
  assert.equal(today18.getHours(), 18);
  assert.equal(today18.getDate(), 19);
  const after18 = startFromPreset("18", new Date("2026-08-19T19:00:00+02:00"));
  assert.equal(after18.getDate(), 20);
  assert.equal(after18.getHours(), 18);
  const ten = startFromPreset("10", now);
  assert.equal(ten.getDate(), 20);
  assert.equal(ten.getHours(), 10);
  assert.equal(ten.getMinutes(), 0);
}

function testCustomChipAndLocal() {
  const d = new Date(2026, 7, 20, 10, 5);
  assert.equal(formatCreateCustomStartChip(d), "20.08. 10:05");
  assert.equal(toDateTimeLocalValue(d), "2026-08-20T10:05");
  assert.equal(startOfLocalDay(now).getHours(), 0);
  assert.equal(
    defaultCustomStart(now).getTime(),
    now.getTime() + 60 * 60 * 1000,
  );
}

function testDurationParse() {
  assert.equal(parseCreateDurationHours("1,5"), 1.5);
  assert.equal(parseCreateDurationHours("0.25"), 0.25);
  assert.equal(parseCreateDurationHours(" 12 "), 12);
  assert.equal(parseCreateDurationHours(""), null);
  assert.equal(parseCreateDurationHours("x"), null);
}

function testWindowCaps() {
  const ok3 = resolveCreateWindow({
    startPreset: "now",
    durationIsCustom: false,
    durationH: 3,
    now,
  });
  assert.ok(!("error" in ok3));
  if (!("error" in ok3)) {
    assert.equal(ok3.durationHours, 3);
    assert.equal(ok3.status, "open");
  }

  const half = resolveCreateWindow({
    startPreset: "custom",
    customStartLocal: toDateTimeLocalValue(
      new Date("2026-08-19T10:00:00+02:00"),
    ),
    durationIsCustom: true,
    durationH: 3,
    durationCustomRaw: "0,25",
    now,
  });
  assert.ok(!("error" in half));
  if (!("error" in half)) assert.equal(half.durationHours, 0.25);

  assert.equal(
    "error" in
      resolveCreateWindow({
        startPreset: "now",
        durationIsCustom: true,
        durationH: 3,
        durationCustomRaw: "0,1",
        now,
      }),
    true,
  );
  assert.equal(
    "error" in
      resolveCreateWindow({
        startPreset: "now",
        durationIsCustom: true,
        durationH: 3,
        durationCustomRaw: "13",
        now,
      }),
    true,
  );
  assert.equal(
    "error" in
      resolveCreateWindow({
        startPreset: "now",
        durationIsCustom: true,
        durationH: 3,
        durationCustomRaw: "",
        now,
      }),
    true,
  );

  const in14 = resolveCreateWindow({
    startPreset: "custom",
    customStartLocal: toDateTimeLocalValue(
      new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000),
    ),
    durationIsCustom: false,
    durationH: 3,
    now,
  });
  assert.ok(!("error" in in14), "Start genau 14 Tage muss gehen");

  const over = resolveCreateWindow({
    startPreset: "custom",
    customStartLocal: toDateTimeLocalValue(
      new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000 + 60 * 60 * 1000),
    ),
    durationIsCustom: false,
    durationH: 3,
    now,
  });
  assert.ok("error" in over);
  if ("error" in over) assert.equal(over.error, "startsAt_too_far");

  const max = createStartMax(now);
  assert.equal(max.getTime() - now.getTime(), 14 * 24 * 60 * 60 * 1000);
}

function testPresetWindow() {
  const in1h = resolveCreateWindow({
    startPreset: "1h",
    durationIsCustom: false,
    durationH: 2,
    now,
  });
  assert.ok(!("error" in in1h));
  if (!("error" in in1h)) {
    assert.equal(in1h.status, "scheduled");
    assert.equal(in1h.durationHours, 2);
    assert.equal(in1h.start.getTime(), now.getTime() + 60 * 60 * 1000);
  }
}

testPresets();
testCustomChipAndLocal();
testDurationParse();
testWindowCaps();
testPresetWindow();
console.log("rideGroupCreateTime.test.ts OK");
