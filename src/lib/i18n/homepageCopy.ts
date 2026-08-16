import type { ChromeLang } from "./chromeLang";
import {
  HOME_CTA,
  HOME_DISCIPLINES,
  HOME_DOOR_STORIES,
  HOME_GUIDES,
  HOME_HONESTY,
  HOME_INTRO,
  HOME_JOURNEY,
  HOME_PRICING,
  HOME_SPLIT,
  HOME_TOURS,
  HOME_VOICES,
} from "../content/homepage";
import { APP_SURFACES, JOURNEY, WEB_SURFACES } from "../content/productMap";

export type HomepageCopy = {
  intro: {
    kicker: string;
    title: string;
    lead: string;
    paragraphs: readonly string[];
  };
  disciplines: { title: string; href: string; body: string }[];
  doors: { href: string; title: string; kicker: string; body: string }[];
  split: { kicker: string; title: string; webLead: string; appLead: string };
  tours: { kicker: string; title: string; lead: string };
  journey: { kicker: string; title: string; lead: string };
  voices: { kicker: string; title: string; lead: string };
  guides: {
    kicker: string;
    title: string;
    lead: string;
    slugs: readonly string[];
  };
  pricing: {
    kicker: string;
    title: string;
    lead: string;
    free: string;
    pro: string;
  };
  honesty: {
    kicker: string;
    title: string;
    lead: string;
    live: readonly string[];
    notYet: readonly string[];
  };
  cta: { title: string; body: string };
  webSurfaces: { title: string; body: string }[];
  appSurfaces: { title: string; body: string }[];
  journeySteps: { n: string; title: string; body: string }[];
  ui: {
    productMap: string;
    bikesTitle: string;
    bikesLead: string;
    doorsTitle: string;
    doorsLead: string;
    onWebsite: string;
    inApp: string;
    allRegions: string;
    allGuides: string;
    allQuestions: string;
    faqKicker: string;
    faqTitle: string;
    faqLead: string;
    alreadyHere: string;
    notYetTitle: string;
    editorial: string;
    free: string;
    pro: string;
    pricesDetail: string;
    community: string;
    readMin: (n: number) => string;
    readMinLong: (n: number) => string;
    heroTagline: string;
    heroLead: (rideOut: string) => string;
    heroFair: string;
    heroFoot: string;
    trustClose: string;
    trustTitle: string;
    trustBody: string;
    trustOffline: string;
    trustOk: string;
    faqPageLead: string;
    faqPageMoreBefore: string;
    guidesIndexLead: string;
    related: string;
  };
};

const DE: HomepageCopy = {
  intro: HOME_INTRO,
  disciplines: HOME_DISCIPLINES,
  doors: HOME_DOOR_STORIES,
  split: HOME_SPLIT,
  tours: HOME_TOURS,
  journey: HOME_JOURNEY,
  voices: HOME_VOICES,
  guides: HOME_GUIDES,
  pricing: HOME_PRICING,
  honesty: HOME_HONESTY,
  cta: HOME_CTA,
  webSurfaces: WEB_SURFACES.map((s) => ({ title: s.title, body: s.body })),
  appSurfaces: APP_SURFACES.map((s) => ({ title: s.title, body: s.body })),
  journeySteps: JOURNEY.map((s) => ({ n: s.n, title: s.title, body: s.body })),
  ui: {
    productMap: "Produktkarte",
    bikesTitle: "Für welche Räder",
    bikesLead:
      "Eine Anwendung, fünf Türen — nicht fünf Apps. Sport-Filter auf der Karte, Setup in der Werkstatt.",
    doorsTitle: "Fünf Türen am Hof",
    doorsLead:
      "Der Hof ist der Stand. Alles andere ist eine Tür — nicht ein Stapel Karten. Ride ist kein Tab.",
    onWebsite: "Auf der Website",
    inApp: "In der App",
    allRegions: "Alle Regionen",
    allGuides: "Alle Guides",
    allQuestions: "Alle Fragen",
    faqKicker: "FAQ",
    faqTitle: "Kurz und ehrlich",
    faqLead: "Keine Store-Versprechen, keine erfundenen Adressen.",
    alreadyHere: "Schon da",
    notYetTitle: "Noch nicht — und nicht erfunden",
    editorial: "Editorial",
    free: "Free",
    pro: "Pro",
    pricesDetail: "Preise im Detail",
    community: "Community",
    readMin: (n) => `${n} Min.`,
    readMinLong: (n) => `${n} Min. Lesezeit`,
    heroTagline: "Das Rad wohnt hier.",
    heroLead: (rideOut) =>
      `Outdoor Cycling, vereinfacht: planen und pflegen im Browser, fahren in der App. Drei Sekunden — der Himmel, eine Stunde vor dem Tor, ein Knopf: ${rideOut}.`,
    heroFair: "So bleibt’s fair",
    heroFoot: "Kein Feed, keine KPI-Leiste, keine zweite Kasse im Browser.",
    trustClose: "Schließen",
    trustTitle: "Fair von Anfang an.",
    trustBody:
      "Sync, Navigation und Export bleiben frei — ohne Überraschungen mitten in der Tour.",
    trustOffline: "Offline ✓ frei",
    trustOk: "Verstanden",
    faqPageLead:
      "Keine Store-Versprechen, keine erfundenen Adressen, kein Feed auf dem Hof.",
    faqPageMoreBefore: "Mehr Screens und Abläufe stehen unter",
    guidesIndexLead:
      "Ratgeber für Rennrad, Gravel, MTB und E-Bike: Touren planen, Reichweite als Spanne, Setup nach Gewicht, der Hof mit fünf Türen, Teilen per Link, der Laden ohne zweite Kasse. Kein Affiliate-Clickbait — was im Produkt fehlt, steht hier nicht als Versprechen.",
    related: "Weiter",
  },
};

const EN: HomepageCopy = {
  intro: {
    kicker: "What FlowLine is",
    title: "Outdoor cycling, without a timeline.",
    lead: "FlowLine is the everyday app between a weeknight loop and a weekend stage. In the browser you plan, look after the bike, and share a Mappe. In the app you ride: HUD, GPS, offline, sensors.",
    paragraphs: [
      "Home is the stand — not a feed. Five doors: Home, Map, Platz, Workshop, Shop. Ride is the orange button, not a sixth tab. What is missing stays empty: no dummy kilometres, no leaderboard, no second till in the browser.",
      "Public tour pages are editorial ideas with a pin. The line appears when you plan — the Alster in Hamburg, not the Alps by default. Community sits on the tour: Stimmen, Mappe links, invite links. Public profiles only with opt-in, without GPS traces.",
    ],
  },
  disciplines: [
    {
      title: "Road",
      href: "/discover?sport=road",
      body: "Tarmac, elevation, flat shores. Filters and nearby loops on the map — without traffic as a game.",
    },
    {
      title: "Gravel",
      href: "/discover?sport=gravel",
      body: "Forest roads and mixed surfaces. The “Gravel” profile avoids hard trails. After rain it stays honest: slippery is slippery.",
    },
    {
      title: "MTB",
      href: "/discover?sport=mtb",
      body: "S-scales instead of star inflation. Navigation in the app. Editorial ideas like Königstuhl — no invented downhill GPX.",
    },
    {
      title: "E-Bike",
      href: "/guides/ebike-reichweite",
      body: "Range as a span, not a point. Assist and calibration in Pro. Bosch live only native, not in the tab.",
    },
    {
      title: "Touring & city",
      href: "/discover?sport=urban",
      body: "Stages, rest spots, after work. The same tours in the Mappe as on the map — no second app for everyday riding.",
    },
  ],
  doors: [
    {
      href: "/home",
      title: "Home",
      kicker: "The stand",
      body: "The bike lives here. Sky, an hour at the gate, what came in. No KPI bar, no stories. Ride out is a button — then the app takes over.",
    },
    {
      href: "/discover",
      title: "Map",
      kicker: "At the gate",
      body: "OpenStreetMap, real nearby rides, sport filters. You plan on the desktop: start, via, destination. There is no live navigation in the browser — and we do not pretend there is.",
    },
    {
      href: "/library",
      title: "Platz",
      kicker: "Community on the tour",
      body: "Mappe, Stimmen, invite links. Share by link, not by timeline. Whoever has the link saves the tour locally — no account required, no track in the comment.",
    },
    {
      href: "/garage",
      title: "Workshop",
      kicker: "The bike",
      body: "Park, setup, service intervals with a source. Bracketing and range spans are Pro. Spare parts lead to the shop, not a second cart.",
    },
    {
      href: "/shop",
      title: "Shop",
      kicker: "A door, not a till",
      body: "Shopify sits behind the door. Fit comes from the workshop. Without an imprint on file, checkout stays locked — we do not invent an address so something can say “buy”.",
    },
  ],
  split: {
    kicker: "Two surfaces",
    title: "Web is Home. The app rides.",
    webLead:
      "Inspiration, planning, care and sharing belong at the desk. The browser may stay empty where GPS and sensors belong.",
    appLead:
      "On the road, a locked display, offline packs and a watch on the rider matter. There is no web dummy for that.",
  },
  tours: {
    kicker: "At the gate",
    title: "Ideas from nearby, not from Alpine stock.",
    lead: "Four editorial tours as a start — Hamburg Alster, Heidelberg, Schwarzwald Gravel, Bodensee. They are ideas with a pin, not surveyed community tracks. You compute the line under Plan.",
  },
  journey: {
    kicker: "Sequence",
    title: "How you get out — and back.",
    lead: "Arrive, bike at the stand, an hour at the gate, ride out, back at Home. No onboarding theatre, no demo bike that fakes kilometres.",
  },
  voices: {
    kicker: "Stimmen",
    title: "On the tour, not in a feed.",
    lead: "Editorial, clearly marked. Short text without a track attached. New Stimmen start in review.",
  },
  guides: {
    kicker: "Guides",
    title: "Read up before you leave.",
    lead: "Planning, range, setup, Home and sharing — no affiliate clickbait. What the product lacks is not promised here either.",
    slugs: HOME_GUIDES.slugs,
  },
  pricing: {
    kicker: "Prices",
    title: "Free plans. Pro goes deeper.",
    lead: "Map, planning, one bike, app navigation: free. Multi-bike, bracketing, range spans and higher chat limits: Pro. Checkout in the profile, not in the middle of a ride. App store listings follow once they are live.",
    free: "0 € — Home, Map, Platz, one bike, navigation in the app.",
    pro: "6.99 €/month or 59.99 €/year. Cancel in the portal or via Play.",
  },
  honesty: {
    kicker: "Status",
    title: "Complete where it stands — empty where it is missing.",
    lead: "A homepage must not pretend the shop is open or the store is already listed. Hence the honest status:",
    live: [
      "Home, Map, planning, Platz, workshop in the browser",
      "Editorial tours and regions in DACH",
      "Stimmen, Mappe links, editorial profiles",
      "Free and Pro described, checkout in the profile (Stripe)",
    ],
    notYet: [
      "A serviceable address in the imprint — so shop checkout stays locked",
      "App Store and Play listings — HUD and sensors come with the native app",
      "Live partner booking for workshops — interest by email",
    ],
  },
  cta: {
    title: "The bike is there. You come back.",
    body: "Open Home in the browser. The app takes navigation, offline and the watch once the listings are there — until then the stand stays honestly empty instead of filled.",
  },
  webSurfaces: [
    {
      title: "Home, Map, planning",
      body: "Inspiration, nearby loops, desktop planner. Save to the Mappe.",
    },
    {
      title: "Workshop",
      body: "Bikes, components, setup, service — also without the app.",
    },
    {
      title: "Platz",
      body: "GPX, collections, Stimmen, groups. Share without a feed.",
    },
    {
      title: "Shop",
      body: "Matching parts from the workshop. Checkout only at Shopify.",
    },
  ],
  appSurfaces: [
    {
      title: "Ride out",
      body: "Ride HUD, turn-by-turn, GPS in the background, locked display.",
    },
    {
      title: "Offline",
      body: "Map and routing packs without a network. Not useful in the browser.",
    },
    {
      title: "Sensors & watch",
      body: "BLE, CSC, watch on the rider. Pairing only native — not in the browser.",
    },
    {
      title: "Recording",
      body: "Real rides are created in the app. Home shows what came in.",
    },
  ],
  journeySteps: [
    {
      n: "1",
      title: "Arrive",
      body: "Sport and weight — or skip. No demo bike, no fake kilometres.",
    },
    {
      n: "2",
      title: "Bike at the stand",
      body: "Park it in the workshop — or ride without a bike.",
    },
    {
      n: "3",
      title: "An hour at the gate",
      body: "The map shows real nearby loops. If one is missing, the gate stays empty.",
    },
    {
      n: "4",
      title: "Ride out",
      body: "One orange button. Navigation and sensors run in the app.",
    },
    {
      n: "5",
      title: "Back at Home",
      body: "What came in: analysis, setup hint, service. Stimmen on Platz.",
    },
  ],
  ui: {
    productMap: "Product map",
    bikesTitle: "Which bikes",
    bikesLead:
      "One app, five doors — not five apps. Sport filters on the map, setup in the workshop.",
    doorsTitle: "Five doors at Home",
    doorsLead:
      "Home is the stand. Everything else is a door — not a stack of cards. Ride is not a tab.",
    onWebsite: "On the website",
    inApp: "In the app",
    allRegions: "All regions",
    allGuides: "All guides",
    allQuestions: "All questions",
    faqKicker: "FAQ",
    faqTitle: "Short and honest",
    faqLead: "No store promises, no invented addresses.",
    alreadyHere: "Already here",
    notYetTitle: "Not yet — and not invented",
    editorial: "Editorial",
    free: "Free",
    pro: "Pro",
    pricesDetail: "Prices in detail",
    community: "Community",
    readMin: (n) => `${n} min`,
    readMinLong: (n) => `${n} min read`,
    heroTagline: "The bike lives here.",
    heroLead: (rideOut) =>
      `Outdoor cycling, simplified: plan and look after the bike in the browser, ride in the app. Three seconds — the sky, an hour at the gate, one button: ${rideOut}.`,
    heroFair: "How we keep it fair",
    heroFoot: "No feed, no KPI bar, no second till in the browser.",
    trustClose: "Close",
    trustTitle: "Fair from the start.",
    trustBody:
      "Sync, navigation and export stay free — no surprises in the middle of a ride.",
    trustOffline: "Offline ✓ free",
    trustOk: "Got it",
    faqPageLead:
      "No store promises, no invented addresses, no feed at Home.",
    faqPageMoreBefore: "More screens and flows are under",
    guidesIndexLead:
      "Guides for road, gravel, MTB and e-bike: planning tours, range as a span, setup by weight, Home with five doors, sharing by link, the shop without a second till. No affiliate clickbait — what the product lacks is not promised here.",
    related: "Next",
  },
};

const FR: HomepageCopy = {
  intro: {
    kicker: "Ce qu’est FlowLine",
    title: "Le vélo dehors, sans fil d’actualité.",
    lead: "FlowLine est l’appli du quotidien, entre la boucle en semaine et l’étape du week-end. Dans le navigateur tu planifies, tu soignes le vélo et tu partages une Mappe. Dans l’appli tu roules : HUD, GPS, hors ligne, capteurs.",
    paragraphs: [
      "Home est le stand — pas un fil. Cinq portes : Home, Carte, Platz, Atelier, Magasin. Ride est le bouton orange, pas un sixième onglet. Ce qui manque reste vide : pas de kilomètres fictifs, pas de classement, pas de deuxième caisse dans le navigateur.",
      "Les pages de sorties publiques sont des idées éditoriales avec une épingle. La ligne apparaît quand tu planifies — l’Alster à Hamburg, pas les Alpes par défaut. La communauté tient à la sortie : Stimmen, liens Mappe, liens d’invitation. Profils publics seulement avec opt-in, sans traces GPS.",
    ],
  },
  disciplines: [
    {
      title: "Route",
      href: "/discover?sport=road",
      body: "Bitume, dénivelé, rives plates. Filtres et boucles proches sur la carte — sans faire du trafic un jeu.",
    },
    {
      title: "Gravel",
      href: "/discover?sport=gravel",
      body: "Pistes forestières et mix. Le profil « Gravel » évite les trails durs. Après la pluie, c’est honnête : glissant reste glissant.",
    },
    {
      title: "MTB",
      href: "/discover?sport=mtb",
      body: "Échelles S plutôt qu’une inflation d’étoiles. Navigation dans l’appli. Idées éditoriales comme le Königstuhl — pas de GPX de descente inventé.",
    },
    {
      title: "E-Bike",
      href: "/guides/ebike-reichweite",
      body: "Autonomie en fourchette, pas en point. Assist et calibration dans Pro. Bosch en live seulement en natif, pas dans l’onglet.",
    },
    {
      title: "Touring & ville",
      href: "/discover?sport=urban",
      body: "Étapes, pauses, après le travail. Les mêmes sorties dans la Mappe que sur la carte — pas de deuxième appli pour le quotidien.",
    },
  ],
  doors: [
    {
      href: "/home",
      title: "Home",
      kicker: "Le stand",
      body: "Le vélo habite ici. Ciel, une heure devant la porte, ce qui est rentré. Pas de barre KPI, pas de stories. Sortir est un bouton — ensuite l’appli prend le relais.",
    },
    {
      href: "/discover",
      title: "Carte",
      kicker: "Devant la porte",
      body: "OpenStreetMap, de vraies sorties proches, filtres sport. Tu planifies sur le bureau : départ, via, arrivée. Il n’y a pas de navigation live dans le navigateur — et on ne fait pas semblant.",
    },
    {
      href: "/library",
      title: "Platz",
      kicker: "Communauté sur la sortie",
      body: "Mappe, Stimmen, liens d’invitation. Partage par lien, pas par fil. Qui a le lien enregistre la sortie en local — sans compte obligatoire, sans trace dans le commentaire.",
    },
    {
      href: "/garage",
      title: "Atelier",
      kicker: "Le vélo",
      body: "Garer, setup, intervalles d’entretien avec source. Bracketing et fourchettes d’autonomie sont Pro. Les pièces mènent au magasin, pas à un deuxième panier.",
    },
    {
      href: "/shop",
      title: "Magasin",
      kicker: "Une porte, pas une caisse",
      body: "Shopify est derrière la porte. Le fit vient de l’atelier. Sans mentions légales déposées, le checkout reste bloqué — on n’invente pas d’adresse pour que quelque chose dise « acheter ».",
    },
  ],
  split: {
    kicker: "Deux surfaces",
    title: "Le web est Home. L’appli roule.",
    webLead:
      "Inspiration, planification, entretien et partage appartiennent au bureau. Le navigateur peut rester vide là où GPS et capteurs ont leur place.",
    appLead:
      "En route, un écran verrouillé, des packs hors ligne et une montre sur le cycliste comptent. Il n’y a pas de simulacre web pour ça.",
  },
  tours: {
    kicker: "Devant la porte",
    title: "Des idées du coin, pas du stock alpin.",
    lead: "Quatre sorties éditoriales pour commencer — Hamburg Alster, Heidelberg, Schwarzwald Gravel, Bodensee. Ce sont des idées avec une épingle, pas des traces community mesurées. Tu calcules la ligne sous Planifier.",
  },
  journey: {
    kicker: "Parcours",
    title: "Comment tu sors — et tu reviens.",
    lead: "Arriver, vélo au stand, une heure devant la porte, sortir, de retour à Home. Pas de théâtre d’onboarding, pas de vélo démo qui invente des kilomètres.",
  },
  voices: {
    kicker: "Stimmen",
    title: "Sur la sortie, pas dans un fil.",
    lead: "Éditorial, clairement marqué. Texte court sans trace jointe. Les nouvelles Stimmen partent en relecture.",
  },
  guides: {
    kicker: "Guides",
    title: "Lire avant de partir.",
    lead: "Planification, autonomie, setup, Home et partage — pas de clickbait affilié. Ce qui manque au produit n’est pas promis ici non plus.",
    slugs: HOME_GUIDES.slugs,
  },
  pricing: {
    kicker: "Prix",
    title: "Free planifie. Pro approfondit.",
    lead: "Carte, planification, un vélo, navigation dans l’appli : gratuit. Multi-vélo, bracketing, fourchettes d’autonomie et limites de chat plus hautes : Pro. Checkout dans le profil, pas au milieu de la sortie. Les listings store suivent dès qu’ils sont en ligne.",
    free: "0 € — Home, Carte, Platz, un vélo, navigation dans l’appli.",
    pro: "6,99 €/mois ou 59,99 €/an. Résiliation dans le portail ou via Play.",
  },
  honesty: {
    kicker: "État",
    title: "Complet là où c’est écrit — vide là où ça manque.",
    lead: "Une page d’accueil ne doit pas faire comme si le magasin était ouvert ou le store déjà listé. D’où l’état honnête :",
    live: [
      "Home, Carte, planification, Platz, atelier dans le navigateur",
      "Sorties et régions éditoriales en DACH",
      "Stimmen, liens Mappe, profils éditoriaux",
      "Free et Pro décrits, checkout dans le profil (Stripe)",
    ],
    notYet: [
      "Une adresse de signification dans les mentions légales — donc checkout magasin bloqué",
      "Listings App Store et Play — HUD et capteurs viennent avec l’appli native",
      "Réservation partenaire live pour les ateliers — intérêt par e-mail",
    ],
  },
  cta: {
    title: "Le vélo est là. Tu reviens.",
    body: "Ouvre Home dans le navigateur. L’appli prend la navigation, le hors ligne et la montre dès que les listings sont là — jusque-là le stand reste honnêtement vide plutôt que rempli.",
  },
  webSurfaces: [
    {
      title: "Home, Carte, planifier",
      body: "Inspiration, boucles proches, planificateur bureau. Enregistrer dans la Mappe.",
    },
    {
      title: "Atelier",
      body: "Vélos, composants, setup, entretien — aussi sans l’appli.",
    },
    {
      title: "Platz",
      body: "GPX, collections, Stimmen, groupes. Partager sans fil.",
    },
    {
      title: "Magasin",
      body: "Pièces adaptées depuis l’atelier. Checkout seulement chez Shopify.",
    },
  ],
  appSurfaces: [
    {
      title: "Sortir",
      body: "Ride-HUD, guidage, GPS en arrière-plan, écran verrouillé.",
    },
    {
      title: "Hors ligne",
      body: "Packs carte et routing sans réseau. Pas utile dans le navigateur.",
    },
    {
      title: "Capteurs et montre",
      body: "BLE, CSC, montre sur le cycliste. Couplage seulement en natif — pas dans le navigateur.",
    },
    {
      title: "Enregistrement",
      body: "Les vraies sorties naissent dans l’appli. Home montre ce qui est rentré.",
    },
  ],
  journeySteps: [
    {
      n: "1",
      title: "Arriver",
      body: "Sport et poids — ou passer. Pas de vélo démo, pas de kilomètres fictifs.",
    },
    {
      n: "2",
      title: "Vélo au stand",
      body: "Le garer à l’atelier — ou rouler sans vélo.",
    },
    {
      n: "3",
      title: "Une heure devant la porte",
      body: "La carte montre de vraies boucles proches. S’il en manque une, la porte reste vide.",
    },
    {
      n: "4",
      title: "Sortir",
      body: "Un bouton orange. Navigation et capteurs tournent dans l’appli.",
    },
    {
      n: "5",
      title: "De retour à Home",
      body: "Ce qui est rentré : analyse, hint de setup, entretien. Stimmen sur le Platz.",
    },
  ],
  ui: {
    productMap: "Carte produit",
    bikesTitle: "Pour quels vélos",
    bikesLead:
      "Une appli, cinq portes — pas cinq applis. Filtres sport sur la carte, setup à l’atelier.",
    doorsTitle: "Cinq portes à Home",
    doorsLead:
      "Home est le stand. Tout le reste est une porte — pas une pile de cartes. Ride n’est pas un onglet.",
    onWebsite: "Sur le site",
    inApp: "Dans l’appli",
    allRegions: "Toutes les régions",
    allGuides: "Tous les guides",
    allQuestions: "Toutes les questions",
    faqKicker: "FAQ",
    faqTitle: "Court et honnête",
    faqLead: "Pas de promesses store, pas d’adresses inventées.",
    alreadyHere: "Déjà là",
    notYetTitle: "Pas encore — et pas inventé",
    editorial: "Éditorial",
    free: "Free",
    pro: "Pro",
    pricesDetail: "Les prix en détail",
    community: "Community",
    readMin: (n) => `${n} min`,
    readMinLong: (n) => `${n} min de lecture`,
    heroTagline: "Le vélo habite ici.",
    heroLead: (rideOut) =>
      `Le vélo dehors, simplifié : planifier et soigner dans le navigateur, rouler dans l’appli. Trois secondes — le ciel, une heure devant la porte, un bouton : ${rideOut}.`,
    heroFair: "Pour rester juste",
    heroFoot: "Pas de fil, pas de barre KPI, pas de deuxième caisse dans le navigateur.",
    trustClose: "Fermer",
    trustTitle: "Juste dès le départ.",
    trustBody:
      "Sync, navigation et export restent libres — sans surprises au milieu de la sortie.",
    trustOffline: "Hors ligne ✓ libre",
    trustOk: "Compris",
    faqPageLead:
      "Pas de promesses store, pas d’adresses inventées, pas de fil à Home.",
    faqPageMoreBefore: "Plus d’écrans et de parcours sous",
    guidesIndexLead:
      "Guides pour la route, le gravel, le MTB et l’e-bike : planifier des sorties, autonomie en fourchette, setup selon le poids, Home avec cinq portes, partage par lien, magasin sans deuxième caisse. Pas de clickbait affilié — ce qui manque au produit n’est pas promis ici.",
    related: "Suite",
  },
};

const IT: HomepageCopy = {
  intro: {
    kicker: "Cos’è FlowLine",
    title: "Ciclismo outdoor, senza timeline.",
    lead: "FlowLine è l’app del quotidiano, tra il giro serale e la tappa del weekend. Nel browser pianifichi, curi la bici e condividi una Mappe. Nell’app pedali: HUD, GPS, offline, sensori.",
    paragraphs: [
      "Home è lo stand — non un feed. Cinque porte: Home, Mappa, Platz, Officina, Negozio. Ride è il pulsante arancione, non la sesta scheda. Ciò che manca resta vuoto: niente chilometri finti, niente classifica, niente seconda cassa nel browser.",
      "Le pagine pubbliche delle uscite sono idee editoriali con un pin. La linea nasce quando pianifichi — l’Alster ad Hamburg, non le Alpi di default. La community sta sull’uscita: Stimmen, link Mappe, link di invito. Profili pubblici solo con opt-in, senza tracce GPS.",
    ],
  },
  disciplines: [
    {
      title: "Strada",
      href: "/discover?sport=road",
      body: "Asfalto, dislivello, rive piatte. Filtri e anelli vicini sulla mappa — senza fare del traffico un gioco.",
    },
    {
      title: "Gravel",
      href: "/discover?sport=gravel",
      body: "Strade forestali e mix. Il profilo «Gravel» evita i trail duri. Dopo la pioggia resta onesto: scivoloso è scivoloso.",
    },
    {
      title: "MTB",
      href: "/discover?sport=mtb",
      body: "Scale S invece dell’inflazione di stelle. Navigazione nell’app. Idee editoriali come il Königstuhl — niente GPX downhill inventati.",
    },
    {
      title: "E-Bike",
      href: "/guides/ebike-reichweite",
      body: "Autonomia come fascia, non come punto. Assist e calibrazione in Pro. Bosch live solo nativo, non nel tab.",
    },
    {
      title: "Touring e città",
      href: "/discover?sport=urban",
      body: "Tappe, pause, dopo il lavoro. Le stesse uscite nella Mappe e sulla mappa — niente seconda app per il quotidiano.",
    },
  ],
  doors: [
    {
      href: "/home",
      title: "Home",
      kicker: "Lo stand",
      body: "La bici abita qui. Cielo, un’ora davanti al cancello, ciò che è rientrato. Niente barra KPI, niente stories. Uscire è un pulsante — poi l’app prende il posto.",
    },
    {
      href: "/discover",
      title: "Mappa",
      kicker: "Davanti al cancello",
      body: "OpenStreetMap, uscite vicine vere, filtri sport. Pianifichi sul desktop: partenza, via, arrivo. Non c’è navigazione live nel browser — e non facciamo finta.",
    },
    {
      href: "/library",
      title: "Platz",
      kicker: "Community sull’uscita",
      body: "Mappe, Stimmen, link di invito. Condividi per link, non per timeline. Chi ha il link salva l’uscita in locale — senza account obbligatorio, senza traccia nel commento.",
    },
    {
      href: "/garage",
      title: "Officina",
      kicker: "La bici",
      body: "Parcheggiare, setup, intervalli di manutenzione con fonte. Bracketing e fasce di autonomia sono Pro. I ricambi portano al negozio, non a un secondo carrello.",
    },
    {
      href: "/shop",
      title: "Negozio",
      kicker: "Una porta, non una cassa",
      body: "Shopify sta dietro la porta. Il fit viene dall’officina. Senza Impressum depositato, il checkout resta bloccato — non inventiamo un indirizzo perché qualcosa dica «compra».",
    },
  ],
  split: {
    kicker: "Due superfici",
    title: "Il web è Home. L’app pedala.",
    webLead:
      "Ispirazione, pianificazione, cura e condivisione stanno alla scrivania. Il browser può restare vuoto dove GPS e sensori appartengono.",
    appLead:
      "In strada contano un display bloccato, pack offline e un orologio sul ciclista. Non c’è un finto web per questo.",
  },
  tours: {
    kicker: "Davanti al cancello",
    title: "Idee dal vicino, non dallo stock alpino.",
    lead: "Quattro uscite editoriali per iniziare — Hamburg Alster, Heidelberg, Schwarzwald Gravel, Bodensee. Sono idee con un pin, non tracce community misurate. Calcoli la linea sotto Pianifica.",
  },
  journey: {
    kicker: "Percorso",
    title: "Così esci — e torni.",
    lead: "Arrivare, bici allo stand, un’ora davanti al cancello, uscire, di nuovo a Home. Niente teatro di onboarding, niente bici demo che inventa chilometri.",
  },
  voices: {
    kicker: "Stimmen",
    title: "Sull’uscita, non in un feed.",
    lead: "Editoriale, chiaramente segnalato. Testo breve senza traccia in allegato. Le nuove Stimmen partono in revisione.",
  },
  guides: {
    kicker: "Guide",
    title: "Leggi prima di partire.",
    lead: "Pianificazione, autonomia, setup, Home e condivisione — niente clickbait affiliato. Ciò che manca al prodotto non è promesso neanche qui.",
    slugs: HOME_GUIDES.slugs,
  },
  pricing: {
    kicker: "Prezzi",
    title: "Free pianifica. Pro approfondisce.",
    lead: "Mappa, pianificazione, una bici, navigazione nell’app: gratis. Multi-bici, bracketing, fasce di autonomia e limiti chat più alti: Pro. Checkout nel profilo, non in mezzo all’uscita. I listing store arrivano quando sono live.",
    free: "0 € — Home, Mappa, Platz, una bici, navigazione nell’app.",
    pro: "6,99 €/mese oppure 59,99 €/anno. Disdetta nel portale o via Play.",
  },
  honesty: {
    kicker: "Stato",
    title: "Completo dove sta scritto — vuoto dove manca.",
    lead: "Una homepage non deve far finta che il negozio sia aperto o lo store già in elenco. Per questo lo stato onesto:",
    live: [
      "Home, Mappa, pianificazione, Platz, officina nel browser",
      "Uscite e regioni editoriali in DACH",
      "Stimmen, link Mappe, profili editoriali",
      "Free e Pro descritti, checkout nel profilo (Stripe)",
    ],
    notYet: [
      "Un indirizzo notificabile nell’Impressum — quindi checkout negozio bloccato",
      "Listing App Store e Play — HUD e sensori arrivano con l’app nativa",
      "Prenotazione partner live per le officine — interesse via e-mail",
    ],
  },
  cta: {
    title: "La bici c’è. Tu torni.",
    body: "Apri Home nel browser. L’app prende navigazione, offline e orologio quando i listing ci sono — fino ad allora lo stand resta onestamente vuoto invece che riempito.",
  },
  webSurfaces: [
    {
      title: "Home, Mappa, pianifica",
      body: "Ispirazione, anelli vicini, planner desktop. Salva nella Mappe.",
    },
    {
      title: "Officina",
      body: "Bici, componenti, setup, manutenzione — anche senza app.",
    },
    {
      title: "Platz",
      body: "GPX, raccolte, Stimmen, gruppi. Condividi senza feed.",
    },
    {
      title: "Negozio",
      body: "Ricambi adatti dall’officina. Checkout solo da Shopify.",
    },
  ],
  appSurfaces: [
    {
      title: "Esci",
      body: "Ride-HUD, turn-by-turn, GPS in background, display bloccato.",
    },
    {
      title: "Offline",
      body: "Pack di mappe e routing senza rete. Nel browser non ha senso.",
    },
    {
      title: "Sensori e orologio",
      body: "BLE, CSC, orologio sul ciclista. Accoppiamento solo nativo — non nel browser.",
    },
    {
      title: "Registrazione",
      body: "Le uscite vere nascono nell’app. Home mostra ciò che è rientrato.",
    },
  ],
  journeySteps: [
    {
      n: "1",
      title: "Arrivo",
      body: "Sport e peso — o salta. Niente bici demo, niente chilometri finti.",
    },
    {
      n: "2",
      title: "Bici allo stand",
      body: "Parcheggiarla in officina — o pedalare senza bici.",
    },
    {
      n: "3",
      title: "Un’ora davanti al cancello",
      body: "La mappa mostra anelli vicini veri. Se ne manca uno, il cancello resta vuoto.",
    },
    {
      n: "4",
      title: "Esci",
      body: "Un pulsante arancione. Navigazione e sensori girano nell’app.",
    },
    {
      n: "5",
      title: "Di nuovo a Home",
      body: "Ciò che è rientrato: analisi, hint di setup, manutenzione. Stimmen sul Platz.",
    },
  ],
  ui: {
    productMap: "Mappa prodotto",
    bikesTitle: "Per quali bici",
    bikesLead:
      "Un’app, cinque porte — non cinque app. Filtri sport sulla mappa, setup in officina.",
    doorsTitle: "Cinque porte a Home",
    doorsLead:
      "Home è lo stand. Tutto il resto è una porta — non una pila di schede. Ride non è una scheda.",
    onWebsite: "Sul sito",
    inApp: "Nell’app",
    allRegions: "Tutte le regioni",
    allGuides: "Tutte le guide",
    allQuestions: "Tutte le domande",
    faqKicker: "FAQ",
    faqTitle: "Breve e onesto",
    faqLead: "Niente promesse store, niente indirizzi inventati.",
    alreadyHere: "Già qui",
    notYetTitle: "Non ancora — e non inventato",
    editorial: "Editoriale",
    free: "Free",
    pro: "Pro",
    pricesDetail: "Prezzi in dettaglio",
    community: "Community",
    readMin: (n) => `${n} min`,
    readMinLong: (n) => `${n} min di lettura`,
    heroTagline: "La bici abita qui.",
    heroLead: (rideOut) =>
      `Ciclismo outdoor, semplificato: pianificare e curare nel browser, pedalare nell’app. Tre secondi — il cielo, un’ora davanti al cancello, un pulsante: ${rideOut}.`,
    heroFair: "Così resta onesto",
    heroFoot: "Niente feed, niente barra KPI, niente seconda cassa nel browser.",
    trustClose: "Chiudi",
    trustTitle: "Onesto fin dall’inizio.",
    trustBody:
      "Sync, navigazione ed export restano liberi — senza sorprese in mezzo all’uscita.",
    trustOffline: "Offline ✓ libero",
    trustOk: "Capito",
    faqPageLead:
      "Niente promesse store, niente indirizzi inventati, niente feed a Home.",
    faqPageMoreBefore: "Altre schermate e flussi sotto",
    guidesIndexLead:
      "Guide per strada, gravel, MTB ed e-bike: pianificare uscite, autonomia come fascia, setup in base al peso, Home con cinque porte, condivisione per link, negozio senza seconda cassa. Niente clickbait affiliato — ciò che manca al prodotto non è promesso qui.",
    related: "Avanti",
  },
};

const BY_LANG: Record<ChromeLang, HomepageCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
};

export function homepageCopy(lang: ChromeLang): HomepageCopy {
  return BY_LANG[lang];
}
