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
      "Eine Anwendung, vier Türen — nicht vier Apps. Sport-Filter auf der Karte, Setup am Rad.",
    doorsTitle: "Vier Türen am Hof",
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
      "Ratgeber für Rennrad, Gravel, MTB und E-Bike: Touren planen, Reichweite als Spanne, Setup nach Gewicht, der Hof mit vier Türen, Teilen per Link, Teile am Rad. Kein Affiliate-Clickbait — was im Produkt fehlt, steht hier nicht als Versprechen.",
    related: "Weiter",
  },
};

const EN: HomepageCopy = {
  intro: {
    kicker: "What FlowLine is",
    title: "Outdoor cycling, without a timeline.",
    lead: "FlowLine is the everyday app between a weeknight loop and a weekend stage. In the browser you plan, look after the bike, and share a Mappe. In the app you ride: HUD, GPS, offline routing, sensors.",
    paragraphs: [
      "Home is the stand — not a feed. Four doors: Home, Map, Tours, Bike. Parts sit on the bike, not as a fifth tab. Ride is the orange button, not a fifth tab. What is missing stays empty: no dummy kilometres, no leaderboard, no second till in the browser.",
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
      title: "Start",
      kicker: "Ride",
      body: "Your bike, weather, what came in. One orange button. No KPI bar, no stories. Ride starts the app — the map is for planning.",
    },
    {
      href: "/discover",
      title: "Map",
      kicker: "At the gate",
      body: "OpenStreetMap, real nearby rides, sport filters. You plan on the desktop: start, via, destination. There is no live navigation in the browser — and we do not pretend there is.",
    },
    {
      href: "/library",
      title: "Tours",
      kicker: "Saved and shared",
      body: "Your rides, tips, invite links. Share by link, not by timeline. Whoever has the link saves the tour locally — no account required, no track in the comment.",
    },
    {
      href: "/garage",
      title: "Bike",
      kicker: "This bike",
      body: "Add a bike, setup, service intervals with a source. Bracketing and range spans are Pro. The shop is paused — no second till.",
    },
  ],
  split: {
    kicker: "Two surfaces",
    title: "Web is Home. The app rides.",
    webLead:
      "Inspiration, planning, care and sharing belong at the desk. The browser may stay empty where GPS and sensors belong.",
    appLead:
      "On the road, a locked display, offline routing and a watch on the rider matter. There is no web dummy for that.",
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
    free: "0 € — Home, Map, Tours, one bike, navigation in the app.",
    pro: "6.99 €/month or 59.99 €/year. Cancel in the portal or via Play.",
  },
  honesty: {
    kicker: "Status",
    title: "Complete where it stands — empty where it is missing.",
    lead: "A homepage must not pretend the shop is open or the store is already listed. Hence the honest status:",
    live: [
      "Home, Map, planning, Tours, Bike in the browser",
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
      title: "Bike",
      body: "Bikes, components, setup, service — also without the app.",
    },
    {
      title: "Tours",
      body: "GPX, collections, tips, groups. Share without a feed.",
    },
  ],
  appSurfaces: [
    {
      title: "Ride out",
      body: "Ride HUD, turn-by-turn, GPS in the background, locked display.",
    },
    {
      title: "Offline",
      body: "Routing graph of the pack without a network. No country map, no Komoot Europe.",
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
      body: "Add it at the stand — or ride without a bike.",
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
      "One app, four doors — not four apps. Sport filters on the map, setup on the bike.",
    doorsTitle: "Four doors at Home",
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
      "Guides for road, gravel, MTB and e-bike: planning tours, range as a span, setup by weight, Home with four doors, sharing by link, parts on the bike. No affiliate clickbait — what the product lacks is not promised here.",
    related: "Next",
  },
};

const FR: HomepageCopy = {
  intro: {
    kicker: "Ce qu’est FlowLine",
    title: "Le vélo dehors, sans fil d’actualité.",
    lead: "FlowLine est l’appli du quotidien, entre la boucle en semaine et l’étape du week-end. Dans le navigateur tu planifies, tu soignes le vélo et tu partages une Mappe. Dans l’appli tu roules : HUD, GPS, routage hors ligne, capteurs.",
    paragraphs: [
      "Home est le stand — pas un fil. Quatre portes : Home, Carte, Parcours, Vélo. Les pièces tiennent au vélo, pas comme cinquième onglet. Ride est le bouton orange, pas un cinquième onglet. Ce qui manque reste vide : pas de kilomètres fictifs, pas de classement, pas de deuxième caisse dans le navigateur.",
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
      title: "Accueil",
      kicker: "Rouler",
      body: "Ton vélo, la météo, ce qui est rentré. Un bouton orange. Pas de barre KPI, pas de stories. Rouler lance l’appli — la carte sert à planifier.",
    },
    {
      href: "/discover",
      title: "Carte",
      kicker: "Devant la porte",
      body: "OpenStreetMap, de vraies sorties proches, filtres sport. Tu planifies sur le bureau : départ, via, arrivée. Il n’y a pas de navigation live dans le navigateur — et on ne fait pas semblant.",
    },
    {
      href: "/library",
      title: "Parcours",
      kicker: "Enregistré et partagé",
      body: "Tes sorties, astuces, liens d’invitation. Partage par lien, pas par fil. Qui a le lien enregistre la sortie en local — sans compte obligatoire, sans trace dans le commentaire.",
    },
    {
      href: "/garage",
      title: "Vélo",
      kicker: "Ce vélo",
      body: "Ajouter, setup, intervalles d’entretien avec source. Bracketing et fourchettes d’autonomie sont Pro. Le magasin est en pause — pas de deuxième caisse.",
    },
  ],
  split: {
    kicker: "Deux surfaces",
    title: "Le web est Home. L’appli roule.",
    webLead:
      "Inspiration, planification, entretien et partage appartiennent au bureau. Le navigateur peut rester vide là où GPS et capteurs ont leur place.",
    appLead:
      "En route, un écran verrouillé, le routage hors ligne et une montre sur le cycliste comptent. Il n’y a pas de simulacre web pour ça.",
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
    free: "0 € — Home, Carte, Parcours, un vélo, navigation dans l’appli.",
    pro: "6,99 €/mois ou 59,99 €/an. Résiliation dans le portail ou via Play.",
  },
  honesty: {
    kicker: "État",
    title: "Complet là où c’est écrit — vide là où ça manque.",
    lead: "Une page d’accueil ne doit pas faire comme si le magasin était ouvert ou le store déjà listé. D’où l’état honnête :",
    live: [
      "Home, Carte, planification, Parcours, Vélo dans le navigateur",
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
      title: "Vélo",
      body: "Vélos, composants, setup, entretien — aussi sans l’appli.",
    },
    {
      title: "Parcours",
      body: "GPX, collections, astuces, groupes. Partager sans fil.",
    },
  ],
  appSurfaces: [
    {
      title: "Sortir",
      body: "Ride-HUD, guidage, GPS en arrière-plan, écran verrouillé.",
    },
    {
      title: "Hors ligne",
      body: "Graphe de routage du pack sans réseau. Pas de carte pays, pas de Komoot Europe.",
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
      body: "L’ajouter au stand — ou rouler sans vélo.",
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
      "Une appli, quatre portes — pas quatre applis. Filtres sport sur la carte, setup sur le vélo.",
    doorsTitle: "Quatre portes à Home",
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
      "Guides pour la route, le gravel, le MTB et l’e-bike : planifier des sorties, autonomie en fourchette, setup selon le poids, Home avec quatre portes, partage par lien, pièces sur le vélo. Pas de clickbait affilié — ce qui manque au produit n’est pas promis ici.",
    related: "Suite",
  },
};

const IT: HomepageCopy = {
  intro: {
    kicker: "Cos’è FlowLine",
    title: "Ciclismo outdoor, senza timeline.",
    lead: "FlowLine è l’app del quotidiano, tra il giro serale e la tappa del weekend. Nel browser pianifichi, curi la bici e condividi una Mappe. Nell’app pedali: HUD, GPS, routing offline, sensori.",
    paragraphs: [
      "Home è lo stand — non un feed. Quattro porte: Home, Mappa, Percorsi, Bici. I pezzi stanno sulla bici, non come quinta scheda. Ride è il pulsante arancione, non la quinta scheda. Ciò che manca resta vuoto: niente chilometri finti, niente classifica, niente seconda cassa nel browser.",
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
      title: "Inizio",
      kicker: "Pedala",
      body: "La tua bici, il tempo, ciò che è rientrato. Un pulsante arancione. Niente barra KPI, niente stories. Pedala avvia l’app — la mappa serve a pianificare.",
    },
    {
      href: "/discover",
      title: "Mappa",
      kicker: "Davanti al cancello",
      body: "OpenStreetMap, uscite vicine vere, filtri sport. Pianifichi sul desktop: partenza, via, arrivo. Non c’è navigazione live nel browser — e non facciamo finta.",
    },
    {
      href: "/library",
      title: "Percorsi",
      kicker: "Salvato e condiviso",
      body: "Le tue uscite, consigli, link di invito. Condividi per link, non per timeline. Chi ha il link salva l’uscita in locale — senza account obbligatorio, senza traccia nel commento.",
    },
    {
      href: "/garage",
      title: "Bici",
      kicker: "Questa bici",
      body: "Aggiungere, setup, intervalli di manutenzione con fonte. Bracketing e fasce di autonomia sono Pro. Il negozio è in pausa — niente seconda cassa.",
    },
  ],
  split: {
    kicker: "Due superfici",
    title: "Il web è Home. L’app pedala.",
    webLead:
      "Ispirazione, pianificazione, cura e condivisione stanno alla scrivania. Il browser può restare vuoto dove GPS e sensori appartengono.",
    appLead:
      "In strada contano un display bloccato, il routing offline e un orologio sul ciclista. Non c’è un finto web per questo.",
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
    free: "0 € — Home, Mappa, Percorsi, una bici, navigazione nell’app.",
    pro: "6,99 €/mese oppure 59,99 €/anno. Disdetta nel portale o via Play.",
  },
  honesty: {
    kicker: "Stato",
    title: "Completo dove sta scritto — vuoto dove manca.",
    lead: "Una homepage non deve far finta che il negozio sia aperto o lo store già in elenco. Per questo lo stato onesto:",
    live: [
      "Home, Mappa, pianificazione, Percorsi, Bici nel browser",
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
      title: "Bici",
      body: "Bici, componenti, setup, manutenzione — anche senza app.",
    },
    {
      title: "Percorsi",
      body: "GPX, raccolte, consigli, gruppi. Condividi senza feed.",
    },
  ],
  appSurfaces: [
    {
      title: "Esci",
      body: "Ride-HUD, turn-by-turn, GPS in background, display bloccato.",
    },
    {
      title: "Offline",
      body: "Grafo di routing del pack senza rete. Nessuna carta nazionale, niente Komoot Europa.",
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
      body: "Aggiungerla allo stand — o pedalare senza bici.",
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
      "Un’app, quattro porte — non quattro app. Filtri sport sulla mappa, setup sulla bici.",
    doorsTitle: "Quattro porte a Home",
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
      "Guide per strada, gravel, MTB ed e-bike: pianificare uscite, autonomia come fascia, setup in base al peso, Home con quattro porte, condivisione per link, pezzi sulla bici. Niente clickbait affiliato — ciò che manca al prodotto non è promesso qui.",
    related: "Avanti",
  },
};

const NL: HomepageCopy = {
  intro: {
    kicker: "Wat FlowLine is",
    title: "Outdoor cycling, zonder tijdlijn.",
    lead: "FlowLine is de dagelijkse app tussen de doordeweekse ronde en de weekendetappe. In de browser plan je, verzorg je de fiets en deel je een Mappe. In de app rijd je: HUD, GPS, offline-routing, sensoren.",
    paragraphs: [
      "Home is de stand — geen feed. Vier deuren: Home, Kaart, Tochten, Fiets. Onderdelen zitten aan de fiets, niet als vijfde tab. Ride is de oranje knop, niet de vijfde tab. Wat ontbreekt blijft leeg: geen dummy-kilometers, geen klassement, geen tweede kassa in de browser.",
      "Openbare tochtpagina’s zijn redactionele ideeën met een pin. De lijn ontstaat als je plant — de Alster in Hamburg, niet standaard de Alpen. Community hangt aan de tocht: Stimmen, Mappe-links, uitnodigingslinks. Publieke profielen alleen met opt-in, zonder GPS-sporen.",
    ],
  },
  disciplines: [
    {
      title: "Race",
      href: "/discover?sport=road",
      body: "Asfalt, hoogtemeters, vlakke oevers. Filters en nabije ronden op de kaart — zonder verkeer als spel.",
    },
    {
      title: "Gravel",
      href: "/discover?sport=gravel",
      body: "Boswegen en mix. Het profiel „Gravel“ mijdt harde trails. Na regen blijft het eerlijk: glad is glad.",
    },
    {
      title: "MTB",
      href: "/discover?sport=mtb",
      body: "S-schalen in plaats van sterreninflatie. Navigatie in de app. Redactionele ideeën zoals Königstuhl — geen verzonnen downhill-GPX.",
    },
    {
      title: "E-Bike",
      href: "/guides/ebike-reichweite",
      body: "Actieradius als interval, niet als punt. Assist en kalibratie in Pro. Bosch live alleen native, niet in de tab.",
    },
    {
      title: "Touring & stad",
      href: "/discover?sport=urban",
      body: "Etappes, rustplekken, na het werk. Dezelfde tochten in de Mappe als op de kaart — geen tweede app voor alledag.",
    },
  ],
  doors: [
    {
      href: "/home",
      title: "Start",
      kicker: "Rijden",
      body: "Jouw fiets, het weer, wat er binnenkwam. Eén oranje knop. Geen KPI-balk, geen stories. Rijden start de app — de kaart is om te plannen.",
    },
    {
      href: "/discover",
      title: "Kaart",
      kicker: "Bij de poort",
      body: "OpenStreetMap, echte tochten in de buurt, sportfilters. Je plant op de desktop: start, via, finish. Live-navigatie in de browser is er niet — en we doen niet alsof.",
    },
    {
      href: "/library",
      title: "Tochten",
      kicker: "Opgeslagen en gedeeld",
      body: "Jouw ritten, tips, uitnodigingslinks. Delen via link, niet via tijdlijn. Wie de link heeft, slaat de tocht lokaal op — geen account verplicht, geen track in de reactie.",
    },
    {
      href: "/garage",
      title: "Fiets",
      kicker: "Deze fiets",
      body: "Toevoegen, setup, onderhoudsintervallen met bron. Bracketing en actieradius als interval zijn Pro. De winkel staat stil — geen tweede kassa.",
    },
  ],
  split: {
    kicker: "Twee oppervlakken",
    title: "Web is Home. De app rijdt.",
    webLead:
      "Inspiratie, plannen, onderhoud en delen horen aan het bureau. De browser mag leeg blijven waar GPS en sensoren thuishoren.",
    appLead:
      "Onderweg tellen een vergrendeld scherm, offline-routing en een horloge op de renner. Daar is geen web-namaak voor.",
  },
  tours: {
    kicker: "Bij de poort",
    title: "Ideeën uit de buurt, niet uit de Alpenvoorraad.",
    lead: "Vier redactionele tochten als start — Hamburg Alster, Heidelberg, Schwarzwald Gravel, Bodensee. Het zijn ideeën met een pin, geen ingemeten community-tracks. De lijn reken je onder Plannen.",
  },
  journey: {
    kicker: "Volgorde",
    title: "Zo ga je eruit — en kom je terug.",
    lead: "Aankomen, fiets aan de stand, een uur bij de poort, eruit, terug bij Home. Geen onboardingtheater, geen demofiets die kilometers faket.",
  },
  voices: {
    kicker: "Stimmen",
    title: "Aan de tocht, niet in een feed.",
    lead: "Redactioneel, duidelijk gemarkeerd. Korte tekst zonder track erbij. Nieuwe Stimmen starten in beoordeling.",
  },
  guides: {
    kicker: "Guides",
    title: "Lees na voor je weggaat.",
    lead: "Plannen, actieradius, setup, Home en delen — geen affiliate-clickbait. Wat het product mist, beloven we hier ook niet.",
    slugs: HOME_GUIDES.slugs,
  },
  pricing: {
    kicker: "Prijzen",
    title: "Free plant. Pro gaat dieper.",
    lead: "Kaart, plannen, één fiets, app-navigatie: gratis. Multi-fiets, bracketing, actieradius als interval en hogere chatlimieten: Pro. Checkout in het profiel, niet midden in een tocht. Store-listings volgen zodra ze live zijn.",
    free: "0 € — Home, Kaart, Tochten, één fiets, navigatie in de app.",
    pro: "6,99 €/maand of 59,99 €/jaar. Opzeggen in het portaal of via Play.",
  },
  honesty: {
    kicker: "Stand",
    title: "Compleet waar het staat — leeg waar het ontbreekt.",
    lead: "Een homepage mag niet doen alsof de winkel open is of de store al gelist. Daarom de eerlijke stand:",
    live: [
      "Home, Kaart, plannen, Tochten, Fiets in de browser",
      "Redactionele tochten en regio’s in DACH",
      "Stimmen, Mappe-links, redactionele profielen",
      "Free en Pro beschreven, checkout in het profiel (Stripe)",
    ],
    notYet: [
      "Een geldig adres in het Impressum — daarom shop-checkout geblokkeerd",
      "App Store- en Play-listings — HUD en sensoren komen met de native app",
      "Live-partnerboeking voor werkplaatsen — interesse per e-mail",
    ],
  },
  cta: {
    title: "De fiets staat. Jij komt terug.",
    body: "Open Home in de browser. De app neemt navigatie, offline en horloge over zodra de listings er zijn — tot dan blijft de stand eerlijk leeg in plaats van gevuld.",
  },
  webSurfaces: [
    {
      title: "Home, Kaart, plannen",
      body: "Inspiratie, nabije ronden, desktopplanner. Opslaan in de Mappe.",
    },
    {
      title: "Fiets",
      body: "Fietsen, onderdelen, setup, onderhoud — ook zonder de app.",
    },
    {
      title: "Tochten",
      body: "GPX, verzamelingen, tips, groepen. Delen zonder feed.",
    },
  ],
  appSurfaces: [
    {
      title: "Eruit",
      body: "Ride-HUD, turn-by-turn, GPS op de achtergrond, vergrendeld scherm.",
    },
    {
      title: "Offline",
      body: "Routinggraaf van het pack zonder netwerk. Geen landkaart, geen Komoot-Europa.",
    },
    {
      title: "Sensoren & horloge",
      body: "BLE, CSC, horloge op de renner. Koppelen alleen native — niet in de browser.",
    },
    {
      title: "Registratie",
      body: "Echte ritten ontstaan in de app. Home toont wat er binnenkwam.",
    },
  ],
  journeySteps: [
    {
      n: "1",
      title: "Aankomen",
      body: "Sport en gewicht — of overslaan. Geen demofiets, geen nepkilometers.",
    },
    {
      n: "2",
      title: "Fiets aan de stand",
      body: "Toevoegen aan de stand — of rijden zonder fiets.",
    },
    {
      n: "3",
      title: "Een uur bij de poort",
      body: "De kaart toont echte ronden in de buurt. Ontbreekt er een, dan blijft de poort leeg.",
    },
    {
      n: "4",
      title: "Eruit",
      body: "Eén oranje knop. Navigatie en sensoren draaien in de app.",
    },
    {
      n: "5",
      title: "Terug bij Home",
      body: "Wat er binnenkwam: analyse, setup-hint, onderhoud. Stimmen op de Platz.",
    },
  ],
  ui: {
    productMap: "Productkaart",
    bikesTitle: "Voor welke fietsen",
    bikesLead:
      "Eén app, vier deuren — geen vier apps. Sportfilters op de kaart, setup aan de fiets.",
    doorsTitle: "Vier deuren bij Home",
    doorsLead:
      "Home is de stand. Al het andere is een deur — geen stapel kaarten. Ride is geen tab.",
    onWebsite: "Op de website",
    inApp: "In de app",
    allRegions: "Alle regio’s",
    allGuides: "Alle guides",
    allQuestions: "Alle vragen",
    faqKicker: "FAQ",
    faqTitle: "Kort en eerlijk",
    faqLead: "Geen store-beloftes, geen verzonnen adressen.",
    alreadyHere: "Al hier",
    notYetTitle: "Nog niet — en niet verzonnen",
    editorial: "Redactioneel",
    free: "Free",
    pro: "Pro",
    pricesDetail: "Prijzen in detail",
    community: "Community",
    readMin: (n) => `${n} min`,
    readMinLong: (n) => `${n} min leestijd`,
    heroTagline: "De fiets woont hier.",
    heroLead: (rideOut) =>
      `Outdoor cycling, vereenvoudigd: plannen en verzorgen in de browser, rijden in de app. Drie seconden — de lucht, een uur bij de poort, één knop: ${rideOut}.`,
    heroFair: "Zo blijft het eerlijk",
    heroFoot: "Geen feed, geen KPI-balk, geen tweede kassa in de browser.",
    trustClose: "Sluiten",
    trustTitle: "Eerlijk vanaf het begin.",
    trustBody:
      "Sync, navigatie en export blijven vrij — geen verrassingen midden in de tocht.",
    trustOffline: "Offline ✓ vrij",
    trustOk: "Begrepen",
    faqPageLead:
      "Geen store-beloftes, geen verzonnen adressen, geen feed bij Home.",
    faqPageMoreBefore: "Meer schermen en flows staan onder",
    guidesIndexLead:
      "Guides voor race, gravel, MTB en e-bike: tochten plannen, actieradius als interval, setup naar gewicht, Home met vier deuren, delen via link, onderdelen aan de fiets. Geen affiliate-clickbait — wat het product mist, beloven we hier niet.",
    related: "Verder",
  },
};

const BY_LANG: Record<ChromeLang, HomepageCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function homepageCopy(lang: ChromeLang): HomepageCopy {
  return BY_LANG[lang];
}
