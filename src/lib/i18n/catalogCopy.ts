import type { ChromeLang } from "./chromeLang";

export type CatalogCopy = {
  regions: {
    title: string;
    lead: string;
    noneOnMap: string;
    toursLine: (n: number, sports: string) => string;
  };
  region: {
    openMap: string;
    empty: string;
    openMapCta: string;
    planCta: string;
    toursIn: (name: string) => string;
    voicesTitle: string;
    voicesLead: string;
    datesTitle: string;
    datesLead: string;
    allDates: string;
    guidesTitle: string;
    neighborsTitle: string;
    neighborsLead: string;
    mapTitle: string;
    mapLead: string;
    mapOpen: string;
    mapTap: string;
  };
  tour: {
    atGate: string;
    loop: string;
    stage: string;
    distance: string;
    elevation: string;
    duration: string;
    difficulty: string;
    roadPath: string;
    about: string;
    honestTitle: string;
    honestBody: string;
    seedKicker: string;
    seedHonestBody: string;
    region: string;
    allToursIn: (name: string) => string;
    disciplines: string;
    similar: string;
    startInApp: string;
    saved: string;
    save: string;
    openPlanner: string;
    inTours: string;
    flashSaved: string;
    flashRemoved: string;
    copyLink: string;
    linkCopied: string;
    noTrackHint: string;
    mapLoading: string;
    mapUnreachable: string;
    mapStart: string;
    mapEnd: string;
    mapPlaces: string;
    kitTitle: string;
    kitLead: string;
    eventTitle: string;
    eventLead: string;
    eventOpen: string;
    groupTitle: string;
    groupBody: string;
    groupCta: string;
    fn: {
      map: string;
      elevation: string;
      weather: string;
      stimmen: string;
      share: string;
      mappe: string;
      gpx: string;
      plan: string;
      ride: string;
      group: string;
      event: string;
      club: string;
      places: string;
    };
  };
  weather: {
    loading: string;
    unreachable: string;
    none: string;
    status: (code: number) => string;
    wet: string;
    damp: string;
    dry: string;
    precip: (mm: number, pct: number | undefined) => string;
  };
  elevation: {
    title: string;
    apiSample: string;
    fromMeta: string;
    noteApi: string;
    noteMeta: string;
  };
  stimmen: {
    heading: string;
    liveHint: string;
    empty: string;
    countLine: (avg: number, n: number, photos: number) => string;
    write: string;
    starsAria: (n: number) => string;
    namePlaceholder: string;
    nameAria: string;
    bodyPlaceholder: string;
    photo: string;
    photoAlt: string;
    counter: (n: number) => string;
    submit: string;
    pending: string;
    remove: string;
    minChars: string;
    ratingRange: string;
    savedLocalSignIn: string;
    thanksPublished: string;
    thanksPending: string;
    savedLocalCloud: string;
    tagsHint: string;
    tagLabel: (wire: string) => string;
    difficultyHint: string;
    difficultyEasier: string;
    difficultyAsMarked: string;
    difficultyHarder: string;
    crowdEasier: (n: number) => string;
    crowdAsMarked: (n: number) => string;
    crowdHarder: (n: number) => string;
    pinOnLine: string;
  };
};

const DE: CatalogCopy = {
  regions: {
    title: "Regionen",
    lead: "Redaktionelle Tour-Ideen nach Gebiet: Baden-Württemberg, Schwarzwald, Bayern, Bodensee, Norddeutschland, Berlin, NRW, Österreich, Schweiz. Die Stunde vor dem Tor kommt aus echten Nähe-Seeds — Hamburg Alster, nicht pauschal Alpen. Wo noch keine Touren stehen, gilt die Karte vor Ort. Es gibt keine Füll-Routen, damit die Liste voll wirkt.",
    noneOnMap: "Noch keine Touren · auf der Karte suchen",
    toursLine: (n, sports) => `${n} Touren · ${sports}`,
  },
  region: {
    openMap: "Auf der Karte öffnen",
    empty:
      "Noch keine redaktionellen Touren in dieser Region. Auf der Karte siehst du Nähe vor Ort — ohne Dummy-Routen.",
    openMapCta: "Karte öffnen →",
    planCta: "Planen →",
    toursIn: (name) => `Touren in ${name}`,
    voicesTitle: "Stimmen aus der Region",
    voicesLead: "Editorial-Profile, keine GPS-Spuren.",
    datesTitle: "Termine",
    datesLead: "Redaktionell — kein erfundenes RSVP.",
    allDates: "Alle Termine →",
    guidesTitle: "Passende Guides",
    neighborsTitle: "Nachbarregionen",
    neighborsLead: "Weiterlesen in der Nähe — nicht als GPS-Fill.",
    mapTitle: "Touren auf der Karte",
    mapLead: "Pin wählen zeigt die Tour — Öffnen führt zur Seite",
    mapOpen: "Tour öffnen",
    mapTap: "Pin wählen · Sportfarben",
  },
  tour: {
    atGate: "Vor dem Tor",
    loop: "Rundkurs",
    stage: "Etappe",
    distance: "Distanz",
    elevation: "Höhenmeter",
    duration: "Dauer",
    difficulty: "Schwierigkeit",
    roadPath: "Straße/Weg",
    about: "Über diese Tour",
    honestTitle: "Ehrlicher Hinweis",
    honestBody:
      "Das ist eine redaktionelle Tour-Idee, kein Community-Track mit vermessener GPS-Linie. Unter Planen oder Touren wird die Route mit dem gewählten Sport-Profil berechnet. Navigation und Offline nur in der nativen App. Stimmen sind moderiert und enthalten keine Tracks.",
    seedKicker: "Nähe-Idee",
    seedHonestBody:
      "Kuratierte Nähe-Idee, kein Community-Feed. Linie nur bei gespeichertem Track — sonst nur der Pin. Keine Sterne, keine erfundenen Fahrten.",
    region: "Region",
    allToursIn: (name) => `Alle Touren in ${name} →`,
    disciplines: "Disziplinen",
    similar: "Ähnliche Touren",
    startInApp: "In App starten",
    saved: "Gespeichert",
    save: "Speichern",
    openPlanner: "Im Planer öffnen",
    inTours: "In Touren",
    flashSaved: "In der Mappe",
    flashRemoved: "Aus der Mappe genommen",
    copyLink: "Tour-Link kopieren",
    linkCopied: "Link kopiert",
    noTrackHint: "Ohne Track. Katalog-Tour, schon freigegeben.",
    mapLoading: "Live-Route wird berechnet…",
    mapUnreachable: "Routing nicht erreichbar",
    mapStart: "Start",
    mapEnd: "Ziel",
    mapPlaces: "Orte an der Tour",
    kitTitle: "Funktionen dieser Tour",
    kitLead:
      "Was an dieser Katalog-Tour wirklich hängt: Karte, Profil, Wetter, Stimmen, Teilen, Mappe, GPX, Planen, Fahrt, Gruppe, Termin, Club, Orte.",
    eventTitle: "Termin an dieser Tour",
    eventLead: "Redaktionell — kein RSVP, kein Live-Standort.",
    eventOpen: "Tour zum Termin →",
    groupTitle: "Zusammen raus",
    groupBody:
      "Gruppe mit Einladungslink auf dem Platz. Nur an freigegebener oder Katalog-Tour. Live-Pins nur in der App, mit Opt-in.",
    groupCta: "Gruppe auf dem Platz →",
    fn: {
      map: "Karte",
      elevation: "Höhe",
      weather: "Wetter",
      stimmen: "Stimmen",
      share: "Teilen",
      mappe: "Mappe",
      gpx: "GPX",
      plan: "Planen",
      ride: "Fahrt",
      group: "Gruppe",
      event: "Termin",
      club: "Club",
      places: "Orte",
    },
  },
  weather: {
    loading: "Wetter wird geladen…",
    unreachable: "Wetter nicht erreichbar",
    none: "Keine Wetterdaten",
    status: (code) => `Wetter ${code}`,
    wet: "Nass wahrscheinlich — Trails rutschig möglich",
    damp: "Leicht feucht möglich",
    dry: "Eher trocken",
    precip: (mm, pct) =>
      `Niederschlag heute ~${mm} mm${pct != null ? ` · max. ${pct} %` : ""}`,
  },
  elevation: {
    title: "Höhenprofil",
    apiSample: "API-Stichprobe",
    fromMeta: "Aus Tour-Metadaten",
    noteApi: "Höhenpunkte via Open-Elevation (Stichprobe um Pin)",
    noteMeta:
      "Geschätztes Profil aus km/hm — kein vermessener Track. Live-Routing unter Planen liefert die echte Linie.",
  },
  stimmen: {
    heading: "Stimmen",
    liveHint: "Live aus der Stimmen-API — keine Stub-Sterne.",
    empty: "Noch keine Stimmen.",
    countLine: (avg, n, photos) =>
      `${avg} · ${n} Stimmen${photos > 0 ? ` · ${photos} Fotos` : ""}`,
    write: "Stimme schreiben",
    starsAria: (n) => `${n} Sterne`,
    namePlaceholder: "Name",
    nameAria: "Anzeigename",
    bodyPlaceholder:
      "Wie war die Tour? Belag, Verkehr, Tipps… (keine privaten Orte)",
    photo: "Foto",
    photoAlt: "Stimmen-Foto",
    counter: (n) => `${n}/500 · Foto nach Login`,
    submit: "Absenden",
    pending: "In Prüfung",
    remove: "Entfernen",
    minChars: "Bitte mindestens 8 Zeichen schreiben.",
    ratingRange: "Bewertung 1–5.",
    savedLocalSignIn:
      "Gespeichert lokal — für Cloud und Foto bitte anmelden (Profil).",
    thanksPublished: "Danke — veröffentlicht.",
    thanksPending:
      "Danke — in Prüfung, bis zur Freigabe nur für dich sichtbar.",
    savedLocalCloud: "Gespeichert lokal — Cloud gerade nicht erreichbar.",
    tagsHint: "Zustand — optional, max. drei",
    tagLabel: (wire) =>
      ({
        nass: "nass",
        zu: "gesperrt",
        viel_los: "voll",
        top: "top",
        baustelle: "Baustelle",
      }[wire] ?? wire),
    difficultyHint: "Schwierigkeit gegenüber der Markierung — optional",
    difficultyEasier: "leichter",
    difficultyAsMarked: "wie markiert",
    difficultyHarder: "härter",
    crowdEasier: (n) => `Fahrer: eher leichter als markiert (${n})`,
    crowdAsMarked: (n) => `Fahrer: wie markiert (${n})`,
    crowdHarder: (n) => `Fahrer: eher härter als markiert (${n})`,
    pinOnLine: "Pin auf der Linie",
  },
};

const EN: CatalogCopy = {
  regions: {
    title: "Regions",
    lead: "Editorial tour ideas by area: Baden-Württemberg, Schwarzwald, Bayern, Bodensee, northern Germany, Berlin, NRW, Austria, Switzerland. The hour at the gate comes from real nearby seeds — Hamburg Alster, not generic Alps. Where no tours sit yet, the map on site applies. There are no filler routes to make the list look full.",
    noneOnMap: "No tours yet · search on the map",
    toursLine: (n, sports) => `${n} tours · ${sports}`,
  },
  region: {
    openMap: "Open on the map",
    empty:
      "No editorial tours in this region yet. On the map you see nearby loops — no dummy routes.",
    openMapCta: "Open map →",
    planCta: "Plan →",
    toursIn: (name) => `Tours in ${name}`,
    voicesTitle: "Stimmen from the region",
    voicesLead: "Editorial profiles, no GPS traces.",
    datesTitle: "Dates",
    datesLead: "Editorial — no invented RSVP.",
    allDates: "All dates →",
    guidesTitle: "Related guides",
    neighborsTitle: "Neighbouring regions",
    neighborsLead: "Read on nearby — not as GPS fill.",
    mapTitle: "Tours on the map",
    mapLead: "Select a pin to preview — Open goes to the tour page",
    mapOpen: "Open tour",
    mapTap: "Tap a pin · sport colours",
  },
  tour: {
    atGate: "At the gate",
    loop: "Loop",
    stage: "Stage",
    distance: "Distance",
    elevation: "Elevation",
    duration: "Duration",
    difficulty: "Difficulty",
    roadPath: "Road/path",
    about: "About this tour",
    honestTitle: "Honest note",
    honestBody:
      "This is an editorial tour idea, not a community track with a surveyed GPS line. Under Plan or Tours the route is calculated with the chosen sport profile. Navigation and offline only in the native app. Stimmen are moderated and carry no tracks.",
    seedKicker: "Nearby idea",
    seedHonestBody:
      "A curated nearby idea, not a community feed. A line only when a track is stored — otherwise just the pin. No stars, no invented ride counts.",
    region: "Region",
    allToursIn: (name) => `All tours in ${name} →`,
    disciplines: "Disciplines",
    similar: "Similar tours",
    startInApp: "Start in app",
    saved: "Saved",
    save: "Save",
    openPlanner: "Open in planner",
    inTours: "In Tours",
    flashSaved: "In Die Mappe",
    flashRemoved: "Removed from Die Mappe",
    copyLink: "Copy tour link",
    linkCopied: "Link copied",
    noTrackHint: "No track. Catalogue tour, already shared.",
    mapLoading: "Live route is being calculated…",
    mapUnreachable: "Routing unavailable",
    mapStart: "Start",
    mapEnd: "Finish",
    mapPlaces: "Places on the tour",
    kitTitle: "Functions on this tour",
    kitLead:
      "What this catalogue tour actually has: map, profile, weather, Stimmen, share, Mappe, GPX, plan, ride, group, date, club, places.",
    eventTitle: "Date on this tour",
    eventLead: "Editorial — no RSVP, no live location.",
    eventOpen: "Tour for this date →",
    groupTitle: "Ride together",
    groupBody:
      "Invite-link group on Platz. Only on a shared or catalogue tour. Live pins only in the app, with opt-in.",
    groupCta: "Group on Platz →",
    fn: {
      map: "Map",
      elevation: "Elevation",
      weather: "Weather",
      stimmen: "Stimmen",
      share: "Share",
      mappe: "Mappe",
      gpx: "GPX",
      plan: "Plan",
      ride: "Ride",
      group: "Group",
      event: "Date",
      club: "Club",
      places: "Places",
    },
  },
  weather: {
    loading: "Loading weather…",
    unreachable: "Weather unreachable",
    none: "No weather data",
    status: (code) => `Weather ${code}`,
    wet: "Wet likely — trails may be slippery",
    damp: "Slightly damp possible",
    dry: "Mostly dry",
    precip: (mm, pct) =>
      `Rain today ~${mm} mm${pct != null ? ` · max. ${pct} %` : ""}`,
  },
  elevation: {
    title: "Elevation profile",
    apiSample: "API sample",
    fromMeta: "From tour metadata",
    noteApi: "Elevation points via Open-Elevation (sample around the pin)",
    noteMeta:
      "Estimated profile from km/hm — not a surveyed track. Live routing under Plan delivers the real line.",
  },
  stimmen: {
    heading: "Stimmen",
    liveHint: "Live from the Stimmen API — no stub stars.",
    empty: "No Stimmen yet.",
    countLine: (avg, n, photos) =>
      `${avg} · ${n} Stimmen${photos > 0 ? ` · ${photos} photos` : ""}`,
    write: "Write a Stimme",
    starsAria: (n) => `${n} stars`,
    namePlaceholder: "Name",
    nameAria: "Display name",
    bodyPlaceholder:
      "How was the tour? Surface, traffic, tips… (no private places)",
    photo: "Photo",
    photoAlt: "Stimmen photo",
    counter: (n) => `${n}/500 · photo after sign-in`,
    submit: "Send",
    pending: "In review",
    remove: "Remove",
    minChars: "Please write at least 8 characters.",
    ratingRange: "Rating 1–5.",
    savedLocalSignIn: "Saved locally — sign in (Profile) for cloud and photo.",
    thanksPublished: "Thanks — published.",
    thanksPending: "Thanks — in review, visible only to you until approved.",
    savedLocalCloud: "Saved locally — cloud unreachable right now.",
    tagsHint: "Condition — optional, max three",
    tagLabel: (wire) =>
      ({
        nass: "wet",
        zu: "closed",
        viel_los: "busy",
        top: "top",
        baustelle: "works",
      }[wire] ?? wire),
    difficultyHint: "Difficulty vs the marked grade — optional",
    difficultyEasier: "easier",
    difficultyAsMarked: "as marked",
    difficultyHarder: "harder",
    crowdEasier: (n) => `Riders: easier than marked (${n})`,
    crowdAsMarked: (n) => `Riders: as marked (${n})`,
    crowdHarder: (n) => `Riders: harder than marked (${n})`,
    pinOnLine: "Pin on the line",
  },
};

const FR: CatalogCopy = {
  regions: {
    title: "Régions",
    lead: "Idées de sorties éditoriales par zone : Bade-Wurtemberg, Forêt-Noire, Bavière, lac de Constance, nord de l’Allemagne, Berlin, NRW, Autriche, Suisse. L’heure devant la porte vient de vrais seeds de proximité — Alster à Hambourg, pas les Alpes par défaut. Là où il n’y a pas encore de sorties, c’est la carte sur place. Pas de parcours de remplissage pour faire plein la liste.",
    noneOnMap: "Pas encore de sorties · chercher sur la carte",
    toursLine: (n, sports) => `${n} sorties · ${sports}`,
  },
  region: {
    openMap: "Ouvrir sur la carte",
    empty:
      "Pas encore de sorties éditoriales dans cette région. Sur la carte tu vois la proximité — sans parcours factices.",
    openMapCta: "Ouvrir la carte →",
    planCta: "Planifier →",
    toursIn: (name) => `Sorties à ${name}`,
    voicesTitle: "Stimmen de la région",
    voicesLead: "Profils éditoriaux, pas de traces GPS.",
    datesTitle: "Dates",
    datesLead: "Éditorial — pas de RSVP inventé.",
    allDates: "Toutes les dates →",
    guidesTitle: "Guides liés",
    neighborsTitle: "Régions voisines",
    neighborsLead: "Lire à proximité — pas comme remplissage GPS.",
    mapTitle: "Sorties sur la carte",
    mapLead: "Choisir une épingle prévisualise — Ouvrir mène à la page",
    mapOpen: "Ouvrir la sortie",
    mapTap: "Choisir une épingle · couleurs sport",
  },
  tour: {
    atGate: "Devant la porte",
    loop: "Boucle",
    stage: "Étape",
    distance: "Distance",
    elevation: "Dénivelé",
    duration: "Durée",
    difficulty: "Difficulté",
    roadPath: "Route/chemin",
    about: "Sur cette sortie",
    honestTitle: "Note honnête",
    honestBody:
      "C’est une idée de sortie éditoriale, pas une trace community avec une ligne GPS mesurée. Sous Planifier ou Sorties, l’itinéraire est calculé avec le profil sport choisi. Navigation et hors ligne seulement dans l’appli native. Les Stimmen sont modérées et ne portent pas de traces.",
    seedKicker: "Idée proche",
    seedHonestBody:
      "Idée de proximité, pas un fil community. Une ligne seulement s’il y a une trace enregistrée — sinon uniquement l’épingle. Pas d’étoiles, pas de sorties inventées.",
    region: "Région",
    allToursIn: (name) => `Toutes les sorties à ${name} →`,
    disciplines: "Disciplines",
    similar: "Sorties similaires",
    startInApp: "Démarrer dans l’app",
    saved: "Enregistré",
    save: "Enregistrer",
    openPlanner: "Ouvrir dans le planificateur",
    inTours: "Dans Sorties",
    flashSaved: "Dans Die Mappe",
    flashRemoved: "Retiré de Die Mappe",
    copyLink: "Copier le lien de sortie",
    linkCopied: "Lien copié",
    noTrackHint: "Sans trace. Sortie catalogue, déjà partagée.",
    mapLoading: "Itinéraire live en cours de calcul…",
    mapUnreachable: "Routage indisponible",
    mapStart: "Départ",
    mapEnd: "Arrivée",
    mapPlaces: "Lieux sur la sortie",
    kitTitle: "Fonctions de cette sortie",
    kitLead:
      "Ce que cette sortie catalogue a vraiment : carte, profil, météo, Stimmen, partage, Mappe, GPX, plan, sortie, groupe, date, club, lieux.",
    eventTitle: "Date sur cette sortie",
    eventLead: "Éditorial — pas de RSVP, pas de position live.",
    eventOpen: "Sortie pour cette date →",
    groupTitle: "Sortir ensemble",
    groupBody:
      "Groupe avec lien d’invitation sur Platz. Seulement sur une sortie partagée ou catalogue. Pins live seulement dans l’app, avec opt-in.",
    groupCta: "Groupe sur Platz →",
    fn: {
      map: "Carte",
      elevation: "Dénivelé",
      weather: "Météo",
      stimmen: "Stimmen",
      share: "Partager",
      mappe: "Mappe",
      gpx: "GPX",
      plan: "Planifier",
      ride: "Sortie",
      group: "Groupe",
      event: "Date",
      club: "Club",
      places: "Lieux",
    },
  },
  weather: {
    loading: "Météo en cours de chargement…",
    unreachable: "Météo injoignable",
    none: "Pas de données météo",
    status: (code) => `Météo ${code}`,
    wet: "Humide probable — trails glissants possibles",
    damp: "Légèrement humide possible",
    dry: "Plutôt sec",
    precip: (mm, pct) =>
      `Précipitations aujourd’hui ~${mm} mm${pct != null ? ` · max. ${pct} %` : ""}`,
  },
  elevation: {
    title: "Profil altimétrique",
    apiSample: "Échantillon API",
    fromMeta: "Depuis les métadonnées",
    noteApi: "Points d’altitude via Open-Elevation (échantillon autour de l’épingle)",
    noteMeta:
      "Profil estimé à partir des km/hm — pas une trace mesurée. Le routage live sous Planifier donne la vraie ligne.",
  },
  stimmen: {
    heading: "Stimmen",
    liveHint: "Live depuis l’API Stimmen — pas d’étoiles factices.",
    empty: "Pas encore de Stimmen.",
    countLine: (avg, n, photos) =>
      `${avg} · ${n} Stimmen${photos > 0 ? ` · ${photos} photos` : ""}`,
    write: "Écrire une Stimme",
    starsAria: (n) => `${n} étoiles`,
    namePlaceholder: "Nom",
    nameAria: "Nom affiché",
    bodyPlaceholder:
      "Comment était la sortie ? Revêtement, trafic, conseils… (pas de lieux privés)",
    photo: "Photo",
    photoAlt: "Photo Stimmen",
    counter: (n) => `${n}/500 · photo après connexion`,
    submit: "Envoyer",
    pending: "En relecture",
    remove: "Retirer",
    minChars: "Écris au moins 8 caractères.",
    ratingRange: "Note 1–5.",
    savedLocalSignIn:
      "Enregistré en local — connecte-toi (Profil) pour le cloud et la photo.",
    thanksPublished: "Merci — publié.",
    thanksPending:
      "Merci — en relecture, visible seulement pour toi jusqu’à validation.",
    savedLocalCloud: "Enregistré en local — cloud injoignable pour l’instant.",
    tagsHint: "État — optionnel, max. trois",
    tagLabel: (wire) =>
      ({
        nass: "mouillé",
        zu: "fermé",
        viel_los: "fréquenté",
        top: "top",
        baustelle: "travaux",
      }[wire] ?? wire),
    difficultyHint: "Difficulté par rapport au niveau indiqué — optionnel",
    difficultyEasier: "plus facile",
    difficultyAsMarked: "comme indiqué",
    difficultyHarder: "plus dur",
    crowdEasier: (n) => `Coureurs : plus facile que marqué (${n})`,
    crowdAsMarked: (n) => `Coureurs : comme indiqué (${n})`,
    crowdHarder: (n) => `Coureurs : plus dur que marqué (${n})`,
    pinOnLine: "Pin sur la ligne",
  },
};

const IT: CatalogCopy = {
  regions: {
    title: "Regioni",
    lead: "Idee di uscita editoriali per zona: Baden-Württemberg, Foresta Nera, Baviera, Lago di Costanza, nord Germania, Berlino, NRW, Austria, Svizzera. L’ora davanti al cancello viene da seed di prossimità veri — Alster ad Amburgo, non Alpi generiche. Dove non ci sono ancora uscite vale la mappa sul posto. Niente percorsi di riempimento per far sembrare piena la lista.",
    noneOnMap: "Ancora nessuna uscita · cerca sulla mappa",
    toursLine: (n, sports) => `${n} uscite · ${sports}`,
  },
  region: {
    openMap: "Apri sulla mappa",
    empty:
      "Ancora nessuna uscita editoriale in questa regione. Sulla mappa vedi la vicinanza — senza percorsi finti.",
    openMapCta: "Apri la mappa →",
    planCta: "Pianifica →",
    toursIn: (name) => `Uscite a ${name}`,
    voicesTitle: "Stimmen dalla regione",
    voicesLead: "Profili editoriali, nessuna traccia GPS.",
    datesTitle: "Date",
    datesLead: "Editoriale — niente RSVP inventato.",
    allDates: "Tutte le date →",
    guidesTitle: "Guide collegate",
    neighborsTitle: "Regioni vicine",
    neighborsLead: "Continua nelle vicinanze — non come riempimento GPS.",
    mapTitle: "Uscite sulla mappa",
    mapLead: "Scegliere un pin mostra l’uscita — Apri porta alla pagina",
    mapOpen: "Apri l’uscita",
    mapTap: "Scegli un pin · colori sport",
  },
  tour: {
    atGate: "Davanti al cancello",
    loop: "Anello",
    stage: "Tappa",
    distance: "Distanza",
    elevation: "Dislivello",
    duration: "Durata",
    difficulty: "Difficoltà",
    roadPath: "Strada/sentiero",
    about: "Su questa uscita",
    honestTitle: "Nota onesta",
    honestBody:
      "È un’idea di uscita editoriale, non una traccia community con linea GPS rilevata. Sotto Pianifica o Uscite il percorso è calcolato con il profilo sport scelto. Navigazione e offline solo nell’app nativa. Le Stimmen sono moderate e non portano tracce.",
    seedKicker: "Idea vicina",
    seedHonestBody:
      "Idea di prossimità, non un feed community. Linea solo con traccia salvata — altrimenti solo il pin. Niente stelle, niente uscite inventate.",
    region: "Regione",
    allToursIn: (name) => `Tutte le uscite a ${name} →`,
    disciplines: "Discipline",
    similar: "Uscite simili",
    startInApp: "Avvia nell’app",
    saved: "Salvato",
    save: "Salva",
    openPlanner: "Apri nel planner",
    inTours: "Nelle uscite",
    flashSaved: "In Die Mappe",
    flashRemoved: "Tolto da Die Mappe",
    copyLink: "Copia link uscita",
    linkCopied: "Link copiato",
    noTrackHint: "Senza traccia. Uscita catalogo, già condivisa.",
    mapLoading: "Percorso live in calcolo…",
    mapUnreachable: "Routing non raggiungibile",
    mapStart: "Partenza",
    mapEnd: "Arrivo",
    mapPlaces: "Luoghi sull’uscita",
    kitTitle: "Funzioni di questa uscita",
    kitLead:
      "Cosa ha davvero questa uscita catalogo: mappa, profilo, meteo, Stimmen, condivisione, Mappe, GPX, piano, uscita, gruppo, data, club, luoghi.",
    eventTitle: "Data su questa uscita",
    eventLead: "Editoriale — niente RSVP, niente posizione live.",
    eventOpen: "Uscita per questa data →",
    groupTitle: "Uscire insieme",
    groupBody:
      "Gruppo con link d’invito sul Platz. Solo su uscita condivisa o catalogo. Pin live solo nell’app, con opt-in.",
    groupCta: "Gruppo sul Platz →",
    fn: {
      map: "Mappa",
      elevation: "Dislivello",
      weather: "Meteo",
      stimmen: "Stimmen",
      share: "Condividi",
      mappe: "Mappe",
      gpx: "GPX",
      plan: "Pianifica",
      ride: "Uscita",
      group: "Gruppo",
      event: "Data",
      club: "Club",
      places: "Luoghi",
    },
  },
  weather: {
    loading: "Meteo in caricamento…",
    unreachable: "Meteo non raggiungibile",
    none: "Nessun dato meteo",
    status: (code) => `Meteo ${code}`,
    wet: "Bagnato probabile — trail scivolosi possibili",
    damp: "Leggermente umido possibile",
    dry: "Piuttosto asciutto",
    precip: (mm, pct) =>
      `Precipitazioni oggi ~${mm} mm${pct != null ? ` · max. ${pct} %` : ""}`,
  },
  elevation: {
    title: "Profilo altimetrico",
    apiSample: "Campione API",
    fromMeta: "Dai metadati dell’uscita",
    noteApi: "Punti quota via Open-Elevation (campione intorno al pin)",
    noteMeta:
      "Profilo stimato da km/hm — non una traccia rilevata. Il routing live sotto Pianifica dà la linea vera.",
  },
  stimmen: {
    heading: "Stimmen",
    liveHint: "Live dall’API Stimmen — niente stelle fittizie.",
    empty: "Ancora nessuna Stimme.",
    countLine: (avg, n, photos) =>
      `${avg} · ${n} Stimmen${photos > 0 ? ` · ${photos} foto` : ""}`,
    write: "Scrivi una Stimme",
    starsAria: (n) => `${n} stelle`,
    namePlaceholder: "Nome",
    nameAria: "Nome visibile",
    bodyPlaceholder:
      "Com’era l’uscita? Fondo, traffico, consigli… (niente luoghi privati)",
    photo: "Foto",
    photoAlt: "Foto Stimmen",
    counter: (n) => `${n}/500 · foto dopo l’accesso`,
    submit: "Invia",
    pending: "In revisione",
    remove: "Rimuovi",
    minChars: "Scrivi almeno 8 caratteri.",
    ratingRange: "Valutazione 1–5.",
    savedLocalSignIn:
      "Salvato in locale — accedi (Profilo) per cloud e foto.",
    thanksPublished: "Grazie — pubblicato.",
    thanksPending:
      "Grazie — in revisione, visibile solo a te fino all’approvazione.",
    savedLocalCloud: "Salvato in locale — cloud non raggiungibile ora.",
    tagsHint: "Stato — opzionale, max tre",
    tagLabel: (wire) =>
      ({
        nass: "bagnato",
        zu: "chiuso",
        viel_los: "affollato",
        top: "top",
        baustelle: "cantiere",
      }[wire] ?? wire),
    difficultyHint: "Difficoltà rispetto al grado indicato — opzionale",
    difficultyEasier: "più facile",
    difficultyAsMarked: "come indicato",
    difficultyHarder: "più duro",
    crowdEasier: (n) => `Rider: più facile del segnato (${n})`,
    crowdAsMarked: (n) => `Rider: come indicato (${n})`,
    crowdHarder: (n) => `Rider: più duro del segnato (${n})`,
    pinOnLine: "Pin sulla linea",
  },
};

const NL: CatalogCopy = {
  regions: {
    title: "Regio's",
    lead: "Redactionele tochtideeën per gebied: Baden-Württemberg, Schwarzwald, Bayern, Bodensee, Noord-Duitsland, Berlin, NRW, Oostenrijk, Zwitserland. Het uur voor de poort komt uit echte nabijheid-seeds — Hamburg Alster, niet generiek de Alpen. Waar nog geen tochten staan, geldt de kaart ter plaatse. Geen vulroutes om de lijst vol te laten lijken.",
    noneOnMap: "Nog geen tochten · zoek op de kaart",
    toursLine: (n, sports) => `${n} tochten · ${sports}`,
  },
  region: {
    openMap: "Openen op de kaart",
    empty:
      "Nog geen redactionele tochten in deze regio. Op de kaart zie je nabijheid — zonder dummy-routes.",
    openMapCta: "Kaart openen →",
    planCta: "Plannen →",
    toursIn: (name) => `Tochten in ${name}`,
    voicesTitle: "Stimmen uit de regio",
    voicesLead: "Editorial-profielen, geen GPS-sporen.",
    datesTitle: "Data",
    datesLead: "Redactioneel — geen verzonnen RSVP.",
    allDates: "Alle data →",
    guidesTitle: "Passende guides",
    neighborsTitle: "Buurregio's",
    neighborsLead: "Verder lezen in de buurt — niet als GPS-vulling.",
    mapTitle: "Tochten op de kaart",
    mapLead: "Pin kiezen toont de tocht — Openen gaat naar de pagina",
    mapOpen: "Tocht openen",
    mapTap: "Pin kiezen · sportkleuren",
  },
  tour: {
    atGate: "Voor de poort",
    loop: "Lus",
    stage: "Etappe",
    distance: "Afstand",
    elevation: "Hoogtemeters",
    duration: "Duur",
    difficulty: "Moeilijkheid",
    roadPath: "Weg/pad",
    about: "Over deze tocht",
    honestTitle: "Eerlijke noot",
    honestBody:
      "Dit is een redactioneel tochtidee, geen community-track met gemeten GPS-lijn. Onder Plannen of Tochten wordt de route berekend met het gekozen sportprofiel. Navigatie en offline alleen in de native app. Stimmen zijn gemodereerd en dragen geen tracks.",
    seedKicker: "Idee in de buurt",
    seedHonestBody:
      "Idee in de buurt, geen community-feed. Lijn alleen bij opgeslagen track — anders alleen de pin. Geen sterren, geen verzonnen ritten.",
    region: "Regio",
    allToursIn: (name) => `Alle tochten in ${name} →`,
    disciplines: "Disciplines",
    similar: "Vergelijkbare tochten",
    startInApp: "Starten in app",
    saved: "Opgeslagen",
    save: "Opslaan",
    openPlanner: "In de planner openen",
    inTours: "In Tochten",
    flashSaved: "In Die Mappe",
    flashRemoved: "Uit Die Mappe gehaald",
    copyLink: "Tochtlink kopiëren",
    linkCopied: "Link gekopieerd",
    noTrackHint: "Zonder track. Catalogustocht, al gedeeld.",
    mapLoading: "Live-route wordt berekend…",
    mapUnreachable: "Routing niet bereikbaar",
    mapStart: "Start",
    mapEnd: "Finish",
    mapPlaces: "Plekken op de tocht",
    kitTitle: "Functies van deze tocht",
    kitLead:
      "Wat deze catalogustocht echt heeft: kaart, profiel, weer, Stimmen, delen, Mappe, GPX, plannen, rit, groep, datum, club, plekken.",
    eventTitle: "Datum bij deze tocht",
    eventLead: "Redactioneel — geen RSVP, geen live-locatie.",
    eventOpen: "Tocht bij deze datum →",
    groupTitle: "Samen eropuit",
    groupBody:
      "Groep met uitnodigingslink op Platz. Alleen op een gedeelde of catalogustocht. Live-pins alleen in de app, met opt-in.",
    groupCta: "Groep op Platz →",
    fn: {
      map: "Kaart",
      elevation: "Hoogte",
      weather: "Weer",
      stimmen: "Stimmen",
      share: "Delen",
      mappe: "Mappe",
      gpx: "GPX",
      plan: "Plannen",
      ride: "Rit",
      group: "Groep",
      event: "Datum",
      club: "Club",
      places: "Plekken",
    },
  },
  weather: {
    loading: "Weer wordt geladen…",
    unreachable: "Weer niet bereikbaar",
    none: "Geen weerdata",
    status: (code) => `Weer ${code}`,
    wet: "Nat waarschijnlijk — trails kunnen glad zijn",
    damp: "Licht vochtig mogelijk",
    dry: "Eerder droog",
    precip: (mm, pct) =>
      `Neerslag vandaag ~${mm} mm${pct != null ? ` · max. ${pct} %` : ""}`,
  },
  elevation: {
    title: "Hoogteprofiel",
    apiSample: "API-steekproef",
    fromMeta: "Uit tochtmetadata",
    noteApi: "Hoogtepunten via Open-Elevation (steekproef rond de pin)",
    noteMeta:
      "Geschat profiel uit km/hm — geen gemeten track. Live-routing onder Plannen geeft de echte lijn.",
  },
  stimmen: {
    heading: "Stimmen",
    liveHint: "Live uit de Stimmen-API — geen stub-sterren.",
    empty: "Nog geen Stimmen.",
    countLine: (avg, n, photos) =>
      `${avg} · ${n} Stimmen${photos > 0 ? ` · ${photos} foto's` : ""}`,
    write: "Stimme schrijven",
    starsAria: (n) => `${n} sterren`,
    namePlaceholder: "Naam",
    nameAria: "Weergavenaam",
    bodyPlaceholder:
      "Hoe was de tocht? Ondergrond, verkeer, tips… (geen privéplekken)",
    photo: "Foto",
    photoAlt: "Stimmen-foto",
    counter: (n) => `${n}/500 · foto na login`,
    submit: "Versturen",
    pending: "In beoordeling",
    remove: "Verwijderen",
    minChars: "Schrijf minstens 8 tekens.",
    ratingRange: "Beoordeling 1–5.",
    savedLocalSignIn:
      "Lokaal opgeslagen — meld je aan (Profiel) voor cloud en foto.",
    thanksPublished: "Dank — gepubliceerd.",
    thanksPending:
      "Dank — in beoordeling, tot vrijgave alleen voor jou zichtbaar.",
    savedLocalCloud: "Lokaal opgeslagen — cloud nu niet bereikbaar.",
    tagsHint: "Staat — optioneel, max. drie",
    tagLabel: (wire) =>
      ({
        nass: "nat",
        zu: "dicht",
        viel_los: "druk",
        top: "top",
        baustelle: "werkzaamheden",
      }[wire] ?? wire),
    difficultyHint: "Moeilijkheid t.o.v. de markering — optioneel",
    difficultyEasier: "lichter",
    difficultyAsMarked: "zoals gemarkeerd",
    difficultyHarder: "zwaarder",
    crowdEasier: (n) => `Rijders: eerder lichter dan gemarkeerd (${n})`,
    crowdAsMarked: (n) => `Rijders: zoals gemarkeerd (${n})`,
    crowdHarder: (n) => `Rijders: eerder zwaarder dan gemarkeerd (${n})`,
    pinOnLine: "Pin op de lijn",
  },
};

const BY_LANG: Record<ChromeLang, CatalogCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function catalogCopy(lang: ChromeLang): CatalogCopy {
  return BY_LANG[lang];
}
