import type { ChromeLang } from "./chromeLang";

export type BikeIdentityCopy = {
  title: string;
  hint: string;
  empty: string;
  add: string;
  edit: string;
  save: string;
  serial: string;
  serialHint: string;
  serialCopied: string;
  color: string;
  weight: string;
  notes: string;
  purchasedAt: string;
  purchasedFrom: string;
  price: string;
  insurance: string;
  policy: string;
  keyNumber: string;
  privateHint: string;
  year: string;
  name: string;
  frameSize: string;
  wheels: string;
  travel: string;
  hours: string;
  headAngle: string;
  chainstay: string;
  wheelbase: string;
  geoSetting: string;
  techDetails: string;
  techHint: string;
  photoUrl: string;
  photoUrlHint: string;
};

const DE: BikeIdentityCopy = {
  title: "Ausweis",
  hint: "Rahmennummer, Kauf und Versicherung — nur auf dem Gerät.",
  empty: "Rahmennummer hinterlegen — für Diebstahl und Versicherung.",
  add: "Ausweis anlegen",
  edit: "Rad bearbeiten",
  save: "Speichern",
  serial: "Rahmennummer",
  serialHint: "Steht am Tretlager, Steuerrohr oder der Kettenstrebe.",
  serialCopied: "Rahmennummer kopiert",
  color: "Farbe",
  weight: "Gewicht (kg)",
  notes: "Notizen",
  purchasedAt: "Gekauft am",
  purchasedFrom: "Gekauft bei",
  price: "Kaufpreis (€)",
  insurance: "Versicherung",
  policy: "Schein / Police",
  keyNumber: "Schlüsselnummer",
  privateHint: "Bleibt lokal und in deiner Sicherung. Nicht öffentlich.",
  year: "Jahr",
  name: "Name",
  frameSize: "Rahmengröße",
  wheels: "Laufrad",
  travel: "Federweg",
  hours: "Stunden",
  headAngle: "Lenkwinkel",
  chainstay: "Kettenstrebe",
  wheelbase: "Radstand",
  geoSetting: "Geo-Setting",
  techDetails: "Technische Details",
  techHint: "Federweg, Rahmen…",
  photoUrl: "Foto-Link",
  photoUrlHint: "Nur wenn du eine Bild-URL hast. Kamera sitzt am Stand.",
};

const EN: BikeIdentityCopy = {
  title: "ID card",
  hint: "Frame number, purchase and insurance — on this device only.",
  empty: "Add the frame number — for theft and insurance.",
  add: "Add ID card",
  edit: "Edit bike",
  save: "Save",
  serial: "Frame number",
  serialHint: "Stamped at the bottom bracket, head tube or chainstay.",
  serialCopied: "Frame number copied",
  color: "Color",
  weight: "Weight (kg)",
  notes: "Notes",
  purchasedAt: "Bought on",
  purchasedFrom: "Bought at",
  price: "Price (€)",
  insurance: "Insurance",
  policy: "Policy number",
  keyNumber: "Key number",
  privateHint: "Stays local and in your backup. Not public.",
  year: "Year",
  name: "Name",
  frameSize: "Frame size",
  wheels: "Wheels",
  travel: "Travel",
  hours: "Hours",
  headAngle: "Head angle",
  chainstay: "Chainstay",
  wheelbase: "Wheelbase",
  geoSetting: "Geo setting",
  techDetails: "Technical details",
  techHint: "Travel, frame…",
  photoUrl: "Photo URL",
  photoUrlHint: "Only if you have an image URL. The camera sits on the stand.",
};

const FR: BikeIdentityCopy = {
  title: "Carte d'identité",
  hint: "Numéro de cadre, achat et assurance — uniquement sur l'appareil.",
  empty: "Ajouter le numéro de cadre — vol et assurance.",
  add: "Créer la carte",
  edit: "Modifier le vélo",
  save: "Enregistrer",
  serial: "Numéro de cadre",
  serialHint: "Gravé au boîtier de pédalier, au tube de direction ou au hauban.",
  serialCopied: "Numéro de cadre copié",
  color: "Couleur",
  weight: "Poids (kg)",
  notes: "Notes",
  purchasedAt: "Acheté le",
  purchasedFrom: "Acheté chez",
  price: "Prix (€)",
  insurance: "Assurance",
  policy: "N° de police",
  keyNumber: "N° de clé",
  privateHint: "Reste local et dans ta sauvegarde. Pas public.",
  year: "Année",
  name: "Nom",
  frameSize: "Taille de cadre",
  wheels: "Roues",
  travel: "Débattement",
  hours: "Heures",
  headAngle: "Angle de direction",
  chainstay: "Bases",
  wheelbase: "Empattement",
  geoSetting: "Réglage géo",
  techDetails: "Détails techniques",
  techHint: "Débattement, cadre…",
  photoUrl: "Lien photo",
  photoUrlHint: "Seulement si tu as une URL. L’appareil photo est sur le stand.",
};

const IT: BikeIdentityCopy = {
  title: "Documento",
  hint: "Numero di telaio, acquisto e assicurazione — solo sul dispositivo.",
  empty: "Aggiungi il numero di telaio — per furto e assicurazione.",
  add: "Crea documento",
  edit: "Modifica bici",
  save: "Salva",
  serial: "Numero di telaio",
  serialHint: "Stampato sul movimento centrale, sul tubo sterzo o sul fodero.",
  serialCopied: "Numero di telaio copiato",
  color: "Colore",
  weight: "Peso (kg)",
  notes: "Note",
  purchasedAt: "Acquistata il",
  purchasedFrom: "Acquistata da",
  price: "Prezzo (€)",
  insurance: "Assicurazione",
  policy: "N. polizza",
  keyNumber: "N. chiave",
  privateHint: "Resta locale e nel backup. Non pubblico.",
  year: "Anno",
  name: "Nome",
  frameSize: "Taglia telaio",
  wheels: "Ruote",
  travel: "Escursione",
  hours: "Ore",
  headAngle: "Angolo sterzo",
  chainstay: "Foderi",
  wheelbase: "Passo",
  geoSetting: "Setting geo",
  techDetails: "Dettagli tecnici",
  techHint: "Escursione, telaio…",
  photoUrl: "Link foto",
  photoUrlHint: "Solo se hai un URL. La fotocamera sta sul stand.",
};

const NL: BikeIdentityCopy = {
  title: "Paspoort",
  hint: "Framenummer, aankoop en verzekering — alleen op dit apparaat.",
  empty: "Framenummer vastleggen — voor diefstal en verzekering.",
  add: "Paspoort aanmaken",
  edit: "Fiets bewerken",
  save: "Opslaan",
  serial: "Framenummer",
  serialHint: "Staat op trapas, balhoofd of liggende achtervork.",
  serialCopied: "Framenummer gekopieerd",
  color: "Kleur",
  weight: "Gewicht (kg)",
  notes: "Notities",
  purchasedAt: "Gekocht op",
  purchasedFrom: "Gekocht bij",
  price: "Prijs (€)",
  insurance: "Verzekering",
  policy: "Polisnummer",
  keyNumber: "Sleutelnummer",
  privateHint: "Blijft lokaal en in je back-up. Niet openbaar.",
  year: "Jaar",
  name: "Naam",
  frameSize: "Framemaat",
  wheels: "Wielen",
  travel: "Veerweg",
  hours: "Uren",
  headAngle: "Balhoofdhoek",
  chainstay: "Liggende achtervork",
  wheelbase: "Wielbasis",
  geoSetting: "Geo-setting",
  techDetails: "Technische details",
  techHint: "Veerweg, frame…",
  photoUrl: "Foto-link",
  photoUrlHint: "Alleen als je een URL hebt. De camera zit op de stand.",
};

const BY_LANG: Record<ChromeLang, BikeIdentityCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function bikeIdentityCopy(lang: ChromeLang = "de"): BikeIdentityCopy {
  return BY_LANG[lang] ?? DE;
}
