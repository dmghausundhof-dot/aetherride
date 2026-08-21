/**
 * Compatibility chrome. Engine stores German titles/explainDe; UI maps by ruleCode.
 * Fail strings match Flutter ARB compatFail* / compatTitle*.
 */
import type { ChromeLang } from "./chromeLang";
import type {
  CompatibilityResult,
  CompatibilityVerdict,
} from "@/types/garage";

function ev(
  r: CompatibilityResult,
  key: string,
  side: "a" | "b"
): string {
  const item = r.evidence.find((e) => e.attributeKey === key);
  const v = side === "a" ? item?.valueA : item?.valueB;
  if (v === undefined || v === null || v === "") return "?";
  return String(v);
}

const VERDICT: Record<ChromeLang, Record<CompatibilityVerdict, string>> = {
  de: {
    COMPATIBLE: "Kompatibel",
    CONDITIONAL: "Bedingt",
    INCOMPATIBLE: "Inkompatibel",
    INSUFFICIENT_DATA: "Daten fehlen",
  },
  en: {
    COMPATIBLE: "Fits",
    CONDITIONAL: "Check",
    INCOMPATIBLE: "No fit",
    INSUFFICIENT_DATA: "Unclear",
  },
  fr: {
    COMPATIBLE: "Ça va",
    CONDITIONAL: "À voir",
    INCOMPATIBLE: "Ne va pas",
    INSUFFICIENT_DATA: "Pas clair",
  },
  it: {
    COMPATIBLE: "Va bene",
    CONDITIONAL: "Da vedere",
    INCOMPATIBLE: "Non va",
    INSUFFICIENT_DATA: "Poco chiaro",
  },
  nl: {
    COMPATIBLE: "Past",
    CONDITIONAL: "Checken",
    INCOMPATIBLE: "Past niet",
    INSUFFICIENT_DATA: "Onzeker",
  },
};

const TITLE: Record<string, Record<ChromeLang, string>> = {
  "RL-DRV-011": {
    de: "Kassette benötigt passenden Freilaufkörper",
    en: "Cassette needs matching freehub body",
    fr: "La cassette demande un corps de roue libre adapté",
    it: "La cassetta chiede un corpo ruota libera adatto",
    nl: "Cassette vraagt passende freehub-body",
  },
  "RL-FRM-004": {
    de: "Hinterbau-Einbaubreite muss zur Nabe passen",
    en: "Rear spacing must match the hub",
    fr: "L’écartement arrière doit matcher le moyeu",
    it: "Lo spacing posteriore deve coincidere col mozzo",
    nl: "Achteras-afstand moet bij de naaf passen",
  },
  "RL-SUS-007": {
    de: "Dämpfer-Maß muss zur Rahmenvorgabe passen",
    en: "Shock size must match the frame spec",
    fr: "La cote amortisseur doit matcher le cadre",
    it: "La misura ammortizzatore deve coincidere col telaio",
    nl: "Dempermaat moet bij de framespec passen",
  },
  "RL-SUS-012": {
    de: "Gabel-Schaft vs. Steuersatz (S.H.I.S.)",
    en: "Fork steerer vs headset (S.H.I.S.)",
    fr: "Pivot fourche vs jeu de direction (S.H.I.S.)",
    it: "Cannotto forcella vs serie sterzo (S.H.I.S.)",
    nl: "Vork-steerer vs balhoofd (S.H.I.S.)",
  },
  "RL-BRK-003": {
    de: "Bremssattel-Aufnahme am Rahmen/Gabel",
    en: "Brake caliper mount on the frame",
    fr: "Fixation étrier sur le cadre",
    it: "Attacco pinza sul telaio",
    nl: "Remklauw-montage op het frame",
  },
  "RL-BRK-008": {
    de: "Bremsscheiben-Aufnahme vs. Nabe",
    en: "Rotor mount vs hub",
    fr: "Fixation disque vs moyeu",
    it: "Attacco disco vs mozzo",
    nl: "Schijfmontage vs naaf",
  },
  "RL-BRK-008F": {
    de: "Bremsscheibe vorne vs. Vorderradnabe",
    en: "Front rotor vs front hub",
    fr: "Disque avant vs moyeu avant",
    it: "Disco anteriore vs mozzo anteriore",
    nl: "Voorschijf vs voornaaf",
  },
  "RL-WHL-005": {
    de: "Reifenbreite zur Felgen-Maulweite",
    en: "Tire width vs internal rim width",
    fr: "Largeur pneu vs largeur interne jante",
    it: "Larghezza copertone vs canale interno",
    nl: "Bandbreedte vs interne velgbreedte",
  },
  "RL-WHL-005F": {
    de: "Vorderreifen zur Felgen-Maulweite",
    en: "Front tire vs internal rim width",
    fr: "Pneu avant vs largeur interne jante",
    it: "Anteriore vs canale interno",
    nl: "Voorband vs interne velgbreedte",
  },
  "RL-WHL-009": {
    de: "Reifen-Außenmaß vs. Rahmenfreigang",
    en: "Tire width vs frame clearance",
    fr: "Largeur pneu vs passage cadre",
    it: "Larghezza copertone vs passaggio telaio",
    nl: "Bandbreedte vs framedoorgang",
  },
  "RL-CKP-002": {
    de: "Lenker-Klemmdurchmesser vs. Vorbau",
    en: "Handlebar clamp diameter vs stem",
    fr: "Diamètre serrage cintre vs potence",
    it: "Diametro morsetto piega vs attacco",
    nl: "Stuurklem-diameter vs stuurpen",
  },
  "RL-SPT-006": {
    de: "Sattelstützendurchmesser vs. Sitzrohr",
    en: "Seatpost diameter vs seat tube",
    fr: "Diamètre tige de selle vs tube de selle",
    it: "Diametro reggisella vs tubo sella",
    nl: "Zadelpen-diameter vs zadelbuis",
  },
  "RL-BB-003": {
    de: "Innenlager-Standard vs. Kurbelwelle",
    en: "Bottom bracket standard vs crank axle",
    fr: "Standard boîtier vs axe de pédalier",
    it: "Standard movimento vs perno pedivella",
    nl: "Trapasstandaard vs crankas",
  },
  "RL-BB-003F": {
    de: "Innenlager vs. Rahmen-Standard",
    en: "Bottom bracket vs frame standard",
    fr: "Boîtier vs standard cadre",
    it: "Movimento vs standard telaio",
    nl: "Trapas vs framestandaard",
  },
  "RL-EBK-002": {
    de: "Motor-Interface nur bei OEM-Freigabe",
    en: "Motor interface only with OEM approval",
    fr: "Interface moteur seulement avec accord OEM",
    it: "Interfaccia motore solo con via libera OEM",
    nl: "Motor-interface alleen met OEM-vrijgave",
  },
  "RL-FRM-004F": {
    de: "Vorderrad-Achse vs. Gabel",
    en: "Front axle vs fork",
    fr: "Axe avant vs fourche",
    it: "Asse anteriore vs forcella",
    nl: "Vooras vs vork",
  },
};

const OK: Record<ChromeLang, string> = {
  de: "Regel erfüllt.",
  en: "Rule met.",
  fr: "Règle respectée.",
  it: "Regola soddisfatta.",
  nl: "Regel gehaald.",
};

const MISSING: Record<ChromeLang, string> = {
  de: "Fehlende Attribute — kein COMPATIBLE ohne vollständige Faktenlage.",
  en: "Missing attributes — no COMPATIBLE without complete facts.",
  fr: "Attributs manquants — pas de COMPATIBLE sans faits complets.",
  it: "Attributi mancanti — niente COMPATIBLE senza fatti completi.",
  nl: "Attributen ontbreken — geen COMPATIBLE zonder complete feiten.",
};

const FREE_TEXT: Record<ChromeLang, string> = {
  de: "Freitext-Komponente ohne Katalogbezug — Kompatibilitätsprüfung gesperrt.",
  en: "Free-text part without a catalogue match — fit check locked.",
  fr: "Pièce en texte libre sans catalogue — contrôle de compat bloqué.",
  it: "Componente a testo libero senza catalogo — controllo compat bloccato.",
  nl: "Vrije-tekst-onderdeel zonder catalogus — pascheck geblokkeerd.",
};

const CONDITIONAL: Record<ChromeLang, string> = {
  de: "Bedingt kompatibel",
  en: "Conditionally compatible",
  fr: "Compatible sous conditions",
  it: "Compatibile con riserva",
  nl: "Voorwaardelijk compatibel",
};

const CONDITION_BRK003: Record<ChromeLang, string> = {
  de: "Nur mit passendem Adapter (Post Mount ↔ IS).",
  en: "Only with a matching adapter (Post Mount ↔ IS).",
  fr: "Seulement avec un adaptateur adapté (Post Mount ↔ IS).",
  it: "Solo con adattatore adatto (Post Mount ↔ IS).",
  nl: "Alleen met passende adapter (Post Mount ↔ IS).",
};

const CONDITION_WHL: Record<ChromeLang, string> = {
  de: "Ohne Herstellerfreigabe gilt die Praxis-Tabelle Reifenbreite ≈ 1,4–2,4× Maulweite.",
  en: "Without a maker approval the practice chart applies (tyre width ≈ 1.4–2.4× internal width).",
  fr: "Sans feu vert constructeur, le tableau pratique s’applique (largeur pneu ≈ 1,4–2,4× largeur interne).",
  it: "Senza via libera del maker vale la tabella pratica (larghezza ≈ 1,4–2,4× canale interno).",
  nl: "Zonder maker-vrijgave geldt de praktijktabel (bandbreedte ≈ 1,4–2,4× interne breedte).",
};

function failExplain(r: CompatibilityResult, lang: ChromeLang): string {
  const a = (k: string) => ev(r, k, "a");
  const b = (k: string) => ev(r, k, "b");
  switch (r.ruleCode) {
    case "RL-DRV-011":
      return {
        de: `Die Kassette benötigt ${a("freehub_standard")}, deine Nabe hat ${b("freehub_standard")}.`,
        en: `The cassette needs ${a("freehub_standard")}, your hub has ${b("freehub_standard")}.`,
        fr: `La cassette demande ${a("freehub_standard")}, ton moyeu a ${b("freehub_standard")}.`,
        it: `La cassetta chiede ${a("freehub_standard")}, il mozzo ha ${b("freehub_standard")}.`,
        nl: `De cassette vraagt ${a("freehub_standard")}, jouw naaf heeft ${b("freehub_standard")}.`,
      }[lang];
    case "RL-FRM-004":
      return {
        de: `Rahmen-Einbaubreite ${a("rear_spacing")} ≠ Nabe ${b("rear_spacing")}.`,
        en: `Frame spacing ${a("rear_spacing")} ≠ hub ${b("rear_spacing")}.`,
        fr: `Écartement cadre ${a("rear_spacing")} ≠ moyeu ${b("rear_spacing")}.`,
        it: `Spacing telaio ${a("rear_spacing")} ≠ mozzo ${b("rear_spacing")}.`,
        nl: `Frame-afstand ${a("rear_spacing")} ≠ naaf ${b("rear_spacing")}.`,
      }[lang];
    case "RL-SUS-007":
      return {
        de: `Dämpfer ${a("eye_to_eye_mm")}×${a("stroke_mm")} (${a("mount_type")}) passt nicht zur Rahmenvorgabe.`,
        en: `Shock ${a("eye_to_eye_mm")}×${a("stroke_mm")} (${a("mount_type")}) does not match the frame spec.`,
        fr: `Amortisseur ${a("eye_to_eye_mm")}×${a("stroke_mm")} (${a("mount_type")}) ne matche pas le cadre.`,
        it: `Ammortizzatore ${a("eye_to_eye_mm")}×${a("stroke_mm")} (${a("mount_type")}) non coincide col telaio.`,
        nl: `Demper ${a("eye_to_eye_mm")}×${a("stroke_mm")} (${a("mount_type")}) past niet bij de framespec.`,
      }[lang];
    case "RL-SUS-012":
      return {
        de: `Gabel-Schaft ${a("steerer_type")} passt nicht zum Steuersatz ${b("steerer_type")}.`,
        en: `Fork steerer ${a("steerer_type")} does not match headset ${b("steerer_type")}.`,
        fr: `Pivot ${a("steerer_type")} ne matche pas le jeu de direction ${b("steerer_type")}.`,
        it: `Cannotto ${a("steerer_type")} non coincide con la serie sterzo ${b("steerer_type")}.`,
        nl: `Vork-steerer ${a("steerer_type")} past niet bij balhoofd ${b("steerer_type")}.`,
      }[lang];
    case "RL-BRK-003":
      return {
        de: `Bremssattel ${a("brake_mount")} vs. Rahmenaufnahme ${b("brake_mount_rear")}.`,
        en: `Caliper ${a("brake_mount")} vs frame mount ${b("brake_mount_rear")}.`,
        fr: `Étrier ${a("brake_mount")} vs fixation cadre ${b("brake_mount_rear")}.`,
        it: `Pinza ${a("brake_mount")} vs attacco telaio ${b("brake_mount_rear")}.`,
        nl: `Remklauw ${a("brake_mount")} vs framemontage ${b("brake_mount_rear")}.`,
      }[lang];
    case "RL-BRK-008":
      return {
        de: `Scheibe ${a("rotor_mount")} passt nicht zur Nabe ${b("rotor_mount")}.`,
        en: `Rotor ${a("rotor_mount")} ≠ hub ${b("rotor_mount")}.`,
        fr: `Disque ${a("rotor_mount")} ≠ moyeu ${b("rotor_mount")}.`,
        it: `Disco ${a("rotor_mount")} ≠ mozzo ${b("rotor_mount")}.`,
        nl: `Schijf ${a("rotor_mount")} ≠ naaf ${b("rotor_mount")}.`,
      }[lang];
    case "RL-BRK-008F":
      return {
        de: `Vordere Scheibe ${a("rotor_mount")} passt nicht zur Nabe ${b("rotor_mount")}.`,
        en: `Front rotor ${a("rotor_mount")} ≠ hub ${b("rotor_mount")}.`,
        fr: `Disque avant ${a("rotor_mount")} ≠ moyeu ${b("rotor_mount")}.`,
        it: `Disco anteriore ${a("rotor_mount")} ≠ mozzo ${b("rotor_mount")}.`,
        nl: `Voorschijf ${a("rotor_mount")} ≠ naaf ${b("rotor_mount")}.`,
      }[lang];
    case "RL-WHL-005":
      return {
        de: `Reifenbreite ${a("tire_width_mm")} mm liegt außerhalb des empfohlenen Bereichs für Maulweite ${b("internal_rim_width_mm")} mm.`,
        en: `Tire width ${a("tire_width_mm")} mm outside range for internal width ${b("internal_rim_width_mm")} mm.`,
        fr: `Largeur pneu ${a("tire_width_mm")} mm hors plage pour largeur interne ${b("internal_rim_width_mm")} mm.`,
        it: `Larghezza ${a("tire_width_mm")} mm fuori range per canale ${b("internal_rim_width_mm")} mm.`,
        nl: `Bandbreedte ${a("tire_width_mm")} mm buiten bereik voor interne breedte ${b("internal_rim_width_mm")} mm.`,
      }[lang];
    case "RL-WHL-005F":
      return {
        de: `Vorderreifen ${a("tire_width_mm")} mm außerhalb des Bereichs für Maulweite ${b("internal_rim_width_mm")} mm.`,
        en: `Front tire ${a("tire_width_mm")} mm outside range for ${b("internal_rim_width_mm")} mm.`,
        fr: `Pneu avant ${a("tire_width_mm")} mm hors plage pour ${b("internal_rim_width_mm")} mm.`,
        it: `Anteriore ${a("tire_width_mm")} mm fuori range per ${b("internal_rim_width_mm")} mm.`,
        nl: `Voorband ${a("tire_width_mm")} mm buiten bereik voor ${b("internal_rim_width_mm")} mm.`,
      }[lang];
    case "RL-WHL-009":
      return {
        de: `Reifenbreite ${a("tire_width_mm")} mm überschreitet Rahmenfreigang ${b("max_tire_width_mm")} mm.`,
        en: `Tire width ${a("tire_width_mm")} mm > frame clearance ${b("max_tire_width_mm")} mm.`,
        fr: `Largeur pneu ${a("tire_width_mm")} mm > passage cadre ${b("max_tire_width_mm")} mm.`,
        it: `Larghezza ${a("tire_width_mm")} mm > passaggio telaio ${b("max_tire_width_mm")} mm.`,
        nl: `Bandbreedte ${a("tire_width_mm")} mm > framedoorgang ${b("max_tire_width_mm")} mm.`,
      }[lang];
    case "RL-CKP-002":
      return {
        de: `Lenkerklemmung ${a("handlebar_clamp_mm")} mm ≠ Vorbau ${b("stem_clamp_mm")} mm.`,
        en: `Bar clamp ${a("handlebar_clamp_mm")} mm ≠ stem ${b("stem_clamp_mm")} mm.`,
        fr: `Serrage cintre ${a("handlebar_clamp_mm")} mm ≠ potence ${b("stem_clamp_mm")} mm.`,
        it: `Morsetto piega ${a("handlebar_clamp_mm")} mm ≠ attacco ${b("stem_clamp_mm")} mm.`,
        nl: `Stuurklem ${a("handlebar_clamp_mm")} mm ≠ stuurpen ${b("stem_clamp_mm")} mm.`,
      }[lang];
    case "RL-SPT-006":
      return {
        de: `Stütze Ø ${a("seatpost_diameter_mm")} passt nicht zu Rahmen Ø ${b("seatpost_diameter_mm")}.`,
        en: `Post Ø ${a("seatpost_diameter_mm")} does not match frame Ø ${b("seatpost_diameter_mm")}.`,
        fr: `Tige Ø ${a("seatpost_diameter_mm")} ne matche pas le cadre Ø ${b("seatpost_diameter_mm")}.`,
        it: `Reggisella Ø ${a("seatpost_diameter_mm")} non coincide col telaio Ø ${b("seatpost_diameter_mm")}.`,
        nl: `Zadelpen Ø ${a("seatpost_diameter_mm")} past niet bij frame Ø ${b("seatpost_diameter_mm")}.`,
      }[lang];
    case "RL-BB-003":
      return {
        de: `Innenlager-Welle ${a("crank_axle")} ≠ Kurbel ${b("crank_axle")}.`,
        en: `BB axle ${a("crank_axle")} ≠ crank ${b("crank_axle")}.`,
        fr: `Axe boîtier ${a("crank_axle")} ≠ pédalier ${b("crank_axle")}.`,
        it: `Perno movimento ${a("crank_axle")} ≠ pedivella ${b("crank_axle")}.`,
        nl: `Trapasas ${a("crank_axle")} ≠ crank ${b("crank_axle")}.`,
      }[lang];
    case "RL-BB-003F":
      return {
        de: `Innenlager ${a("bb_standard")} passt nicht zum Rahmen ${b("bb_standard")}.`,
        en: `Bottom bracket ${a("bb_standard")} ≠ frame ${b("bb_standard")}.`,
        fr: `Boîtier ${a("bb_standard")} ≠ cadre ${b("bb_standard")}.`,
        it: `Movimento ${a("bb_standard")} ≠ telaio ${b("bb_standard")}.`,
        nl: `Trapas ${a("bb_standard")} ≠ frame ${b("bb_standard")}.`,
      }[lang];
    case "RL-EBK-002":
      return {
        de: `Motortausch außerhalb OEM-Freigabe unzulässig. Frame ${b("motor_interface")} ≠ Motor ${a("motor_interface")}.`,
        en: `Motor swap outside OEM approval is not allowed. Frame ${b("motor_interface")} ≠ motor ${a("motor_interface")}.`,
        fr: `Changer le moteur hors accord OEM n’est pas permis. Cadre ${b("motor_interface")} ≠ moteur ${a("motor_interface")}.`,
        it: `Cambio motore fuori via libera OEM non ammesso. Telaio ${b("motor_interface")} ≠ motore ${a("motor_interface")}.`,
        nl: `Motorwissel buiten OEM-vrijgave mag niet. Frame ${b("motor_interface")} ≠ motor ${a("motor_interface")}.`,
      }[lang];
    case "RL-FRM-004F":
      return {
        de: `Gabel-Achse ${a("axle_front")} ≠ Nabe ${b("axle_front")}.`,
        en: `Fork axle ${a("axle_front")} ≠ hub ${b("axle_front")}.`,
        fr: `Axe fourche ${a("axle_front")} ≠ moyeu ${b("axle_front")}.`,
        it: `Asse forcella ${a("axle_front")} ≠ mozzo ${b("axle_front")}.`,
        nl: `Vorkas ${a("axle_front")} ≠ naaf ${b("axle_front")}.`,
      }[lang];
    default:
      return r.explainDe;
  }
}

function conditionFor(r: CompatibilityResult, lang: ChromeLang): string {
  if (r.ruleCode === "RL-BRK-003") return CONDITION_BRK003[lang];
  if (r.ruleCode === "RL-WHL-005" || r.ruleCode === "RL-WHL-005F") {
    return CONDITION_WHL[lang];
  }
  return r.conditionText?.trim() ? r.conditionText : CONDITIONAL[lang];
}

export function compatVerdictLabel(
  v: CompatibilityVerdict,
  lang: ChromeLang = "de"
): string {
  return VERDICT[lang][v];
}

export function compatTitle(
  r: CompatibilityResult,
  lang: ChromeLang = "de"
): string {
  return TITLE[r.ruleCode]?.[lang] ?? r.title;
}

export function presentCompat(
  r: CompatibilityResult,
  lang: ChromeLang = "de"
): { title: string; explain: string; verdict: string } {
  const title = compatTitle(r, lang);
  const verdict = compatVerdictLabel(r.verdict, lang);
  if (r.verdict === "INSUFFICIENT_DATA") {
    const explain = r.explainDe.includes("Freitext")
      ? FREE_TEXT[lang]
      : MISSING[lang];
    return { title, explain, verdict };
  }
  if (r.verdict === "COMPATIBLE") {
    return { title, explain: OK[lang], verdict };
  }
  if (r.verdict === "CONDITIONAL") {
    return { title, explain: conditionFor(r, lang), verdict };
  }
  return { title, explain: failExplain(r, lang), verdict };
}
