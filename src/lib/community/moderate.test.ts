/**
 * npx tsx src/lib/community/moderate.test.ts
 */
import assert from "node:assert/strict";
import {
  applyTextRules,
  parseAiVerdict,
  decideModeration,
} from "./moderate";

assert.equal(applyTextRules("Schöne Tour am Neckar"), null);

const hate = applyTextRules("du hurensohn");
assert.equal(hate?.action, "rejected");
assert.equal(hate?.source, "rule");

const spam = applyTextRules("http://a.com http://b.com http://c.com http://d.com");
assert.equal(spam?.labels.includes("spam"), true);

const parsed = parseAiVerdict(
  'Hier: {"action":"approved","confidence":0.96,"labels":["ok"],"note":"sachlich"}'
);
assert.equal(parsed?.action, "approved");
assert.equal(parsed?.confidence, 0.96);

const auto = decideModeration("review", null, parsed, "grok-3-mini");
assert.equal(auto.action, "approved");
assert.equal(auto.source, "ai");

const photoOk = decideModeration("photo", null, parsed, "grok-2-vision-1212");
assert.equal(photoOk.action, "pending", "Fotos nie auto-approve");

const placeOk = decideModeration("place", null, parsed, "grok-3-mini");
assert.equal(placeOk.action, "pending", "User-Orte nie auto-approve");

const aiReject = decideModeration(
  "review",
  null,
  {
    action: "rejected",
    confidence: 0.91,
    labels: ["hate"],
    note: "Hass",
  },
  "grok-3-mini"
);
assert.equal(aiReject.action, "rejected");

const unsure = decideModeration(
  "review",
  null,
  { action: "review", confidence: 0.4, labels: [], note: "?" },
  "grok-3-mini"
);
assert.equal(unsure.action, "pending");

console.log("moderate.test.ts ok");
