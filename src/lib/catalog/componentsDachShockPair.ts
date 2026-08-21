/**
 * Shock-Paarung Rahmen↔OEM-Dämpfer — nur Maße aus Kit/Service-Doku.
 * Keine geratenen DH-Coil-Werte (Tues/Sender/Demo bleiben leer).
 */
import type { ComponentModel, TypedAttribute } from "@/types/garage";

const VERIFIED = "2026-08-21T00:00:00.000Z";

function attr(
  key: string,
  opts: {
    text?: string;
    num?: number;
    enum?: string;
    unit?: string;
  }
): TypedAttribute {
  return {
    key,
    valueText: opts.text,
    valueNum: opts.num,
    valueEnum: opts.enum ?? opts.text,
    unit: opts.unit,
    source: "manufacturer_doc",
    verifiedAt: VERIFIED,
  };
}

function shockMetric(
  eye: number,
  stroke: number,
  mount: "trunnion" | "standard"
): TypedAttribute[] {
  return [
    attr("shock_eye_to_eye_mm", { num: eye, unit: "mm" }),
    attr("shock_stroke_mm", { num: stroke, unit: "mm" }),
    attr("shock_mount_type", { enum: mount }),
  ];
}

/** Rahmen-IDs → Shock-Maße des mitgelieferten OEM-Dämpfers. */
export const FRAME_SHOCK_PAIR_ATTRS: Record<string, TypedAttribute[]> = {
  // YT Decoy MX: Fox FLOAT X2 230×65 (Vital/YT Spec)
  "cm-yt-decoy-frame": shockMetric(230, 65, "trunnion"),
  // Trek Rail Gen 4 Service Manual: 230×57.5 Standard
  "cm-trek-rail-frame": shockMetric(230, 57.5, "standard"),
  // Centurion Numinis R2000 OEM-Dämpfer 210×52.5
  "cm-centurion-numinis-frame": shockMetric(210, 52.5, "trunnion"),
  // Focus JAM² → Fox FLOAT X 210×55
  "cm-focus-jam2-frame": shockMetric(210, 55, "trunnion"),
  // Canyon Lux Trail → SIDLuxe / FLOAT SL 190×45
  "cm-canyon-lux-trail-frame": shockMetric(190, 45, "standard"),
  // Specialized Epic → SIDLuxe 190×45
  "cm-specialized-epic-frame": shockMetric(190, 45, "standard"),
  // Trek Fuel EXe → FLOAT X 210×55
  "cm-trek-fuel-exe-frame": shockMetric(210, 55, "trunnion"),
  // Santa Cruz Nomad → FLOAT X 205×65
  "cm-santa-cruz-nomad-frame": shockMetric(205, 65, "trunnion"),
  // Santa Cruz Blur → SIDLuxe 190×45
  "cm-santa-cruz-blur-frame": shockMetric(190, 45, "standard"),
  // Orbea Rise → FLOAT X 210×55
  "cm-orbea-rise-h30-frame": shockMetric(210, 55, "trunnion"),
  // Orbea Oiz → FLOAT SL 190×45
  "cm-orbea-oiz-h30-frame": shockMetric(190, 45, "standard"),
  // Giant Trance X E+ → FLOAT DPS 185×52.5
  "cm-giant-trance-x-e-frame": shockMetric(185, 52.5, "trunnion"),
  // Propain FLOAT X Kits: Trunnion (nicht Standard)
  "cm-propain-tyee-trail-frame": shockMetric(210, 50, "trunnion"),
  "cm-propain-hugene-frame": shockMetric(210, 47.5, "trunnion"),
  "cm-propain-ekano-trail-frame": shockMetric(210, 50, "trunnion"),
  // Canyon Strive CFR → FLOAT X2 230×65 Trunnion
  "cm-canyon-strive-cfr-frame": shockMetric(230, 65, "trunnion"),
};

function part(
  id: string,
  manufacturer: string,
  model: string,
  opts: {
    variant: string;
    year: number;
    url: string;
    eye: number;
    stroke: number;
    mount: "trunnion" | "standard";
  }
): ComponentModel {
  return {
    id,
    slot: "rear_shock",
    manufacturer,
    model,
    variant: opts.variant,
    modelYear: opts.year,
    attributes: [
      attr("eye_to_eye_mm", { num: opts.eye, unit: "mm" }),
      attr("stroke_mm", { num: opts.stroke, unit: "mm" }),
      attr("mount_type", { enum: opts.mount }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: opts.url,
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  };
}

/** Größe-spezifische FLOAT X (statt generischem Factory ohne Maß). */
export const COMPONENT_CATALOG_SHOCK_PAIR: ComponentModel[] = [
  part("cm-fox-float-x-21050", "Fox", "FLOAT X Factory", {
    variant: "210×50 Trunnion",
    year: 2025,
    url: "https://www.ridefox.com/",
    eye: 210,
    stroke: 50,
    mount: "trunnion",
  }),
  part("cm-fox-float-x-210475", "Fox", "FLOAT X Factory", {
    variant: "210×47.5 Trunnion",
    year: 2024,
    url: "https://www.ridefox.com/",
    eye: 210,
    stroke: 47.5,
    mount: "trunnion",
  }),
];

/** Mount-Typ nachziehen, wo Eye/Stroke schon sitzen. */
export const SHOCK_MOUNT_PATCHES: Record<string, TypedAttribute[]> = {
  "cm-rockshox-deluxe-230575": [
    attr("mount_type", { enum: "standard" }),
  ],
  "cm-centurion-numinis-shock": [
    attr("mount_type", { enum: "trunnion" }),
  ],
};

export function applyShockPairCatalog(
  catalog: ComponentModel[]
): ComponentModel[] {
  const byId = new Map(catalog.map((c) => [c.id, c]));
  for (const extra of COMPONENT_CATALOG_SHOCK_PAIR) {
    if (!byId.has(extra.id)) byId.set(extra.id, extra);
  }

  const patch = (
    id: string,
    attrs: TypedAttribute[]
  ): void => {
    const cur = byId.get(id);
    if (!cur) return;
    const keys = new Set(attrs.map((a) => a.key));
    byId.set(id, {
      ...cur,
      attributes: [
        ...cur.attributes.filter((a) => !keys.has(a.key)),
        ...attrs,
      ],
      verifiedAt: VERIFIED,
    });
  };

  for (const [id, attrs] of Object.entries(FRAME_SHOCK_PAIR_ATTRS)) {
    patch(id, attrs);
  }
  for (const [id, attrs] of Object.entries(SHOCK_MOUNT_PATCHES)) {
    patch(id, attrs);
  }

  return [...byId.values()];
}
