import type { ChromeLang } from "./chromeLang";
import {
  ABOUT_REFUSALS,
  ABOUT_STATUS,
  ABOUT_STORY,
} from "../content/aboutPage";
import { FLOWLINE_ABOUT } from "../content/brand";

export type AboutCopy = {
  brand: {
    kicker: string;
    title: string;
    lead: string;
    madeFor: string;
    pillarsTitle: string;
    pillars: { title: string; body: string }[];
  };
  story: {
    kicker: string;
    title: string;
    paragraphs: readonly string[];
  };
  refusalsTitle: string;
  refusalsLead: string;
  refusals: { title: string; body: string }[];
  doorsTitle: string;
  doorsLead: string;
  status: { title: string; body: string };
};

const DE: AboutCopy = {
  brand: {
    kicker: FLOWLINE_ABOUT.kicker,
    title: FLOWLINE_ABOUT.title,
    lead: FLOWLINE_ABOUT.lead,
    madeFor:
      "Gebaut für Fahrerinnen und Fahrer. Gezeichnet für Fokus. Gemacht für die Fahrt — nicht für die Timeline.",
    pillarsTitle: "Drei Sätze aus dem Style Guide",
    pillars: FLOWLINE_ABOUT.pillars.map((p) => ({ title: p.title, body: p.body })),
  },
  story: ABOUT_STORY,
  refusalsTitle: "Was wir nicht bauen",
  refusalsLead:
    "Absicht, kein Feature-Rückstand. Die Homepage sagt das in Klartext.",
  refusals: ABOUT_REFUSALS,
  doorsTitle: "Vier Türen, keine fünfte",
  doorsLead: "Dieselbe IA wie in der App. Ride bleibt der Knopf, nicht der Tab.",
  status: ABOUT_STATUS,
};

const EN: AboutCopy = {
  brand: {
    kicker: "Brand",
    title: "The bike lives here.",
    lead: "FlowLine is outdoor cycling, simplified: Home in the browser, the ride in the app. Four doors, one orange button, no timeline.",
    madeFor:
      "Built for riders. Drawn for focus. Made for the ride — not for the timeline.",
    pillarsTitle: "Three lines from the style guide",
    pillars: [
      {
        title: "For riders",
        body: "No KPI bar, no feed, no dummy kilometres. What is missing stays empty.",
      },
      {
        title: "For focus",
        body: "One surface, one door. Ride is not a tab. The shop does not charge here.",
      },
      {
        title: "For the ride",
        body: "Plan and look after the bike at the desk. HUD, sensors and offline only native.",
      },
    ],
  },
  story: {
    kicker: "Why a Home",
    title: "Not another timeline on two wheels.",
    paragraphs: [
      "Most cycling apps stack cards: Explore, Club, Shop, Activity. Eventually the start screen is a feed, the ride is a statistic, the bike is an SKU. FlowLine turns that around. Home is the stand. Four doors. One orange button.",
      "Web is the desk: find tours, plan, look after the bike, share a Mappe. The app is the ride: HUD, GPS in the background, offline packs, sensors, watch. What the browser cannot do reliably is not sold as live GPS in the tab.",
      "The name is the stance: Flow for the cut, Line for the line. Outdoor · Cycling · Flow. No leaderboard that scores your weeknight loop. No dummy kilometre that makes Home look full.",
    ],
  },
  refusalsTitle: "What we do not build",
  refusalsLead: "On purpose, not a feature backlog. The homepage says it in plain language.",
  refusals: [
    {
      title: "No feed",
      body: "Community sits on the tour. Stimmen are short text. Collections are links. Groups have a code — live pins only in the app HUD, with opt-in.",
    },
    {
      title: "No second till",
      body: "The shop is a door to Shopify. Fit comes from the workshop. Without an imprint, checkout stays closed. We do not invent an address.",
    },
    {
      title: "No dummy",
      body: "Empty areas stay empty. Store buttons appear when listings are live. Routing lines appear when you plan, not as dummy Alps in Hamburg.",
    },
  ],
  doorsTitle: "Four doors, no fifth",
  doorsLead: "The same IA as in the app. Ride stays the button, not the tab.",
  status: {
    title: "Who we are — and what is still missing",
    body: "FlowLine is built by dmg hausundhof. Contact is by email. Name and a serviceable address are in the imprint once they are on file — not earlier, not invented. Until then the provider notice under TMG is incomplete, and marketplace checkout stays locked.",
  },
};

const FR: AboutCopy = {
  brand: {
    kicker: "Marque",
    title: "Le vélo habite ici.",
    lead: "FlowLine est le vélo dehors, simplifié : Home dans le navigateur, la sortie dans l’appli. Cinq portes, un bouton orange, pas de fil.",
    madeFor:
      "Fait pour les cyclistes. Dessiné pour le focus. Fait pour la sortie — pas pour le fil.",
    pillarsTitle: "Trois phrases du style guide",
    pillars: [
      {
        title: "Pour les cyclistes",
        body: "Pas de barre KPI, pas de fil, pas de kilomètres fictifs. Ce qui manque reste vide.",
      },
      {
        title: "Pour le focus",
        body: "Une surface, une porte. Ride n’est pas un onglet. Le magasin n’encaisse pas ici.",
      },
      {
        title: "Pour la sortie",
        body: "Planifier et soigner au bureau. HUD, capteurs et hors ligne seulement en natif.",
      },
    ],
  },
  story: {
    kicker: "Pourquoi un Home",
    title: "Pas encore un fil d’actualité sur deux roues.",
    paragraphs: [
      "La plupart des applis vélo empilent des cartes : Explore, Club, Shop, Activity. Un jour l’accueil est un fil, la sortie une statistique, le vélo un SKU. FlowLine inverse ça. Home est le stand. Cinq portes. Un bouton orange.",
      "Le web est le bureau : trouver des sorties, planifier, soigner le vélo, partager une Mappe. L’appli est la sortie : HUD, GPS en arrière-plan, packs hors ligne, capteurs, montre. Ce que le navigateur ne fait pas de façon fiable n’est pas vendu comme GPS live dans l’onglet.",
      "Le nom dit la posture : Flow pour la coupe, Line pour la ligne. Outdoor · Cycling · Flow. Pas de classement qui note ta boucle en semaine. Pas de kilomètre fictif qui fait paraître Home plein.",
    ],
  },
  refusalsTitle: "Ce que nous ne construisons pas",
  refusalsLead:
    "C’est voulu, pas un retard de features. La page d’accueil le dit clairement.",
  refusals: [
    {
      title: "Pas de fil",
      body: "La communauté tient à la sortie. Les Stimmen sont un texte court. Les collections sont des liens. Les groupes ont un code — pins live seulement dans le HUD de l’appli, avec opt-in.",
    },
    {
      title: "Pas de deuxième caisse",
      body: "Le magasin est une porte vers Shopify. Le fit vient de l’atelier. Sans mentions légales, le checkout reste fermé. On n’invente pas d’adresse.",
    },
    {
      title: "Pas de simulacre",
      body: "Les surfaces vides restent vides. Les boutons store apparaissent quand les listings sont en ligne. Les lignes de routing naissent quand tu planifies, pas comme des Alpes fictives à Hamburg.",
    },
  ],
  doorsTitle: "Quatre portes, pas de cinquième",
  doorsLead: "La même IA que dans l’appli. Ride reste le bouton, pas l’onglet.",
  status: {
    title: "Qui nous sommes — et ce qui manque encore",
    body: "FlowLine est construit par dmg hausundhof. Le contact passe par e-mail. Le nom et une adresse de signification sont dans les mentions légales dès qu’ils sont déposés — pas plus tôt, pas inventés. Jusque-là l’identification de l’éditeur selon le TMG est incomplète, et le checkout marketplace reste bloqué.",
  },
};

const IT: AboutCopy = {
  brand: {
    kicker: "Marca",
    title: "La bici abita qui.",
    lead: "FlowLine è ciclismo outdoor, semplificato: Home nel browser, l’uscita nell’app. Cinque porte, un pulsante arancione, niente timeline.",
    madeFor:
      "Fatto per chi pedala. Disegnato per il focus. Fatto per l’uscita — non per la timeline.",
    pillarsTitle: "Tre frasi dallo style guide",
    pillars: [
      {
        title: "Per chi pedala",
        body: "Niente barra KPI, niente feed, niente chilometri finti. Ciò che manca resta vuoto.",
      },
      {
        title: "Per il focus",
        body: "Una superficie, una porta. Ride non è una scheda. Il negozio non incassa qui.",
      },
      {
        title: "Per l’uscita",
        body: "Pianificare e curare alla scrivania. HUD, sensori e offline solo nativi.",
      },
    ],
  },
  story: {
    kicker: "Perché una Home",
    title: "Non un’altra timeline su due ruote.",
    paragraphs: [
      "La maggior parte delle app bici impila schede: Explore, Club, Shop, Activity. Alla fine l’inizio è un feed, l’uscita una statistica, la bici uno SKU. FlowLine lo gira. Home è lo stand. Cinque porte. Un pulsante arancione.",
      "Il web è la scrivania: trovare uscite, pianificare, curare la bici, condividere una Mappe. L’app è l’uscita: HUD, GPS in background, pack offline, sensori, orologio. Ciò che il browser non fa in modo affidabile non viene venduto come GPS live nel tab.",
      "Il nome è la postura: Flow per il taglio, Line per la linea. Outdoor · Cycling · Flow. Niente classifica che valuta il giro serale. Niente chilometro finto che fa sembrare Home piena.",
    ],
  },
  refusalsTitle: "Cosa non costruiamo",
  refusalsLead:
    "Voluto, non un ritardo di feature. La homepage lo dice in chiaro.",
  refusals: [
    {
      title: "Niente feed",
      body: "La community sta sull’uscita. Le Stimmen sono testo breve. Le raccolte sono link. I gruppi hanno un codice — pin live solo nell’HUD dell’app, con opt-in.",
    },
    {
      title: "Niente seconda cassa",
      body: "Il negozio è una porta verso Shopify. Il fit viene dall’officina. Senza Impressum il checkout resta chiuso. Non inventiamo un indirizzo.",
    },
    {
      title: "Niente finto",
      body: "Le superfici vuote restano vuote. I pulsanti store compaiono quando i listing sono live. Le linee di routing nascono quando pianifichi, non come Alpi fittizie ad Hamburg.",
    },
  ],
  doorsTitle: "Quattro porte, nessuna quinta",
  doorsLead: "La stessa IA dell’app. Ride resta il pulsante, non la scheda.",
  status: {
    title: "Chi siamo — e cosa manca ancora",
    body: "FlowLine è costruito da dmg hausundhof. Il contatto passa per e-mail. Nome e indirizzo notificabile stanno nell’Impressum quando sono depositati — non prima, non inventati. Fino ad allora l’identificazione del fornitore secondo TMG è incompleta, e il checkout del marketplace resta bloccato.",
  },
};

const BY_LANG: Record<ChromeLang, AboutCopy> = { de: DE, en: EN, fr: FR, it: IT };

export function aboutCopy(lang: ChromeLang): AboutCopy {
  return BY_LANG[lang];
}
