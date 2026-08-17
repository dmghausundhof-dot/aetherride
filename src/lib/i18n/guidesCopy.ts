import type { ChromeLang } from "./chromeLang";
import {
  GUIDE_CATEGORY_LABEL,
  GUIDE_CATEGORY_ORDER,
  GUIDES,
  getGuide,
  type Guide,
} from "../content/guides";

type Overlay = {
  title: string;
  teaser: string;
  body: string[];
  relatedLabels: string[];
};

const CATEGORY_EN: Record<Guide["category"], string> = {
  planning: "Planning",
  bike: "Bike & service",
  ebike: "E-Bike",
  setup: "Setup",
  safety: "Platform",
};

const CATEGORY_FR: Record<Guide["category"], string> = {
  planning: "Planification",
  bike: "Vélo et entretien",
  ebike: "E-Bike",
  setup: "Setup",
  safety: "Plateforme",
};

const CATEGORY_IT: Record<Guide["category"], string> = {
  planning: "Pianificazione",
  bike: "Bici e manutenzione",
  ebike: "E-Bike",
  setup: "Setup",
  safety: "Piattaforma",
};

const EN: Record<string, Overlay> = {
  "gravel-touren-planen": {
    title: "Planning gravel tours: surface, profiles and honest expectations",
    teaser:
      "Why gravel routing often “hallucinates”, and how you build better tours under Plan with surface and profiles.",
    body: [
      "Gravel lives on mixed surfaces: tarmac, gravel, forest roads. Many apps push trails or road too hard — and send you onto singletracks that do not exist or onto pure motorway alternatives.",
      "In FlowLine you pick the “Gravel” profile under Plan. Routing prefers tracks and unpaved, but avoids hard MTB scales. Still: without a live engine (demo mode) lines are approximations — check critical stretches on the map and save GPX.",
      "Tip: plan on the desktop, save to Platz, navigate in the app. For multi-day tours, break stages by hand (start/via/destination) and use flat long-distance cycle paths as backup.",
      "Community wish: transparent surface layers and warnings instead of silent detours. That is our honesty approach — label demo clearly, show live status.",
    ],
    relatedLabels: ["Open Plan", "Gravel in tours", "Region Schwarzwald"],
  },
  "rennrad-hoehenmeter": {
    title: "Road: judging elevation and cycle paths realistically",
    teaser:
      "Elevation figures, cycling infrastructure, and why flat shore routes and Kaiserstuhl loops train differently.",
    body: [
      "Road tours need different filters than MTB: share of tarmac, traffic and cumulative elevation matter more than S-scales.",
      "Under tours, use the sport filter “Road” and difficulty “Easy” vs. “Sporty”. Public tour pages show weather and an elevation profile — the metadata profile is an estimate until you route live.",
      "Bodensee south shore and the Inn cycle path suit long, flat days. Kaiserstuhl and the Alpine foothills deliver intervals. Save variants on Platz and start in the app.",
    ],
    relatedLabels: ["Road tours", "Bodensee tour", "Kaiserstuhl"],
  },
  "ebike-reichweite": {
    title: "Judging e-bike range properly (spans, not point values)",
    teaser:
      "Why an “80 km display” lies — and how FlowLine works with physics, assist and calibration.",
    body: [
      "Range depends on weight, wind, temperature, elevation, tyre pressure, assist mode and battery health. A single kilometre figure is marketing — serious systems show spans.",
      "FlowLine Pro estimates a band (kmLow–kmHigh) and can calibrate over rides. Bosch LDI delivers live SOC in the app — not in the browser.",
      "Plan demanding tours (e.g. e-MTB alpine) with reserve: aim under 70–80 % of the upper span. Think charging infrastructure and Eco modes for the way back.",
      "Under tours, e-bikes show range notes on tour ideas. Navigation and sensors stay app-only.",
    ],
    relatedLabels: ["Pro & range", "Get the app", "E-bike in the workshop"],
  },
  "setup-koerpergewicht": {
    title: "Setup by body weight — honest, and as a starting point",
    teaser:
      "OEM tables, SAG and bracketing: how you set suspension without fake precision.",
    body: [
      "Pressure and rebound depend on system weight (rider + packs + bike) and travel. Manufacturer charts are starting points, not laws.",
      "In the workshop you find SAG hints and setup versions. Bracketing (Pro) compares series systematically — with the rule that “no significant difference” is shown honestly.",
      "Post-ride feedback (≤3 taps in the app) feeds into suggestions. On the desktop you deepen setups and export service reports for the workshop.",
    ],
    relatedLabels: ["Workshop", "Pro for bracketing", "Activities"],
  },
  "wartung-intervalle": {
    title: "Service intervals, plainly: chain, pads, fork",
    teaser:
      "Kilometres vs. hours, wear spans, and when the shop helps with a compatibility verdict.",
    body: [
      "Chains: often replace from ~0.5 % elongation (manufacturer/Park Tool). Pads: remaining compound and noise. Fork/shock: service intervals in hours or seasons.",
      "FlowLine stores intervals per bike and warns in the workshop. The shop suggests spare parts — only with consent and with a compatibility verdict for the active bike.",
      "Road and city need different emphases (punctures, chain, brakes) than enduro (suspension, pads, tyres). Discipline filters in the shop help.",
    ],
    relatedLabels: ["Service", "Shop: replace"],
  },
  "web-vs-app": {
    title: "Website vs. app: what belongs where",
    teaser:
      "The Komoot pattern, explained: desktop plans, phone navigates — and why the browser is not a GPS ride.",
    body: [
      "Large outdoor products split clearly: web for inspiration, SEO tours and desktop planning; app for offline, turn-by-turn and sensors.",
      "FlowLine follows that: tours, planning, tour pages, workshop and Platz in the browser. Live riding, BLE and background GPS only native.",
      "When you see “Ride out”, you land on the app bridge — save the tour and open it on the device.",
    ],
    relatedLabels: [
      "Get the app",
      "Product: Web vs. App",
      "Plan",
      "Map",
      "Community / Platz",
    ],
  },
  "hof-fuenf-tueren": {
    title: "Home: four doors, no Ride tab",
    teaser:
      "Why FlowLine does not look like a feed — and what Home, Map, Platz and workshop are for.",
    body: [
      "Many cycling apps stack cards: Home, Explore, Activity, Club, Shop. FlowLine has four doors at Home. Ride is the orange button, not a fifth tab. The shop is not a door in the bar.",
      "Home is the stand: sky, an hour at the gate, ride out. The map shows nearby and planning. Platz holds Mappe, Stimmen and groups. The workshop knows the bike — and opens the Shopify door when a part fits this bike.",
      "What is missing in the browser stays empty: no live GPS, no HUD, no dummy kilometres. The app takes navigation, offline and sensors.",
    ],
    relatedLabels: ["To Home", "Product map", "About FlowLine", "The shop"],
  },
  "platz-ohne-feed": {
    title: "Platz instead of a timeline: Stimmen, Mappe, groups",
    teaser:
      "Community sits on the tour. No feed at Home, no tracks in comments.",
    body: [
      "Platz is the community door. The same tours as on the map sit in the Mappe. Stimmen are short text on the tour — new ones start in review, editorial is marked.",
      "You share collections as a link. Whoever has the link puts the tours into their own Mappe, without an account required. Groups run via code at the gate; live pins exist only in the app HUD and only with opt-in.",
      "Public profile is deliberate: handle, sport, optional rides — no GPS traces. Events and clubs on the website are editorial, no fake RSVP.",
    ],
    relatedLabels: [
      "To Platz",
      "Community",
      "Share",
      "Sample profile",
      "Guide: Share",
    ],
  },
  "teilen-per-link": {
    title: "Share by link: tour, Mappe, no feed",
    teaser:
      "Whoever has the link puts the tour into their own Mappe. No account required, no silent GPS attachments.",
    body: [
      "FlowLine does not share through a timeline. A tour or a Mappe becomes a link. Whoever opens it can take the idea locally — without an account, without follow, without a heatmap.",
      "The tour link carries name and stats. A trace is only inside if it sits in the token on purpose; catalogue examples stay pin and text. The Mappe collects several catalogue tours, always without tracks.",
      "Stimmen and groups stay on Platz. Public profiles are opt-in and store no raw GPS data. There is no live location at the gate.",
    ],
    relatedLabels: ["How to share", "Sample tour", "Sample Mappe", "Community"],
  },
  "laden-ohne-zweite-kasse": {
    title: "The shop: a door to Shopify, no second till",
    teaser:
      "Parts and merch sit behind a door. The purchase contract and checkout happen at Shopify — or not at all, as long as the imprint is missing.",
    body: [
      "The shop is not a fifth door in the bar. Catalogue and fit come from the workshop, bound to slot and bike. The till sits at Shopify — there is no cart that charges here.",
      "Without an imprint on file (name and a serviceable address), checkout stays locked. That is intentional: we do not invent TMG details so something can say “buy”.",
      "Merchandise is not filtered by fit to the bike. Spare parts are: category and wheel size to the parked bike, no invented SKUs. App store listings are independent of that and appear once they are live.",
    ],
    relatedLabels: ["To the shop", "Workshop", "Imprint", "Product map"],
  },
};

const FR: Record<string, Overlay> = {
  "gravel-touren-planen": {
    title: "Planifier des sorties gravel : revêtement, profils et attentes honnêtes",
    teaser:
      "Pourquoi le routing gravel « hallucine » souvent, et comment tu construis de meilleures sorties sous Planifier avec surface et profils.",
    body: [
      "Le gravel vit sur des surfaces mixtes : bitume, graviers, pistes forestières. Beaucoup d’applis poussent trop les trails ou la route — et t’envoient sur des singletracks qui n’existent pas ou sur de pures alternatives autoroute.",
      "Dans FlowLine tu choisis le profil « Gravel » sous Planifier. Le routing préfère tracks et unpaved, mais évite les échelles MTB dures. Quand même : sans moteur live (mode démo) les lignes sont des approximations — vérifie les tronçons critiques sur la carte et enregistre le GPX.",
      "Conseil : planifie sur le bureau, enregistre sur le Platz, navigue dans l’appli. Pour les sorties de plusieurs jours, coupe les étapes à la main (départ/via/arrivée) et utilise les voies vertes plates comme backup.",
      "Vœu community : couches de surface transparentes et avertissements plutôt que des détours silencieux. C’est notre approche honesty — labelliser clairement la démo, afficher le statut live.",
    ],
    relatedLabels: ["Ouvrir Planifier", "Gravel dans les sorties", "Région Schwarzwald"],
  },
  "rennrad-hoehenmeter": {
    title: "Route : estimer dénivelé et pistes cyclables sans mensonge",
    teaser:
      "Chiffres de dénivelé, infrastructure cyclable, et pourquoi les rives plates et les boucles du Kaiserstuhl s’entraînent autrement.",
    body: [
      "Les sorties route ont besoin d’autres filtres que le MTB : part de bitume, trafic et dénivelé cumulé comptent plus que les échelles S.",
      "Sous les sorties, utilise le filtre sport « Route » et la difficulté « Tranquille » vs. « Sportif ». Les pages publiques montrent la météo et un profil altimétrique — le profil des métadonnées est une estimation jusqu’à ce que tu routes en live.",
      "La rive sud du Bodensee et la piste de l’Inn conviennent aux longues journées plates. Kaiserstuhl et avant-pays alpin livrent des intervalles. Enregistre des variantes sur le Platz et démarre dans l’appli.",
    ],
    relatedLabels: ["Sorties route", "Sortie Bodensee", "Kaiserstuhl"],
  },
  "ebike-reichweite": {
    title: "Estimer l’autonomie e-bike (fourchettes, pas de valeur unique)",
    teaser:
      "Pourquoi un « affichage 80 km » ment — et comment FlowLine travaille avec la physique, l’assist et la calibration.",
    body: [
      "L’autonomie dépend du poids, du vent, de la température, du dénivelé, de la pression des pneus, du mode d’assist et de l’état de la batterie. Un seul chiffre en kilomètres, c’est du marketing — les systèmes sérieux montrent des fourchettes.",
      "FlowLine Pro estime une bande (kmLow–kmHigh) et peut se calibrer sur les sorties. Bosch LDI fournit le SOC live dans l’appli — pas dans le navigateur.",
      "Planifie les sorties exigeantes (p. ex. e-MTB alpin) avec de la réserve : vise sous 70–80 % de la fourchette haute. Pense infra de charge et modes Eco pour le retour.",
      "Sous les sorties, les e-bikes montrent des hints d’autonomie sur les idées. Navigation et capteurs restent app-only.",
    ],
    relatedLabels: ["Pro et autonomie", "Télécharger l’appli", "E-bike à l’atelier"],
  },
  "setup-koerpergewicht": {
    title: "Setup selon le poids — honnête, et comme point de départ",
    teaser:
      "Tableaux OEM, SAG et bracketing : comment tu règles la suspension sans fausse précision.",
    body: [
      "Pression et rebound dépendent du poids système (cycliste + packs + vélo) et du débattement. Les charts constructeur sont des points de départ, pas des lois.",
      "À l’atelier tu trouves des hints SAG et des versions de setup. Le bracketing (Pro) compare des séries de façon systématique — avec la règle qu’« aucune différence significative » s’affiche honnêtement.",
      "Le feedback post-ride (≤3 taps dans l’appli) alimente les suggestions. Sur le bureau tu approfondis les setups et tu exportes des rapports d’entretien pour l’atelier.",
    ],
    relatedLabels: ["Atelier", "Pro pour le bracketing", "Activités"],
  },
  "wartung-intervalle": {
    title: "Intervalles d’entretien, clairement : chaîne, plaquettes, fourche",
    teaser:
      "Kilomètres vs. heures, fourchettes d’usure, et quand le magasin aide avec un verdict de compatibilité.",
    body: [
      "Chaînes : souvent à changer dès ~0,5 % d’allongement (constructeur/Park Tool). Plaquettes : garniture restante et bruits. Fourche/amortisseur : intervalles en heures ou saisons.",
      "FlowLine enregistre les intervalles par vélo et avertit à l’atelier. Le magasin propose des pièces — seulement avec consentement et avec un verdict de compatibilité pour le vélo actif.",
      "Route et ville ont d’autres priorités (crevaisons, chaîne, freins) que l’enduro (suspension, plaquettes, pneus). Les filtres discipline dans le magasin aident.",
    ],
    relatedLabels: ["Entretien", "Magasin : remplacer"],
  },
  "web-vs-app": {
    title: "Site vs. appli : ce qui va où",
    teaser:
      "Le schéma Komoot expliqué : le bureau planifie, le téléphone navigue — et pourquoi le navigateur n’est pas une sortie GPS.",
    body: [
      "Les grands produits outdoor séparent clairement : web pour l’inspiration, les sorties SEO et la planification bureau ; appli pour le hors ligne, le guidage et les capteurs.",
      "FlowLine suit ça : sorties, planifier, pages de sorties, atelier et Platz dans le navigateur. Sortie live, BLE et GPS en arrière-plan seulement en natif.",
      "Quand tu vois « Sortir », tu arrives sur le pont appli — enregistre la sortie et ouvre-la sur l’appareil.",
    ],
    relatedLabels: [
      "Télécharger l’appli",
      "Produit : Web vs. App",
      "Planifier",
      "Carte",
      "Community / Platz",
    ],
  },
  "hof-fuenf-tueren": {
    title: "Home : quatre portes, pas d’onglet Ride",
    teaser:
      "Pourquoi FlowLine ne ressemble pas à un fil — et à quoi servent Home, Carte, Platz et atelier.",
    body: [
      "Beaucoup d’applis vélo empilent des cartes : Home, Explore, Activity, Club, Shop. FlowLine a quatre portes à Home. Ride est le bouton orange, pas un cinquième onglet. Le magasin n’est pas une porte dans la barre.",
      "Home est le stand : ciel, une heure devant la porte, sortir. La carte montre le proche et Planifier. Le Platz tient Mappe, Stimmen et groupes. L’atelier connaît le vélo — et ouvre la porte Shopify quand une pièce va à ce vélo.",
      "Ce qui manque dans le navigateur reste vide : pas de GPS live, pas de HUD, pas de kilomètres fictifs. L’appli prend navigation, hors ligne et capteurs.",
    ],
    relatedLabels: ["Vers Home", "Carte produit", "À propos de FlowLine", "Le magasin"],
  },
  "platz-ohne-feed": {
    title: "Platz plutôt qu’un fil : Stimmen, Mappe, groupes",
    teaser:
      "La communauté tient à la sortie. Pas de fil à Home, pas de traces dans les commentaires.",
    body: [
      "Le Platz est la porte community. Les mêmes sorties que sur la carte sont dans la Mappe. Les Stimmen sont un texte court sur la sortie — les nouvelles partent en relecture, l’éditorial est marqué.",
      "Tu partages les collections comme un lien. Qui a le lien met les sorties dans sa propre Mappe, sans compte obligatoire. Les groupes passent par un code devant la porte ; les pins live n’existent que dans le HUD de l’appli et seulement avec opt-in.",
      "Le profil public est volontaire : handle, sport, sorties optionnelles — pas de traces GPS. Events et clubs sur le site sont éditoriaux, pas de faux RSVP.",
    ],
    relatedLabels: [
      "Vers le Platz",
      "Community",
      "Partager",
      "Profil exemple",
      "Guide : Partager",
    ],
  },
  "teilen-per-link": {
    title: "Partager par lien : sortie, Mappe, pas de fil",
    teaser:
      "Qui a le lien met la sortie dans sa propre Mappe. Pas de compte obligatoire, pas de GPS silencieux en pièce jointe.",
    body: [
      "FlowLine ne partage pas via un fil. Une sortie ou une Mappe devient un lien. Qui l’ouvre peut reprendre l’idée en local — sans compte, sans follow, sans heatmap.",
      "Le lien de sortie porte nom et stats. Une trace n’est dedans que si elle est dans le token exprès ; les exemples catalogue restent épingle et texte. La Mappe rassemble plusieurs sorties catalogue, toujours sans traces.",
      "Stimmen et groupes restent sur le Platz. Les profils publics sont opt-in et ne stockent pas de GPS brut. Il n’y a pas de position live devant la porte.",
    ],
    relatedLabels: ["Comment partager", "Exemple de sortie", "Exemple de Mappe", "Community"],
  },
  "laden-ohne-zweite-kasse": {
    title: "Le magasin : porte vers Shopify, pas de deuxième caisse",
    teaser:
      "Pièces et merch sont derrière une porte. Le contrat d’achat et le checkout naissent chez Shopify — ou pas du tout, tant que les mentions légales manquent.",
    body: [
      "Le magasin n’est pas une cinquième porte dans la barre. Catalogue et fit viennent de l’atelier, liés au slot et au vélo. La caisse est chez Shopify — il n’y a pas de panier qui encaisse ici.",
      "Sans mentions légales déposées (nom et adresse de signification), le checkout reste bloqué. C’est voulu : on n’invente pas d’indications TMG pour que quelque chose dise « acheter ».",
      "Le merch n’est pas filtré par le fit au vélo. Les pièces oui : catégorie et roue au vélo garé, pas de SKU inventés. Les listings store de l’appli sont indépendants et apparaissent dès qu’ils sont en ligne.",
    ],
    relatedLabels: ["Vers le magasin", "Atelier", "Mentions légales", "Carte produit"],
  },
};

const IT: Record<string, Overlay> = {
  "gravel-touren-planen": {
    title: "Pianificare uscite gravel: fondo, profili e attese oneste",
    teaser:
      "Perché il routing gravel spesso «allucina» e come costruisci uscite migliori sotto Pianifica con surface e profili.",
    body: [
      "Il gravel vive su superfici miste: asfalto, sterrato, strade forestali. Molte app spingono troppo trail o strada — e ti mandano su singletrack inesistenti o su alternative da autostrada.",
      "In FlowLine scegli il profilo «Gravel» sotto Pianifica. Il routing preferisce tracks e unpaved, ma evita scale MTB dure. Comunque: senza motore live (modo demo) le linee sono stime — controlla i tratti critici sulla mappa e salva il GPX.",
      "Consiglio: pianifica sul desktop, salva sul Platz, naviga nell’app. Per i tour di più giorni spezza le tappe a mano (partenza/via/arrivo) e usa piste ciclabili piatte come backup.",
      "Desiderio community: layer di surface trasparenti e avvisi invece di deviazioni silenziose. Questo è il nostro approccio honesty — marcare chiaro il demo, mostrare lo stato live.",
    ],
    relatedLabels: ["Apri Pianifica", "Gravel nelle uscite", "Regione Schwarzwald"],
  },
  "rennrad-hoehenmeter": {
    title: "Strada: stimare dislivello e piste ciclabili in modo realistico",
    teaser:
      "Cifre di dislivello, infrastruttura ciclabile e perché rive piatte e giri del Kaiserstuhl allenano in modo diverso.",
    body: [
      "Le uscite su strada hanno filtri diversi dal MTB: quota di asfalto, traffico e dislivello cumulato contano più delle scale S.",
      "Sotto le uscite usa il filtro sport «Strada» e la difficoltà «Tranquillo» vs. «Sportivo». Le pagine pubbliche mostrano meteo e un profilo altimetrico — il profilo dai metadati è una stima finché non routi in live.",
      "La sponda sud del Bodensee e la pista dell’Inn vanno per giornate lunghe e piatte. Kaiserstuhl e Prealpi danno intervalli. Salva varianti sul Platz e parti nell’app.",
    ],
    relatedLabels: ["Uscite strada", "Uscita Bodensee", "Kaiserstuhl"],
  },
  "ebike-reichweite": {
    title: "Stimare l’autonomia e-bike (fasce, non valori puntuali)",
    teaser:
      "Perché un «display da 80 km» mente — e come FlowLine lavora con fisica, assist e calibrazione.",
    body: [
      "L’autonomia dipende da peso, vento, temperatura, dislivello, pressione gomme, modo assist e stato della batteria. Un solo numero in chilometri è marketing — i sistemi seri mostrano fasce.",
      "FlowLine Pro stima una banda (kmLow–kmHigh) e può calibrarsi sulle uscite. Bosch LDI dà SOC live nell’app — non nel browser.",
      "Pianifica uscite impegnative (es. e-MTB alpino) con riserva: punta sotto il 70–80 % della fascia alta. Pensa a ricarica e modi Eco per il ritorno.",
      "Sotto le uscite, le e-bike mostrano note di autonomia sulle idee. Navigazione e sensori restano app-only.",
    ],
    relatedLabels: ["Pro e autonomia", "Scarica l’app", "E-bike in officina"],
  },
  "setup-koerpergewicht": {
    title: "Setup in base al peso — onesto, e come punto di partenza",
    teaser:
      "Tabelle OEM, SAG e bracketing: come regoli le sospensioni senza falsa precisione.",
    body: [
      "Pressione e rebound dipendono dal peso di sistema (ciclista + pack + bici) e dall’escursione. Le tabelle del produttore sono punti di partenza, non leggi.",
      "In officina trovi hint SAG e versioni di setup. Il bracketing (Pro) confronta serie in modo sistematico — con la regola che «nessuna differenza significativa» viene mostrata onestamente.",
      "Il feedback post-ride (≤3 tap nell’app) entra nei suggerimenti. Sul desktop approfondisci i setup ed esporti report di servizio per l’officina.",
    ],
    relatedLabels: ["Officina", "Pro per il bracketing", "Attività"],
  },
  "wartung-intervalle": {
    title: "Intervalli di manutenzione, chiari: catena, pastiglie, forcella",
    teaser:
      "Chilometri vs. ore, fasce di usura e quando il negozio aiuta con un verdetto di compatibilità.",
    body: [
      "Catene: spesso cambiare da ~0,5 % di allungamento (produttore/Park Tool). Pastiglie: materiale residuo e rumori. Forcella/ammortizzatore: intervalli in ore o stagioni.",
      "FlowLine salva gli intervalli per bici e avvisa in officina. Il negozio propone ricambi — solo con consenso e con un verdetto di compatibilità per la bici attiva.",
      "Strada e città hanno altri pesi (forature, catena, freni) rispetto all’enduro (sospensioni, pastiglie, gomme). I filtri disciplina nel negozio aiutano.",
    ],
    relatedLabels: ["Manutenzione", "Negozio: sostituisci"],
  },
  "web-vs-app": {
    title: "Sito vs. app: cosa sta dove",
    teaser:
      "Lo schema Komoot spiegato: il desktop pianifica, il telefono naviga — e perché il browser non è un’uscita GPS.",
    body: [
      "I grandi prodotti outdoor separano chiaro: web per ispirazione, uscite SEO e pianificazione desktop; app per offline, turn-by-turn e sensori.",
      "FlowLine segue questo: uscite, pianifica, pagine uscite, officina e Platz nel browser. Uscita live, BLE e GPS in background solo nativi.",
      "Quando vedi «Esci», atterri sul ponte app — salva l’uscita e aprila sul dispositivo.",
    ],
    relatedLabels: [
      "Scarica l’app",
      "Prodotto: Web vs. App",
      "Pianifica",
      "Mappa",
      "Community / Platz",
    ],
  },
  "hof-fuenf-tueren": {
    title: "Home: quattro porte, nessuna scheda Ride",
    teaser:
      "Perché FlowLine non sembra un feed — e a cosa servono Home, Mappa, Platz e officina.",
    body: [
      "Molte app bici impilano schede: Home, Explore, Activity, Club, Shop. FlowLine ha quattro porte a Home. Ride è il pulsante arancione, non la quinta scheda. Il negozio non è una porta nella barra.",
      "Home è lo stand: cielo, un’ora davanti al cancello, esci. La mappa mostra il vicino e Pianifica. Il Platz tiene Mappe, Stimmen e gruppi. L’officina conosce la bici — e apre la porta Shopify quando un pezzo sta a questa bici.",
      "Ciò che manca nel browser resta vuoto: niente GPS live, niente HUD, niente chilometri finti. L’app prende navigazione, offline e sensori.",
    ],
    relatedLabels: ["Verso Home", "Mappa prodotto", "Su FlowLine", "Il negozio"],
  },
  "platz-ohne-feed": {
    title: "Platz invece della timeline: Stimmen, Mappe, gruppi",
    teaser:
      "La community sta sull’uscita. Niente feed a Home, niente tracce nei commenti.",
    body: [
      "Il Platz è la porta community. Le stesse uscite della mappa stanno nella Mappe. Le Stimmen sono testo breve sull’uscita — le nuove partono in revisione, l’editoriale è segnalato.",
      "Condividi le raccolte come link. Chi ha il link mette le uscite nella propria Mappe, senza account obbligatorio. I gruppi passano da un codice davanti al cancello; i pin live esistono solo nell’HUD dell’app e solo con opt-in.",
      "Il profilo pubblico è voluto: handle, sport, uscite opzionali — niente tracce GPS. Eventi e club sul sito sono editoriali, niente RSVP finto.",
    ],
    relatedLabels: [
      "Verso il Platz",
      "Community",
      "Condividi",
      "Profilo esempio",
      "Guida: Condividi",
    ],
  },
  "teilen-per-link": {
    title: "Condividere per link: uscita, Mappe, niente feed",
    teaser:
      "Chi ha il link mette l’uscita nella propria Mappe. Niente account obbligatorio, niente GPS silenzioso in allegato.",
    body: [
      "FlowLine non condivide tramite una timeline. Un’uscita o una Mappe diventa un link. Chi lo apre può riprendere l’idea in locale — senza account, senza follow, senza heatmap.",
      "Il link dell’uscita porta nome e stats. Una traccia c’è solo se sta nel token di proposito; gli esempi catalogo restano pin e testo. La Mappe raccoglie più uscite catalogo, sempre senza tracce.",
      "Stimmen e gruppi restano sul Platz. I profili pubblici sono opt-in e non memorizzano GPS grezzo. Non c’è posizione live davanti al cancello.",
    ],
    relatedLabels: ["Come condividere", "Uscita esempio", "Mappe esempio", "Community"],
  },
  "laden-ohne-zweite-kasse": {
    title: "Il negozio: porta verso Shopify, niente seconda cassa",
    teaser:
      "Ricambi e merch stanno dietro una porta. Il contratto d’acquisto e il checkout nascono da Shopify — o per niente, finché manca l’Impressum.",
    body: [
      "Il negozio non è una quinta porta nella barra. Catalogo e fit vengono dall’officina, legati a slot e bici. La cassa è da Shopify — non c’è un carrello che incassa qui.",
      "Senza Impressum depositato (nome e indirizzo notificabile) il checkout resta bloccato. È voluto: non inventiamo dati TMG perché qualcosa dica «compra».",
      "Il merch non è filtrato sul fit alla bici. I ricambi sì: categoria e ruota alla bici parcheggiata, niente SKU inventati. I listing store dell’app sono indipendenti e compaiono quando sono live.",
    ],
    relatedLabels: ["Verso il negozio", "Officina", "Impressum", "Mappa prodotto"],
  },
};

const OVERLAY: Record<Exclude<ChromeLang, "de">, Record<string, Overlay>> = {
  en: EN,
  fr: FR,
  it: IT,
};

const CATEGORY: Record<ChromeLang, Record<Guide["category"], string>> = {
  de: GUIDE_CATEGORY_LABEL,
  en: CATEGORY_EN,
  fr: CATEGORY_FR,
  it: CATEGORY_IT,
};

export function guideCategoryLabel(
  lang: ChromeLang,
): Record<Guide["category"], string> {
  return CATEGORY[lang];
}

export function guideFor(slug: string, lang: ChromeLang): Guide | null {
  const g = getGuide(slug);
  if (!g) return null;
  if (lang === "de") return g;
  const o = OVERLAY[lang][slug];
  if (!o) return g;
  return {
    ...g,
    title: o.title,
    teaser: o.teaser,
    body: o.body,
    relatedHrefs: g.relatedHrefs?.map((r, i) => ({
      href: r.href,
      label: o.relatedLabels[i] ?? r.label,
    })),
  };
}

export function listGuidesGroupedFor(lang: ChromeLang): {
  category: Guide["category"];
  label: string;
  guides: Guide[];
}[] {
  const labels = guideCategoryLabel(lang);
  return GUIDE_CATEGORY_ORDER.map((category) => ({
    category,
    label: labels[category],
    guides: GUIDES.filter((g) => g.category === category)
      .map((g) => guideFor(g.slug, lang))
      .filter((g): g is Guide => g != null),
  })).filter((group) => group.guides.length > 0);
}
