import type { ChromeLang } from "./chromeLang";

export type PricingRow = {
  feature: string;
  free: boolean | string;
  pro: boolean | string;
};

export type PublicPagesCopy = {
  pricing: {
    title: string;
    lead: string;
    freeHint: string;
    recommended: string;
    perMonth: string;
    yearHint: string;
    unlockPro: string;
    checkoutHint: string;
    colFeature: string;
    included: string;
    notIncluded: string;
    appTitle: string;
    appLead: string;
    legalBefore: string;
    rows: PricingRow[];
  };
  download: {
    title: string;
    lead: string;
    noStore: string;
    splitTitle: string;
    openMap: string;
    reasons: { title: string; body: string }[];
  };
  contact: {
    kicker: string;
    title: string;
    lead: string;
    emailLabel: string;
    workshopHint: string;
    imprintPending: string;
  };
  serviceCheck: {
    kicker: string;
    title: string;
    lead: string;
    free: string;
    sources: string;
    deepLink: string;
    toWorkshop: string;
    toMaintenance: string;
    demoKicker: string;
    demoTitle: string;
    demoBody: string;
    demoFoot: string;
    ownStatus: string;
    shopsTitle: string;
    shopsBodyBefore: string;
    shopsBodyStrong: string;
    shopsBodyAfter: string;
    shopsMail: string;
  };
};

const DE: PublicPagesCopy = {
  pricing: {
    title: "Free plant. Pro vertieft.",
    lead: "Touren auf der Karte und Planen ist für alle da. Multi-Bike, Bracketing und ehrliche Reichweiten-Spannen sind Pro — Navigation läuft in der App auf beiden Stufen.",
    freeHint: "Touren, Planen, 1 Bike, App-Navigation",
    recommended: "Empfohlen",
    perMonth: "/Mo",
    yearHint: "oder 59,99 €/Jahr · Kündigung im Portal",
    unlockPro: "Pro freischalten",
    checkoutHint: "Checkout im Profil (Stripe) · Play Billing in der Android-App",
    colFeature: "Funktion",
    included: "Enthalten",
    notIncluded: "Nicht enthalten",
    appTitle: "App für unterwegs",
    appLead: "Free und Pro navigieren in der nativen App — nicht im Browser.",
    legalBefore: "Details zu Daten und Abo:",
    rows: [
      { feature: "Karte & öffentliche Routen", free: true, pro: true },
      { feature: "Planen auf der Karte", free: true, pro: true },
      { feature: "Platz: Mappe, Stimmen, Gruppen", free: true, pro: true },
      { feature: "1 Rad in der Werkstatt", free: true, pro: true },
      { feature: "Mehrere Räder", free: false, pro: true },
      { feature: "Kompatibilität & Setup-Basis", free: true, pro: true },
      { feature: "Bracketing-Auswertung", free: false, pro: true },
      { feature: "E-Bike-Reichweite (Spanne)", free: false, pro: true },
      { feature: "Erweiterte Offline-Packs", free: false, pro: true },
      { feature: "KI-Chat (höheres Limit)", free: "5/Tag", pro: "50/Tag" },
      { feature: "App-Navigation & Sensoren", free: true, pro: true },
    ],
  },
  download: {
    title: "Die App für unterwegs",
    lead: "Der Hof, die Karte, der Platz und die Werkstatt laufen im Browser. Rausfahren mit HUD, Uhr koppeln und Sensoren — nur in der nativen App.",
    noStore:
      "Noch keine Store-Links. Der Hof, die Karte, der Platz und die Werkstatt laufen im Browser. HUD, Offline und Sensoren kommen mit der nativen App.",
    splitTitle: "Web und App, ehrlich getrennt",
    openMap: "Zuerst die Karte im Web öffnen",
    reasons: [
      {
        title: "Navigation",
        body: "Turn-by-turn und Karte während der Fahrt — stabil im Hintergrund.",
      },
      {
        title: "Offline",
        body: "Karten und Routing-Packs ohne Netz. Im Browser nicht sinnvoll.",
      },
      {
        title: "Sensoren & BLE",
        body: "Uhr und Radsensor am Fahrer bzw. am Rad. Koppeln nur nativ.",
      },
      {
        title: "Aufzeichnung",
        body: "Zuverlässiges Ride-Recording auch bei gesperrtem Display.",
      },
    ],
  },
  contact: {
    kicker: "Kontakt",
    title: "Schreib uns",
    lead: "Kein Formular-Bot, keine Fake-Hotline. Eine Adresse reicht.",
    emailLabel: "E-Mail",
    workshopHint:
      "Werkstatt-Interesse am Service-Check: dieselbe Adresse, Betreff „Werkstatt-Interesse“.",
    imprintPending: " — Name und Anschrift stehen, sobald sie hinterlegt sind.",
  },
  serviceCheck: {
    kicker: "Service-Check",
    title: "Dein Rad sagt dir, was fällig ist.",
    lead: "FlowLine rechnet Wartungsintervalle aus deinem Kilometerstand und deinen Stunden — mit Quellen aus Hersteller- und Industriepraxis (RockShox, Fox, Park Tool u. a.). Keine Blackbox, keine Fake-Partner.",
    free: "Status in der Werkstatt — immer kostenlos",
    sources: "Quellen sichtbar pro Intervall (kein „KI hat gesagt“)",
    deepLink: "Deep-Link: gleicher Status wie in der App-Werkstatt",
    toWorkshop: "Zur Werkstatt",
    toMaintenance: "Zur Werkstatt · Wartung",
    demoKicker: "Wartungs-Status · Beispiel",
    demoTitle: "Kette · 180 km · bald checken",
    demoBody: "Kettenverschleiß prüfen · Quelle: Park Tool / Industriepraxis",
    demoFoot: "Demo-Darstellung — echte Werte kommen aus deinem Bike in der Werkstatt.",
    ownStatus: "Eigenen Status ansehen",
    shopsTitle: "Werkstätten: Interesse melden",
    shopsBodyBefore: "Wir bauen eine Warteliste für Werkstatt-Partner. Es gibt",
    shopsBodyStrong: "noch keine Live-Partner-Buchung",
    shopsBodyAfter: "— bei Interesse melde dich unverbindlich.",
    shopsMail: "Interesse per E-Mail",
  },
};

const EN: PublicPagesCopy = {
  pricing: {
    title: "Free plans. Pro goes deeper.",
    lead: "Tours on the map and planning are for everyone. Multi-bike, bracketing and honest range spans are Pro — navigation runs in the app on both tiers.",
    freeHint: "Tours, planning, 1 bike, app navigation",
    recommended: "Recommended",
    perMonth: "/mo",
    yearHint: "or 59.99 €/year · cancel in the portal",
    unlockPro: "Unlock Pro",
    checkoutHint: "Checkout in the profile (Stripe) · Play Billing in the Android app",
    colFeature: "Feature",
    included: "Included",
    notIncluded: "Not included",
    appTitle: "App on the road",
    appLead: "Free and Pro navigate in the native app — not in the browser.",
    legalBefore: "Details on data and the plan:",
    rows: [
      { feature: "Map & public routes", free: true, pro: true },
      { feature: "Planning on the map", free: true, pro: true },
      { feature: "Platz: Mappe, Stimmen, groups", free: true, pro: true },
      { feature: "1 bike in the workshop", free: true, pro: true },
      { feature: "Several bikes", free: false, pro: true },
      { feature: "Compatibility & setup basics", free: true, pro: true },
      { feature: "Bracketing evaluation", free: false, pro: true },
      { feature: "E-bike range (span)", free: false, pro: true },
      { feature: "Extended offline packs", free: false, pro: true },
      { feature: "AI chat (higher limit)", free: "5/day", pro: "50/day" },
      { feature: "App navigation & sensors", free: true, pro: true },
    ],
  },
  download: {
    title: "The app for the road",
    lead: "Home, Map, Platz and the workshop run in the browser. Ride out with HUD, pair a watch and sensors — only in the native app.",
    noStore:
      "No store links yet. Home, Map, Platz and the workshop run in the browser. HUD, offline and sensors come with the native app.",
    splitTitle: "Web and app, honestly split",
    openMap: "Open the map on the web first",
    reasons: [
      {
        title: "Navigation",
        body: "Turn-by-turn and map during the ride — stable in the background.",
      },
      {
        title: "Offline",
        body: "Map and routing packs without a network. Not useful in the browser.",
      },
      {
        title: "Sensors & BLE",
        body: "Watch and bike sensor on the rider or the bike. Pairing only native.",
      },
      {
        title: "Recording",
        body: "Reliable ride recording even with a locked display.",
      },
    ],
  },
  contact: {
    kicker: "Contact",
    title: "Write to us",
    lead: "No form bot, no fake hotline. One address is enough.",
    emailLabel: "Email",
    workshopHint:
      "Workshop interest in the service check: the same address, subject “Werkstatt-Interesse”.",
    imprintPending: " — name and address appear once they are on file.",
  },
  serviceCheck: {
    kicker: "Service check",
    title: "Your bike tells you what is due.",
    lead: "FlowLine computes service intervals from your kilometres and hours — with sources from manufacturer and industry practice (RockShox, Fox, Park Tool and others). No black box, no fake partners.",
    free: "Status in the workshop — always free",
    sources: "Sources visible per interval (no “the AI said so”)",
    deepLink: "Deep link: the same status as in the app workshop",
    toWorkshop: "To the workshop",
    toMaintenance: "To the workshop · service",
    demoKicker: "Service status · example",
    demoTitle: "Chain · 180 km · check soon",
    demoBody: "Check chain wear · source: Park Tool / industry practice",
    demoFoot: "Demo display — real values come from your bike in the workshop.",
    ownStatus: "See your own status",
    shopsTitle: "Workshops: register interest",
    shopsBodyBefore: "We are building a waitlist for workshop partners. There is",
    shopsBodyStrong: "no live partner booking yet",
    shopsBodyAfter: "— if you are interested, get in touch with no obligation.",
    shopsMail: "Interest by email",
  },
};

const FR: PublicPagesCopy = {
  pricing: {
    title: "Free planifie. Pro approfondit.",
    lead: "Les sorties sur la carte et Planifier sont pour tout le monde. Multi-vélo, bracketing et fourchettes d’autonomie honnêtes sont Pro — la navigation tourne dans l’appli aux deux niveaux.",
    freeHint: "Sorties, planifier, 1 vélo, navigation dans l’appli",
    recommended: "Recommandé",
    perMonth: "/mois",
    yearHint: "ou 59,99 €/an · résiliation dans le portail",
    unlockPro: "Activer Pro",
    checkoutHint: "Checkout dans le profil (Stripe) · Play Billing dans l’appli Android",
    colFeature: "Fonction",
    included: "Inclus",
    notIncluded: "Non inclus",
    appTitle: "Appli pour la route",
    appLead: "Free et Pro naviguent dans l’appli native — pas dans le navigateur.",
    legalBefore: "Détails sur les données et l’abo :",
    rows: [
      { feature: "Carte et itinéraires publics", free: true, pro: true },
      { feature: "Planifier sur la carte", free: true, pro: true },
      { feature: "Platz : Mappe, Stimmen, groupes", free: true, pro: true },
      { feature: "1 vélo à l’atelier", free: true, pro: true },
      { feature: "Plusieurs vélos", free: false, pro: true },
      { feature: "Compatibilité et base de setup", free: true, pro: true },
      { feature: "Évaluation bracketing", free: false, pro: true },
      { feature: "Autonomie e-bike (fourchette)", free: false, pro: true },
      { feature: "Packs hors ligne étendus", free: false, pro: true },
      { feature: "Chat IA (limite plus haute)", free: "5/jour", pro: "50/jour" },
      { feature: "Navigation appli et capteurs", free: true, pro: true },
    ],
  },
  download: {
    title: "L’appli pour la route",
    lead: "Home, Carte, Platz et l’atelier tournent dans le navigateur. Sortir avec HUD, coupler la montre et les capteurs — seulement dans l’appli native.",
    noStore:
      "Pas encore de liens store. Home, Carte, Platz et l’atelier tournent dans le navigateur. HUD, hors ligne et capteurs viennent avec l’appli native.",
    splitTitle: "Web et appli, honnêtement séparés",
    openMap: "D’abord ouvrir la carte sur le web",
    reasons: [
      {
        title: "Navigation",
        body: "Guidage et carte pendant la sortie — stable en arrière-plan.",
      },
      {
        title: "Hors ligne",
        body: "Packs carte et routing sans réseau. Pas utile dans le navigateur.",
      },
      {
        title: "Capteurs et BLE",
        body: "Montre et capteur vélo sur le cycliste ou le vélo. Couplage seulement en natif.",
      },
      {
        title: "Enregistrement",
        body: "Enregistrement de sortie fiable même avec l’écran verrouillé.",
      },
    ],
  },
  contact: {
    kicker: "Contact",
    title: "Écris-nous",
    lead: "Pas de bot de formulaire, pas de fausse hotline. Une adresse suffit.",
    emailLabel: "E-mail",
    workshopHint:
      "Intérêt atelier pour le service-check : la même adresse, objet « Werkstatt-Interesse ».",
    imprintPending:
      " — le nom et l’adresse apparaissent dès qu’ils sont déposés.",
  },
  serviceCheck: {
    kicker: "Service-check",
    title: "Ton vélo te dit ce qui est dû.",
    lead: "FlowLine calcule les intervalles d’entretien à partir de tes kilomètres et de tes heures — avec des sources de pratique constructeur et industrie (RockShox, Fox, Park Tool, etc.). Pas de boîte noire, pas de faux partenaires.",
    free: "Statut à l’atelier — toujours gratuit",
    sources: "Sources visibles par intervalle (pas de « l’IA a dit »)",
    deepLink: "Deep link : le même statut que dans l’atelier de l’appli",
    toWorkshop: "Vers l’atelier",
    toMaintenance: "Vers l’atelier · entretien",
    demoKicker: "Statut d’entretien · exemple",
    demoTitle: "Chaîne · 180 km · à vérifier bientôt",
    demoBody: "Vérifier l’usure de chaîne · source : Park Tool / pratique industrie",
    demoFoot:
      "Affichage démo — les vraies valeurs viennent de ton vélo à l’atelier.",
    ownStatus: "Voir ton propre statut",
    shopsTitle: "Ateliers : signaler un intérêt",
    shopsBodyBefore: "Nous construisons une liste d’attente pour les partenaires atelier. Il n’y a",
    shopsBodyStrong: "pas encore de réservation partenaire live",
    shopsBodyAfter: "— si ça t’intéresse, écris sans engagement.",
    shopsMail: "Intérêt par e-mail",
  },
};

const IT: PublicPagesCopy = {
  pricing: {
    title: "Free pianifica. Pro approfondisce.",
    lead: "Uscite sulla mappa e Pianifica sono per tutti. Multi-bici, bracketing e fasce di autonomia oneste sono Pro — la navigazione gira nell’app su entrambi i livelli.",
    freeHint: "Uscite, pianifica, 1 bici, navigazione nell’app",
    recommended: "Consigliato",
    perMonth: "/mese",
    yearHint: "oppure 59,99 €/anno · disdetta nel portale",
    unlockPro: "Attiva Pro",
    checkoutHint: "Checkout nel profilo (Stripe) · Play Billing nell’app Android",
    colFeature: "Funzione",
    included: "Incluso",
    notIncluded: "Non incluso",
    appTitle: "App in strada",
    appLead: "Free e Pro navigano nell’app nativa — non nel browser.",
    legalBefore: "Dettagli su dati e abbonamento:",
    rows: [
      { feature: "Mappa e percorsi pubblici", free: true, pro: true },
      { feature: "Pianificare sulla mappa", free: true, pro: true },
      { feature: "Platz: Mappe, Stimmen, gruppi", free: true, pro: true },
      { feature: "1 bici in officina", free: true, pro: true },
      { feature: "Più bici", free: false, pro: true },
      { feature: "Compatibilità e base di setup", free: true, pro: true },
      { feature: "Valutazione bracketing", free: false, pro: true },
      { feature: "Autonomia e-bike (fascia)", free: false, pro: true },
      { feature: "Pack offline estesi", free: false, pro: true },
      { feature: "Chat IA (limite più alto)", free: "5/giorno", pro: "50/giorno" },
      { feature: "Navigazione app e sensori", free: true, pro: true },
    ],
  },
  download: {
    title: "L’app per la strada",
    lead: "Home, Mappa, Platz e officina girano nel browser. Uscire con HUD, accoppiare orologio e sensori — solo nell’app nativa.",
    noStore:
      "Ancora nessun link store. Home, Mappa, Platz e officina girano nel browser. HUD, offline e sensori arrivano con l’app nativa.",
    splitTitle: "Web e app, separati in modo onesto",
    openMap: "Prima apri la mappa sul web",
    reasons: [
      {
        title: "Navigazione",
        body: "Turn-by-turn e mappa durante l’uscita — stabile in background.",
      },
      {
        title: "Offline",
        body: "Pack di mappe e routing senza rete. Nel browser non ha senso.",
      },
      {
        title: "Sensori e BLE",
        body: "Orologio e sensore bici sul ciclista o sulla bici. Accoppiamento solo nativo.",
      },
      {
        title: "Registrazione",
        body: "Registrazione dell’uscita affidabile anche a display bloccato.",
      },
    ],
  },
  contact: {
    kicker: "Contatto",
    title: "Scrivici",
    lead: "Niente bot di form, niente finta hotline. Un indirizzo basta.",
    emailLabel: "E-mail",
    workshopHint:
      "Interesse officina per il service-check: lo stesso indirizzo, oggetto «Werkstatt-Interesse».",
    imprintPending:
      " — nome e indirizzo compaiono quando sono depositati.",
  },
  serviceCheck: {
    kicker: "Service-check",
    title: "La tua bici ti dice cosa è dovuto.",
    lead: "FlowLine calcola gli intervalli di manutenzione da chilometri e ore — con fonti da pratica di produttori e industria (RockShox, Fox, Park Tool e altri). Niente black box, niente partner finti.",
    free: "Stato in officina — sempre gratis",
    sources: "Fonti visibili per intervallo (niente «l’IA ha detto»)",
    deepLink: "Deep link: lo stesso stato dell’officina nell’app",
    toWorkshop: "Verso l’officina",
    toMaintenance: "Verso l’officina · manutenzione",
    demoKicker: "Stato manutenzione · esempio",
    demoTitle: "Catena · 180 km · controlla presto",
    demoBody: "Controllare usura catena · fonte: Park Tool / pratica industria",
    demoFoot:
      "Vista demo — i valori veri arrivano dalla tua bici in officina.",
    ownStatus: "Vedi il tuo stato",
    shopsTitle: "Officine: segnala interesse",
    shopsBodyBefore: "Stiamo costruendo una lista d’attesa per partner officina. Non c’è",
    shopsBodyStrong: "ancora nessuna prenotazione partner live",
    shopsBodyAfter: "— se ti interessa, scrivi senza impegno.",
    shopsMail: "Interesse via e-mail",
  },
};

const NL: PublicPagesCopy = {
  pricing: {
    title: "Free plant. Pro gaat dieper.",
    lead: "Tochten op de kaart en plannen zijn voor iedereen. Multi-fiets, bracketing en eerlijke actieradius als interval zijn Pro — navigatie draait in de app op beide niveaus.",
    freeHint: "Tochten, plannen, 1 fiets, app-navigatie",
    recommended: "Aanbevolen",
    perMonth: "/mnd",
    yearHint: "of 59,99 €/jaar · opzeggen in het portaal",
    unlockPro: "Pro vrijschakelen",
    checkoutHint: "Checkout in het profiel (Stripe) · Play Billing in de Android-app",
    colFeature: "Functie",
    included: "Inbegrepen",
    notIncluded: "Niet inbegrepen",
    appTitle: "App onderweg",
    appLead: "Free en Pro navigeren in de native app — niet in de browser.",
    legalBefore: "Details over data en abo:",
    rows: [
      { feature: "Kaart & openbare routes", free: true, pro: true },
      { feature: "Plannen op de kaart", free: true, pro: true },
      { feature: "Platz: Mappe, Stimmen, groepen", free: true, pro: true },
      { feature: "1 fiets in de werkplaats", free: true, pro: true },
      { feature: "Meerdere fietsen", free: false, pro: true },
      { feature: "Compatibiliteit & setup-basis", free: true, pro: true },
      { feature: "Bracketing-evaluatie", free: false, pro: true },
      { feature: "E-bike-actieradius (interval)", free: false, pro: true },
      { feature: "Uitgebreide offline-packs", free: false, pro: true },
      { feature: "AI-chat (hoger limiet)", free: "5/dag", pro: "50/dag" },
      { feature: "App-navigatie & sensoren", free: true, pro: true },
    ],
  },
  download: {
    title: "De app voor onderweg",
    lead: "Home, Kaart, Platz en de werkplaats draaien in de browser. Eruit met HUD, horloge en sensoren koppelen — alleen in de native app.",
    noStore:
      "Nog geen store-links. Home, Kaart, Platz en de werkplaats draaien in de browser. HUD, offline en sensoren komen met de native app.",
    splitTitle: "Web en app, eerlijk gescheiden",
    openMap: "Eerst de kaart op het web openen",
    reasons: [
      {
        title: "Navigatie",
        body: "Turn-by-turn en kaart tijdens de tocht — stabiel op de achtergrond.",
      },
      {
        title: "Offline",
        body: "Kaart- en routingpacks zonder netwerk. In de browser niet zinvol.",
      },
      {
        title: "Sensoren & BLE",
        body: "Horloge en fietssensor op de renner of de fiets. Koppelen alleen native.",
      },
      {
        title: "Registratie",
        body: "Betrouwbare ritregistratie, ook met vergrendeld scherm.",
      },
    ],
  },
  contact: {
    kicker: "Contact",
    title: "Schrijf ons",
    lead: "Geen formulierbot, geen nephotline. Eén adres is genoeg.",
    emailLabel: "E-mail",
    workshopHint:
      "Werkplaats-interesse bij de service-check: hetzelfde adres, onderwerp „Werkstatt-Interesse”.",
    imprintPending:
      " — naam en adres verschijnen zodra ze zijn vastgelegd.",
  },
  serviceCheck: {
    kicker: "Service-check",
    title: "Jouw fiets zegt wat eraan komt.",
    lead: "FlowLine rekent onderhoudsintervallen uit je kilometers en uren — met bronnen uit fabrikant- en industriepraktijk (RockShox, Fox, Park Tool e.a.). Geen black box, geen nep-partners.",
    free: "Status in de werkplaats — altijd gratis",
    sources: "Bronnen zichtbaar per interval (geen „de AI zei het”)",
    deepLink: "Deep link: dezelfde status als in de app-werkplaats",
    toWorkshop: "Naar de werkplaats",
    toMaintenance: "Naar de werkplaats · onderhoud",
    demoKicker: "Onderhoudsstatus · voorbeeld",
    demoTitle: "Ketting · 180 km · binnenkort checken",
    demoBody: "Kettingslijtage checken · bron: Park Tool / industriepraktijk",
    demoFoot:
      "Demo-weergave — echte waarden komen van jouw fiets in de werkplaats.",
    ownStatus: "Eigen status bekijken",
    shopsTitle: "Werkplaatsen: interesse melden",
    shopsBodyBefore: "We bouwen een wachtlijst voor werkplaats-partners. Er is",
    shopsBodyStrong: "nog geen live-partnerboeking",
    shopsBodyAfter: "— bij interesse mail je vrijblijvend.",
    shopsMail: "Interesse per e-mail",
  },
};

const BY_LANG: Record<ChromeLang, PublicPagesCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function publicPagesCopy(lang: ChromeLang): PublicPagesCopy {
  return BY_LANG[lang];
}
