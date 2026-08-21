import type { ChromeLang } from "./chromeLang";
import { FAQ_ITEMS } from "../content/faq";

export type FaqItem = {
  id: string;
  q: string;
  a: string;
  links?: { href: string; label: string }[];
};

const EN: FaqItem[] = [
  {
    id: "was",
    q: "What is FlowLine?",
    a: "FlowLine is outdoor cycling with a Home: plan, look after the bike, share in the browser — ride in the app. Four doors, no feed, no second till.",
    links: [
      { href: "/produkt", label: "Product map" },
      { href: "/ueber", label: "About FlowLine" },
    ],
  },
  {
    id: "fuer-wen",
    q: "Who is FlowLine for?",
    a: "For road, gravel, MTB, e-bike, touring and city. One app, four doors — not four apps. If you want a feed or a leaderboard, this is the wrong place. If you want to plan tours, look after the bike and share without a timeline, this is the right place.",
    links: [
      { href: "/regions", label: "Regions" },
      { href: "/karten", label: "Maps" },
      { href: "/produkt", label: "Product" },
    ],
  },
  {
    id: "web-app",
    q: "What runs in the browser, what in the app?",
    a: "On the web: Home, Map, planning, Tours, Bike. In the app: Ride HUD, offline routing, GPS recording, sensors and watch. There is no live navigation in the tab.",
    links: [
      { href: "/guides/web-vs-app", label: "Guide: Web vs. App" },
      { href: "/download", label: "App" },
    ],
  },
  {
    id: "konto",
    q: "Do I need an account?",
    a: "No. Home stays usable locally. An account syncs with the app and unlocks Pro in the profile.",
    links: [{ href: "/anmelden", label: "Sign in" }],
  },
  {
    id: "ohne-app",
    q: "Does FlowLine work only in the browser?",
    a: "Planning, Map, Tours and Bike: yes. Navigation, offline, GPS recording, sensors and watch need the native app. There is no live navigation in the tab — and no dummy that pretends there is.",
    links: [
      { href: "/guides/web-vs-app", label: "Guide: Web vs. App" },
      { href: "/download", label: "App" },
    ],
  },
  {
    id: "karten",
    q: "Where can I ride with a real map?",
    a: "Online in nine regions: DACH, France, southern Alps, Benelux, northern, central and southern Italy, Catalonia/Pyrenees, southern England. In DACH the atlas and from zoom 12 the ways for DE, AT, CH and LI — not only in ten cities. The map follows the viewport. Offline these are city packs for routing in the app — not a country map. Sicily, Sardinia, Scandinavia, Poland, the rest of the UK and Iberia are holes.",
    links: [
      { href: "/karten", label: "Maps" },
      { href: "/discover", label: "Open the map" },
      { href: "/download", label: "App" },
    ],
  },
  {
    id: "preise",
    q: "What does Pro cost?",
    a: "Free plans and navigates in the app. Pro costs 6.99 €/month or 59.99 €/year — multi-bike, bracketing, range spans, higher chat limits. Checkout in the profile (Stripe) or Play Billing on Android. No subscription in the middle of a ride.",
    links: [{ href: "/pricing", label: "Prices" }],
  },
  {
    id: "community",
    q: "Is there a community / a feed?",
    a: "Community sits on the tour: Stimmen, Mappe links, invite links, optional public profile. There is no timeline at Home, no leaderboard and no live GPS at the gate.",
    links: [
      { href: "/community", label: "Community" },
      { href: "/library", label: "Platz" },
    ],
  },
  {
    id: "teilen",
    q: "How do I share a tour or a Mappe?",
    a: "By link, not by feed. Whoever has the link saves the tour locally into the Mappe — no account required. Stimmen and groups stay on Platz. Public profiles are opt-in and carry no GPS traces.",
    links: [
      { href: "/share", label: "Share" },
      { href: "/share/t/demo", label: "Sample tour" },
      { href: "/guides/teilen-per-link", label: "Guide: Share" },
    ],
  },
  {
    id: "shop",
    q: "Can I buy spare parts here?",
    a: "No. The shop and Shopify are off for now. The bike stays for setup and service — no till in FlowLine.",
    links: [{ href: "/garage", label: "Bike" }],
  },
  {
    id: "regionen",
    q: "Are the tours real GPS traces?",
    a: "Public tour pages are editorial ideas with a pin. The line appears when you plan with the routing profile — no guaranteed GPX file and no dummy Alps if you are standing in Hamburg.",
    links: [
      { href: "/regions", label: "Regions" },
      { href: "/karten", label: "Maps" },
      { href: "/discover", label: "Map" },
    ],
  },
  {
    id: "daten",
    q: "What happens to my data?",
    a: "Offline-first, GDPR, export in the profile. Stimmen without a track attached. Public profile only with opt-in. Sync and navigation stay free.",
    links: [{ href: "/legal/datenschutz", label: "Privacy" }],
  },
  {
    id: "app-stores",
    q: "Where do I get the app?",
    a: "Store links appear once the listings are live. Until then Home, Map, Tours and the bike run in the browser. HUD, offline and sensors come with the native app.",
    links: [{ href: "/download", label: "App" }],
  },
  {
    id: "kontakt",
    q: "How do I reach you?",
    a: "By email. Name and a serviceable address are in the imprint once they are on file — we do not invent them.",
    links: [
      { href: "/kontakt", label: "Contact" },
      { href: "/legal/impressum", label: "Imprint" },
    ],
  },
];

const FR: FaqItem[] = [
  {
    id: "was",
    q: "Qu’est-ce que FlowLine ?",
    a: "FlowLine est le vélo dehors avec un Home : planifier, soigner, partager dans le navigateur — rouler dans l’appli. Quatre portes, pas de fil, pas de deuxième caisse.",
    links: [
      { href: "/produkt", label: "Carte produit" },
      { href: "/ueber", label: "À propos de FlowLine" },
    ],
  },
  {
    id: "fuer-wen",
    q: "Pour qui est FlowLine ?",
    a: "Pour la route, le gravel, le MTB, l’e-bike, le touring et la ville. Une appli, quatre portes — pas quatre applis. Si tu cherches un fil ou un classement, tu n’es pas au bon endroit. Si tu veux planifier des sorties, soigner le vélo et partager sans timeline, tu es au bon.",
    links: [
      { href: "/regions", label: "Régions" },
      { href: "/karten", label: "Cartes" },
      { href: "/produkt", label: "Produit" },
    ],
  },
  {
    id: "web-app",
    q: "Qu’est-ce qui tourne dans le navigateur, qu’est-ce qui tourne dans l’appli ?",
    a: "Sur le web : Home, Carte, planifier, Parcours, Vélo. Dans l’appli : Ride-HUD, routage hors ligne, enregistrement GPS, capteurs et montre. Il n’y a pas de navigation live dans l’onglet.",
    links: [
      { href: "/guides/web-vs-app", label: "Guide : Web vs. App" },
      { href: "/download", label: "App" },
    ],
  },
  {
    id: "konto",
    q: "Est-ce que j’ai besoin d’un compte ?",
    a: "Non. Home reste utilisable en local. Un compte synchronise avec l’appli et débloque Pro dans le profil.",
    links: [{ href: "/anmelden", label: "Se connecter" }],
  },
  {
    id: "ohne-app",
    q: "FlowLine marche seulement dans le navigateur ?",
    a: "Planifier, Carte, Parcours et Vélo : oui. Navigation, hors ligne, enregistrement GPS, capteurs et montre ont besoin de l’appli native. Il n’y a pas de navigation live dans l’onglet — et pas de simulacre qui fait semblant.",
    links: [
      { href: "/guides/web-vs-app", label: "Guide : Web vs. App" },
      { href: "/download", label: "App" },
    ],
  },
  {
    id: "karten",
    q: "Où puis-je rouler avec une vraie carte ?",
    a: "En ligne dans neuf régions : DACH, France, Alpes sud, Benelux, Italie nord, centre et sud, Catalogne/Pyrénées, sud de l’Angleterre. En DACH l’atlas et dès le zoom 12 les voies pour DE, AT, CH et LI — pas seulement dans dix villes. La carte suit le cadre. Hors ligne ce sont des packs ville pour le routing dans l’appli — pas une carte pays. Sicile, Sardaigne, Scandinavie, Pologne, le reste du UK et de l’Ibérie sont des trous.",
    links: [
      { href: "/karten", label: "Cartes" },
      { href: "/discover", label: "Ouvrir la carte" },
      { href: "/download", label: "App" },
    ],
  },
  {
    id: "preise",
    q: "Combien coûte Pro ?",
    a: "Free planifie et navigue dans l’appli. Pro coûte 6,99 €/mois ou 59,99 €/an — multi-vélo, bracketing, fourchettes d’autonomie, limites de chat plus hautes. Checkout dans le profil (Stripe) ou Play Billing sur Android. Pas d’abo au milieu de la sortie.",
    links: [{ href: "/pricing", label: "Prix" }],
  },
  {
    id: "community",
    q: "Y a-t-il une community / un fil ?",
    a: "La communauté tient à la sortie : Stimmen, liens Mappe, liens d’invitation, profil public optionnel. Pas de fil à Home, pas de classement et pas de GPS live devant la porte.",
    links: [
      { href: "/community", label: "Community" },
      { href: "/library", label: "Platz" },
    ],
  },
  {
    id: "teilen",
    q: "Comment je partage une sortie ou une Mappe ?",
    a: "Par lien, pas par fil. Qui a le lien enregistre la sortie en local dans la Mappe — sans compte obligatoire. Stimmen et groupes restent sur le Platz. Les profils publics sont opt-in et ne portent pas de traces GPS.",
    links: [
      { href: "/share", label: "Partager" },
      { href: "/share/t/demo", label: "Exemple de sortie" },
      { href: "/guides/teilen-per-link", label: "Guide : Partager" },
    ],
  },
  {
    id: "shop",
    q: "Est-ce que je peux acheter des pièces ici ?",
    a: "Non. Le magasin et Shopify sont coupés pour l’instant. Le vélo reste pour le setup et l’entretien — pas de caisse dans FlowLine.",
    links: [{ href: "/garage", label: "Vélo" }],
  },
  {
    id: "regionen",
    q: "Les sorties sont-elles de vraies traces GPS ?",
    a: "Les pages publiques sont des idées éditoriales avec une épingle. La ligne apparaît quand tu planifies avec le profil de routing — pas de fichier GPX garanti et pas d’Alpes fictives si tu es à Hamburg.",
    links: [
      { href: "/regions", label: "Régions" },
      { href: "/karten", label: "Cartes" },
      { href: "/discover", label: "Carte" },
    ],
  },
  {
    id: "daten",
    q: "Que deviennent mes données ?",
    a: "Offline-first, RGPD, export dans le profil. Stimmen sans trace jointe. Profil public seulement avec opt-in. Sync et navigation restent libres.",
    links: [{ href: "/legal/datenschutz", label: "Confidentialité" }],
  },
  {
    id: "app-stores",
    q: "Où je charge l’appli ?",
    a: "Les liens store apparaissent dès que les listings sont en ligne. Jusque-là Home, Carte, Parcours et le vélo tournent dans le navigateur. HUD, hors ligne et capteurs viennent avec l’appli native.",
    links: [{ href: "/download", label: "App" }],
  },
  {
    id: "kontakt",
    q: "Comment je vous contacte ?",
    a: "Par e-mail. Le nom et une adresse de signification sont dans les mentions légales dès qu’ils sont déposés — on ne les invente pas.",
    links: [
      { href: "/kontakt", label: "Contact" },
      { href: "/legal/impressum", label: "Mentions légales" },
    ],
  },
];

const IT: FaqItem[] = [
  {
    id: "was",
    q: "Cos’è FlowLine?",
    a: "FlowLine è ciclismo outdoor con una Home: pianificare, curare, condividere nel browser — pedalare nell’app. Quattro porte, niente feed, niente seconda cassa.",
    links: [
      { href: "/produkt", label: "Mappa prodotto" },
      { href: "/ueber", label: "Su FlowLine" },
    ],
  },
  {
    id: "fuer-wen",
    q: "Per chi è FlowLine?",
    a: "Per strada, gravel, MTB, e-bike, touring e città. Un’app, quattro porte — non quattro app. Se cerchi un feed o una classifica, sei nel posto sbagliato. Se vuoi pianificare uscite, curare la bici e condividere senza timeline, sei nel posto giusto.",
    links: [
      { href: "/regions", label: "Regioni" },
      { href: "/karten", label: "Carte" },
      { href: "/produkt", label: "Prodotto" },
    ],
  },
  {
    id: "web-app",
    q: "Cosa gira nel browser, cosa nell’app?",
    a: "Sul web: Home, Mappa, pianifica, Percorsi, Bici. Nell’app: Ride-HUD, routing offline, registrazione GPS, sensori e orologio. Non c’è navigazione live nel tab.",
    links: [
      { href: "/guides/web-vs-app", label: "Guida: Web vs. App" },
      { href: "/download", label: "App" },
    ],
  },
  {
    id: "konto",
    q: "Serve un account?",
    a: "No. Home resta usabile in locale. Un account sincronizza con l’app e sblocca Pro nel profilo.",
    links: [{ href: "/anmelden", label: "Accedi" }],
  },
  {
    id: "ohne-app",
    q: "FlowLine funziona solo nel browser?",
    a: "Pianificare, Mappa, Percorsi e Bici: sì. Navigazione, offline, registrazione GPS, sensori e orologio hanno bisogno dell’app nativa. Non c’è navigazione live nel tab — e nessun finto che faccia finta.",
    links: [
      { href: "/guides/web-vs-app", label: "Guida: Web vs. App" },
      { href: "/download", label: "App" },
    ],
  },
  {
    id: "karten",
    q: "Dove posso pedalare con una mappa vera?",
    a: "Online in nove regioni: DACH, Francia, Alpi sud, Benelux, Italia nord, centro e sud, Catalogna/Pirenei, Inghilterra sud. In DACH l’atlante e dallo zoom 12 le vie per DE, AT, CH e LI — non solo in dieci città. La mappa segue l’inquadratura. Offline sono pack città per il routing nell’app — non una carta nazionale. Sicilia, Sardegna, Scandinavia, Polonia, il resto del UK e dell’Iberia sono buchi.",
    links: [
      { href: "/karten", label: "Carte" },
      { href: "/discover", label: "Apri la mappa" },
      { href: "/download", label: "App" },
    ],
  },
  {
    id: "preise",
    q: "Quanto costa Pro?",
    a: "Free pianifica e naviga nell’app. Pro costa 6,99 €/mese oppure 59,99 €/anno — multi-bici, bracketing, fasce di autonomia, limiti chat più alti. Checkout nel profilo (Stripe) o Play Billing su Android. Niente abbonamento in mezzo all’uscita.",
    links: [{ href: "/pricing", label: "Prezzi" }],
  },
  {
    id: "community",
    q: "C’è una community / un feed?",
    a: "La community sta sull’uscita: Stimmen, link Mappe, link di invito, profilo pubblico opzionale. Niente timeline a Home, niente classifica e niente GPS live davanti al cancello.",
    links: [
      { href: "/community", label: "Community" },
      { href: "/library", label: "Platz" },
    ],
  },
  {
    id: "teilen",
    q: "Come condivido un’uscita o una Mappe?",
    a: "Per link, non per feed. Chi ha il link salva l’uscita in locale nella Mappe — senza account obbligatorio. Stimmen e gruppi restano sul Platz. I profili pubblici sono opt-in e non portano tracce GPS.",
    links: [
      { href: "/share", label: "Condividi" },
      { href: "/share/t/demo", label: "Uscita esempio" },
      { href: "/guides/teilen-per-link", label: "Guida: Condividi" },
    ],
  },
  {
    id: "shop",
    q: "Posso comprare ricambi qui?",
    a: "No. Il negozio e Shopify sono spenti per ora. La bici resta per setup e manutenzione — niente cassa in FlowLine.",
    links: [{ href: "/garage", label: "Bici" }],
  },
  {
    id: "regionen",
    q: "Le uscite sono tracce GPS vere?",
    a: "Le pagine pubbliche sono idee editoriali con un pin. La linea nasce quando pianifichi con il profilo di routing — niente file GPX garantito e niente Alpi fittizie se sei ad Hamburg.",
    links: [
      { href: "/regions", label: "Regioni" },
      { href: "/karten", label: "Carte" },
      { href: "/discover", label: "Mappa" },
    ],
  },
  {
    id: "daten",
    q: "Che succede ai miei dati?",
    a: "Offline-first, GDPR, export nel profilo. Stimmen senza traccia in allegato. Profilo pubblico solo con opt-in. Sync e navigazione restano liberi.",
    links: [{ href: "/legal/datenschutz", label: "Privacy" }],
  },
  {
    id: "app-stores",
    q: "Dove scarico l’app?",
    a: "I link store compaiono quando i listing sono live. Fino ad allora Home, Mappa, Percorsi e la bici girano nel browser. HUD, offline e sensori arrivano con l’app nativa.",
    links: [{ href: "/download", label: "App" }],
  },
  {
    id: "kontakt",
    q: "Come vi raggiungo?",
    a: "Via e-mail. Nome e indirizzo notificabile stanno nell’Impressum quando sono depositati — non li inventiamo.",
    links: [
      { href: "/kontakt", label: "Contatto" },
      { href: "/legal/impressum", label: "Impressum" },
    ],
  },
];

const NL: FaqItem[] = [
  {
    id: "was",
    q: "Wat is FlowLine?",
    a: "FlowLine is outdoor cycling met een Home: plannen, verzorgen, delen in de browser — rijden in de app. Vier deuren, geen feed, geen tweede kassa.",
    links: [
      { href: "/produkt", label: "Productkaart" },
      { href: "/ueber", label: "Over FlowLine" },
    ],
  },
  {
    id: "fuer-wen",
    q: "Voor wie is FlowLine?",
    a: "Voor race, gravel, MTB, e-bike, touring en stad. Eén app, vier deuren — geen vier apps. Zoek je een feed of een klassement, dan ben je hier verkeerd. Wil je tochten plannen, de fiets verzorgen en delen zonder tijdlijn, dan ben je goed.",
    links: [
      { href: "/regions", label: "Regio’s" },
      { href: "/karten", label: "Kaarten" },
      { href: "/produkt", label: "Product" },
    ],
  },
  {
    id: "web-app",
    q: "Wat draait in de browser, wat in de app?",
    a: "Op het web: Home, Kaart, plannen, Tochten, Fiets. In de app: Ride-HUD, offline-routing, GPS-registratie, sensoren en horloge. Live-navigatie in de tab is er niet.",
    links: [
      { href: "/guides/web-vs-app", label: "Guide: Web vs. App" },
      { href: "/download", label: "App" },
    ],
  },
  {
    id: "konto",
    q: "Heb ik een account nodig?",
    a: "Nee. Home blijft lokaal bruikbaar. Een account synchroniseert met de app en schakelt Pro vrij in het profiel.",
    links: [{ href: "/anmelden", label: "Aanmelden" }],
  },
  {
    id: "ohne-app",
    q: "Werkt FlowLine alleen in de browser?",
    a: "Plannen, Kaart, Tochten en Fiets: ja. Navigatie, offline, GPS-registratie, sensoren en horloge hebben de native app nodig. Live-navigatie in de tab is er niet — en geen namaak die dat veinst.",
    links: [
      { href: "/guides/web-vs-app", label: "Guide: Web vs. App" },
      { href: "/download", label: "App" },
    ],
  },
  {
    id: "karten",
    q: "Waar kan ik rijden met een echte kaart?",
    a: "Online in negen regio’s: DACH, Frankrijk, zuidelijke Alpen, Benelux, Noord-, Midden- en Zuid-Italië, Catalonië/Pyreneeën, Zuid-Engeland. In DACH de atlas en vanaf zoom 12 de paden voor DE, AT, CH en LI — niet alleen in tien steden. De kaart volgt het kader. Offline zijn het stadspacks voor routing in de app — geen landkaart. Sicilië, Sardinië, Scandinavië, Polen, de rest van het UK en Iberia zijn gaten.",
    links: [
      { href: "/karten", label: "Kaarten" },
      { href: "/discover", label: "Kaart openen" },
      { href: "/download", label: "App" },
    ],
  },
  {
    id: "preise",
    q: "Wat kost Pro?",
    a: "Free plant en navigeert in de app. Pro kost 6,99 €/maand of 59,99 €/jaar — multi-fiets, bracketing, actieradius als interval, hogere chatlimieten. Checkout in het profiel (Stripe) of Play Billing op Android. Geen abo midden in de tocht.",
    links: [{ href: "/pricing", label: "Prijzen" }],
  },
  {
    id: "community",
    q: "Is er een community / een feed?",
    a: "Community hangt aan de tocht: Stimmen, Mappe-links, uitnodigingslinks, optioneel publiek profiel. Geen tijdlijn bij Home, geen klassement en geen live-GPS bij de poort.",
    links: [
      { href: "/community", label: "Community" },
      { href: "/library", label: "Platz" },
    ],
  },
  {
    id: "teilen",
    q: "Hoe deel ik een tocht of een Mappe?",
    a: "Via een link, niet via een feed. Wie de link heeft, slaat de tocht lokaal op in de Mappe — geen account verplicht. Stimmen en groepen blijven op de Platz. Publieke profielen zijn opt-in en dragen geen GPS-sporen.",
    links: [
      { href: "/share", label: "Delen" },
      { href: "/share/t/demo", label: "Voorbeeldtocht" },
      { href: "/guides/teilen-per-link", label: "Guide: Delen" },
    ],
  },
  {
    id: "shop",
    q: "Kan ik hier onderdelen kopen?",
    a: "Nee. De winkel en Shopify staan voorlopig uit. De fiets blijft voor setup en onderhoud — geen kassa in FlowLine.",
    links: [{ href: "/garage", label: "Fiets" }],
  },
  {
    id: "regionen",
    q: "Zijn de tochten echte GPS-sporen?",
    a: "Openbare tochtpagina’s zijn redactionele ideeën met een pin. De lijn ontstaat als je plant met het routingprofiel — geen gegarandeerd GPX-bestand en geen nepalpen als je in Hamburg staat.",
    links: [
      { href: "/regions", label: "Regio’s" },
      { href: "/karten", label: "Kaarten" },
      { href: "/discover", label: "Kaart" },
    ],
  },
  {
    id: "daten",
    q: "Wat gebeurt er met mijn data?",
    a: "Offline-first, AVG, export in het profiel. Stimmen zonder track erbij. Publiek profiel alleen met opt-in. Sync en navigatie blijven vrij.",
    links: [{ href: "/legal/datenschutz", label: "Privacy" }],
  },
  {
    id: "app-stores",
    q: "Waar haal ik de app?",
    a: "Store-links verschijnen zodra de listings live zijn. Tot dan draaien Home, Kaart, Tochten en de fiets in de browser. HUD, offline en sensoren komen met de native app.",
    links: [{ href: "/download", label: "App" }],
  },
  {
    id: "kontakt",
    q: "Hoe bereik ik jullie?",
    a: "Per e-mail. Naam en een geldig adres staan in het Impressum zodra ze zijn vastgelegd — we verzinnen ze niet.",
    links: [
      { href: "/kontakt", label: "Contact" },
      { href: "/legal/impressum", label: "Impressum" },
    ],
  },
];

const BY_LANG: Record<ChromeLang, FaqItem[]> = {
  de: FAQ_ITEMS,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function faqItems(lang: ChromeLang): FaqItem[] {
  return BY_LANG[lang];
}
