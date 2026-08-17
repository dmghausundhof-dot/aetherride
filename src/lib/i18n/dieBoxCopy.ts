import type { ChromeLang } from "./chromeLang";
import type { Bike, Ride } from "@/types";
import type {
  DieBoxPlan,
  DieBoxReadiness,
  DieBoxTodayItem,
} from "@/lib/garage/dieBox";
import { wheelLabel } from "@/lib/garage/dieBox";
import { lastRideForBike } from "@/lib/maintenance/summary";

/** Die Box chrome. Domain plan/sentence stay German; UI maps by id/label. */
export type DieBoxCopy = {
  ready: string;
  almost: string;
  unknown: string;
  nothingDueMonday: string;
  nothingDue: string;
  emptyHint: string;
  addMore: string;
  batteryHint: string;
  partLogged: string;
  cancel: string;
  done: string;
  pressureTitle: string;
  pressureHint: string;
  pressureFront: string;
  pressureRear: string;
  sagTitle: string;
  sagHint: string;
  sagFork: string;
  sagShock: string;
  travelTitle: string;
  travelHint: string;
  travelFront: string;
  travelRear: string;
  travelSave: string;
  setActiveTitle: string;
  setActiveHint: string;
  setActiveCta: string;
  lightsTitle: string;
  lightsHint: string;
  lightsCta: string;
  lockTitle: string;
  lockHint: string;
  lockCta: string;
  rackTitle: string;
  rackHint: string;
  rackCta: string;
  bagsTitle: string;
  bagsHint: string;
  bagsCta: string;
  pressureMissingTitle: string;
  pressureMissingHint: string;
  pressureMissingCta: string;
  tirePressureTitle: string;
  tirePressureHint: string;
  travelMissingTitle: string;
  travelMissingHint: string;
  travelMissingCta: string;
  sagMissingTitle: string;
  sagMissingHint: string;
  sagMissingCta: string;
  chainTitle: string;
  chainHint: string;
  chainCta: string;
  brakesTitle: string;
  brakesHint: string;
  brakesCta: string;
  chainDueTitle: string;
  chainDueHint: string;
  parkTrailTitle: string;
  parkTrailHint: string;
  parkTrailCta: string;
  chipLight: string;
  chipLock: string;
  chipRack: string;
  chipBags: string;
  chipTires: string;
  chipDropper: string;
  chipBrakes: string;
  chipParkTrail: string;
  chipTravel: string;
  chipCsc: string;
  chipSag: string;
  chipChain: string;
  chipPressure: string;
  chipCockpit: string;
  bitPressureLogged: string;
  bitBagsYes: string;
  bitChainYes: string;
  sentencePark: string;
  driveAssist: string;
  lastRideNoGps: string;
  lastRideKm: (km: string) => string;
  sentenceEverydayReady: (name: string) => string;
  sentenceHome: (name: string) => string;
  sentenceBits: (name: string, bits: string) => string;
  sentenceReadyBits: (name: string, bits: string) => string;
  sentenceMtb: (name: string, travel: string, drive: string) => string;
  sentenceMtbReady: (name: string, travel: string, drive: string) => string;
};

const DE: DieBoxCopy = {
  ready: "Bereit",
  almost: "Fast bereit",
  unknown: "Neu hier",
  nothingDueMonday: "Montag-bereit — Licht und Kette sitzen.",
  nothingDue: "Bereit — nichts liegt an.",
  emptyHint:
    "Noch nichts eingetragen. Name und Typ reichen — Teile nur, wenn sie wirklich dran sind.",
  addMore: "Weiteres eintragen",
  batteryHint:
    "Akkustand erscheint, sobald ein Sensor am Rad koppelt. Bis dahin keine Zahl.",
  partLogged: "eingetragen",
  cancel: "Abbrechen",
  done: "Erledigt",
  pressureTitle: "Druck merken",
  pressureHint: "Vorn und hinten am Ventil ablesen.",
  pressureFront: "Vorn",
  pressureRear: "Hinten",
  sagTitle: "Federung merken",
  sagHint:
    "Prozent an Gabel und Dämpfer. SAG ist, wie weit die Federung mit dir einsinkt.",
  sagFork: "Gabel SAG %",
  sagShock: "Dämpfer SAG %",
  travelTitle: "Federweg eintragen",
  travelHint: "Nur der Federweg, der am Rad steht.",
  travelFront: "Vorn mm",
  travelRear: "Hinten mm",
  travelSave: "Eintragen",
  setActiveTitle: "Dieses Rad nach vorn",
  setActiveHint: "Eines steht in der Box — Umschalten holt es nach vorn.",
  setActiveCta: "Als aktiv setzen",
  lightsTitle: "Licht eintragen",
  lightsHint: "Nur wenn Licht wirklich am Rad ist.",
  lightsCta: "Licht eintragen",
  lockTitle: "Schloss eintragen",
  lockHint: "Nur wenn ein Schloss am Rad ist.",
  lockCta: "Schloss eintragen",
  rackTitle: "Träger eintragen",
  rackHint: "Nur wenn das Rad einen Gepäckträger hat.",
  rackCta: "Träger eintragen",
  bagsTitle: "Taschen eintragen",
  bagsHint: "Nur wenn Taschen am Rad sind.",
  bagsCta: "Taschen eintragen",
  pressureMissingTitle: "Druck merken",
  pressureMissingHint: "Vorn und hinten am Ventil ablesen.",
  pressureMissingCta: "Druck merken",
  tirePressureTitle: "Reifendruck merken",
  tirePressureHint: "Vorn und hinten am Ventil ablesen.",
  travelMissingTitle: "Federweg eintragen",
  travelMissingHint: "Nur der Federweg, der am Rad steht.",
  travelMissingCta: "Federweg eintragen",
  sagMissingTitle: "Federung merken",
  sagMissingHint: "Eine Zahl an Gabel und Dämpfer, abgelesen am Rad.",
  sagMissingCta: "Federung merken",
  chainTitle: "Kette merken",
  chainHint: "Mit der Lehre messen, dann hier merken.",
  chainCta: "Kette gemessen",
  brakesTitle: "Bremsen eintragen",
  brakesHint: "Nur wenn Beläge am Rad sind.",
  brakesCta: "Bremse eintragen",
  chainDueTitle: "Kette mit der Lehre prüfen",
  chainDueHint: "Anschauen und mit der Lehre messen.",
  parkTrailTitle: "Park oder Trail",
  parkTrailHint: "Beide Setups sind da — wechseln, wenn du willst.",
  parkTrailCta: "Wechseln",
  chipLight: "Licht",
  chipLock: "Schloss",
  chipRack: "Träger",
  chipBags: "Taschen",
  chipTires: "Reifen",
  chipDropper: "Vario",
  chipBrakes: "Bremsen",
  chipParkTrail: "Park | Trail",
  chipTravel: "Federweg",
  chipCsc: "CSC",
  chipSag: "SAG",
  chipChain: "Kette",
  chipPressure: "Druck",
  chipCockpit: "Cockpit",
  bitPressureLogged: "Druck gemerkt",
  bitBagsYes: "Taschen da",
  bitChainYes: "Kette gemessen",
  sentencePark: "Park-Setup",
  driveAssist: " · E-Antrieb",
  lastRideNoGps: "Zuletzt unterwegs — ohne GPS-Strecke",
  lastRideKm: (km) => `Zuletzt ${km} km`,
  sentenceEverydayReady: (name) => `${name} wohnt hier · Montag-bereit`,
  sentenceHome: (name) => `${name} wohnt hier`,
  sentenceBits: (name, bits) => `${name} · ${bits}`,
  sentenceReadyBits: (name, bits) => `${name} · ${bits} · bereit`,
  sentenceMtb: (name, travel, drive) => `${name} · ${travel}${drive}`,
  sentenceMtbReady: (name, travel, drive) =>
    `${name} · ${travel}${drive} · bereit`,
};

const EN: DieBoxCopy = {
  ready: "Ready",
  almost: "Almost ready",
  unknown: "Just arrived",
  nothingDueMonday: "Monday-ready — lights and chain are set.",
  nothingDue: "Ready — nothing waiting.",
  emptyHint:
    "Nothing logged yet. Name and type are enough — parts only if they’re really on the bike.",
  addMore: "Log more",
  batteryHint:
    "Charge appears once a sensor on the bike pairs. No number until then.",
  partLogged: "logged",
  cancel: "Cancel",
  done: "Done",
  pressureTitle: "Log pressure",
  pressureHint: "Read front and rear at the valve.",
  pressureFront: "Front",
  pressureRear: "Rear",
  sagTitle: "Log suspension",
  sagHint:
    "Percent on fork and shock. SAG is how far the suspension sinks with you on it.",
  sagFork: "Fork SAG %",
  sagShock: "Shock SAG %",
  travelTitle: "Log travel",
  travelHint: "Only the travel that’s on the bike.",
  travelFront: "Front mm",
  travelRear: "Rear mm",
  travelSave: "Log it",
  setActiveTitle: "Bring this bike forward",
  setActiveHint: "One bike stands in the stall — switching brings it forward.",
  setActiveCta: "Set as active",
  lightsTitle: "Log lights",
  lightsHint: "Only if lights are really on the bike.",
  lightsCta: "Log lights",
  lockTitle: "Log lock",
  lockHint: "Only if a lock is on the bike.",
  lockCta: "Log lock",
  rackTitle: "Log rack",
  rackHint: "Only if the bike has a rack.",
  rackCta: "Log rack",
  bagsTitle: "Log bags",
  bagsHint: "Only if bags are on the bike.",
  bagsCta: "Log bags",
  pressureMissingTitle: "Log pressure",
  pressureMissingHint: "Read front and rear at the valve.",
  pressureMissingCta: "Log pressure",
  tirePressureTitle: "Log tire pressure",
  tirePressureHint: "Read front and rear at the valve.",
  travelMissingTitle: "Log travel",
  travelMissingHint: "Only the travel that’s on the bike.",
  travelMissingCta: "Log travel",
  sagMissingTitle: "Log suspension",
  sagMissingHint: "One number on fork and shock, read on the bike.",
  sagMissingCta: "Log suspension",
  chainTitle: "Log the chain",
  chainHint: "Measure with a gauge, then log it here.",
  chainCta: "Chain measured",
  brakesTitle: "Log brakes",
  brakesHint: "Only if pads are on the bike.",
  brakesCta: "Log brake",
  chainDueTitle: "Check the chain with a gauge",
  chainDueHint: "Look, then measure with a gauge.",
  parkTrailTitle: "Park or trail",
  parkTrailHint: "Both setups are here — switch if you want.",
  parkTrailCta: "Switch",
  chipLight: "Lights",
  chipLock: "Lock",
  chipRack: "Rack",
  chipBags: "Bags",
  chipTires: "Tires",
  chipDropper: "Dropper",
  chipBrakes: "Brakes",
  chipParkTrail: "Park | Trail",
  chipTravel: "Travel",
  chipCsc: "CSC",
  chipSag: "SAG",
  chipChain: "Chain",
  chipPressure: "Pressure",
  chipCockpit: "Cockpit",
  bitPressureLogged: "Pressure logged",
  bitBagsYes: "Bags on",
  bitChainYes: "Chain measured",
  sentencePark: "Park setup",
  driveAssist: " · e-assist",
  lastRideNoGps: "Last out — no GPS track",
  lastRideKm: (km) => `Last ${km} km`,
  sentenceEverydayReady: (name) => `${name} lives here · Monday-ready`,
  sentenceHome: (name) => `${name} lives here`,
  sentenceBits: (name, bits) => `${name} · ${bits}`,
  sentenceReadyBits: (name, bits) => `${name} · ${bits} · ready`,
  sentenceMtb: (name, travel, drive) => `${name} · ${travel}${drive}`,
  sentenceMtbReady: (name, travel, drive) =>
    `${name} · ${travel}${drive} · ready`,
};

const FR: DieBoxCopy = {
  ready: "Prêt",
  almost: "Presque prêt",
  unknown: "Tout juste arrivé",
  nothingDueMonday: "Prêt pour lundi — éclairage et chaîne sont là.",
  nothingDue: "Prêt — rien n’attend.",
  emptyHint:
    "Rien d’inscrit. Nom et type suffisent — des pièces seulement si elles sont vraiment sur le vélo.",
  addMore: "Inscrire autre chose",
  batteryHint:
    "La charge apparaît dès qu’un capteur sur le vélo est couplé. Pas de chiffre avant.",
  partLogged: "inscrit",
  cancel: "Annuler",
  done: "Fait",
  pressureTitle: "Noter la pression",
  pressureHint: "Lis avant et arrière à la valve.",
  pressureFront: "Avant",
  pressureRear: "Arrière",
  sagTitle: "Noter la suspension",
  sagHint:
    "Pourcent sur fourche et amortisseur. Le SAG, c’est l’enfoncement avec toi dessus.",
  sagFork: "SAG fourche %",
  sagShock: "SAG amortisseur %",
  travelTitle: "Inscrire le débattement",
  travelHint: "Seulement le débattement inscrit sur le vélo.",
  travelFront: "Avant mm",
  travelRear: "Arrière mm",
  travelSave: "Inscrire",
  setActiveTitle: "Mettre ce vélo devant",
  setActiveHint: "Un vélo tient dans le box — changer le met devant.",
  setActiveCta: "Mettre en actif",
  lightsTitle: "Inscrire l’éclairage",
  lightsHint: "Seulement si l’éclairage est vraiment sur le vélo.",
  lightsCta: "Inscrire l'éclairage",
  lockTitle: "Inscrire l’antivol",
  lockHint: "Seulement s’il y a un antivol sur le vélo.",
  lockCta: "Inscrire l'antivol",
  rackTitle: "Inscrire le porte-bagages",
  rackHint: "Seulement si le vélo en a un.",
  rackCta: "Inscrire le porte-bagages",
  bagsTitle: "Inscrire les sacoches",
  bagsHint: "Seulement si des sacoches sont sur le vélo.",
  bagsCta: "Inscrire les sacoches",
  pressureMissingTitle: "Noter la pression",
  pressureMissingHint: "Lis avant et arrière à la valve.",
  pressureMissingCta: "Noter la pression",
  tirePressureTitle: "Noter la pression des pneus",
  tirePressureHint: "Lis avant et arrière à la valve.",
  travelMissingTitle: "Inscrire le débattement",
  travelMissingHint: "Seulement le débattement inscrit sur le vélo.",
  travelMissingCta: "Inscrire le débattement",
  sagMissingTitle: "Noter la suspension",
  sagMissingHint: "Un chiffre sur fourche et amortisseur, lu sur le vélo.",
  sagMissingCta: "Noter la suspension",
  chainTitle: "Noter la chaîne",
  chainHint: "Mesure au calibre, puis note ici.",
  chainCta: "Chaîne mesurée",
  brakesTitle: "Inscrire les freins",
  brakesHint: "Seulement si les plaquettes sont sur le vélo.",
  brakesCta: "Inscrire le frein",
  chainDueTitle: "Contrôler la chaîne avec la jauge",
  chainDueHint: "Regarde, puis mesure au calibre.",
  parkTrailTitle: "Park ou trail",
  parkTrailHint: "Les deux setups sont là — change si tu veux.",
  parkTrailCta: "Changer",
  chipLight: "Éclairage",
  chipLock: "Antivol",
  chipRack: "Porte-bagages",
  chipBags: "Sacoches",
  chipTires: "Pneus",
  chipDropper: "Télesco",
  chipBrakes: "Freins",
  chipParkTrail: "Park | Trail",
  chipTravel: "Débattement",
  chipCsc: "CSC",
  chipSag: "SAG",
  chipChain: "Chaîne",
  chipPressure: "Pression",
  chipCockpit: "Cockpit",
  bitPressureLogged: "Pression notée",
  bitBagsYes: "Sacoches là",
  bitChainYes: "Chaîne mesurée",
  sentencePark: "Setup park",
  driveAssist: " · e-assist",
  lastRideNoGps: "Dernière sortie — sans trace GPS",
  lastRideKm: (km) => `Dernière ${km} km`,
  sentenceEverydayReady: (name) => `${name} habite ici · prêt pour lundi`,
  sentenceHome: (name) => `${name} habite ici`,
  sentenceBits: (name, bits) => `${name} · ${bits}`,
  sentenceReadyBits: (name, bits) => `${name} · ${bits} · prêt`,
  sentenceMtb: (name, travel, drive) => `${name} · ${travel}${drive}`,
  sentenceMtbReady: (name, travel, drive) =>
    `${name} · ${travel}${drive} · prêt`,
};

const IT: DieBoxCopy = {
  ready: "Pronto",
  almost: "Quasi pronto",
  unknown: "Appena arrivato",
  nothingDueMonday: "Pronto per lunedì — luci e catena a posto.",
  nothingDue: "Pronto — niente in attesa.",
  emptyHint:
    "Niente iscritto. Nome e tipo bastano — parti solo se sono davvero sulla bici.",
  addMore: "Iscrivi altro",
  batteryHint:
    "La carica compare quando un sensore sulla bici si accoppia. Nessun numero prima.",
  partLogged: "iscritto",
  cancel: "Annulla",
  done: "Fatto",
  pressureTitle: "Segna la pressione",
  pressureHint: "Leggi anteriore e posteriore alla valvola.",
  pressureFront: "Anteriore",
  pressureRear: "Posteriore",
  sagTitle: "Segna la sospensione",
  sagHint:
    "Percentuale su forcella e ammortizzatore. Il SAG è quanto affonda con te sopra.",
  sagFork: "SAG forcella %",
  sagShock: "SAG ammortizzatore %",
  travelTitle: "Iscrivi l'escursione",
  travelHint: "Solo l’escursione scritta sulla bici.",
  travelFront: "Anteriore mm",
  travelRear: "Posteriore mm",
  travelSave: "Iscrivi",
  setActiveTitle: "Porta avanti questa bici",
  setActiveHint: "Una bici sta nel box — cambiare la porta avanti.",
  setActiveCta: "Imposta come attiva",
  lightsTitle: "Iscrivi le luci",
  lightsHint: "Solo se le luci sono davvero sulla bici.",
  lightsCta: "Iscrivi luci",
  lockTitle: "Iscrivi il lucchetto",
  lockHint: "Solo se c’è un lucchetto sulla bici.",
  lockCta: "Iscrivi lucchetto",
  rackTitle: "Iscrivi il portapacchi",
  rackHint: "Solo se la bici ce l’ha.",
  rackCta: "Iscrivi portapacchi",
  bagsTitle: "Iscrivi le borse",
  bagsHint: "Solo se le borse sono sulla bici.",
  bagsCta: "Iscrivi borse",
  pressureMissingTitle: "Segna la pressione",
  pressureMissingHint: "Leggi anteriore e posteriore alla valvola.",
  pressureMissingCta: "Segna la pressione",
  tirePressureTitle: "Segna la pressione gomme",
  tirePressureHint: "Leggi anteriore e posteriore alla valvola.",
  travelMissingTitle: "Iscrivi l’escursione",
  travelMissingHint: "Solo l’escursione scritta sulla bici.",
  travelMissingCta: "Iscrivi l'escursione",
  sagMissingTitle: "Segna la sospensione",
  sagMissingHint:
    "Un numero su forcella e ammortizzatore, letto sulla bici.",
  sagMissingCta: "Segna la sospensione",
  chainTitle: "Segna la catena",
  chainHint: "Misura col calibro, poi segna qui.",
  chainCta: "Catena misurata",
  brakesTitle: "Iscrivi i freni",
  brakesHint: "Solo se le pastiglie sono sulla bici.",
  brakesCta: "Iscrivi freno",
  chainDueTitle: "Controlla la catena col calibro",
  chainDueHint: "Guarda, poi misura col calibro.",
  parkTrailTitle: "Park o trail",
  parkTrailHint: "Entrambi i setup ci sono — cambia se vuoi.",
  parkTrailCta: "Cambia",
  chipLight: "Luci",
  chipLock: "Lucchetto",
  chipRack: "Portapacchi",
  chipBags: "Borse",
  chipTires: "Gomme",
  chipDropper: "Telescopica",
  chipBrakes: "Freni",
  chipParkTrail: "Park | Trail",
  chipTravel: "Escursione",
  chipCsc: "CSC",
  chipSag: "SAG",
  chipChain: "Catena",
  chipPressure: "Pressione",
  chipCockpit: "Cockpit",
  bitPressureLogged: "Pressione segnata",
  bitBagsYes: "Borse ci sono",
  bitChainYes: "Catena misurata",
  sentencePark: "Setup park",
  driveAssist: " · e-assist",
  lastRideNoGps: "Ultima uscita — senza traccia GPS",
  lastRideKm: (km) => `Ultimi ${km} km`,
  sentenceEverydayReady: (name) => `${name} vive qui · pronto per lunedì`,
  sentenceHome: (name) => `${name} vive qui`,
  sentenceBits: (name, bits) => `${name} · ${bits}`,
  sentenceReadyBits: (name, bits) => `${name} · ${bits} · pronto`,
  sentenceMtb: (name, travel, drive) => `${name} · ${travel}${drive}`,
  sentenceMtbReady: (name, travel, drive) =>
    `${name} · ${travel}${drive} · pronto`,
};

const NL: DieBoxCopy = {
  ready: "Klaar",
  almost: "Bijna klaar",
  unknown: "Nieuw hier",
  nothingDueMonday: "Maandag-klaar — licht en ketting zitten.",
  nothingDue: "Klaar — niets te doen.",
  emptyHint:
    "Nog niets ingevuld. Naam en type volstaan — onderdelen alleen als ze echt op de fiets zitten.",
  addMore: "Meer invullen",
  batteryHint:
    "Accustand verschijnt zodra een sensor op de fiets koppelt. Tot dan geen getal.",
  partLogged: "ingevuld",
  cancel: "Annuleren",
  done: "Gedaan",
  pressureTitle: "Druk noteren",
  pressureHint: "Voor en achter bij het ventiel aflezen.",
  pressureFront: "Voor",
  pressureRear: "Achter",
  sagTitle: "Vering noteren",
  sagHint:
    "Procent op vork en demper. SAG is hoe ver de vering inzakt met jou erop.",
  sagFork: "Vork SAG %",
  sagShock: "Demper SAG %",
  travelTitle: "Veerweg invullen",
  travelHint: "Alleen de veerweg die op de fiets staat.",
  travelFront: "Voor mm",
  travelRear: "Achter mm",
  travelSave: "Invullen",
  setActiveTitle: "Deze fiets naar voren",
  setActiveHint: "Eén fiets staat in de box — wisselen haalt hem naar voren.",
  setActiveCta: "Als actief zetten",
  lightsTitle: "Licht invullen",
  lightsHint: "Alleen als licht echt op de fiets zit.",
  lightsCta: "Licht invullen",
  lockTitle: "Slot invullen",
  lockHint: "Alleen als er een slot op de fiets zit.",
  lockCta: "Slot invullen",
  rackTitle: "Rek invullen",
  rackHint: "Alleen als de fiets een bagagerek heeft.",
  rackCta: "Rek invullen",
  bagsTitle: "Tassen invullen",
  bagsHint: "Alleen als er tassen op de fiets zitten.",
  bagsCta: "Tassen invullen",
  pressureMissingTitle: "Druk noteren",
  pressureMissingHint: "Voor en achter bij het ventiel aflezen.",
  pressureMissingCta: "Druk noteren",
  tirePressureTitle: "Bandendruk noteren",
  tirePressureHint: "Voor en achter bij het ventiel aflezen.",
  travelMissingTitle: "Veerweg invullen",
  travelMissingHint: "Alleen de veerweg die op de fiets staat.",
  travelMissingCta: "Veerweg invullen",
  sagMissingTitle: "Vering noteren",
  sagMissingHint: "Eén getal op vork en demper, afgelezen op de fiets.",
  sagMissingCta: "Vering noteren",
  chainTitle: "Ketting noteren",
  chainHint: "Met de meter meten, dan hier noteren.",
  chainCta: "Ketting gemeten",
  brakesTitle: "Remmen invullen",
  brakesHint: "Alleen als er blokken op de fiets zitten.",
  brakesCta: "Rem invullen",
  chainDueTitle: "Ketting met de meter checken",
  chainDueHint: "Kijken en met de meter meten.",
  parkTrailTitle: "Park of trail",
  parkTrailHint: "Beide setups zijn er — wissel als je wilt.",
  parkTrailCta: "Wisselen",
  chipLight: "Licht",
  chipLock: "Slot",
  chipRack: "Rek",
  chipBags: "Tassen",
  chipTires: "Banden",
  chipDropper: "Dropper",
  chipBrakes: "Remmen",
  chipParkTrail: "Park | Trail",
  chipTravel: "Veerweg",
  chipCsc: "CSC",
  chipSag: "SAG",
  chipChain: "Ketting",
  chipPressure: "Druk",
  chipCockpit: "Cockpit",
  bitPressureLogged: "Druk genoteerd",
  bitBagsYes: "Tassen erop",
  bitChainYes: "Ketting gemeten",
  sentencePark: "Park-setup",
  driveAssist: " · e-assist",
  lastRideNoGps: "Laatst onderweg — zonder GPS-track",
  lastRideKm: (km) => `Laatst ${km} km`,
  sentenceEverydayReady: (name) => `${name} woont hier · maandag-klaar`,
  sentenceHome: (name) => `${name} woont hier`,
  sentenceBits: (name, bits) => `${name} · ${bits}`,
  sentenceReadyBits: (name, bits) => `${name} · ${bits} · klaar`,
  sentenceMtb: (name, travel, drive) => `${name} · ${travel}${drive}`,
  sentenceMtbReady: (name, travel, drive) =>
    `${name} · ${travel}${drive} · klaar`,
};

const BY_LANG: Record<ChromeLang, DieBoxCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

const MAINT: Record<ChromeLang, Record<string, string>> = {
  de: {
    "Gabel Lower-Leg Service": "Gabel Lower-Leg Service",
    "Gabel Vollservice (Feder/Dämpfer)": "Gabel Vollservice (Feder/Dämpfer)",
    "Dämpfer Air-Can Service": "Dämpfer Air-Can Service",
    "Dämpfer Vollservice": "Dämpfer Vollservice",
    "Kettenverschleiß prüfen": "Kettenverschleiß prüfen",
    "Kassette prüfen (nach 2–3 Ketten)": "Kassette prüfen (nach 2–3 Ketten)",
    "Bremsbeläge vorne prüfen": "Bremsbeläge vorne prüfen",
    "Bremsbeläge hinten prüfen": "Bremsbeläge hinten prüfen",
    "Tubeless-Milch erneuern": "Tubeless-Milch erneuern",
    "Dropper Lower-Post Service": "Dropper Lower-Post Service",
  },
  en: {
    "Gabel Lower-Leg Service": "Fork lower-leg service",
    "Gabel Vollservice (Feder/Dämpfer)": "Fork full service (spring/damper)",
    "Dämpfer Air-Can Service": "Shock air-can service",
    "Dämpfer Vollservice": "Shock full service",
    "Kettenverschleiß prüfen": "Check chain wear",
    "Kassette prüfen (nach 2–3 Ketten)": "Check cassette (after 2–3 chains)",
    "Bremsbeläge vorne prüfen": "Check front brake pads",
    "Bremsbeläge hinten prüfen": "Check rear brake pads",
    "Tubeless-Milch erneuern": "Refresh tubeless sealant",
    "Dropper Lower-Post Service": "Dropper lower-post service",
  },
  fr: {
    "Gabel Lower-Leg Service": "Service lower-leg fourche",
    "Gabel Vollservice (Feder/Dämpfer)":
      "Révision complète fourche (ressort/amortisseur)",
    "Dämpfer Air-Can Service": "Service air-can amortisseur",
    "Dämpfer Vollservice": "Révision complète amortisseur",
    "Kettenverschleiß prüfen": "Contrôle usure chaîne",
    "Kassette prüfen (nach 2–3 Ketten)":
      "Contrôle cassette (après 2–3 chaînes)",
    "Bremsbeläge vorne prüfen": "Contrôle plaquettes avant",
    "Bremsbeläge hinten prüfen": "Contrôle plaquettes arrière",
    "Tubeless-Milch erneuern": "Renouveler le lait tubeless",
    "Dropper Lower-Post Service": "Service lower-post dropper",
  },
  it: {
    "Gabel Lower-Leg Service": "Service lower-leg forcella",
    "Gabel Vollservice (Feder/Dämpfer)":
      "Revisione completa forcella (molla/ammortizzatore)",
    "Dämpfer Air-Can Service": "Service air-can ammortizzatore",
    "Dämpfer Vollservice": "Revisione completa ammortizzatore",
    "Kettenverschleiß prüfen": "Controlla usura catena",
    "Kassette prüfen (nach 2–3 Ketten)":
      "Controlla cassetta (dopo 2–3 catene)",
    "Bremsbeläge vorne prüfen": "Controlla pastiglie anteriori",
    "Bremsbeläge hinten prüfen": "Controlla pastiglie posteriori",
    "Tubeless-Milch erneuern": "Rinnova latte tubeless",
    "Dropper Lower-Post Service": "Service lower-post dropper",
  },
  nl: {
    "Gabel Lower-Leg Service": "Voorvork lower-leg service",
    "Gabel Vollservice (Feder/Dämpfer)":
      "Voorvork volledige service (veer/demper)",
    "Dämpfer Air-Can Service": "Demper air-can service",
    "Dämpfer Vollservice": "Demper volledige service",
    "Kettenverschleiß prüfen": "Check kettingslijtage",
    "Kassette prüfen (nach 2–3 Ketten)":
      "Check cassette (na 2–3 kettingen)",
    "Bremsbeläge vorne prüfen": "Check voorremblokken",
    "Bremsbeläge hinten prüfen": "Check achterremblokken",
    "Tubeless-Milch erneuern": "Tubeless-melk vernieuwen",
    "Dropper Lower-Post Service": "Dropper lower-post service",
  },
};

const DAYS: Record<ChromeLang, (n: string) => string> = {
  de: (n) => `${n} Tage`,
  en: (n) => `${n} days`,
  fr: (n) => `${n} jours`,
  it: (n) => `${n} giorni`,
  nl: (n) => `${n} dagen`,
};

export function dieBoxCopy(lang: ChromeLang = "de"): DieBoxCopy {
  return BY_LANG[lang];
}

export function dieBoxReadinessUi(
  r: DieBoxReadiness,
  lang: ChromeLang
): string {
  const c = dieBoxCopy(lang);
  if (r === "ready") return c.ready;
  if (r === "almost") return c.almost;
  return c.unknown;
}

export function dieBoxChipLabel(label: string, lang: ChromeLang): string {
  const c = dieBoxCopy(lang);
  switch (label) {
    case "Licht":
      return c.chipLight;
    case "Schloss":
      return c.chipLock;
    case "Träger":
      return c.chipRack;
    case "Taschen":
      return c.chipBags;
    case "Reifen":
      return c.chipTires;
    case "Vario":
      return c.chipDropper;
    case "Bremsen":
      return c.chipBrakes;
    case "Park | Trail":
      return c.chipParkTrail;
    case "Federweg":
      return c.chipTravel;
    case "CSC":
      return c.chipCsc;
    case "SAG":
      return c.chipSag;
    case "Kette":
      return c.chipChain;
    case "Druck":
      return c.chipPressure;
    case "Cockpit":
      return c.chipCockpit;
    default:
      return label;
  }
}

function maintIntervalLabel(de: string, lang: ChromeLang): string {
  return MAINT[lang][de] ?? de;
}

function maintRemaining(raw: string | undefined, lang: ChromeLang): string {
  if (!raw) return "";
  if (raw === "Kein Intervall") {
    return lang === "en"
      ? "No interval"
      : lang === "fr"
        ? "Pas d’intervalle"
        : lang === "it"
          ? "Nessun intervallo"
          : lang === "nl"
            ? "Geen interval"
            : raw;
  }
  return raw
    .split(" · ")
    .map((part) => {
      const m = /^(\d+)\s+Tage$/.exec(part.trim());
      return m ? DAYS[lang](m[1]!) : part.trim();
    })
    .join(" · ");
}

export function localizeDieBoxItem(
  item: DieBoxTodayItem,
  lang: ChromeLang
): DieBoxTodayItem {
  const c = dieBoxCopy(lang);
  switch (item.id) {
    case "setActive":
      return {
        ...item,
        title: c.setActiveTitle,
        hint: c.setActiveHint,
        cta: c.setActiveCta,
      };
    case "lightsMissing":
      return {
        ...item,
        title: c.lightsTitle,
        hint: c.lightsHint,
        cta: c.lightsCta,
      };
    case "lockMissing":
      return { ...item, title: c.lockTitle, hint: c.lockHint, cta: c.lockCta };
    case "rackMissing":
      return { ...item, title: c.rackTitle, hint: c.rackHint, cta: c.rackCta };
    case "bagsMissing":
      return { ...item, title: c.bagsTitle, hint: c.bagsHint, cta: c.bagsCta };
    case "pressureUnknown": {
      const tire = item.title.startsWith("Reifendruck");
      return {
        ...item,
        title: tire ? c.tirePressureTitle : c.pressureMissingTitle,
        hint: tire ? c.tirePressureHint : c.pressureMissingHint,
        cta: c.pressureMissingCta,
      };
    }
    case "travelUnknown":
      return {
        ...item,
        title: c.travelMissingTitle,
        hint: c.travelMissingHint,
        cta: c.travelMissingCta,
      };
    case "sagUnknown":
      return {
        ...item,
        title: c.sagMissingTitle,
        hint: c.sagMissingHint,
        cta: c.sagMissingCta,
      };
    case "chainTeach":
      return {
        ...item,
        title: c.chainTitle,
        hint: c.chainHint,
        cta: c.chainCta,
      };
    case "brakesUnknown":
      return {
        ...item,
        title: c.brakesTitle,
        hint: c.brakesHint,
        cta: c.brakesCta,
      };
    case "dueCare": {
      const chain = item.slot === "chain";
      return {
        ...item,
        title: chain ? c.chainDueTitle : maintIntervalLabel(item.title, lang),
        hint: chain ? c.chainDueHint : maintRemaining(item.hint, lang),
        cta: c.done,
      };
    }
    case "parkTrail":
      return {
        ...item,
        title: c.parkTrailTitle,
        hint: c.parkTrailHint,
        cta: c.parkTrailCta,
      };
    default:
      return item;
  }
}

export function dieBoxSentenceUi(
  plan: DieBoxPlan,
  bike: Bike,
  lang: ChromeLang
): string {
  const c = dieBoxCopy(lang);
  const chips = new Map(plan.chips.map((ch) => [ch.label, ch.known]));
  const known = (label: string) => chips.get(label) === true;
  const kind = plan.kind;

  if (kind === "urban") {
    return plan.readiness === "ready"
      ? c.sentenceEverydayReady(bike.name)
      : c.sentenceHome(bike.name);
  }
  if (kind === "gravel") {
    const bits = [
      wheelLabel(bike),
      known("Druck") ? c.bitPressureLogged : null,
      known("Taschen") ? c.bitBagsYes : null,
    ].filter((x): x is string => Boolean(x));
    if (bits.length === 0) {
      return plan.readiness === "ready"
        ? c.sentenceEverydayReady(bike.name)
        : c.sentenceHome(bike.name);
    }
    const joined = bits.join(" · ");
    return plan.readiness === "ready"
      ? c.sentenceReadyBits(bike.name, joined)
      : c.sentenceBits(bike.name, joined);
  }
  if (kind === "road") {
    const bits = [
      wheelLabel(bike),
      known("Kette") ? c.bitChainYes : null,
      known("Druck") ? c.bitPressureLogged : null,
    ].filter((x): x is string => Boolean(x));
    if (bits.length === 0) return c.sentenceHome(bike.name);
    const joined = bits.join(" · ");
    return plan.readiness === "ready"
      ? c.sentenceReadyBits(bike.name, joined)
      : c.sentenceBits(bike.name, joined);
  }
  if (kind === "mtb") {
    if (plan.showParkTrail && plan.parkSetup?.isCurrent) {
      return c.sentencePark;
    }
    if ((bike.travelFrontMm ?? 0) === 0 && (bike.travelRearMm ?? 0) === 0) {
      return c.sentenceHome(bike.name);
    }
    const travel = `${bike.travelFrontMm ?? "–"}/${bike.travelRearMm ?? "–"}`;
    const drive = plan.hasElectricAssist ? c.driveAssist : "";
    return plan.readiness === "ready"
      ? c.sentenceMtbReady(bike.name, travel, drive)
      : c.sentenceMtb(bike.name, travel, drive);
  }
  return c.sentenceHome(bike.name);
}

export function lastRideHeroUi(
  ride: Ride | undefined,
  lang: ChromeLang
): string | null {
  if (!ride) return null;
  const km = ride.distanceM / 1000;
  const c = dieBoxCopy(lang);
  if (Number.isFinite(km) && km >= 0.05) return c.lastRideKm(km.toFixed(1));
  return c.lastRideNoGps;
}

export function lastRideHeroUiForBike(
  rides: Ride[],
  bikeId: string,
  lang: ChromeLang
): string | null {
  const ended = rides.filter((r) => Boolean(r.endTime));
  return lastRideHeroUi(lastRideForBike(ended, bikeId), lang);
}

export function dieBoxMeasureSpec(
  kind: "pressure" | "sag" | "travel",
  lang: ChromeLang,
  pressureUnit?: string
): { title: string; hint: string; front: string; rear: string; save: string } {
  const c = dieBoxCopy(lang);
  if (kind === "pressure") {
    const unit = pressureUnit ? ` (${pressureUnit})` : "";
    return {
      title: c.pressureTitle,
      hint: c.pressureHint,
      front: `${c.pressureFront}${unit}`,
      rear: `${c.pressureRear}${unit}`,
      save: c.pressureMissingCta,
    };
  }
  if (kind === "sag") {
    return {
      title: c.sagTitle,
      hint: c.sagHint,
      front: c.sagFork,
      rear: c.sagShock,
      save: c.sagMissingCta,
    };
  }
  return {
    title: c.travelTitle,
    hint: c.travelHint,
    front: c.travelFront,
    rear: c.travelRear,
    save: c.travelSave,
  };
}
