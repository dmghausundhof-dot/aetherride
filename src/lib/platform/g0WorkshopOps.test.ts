/**
 * G-0 Workshop Ops — Einladung/Runbook bereit, Gate offen.
 */
import {
  G0_FACILITATOR_RUNBOOK,
  G0_PREREAD_CHECKLIST,
  G0_WORKSHOP_META,
  renderG0FacilitatorRunbookMarkdown,
  renderG0WorkshopIcsStub,
  renderG0WorkshopInviteText,
} from "./g0WorkshopOps";
import { G0_MOBILE_STACK_CONFIRMED } from "./g0TeamSetup";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

assert(G0_MOBILE_STACK_CONFIRMED === false, "gate open");
assert(G0_WORKSHOP_META.suggestedDurationMin >= 60, "duration");
assert(G0_PREREAD_CHECKLIST.length >= 5, "preread");
assert(G0_FACILITATOR_RUNBOOK.length >= 5, "runbook");

const invite = renderG0WorkshopInviteText();
assert(invite.includes("G-0"), "invite title");
assert(invite.includes("kein Auto-Calendar"), "manual");
assert(invite.includes("info@dmgservice.org"), "sender");

const ics = renderG0WorkshopIcsStub({ dtStartLocal: "20260901T100000" });
assert(ics.includes("BEGIN:VEVENT"), "ics event");
assert(ics.includes("TZID=Europe/Berlin"), "tz");

const runbook = renderG0FacilitatorRunbookMarkdown();
assert(runbook.includes("Facilitator"), "runbook title");
assert(runbook.includes("Gegenanzeige"), "gegenanzeige");
assert(runbook.includes("g0TeamSetup"), "closure");

console.log("g0WorkshopOps.test OK", {
  agendaLinked: G0_FACILITATOR_RUNBOOK.length,
  inviteChars: invite.length,
});
