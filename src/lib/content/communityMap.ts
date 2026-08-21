/**
 * Community on the website = Platz, not a sixth tab and not a feed.
 * Status is rider-facing: what exists vs what stays out.
 */

export const COMMUNITY_FEATURES: {
  title: string;
  body: string;
  href: string;
  cta: string;
}[] = [
  {
    title: "Platz",
    body: "Die Tür. Mappe, Freigabe, GPX, Stimmen und Gruppen — dieselben Touren wie auf der Karte.",
    href: "/library",
    cta: "Zum Platz",
  },
  {
    title: "Stimmen",
    body: "Kurztext an der Tour, keine Tracks im Kommentar. Neu startet in Prüfung, Editorial ist gekennzeichnet.",
    href: "/tours/r-heidelberg-city",
    cta: "Beispiel-Tour",
  },
  {
    title: "Mappe teilen",
    body: "Sammlung als Link. Wer den Link hat, legt die Touren in die eigene Mappe — ohne Account-Zwang.",
    href: "/share",
    cta: "So teilen",
  },
  {
    title: "Zusammen raus",
    body: "Gruppe mit Einladungslink vor dem Tor. Öffentlich: Treffen-Pin auf der Karte, ohne Live-GPS. Web hält Roster und Einladung. Live-Pins nur im App-HUD, mit Opt-in.",
    href: "/library",
    cta: "Zum Platz",
  },
  {
    title: "Public Profile",
    body: "Nur mit Opt-in. Handle, Sport, optional Anzahl Fahrten — keine GPS-Spuren.",
    href: "/u/mara_road",
    cta: "Beispiel mara_road",
  },
  {
    title: "Events & Clubs",
    body: "Redaktionell auf der Website, nicht in der App. Kein RSVP-Fake, kein Live-Standort-Zwang.",
    href: "/community#events",
    cta: "Termine",
  },
];

export const COMMUNITY_OUT: string[] = [
  "Kein Feed auf dem Hof",
  "Kein Leaderboard, kein Level",
  "Kein Live-GPS auf der Karte vor dem Tor",
  "Ride ist kein Tab",
  "Stimmen ohne Track-Anhang",
];
