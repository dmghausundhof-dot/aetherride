/**
 * Garage bike-schema anchors — G-SCH-02.
 * viewBox 0 0 1000 500 shared by all templates (road/gravel/mtb/city).
 * Locked BB (400, 372) and ground Y 420 — sport cues via tire/bar/WB/HTA.
 * Keep in sync with public/garage/silhouettes/*.hotspots.json
 */

export type BikeSchemaTemplate = "road" | "gravel" | "mtb" | "city";

export type HotspotStatus = "ok" | "missing" | "maintenance";

export interface SchemaAnchor {
  cx: number;
  cy: number;
  /** Invisible hit radius in viewBox units (≥22 ≈ 44pt at typical display) */
  hitR: number;
  label_de: string;
}

export interface SchemaLineLayer {
  type: "line";
  x1: number;
  y1: number;
  x2: number;
  y2: number;
  stroke: string;
  strokeWidth: number;
}

export interface SchemaRectLayer {
  type: "rect";
  x: number;
  y: number;
  width: number;
  height: number;
  rx: number;
  fill: string;
}

export type SchemaLayer = SchemaLineLayer | SchemaRectLayer;

export const SCHEMA_VIEWBOX = "0 0 1000 500" as const;
export const SCHEMA_VIEWBOX_W = 1000;
export const SCHEMA_VIEWBOX_H = 500;
/** Locked bottom-bracket center (all templates) */
export const SCHEMA_BB = { x: 400, y: 372 } as const;
export const SCHEMA_GROUND_Y = 420;

/** Visible status-dot radius (smaller than hit target) */
export const SCHEMA_DOT_R = 8;
/** Min hit radius in viewBox units */
export const SCHEMA_HIT_R_MIN = 22;

export const STATUS_COLORS: Record<HotspotStatus, string> = {
  ok: "#22C55E",
  maintenance: "#EAB308",
  missing: "#6B7280",
};

export const SCHEMA_ASSET_PATH: Record<BikeSchemaTemplate, string> = {
  road: "/garage/silhouettes/road.svg",
  gravel: "/garage/silhouettes/gravel.svg",
  mtb: "/garage/silhouettes/mtb.svg",
  city: "/garage/silhouettes/city.svg",
};

export const SCHEMA_HOTSPOTS: Record<
  BikeSchemaTemplate,
  Record<string, SchemaAnchor>
> = {
  "road": {
    "tire_front": {
      "cx": 220,
      "cy": 420,
      "hitR": 28,
      "label_de": "Vorderrad"
    },
    "fork": {
      "cx": 254,
      "cy": 289,
      "hitR": 28,
      "label_de": "Gabel"
    },
    "brake_front": {
      "cx": 242,
      "cy": 365,
      "hitR": 28,
      "label_de": "Vorderradbremse"
    },
    "handlebar": {
      "cx": 232,
      "cy": 128,
      "hitR": 28,
      "label_de": "Lenker"
    },
    "stem": {
      "cx": 260,
      "cy": 143,
      "hitR": 28,
      "label_de": "Vorbau"
    },
    "frame": {
      "cx": 365.3,
      "cy": 227.3,
      "hitR": 28,
      "label_de": "Rahmen"
    },
    "seatpost": {
      "cx": 408,
      "cy": 262,
      "hitR": 28,
      "label_de": "Sattelstütze"
    },
    "saddle": {
      "cx": 418,
      "cy": 130,
      "hitR": 28,
      "label_de": "Sattel"
    },
    "crankset": {
      "cx": 400,
      "cy": 372,
      "hitR": 28,
      "label_de": "Kurbel"
    },
    "chain": {
      "cx": 502,
      "cy": 394,
      "hitR": 28,
      "label_de": "Kette"
    },
    "cassette": {
      "cx": 618,
      "cy": 408,
      "hitR": 28,
      "label_de": "Kassette"
    },
    "tire_rear": {
      "cx": 604,
      "cy": 420,
      "hitR": 28,
      "label_de": "Hinterrad"
    },
    "brake_rear": {
      "cx": 576,
      "cy": 362,
      "hitR": 28,
      "label_de": "Hinterradbremse"
    },
    "motor": {
      "cx": 354,
      "cy": 354,
      "hitR": 28,
      "label_de": "Motor"
    },
    "battery": {
      "cx": 364,
      "cy": 275,
      "hitR": 28,
      "label_de": "Akku"
    }
  },
  "gravel": {
    "tire_front": {
      "cx": 220,
      "cy": 420,
      "hitR": 28,
      "label_de": "Vorderrad"
    },
    "fork": {
      "cx": 256,
      "cy": 290,
      "hitR": 28,
      "label_de": "Gabel"
    },
    "brake_front": {
      "cx": 242,
      "cy": 365,
      "hitR": 28,
      "label_de": "Vorderradbremse"
    },
    "handlebar": {
      "cx": 248,
      "cy": 138,
      "hitR": 28,
      "label_de": "Lenker"
    },
    "stem": {
      "cx": 270,
      "cy": 149,
      "hitR": 28,
      "label_de": "Vorbau"
    },
    "frame": {
      "cx": 368,
      "cy": 229,
      "hitR": 28,
      "label_de": "Rahmen"
    },
    "seatpost": {
      "cx": 412,
      "cy": 263.5,
      "hitR": 28,
      "label_de": "Sattelstütze"
    },
    "saddle": {
      "cx": 422,
      "cy": 133,
      "hitR": 28,
      "label_de": "Sattel"
    },
    "crankset": {
      "cx": 400,
      "cy": 372,
      "hitR": 28,
      "label_de": "Kurbel"
    },
    "chain": {
      "cx": 512,
      "cy": 394,
      "hitR": 28,
      "label_de": "Kette"
    },
    "cassette": {
      "cx": 638,
      "cy": 408,
      "hitR": 28,
      "label_de": "Kassette"
    },
    "tire_rear": {
      "cx": 624,
      "cy": 420,
      "hitR": 28,
      "label_de": "Hinterrad"
    },
    "brake_rear": {
      "cx": 596,
      "cy": 362,
      "hitR": 28,
      "label_de": "Hinterradbremse"
    },
    "motor": {
      "cx": 356,
      "cy": 354,
      "hitR": 28,
      "label_de": "Motor"
    },
    "battery": {
      "cx": 366,
      "cy": 276,
      "hitR": 28,
      "label_de": "Akku"
    }
  },
  "mtb": {
    "tire_front": {
      "cx": 220,
      "cy": 420,
      "hitR": 28,
      "label_de": "Vorderrad"
    },
    "fork": {
      "cx": 269,
      "cy": 297.5,
      "hitR": 28,
      "label_de": "Gabel"
    },
    "brake_front": {
      "cx": 242,
      "cy": 365,
      "hitR": 28,
      "label_de": "Vorderradbremse"
    },
    "handlebar": {
      "cx": 298,
      "cy": 168,
      "hitR": 28,
      "label_de": "Lenker"
    },
    "stem": {
      "cx": 308,
      "cy": 171.5,
      "hitR": 28,
      "label_de": "Vorbau"
    },
    "frame": {
      "cx": 382.7,
      "cy": 231.7,
      "hitR": 28,
      "label_de": "Rahmen"
    },
    "seatpost": {
      "cx": 430,
      "cy": 260,
      "hitR": 28,
      "label_de": "Sattelstütze"
    },
    "saddle": {
      "cx": 440,
      "cy": 126,
      "hitR": 28,
      "label_de": "Sattel"
    },
    "crankset": {
      "cx": 400,
      "cy": 372,
      "hitR": 28,
      "label_de": "Kurbel"
    },
    "chain": {
      "cx": 545,
      "cy": 394,
      "hitR": 28,
      "label_de": "Kette"
    },
    "cassette": {
      "cx": 704,
      "cy": 408,
      "hitR": 28,
      "label_de": "Kassette"
    },
    "tire_rear": {
      "cx": 690,
      "cy": 420,
      "hitR": 28,
      "label_de": "Hinterrad"
    },
    "brake_rear": {
      "cx": 662,
      "cy": 362,
      "hitR": 28,
      "label_de": "Hinterradbremse"
    },
    "rear_shock": {
      "cx": 457,
      "cy": 224,
      "hitR": 28,
      "label_de": "Dämpfer"
    },
    "motor": {
      "cx": 369,
      "cy": 354,
      "hitR": 28,
      "label_de": "Motor"
    },
    "battery": {
      "cx": 379,
      "cy": 283.5,
      "hitR": 28,
      "label_de": "Akku"
    }
  },
  "city": {
    "tire_front": {
      "cx": 220,
      "cy": 420,
      "hitR": 28,
      "label_de": "Vorderrad"
    },
    "fork": {
      "cx": 257,
      "cy": 282.5,
      "hitR": 28,
      "label_de": "Gabel"
    },
    "brake_front": {
      "cx": 242,
      "cy": 365,
      "hitR": 28,
      "label_de": "Vorderradbremse"
    },
    "handlebar": {
      "cx": 258,
      "cy": 105,
      "hitR": 28,
      "label_de": "Lenker"
    },
    "stem": {
      "cx": 276,
      "cy": 125,
      "hitR": 28,
      "label_de": "Vorbau"
    },
    "frame": {
      "cx": 370.7,
      "cy": 212.3,
      "hitR": 28,
      "label_de": "Rahmen"
    },
    "seatpost": {
      "cx": 418,
      "cy": 246,
      "hitR": 28,
      "label_de": "Sattelstütze"
    },
    "saddle": {
      "cx": 428,
      "cy": 98,
      "hitR": 28,
      "label_de": "Sattel"
    },
    "crankset": {
      "cx": 400,
      "cy": 372,
      "hitR": 28,
      "label_de": "Kurbel"
    },
    "chain": {
      "cx": 525,
      "cy": 394,
      "hitR": 28,
      "label_de": "Kette"
    },
    "cassette": {
      "cx": 664,
      "cy": 408,
      "hitR": 28,
      "label_de": "Kassette"
    },
    "tire_rear": {
      "cx": 650,
      "cy": 420,
      "hitR": 28,
      "label_de": "Hinterrad"
    },
    "brake_rear": {
      "cx": 622,
      "cy": 362,
      "hitR": 28,
      "label_de": "Hinterradbremse"
    },
    "motor": {
      "cx": 357,
      "cy": 354,
      "hitR": 28,
      "label_de": "Motor"
    },
    "battery": {
      "cx": 367,
      "cy": 268.5,
      "hitR": 28,
      "label_de": "Akku"
    }
  }
};

export const SCHEMA_LAYERS: Record<
  BikeSchemaTemplate,
  Record<string, SchemaLayer>
> = {
  "road": {
    "motor": {
      "type": "rect",
      "x": 372,
      "y": 334,
      "width": 56,
      "height": 32,
      "rx": 6,
      "fill": "#FF6A00"
    },
    "battery": {
      "type": "rect",
      "x": 334,
      "y": 245,
      "width": 44,
      "height": 22,
      "rx": 4,
      "fill": "#7A8B73"
    }
  },
  "gravel": {
    "motor": {
      "type": "rect",
      "x": 372,
      "y": 334,
      "width": 56,
      "height": 32,
      "rx": 6,
      "fill": "#FF6A00"
    },
    "battery": {
      "type": "rect",
      "x": 336,
      "y": 246,
      "width": 44,
      "height": 22,
      "rx": 4,
      "fill": "#7A8B73"
    }
  },
  "mtb": {
    "rear_shock": {
      "type": "line",
      "x1": 432,
      "y1": 198,
      "x2": 482,
      "y2": 350,
      "stroke": "#FF6A00",
      "strokeWidth": 10
    },
    "motor": {
      "type": "rect",
      "x": 372,
      "y": 334,
      "width": 56,
      "height": 32,
      "rx": 6,
      "fill": "#FF6A00"
    },
    "battery": {
      "type": "rect",
      "x": 349,
      "y": 253.5,
      "width": 44,
      "height": 22,
      "rx": 4,
      "fill": "#7A8B73"
    }
  },
  "city": {
    "motor": {
      "type": "rect",
      "x": 372,
      "y": 334,
      "width": 56,
      "height": 32,
      "rx": 6,
      "fill": "#FF6A00"
    },
    "battery": {
      "type": "rect",
      "x": 337,
      "y": 238.5,
      "width": 44,
      "height": 22,
      "rx": 4,
      "fill": "#7A8B73"
    }
  }
};
