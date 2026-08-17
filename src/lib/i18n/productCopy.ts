import type { ChromeLang } from "./chromeLang";
import {
  PRODUCT_DOORS,
  SCREEN_GROUPS,
  WEB_APP_MATRIX,
  WORKFLOWS,
} from "../content/productMap";

export type ProductDoor = { href: string; title: string; body: string };
export type MatrixRow = { feature: string; web: string; app: string };
export type Workflow = {
  id: string;
  title: string;
  hint: string;
  steps: { label: string; href: string }[];
};
export type ScreenGroup = {
  title: string;
  hint: string;
  screens: { href: string; name: string; role: string }[];
};

export type ProductCopy = {
  doors: ProductDoor[];
  matrix: MatrixRow[];
  workflows: Workflow[];
  screenGroups: ScreenGroup[];
  ui: {
    kicker: string;
    title: string;
    lead: string;
    doorsLead: string;
    galleryHeading: string;
    galleryHint: string;
    whereRuns: string;
    colSurface: string;
    colWeb: string;
    colApp: string;
    journeyTitle: string;
    processes: string;
    processesLead: string;
    allScreens: string;
    allScreensLead: string;
    ctaLead: string;
  };
};

const DE: ProductCopy = {
  doors: PRODUCT_DOORS.map((d) => ({ href: d.href, title: d.title, body: d.body })),
  matrix: WEB_APP_MATRIX,
  workflows: WORKFLOWS,
  screenGroups: SCREEN_GROUPS,
  ui: {
    kicker: "Produkt",
    title: "Web ist der Hof. Die App fährt.",
    lead: "Dieselbe Anwendung, zwei Oberflächen. Im Browser planst, pflegst und teilst du: Hof, Karte, Platz, Werkstatt. Teile sitzen am Rad. Auf dem Gerät navigierst, zeichnest und koppelst du. Es gibt keinen Feed, keine zweite Kasse und kein Fake-GPS im Tab — leere Flächen bleiben leer.",
    doorsLead:
      "Ride ist kein Tab. Der Laden ist eine Tür aus der Werkstatt zu Shopify, kein fünfter Reiter.",
    galleryHeading: "Screens",
    galleryHint:
      "Design-System aus Logo und Bilder, zugeordnet zu den Türen. Ride-HUD bleibt die App.",
    whereRuns: "Was wo läuft",
    colSurface: "Fläche",
    colWeb: "Web",
    colApp: "App",
    journeyTitle: "So kommst du raus",
    processes: "Prozesse",
    processesLead:
      "Jeder Ablauf endet an einer echten Tür — nicht an einer leeren Seite.",
    allScreens: "Alle Screens",
    allScreensLead: "Öffentliche Website und Hof-App. Ride-HUD bleibt nativ.",
    ctaLead: "Öffne den Hof im Browser oder lade die App für Navigation und Uhr.",
  },
};

const EN: ProductCopy = {
  doors: [
    {
      href: "/home",
      title: "Home",
      body: "The stand: sky, an hour at the gate, what came in. One button — Ride out. No feed.",
    },
    {
      href: "/discover",
      title: "Map",
      body: "OpenStreetMap, nearby loops, sport filters, planning on the desktop. No live GPS in the tab.",
    },
    {
      href: "/library",
      title: "Platz",
      body: "Mappe, Stimmen, invite links. The same tours as on the map — share by link, not by timeline.",
    },
    {
      href: "/garage",
      title: "Workshop",
      body: "Park the bike, setup, service with a source. Parts for this bike — no shop tab, no second till.",
    },
  ],
  matrix: [
    { feature: "Home, Map, Platz, workshop", web: "full", app: "full" },
    { feature: "Plan and save a tour", web: "full", app: "full" },
    { feature: "SEO tours & regions", web: "full", app: "Deep Link" },
    { feature: "Live navigation / HUD", web: "Bridge to app", app: "full" },
    { feature: "Offline maps", web: "—", app: "Packs" },
    { feature: "GPS recording", web: "after sync", app: "native" },
    { feature: "Sensors, watch, BLE", web: "hint", app: "pair" },
    { feature: "Shop / till", web: "Gateway", app: "Gateway" },
    { feature: "Stimmen on the tour", web: "full", app: "full" },
    { feature: "Share Mappe & collections", web: "full", app: "Deep Link" },
    { feature: "Groups / ride together", web: "Roster + link", app: "HUD pins" },
    { feature: "Public Profile", web: "Opt-in", app: "Opt-in" },
  ],
  workflows: [
    {
      id: "first",
      title: "First visit",
      hint: "The website tells the story. Home takes you in.",
      steps: [
        { label: "Start", href: "/" },
        { label: "Product", href: "/produkt" },
        { label: "Sign in", href: "/anmelden" },
        { label: "Home", href: "/home" },
      ],
    },
    {
      id: "plan-ride",
      title: "Plan and ride",
      hint: "Web plans. The app rides.",
      steps: [
        { label: "Map", href: "/discover" },
        { label: "Plan", href: "/planner" },
        { label: "Platz / Mappe", href: "/library" },
        { label: "App bridge", href: "/ride" },
      ],
    },
    {
      id: "return",
      title: "After the ride",
      hint: "Recording stays native. Analysis may live in the browser.",
      steps: [
        { label: "What came in", href: "/activities" },
        { label: "After the ride", href: "/post-ride" },
        { label: "Die Tafel", href: "/home" },
        { label: "Workshop", href: "/garage" },
      ],
    },
    {
      id: "garage-shop",
      title: "Care and parts",
      hint: "The workshop knows the bike. The shop does not charge here.",
      steps: [
        { label: "Park the bike", href: "/garage?wizard=basic" },
        { label: "Service", href: "/garage?tab=maintenance" },
        { label: "Shop", href: "/shop" },
        { label: "Parts", href: "/shop/parts" },
      ],
    },
    {
      id: "platz",
      title: "Platz and Stimmen",
      hint: "No feed at Home. Community sits on the tour.",
      steps: [
        { label: "Platz", href: "/library" },
        { label: "Share", href: "/share" },
        { label: "Community", href: "/community" },
        { label: "Sample profile", href: "/u/mara_road" },
      ],
    },
    {
      id: "pro",
      title: "Account and Pro",
      hint: "Free plans. Pro goes deeper. Navigation in the app on both tiers.",
      steps: [
        { label: "Sign in", href: "/anmelden" },
        { label: "Prices", href: "/pricing" },
        { label: "Profile / plan", href: "/profile" },
        { label: "Data", href: "/privacy" },
      ],
    },
  ],
  screenGroups: [
    {
      title: "Public website",
      hint: "Story, SEO, trust. No five app tabs in the header.",
      screens: [
        { href: "/", name: "Start", role: "Hero, doors, journey" },
        { href: "/produkt", name: "Product", role: "Screens and flows" },
        { href: "/regions", name: "Regions", role: "DACH ideas, nearby" },
        { href: "/guides", name: "Guides", role: "Planning, setup, e-bike" },
        { href: "/guides/teilen-per-link", name: "Share guide", role: "Link instead of feed" },
        { href: "/guides/laden-ohne-zweite-kasse", name: "Shop guide", role: "No second till" },
        { href: "/community", name: "Community", role: "Events light, Platz" },
        { href: "/pricing", name: "Prices", role: "Free / Pro" },
        { href: "/download", name: "App", role: "Why native" },
        { href: "/anmelden", name: "Sign in", role: "Account, then Home" },
        { href: "/faq", name: "FAQ", role: "Web, app, prices" },
        { href: "/ueber", name: "About", role: "Brand, four doors" },
        { href: "/kontakt", name: "Contact", role: "Email, no bot" },
        { href: "/share", name: "Share", role: "Tour link and Mappe" },
        { href: "/u/mara_road", name: "Profile", role: "Editorial sample" },
      ],
    },
    {
      title: "Four doors (web app)",
      hint: "The same IA as in the native app. Ride is not a tab. Parts come from the workshop.",
      screens: [
        { href: "/home", name: "Home", role: "Stand, sky, gate" },
        { href: "/discover", name: "Map", role: "OSM, loops, filters" },
        { href: "/planner", name: "Plan", role: "Start, via, destination" },
        { href: "/library", name: "Platz", role: "Mappe, Stimmen, groups" },
        { href: "/garage", name: "Workshop", role: "Die Box, setup, care, parts" },
      ],
    },
    {
      title: "Ride and return",
      hint: "HUD only in the app. Web shows the bridge, then the file.",
      screens: [
        { href: "/ride", name: "App bridge", role: "Deep Link, no live GPS" },
        { href: "/activities", name: "What came in", role: "List after sync" },
        { href: "/post-ride", name: "After the ride", role: "Feedback, setup" },
      ],
    },
    {
      title: "Account, Coach, shop",
      hint: "Beside the doors — reachable, not as a feed.",
      screens: [
        { href: "/profile", name: "Profile", role: "Account, riding style, plan" },
        { href: "/privacy", name: "Data", role: "Export, zones, family" },
        { href: "/chat", name: "Coach", role: "Power user, limits" },
        { href: "/shop/parts", name: "Parts", role: "Fit to the workshop" },
        { href: "/checkout", name: "Checkout", role: "Pointer to Shopify" },
      ],
    },
    {
      title: "Sharing and legal",
      hint: "Links without an account required. Legal without overlay.",
      screens: [
        { href: "/share/t/demo", name: "Tour link", role: "Into the Mappe" },
        { href: "/share/c/demo", name: "Collection", role: "Shared Mappe" },
        { href: "/legal/impressum", name: "Imprint", role: "Provider" },
        { href: "/legal/datenschutz", name: "Privacy", role: "GDPR" },
        { href: "/legal/agb", name: "Terms", role: "Contract" },
        { href: "/legal/widerruf", name: "Withdrawal", role: "Plan / shop" },
      ],
    },
  ],
  ui: {
    kicker: "Product",
    title: "Web is Home. The app rides.",
    lead: "The same app, two surfaces. In the browser you plan, look after the bike and share: Home, Map, Platz, workshop, shop door. On the device you navigate, record and pair. There is no feed, no second till and no fake GPS in the tab — empty areas stay empty.",
    doorsLead: "Ride is not a tab. The shop is a door to Shopify, not a second shop.",
    galleryHeading: "Screens",
    galleryHint:
      "Design system from Logo und Bilder, mapped to the doors. Ride HUD stays the app.",
    whereRuns: "What runs where",
    colSurface: "Surface",
    colWeb: "Web",
    colApp: "App",
    journeyTitle: "How you get out",
    processes: "Flows",
    processesLead: "Every flow ends at a real door — not on an empty page.",
    allScreens: "All screens",
    allScreensLead: "Public website and Home app. Ride HUD stays native.",
    ctaLead: "Open Home in the browser, or get the app for navigation and the watch.",
  },
};

const FR: ProductCopy = {
  doors: [
    {
      href: "/home",
      title: "Home",
      body: "Le stand : ciel, une heure devant la porte, ce qui est rentré. Un bouton — Sortir. Pas de fil.",
    },
    {
      href: "/discover",
      title: "Carte",
      body: "OpenStreetMap, boucles proches, filtres sport, planification sur le bureau. Pas de GPS live dans l’onglet.",
    },
    {
      href: "/library",
      title: "Platz",
      body: "Mappe, Stimmen, liens d’invitation. Les mêmes sorties que sur la carte — partager par lien, pas par fil.",
    },
    {
      href: "/garage",
      title: "Atelier",
      body: "Garer le vélo, setup, entretien avec source. Pièces pour ce vélo — pas d’onglet magasin, pas de deuxième caisse.",
    },
  ],
  matrix: [
    { feature: "Home, Carte, Platz, atelier", web: "complet", app: "complet" },
    { feature: "Planifier et enregistrer une sortie", web: "complet", app: "complet" },
    { feature: "Sorties SEO et régions", web: "complet", app: "Deep Link" },
    { feature: "Navigation live / HUD", web: "Pont vers l’appli", app: "complet" },
    { feature: "Cartes hors ligne", web: "—", app: "Packs" },
    { feature: "Enregistrement GPS", web: "après sync", app: "natif" },
    { feature: "Capteurs, montre, BLE", web: "indice", app: "coupler" },
    { feature: "Magasin / caisse", web: "Gateway", app: "Gateway" },
    { feature: "Stimmen sur la sortie", web: "complet", app: "complet" },
    { feature: "Partager Mappe et collections", web: "complet", app: "Deep Link" },
    { feature: "Groupes / sortir ensemble", web: "Roster + lien", app: "Pins HUD" },
    { feature: "Public Profile", web: "Opt-in", app: "Opt-in" },
  ],
  workflows: [
    {
      id: "first",
      title: "Première visite",
      hint: "Le site raconte. Home t’accueille.",
      steps: [
        { label: "Accueil", href: "/" },
        { label: "Produit", href: "/produkt" },
        { label: "Se connecter", href: "/anmelden" },
        { label: "Home", href: "/home" },
      ],
    },
    {
      id: "plan-ride",
      title: "Planifier et rouler",
      hint: "Le web planifie. L’appli roule.",
      steps: [
        { label: "Carte", href: "/discover" },
        { label: "Planifier", href: "/planner" },
        { label: "Platz / Mappe", href: "/library" },
        { label: "Pont appli", href: "/ride" },
      ],
    },
    {
      id: "return",
      title: "Après la sortie",
      hint: "L’enregistrement reste natif. L’analyse peut vivre dans le navigateur.",
      steps: [
        { label: "Ce qui est rentré", href: "/activities" },
        { label: "Après la sortie", href: "/post-ride" },
        { label: "Die Tafel", href: "/home" },
        { label: "Atelier", href: "/garage" },
      ],
    },
    {
      id: "garage-shop",
      title: "Entretien et pièces",
      hint: "L’atelier connaît le vélo. Le magasin n’encaisse pas ici.",
      steps: [
        { label: "Garer le vélo", href: "/garage?wizard=basic" },
        { label: "Entretien", href: "/garage?tab=maintenance" },
        { label: "Magasin", href: "/shop" },
        { label: "Pièces", href: "/shop/parts" },
      ],
    },
    {
      id: "platz",
      title: "Platz et Stimmen",
      hint: "Pas de fil à Home. La communauté tient à la sortie.",
      steps: [
        { label: "Platz", href: "/library" },
        { label: "Partager", href: "/share" },
        { label: "Community", href: "/community" },
        { label: "Profil exemple", href: "/u/mara_road" },
      ],
    },
    {
      id: "pro",
      title: "Compte et Pro",
      hint: "Free planifie. Pro approfondit. Navigation dans l’appli aux deux niveaux.",
      steps: [
        { label: "Se connecter", href: "/anmelden" },
        { label: "Prix", href: "/pricing" },
        { label: "Profil / abo", href: "/profile" },
        { label: "Données", href: "/privacy" },
      ],
    },
  ],
  screenGroups: [
    {
      title: "Site public",
      hint: "Histoire, SEO, confiance. Pas cinq onglets d’appli dans l’en-tête.",
      screens: [
        { href: "/", name: "Accueil", role: "Hero, portes, parcours" },
        { href: "/produkt", name: "Produit", role: "Écrans et parcours" },
        { href: "/regions", name: "Régions", role: "Idées DACH, proximité" },
        { href: "/guides", name: "Guides", role: "Planification, setup, e-bike" },
        { href: "/guides/teilen-per-link", name: "Guide partager", role: "Lien plutôt que fil" },
        { href: "/guides/laden-ohne-zweite-kasse", name: "Guide magasin", role: "Pas de deuxième caisse" },
        { href: "/community", name: "Community", role: "Events light, Platz" },
        { href: "/pricing", name: "Prix", role: "Free / Pro" },
        { href: "/download", name: "App", role: "Pourquoi natif" },
        { href: "/anmelden", name: "Se connecter", role: "Compte, puis Home" },
        { href: "/faq", name: "FAQ", role: "Web, appli, prix" },
        { href: "/ueber", name: "À propos", role: "Marque, cinq portes" },
        { href: "/kontakt", name: "Contact", role: "E-mail, pas de bot" },
        { href: "/share", name: "Partager", role: "Lien de sortie et Mappe" },
        { href: "/u/mara_road", name: "Profil", role: "Exemple éditorial" },
      ],
    },
    {
      title: "Quatre portes (appli web)",
      hint: "La même IA que dans l’appli native. Ride n’est pas un onglet. Les pièces viennent de l’atelier.",
      screens: [
        { href: "/home", name: "Home", role: "Stand, ciel, porte" },
        { href: "/discover", name: "Carte", role: "OSM, boucles, filtres" },
        { href: "/planner", name: "Planifier", role: "Départ, via, arrivée" },
        { href: "/library", name: "Platz", role: "Mappe, Stimmen, groupes" },
        { href: "/garage", name: "Atelier", role: "Die Box, setup, entretien, pièces" },
      ],
    },
    {
      title: "Sortie et retour",
      hint: "HUD seulement dans l’appli. Le web montre le pont, puis le dossier.",
      screens: [
        { href: "/ride", name: "Pont appli", role: "Deep Link, pas de GPS live" },
        { href: "/activities", name: "Ce qui est rentré", role: "Liste après sync" },
        { href: "/post-ride", name: "Après la sortie", role: "Feedback, setup" },
      ],
    },
    {
      title: "Compte, Coach, magasin",
      hint: "À côté des portes — joignable, pas comme un fil.",
      screens: [
        { href: "/profile", name: "Profil", role: "Compte, style, abo" },
        { href: "/privacy", name: "Données", role: "Export, zones, famille" },
        { href: "/chat", name: "Coach", role: "Power-user, limites" },
        { href: "/shop/parts", name: "Pièces", role: "Fit à l’atelier" },
        { href: "/checkout", name: "Caisse", role: "Renvoi vers Shopify" },
      ],
    },
    {
      title: "Partage et mentions",
      hint: "Liens sans compte obligatoire. Mentions sans overlay.",
      screens: [
        { href: "/share/t/demo", name: "Lien de sortie", role: "Dans la Mappe" },
        { href: "/share/c/demo", name: "Collection", role: "Mappe partagée" },
        { href: "/legal/impressum", name: "Mentions légales", role: "Éditeur" },
        { href: "/legal/datenschutz", name: "Confidentialité", role: "RGPD" },
        { href: "/legal/agb", name: "CGV", role: "Contrat" },
        { href: "/legal/widerruf", name: "Rétractation", role: "Abo / magasin" },
      ],
    },
  ],
  ui: {
    kicker: "Produit",
    title: "Le web est Home. L’appli roule.",
    lead: "La même appli, deux surfaces. Dans le navigateur tu planifies, tu soignes et tu partages : Home, Carte, Platz, atelier, porte magasin. Sur l’appareil tu navigues, tu enregistres et tu couples. Pas de fil, pas de deuxième caisse, pas de GPS fictif dans l’onglet — les surfaces vides restent vides.",
    doorsLead:
      "Ride n’est pas un onglet. Le magasin est une porte vers Shopify, pas un deuxième shop.",
    galleryHeading: "Écrans",
    galleryHint:
      "Système de design issu de Logo und Bilder, associé aux portes. Le Ride-HUD reste l’appli.",
    whereRuns: "Ce qui tourne où",
    colSurface: "Surface",
    colWeb: "Web",
    colApp: "App",
    journeyTitle: "Comment tu sors",
    processes: "Parcours",
    processesLead:
      "Chaque parcours s’arrête à une vraie porte — pas sur une page vide.",
    allScreens: "Tous les écrans",
    allScreensLead: "Site public et appli Home. Le Ride-HUD reste natif.",
    ctaLead: "Ouvre Home dans le navigateur, ou charge l’appli pour la navigation et la montre.",
  },
};

const IT: ProductCopy = {
  doors: [
    {
      href: "/home",
      title: "Home",
      body: "Lo stand: cielo, un’ora davanti al cancello, ciò che è rientrato. Un pulsante — Esci. Niente feed.",
    },
    {
      href: "/discover",
      title: "Mappa",
      body: "OpenStreetMap, anelli vicini, filtri sport, pianificazione sul desktop. Niente GPS live nel tab.",
    },
    {
      href: "/library",
      title: "Platz",
      body: "Mappe, Stimmen, link di invito. Le stesse uscite della mappa — condividi per link, non per timeline.",
    },
    {
      href: "/garage",
      title: "Officina",
      body: "Parcheggiare la bici, setup, manutenzione con fonte. Pezzi per questa bici — niente tab negozio, niente seconda cassa.",
    },
  ],
  matrix: [
    { feature: "Home, Mappa, Platz, officina", web: "pieno", app: "pieno" },
    { feature: "Pianificare e salvare un’uscita", web: "pieno", app: "pieno" },
    { feature: "Uscite SEO e regioni", web: "pieno", app: "Deep Link" },
    { feature: "Navigazione live / HUD", web: "Ponte all’app", app: "pieno" },
    { feature: "Mappe offline", web: "—", app: "Packs" },
    { feature: "Registrazione GPS", web: "dopo sync", app: "nativo" },
    { feature: "Sensori, orologio, BLE", web: "hint", app: "accoppia" },
    { feature: "Negozio / cassa", web: "Gateway", app: "Gateway" },
    { feature: "Stimmen sull’uscita", web: "pieno", app: "pieno" },
    { feature: "Condividere Mappe e raccolte", web: "pieno", app: "Deep Link" },
    { feature: "Gruppi / uscire insieme", web: "Roster + link", app: "Pin HUD" },
    { feature: "Public Profile", web: "Opt-in", app: "Opt-in" },
  ],
  workflows: [
    {
      id: "first",
      title: "Prima visita",
      hint: "Il sito racconta. Home ti accoglie.",
      steps: [
        { label: "Inizio", href: "/" },
        { label: "Prodotto", href: "/produkt" },
        { label: "Accedi", href: "/anmelden" },
        { label: "Home", href: "/home" },
      ],
    },
    {
      id: "plan-ride",
      title: "Pianifica e pedala",
      hint: "Il web pianifica. L’app pedala.",
      steps: [
        { label: "Mappa", href: "/discover" },
        { label: "Pianifica", href: "/planner" },
        { label: "Platz / Mappe", href: "/library" },
        { label: "Ponte app", href: "/ride" },
      ],
    },
    {
      id: "return",
      title: "Dopo l’uscita",
      hint: "La registrazione resta nativa. L’analisi può stare nel browser.",
      steps: [
        { label: "Cosa è rientrato", href: "/activities" },
        { label: "Dopo l’uscita", href: "/post-ride" },
        { label: "Die Tafel", href: "/home" },
        { label: "Officina", href: "/garage" },
      ],
    },
    {
      id: "garage-shop",
      title: "Cura e ricambi",
      hint: "L’officina conosce la bici. Il negozio non incassa qui.",
      steps: [
        { label: "Parcheggia la bici", href: "/garage?wizard=basic" },
        { label: "Manutenzione", href: "/garage?tab=maintenance" },
        { label: "Negozio", href: "/shop" },
        { label: "Ricambi", href: "/shop/parts" },
      ],
    },
    {
      id: "platz",
      title: "Platz e Stimmen",
      hint: "Niente feed a Home. La community sta sull’uscita.",
      steps: [
        { label: "Platz", href: "/library" },
        { label: "Condividi", href: "/share" },
        { label: "Community", href: "/community" },
        { label: "Profilo esempio", href: "/u/mara_road" },
      ],
    },
    {
      id: "pro",
      title: "Account e Pro",
      hint: "Free pianifica. Pro approfondisce. Navigazione nell’app su entrambi i livelli.",
      steps: [
        { label: "Accedi", href: "/anmelden" },
        { label: "Prezzi", href: "/pricing" },
        { label: "Profilo / abbonamento", href: "/profile" },
        { label: "Dati", href: "/privacy" },
      ],
    },
  ],
  screenGroups: [
    {
      title: "Sito pubblico",
      hint: "Storia, SEO, fiducia. Niente cinque schede app nell’intestazione.",
      screens: [
        { href: "/", name: "Inizio", role: "Hero, porte, percorso" },
        { href: "/produkt", name: "Prodotto", role: "Schermate e flussi" },
        { href: "/regions", name: "Regioni", role: "Idee DACH, vicino" },
        { href: "/guides", name: "Guide", role: "Pianificazione, setup, e-bike" },
        { href: "/guides/teilen-per-link", name: "Guida condividi", role: "Link invece del feed" },
        { href: "/guides/laden-ohne-zweite-kasse", name: "Guida negozio", role: "Niente seconda cassa" },
        { href: "/community", name: "Community", role: "Eventi light, Platz" },
        { href: "/pricing", name: "Prezzi", role: "Free / Pro" },
        { href: "/download", name: "App", role: "Perché nativa" },
        { href: "/anmelden", name: "Accedi", role: "Account, poi Home" },
        { href: "/faq", name: "FAQ", role: "Web, app, prezzi" },
        { href: "/ueber", name: "Info", role: "Marca, cinque porte" },
        { href: "/kontakt", name: "Contatto", role: "E-mail, niente bot" },
        { href: "/share", name: "Condividi", role: "Link uscita e Mappe" },
        { href: "/u/mara_road", name: "Profilo", role: "Esempio editoriale" },
      ],
    },
    {
      title: "Quattro porte (app web)",
      hint: "La stessa IA dell’app nativa. Ride non è una scheda. I pezzi vengono dall’officina.",
      screens: [
        { href: "/home", name: "Home", role: "Stand, cielo, cancello" },
        { href: "/discover", name: "Mappa", role: "OSM, anelli, filtri" },
        { href: "/planner", name: "Pianifica", role: "Partenza, via, arrivo" },
        { href: "/library", name: "Platz", role: "Mappe, Stimmen, gruppi" },
        { href: "/garage", name: "Officina", role: "Die Box, setup, cura, pezzi" },
      ],
    },
    {
      title: "Uscita e rientro",
      hint: "HUD solo nell’app. Il web mostra il ponte, poi il fascicolo.",
      screens: [
        { href: "/ride", name: "Ponte app", role: "Deep Link, niente GPS live" },
        { href: "/activities", name: "Cosa è rientrato", role: "Lista dopo sync" },
        { href: "/post-ride", name: "Dopo l’uscita", role: "Feedback, setup" },
      ],
    },
    {
      title: "Account, Coach, negozio",
      hint: "Accanto alle porte — raggiungibile, non come feed.",
      screens: [
        { href: "/profile", name: "Profilo", role: "Account, stile, abbonamento" },
        { href: "/privacy", name: "Dati", role: "Export, zone, famiglia" },
        { href: "/chat", name: "Coach", role: "Power user, limiti" },
        { href: "/shop/parts", name: "Ricambi", role: "Fit all’officina" },
        { href: "/checkout", name: "Cassa", role: "Rinvio a Shopify" },
      ],
    },
    {
      title: "Condivisione e legale",
      hint: "Link senza account obbligatorio. Legale senza overlay.",
      screens: [
        { href: "/share/t/demo", name: "Link uscita", role: "Nella Mappe" },
        { href: "/share/c/demo", name: "Raccolta", role: "Mappe condivisa" },
        { href: "/legal/impressum", name: "Impressum", role: "Fornitore" },
        { href: "/legal/datenschutz", name: "Privacy", role: "GDPR" },
        { href: "/legal/agb", name: "Termini", role: "Contratto" },
        { href: "/legal/widerruf", name: "Recesso", role: "Abbonamento / negozio" },
      ],
    },
  ],
  ui: {
    kicker: "Prodotto",
    title: "Il web è Home. L’app pedala.",
    lead: "La stessa app, due superfici. Nel browser pianifichi, curi e condividi: Home, Mappa, Platz, officina, porta negozio. Sul dispositivo navighi, registri e accoppi. Niente feed, niente seconda cassa, niente GPS finto nel tab — le superfici vuote restano vuote.",
    doorsLead:
      "Ride non è una scheda. Il negozio è una porta verso Shopify, non un secondo shop.",
    galleryHeading: "Schermate",
    galleryHint:
      "Design system da Logo und Bilder, assegnato alle porte. Il Ride-HUD resta l’app.",
    whereRuns: "Cosa gira dove",
    colSurface: "Superficie",
    colWeb: "Web",
    colApp: "App",
    journeyTitle: "Così esci",
    processes: "Flussi",
    processesLead:
      "Ogni flusso finisce a una porta vera — non su una pagina vuota.",
    allScreens: "Tutte le schermate",
    allScreensLead: "Sito pubblico e app Home. Il Ride-HUD resta nativo.",
    ctaLead: "Apri Home nel browser, o scarica l’app per navigazione e orologio.",
  },
};

const BY_LANG: Record<ChromeLang, ProductCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
};

export function productCopy(lang: ChromeLang): ProductCopy {
  return BY_LANG[lang];
}
