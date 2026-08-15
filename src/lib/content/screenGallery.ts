/**
 * Product screens from Logo und Bilder — mapped to Hof doors.
 * Mockups may show English/light UI; captions stay in the real IA.
 */

export const SCREEN_GALLERY: {
  src: string;
  alt: string;
  title: string;
  door: string;
  note: string;
}[] = [
  {
    src: "/landing/screens/onboarding.jpg",
    alt: "FlowLine Onboarding: Willkommen und Sport",
    title: "Ankommen",
    door: "Der Hof",
    note: "Sport wählen oder überspringen. Kein Demo-Bike.",
  },
  {
    src: "/landing/screens/karte.jpg",
    alt: "FlowLine Karte mit orangener Linie",
    title: "Karte",
    door: "Karte",
    note: "OSM, Nähe, Filter. Planen ist dieselbe Tür.",
  },
  {
    src: "/landing/screens/hud.jpg",
    alt: "FlowLine Ride-HUD in der Fahrt",
    title: "Rausfahren",
    door: "App",
    note: "HUD nur nativ. Ride ist kein Tab am Hof.",
  },
  {
    src: "/landing/screens/rueckkehr.jpg",
    alt: "FlowLine nach der Fahrt",
    title: "Was reinkam",
    door: "Hof",
    note: "Analyse im Browser. Aufzeichnung bleibt in der App.",
  },
  {
    src: "/landing/screens/werkstatt.jpg",
    alt: "FlowLine Werkstatt-Karte",
    title: "Werkstatt",
    door: "Werkstatt",
    note: "Rad, Kilometer, Pflege. Teile führen in den Laden.",
  },
  {
    src: "/landing/screens/laden.jpg",
    alt: "FlowLine Laden als Shopify-Tür",
    title: "Laden",
    door: "Laden",
    note: "Regal in FlowLine. Kasse bleibt Shopify — kein zweiter Warenkorb.",
  },
  {
    src: "/landing/screens/profil.jpg",
    alt: "FlowLine Profil",
    title: "Profil",
    door: "Konto",
    note: "Fahrstil und Opt-ins. Public Profile nur bewusst.",
  },
];
