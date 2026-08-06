/**
 * G-0 Workshop-Pack — Agenda bereit, Gate offen.
 */
import {
  G0_WORKSHOP_AGENDA,
  G0_WORKSHOP_PARTICIPANTS,
  G0_WORKSHOP_PROTOCOL,
  g0WorkshopStatusSummary,
  renderG0WorkshopPackMarkdown,
} from "./g0Workshop";
import { G0_MOBILE_STACK_CONFIRMED, isG0Closed } from "./g0TeamSetup";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

assert(G0_MOBILE_STACK_CONFIRMED === false, "g0 open");
assert(!isG0Closed(), "not closed");
assert(G0_WORKSHOP_AGENDA.length >= 5, "agenda");
assert(G0_WORKSHOP_PARTICIPANTS.some((p) => p.role.includes("Sensor")), "sensor role");
assert(G0_WORKSHOP_PROTOCOL.protocolFinalized === false, "not finalized");
assert(G0_WORKSHOP_PROTOCOL.chosenStack === "undecided", "undecided");
const md = renderG0WorkshopPackMarkdown();
assert(md.includes("Decision-Workshop"), "title");
assert(md.includes("Gegenanzeige"), "gegenanzeige");
assert(md.includes("Protokollvorlage"), "protocol");
assert(md.includes("sensor_core"), "matrix");
assert(g0WorkshopStatusSummary().includes("Workshop") || g0WorkshopStatusSummary().includes("Go"), "summary");

console.log("g0Workshop.test OK", {
  agendaItems: G0_WORKSHOP_AGENDA.length,
  mdChars: md.length,
});
