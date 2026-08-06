/**
 * Auth password + policy tests
 */
import {
  assertPasswordPolicy,
  hashPassword,
  verifyPassword,
} from "./password";
import { normalizeEmail } from "./userStore";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

async function main() {
  assert(assertPasswordPolicy("short") != null, "too short");
  assert(assertPasswordPolicy("onlyletters") != null, "need digit");
  assert(assertPasswordPolicy("abc12345") == null, "ok policy");

  const hash = await hashPassword("Secure9pass");
  assert(hash.startsWith("$2"), "bcrypt");
  assert(await verifyPassword("Secure9pass", hash), "verify ok");
  assert(!(await verifyPassword("wrong", hash)), "verify fail");
  assert(normalizeEmail("  A@B.De ") === "a@b.de", "email norm");

  console.log("auth.password.test OK");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
