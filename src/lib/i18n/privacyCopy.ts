/**
 * Privacy / export chrome. Headings follow Flutter ARB where keys exist.
 * Web can add a zone via coords/GPS — never invents a home pin.
 */
import type { ConsentPurpose } from "@/lib/privacy/consents";
import type { ChromeLang } from "./chromeLang";

export type PrivacyCopy = {
  exportTitle: string;
  exportGpx: string;
  exportFit: string;
  exportJson: string;
  exportStub: string;
  gpxEmpty: string;
  consents: string;
  policy: (version: string) => string;
  zones: string;
  zonesLead: string;
  noZonesWeb: string;
  zoneDelete: string;
  zoneAdd: string;
  zoneLabel: string;
  zoneLat: string;
  zoneLng: string;
  zoneSave: string;
  zoneInvalid: string;
  zoneUseGps: string;
  trimEndsTitle: string;
  trimEndsBody: string;
  zoneRadius200: string;
  zoneRadius500: string;
  zoneRadius1000: string;
  familyTitle: string;
  familyHint: string;
  familyOneBike: string;
  familySetups: (n: number) => string;
  stravaConnect: string;
  stravaUpload: string;
  stravaUploading: string;
  stravaConnected: string;
  stravaLinked: string;
  stravaConfiguredOff: string;
  stravaStatus: (state: string) => string;
  stravaMissing: string;
  stravaOauthOff: string;
  uploadedGpx: string;
  uploadedMeta: string;
  uploadFailed: string;
  stubSummary: string;
  stubLocal: string;
  backToProfile: string;
  consent: Record<ConsentPurpose, { title: string; description: string }>;
};

const DE: PrivacyCopy = {
  exportTitle: "Export (Art. 20)",
  exportGpx: "Letzten Ride als GPX",
  exportFit: "Letzten Ride als FIT",
  exportJson: "JSON-Vollexport",
  exportStub: "Strava-Payload (lokal, Entwickler)",
  gpxEmpty:
    "Dieser Ride hat keinen GPS-Track — GPX wäre leer. JSON-Export nutzen.",
  consents: "Einwilligungen",
  policy: (v) => `Policy ${v}`,
  zones: "Privatsphärenzonen",
  zonesLead:
    "Tracks werden in diesen Radien gekappt — für Export und wo viele fahren.",
  noZonesWeb:
    "Keine Zone. Die ersten und letzten 200 m werden trotzdem gekürzt — Zuhause bleibt oft erkennbar. Keine erfundene Heimat-Zone.",
  zoneDelete: "Zone löschen",
  zoneAdd: "Zone anlegen",
  zoneLabel: "Bezeichnung",
  zoneLat: "Breite",
  zoneLng: "Länge",
  zoneSave: "Zone speichern",
  zoneInvalid: "Koordinaten ungültig",
  zoneUseGps: "Aktuellen Standort nutzen",
  trimEndsTitle: "Start und Ziel kürzen (200 m)",
  trimEndsBody: "Bei Export, Strava und Heatmap. Ohne Zone bleibt das Haus oft erkennbar.",
  zoneRadius200: "200 m",
  zoneRadius500: "500 m",
  zoneRadius1000: "1000 m",
  familyTitle: "Familie am Rad",
  familyHint: "Familien-Link / Mitfahrer: Gewicht und Setup für diesen Fahrer.",
  familyOneBike: "Ein Rad, mehrere Fahrer mit eigenen Setups.",
  familySetups: (n) => `${n} Setups`,
  stravaConnect: "Mit Strava verbinden",
  stravaUpload: "Letzten Ride zu Strava",
  stravaUploading: "Lade hoch…",
  stravaConnected: "verbunden",
  stravaLinked: "Strava verbunden",
  stravaConfiguredOff: "konfiguriert, nicht verbunden",
  stravaStatus: (state) => `Status: ${state}`,
  stravaMissing:
    "Strava ist nicht eingerichtet. GPX, FIT und JSON sind die Exportwege.",
  stravaOauthOff: "Strava OAuth nicht konfiguriert.",
  uploadedGpx: "Bei Strava hochgeladen (mit Track).",
  uploadedMeta: "Bei Strava hochgeladen (nur Metadaten).",
  uploadFailed: "Upload fehlgeschlagen",
  stubSummary: "Advanced — Stub-Export",
  stubLocal: "Lokaler Dev-/QA-Export — kein Live-Upload.",
  backToProfile: "← Profil",
  consent: {
    raw_data_upload: {
      title: "Rohdaten-Upload",
      description:
        "Sensor-Rohdaten nur bei WLAN und wenn du zustimmst. Jederzeit widerrufbar.",
    },
    heatmap_contribution: {
      title: "Wo viele fahren (anonym, erst ab 5)",
      description:
        "Lokal: deine Fahrten. Mit Konto: anonymisierte Zellen ohne Zeitstempel. Die Karte erscheint erst, wenn 5 Fahrer in einer Zelle unterwegs waren.",
    },
    product_recommendations: {
      title: "Produktempfehlungen",
      description:
        "Nur anlassbezogen, mit nachvollziehbarem Datenpunkt. Kein Tracking-Marketing.",
    },
    analytics: {
      title: "Analytics",
      description: "Produktmetriken ohne Gesundheits- oder Rohsensordaten.",
    },
    health_data: {
      title: "Gesundheitsdaten",
      description:
        "Vorbereitung — noch keine Anbindung an Health Connect. Die Einwilligung speichert nur deine Präferenz für später.",
    },
  },
};

const EN: PrivacyCopy = {
  exportTitle: "Export (Art. 20)",
  exportGpx: "Last ride as GPX",
  exportFit: "Last ride as FIT",
  exportJson: "Full JSON export",
  exportStub: "Strava payload (local, developer)",
  gpxEmpty:
    "This ride has no GPS track — GPX would be empty. Use the JSON export.",
  consents: "Consents",
  policy: (v) => `Policy ${v}`,
  zones: "Privacy zones",
  zonesLead:
    "Tracks are clipped in these radii — for export and where many ride.",
  noZonesWeb:
    "No zone. The first and last 200 m are still trimmed — home often remains identifiable. No invented home pin.",
  zoneDelete: "Delete zone",
  zoneAdd: "Add zone",
  zoneLabel: "Label",
  zoneLat: "Latitude",
  zoneLng: "Longitude",
  zoneSave: "Save zone",
  zoneInvalid: "Invalid coordinates",
  zoneUseGps: "Use current location",
  trimEndsTitle: "Trim start and end (200 m)",
  trimEndsBody: "Applies to export, Strava and heatmap. Without a zone, home often stays visible.",
  zoneRadius200: "200 m",
  zoneRadius500: "500 m",
  zoneRadius1000: "1000 m",
  familyTitle: "Family on the bike",
  familyHint: "Family / extra riders: weight and setup for this rider.",
  familyOneBike: "One bike, several riders with their own setups.",
  familySetups: (n) => `${n} setups`,
  stravaConnect: "Connect Strava",
  stravaUpload: "Last ride to Strava",
  stravaUploading: "Uploading…",
  stravaConnected: "connected",
  stravaLinked: "Strava connected",
  stravaConfiguredOff: "configured, not connected",
  stravaStatus: (state) => `Status: ${state}`,
  stravaMissing:
    "Strava is not set up. GPX, FIT, and JSON are the export paths.",
  stravaOauthOff: "Strava OAuth is not configured.",
  uploadedGpx: "Uploaded to Strava (with track).",
  uploadedMeta: "Uploaded to Strava (metadata only).",
  uploadFailed: "Upload failed",
  stubSummary: "Advanced — stub export",
  stubLocal: "Local dev/QA export — not a live upload.",
  backToProfile: "← Profile",
  consent: {
    raw_data_upload: {
      title: "Raw data upload",
      description:
        "Sensor raw data only on Wi-Fi and if you agree. Revocable anytime.",
    },
    heatmap_contribution: {
      title: "Where many ride (anonymous, from 5 up)",
      description:
        "Local: your rides. With an account: anonymized cells without timestamps. The map appears once 5 riders have been in a cell.",
    },
    product_recommendations: {
      title: "Product recommendations",
      description:
        "Only when relevant, with a traceable data point. No tracking marketing.",
    },
    analytics: {
      title: "Analytics",
      description: "Product metrics without health or raw sensor data.",
    },
    health_data: {
      title: "Health data",
      description:
        "Prep — Health Connect is not wired yet. This consent only stores your preference for later.",
    },
  },
};

const FR: PrivacyCopy = {
  exportTitle: "Export (art. 20)",
  exportGpx: "Dernière sortie en GPX",
  exportFit: "Dernière sortie en FIT",
  exportJson: "Export JSON complet",
  exportStub: "Payload Strava (local, développeur)",
  gpxEmpty:
    "Cette sortie n’a pas de trace GPS — le GPX serait vide. Utilise l’export JSON.",
  consents: "Consentements",
  policy: (v) => `Policy ${v}`,
  zones: "Zones privacy",
  zonesLead:
    "Les traces sont coupées dans ces rayons — pour l’export et là où on roule.",
  noZonesWeb:
    "Aucune zone. Les 200 m de départ et d’arrivée sont quand même coupés — la maison reste souvent identifiable. Pas de pin maison inventé.",
  zoneDelete: "Supprimer la zone",
  zoneAdd: "Ajouter une zone",
  zoneLabel: "Libellé",
  zoneLat: "Latitude",
  zoneLng: "Longitude",
  zoneSave: "Enregistrer la zone",
  zoneInvalid: "Coordonnées invalides",
  zoneUseGps: "Utiliser la position actuelle",
  trimEndsTitle: "Raccourcir départ et arrivée (200 m)",
  trimEndsBody: "Pour export, Strava et heatmap. Sans zone, la maison reste souvent visible.",
  zoneRadius200: "200 m",
  zoneRadius500: "500 m",
  zoneRadius1000: "1000 m",
  familyTitle: "Famille au vélo",
  familyHint: "Famille / autres riders : poids et setup pour ce rider.",
  familyOneBike: "Un vélo, plusieurs riders avec leurs propres setups.",
  familySetups: (n) => `${n} setups`,
  stravaConnect: "Connecter Strava",
  stravaUpload: "Dernière sortie vers Strava",
  stravaUploading: "Envoi…",
  stravaConnected: "connecté",
  stravaLinked: "Strava connecté",
  stravaConfiguredOff: "configuré, pas connecté",
  stravaStatus: (state) => `Statut : ${state}`,
  stravaMissing:
    "Strava n’est pas configuré. GPX, FIT et JSON restent les chemins d’export.",
  stravaOauthOff: "OAuth Strava non configuré.",
  uploadedGpx: "Envoyé vers Strava (avec trace).",
  uploadedMeta: "Envoyé vers Strava (métadonnées seulement).",
  uploadFailed: "Envoi échoué",
  stubSummary: "Avancé — export stub",
  stubLocal: "Export local dev/QA — pas d’upload live.",
  backToProfile: "← Profil",
  consent: {
    raw_data_upload: {
      title: "Upload de données brutes",
      description:
        "Données brutes des capteurs seulement en Wi-Fi et si tu acceptes. Révoquable à tout moment.",
    },
    heatmap_contribution: {
      title: "Là où on roule (anonyme, dès 5)",
      description:
        "En local : tes sorties. Avec un compte : cellules anonymisées sans horodatage. La carte apparaît dès que 5 riders sont passés dans une cellule.",
    },
    product_recommendations: {
      title: "Recommandations produits",
      description:
        "Seulement quand c’est pertinent, avec un point de donnée traçable. Pas de marketing de tracking.",
    },
    analytics: {
      title: "Analytics",
      description: "Métriques produit sans données de santé ni capteurs bruts.",
    },
    health_data: {
      title: "Données de santé",
      description:
        "Préparation — Health Connect n’est pas encore branché. Ce consentement enregistre seulement ta préférence pour plus tard.",
    },
  },
};

const IT: PrivacyCopy = {
  exportTitle: "Export (art. 20)",
  exportGpx: "Ultima uscita come GPX",
  exportFit: "Ultima uscita come FIT",
  exportJson: "Export JSON completo",
  exportStub: "Payload Strava (locale, sviluppatore)",
  gpxEmpty:
    "Questa uscita non ha traccia GPS — il GPX sarebbe vuoto. Usa l’export JSON.",
  consents: "Consensi",
  policy: (v) => `Policy ${v}`,
  zones: "Zone privacy",
  zonesLead:
    "Le tracce vengono tagliate in questi raggi — per export e dove si gira.",
  noZonesWeb:
    "Nessuna zona. I primi e gli ultimi 200 m vengono comunque tagliati — casa resta spesso riconoscibile. Nessun pin di casa inventato.",
  zoneDelete: "Elimina zona",
  zoneAdd: "Aggiungi zona",
  zoneLabel: "Etichetta",
  zoneLat: "Latitudine",
  zoneLng: "Longitudine",
  zoneSave: "Salva zona",
  zoneInvalid: "Coordinate non valide",
  zoneUseGps: "Usa posizione attuale",
  trimEndsTitle: "Accorcia partenza e arrivo (200 m)",
  trimEndsBody: "Per export, Strava e heatmap. Senza zona, casa resta spesso riconoscibile.",
  zoneRadius200: "200 m",
  zoneRadius500: "500 m",
  zoneRadius1000: "1000 m",
  familyTitle: "Famiglia in bici",
  familyHint: "Famiglia / altri rider: peso e setup per questo rider.",
  familyOneBike: "Una bici, più rider con i propri setup.",
  familySetups: (n) => `${n} setup`,
  stravaConnect: "Collega Strava",
  stravaUpload: "Ultima uscita su Strava",
  stravaUploading: "Caricamento…",
  stravaConnected: "collegato",
  stravaLinked: "Strava collegato",
  stravaConfiguredOff: "configurato, non collegato",
  stravaStatus: (state) => `Stato: ${state}`,
  stravaMissing:
    "Strava non è configurato. GPX, FIT e JSON restano le vie di export.",
  stravaOauthOff: "OAuth Strava non configurato.",
  uploadedGpx: "Caricato su Strava (con traccia).",
  uploadedMeta: "Caricato su Strava (solo metadati).",
  uploadFailed: "Upload non riuscito",
  stubSummary: "Avanzate — export stub",
  stubLocal: "Export locale dev/QA — non è un upload live.",
  backToProfile: "← Profilo",
  consent: {
    raw_data_upload: {
      title: "Upload dati grezzi",
      description:
        "Dati grezzi dei sensori solo su Wi-Fi e se accetti. Revocabile in qualsiasi momento.",
    },
    heatmap_contribution: {
      title: "Dove si gira (anonimo, da 5 in su)",
      description:
        "In locale: le tue uscite. Con un account: celle anonimizzate senza timestamp. La mappa compare quando 5 rider sono passati in una cella.",
    },
    product_recommendations: {
      title: "Raccomandazioni prodotti",
      description:
        "Solo quando è pertinente, con un dato tracciabile. Niente marketing di tracking.",
    },
    analytics: {
      title: "Analytics",
      description: "Metriche prodotto senza dati di salute né sensori grezzi.",
    },
    health_data: {
      title: "Dati di salute",
      description:
        "Preparazione — Health Connect non è ancora collegato. Questo consenso salva solo la tua preferenza per dopo.",
    },
  },
};

const NL: PrivacyCopy = {
  exportTitle: "Exporteren (art. 20)",
  exportGpx: "Laatste rit als GPX",
  exportFit: "Laatste rit als FIT",
  exportJson: "Volledige JSON-export",
  exportStub: "Strava-payload (lokaal, ontwikkelaar)",
  gpxEmpty:
    "Deze rit heeft geen GPS-spoor — GPX zou leeg zijn. Gebruik de JSON-export.",
  consents: "Toestemmingen",
  policy: (v) => `Policy ${v}`,
  zones: "Privacyzones",
  zonesLead:
    "Spoor wordt in deze stralen geknipt — voor export en waar velen rijden.",
  noZonesWeb:
    "Geen zone. De eerste en laatste 200 m worden toch geknipt — thuis blijft vaak herkenbaar. Geen verzonnen thuispin.",
  zoneDelete: "Zone verwijderen",
  zoneAdd: "Zone toevoegen",
  zoneLabel: "Label",
  zoneLat: "Breedte",
  zoneLng: "Lengte",
  zoneSave: "Zone opslaan",
  zoneInvalid: "Ongeldige coördinaten",
  zoneUseGps: "Huidige locatie gebruiken",
  trimEndsTitle: "Start en finish inkorten (200 m)",
  trimEndsBody: "Bij export, Strava en heatmap. Zonder zone blijft thuis vaak herkenbaar.",
  zoneRadius200: "200 m",
  zoneRadius500: "500 m",
  zoneRadius1000: "1000 m",
  familyTitle: "Gezin aan de fiets",
  familyHint: "Gezin / extra rijders: gewicht en setup voor deze rijder.",
  familyOneBike: "Eén fiets, meerdere rijders met eigen setups.",
  familySetups: (n) => `${n} setups`,
  stravaConnect: "Strava verbinden",
  stravaUpload: "Laatste rit naar Strava",
  stravaUploading: "Uploaden…",
  stravaConnected: "verbonden",
  stravaLinked: "Strava verbonden",
  stravaConfiguredOff: "geconfigureerd, niet verbonden",
  stravaStatus: (state) => `Status: ${state}`,
  stravaMissing:
    "Strava is niet ingesteld. GPX, FIT en JSON zijn de exportpaden.",
  stravaOauthOff: "Strava-OAuth niet geconfigureerd.",
  uploadedGpx: "Naar Strava geüpload (met spoor).",
  uploadedMeta: "Naar Strava geüpload (alleen metadata).",
  uploadFailed: "Upload mislukt",
  stubSummary: "Geavanceerd — stub-export",
  stubLocal: "Lokale dev/QA-export — geen live-upload.",
  backToProfile: "← Profiel",
  consent: {
    raw_data_upload: {
      title: "Raw-data-upload",
      description:
        "Sensor-raw-data alleen via wifi en als je toestemt. Altijd intrekbaar.",
    },
    heatmap_contribution: {
      title: "Waar velen rijden (anoniem, vanaf 5)",
      description:
        "Lokaal: jouw ritten. Met account: geanonimiseerde cellen zonder tijdstempels. De kaart verschijnt als 5 rijders in een cel zijn geweest.",
    },
    product_recommendations: {
      title: "Productaanbevelingen",
      description:
        "Alleen als het relevant is, met een navolgbaar datapunt. Geen tracking-marketing.",
    },
    analytics: {
      title: "Analytics",
      description: "Productmetrics zonder gezondheid of raw-sensordata.",
    },
    health_data: {
      title: "Gezondheidsdata",
      description:
        "Voorbereiding — Health Connect is nog niet gekoppeld. Deze toestemming slaat alleen je voorkeur op voor later.",
    },
  },
};

const BY: Record<ChromeLang, PrivacyCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function privacyCopy(lang: ChromeLang = "de"): PrivacyCopy {
  return BY[lang] ?? DE;
}

/** Query-flags and API still speak German; the page maps known keys. */
export function presentPrivacyStatus(
  de: string,
  lang: ChromeLang = "de"
): string {
  const c = privacyCopy(lang);
  if (de === "Strava verbunden." || de === DE.stravaLinked)
    return c.stravaLinked;
  if (de === DE.stravaOauthOff) return c.stravaOauthOff;
  if (de === DE.uploadedGpx) return c.uploadedGpx;
  if (de === DE.uploadedMeta) return c.uploadedMeta;
  if (de === DE.uploadFailed) return c.uploadFailed;
  const prefixed = de.match(/^Strava: (.+)$/);
  if (prefixed) return `Strava: ${prefixed[1]}`;
  return de;
}
