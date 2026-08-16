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
  hint: "Marke und Screens aus dem Design-System. Die fünf Türen bleiben: Hof, Karte, Platz, Werkstatt, Laden.",
  shots: SCREEN_GALLERY,
};

const EN: ScreenGalleryCopy = {
  heading: "What FlowLine looks like",
  hint: "Brand and screens from the design system. The five doors stay: Home, Map, Platz, Workshop, Shop.",
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
      alt: "FlowLine workshop card",
      title: "Workshop",
      door: "Workshop",
      note: "Bike, kilometres, care. Parts lead to the shop.",
    },
    {
      src: "/landing/screens/laden.jpg",
      alt: "FlowLine shop as a Shopify door",
      title: "Shop",
      door: "Shop",
      note: "A shelf in FlowLine. The till stays Shopify — no second cart.",
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
  hint: "Marque et écrans du design system. Les cinq portes restent : Home, Carte, Platz, Atelier, Magasin.",
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
      alt: "Carte atelier FlowLine",
      title: "Atelier",
      door: "Atelier",
      note: "Vélo, kilomètres, entretien. Les pièces mènent au magasin.",
    },
    {
      src: "/landing/screens/laden.jpg",
      alt: "Magasin FlowLine comme porte Shopify",
      title: "Magasin",
      door: "Magasin",
      note: "Un rayon dans FlowLine. La caisse reste Shopify — pas de deuxième panier.",
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
  hint: "Marca e schermate dal design system. Le cinque porte restano: Home, Mappa, Platz, Officina, Negozio.",
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
      alt: "Scheda officina FlowLine",
      title: "Officina",
      door: "Officina",
      note: "Bici, chilometri, cura. I ricambi portano al negozio.",
    },
    {
      src: "/landing/screens/laden.jpg",
      alt: "Negozio FlowLine come porta Shopify",
      title: "Negozio",
      door: "Negozio",
      note: "Uno scaffale in FlowLine. La cassa resta Shopify — niente secondo carrello.",
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

const BY_LANG: Record<ChromeLang, ScreenGalleryCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
};

export function screenGalleryCopy(lang: ChromeLang): ScreenGalleryCopy {
  return BY_LANG[lang];
}
