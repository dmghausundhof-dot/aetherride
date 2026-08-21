import type { ChromeLang } from "./chromeLang";
import { SCREEN_GALLERY } from "../content/screenGallery";

export type GalleryShot = {
  src: string;
  alt: string;
  title: string;
  door: string;
  note: string;
};

export type ScreenGalleryCopy = {
  heading: string;
  hint: string;
  shots: GalleryShot[];
};

const DE: ScreenGalleryCopy = {
  heading: "So sieht FlowLine aus",
  hint: "Marke und Screens aus dem Design-System. Die vier Türen bleiben: Hof, Karte, Touren, Rad. Teile sitzen am Rad.",
  shots: SCREEN_GALLERY,
};

const EN: ScreenGalleryCopy = {
  heading: "What FlowLine looks like",
  hint: "Brand and screens from the design system. The four doors stay: Home, Map, Tours, Bike. Parts sit on the bike.",
  shots: [
    {
      src: "/landing/screens/onboarding.jpg",
      alt: "FlowLine onboarding: welcome and sport",
      title: "Arrive",
      door: "Home",
      note: "Pick a sport or skip. No demo bike.",
    },
    {
      src: "/landing/screens/karte.jpg",
      alt: "FlowLine map with an orange line",
      title: "Map",
      door: "Map",
      note: "OSM, nearby, filters. Planning is the same door.",
    },
    {
      src: "/landing/screens/hud.jpg",
      alt: "FlowLine Ride HUD on the road",
      title: "Ride out",
      door: "App",
      note: "HUD only native. Ride is not a tab at Home.",
    },
    {
      src: "/landing/screens/rueckkehr.jpg",
      alt: "FlowLine after the ride",
      title: "What came in",
      door: "Home",
      note: "Analysis in the browser. Recording stays in the app.",
    },
    {
      src: "/landing/screens/werkstatt.jpg",
      alt: "FlowLine bike card",
      title: "Bike",
      door: "Bike",
      note: "Bike, kilometres, care. The shop is off for now.",
    },
    {
      src: "/landing/screens/laden.jpg",
      alt: "FlowLine shop — paused for now",
      title: "Shop paused",
      door: "Bike",
      note: "Not a tab. No till in FlowLine while the shop is closed.",
    },
    {
      src: "/landing/screens/profil.jpg",
      alt: "FlowLine profile",
      title: "Profile",
      door: "Account",
      note: "Riding style and opt-ins. Public profile only on purpose.",
    },
  ],
};

const FR: ScreenGalleryCopy = {
  heading: "À quoi ressemble FlowLine",
  hint: "Marque et écrans du design system. Les quatre portes restent : Home, Carte, Parcours, Vélo. Les pièces tiennent au vélo.",
  shots: [
    {
      src: "/landing/screens/onboarding.jpg",
      alt: "Onboarding FlowLine : bienvenue et sport",
      title: "Arriver",
      door: "Home",
      note: "Choisir un sport ou passer. Pas de vélo démo.",
    },
    {
      src: "/landing/screens/karte.jpg",
      alt: "Carte FlowLine avec une ligne orange",
      title: "Carte",
      door: "Carte",
      note: "OSM, proximité, filtres. Planifier est la même porte.",
    },
    {
      src: "/landing/screens/hud.jpg",
      alt: "Ride-HUD FlowLine en sortie",
      title: "Sortir",
      door: "App",
      note: "HUD seulement en natif. Ride n’est pas un onglet à Home.",
    },
    {
      src: "/landing/screens/rueckkehr.jpg",
      alt: "FlowLine après la sortie",
      title: "Ce qui est rentré",
      door: "Home",
      note: "Analyse dans le navigateur. L’enregistrement reste dans l’appli.",
    },
    {
      src: "/landing/screens/werkstatt.jpg",
      alt: "Carte vélo FlowLine",
      title: "Vélo",
      door: "Vélo",
      note: "Vélo, kilomètres, entretien. Le magasin est coupé pour l’instant.",
    },
    {
      src: "/landing/screens/laden.jpg",
      alt: "Magasin FlowLine — en pause",
      title: "Magasin en pause",
      door: "Vélo",
      note: "Pas un onglet. Pas de caisse dans FlowLine tant que le magasin est fermé.",
    },
    {
      src: "/landing/screens/profil.jpg",
      alt: "Profil FlowLine",
      title: "Profil",
      door: "Compte",
      note: "Style de conduite et opt-ins. Profil public seulement volontairement.",
    },
  ],
};

const IT: ScreenGalleryCopy = {
  heading: "Come si presenta FlowLine",
  hint: "Marca e schermate dal design system. Le quattro porte restano: Home, Mappa, Percorsi, Bici. I pezzi stanno sulla bici.",
  shots: [
    {
      src: "/landing/screens/onboarding.jpg",
      alt: "Onboarding FlowLine: benvenuto e sport",
      title: "Arrivo",
      door: "Home",
      note: "Scegli uno sport o salta. Niente bici demo.",
    },
    {
      src: "/landing/screens/karte.jpg",
      alt: "Mappa FlowLine con una linea arancione",
      title: "Mappa",
      door: "Mappa",
      note: "OSM, vicino, filtri. Pianifica è la stessa porta.",
    },
    {
      src: "/landing/screens/hud.jpg",
      alt: "Ride-HUD FlowLine in uscita",
      title: "Esci",
      door: "App",
      note: "HUD solo nativo. Ride non è una scheda a Home.",
    },
    {
      src: "/landing/screens/rueckkehr.jpg",
      alt: "FlowLine dopo l’uscita",
      title: "Cosa è rientrato",
      door: "Home",
      note: "Analisi nel browser. La registrazione resta nell’app.",
    },
    {
      src: "/landing/screens/werkstatt.jpg",
      alt: "Scheda bici FlowLine",
      title: "Bici",
      door: "Bici",
      note: "Bici, chilometri, cura. Il negozio è spento per ora.",
    },
    {
      src: "/landing/screens/laden.jpg",
      alt: "Negozio FlowLine — in pausa",
      title: "Negozio in pausa",
      door: "Bici",
      note: "Non è una scheda. Niente cassa in FlowLine finché il negozio è chiuso.",
    },
    {
      src: "/landing/screens/profil.jpg",
      alt: "Profilo FlowLine",
      title: "Profilo",
      door: "Account",
      note: "Stile di guida e opt-in. Profilo pubblico solo di proposito.",
    },
  ],
};

const NL: ScreenGalleryCopy = {
  heading: "Zo ziet FlowLine eruit",
  hint: "Merk en schermen uit het design system. De vier deuren blijven: Home, Kaart, Tochten, Fiets. Onderdelen zitten aan de fiets.",
  shots: [
    {
      src: "/landing/screens/onboarding.jpg",
      alt: "FlowLine-onboarding: welkom en sport",
      title: "Aankomen",
      door: "Home",
      note: "Kies een sport of sla over. Geen demofiets.",
    },
    {
      src: "/landing/screens/karte.jpg",
      alt: "FlowLine-kaart met een oranje lijn",
      title: "Kaart",
      door: "Kaart",
      note: "OSM, nabij, filters. Plannen is dezelfde deur.",
    },
    {
      src: "/landing/screens/hud.jpg",
      alt: "FlowLine Ride-HUD op de weg",
      title: "Naar buiten",
      door: "App",
      note: "HUD alleen native. Ride is geen tab bij Home.",
    },
    {
      src: "/landing/screens/rueckkehr.jpg",
      alt: "FlowLine na de rit",
      title: "Wat er binnenkwam",
      door: "Home",
      note: "Analyse in de browser. Opname blijft in de app.",
    },
    {
      src: "/landing/screens/werkstatt.jpg",
      alt: "FlowLine-fietskaart",
      title: "Fiets",
      door: "Fiets",
      note: "Fiets, kilometers, zorg. De winkel is voorlopig uit.",
    },
    {
      src: "/landing/screens/laden.jpg",
      alt: "FlowLine-winkel — voorlopig gepauzeerd",
      title: "Winkel gepauzeerd",
      door: "Fiets",
      note: "Geen tab. Geen kassa in FlowLine zolang de winkel dicht is.",
    },
    {
      src: "/landing/screens/profil.jpg",
      alt: "FlowLine-profiel",
      title: "Profiel",
      door: "Account",
      note: "Rijstijl en opt-ins. Publiek profiel alleen bewust.",
    },
  ],
};

const BY_LANG: Record<ChromeLang, ScreenGalleryCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function screenGalleryCopy(lang: ChromeLang): ScreenGalleryCopy {
  return BY_LANG[lang];
}
