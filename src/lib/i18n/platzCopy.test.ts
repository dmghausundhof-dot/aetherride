/**
 * Run: npx tsx src/lib/i18n/platzCopy.test.ts
 */
import assert from "node:assert/strict";
import {
  formatPlatzGroupWhen,
  platzCopy,
  platzNote,
  platzShareHonesty,
} from "./platzCopy";

const langs = ["de", "en", "fr", "it", "nl"] as const;

function testDe() {
  const g = platzCopy("de");
  assert.equal(g.createGroup, "Gruppe anlegen");
  assert.equal(g.pickMine, "Meine Touren");
  assert.equal(g.pickNearby, "Touren in der Nähe");
  assert.ok(g.nearbyNeedGps.includes("Standort"));
  assert.ok(g.nearbyFromMap.includes("Karte"));
  assert.equal(g.groupCreateReady, "Tour liegt bereit — Gruppe anlegen.");
  assert.equal(g.planAsGroup, "Eigene Tour als Gruppe planen");
  assert.equal(g.needSharedTour, "Zuerst eine Tour wählen oder selbst planen.");
  assert.equal(g.stimmenTitle, "Stimmen");
  assert.equal(g.stimmeUntitled, "Stimme");
  assert.equal(g.visPublic, "Freigegeben");
  assert.equal(g.addRoute, "Route hinzufügen");
  assert.ok(g.addRouteHint.includes("ohne Pin"));
  assert.equal(g.keepRoute, "Merken");
  assert.equal(g.keepName, "Nur den Namen merken");
  assert.equal(g.renameTour, "Umbenennen");
  assert.equal(g.lastRidden("12.8."), "zuletzt 12.8.");
  assert.equal(g.inviteFriends, "Freunde mitnehmen");
  assert.ok(g.startNone.includes("ohne Pin"));
  assert.ok(!g.addRouteHint.toLowerCase().includes("heidelberg"));
  assert.equal(g.intoMappe, "In die Mappe legen");
  assert.equal(g.showAll, "Alle zeigen");
  assert.equal(g.keepOnMap, "Auf der Karte merken");
  assert.equal(g.noTrackLabel, "Kein Track");
  assert.equal(g.loopTag, "Runde");
  assert.ok(g.inviteHint.includes("Freunde"));
  assert.ok(g.inviteHint.includes("Deine Gruppen bleiben"));
  assert.equal(g.collectionTours(1), "1 Tour");
  assert.equal(g.collectionTours(2), "2 Touren");
  assert.equal(g.collectionsTitle, "Sammlungen");
  assert.equal(g.stimmenTitle, "Stimmen");
  assert.notEqual(g.collectionsTitle, g.collectionsTitle.toUpperCase());
  assert.equal(g.joinWithLink, "Verbinden");
  assert.equal(g.copyCode, "Code kopieren");
  assert.equal(g.joinLocalCta, "Auf diesem Gerät merken");
  assert.ok(g.joinUnsignedHint.includes("sieht der Gastgeber dich nicht"));
  assert.ok(!g.joinUnsignedHint.includes("Host"));
  assert.ok(!g.joinNotOnServer("x").includes("Dabei"));
  assert.ok(!g.honestyCatalog.includes("öffentlich"));
  assert.ok(!g.honestyCatalog.includes("Akte"));
  assert.ok(g.shareVisPrivate.includes("gelistet"));
  assert.equal(g.visibility, "Freigabe");
  assert.ok(g.pinsHint.includes("öffentlichen Karte"));
  assert.equal(g.friendN(1), "Freund 1");
  assert.equal(g.extendHour, "Fenster verlängern");
  assert.equal(g.extend30m, "+30 Min");
  assert.equal(g.host, "Gastgeber");
  assert.equal(g.guest, "Gast");
  assert.equal(g.startCustom, "Andere Zeit…");
  assert.equal(g.durationCustom, "Andere…");
  assert.ok(g.windowCapHint.includes("14"));
  assert.ok(g.windowCapHint.includes("12"));
  assert.equal(platzNote("Fenster verlängert.", "en"), "Window extended.");
  assert.equal(g.shareInRide, "Teilen in der Fahrt");
  assert.ok(g.joinPrivateCode.includes("Einladungslink"));
  assert.equal(
    platzNote("Fenster zu — der Link gilt nicht mehr.", "en"),
    platzCopy("en").joinExpired,
  );
  assert.equal(
    platzNote("Gruppe ist aufgelöst.", "en"),
    platzCopy("en").joinClosed,
  );
  assert.equal(
    platzNote("Anmelden — sonst sieht der Host dich nicht.", "en"),
    platzCopy("en").joinSignInFirst,
  );
  assert.equal(
    platzNote("Anmelden — sonst sieht der Gastgeber dich nicht.", "en"),
    platzCopy("en").joinSignInFirst,
  );
  assert.equal(
    platzNote("Kein offener Link. Ohne Login gilt nur dieser Speicher; sonst den Einladungslink einfügen.", "en"),
    platzCopy("en").joinUnknown,
  );
  assert.equal(g.joinField, "Link oder 6-stelliger Code");
  assert.equal(g.joinSignInFirst, "Anmelden — sonst sieht der Gastgeber dich nicht");
  assert.ok(g.joinExpired.includes("Fenster"));
  assert.ok(g.joinClosed.includes("aufgelöst"));
  assert.equal(g.more, "Mehr");
  assert.equal(g.joinCodeField, "Code");
  assert.ok(g.joinHint.includes("Einladungslink"));
  assert.ok(g.joinHint.includes("Code"));
  assert.ok(!g.joinHint.toLowerCase().includes("token"));
  assert.ok(g.listedNote.includes("Code"));
  const listedOld =
    "Auf dem Platz gelistet — wer den Link hat, kann beitreten.";
  assert.ok(platzNote(listedOld, "en").toLowerCase().includes("listed"));
  assert.ok(
    platzNote("Auf dem Platz gelistet — Link oder Code reicht.", "en")
      .toLowerCase()
      .includes("code"),
  );
  assert.ok(g.collectionsHint.includes("Katalog"));
}

function testParity() {
  const de = platzCopy("de");
  for (const lang of langs) {
    const g = platzCopy(lang);
    assert.equal(g.stimmenTitle, "Stimmen", lang);
    assert.ok(
      /profi[e]?l/.test(g.shareProfile("https://x").toLowerCase()),
      lang,
    );
    assert.ok(g.created("x").includes("x"), lang);
    assert.ok(g.collectionTours(3).includes("3"), lang);
    assert.notEqual(g.collectionTours(1), g.collectionTours(2), lang);
    assert.ok(g.addToCollection.length > 0, lang);
    assert.ok(g.intoMappe.includes("Mappe"), lang);
    assert.ok(g.mappeEmptyTitle.length > 4, lang);
    assert.ok(g.noTrackLabel.length > 3, lang);
    assert.ok(g.loopTag.length > 2, lang);
    assert.ok(g.startNone.length > 8, lang);
    assert.ok(g.startFromGps("1").includes("1"), lang);
    assert.ok(g.startFromMap("1").includes("1"), lang);
    assert.ok(g.importGpx.includes("GPX"), lang);
    assert.ok(g.showAll.length > 3, lang);
    assert.ok(g.keepOnMap.length > 4, lang);
    assert.ok(g.showOnMap.length > 3, lang);
    assert.ok(g.nearbyNeedGps.length > 8, lang);
    assert.ok(g.nearbyFromMap.length > 8, lang);
    assert.ok(g.groupCreateReady.length > 8, lang);
    assert.ok(g.notePlaceholder.includes("Stimme"), lang);
    assert.ok(!/\b(token|jeton)\b/i.test(g.joinHint), lang);
  }
  assert.ok(platzCopy("en").joinHint.includes("invitation link"));
  assert.ok(platzCopy("fr").joinHint.includes("lien d’invitation"));
  assert.ok(platzCopy("it").joinHint.includes("link di invito"));
  assert.equal(platzCopy("fr").host, "Hôte");
  assert.equal(platzCopy("it").host, "Organizzatore");
  assert.equal(platzCopy("en").host, "Host");
  assert.notEqual(de.inviteHint, platzCopy("en").inviteHint);
}

function testNotes() {
  const de =
    "Nicht eingeloggt — nur auf diesem Gerät. Join auf dem Server braucht Login.";
  assert.equal(platzNote(de, "de"), de);
  assert.ok(platzNote(de, "en").toLowerCase().includes("signed"));
  assert.equal(platzNote("unknown-de-error", "fr"), "unknown-de-error");
  const listed =
    "Auf dem Platz gelistet — wer den Link hat, kann beitreten.";
  assert.ok(platzNote(listed, "en").toLowerCase().includes("listed"));
}

function testWhen() {
  const start = new Date("2026-08-16T10:00:00+02:00");
  const end = new Date("2026-08-16T13:00:00+02:00");
  const now = new Date("2026-08-16T09:00:00+02:00");
  const de = formatPlatzGroupWhen(
    start.toISOString(),
    end.toISOString(),
    "de",
    now,
  );
  const en = formatPlatzGroupWhen(
    start.toISOString(),
    end.toISOString(),
    "en",
    now,
  );
  assert.ok(de.includes("heute"), de);
  assert.ok(en.includes("today"), en);
  assert.ok(de.includes("h"), de);
  assert.ok(en.includes("h"), en);
  assert.notEqual(de, en);
  const half = formatPlatzGroupWhen(
    start.toISOString(),
    new Date("2026-08-16T11:30:00+02:00").toISOString(),
    "de",
    now,
  );
  assert.ok(half.includes("1,5 h"), half);
  const halfEn = formatPlatzGroupWhen(
    start.toISOString(),
    new Date("2026-08-16T13:30:00+02:00").toISOString(),
    "en",
    now,
  );
  assert.ok(halfEn.includes("3.5 h"), halfEn);
  const quarter = formatPlatzGroupWhen(
    start.toISOString(),
    new Date("2026-08-16T10:15:00+02:00").toISOString(),
    "de",
    now,
  );
  assert.ok(quarter.includes("15 Min"), quarter);
  assert.ok(!quarter.includes("0,3"), quarter);
}

function testHonesty() {
  const de = platzShareHonesty(true, false, "de");
  const en = platzShareHonesty(true, false, "en");
  assert.ok(de.includes("Katalog"));
  assert.ok(en.toLowerCase().includes("catalogue"));
  assert.notEqual(de, en);
}

testDe();
testParity();
testNotes();
testWhen();
testHonesty();
console.log("platzCopy.test.ts OK");
