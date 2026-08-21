/**
 * Garage tab chrome (Teile, Setup, chips, install sheet). DE matches previous UI.
 */
import type { ChromeLang } from "./chromeLang";

export type GarageTabCopy = {
  active: string;
  activeAria: (name: string) => string;
  use: string;
  installedOn: (date: string, km: string) => string;
  selfLogged: string;
  replace: string;
  uninstall: string;
  moveTo: string;
  move: string;
  spareShelf: string;
  spareHint: string;
  reinstall: string;
  spareEmpty: string;
  removedOn: (date: string) => string;
  installTitle: string;
  close: string;
  slot: string;
  makerModel: string;
  makerPlaceholder: string;
  catalogSearch: string;
  catalogPlaceholder: string;
  noHit: string;
  catalogLinked: string;
  saveName: string;
  assignInstall: string;
  rememberWithout: string;
  logged: string;
  setupVersionsTitle: string;
  setupVersionsHint: string;
  setupNew: string;
  setupNewHint: string;
  setupNamePlaceholder: string;
  setupSave: string;
  setupSaved: string;
  setupEmpty: string;
  setupVersion: (n: number) => string;
  setupTemplates: string;
  setupTemplatesHint: string;
  setupTemplateApplied: (label: string) => string;
  compatHeading: string;
};

const DE: GarageTabCopy = {
  active: "aktiv",
  activeAria: (name) => `Aktives Rad: ${name}`,
  use: "Nutzen",
  installedOn: (date, km) => `Einbau ${date} · ≈ ${km} km Laufleistung`,
  selfLogged: " · selbst angelegt",
  replace: "Ersetzen",
  uninstall: "Ausbauen",
  moveTo: "Ziel-Rad…",
  move: "Verschieben",
  spareShelf: "Ersatzteil-Regal",
  spareHint:
    "Ausgebaute Teile bleiben hier — z. B. zweites Laufrad oder Trainingskette. Wiedereinbau ersetzt den aktiven Slot.",
  reinstall: "Wieder einbauen",
  spareEmpty: "Regal leer — Teile ausbauen, um sie hier zu lagern.",
  removedOn: (date) => `Ausgebaut ${date}`,
  installTitle: "Teil eintragen",
  close: "Schließen",
  slot: "Slot",
  makerModel: "Hersteller und Modell",
  makerPlaceholder: "z. B. Maxxis Assegai",
  catalogSearch: "Im Katalog suchen",
  catalogPlaceholder: "optional — Treffer zuordnen",
  noHit: "Kein Treffer — einfach merken ohne Katalog.",
  catalogLinked: "Katalog zugeordnet — Kompat nur wenn Partner-Slots da sind.",
  saveName: "Ohne Treffer speichern wir den Namen. Kompat kannst du später zuordnen.",
  assignInstall: "Zuordnen und einbauen",
  rememberWithout: "Ohne Katalog merken",
  logged: "Eingetragen",
  setupVersionsTitle: "Versionen & Vergleich",
  setupVersionsHint:
    "Jede Änderung speichert eine neue Version. Du kannst jederzeit zurückwechseln.",
  setupNew: "Neue Version",
  setupNewHint:
    "Gib ihr einen Namen, den du wiedererkennst — z. B. „Trail trocken“.",
  setupNamePlaceholder: "Name z. B. Bikepark nass",
  setupSave: "Version speichern",
  setupSaved: "Gespeicherte Versionen",
  setupEmpty:
    "Noch keine Version — starte mit einer Vorlage oder speichere deine Einstellungen.",
  setupVersion: (n) => `Version ${n}`,
  setupTemplates: "Vorlagen zum Start",
  setupTemplatesHint: "Ausgangspunkt — keine persönliche Empfehlung.",
  setupTemplateApplied: (label) => `${label} (Vorlage)`,
  compatHeading: "Kompat",
};

const EN: GarageTabCopy = {
  active: "active",
  activeAria: (name) => `Active bike: ${name}`,
  use: "Use",
  installedOn: (date, km) => `Fitted ${date} · ≈ ${km} km on it`,
  selfLogged: " · entered by you",
  replace: "Replace",
  uninstall: "Remove",
  moveTo: "Move to…",
  move: "Move",
  spareShelf: "Spare shelf",
  spareHint:
    "Removed parts stay here — a second wheelset or a training chain. Reinstalling replaces the live slot.",
  reinstall: "Reinstall",
  spareEmpty: "Shelf empty — remove a part to store it here.",
  removedOn: (date) => `Removed ${date}`,
  installTitle: "Log a part",
  close: "Close",
  slot: "Slot",
  makerModel: "Make and model",
  makerPlaceholder: "e.g. Maxxis Assegai",
  catalogSearch: "Search the catalogue",
  catalogPlaceholder: "optional — match a hit",
  noHit: "No hit — just remember it without the catalogue.",
  catalogLinked: "Catalogue match — fit only if partner slots are there.",
  saveName: "Without a hit we store the name. You can attach fit later.",
  assignInstall: "Match and fit",
  rememberWithout: "Remember without catalogue",
  logged: "Logged",
  setupVersionsTitle: "Versions & compare",
  setupVersionsHint:
    "Each change stores a new version. You can switch back any time.",
  setupNew: "New version",
  setupNewHint: "Give it a name you’ll recognise — e.g. “trail dry”.",
  setupNamePlaceholder: "Name e.g. bike park wet",
  setupSave: "Save version",
  setupSaved: "Saved versions",
  setupEmpty: "No version yet — start from a template or save your settings.",
  setupVersion: (n) => `Version ${n}`,
  setupTemplates: "Starting templates",
  setupTemplatesHint: "A starting point — not a personal recommendation.",
  setupTemplateApplied: (label) => `${label} (template)`,
  compatHeading: "Fit",
};

const FR: GarageTabCopy = {
  active: "actif",
  activeAria: (name) => `Vélo actif : ${name}`,
  use: "Utiliser",
  installedOn: (date, km) => `Monté ${date} · ≈ ${km} km`,
  selfLogged: " · saisi par toi",
  replace: "Remplacer",
  uninstall: "Démonter",
  moveTo: "Vers le vélo…",
  move: "Déplacer",
  spareShelf: "Étagère pièces",
  spareHint:
    "Les pièces démontées restent ici — deuxième jeu de roues ou chaîne d’entraînement. Remonter remplace le slot actif.",
  reinstall: "Remonter",
  spareEmpty: "Étagère vide — démonte une pièce pour la ranger ici.",
  removedOn: (date) => `Démonté ${date}`,
  installTitle: "Enregistrer une pièce",
  close: "Fermer",
  slot: "Emplacement",
  makerModel: "Marque et modèle",
  makerPlaceholder: "ex. Maxxis Assegai",
  catalogSearch: "Chercher dans le catalogue",
  catalogPlaceholder: "optionnel — associer un résultat",
  noHit: "Aucun résultat — retiens-la sans catalogue.",
  catalogLinked: "Catalogue associé — compat seulement si les slots partenaires sont là.",
  saveName: "Sans résultat on garde le nom. La compat pourra venir plus tard.",
  assignInstall: "Associer et monter",
  rememberWithout: "Retenir sans catalogue",
  logged: "Enregistré",
  setupVersionsTitle: "Versions & comparaison",
  setupVersionsHint:
    "Chaque changement enregistre une nouvelle version. Tu peux revenir à tout moment.",
  setupNew: "Nouvelle version",
  setupNewHint: "Donne-lui un nom que tu reconnaîtras — p. ex. « trail sec ».",
  setupNamePlaceholder: "Nom p. ex. bikepark mouillé",
  setupSave: "Enregistrer la version",
  setupSaved: "Versions enregistrées",
  setupEmpty:
    "Pas encore de version — pars d’un modèle ou enregistre tes réglages.",
  setupVersion: (n) => `Version ${n}`,
  setupTemplates: "Modèles pour commencer",
  setupTemplatesHint: "Point de départ — pas une reco personnelle.",
  setupTemplateApplied: (label) => `${label} (modèle)`,
  compatHeading: "Compat",
};

const IT: GarageTabCopy = {
  active: "attiva",
  activeAria: (name) => `Bici attiva: ${name}`,
  use: "Usa",
  installedOn: (date, km) => `Montato ${date} · ≈ ${km} km`,
  selfLogged: " · inserito da te",
  replace: "Sostituisci",
  uninstall: "Smonta",
  moveTo: "Sposta su…",
  move: "Sposta",
  spareShelf: "Scaffale ricambi",
  spareHint:
    "I pezzi smontati restano qui — secondo set ruote o catena da allenamento. Rimontare sostituisce lo slot attivo.",
  reinstall: "Rimonta",
  spareEmpty: "Scaffale vuoto — smonta un pezzo per tenerlo qui.",
  removedOn: (date) => `Smontato ${date}`,
  installTitle: "Registra un pezzo",
  close: "Chiudi",
  slot: "Slot",
  makerModel: "Marca e modello",
  makerPlaceholder: "es. Maxxis Assegai",
  catalogSearch: "Cerca nel catalogo",
  catalogPlaceholder: "opzionale — associa un risultato",
  noHit: "Nessun risultato — salvalo senza catalogo.",
  catalogLinked: "Catalogo associato — compat solo se ci sono gli slot partner.",
  saveName: "Senza risultato teniamo il nome. La compat può arrivare dopo.",
  assignInstall: "Associa e monta",
  rememberWithout: "Salva senza catalogo",
  logged: "Registrato",
  setupVersionsTitle: "Versioni e confronto",
  setupVersionsHint:
    "Ogni modifica salva una nuova versione. Puoi tornare indietro quando vuoi.",
  setupNew: "Nuova versione",
  setupNewHint: "Dagli un nome che riconosci — es. « trail asciutto ».",
  setupNamePlaceholder: "Nome es. bikepark bagnato",
  setupSave: "Salva versione",
  setupSaved: "Versioni salvate",
  setupEmpty:
    "Nessuna versione — parti da un modello o salva le tue regolazioni.",
  setupVersion: (n) => `Versione ${n}`,
  setupTemplates: "Modelli di partenza",
  setupTemplatesHint: "Punto di partenza — non una reco personale.",
  setupTemplateApplied: (label) => `${label} (modello)`,
  compatHeading: "Compat",
};

const NL: GarageTabCopy = {
  active: "actief",
  activeAria: (name) => `Actieve fiets: ${name}`,
  use: "Gebruik",
  installedOn: (date, km) => `Geplaatst ${date} · ≈ ${km} km`,
  selfLogged: " · zelf ingevoerd",
  replace: "Vervangen",
  uninstall: "Demonteren",
  moveTo: "Naar fiets…",
  move: "Verplaatsen",
  spareShelf: "Reserveplank",
  spareHint:
    "Gedemonteerde delen blijven hier — tweede wielset of trainingsketting. Terugplaatsen vervangt de actieve slot.",
  reinstall: "Terugplaatsen",
  spareEmpty: "Plank leeg — demonter een deel om het hier te bewaren.",
  removedOn: (date) => `Gedemonteerd ${date}`,
  installTitle: "Onderdeel vastleggen",
  close: "Sluiten",
  slot: "Slot",
  makerModel: "Merk en model",
  makerPlaceholder: "bijv. Maxxis Assegai",
  catalogSearch: "Zoek in de catalogus",
  catalogPlaceholder: "optioneel — treffer koppelen",
  noHit: "Geen treffer — onthoud het zonder catalogus.",
  catalogLinked: "Catalogus gekoppeld — pasvorm alleen als partner-slots er zijn.",
  saveName: "Zonder treffer bewaren we de naam. Pasvorm kan later.",
  assignInstall: "Koppelen en plaatsen",
  rememberWithout: "Onthouden zonder catalogus",
  logged: "Vastgelegd",
  setupVersionsTitle: "Versies & vergelijken",
  setupVersionsHint:
    "Elke wijziging slaat een nieuwe versie op. Je kunt altijd terug.",
  setupNew: "Nieuwe versie",
  setupNewHint: "Geef een naam die je herkent — bijv. “trail droog”.",
  setupNamePlaceholder: "Naam bijv. bikepark nat",
  setupSave: "Versie opslaan",
  setupSaved: "Opgeslagen versies",
  setupEmpty:
    "Nog geen versie — start met een sjabloon of sla je instellingen op.",
  setupVersion: (n) => `Versie ${n}`,
  setupTemplates: "Sjablonen om te starten",
  setupTemplatesHint: "Startpunt — geen persoonlijk advies.",
  setupTemplateApplied: (label) => `${label} (sjabloon)`,
  compatHeading: "Pasvorm",
};

const BY_LANG: Record<ChromeLang, GarageTabCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function garageTabCopy(lang: ChromeLang = "de"): GarageTabCopy {
  return BY_LANG[lang];
}
