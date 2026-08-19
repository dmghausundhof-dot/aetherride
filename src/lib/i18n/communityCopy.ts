import type { ChromeLang } from "./chromeLang";
import { COMMUNITY_FEATURES, COMMUNITY_OUT } from "../content/communityMap";

export type CommunityFeature = {
  title: string;
  body: string;
  href: string;
  cta: string;
};

export type CommunityCopy = {
  kicker: string;
  title: string;
  lead: string;
  features: CommunityFeature[];
  privacyTitle: string;
  privacyBody: string;
  moderationTitle: string;
  moderationBody: string;
  linkTitle: string;
  linkBody: string;
  outTitle: string;
  out: string[];
  eventsTitle: string;
  eventsLead: string;
  regionCta: string;
  clubsTitle: string;
  clubsLead: string;
  clubsCta: string;
  groupsTitle: string;
  groupsBody: string;
  toPlatz: string;
  shareLinks: string;
  profilesTitle: string;
  profilesLead: string;
  openProfile: string;
  joinTitle: string;
  join1Before: string;
  join1Link: string;
  join1After: string;
  join2Before: string;
  join2After: string;
  join3Before: string;
  join3Mid: string;
  join3All: string;
};

const DE: CommunityCopy = {
  kicker: "Community",
  title: "Am Platz, nicht im Feed",
  lead: "FlowLine teilt Touren, Stimmen und Gruppen. Es gibt keine Timeline auf dem Hof und kein Live-GPS vor dem Tor. Die Tür heißt Platz: Mappe, Kurztext an der Tour, Einladungslink. Public Profiles sind Opt-in und tragen keine Spuren. Editorial-Stimmen sind gekennzeichnet, neue Stimmen starten in Prüfung.",
  features: COMMUNITY_FEATURES,
  privacyTitle: "Privacy-first",
  privacyBody: "Keine Tracks in Stimmen. Public Profile nur mit Opt-in.",
  moderationTitle: "Moderation",
  moderationBody:
    "Neue Stimmen starten „in Prüfung“. Editorial ist gekennzeichnet.",
  linkTitle: "Link statt Feed",
  linkBody: "Sammlung oder Gruppe per Link. Wer ihn hat, ist dabei.",
  outTitle: "Was Community hier nicht ist",
  out: COMMUNITY_OUT,
  eventsTitle: "Kommende Events",
  eventsLead: "Redaktionell auf dieser Seite, nicht in der App. Kein erfundenes RSVP.",
  regionCta: "Region ansehen",
  clubsTitle: "Clubs light",
  clubsLead: "Orientierung auf der Website — keine Mitgliedschaft in der App.",
  clubsCta: "Touren in der Region",
  groupsTitle: "Zusammen raus",
  groupsBody:
    "Gruppen leben am Platz: Einladungslink, Roster im Browser. Öffentlich als Treffen-Pin auf der Karte — ohne Live-GPS. Live-Pins nur im App-HUD und nur mit Opt-in. Eine Website-Erklärung ohne zweite Timeline.",
  toPlatz: "Zum Platz",
  shareLinks: "Tour- und Mappe-Links",
  profilesTitle: "Beispiel-Profile",
  profilesLead:
    "Editorial, klar gekennzeichnet. Keine GPS-Spuren, keine erfundenen Kilometer.",
  openProfile: "Profil öffnen",
  joinTitle: "So machst du mit",
  join1Before: "Tour auf der",
  join1Link: "Karte oder Region",
  join1After: "öffnen und eine Stimme hinterlassen.",
  join2Before: "Auf dem",
  join2After: "eine Sammlung teilen oder eine Gruppe per Link starten.",
  join3Before: "Optional ein",
  join3Mid: "anlegen — Beispiel:",
  join3All: "alle Beispiele",
};

const EN: CommunityCopy = {
  kicker: "Community",
  title: "On Platz, not in a feed",
  lead: "FlowLine shares tours, Stimmen and groups. There is no timeline at Home and no live GPS at the gate. The door is called Platz: Mappe, short text on the tour, invite link. Public profiles are opt-in and carry no traces. Editorial Stimmen are marked; new Stimmen start in review.",
  features: [
    {
      title: "Platz",
      body: "The door. Mappe, visibility, GPX, Stimmen and groups — the same tours as on the map.",
      href: "/library",
      cta: "To Platz",
    },
    {
      title: "Stimmen",
      body: "Short text on the tour, no tracks in the comment. New ones start in review; editorial is marked.",
      href: "/tours/r-heidelberg-city",
      cta: "Sample tour",
    },
    {
      title: "Share a Mappe",
      body: "A collection as a link. Whoever has the link puts the tours into their own Mappe — no account required.",
      href: "/share",
      cta: "How to share",
    },
    {
      title: "Ride together",
      body: "A group with an invite link at the gate. Web holds roster and invite. Live pins only in the app HUD, with opt-in.",
      href: "/library",
      cta: "How groups work",
    },
    {
      title: "Public Profile",
      body: "Only with opt-in. Handle, sport, optional ride count — no GPS traces.",
      href: "/u/mara_road",
      cta: "Sample mara_road",
    },
    {
      title: "Events & clubs",
      body: "Editorial on the website, not in the app. No fake RSVP, no live-location requirement.",
      href: "/community#events",
      cta: "Dates",
    },
  ],
  privacyTitle: "Privacy-first",
  privacyBody: "No tracks in Stimmen. Public profile only with opt-in.",
  moderationTitle: "Moderation",
  moderationBody: "New Stimmen start “in review”. Editorial is marked.",
  linkTitle: "Link instead of feed",
  linkBody: "A collection or group by link. Whoever has it is in.",
  outTitle: "What community is not, here",
  out: [
    "No feed at Home",
    "No leaderboard, no level",
    "No live GPS on the map at the gate",
    "Ride is not a tab",
    "Stimmen without a track attached",
  ],
  eventsTitle: "Upcoming events",
  eventsLead: "Editorial on this page, not in the app. No invented RSVP.",
  regionCta: "See the region",
  clubsTitle: "Clubs light",
  clubsLead: "Orientation on the website — no membership in the app.",
  clubsCta: "Tours in the region",
  groupsTitle: "Ride together",
  groupsBody:
    "Groups live on Platz: invite link, roster in the browser. Public groups as a meeting pin on the map — no live GPS. Live pins only in the app HUD and only with opt-in. A website explanation without a second timeline.",
  toPlatz: "To Platz",
  shareLinks: "Tour and Mappe links",
  profilesTitle: "Sample profiles",
  profilesLead:
    "Editorial, clearly marked. No GPS traces, no invented kilometres.",
  openProfile: "Open profile",
  joinTitle: "How you join",
  join1Before: "Open a tour on the",
  join1Link: "map or region",
  join1After: "and leave a Stimme.",
  join2Before: "On",
  join2After: "share a collection or start a group by link.",
  join3Before: "Optionally create a",
  join3Mid: "— example:",
  join3All: "all samples",
};

const FR: CommunityCopy = {
  kicker: "Community",
  title: "Sur le Platz, pas dans un fil",
  lead: "FlowLine partage sorties, Stimmen et groupes. Pas de fil à Home, pas de GPS live devant la porte. La porte s’appelle Platz : Mappe, texte court sur la sortie, lien d’invitation. Les profils publics sont opt-in et ne portent pas de traces. Les Stimmen éditoriales sont marquées, les nouvelles partent en relecture.",
  features: [
    {
      title: "Platz",
      body: "La porte. Mappe, visibilité, GPX, Stimmen et groupes — les mêmes sorties que sur la carte.",
      href: "/library",
      cta: "Vers le Platz",
    },
    {
      title: "Stimmen",
      body: "Texte court sur la sortie, pas de traces dans le commentaire. Les nouvelles partent en relecture, l’éditorial est marqué.",
      href: "/tours/r-heidelberg-city",
      cta: "Exemple de sortie",
    },
    {
      title: "Partager une Mappe",
      body: "Une collection comme lien. Qui a le lien met les sorties dans sa propre Mappe — sans compte obligatoire.",
      href: "/share",
      cta: "Comment partager",
    },
    {
      title: "Sortir ensemble",
      body: "Un groupe avec lien d’invitation devant la porte. Le web tient roster et invitation. Pins live seulement dans le HUD de l’appli, avec opt-in.",
      href: "/library",
      cta: "Comment marchent les groupes",
    },
    {
      title: "Public Profile",
      body: "Seulement avec opt-in. Handle, sport, nombre de sorties optionnel — pas de traces GPS.",
      href: "/u/mara_road",
      cta: "Exemple mara_road",
    },
    {
      title: "Events et clubs",
      body: "Éditorial sur le site, pas dans l’app. Pas de faux RSVP, pas d’obligation de position live.",
      href: "/community#events",
      cta: "Dates",
    },
  ],
  privacyTitle: "Privacy-first",
  privacyBody: "Pas de traces dans les Stimmen. Profil public seulement avec opt-in.",
  moderationTitle: "Modération",
  moderationBody:
    "Les nouvelles Stimmen partent « en relecture ». L’éditorial est marqué.",
  linkTitle: "Lien plutôt que fil",
  linkBody: "Collection ou groupe par lien. Qui l’a est dedans.",
  outTitle: "Ce que la community n’est pas ici",
  out: [
    "Pas de fil à Home",
    "Pas de classement, pas de niveau",
    "Pas de GPS live sur la carte devant la porte",
    "Ride n’est pas un onglet",
    "Stimmen sans trace jointe",
  ],
  eventsTitle: "Prochains events",
  eventsLead: "Éditorial sur cette page, pas dans l’app. Pas de RSVP inventé.",
  regionCta: "Voir la région",
  clubsTitle: "Clubs light",
  clubsLead: "Orientation sur le site — pas d’adhésion dans l’app.",
  clubsCta: "Sorties dans la région",
  groupsTitle: "Sortir ensemble",
  groupsBody:
    "Les groupes vivent sur le Platz : lien d’invitation, roster dans le navigateur. Publics comme pin de rendez-vous sur la carte — pas de GPS live. Pins live seulement dans le HUD de l’appli et seulement avec opt-in. Une explication de site sans deuxième fil.",
  toPlatz: "Vers le Platz",
  shareLinks: "Liens de sortie et de Mappe",
  profilesTitle: "Profils exemple",
  profilesLead:
    "Éditorial, clairement marqué. Pas de traces GPS, pas de kilomètres inventés.",
  openProfile: "Ouvrir le profil",
  joinTitle: "Comment tu participes",
  join1Before: "Ouvre une sortie sur la",
  join1Link: "carte ou la région",
  join1After: "et laisse une Stimme.",
  join2Before: "Sur le",
  join2After: "partage une collection ou démarre un groupe par lien.",
  join3Before: "Optionnellement crée un",
  join3Mid: "— exemple :",
  join3All: "tous les exemples",
};

const IT: CommunityCopy = {
  kicker: "Community",
  title: "Sul Platz, non nel feed",
  lead: "FlowLine condivide uscite, Stimmen e gruppi. Niente timeline a Home e niente GPS live davanti al cancello. La porta si chiama Platz: Mappe, testo breve sull’uscita, link di invito. I profili pubblici sono opt-in e non portano tracce. Le Stimmen editoriali sono segnalate, le nuove partono in revisione.",
  features: [
    {
      title: "Platz",
      body: "La porta. Mappe, visibilità, GPX, Stimmen e gruppi — le stesse uscite della mappa.",
      href: "/library",
      cta: "Verso il Platz",
    },
    {
      title: "Stimmen",
      body: "Testo breve sull’uscita, niente tracce nel commento. Le nuove partono in revisione, l’editoriale è segnalato.",
      href: "/tours/r-heidelberg-city",
      cta: "Uscita esempio",
    },
    {
      title: "Condividi una Mappe",
      body: "Una raccolta come link. Chi ha il link mette le uscite nella propria Mappe — senza account obbligatorio.",
      href: "/share",
      cta: "Come condividere",
    },
    {
      title: "Uscire insieme",
      body: "Un gruppo con link di invito davanti al cancello. Il web tiene roster e invito. Pin live solo nell’HUD dell’app, con opt-in.",
      href: "/library",
      cta: "Come funzionano i gruppi",
    },
    {
      title: "Public Profile",
      body: "Solo con opt-in. Handle, sport, numero uscite opzionale — niente tracce GPS.",
      href: "/u/mara_road",
      cta: "Esempio mara_road",
    },
    {
      title: "Eventi e club",
      body: "Editoriale sul sito, non nell’app. Niente RSVP finto, niente obbligo di posizione live.",
      href: "/community#events",
      cta: "Date",
    },
  ],
  privacyTitle: "Privacy-first",
  privacyBody: "Niente tracce nelle Stimmen. Profilo pubblico solo con opt-in.",
  moderationTitle: "Moderazione",
  moderationBody:
    "Le nuove Stimmen partono «in revisione». L’editoriale è segnalato.",
  linkTitle: "Link invece del feed",
  linkBody: "Raccolta o gruppo per link. Chi ce l’ha è dentro.",
  outTitle: "Cosa la community non è, qui",
  out: [
    "Niente feed a Home",
    "Niente classifica, niente livello",
    "Niente GPS live sulla mappa davanti al cancello",
    "Ride non è una scheda",
    "Stimmen senza traccia in allegato",
  ],
  eventsTitle: "Prossimi eventi",
  eventsLead: "Editoriale su questa pagina, non nell’app. Niente RSVP inventato.",
  regionCta: "Vedi la regione",
  clubsTitle: "Club light",
  clubsLead: "Orientamento sul sito — niente iscrizione nell’app.",
  clubsCta: "Uscite nella regione",
  groupsTitle: "Uscire insieme",
  groupsBody:
    "I gruppi vivono sul Platz: link di invito, roster nel browser. Pubblici come pin di ritrovo sulla mappa — niente GPS live. Pin live solo nell’HUD dell’app e solo con opt-in. Una spiegazione del sito senza seconda timeline.",
  toPlatz: "Verso il Platz",
  shareLinks: "Link di uscite e Mappe",
  profilesTitle: "Profili esempio",
  profilesLead:
    "Editoriale, chiaramente segnalato. Niente tracce GPS, niente chilometri inventati.",
  openProfile: "Apri il profilo",
  joinTitle: "Come partecipi",
  join1Before: "Apri un’uscita sulla",
  join1Link: "mappa o regione",
  join1After: "e lascia una Stimme.",
  join2Before: "Sul",
  join2After: "condividi una raccolta o avvia un gruppo per link.",
  join3Before: "Opzionalmente crea un",
  join3Mid: "— esempio:",
  join3All: "tutti gli esempi",
};

const NL: CommunityCopy = {
  kicker: "Community",
  title: "Op de Platz, niet in een feed",
  lead: "FlowLine deelt tochten, Stimmen en groepen. Geen tijdlijn bij Home en geen live-GPS bij de poort. De deur heet Platz: Mappe, korte tekst aan de tocht, uitnodigingslink. Publieke profielen zijn opt-in en dragen geen sporen. Redactionele Stimmen zijn gemarkeerd, nieuwe Stimmen starten in beoordeling.",
  features: [
    {
      title: "Platz",
      body: "De deur. Mappe, zichtbaarheid, GPX, Stimmen en groepen — dezelfde tochten als op de kaart.",
      href: "/library",
      cta: "Naar de Platz",
    },
    {
      title: "Stimmen",
      body: "Korte tekst aan de tocht, geen tracks in de reactie. Nieuwe starten in beoordeling, redactioneel is gemarkeerd.",
      href: "/tours/r-heidelberg-city",
      cta: "Voorbeeldtocht",
    },
    {
      title: "Een Mappe delen",
      body: "Een verzameling als link. Wie de link heeft, zet de tochten in de eigen Mappe — geen account verplicht.",
      href: "/share",
      cta: "Zo delen",
    },
    {
      title: "Samen eruit",
      body: "Een groep met uitnodigingslink bij de poort. Web houdt roster en uitnodiging. Live-pins alleen in de app-HUD, met opt-in.",
      href: "/library",
      cta: "Hoe groepen werken",
    },
    {
      title: "Public Profile",
      body: "Alleen met opt-in. Handle, sport, optioneel aantal ritten — geen GPS-sporen.",
      href: "/u/mara_road",
      cta: "Voorbeeld mara_road",
    },
    {
      title: "Events & clubs",
      body: "Redactioneel op de website, niet in de app. Geen nep-RSVP, geen live-locatieplicht.",
      href: "/community#events",
      cta: "Datums",
    },
  ],
  privacyTitle: "Privacy-first",
  privacyBody: "Geen tracks in Stimmen. Publiek profiel alleen met opt-in.",
  moderationTitle: "Moderatie",
  moderationBody:
    "Nieuwe Stimmen starten „in beoordeling”. Redactioneel is gemarkeerd.",
  linkTitle: "Link in plaats van feed",
  linkBody: "Verzameling of groep via link. Wie hem heeft, is erbij.",
  outTitle: "Wat community hier niet is",
  out: [
    "Geen feed bij Home",
    "Geen klassement, geen level",
    "Geen live-GPS op de kaart bij de poort",
    "Ride is geen tab",
    "Stimmen zonder track erbij",
  ],
  eventsTitle: "Komende events",
  eventsLead: "Redactioneel op deze pagina, niet in de app. Geen verzonnen RSVP.",
  regionCta: "Regio bekijken",
  clubsTitle: "Clubs light",
  clubsLead: "Oriëntatie op de website — geen lidmaatschap in de app.",
  clubsCta: "Tochten in de regio",
  groupsTitle: "Samen eruit",
  groupsBody:
    "Groepen leven op de Platz: uitnodigingslink, roster in de browser. Openbaar als trefpunt-pin op de kaart — geen live-GPS. Live-pins alleen in de app-HUD en alleen met opt-in. Een website-uitleg zonder tweede tijdlijn.",
  toPlatz: "Naar de Platz",
  shareLinks: "Tocht- en Mappe-links",
  profilesTitle: "Voorbeeldprofielen",
  profilesLead:
    "Redactioneel, duidelijk gemarkeerd. Geen GPS-sporen, geen verzonnen kilometers.",
  openProfile: "Profiel openen",
  joinTitle: "Zo doe je mee",
  join1Before: "Open een tocht op de",
  join1Link: "kaart of regio",
  join1After: "en laat een Stimme achter.",
  join2Before: "Op de",
  join2After: "een verzameling delen of een groep starten via een link.",
  join3Before: "Optioneel een",
  join3Mid: "aanmaken — voorbeeld:",
  join3All: "alle voorbeelden",
};

const BY_LANG: Record<ChromeLang, CommunityCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function communityCopy(lang: ChromeLang): CommunityCopy {
  return BY_LANG[lang];
}
