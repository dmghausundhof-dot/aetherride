import type { ChromeLang } from "./chromeLang";

export type RideTelemetryCopy = {
  title: string;
  hint: string;
  noElevation: string;
  climb: string;
  descent: string;
  maxGrade: string;
  maxSpeed: string;
  avgSpeed: string;
  hr: string;
  cad: string;
  power: string;
  lean: string;
  impact: string;
  steepUp: string;
  up: string;
  roll: string;
  down: string;
  steepDown: string;
  gap: string;
  km: string;
  hm: string;
  gpsSource: string;
  hoverHere: string;
  notFound: string;
  notFoundHint: string;
  backToList: string;
  activitiesNav: string;
  noTrack: string;
  chassis: string;
  analysis: string;
  noRide: string;
  until: string;
  elevMeters: string;
  openApp: string;
  toMap: string;
  happened: string;
  noticed: string;
  sensorDetails: string;
  distance: string;
  duration: string;
  flowScore: string;
  maxLean: string;
  impactsTotal: string;
  impactsPerKm: string;
  flow: string;
  peakG: string;
  rmsG: string;
  openGarage: string;
  assist: string;
  assistHint: string;
  recommendations: string;
  shopParts: string;
  lastRounds: string;
  lastRoundsHint: string;
  lastAgo: string;
  freeride: string;
  setup: string;
  feedback: string;
  noFeedback: string;
  feedbackSkip: string;
  feedbackOverall: string;
  feedbackPostRide: string;
  tourOnPlatz: string;
  ebikeSimTitle: string;
  ebikeSimHint: string;
  assistLog: string;
  dominant: string;
  segments: string;
  source: string;
  howWasIt: string;
  howWasHint: string;
  front: string;
  brake: string;
  smallBump: string;
  tooSoft: string;
  ok: string;
  tooFirm: string;
  dives: string;
  neutral: string;
  harsh: string;
  rough: string;
  vague: string;
  save: string;
  skip: string;
  feedbackSaved: string;
  askMore: string;
  askMoreLead: string;
  done: string;
  loadingAnalysis: string;
  profileMore: string;
  profileMoreHint: string;
  assistant: string;
  back: string;
  dismiss: string;
  heatmapPrivate: string;
  heatmapPrefix: string;
  expectedEffect: string;
  limits: string;
  why: string;
  accept: string;
  reject: string;
  whatYouCanChange: string;
  min: string;
  avgSocSim: string;
  avgRiderPowerSim: string;
};

const DE: RideTelemetryCopy = {
  title: "Strecke & Neigung",
  hint: "Höhe und Neigung aus GPS. Lücken bleiben Lücken — kein nachgezeichnetes Profil.",
  noElevation: "Keine Höhenpunkte im Track. Neigung ist dann nicht belastbar.",
  climb: "Anstieg",
  descent: "Abfahrt",
  maxGrade: "Steilste",
  maxSpeed: "Spitze",
  avgSpeed: "Schnitt",
  hr: "Puls",
  cad: "Cadenz",
  power: "Leistung",
  lean: "Lean",
  impact: "Impacts",
  steepUp: "Steil bergauf",
  up: "Anstieg",
  roll: "Flach",
  down: "Abfahrt",
  steepDown: "Steil bergab",
  gap: "Lücke",
  km: "km",
  hm: "hm",
  gpsSource: "GPS",
  hoverHere: "Über das Profil fahren — Punkt auf der Karte.",
  notFound: "Aktivität nicht gefunden",
  notFoundHint: "Möglicherweise noch nicht gesynct oder lokal gelöscht.",
  backToList: "← Zur Liste",
  activitiesNav: "Aktivitäten",
  noTrack: "Kein Track gespeichert",
  chassis: "Fahrwerk",
  analysis: "Analyse",
  noRide: "Kein Ride gefunden",
  until: "bis",
  elevMeters: "Höhenmeter",
  openApp: "App öffnen",
  toMap: "Zur Karte",
  happened: "Was passiert ist",
  noticed: "Was aufgefallen ist",
  sensorDetails: "Sensor-Details",
  distance: "Distanz",
  duration: "Dauer",
  flowScore: "Flow Score",
  maxLean: "Max Lean",
  impactsTotal: "Impacts gesamt",
  impactsPerKm: "Impacts / km",
  flow: "Flow",
  peakG: "Peak g",
  rmsG: "RMS g",
  openGarage: "Am Rad öffnen →",
  assist: "Assist (E-Bike)",
  assistHint: "Geschätzte Verteilung — keine Motorsteuerung.",
  recommendations: "Empfehlungen",
  shopParts: "Passende Teile im Shop",
  lastRounds: "Letzte Runden mit diesem Rad",
  lastRoundsHint: "Echte Fahrten — keine erfundenen Kilometer.",
  lastAgo: "Zuletzt",
  freeride: "Freeride",
  setup: "Setup",
  feedback: "Feedback",
  noFeedback: "Noch kein Post-Ride-Feedback.",
  feedbackSkip: "übersprungen",
  feedbackOverall: "Gesamtgefühl",
  feedbackPostRide: "Feedback / Post-Ride →",
  tourOnPlatz: "Tour auf dem Platz",
  ebikeSimTitle: "E-Bike-Livedaten (Simulation)",
  ebikeSimHint:
    "Web-Demo-Werte — keine echten E-Bike-Livedaten. Echte Kopplung nur in der App.",
  assistLog: "Assist-Modus-Log",
  dominant: "Dominant",
  segments: "Segmente",
  source: "Quelle",
  howWasIt: "Wie war's?",
  howWasHint: "Max. 3 Taps — verbessert die nächste Setup-Empfehlung.",
  front: "Front",
  brake: "Anbremsen",
  smallBump: "Kleine Schläge",
  tooSoft: "zu weich",
  ok: "passt",
  tooFirm: "zu hart",
  dives: "taucht ab",
  neutral: "neutral",
  harsh: "hart",
  rough: "rau",
  vague: "vage",
  save: "Speichern",
  skip: "Überspringen",
  feedbackSaved: "Feedback erfasst",
  askMore: "Mehr fragen (KI)",
  askMoreLead: "Tiefe Fragen?",
  done: "Fertig",
  loadingAnalysis: "Lade Analyse…",
  profileMore: "Mehr",
  profileMoreHint: "Kein fünfter Tab — diese Türen hängen am Profil.",
  assistant: "Assistent",
  back: "Zurück",
  dismiss: "OK",
  heatmapPrivate: "Wo viele fahren: private Tour — Spur nicht beigetragen.",
  heatmapPrefix: "Wo viele fahren",
  expectedEffect: "Erwartete Wirkung",
  limits: "Grenzen",
  why: "Warum?",
  accept: "Übernehmen",
  reject: "Verwerfen",
  whatYouCanChange: "Was du ändern kannst",
  min: "min",
  avgSocSim: "Ø SOC (Sim.)",
  avgRiderPowerSim: "Ø Rider Power (Sim.)",
};

const EN: RideTelemetryCopy = {
  title: "Route & grade",
  hint: "Elevation and grade from GPS. Gaps stay gaps — no filled-in profile.",
  noElevation: "No elevation on the track. Grade is then not reliable.",
  climb: "Climb",
  descent: "Descent",
  maxGrade: "Steepest",
  maxSpeed: "Peak",
  avgSpeed: "Average",
  hr: "Heart rate",
  cad: "Cadence",
  power: "Power",
  lean: "Lean",
  impact: "Impacts",
  steepUp: "Steep climb",
  up: "Climb",
  roll: "Rolling",
  down: "Descent",
  steepDown: "Steep descent",
  gap: "Gap",
  km: "km",
  hm: "m+",
  gpsSource: "GPS",
  hoverHere: "Hover the profile — point on the map.",
  notFound: "Activity not found",
  notFoundHint: "Maybe not synced yet, or deleted locally.",
  backToList: "← Back to the list",
  activitiesNav: "Activities",
  noTrack: "No track saved",
  chassis: "Suspension",
  analysis: "Analysis",
  noRide: "No ride found",
  until: "until",
  elevMeters: "Elevation",
  openApp: "Open the app",
  toMap: "To the map",
  happened: "What happened",
  noticed: "What stood out",
  sensorDetails: "Sensor details",
  distance: "Distance",
  duration: "Duration",
  flowScore: "Flow score",
  maxLean: "Max lean",
  impactsTotal: "Impacts total",
  impactsPerKm: "Impacts / km",
  flow: "Flow",
  peakG: "Peak g",
  rmsG: "RMS g",
  openGarage: "Open on the bike →",
  assist: "Assist (e-bike)",
  assistHint: "Estimated split — not motor control.",
  recommendations: "Recommendations",
  shopParts: "Matching parts in the shop",
  lastRounds: "Recent rides on this bike",
  lastRoundsHint: "Real rides — no invented kilometres.",
  lastAgo: "Last",
  freeride: "Freeride",
  setup: "Setup",
  feedback: "Feedback",
  noFeedback: "No post-ride feedback yet.",
  feedbackSkip: "skipped",
  feedbackOverall: "Overall feel",
  feedbackPostRide: "Feedback / post-ride →",
  tourOnPlatz: "Tour on the Platz",
  ebikeSimTitle: "E-bike live data (simulation)",
  ebikeSimHint:
    "Web demo values — not real e-bike live data. Real pairing only in the app.",
  assistLog: "Assist mode log",
  dominant: "Dominant",
  segments: "Segments",
  source: "Source",
  howWasIt: "How was it?",
  howWasHint: "Max. 3 taps — improves the next setup suggestion.",
  front: "Front",
  brake: "Braking",
  smallBump: "Small hits",
  tooSoft: "too soft",
  ok: "fine",
  tooFirm: "too firm",
  dives: "dives",
  neutral: "neutral",
  harsh: "harsh",
  rough: "rough",
  vague: "vague",
  save: "Save",
  skip: "Skip",
  feedbackSaved: "Feedback saved",
  askMore: "Ask more (AI)",
  askMoreLead: "Deeper questions?",
  done: "Done",
  loadingAnalysis: "Loading analysis…",
  profileMore: "More",
  profileMoreHint: "Not a fifth tab — these doors hang on the profile.",
  assistant: "Assistant",
  back: "Back",
  dismiss: "OK",
  heatmapPrivate: "Where people ride: private tour — track not contributed.",
  heatmapPrefix: "Where people ride",
  expectedEffect: "Expected effect",
  limits: "Limits",
  why: "Why?",
  accept: "Apply",
  reject: "Dismiss",
  whatYouCanChange: "What you can change",
  min: "min",
  avgSocSim: "Avg SOC (sim.)",
  avgRiderPowerSim: "Avg rider power (sim.)",
};

const FR: RideTelemetryCopy = {
  title: "Trace et pente",
  hint: "Altitude et pente GPS. Les trous restent des trous — pas de profil inventé.",
  noElevation: "Pas d’altitude sur la trace. La pente n’est alors pas fiable.",
  climb: "Montée",
  descent: "Descente",
  maxGrade: "Plus raide",
  maxSpeed: "Pic",
  avgSpeed: "Moyenne",
  hr: "Pouls",
  cad: "Cadence",
  power: "Puissance",
  lean: "Inclinaison",
  impact: "Impacts",
  steepUp: "Montée raide",
  up: "Montée",
  roll: "Plat",
  down: "Descente",
  steepDown: "Descente raide",
  gap: "Trou",
  km: "km",
  hm: "m+",
  gpsSource: "GPS",
  hoverHere: "Survoler le profil — point sur la carte.",
  notFound: "Activité introuvable",
  notFoundHint: "Pas encore synchronisée, ou déjà effacée ici.",
  backToList: "← Vers la liste",
  activitiesNav: "Activités",
  noTrack: "Aucune trace enregistrée",
  chassis: "Suspension",
  analysis: "Analyse",
  noRide: "Aucune sortie trouvée",
  until: "jusqu’à",
  elevMeters: "Dénivelé",
  openApp: "Ouvrir l’app",
  toMap: "Vers la carte",
  happened: "Ce qui s’est passé",
  noticed: "Ce qui a frappé",
  sensorDetails: "Détails capteurs",
  distance: "Distance",
  duration: "Durée",
  flowScore: "Score Flow",
  maxLean: "Inclinaison max",
  impactsTotal: "Impacts total",
  impactsPerKm: "Impacts / km",
  flow: "Flow",
  peakG: "Pic g",
  rmsG: "RMS g",
  openGarage: "Ouvrir sur le vélo →",
  assist: "Assist (VTTAE)",
  assistHint: "Répartition estimée — pas de commande moteur.",
  recommendations: "Recommandations",
  shopParts: "Pièces adaptées au magasin",
  lastRounds: "Dernières sorties sur ce vélo",
  lastRoundsHint: "Vraies sorties — pas de kilomètres inventés.",
  lastAgo: "Dernière",
  freeride: "Freeride",
  setup: "Réglage",
  feedback: "Avis",
  noFeedback: "Pas encore d’avis après la sortie.",
  feedbackSkip: "passé",
  feedbackOverall: "Sensation globale",
  feedbackPostRide: "Avis / après sortie →",
  tourOnPlatz: "Parcours sur le Platz",
  ebikeSimTitle: "Données live VAE (simulation)",
  ebikeSimHint:
    "Valeurs démo web — pas de vraies données live. Couplage réel seulement dans l’app.",
  assistLog: "Journal des modes d’assistance",
  dominant: "Dominant",
  segments: "Segments",
  source: "Source",
  howWasIt: "Comment c’était ?",
  howWasHint: "3 taps max — améliore la prochaine suggestion de réglage.",
  front: "Avant",
  brake: "Freinage",
  smallBump: "Petits chocs",
  tooSoft: "trop souple",
  ok: "ok",
  tooFirm: "trop ferme",
  dives: "plonge",
  neutral: "neutre",
  harsh: "dur",
  rough: "rugueux",
  vague: "vague",
  save: "Enregistrer",
  skip: "Passer",
  feedbackSaved: "Avis enregistré",
  askMore: "En demander plus (IA)",
  askMoreLead: "Questions plus profondes ?",
  done: "Terminé",
  loadingAnalysis: "Chargement de l’analyse…",
  profileMore: "Plus",
  profileMoreHint: "Pas un cinquième onglet — ces portes tiennent au profil.",
  assistant: "Assistant",
  back: "Retour",
  dismiss: "OK",
  heatmapPrivate: "Où l’on roule : parcours privé — trace non partagée.",
  heatmapPrefix: "Où l’on roule",
  expectedEffect: "Effet attendu",
  limits: "Limites",
  why: "Pourquoi ?",
  accept: "Appliquer",
  reject: "Rejeter",
  whatYouCanChange: "Ce que tu peux changer",
  min: "min",
  avgSocSim: "SOC moy. (sim.)",
  avgRiderPowerSim: "Puissance cycliste moy. (sim.)",
};

const IT: RideTelemetryCopy = {
  title: "Traccia e pendenza",
  hint: "Quota e pendenza dal GPS. I buchi restano buchi — niente profilo inventato.",
  noElevation: "Nessuna quota sulla traccia. La pendenza non è allora affidabile.",
  climb: "Salita",
  descent: "Discesa",
  maxGrade: "Più ripida",
  maxSpeed: "Picco",
  avgSpeed: "Media",
  hr: "Battito",
  cad: "Cadenza",
  power: "Potenza",
  lean: "Inclinazione",
  impact: "Impatti",
  steepUp: "Salita ripida",
  up: "Salita",
  roll: "Pianeggiante",
  down: "Discesa",
  steepDown: "Discesa ripida",
  gap: "Buco",
  km: "km",
  hm: "m+",
  gpsSource: "GPS",
  hoverHere: "Passa sul profilo — punto sulla mappa.",
  notFound: "Attività non trovata",
  notFoundHint: "Forse non ancora sincronizzata, o già cancellata qui.",
  backToList: "← Alla lista",
  activitiesNav: "Attività",
  noTrack: "Nessuna traccia salvata",
  chassis: "Sospensione",
  analysis: "Analisi",
  noRide: "Nessuna uscita trovata",
  until: "fino alle",
  elevMeters: "Dislivello",
  openApp: "Apri l’app",
  toMap: "Alla mappa",
  happened: "Cosa è successo",
  noticed: "Cosa è saltato all’occhio",
  sensorDetails: "Dettagli sensori",
  distance: "Distanza",
  duration: "Durata",
  flowScore: "Punteggio Flow",
  maxLean: "Inclinazione max",
  impactsTotal: "Impatti totali",
  impactsPerKm: "Impatti / km",
  flow: "Flow",
  peakG: "Picco g",
  rmsG: "RMS g",
  openGarage: "Apri sulla bici →",
  assist: "Assist (e-bike)",
  assistHint: "Ripartizione stimata — non è controllo motore.",
  recommendations: "Consigli",
  shopParts: "Parti adatte nel negozio",
  lastRounds: "Ultime uscite su questa bici",
  lastRoundsHint: "Uscite vere — niente chilometri inventati.",
  lastAgo: "Ultimi",
  freeride: "Freeride",
  setup: "Setup",
  feedback: "Feedback",
  noFeedback: "Ancora nessun feedback dopo l’uscita.",
  feedbackSkip: "saltato",
  feedbackOverall: "Sensazione generale",
  feedbackPostRide: "Feedback / post-ride →",
  tourOnPlatz: "Tour sul Platz",
  ebikeSimTitle: "Dati live e-bike (simulazione)",
  ebikeSimHint:
    "Valori demo web — non dati live reali. Accoppiamento vero solo nell’app.",
  assistLog: "Log modalità assist",
  dominant: "Dominante",
  segments: "Segmenti",
  source: "Fonte",
  howWasIt: "Com’è andata?",
  howWasHint: "Max 3 tap — migliora il prossimo consiglio di setup.",
  front: "Anteriore",
  brake: "Frenata",
  smallBump: "Colpi piccoli",
  tooSoft: "troppo morbida",
  ok: "ok",
  tooFirm: "troppo dura",
  dives: "affonda",
  neutral: "neutra",
  harsh: "dura",
  rough: "ruvida",
  vague: "vaga",
  save: "Salva",
  skip: "Salta",
  feedbackSaved: "Feedback salvato",
  askMore: "Chiedi di più (IA)",
  askMoreLead: "Domande più profonde?",
  done: "Fatto",
  loadingAnalysis: "Carico l’analisi…",
  profileMore: "Altro",
  profileMoreHint: "Non è un quinto tab — queste porte stanno sul profilo.",
  assistant: "Assistente",
  back: "Indietro",
  dismiss: "OK",
  heatmapPrivate: "Dove si pedala: tour privato — traccia non condivisa.",
  heatmapPrefix: "Dove si pedala",
  expectedEffect: "Effetto atteso",
  limits: "Limiti",
  why: "Perché?",
  accept: "Applica",
  reject: "Scarta",
  whatYouCanChange: "Cosa puoi cambiare",
  min: "min",
  avgSocSim: "SOC medio (sim.)",
  avgRiderPowerSim: "Potenza rider media (sim.)",
};

const NL: RideTelemetryCopy = {
  title: "Spoor & helling",
  hint: "Hoogte en helling uit GPS. Gaten blijven gaten — geen verzonnen profiel.",
  noElevation: "Geen hoogtepunten op het spoor. Helling is dan niet betrouwbaar.",
  climb: "Stijging",
  descent: "Afdaling",
  maxGrade: "Steilst",
  maxSpeed: "Piek",
  avgSpeed: "Gemiddeld",
  hr: "Hartslag",
  cad: "Cadans",
  power: "Vermogen",
  lean: "Hellingshoek",
  impact: "Impacts",
  steepUp: "Steil omhoog",
  up: "Stijging",
  roll: "Vlak",
  down: "Afdaling",
  steepDown: "Steil omlaag",
  gap: "Gat",
  km: "km",
  hm: "hm",
  gpsSource: "GPS",
  hoverHere: "Over het profiel — punt op de kaart.",
  notFound: "Activiteit niet gevonden",
  notFoundHint: "Nog niet gesynchroniseerd, of lokaal gewist.",
  backToList: "← Naar de lijst",
  activitiesNav: "Activiteiten",
  noTrack: "Geen spoor opgeslagen",
  chassis: "Vering",
  analysis: "Analyse",
  noRide: "Geen rit gevonden",
  until: "tot",
  elevMeters: "Hoogtemeters",
  openApp: "App openen",
  toMap: "Naar de kaart",
  happened: "Wat er gebeurde",
  noticed: "Wat opviel",
  sensorDetails: "Sensordetails",
  distance: "Afstand",
  duration: "Duur",
  flowScore: "Flow-score",
  maxLean: "Max lean",
  impactsTotal: "Impacts totaal",
  impactsPerKm: "Impacts / km",
  flow: "Flow",
  peakG: "Piek g",
  rmsG: "RMS g",
  openGarage: "Open op de fiets →",
  assist: "Assist (e-bike)",
  assistHint: "Geschatte verdeling — geen motorsturing.",
  recommendations: "Aanbevelingen",
  shopParts: "Passende onderdelen in de winkel",
  lastRounds: "Laatste ronden op deze fiets",
  lastRoundsHint: "Echte ritten — geen verzonnen kilometers.",
  lastAgo: "Laatst",
  freeride: "Freeride",
  setup: "Setup",
  feedback: "Feedback",
  noFeedback: "Nog geen post-ride-feedback.",
  feedbackSkip: "overgeslagen",
  feedbackOverall: "Algeheel gevoel",
  feedbackPostRide: "Feedback / post-ride →",
  tourOnPlatz: "Tocht op de Platz",
  ebikeSimTitle: "E-bike livedata (simulatie)",
  ebikeSimHint:
    "Web-demo-waarden — geen echte e-bike-livedata. Echte koppeling alleen in de app.",
  assistLog: "Assist-moduslog",
  dominant: "Dominant",
  segments: "Segmenten",
  source: "Bron",
  howWasIt: "Hoe was het?",
  howWasHint: "Max. 3 taps — verbetert de volgende setup-suggestie.",
  front: "Voor",
  brake: "Remmen",
  smallBump: "Kleine klappen",
  tooSoft: "te zacht",
  ok: "ok",
  tooFirm: "te hard",
  dives: "duikt",
  neutral: "neutraal",
  harsh: "hard",
  rough: "ruw",
  vague: "vaag",
  save: "Opslaan",
  skip: "Overslaan",
  feedbackSaved: "Feedback vastgelegd",
  askMore: "Meer vragen (AI)",
  askMoreLead: "Diepere vragen?",
  done: "Klaar",
  loadingAnalysis: "Analyse laden…",
  profileMore: "Meer",
  profileMoreHint: "Geen vijfde tab — deze deuren hangen aan het profiel.",
  assistant: "Assistent",
  back: "Terug",
  dismiss: "OK",
  heatmapPrivate: "Waar men rijdt: privétocht — spoor niet bijgedragen.",
  heatmapPrefix: "Waar men rijdt",
  expectedEffect: "Verwacht effect",
  limits: "Grenzen",
  why: "Waarom?",
  accept: "Toepassen",
  reject: "Verwerpen",
  whatYouCanChange: "Wat je kunt wijzigen",
  min: "min",
  avgSocSim: "Gem. SOC (sim.)",
  avgRiderPowerSim: "Gem. rider power (sim.)",
};

const BY_LANG: Record<ChromeLang, RideTelemetryCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function rideTelemetryCopy(lang: ChromeLang): RideTelemetryCopy {
  return BY_LANG[lang];
}
