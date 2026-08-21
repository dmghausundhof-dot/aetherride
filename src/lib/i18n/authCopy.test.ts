/**
 * Run: npx tsx src/lib/i18n/authCopy.test.ts
 */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { authCopy, presentAuthError } from "./authCopy";

const langs = ["de", "en", "fr", "it", "nl"] as const;

function testParity() {
  const keys = Object.keys(authCopy("de")).sort();
  for (const lang of langs) {
    assert.deepEqual(Object.keys(authCopy(lang)).sort(), keys, lang);
  }
}

function testArb() {
  assert.equal(authCopy("de").signIn, "Anmelden");
  assert.equal(authCopy("en").signIn, "Sign in");
  assert.equal(authCopy("fr").forgot, "Mot de passe oublié ?");
  assert.equal(authCopy("it").register, "Registrati");
  assert.equal(authCopy("nl").resetSent.includes("reset-mail"), true);
  assert.equal(
    presentAuthError("E-Mail und Passwort erforderlich", "en"),
    "Email and password required"
  );
  assert.equal(presentAuthError("other", "en"), "other");
}

function testWiring() {
  const card = readFileSync("src/components/auth/AuthCard.tsx", "utf8");
  assert.ok(card.includes("authCopy"), "AuthCard uses copy");
  assert.ok(card.includes("presentAuthError"), "AuthCard maps API German keys");
  assert.ok(card.includes("{a.forgot}"), "forgot is copy");
  assert.ok(card.includes("{a.register}"), "register button is copy");
}

testParity();
testArb();
testWiring();
console.log("authCopy.test.ts OK");
