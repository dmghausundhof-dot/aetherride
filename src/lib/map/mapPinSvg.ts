/**
 * Cartographic FlowLine pins — SVG for MapLibre HTML markers.
 * The tour pin is an oval badge with either the compact mountain/wave
 * mark or a two-wheel sport glyph (readable at ~32px).
 */

export type MapPinKind =
  | "drop"
  | "tour"
  | "start"
  | "finish"
  | "via"
  | "meet"
  | "stimme"
  | "flow"
  | "halo"
  | "circle"
  | "poi";

/** Compact POI mark. Not sport/garage glyphs. */
export type MapPoiKind =
  | "place"
  | "trailhead"
  | "viewpoint"
  | "cafe"
  | "culture"
  | "water"
  | "transit"
  | "meetup";

/** Inner plate of the tour oval. `mark` = FlowLine peaks; others = bikes/hike. */
export type MapPinGlyph =
  | "mark"
  | "mtb"
  | "emtb"
  | "gravel"
  | "road"
  | "urban"
  | "hike"
  | "dh";

export const MAP_PIN_GLYPHS: readonly MapPinGlyph[] = [
  "mark",
  "mtb",
  "emtb",
  "gravel",
  "road",
  "urban",
  "hike",
  "dh",
];

const GLYPH_INK = "#3A4046";
/** Brand orange — at pin size the logo-wave #E57532 disappears on cream. */
const GLYPH_ACCENT = "#FF6A00";
const GLYPH_PLATE = "#F4F1EC";

/** Oval/capsule map-pin silhouette, viewBox 64×80, tip at (32, 78). */
export const PIN_OVAL_PATH =
  "M32 3 C47 3 54 14 54 26 L54 44 C54 56 40 68 32 78 C24 68 10 56 10 44 L10 26 C10 14 17 3 32 3 Z";

/** Compact FlowLine mark in 48×26 — peaks + orange/sage/gray waves. */
export function compactFlowlineMarkSvg(): string {
  return [
    '<path d="M1.4 23.6 L8 13.4 L11.1 16.9 L16.6 6.4 L21.3 13.1 L28 1.1 L34.3 11.4 L37.9 6.6 L46.6 23.6 Z" fill="#3A4046"/>',
    '<path d="M8 13.4 L5.4 18.1 L9.6 18.9 L4.1 22.6 L10.6 17.4 Z" fill="#FFFFFF"/>',
    '<path d="M16.6 6.4 L13.1 12.1 L17.9 13.6 L12.6 18.6 L18.7 14.1 L21.3 13.1 Z" fill="#FFFFFF"/>',
    '<path d="M28 1.1 L24.1 8.6 L21.8 12.6 L25.1 13.6 L20.8 19.2 L26.1 15.1 L28.2 19.6 L30.6 14.4 L33.6 19.1 L34.3 11.4 Z" fill="#FFFFFF"/>',
    '<path d="M37.9 6.6 L35.1 11.6 L39.6 13.1 L33.8 18.2 L40.4 12.1 Z" fill="#FFFFFF"/>',
    '<path d="M2.4 21.1 C9.2 19.4 15.2 20.1 21.6 19.3 C28.1 18.5 34.6 19.6 40.6 20.8 C43.1 21.4 45.1 21.8 46.6 22.2 L46.6 24.9 L2.4 24.9 Z" fill="#E57532"/>',
    '<path d="M6.2 23.5 C14.1 22.7 22.2 22.5 30.1 22.9 C38 23.3 43.2 24.2 46.2 24.6 L6.2 24.9 Z" fill="#818C7B"/>',
    '<path d="M14.2 24.1 C22.1 23.3 30.2 23.2 38.1 23.8 L38.1 25.2 L14.2 25.2 Z" fill="#9A9C9B"/>',
  ].join("");
}

function glyphStroke(d: string, color = GLYPH_INK, width = 3): string {
  return `<path d="${d}" fill="none" stroke="${color}" stroke-width="${width}" stroke-linecap="round" stroke-linejoin="round"/>`;
}

/** Filled rings — hairline rims vanish at ~14 px. */
function bikeWheelsSvg(radius: number): string {
  const hole = (radius * 0.4).toFixed(2);
  return [10, 38]
    .map(
      (cx) =>
        `<circle cx="${cx}" cy="18" r="${radius}" fill="${GLYPH_INK}"/><circle cx="${cx}" cy="18" r="${hole}" fill="${GLYPH_PLATE}"/>`
    )
    .join("");
}

function mtbGlyphSvg(): string {
  return [
    bikeWheelsSvg(7),
    glyphStroke("M10 18 L20.2 18 L16.4 6.4 L31.6 8.2 L20.2 18"),
    glyphStroke("M16.4 6.4 L10 18"),
    glyphStroke("M31.6 8.2 L38 18"),
    glyphStroke("M13.4 6.4 H19.6", GLYPH_ACCENT, 2.5),
    glyphStroke("M31.6 8.2 L31.6 3.8 H41"),
  ].join("");
}

function boltGlyphSvg(): string {
  return `<path d="M28.4 2.2 L21 13.8 H27 L22.4 24.4 L32.6 10 H26.2 Z" fill="${GLYPH_ACCENT}"/>`;
}

/** Compact sport mark in 48×26. Distinctive at ~14 px: bars, bolt, walker. */
export function sportGlyphSvg(glyph: MapPinGlyph): string {
  if (glyph === "mark") return compactFlowlineMarkSvg();
  if (glyph === "hike") {
    return [
      `<circle cx="22" cy="6.2" r="3.5" fill="${GLYPH_INK}"/>`,
      glyphStroke("M22 9.8 L22 16.2"),
      glyphStroke("M22 16.2 L16.2 24.2"),
      glyphStroke("M22 16.2 L28.6 23.4"),
      glyphStroke("M22 11.8 L17.6 16.4"),
      glyphStroke("M29.4 3.2 L24.2 24.4", GLYPH_ACCENT, 2.4),
    ].join("");
  }
  if (glyph === "urban") {
    return [
      bikeWheelsSvg(6.2),
      glyphStroke("M10 18 L19.6 18 L23.2 10 H34.6 L38 18"),
      glyphStroke("M34.6 10 L34.6 3.6 H41"),
      glyphStroke("M20.8 10 H26", GLYPH_ACCENT, 2.5),
    ].join("");
  }
  if (glyph === "road") {
    return [
      bikeWheelsSvg(5.05),
      glyphStroke("M10 18 L19.4 18 L17 7.2 L32 8.6 L19.4 18"),
      glyphStroke("M17 7.2 L10 18"),
      glyphStroke("M32 8.6 L38 18"),
      glyphStroke("M14.2 7.2 H19.2", GLYPH_ACCENT, 2.4),
      glyphStroke("M32 8.6 L32 4.2 Q26.4 4 26.8 12.2"),
    ].join("");
  }
  if (glyph === "gravel") {
    return [
      bikeWheelsSvg(6.15),
      glyphStroke("M10 18 L20 18 L16.6 6.8 L31.4 8.4 L20 18"),
      glyphStroke("M16.6 6.8 L10 18"),
      glyphStroke("M31.4 8.4 L38 18"),
      glyphStroke("M13.6 6.8 H19.4", GLYPH_ACCENT, 2.5),
      glyphStroke("M24.2 5.6 L31.4 3.4 L40.2 5.6"),
      glyphStroke("M31.4 8.4 L31.4 3.4"),
    ].join("");
  }
  if (glyph === "dh") {
    return [
      bikeWheelsSvg(7.1),
      glyphStroke("M10 18 L21.2 18 L24.8 4.2 L33.4 10.2 L21.2 18"),
      glyphStroke("M24.8 4.2 L38 18"),
      glyphStroke("M24.8 4.2 L24.8 1.8 H36.2"),
      `<rect x="26.6" y="5.6" width="8.4" height="4.6" rx="0.8" fill="${GLYPH_ACCENT}"/>`,
    ].join("");
  }
  if (glyph === "emtb") return mtbGlyphSvg() + boltGlyphSvg();
  return mtbGlyphSvg();
}

/** Map garage / catalog category → pin glyph. Unknown → FlowLine mark. */
export function pinGlyphForCategory(category?: string | null): MapPinGlyph {
  const c = (category ?? "").trim().toLowerCase();
  if (c === "dh") return "dh";
  if (c === "emtb") return "emtb";
  if (c === "hiking") return "hike";
  if (c === "gravel" || c === "etrekking") return "gravel";
  if (c === "road") return "road";
  if (c.startsWith("mtb") || c === "e_mtb") return "mtb";
  if (c === "urban" || c === "cargo" || c === "folding" || c === "kids") {
    return "urban";
  }
  return "mark";
}

/** North-up chevron for MapLibre `symbol-placement: line`. Slim so it sits in the ribbon. */
export function routeChevronSvg(): string {
  return svgWrap(
    "0 0 48 48",
    48,
    48,
    '<path d="M24 10 L36 32 L24 26 L12 32 Z" fill="#FFFFFF" stroke="#1A120C" stroke-width="2.2" stroke-linejoin="round"/>'
  );
}

/** Seed / coverage aliases → compact POI mark. No sport/garage glyphs. */
export function mapPoiKindFromRaw(kind?: string | null): MapPoiKind {
  const k = (kind ?? "")
    .toLowerCase()
    .trim()
    .replace(/é/g, "e")
    .replace(/è/g, "e");
  if (k === "trailhead") return "trailhead";
  if (k === "viewpoint" || k === "aussicht") return "viewpoint";
  if (k === "cafe") return "cafe";
  if (k === "culture" || k === "kultur") return "culture";
  if (k === "water" || k === "see") return "water";
  if (k === "transit" || k === "bahn") return "transit";
  if (k === "meetup") return "meetup";
  if (k === "park") return "place";
  return "place";
}

/** 3D FlowLine sprites in /public/map/pins (256×320, aspect 4:5). */
export function poiPinSrc(kind: MapPoiKind): string {
  return kind === "place" ? "/map/pins/poi.png" : `/map/pins/poi-${kind}.png`;
}

export function routePinSrc(
  kind: MapPinKind,
  color?: string
): string | null {
  const sage = (color ?? "").trim().toUpperCase() === "#7A8B73";
  switch (kind) {
    case "start":
      return sage ? "/map/pins/pin-start-out.png" : "/map/pins/pin-start.png";
    case "finish":
      return sage ? "/map/pins/pin-finish-out.png" : "/map/pins/pin-finish.png";
    case "via":
      return sage ? "/map/pins/pin-via-out.png" : "/map/pins/pin-via.png";
    case "meet":
      return "/map/pins/pin-meet.png";
    case "stimme":
      return "/map/pins/pin-stimme.png";
    default:
      return null;
  }
}

export function mapPoiDisplaySize(selected?: boolean): { w: number; h: number } {
  return selected ? { w: 36, h: 45 } : { w: 32, h: 40 };
}

/** Coverage / Google kinds that already map to a 3D POI sprite. */
export function coveragePlacePoiKind(kind?: string | null): MapPoiKind | null {
  const n = (kind ?? "").toLowerCase().trim().replace(/-/g, "_");
  if (
    n === "shop" ||
    n === "repair" ||
    n === "bike_shop" ||
    n === "bicycle_store"
  ) {
    return "place";
  }
  if (
    n === "cafe" ||
    n === "bakery" ||
    n === "restaurant" ||
    n === "water" ||
    n === "drinking_water" ||
    n === "fountain" ||
    n === "viewpoint" ||
    n === "peak" ||
    n === "scenic" ||
    n === "trailhead" ||
    n === "parking" ||
    n === "culture" ||
    n === "kultur" ||
    n === "transit" ||
    n === "bahn" ||
    n === "meetup"
  ) {
    return mapPoiKindFromRaw(n);
  }
  const mapped = mapPoiKindFromRaw(n);
  return mapped === "place" ? null : mapped;
}

export function resolveMapPinKind(
  id: string,
  kind?: MapPinKind | null
): MapPinKind {
  if (kind) return kind;
  if (id.startsWith("meet-") || id.startsWith("meet:")) return "meet";
  if (
    id === "idea" ||
    id === "tour-idea" ||
    id === "tour-pin" ||
    id.startsWith("tour-")
  ) {
    return "tour";
  }
  return "drop";
}

export function mapPinAnchor(kind: MapPinKind): "bottom" | "center" {
  return kind === "flow" ||
    kind === "halo" ||
    kind === "circle" ||
    kind === "via"
    ? "center"
    : "bottom";
}

export function mapPinDisplaySize(kind: MapPinKind): { w: number; h: number } {
  switch (kind) {
    case "tour":
      return { w: 36, h: 46 };
    case "drop":
      return { w: 28, h: 36 };
    case "start":
    case "finish":
    case "poi":
    case "meet":
    case "stimme":
      return { w: 32, h: 40 };
    case "via":
      return { w: 30, h: 30 };
    case "circle":
      return { w: 32, h: 32 };
    case "flow":
      return { w: 22, h: 22 };
    case "halo":
      return { w: 36, h: 36 };
    default:
      return { w: 22, h: 22 };
  }
}

let pinUid = 0;

function safeFill(color: string | undefined, fallback: string): string {
  const c = (color ?? "").trim();
  return /^#([0-9a-fA-F]{6})$/.test(c) ? c : fallback;
}

function svgWrap(viewBox: string, w: number, h: number, inner: string): string {
  const fid = `flps${++pinUid}`;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox}" width="${w}" height="${h}" aria-hidden="true" overflow="visible" shape-rendering="geometricPrecision"><defs><filter id="${fid}" x="-40%" y="-30%" width="180%" height="180%"><feDropShadow dx="0" dy="1.2" stdDeviation="1.05" flood-color="#1A120C" flood-opacity="0.42"/></filter></defs><g filter="url(#${fid})">${inner}</g></svg>`;
}

function tourInner(fill: string, glyph: MapPinGlyph = "mark"): string {
  const id = `flh${++pinUid}`;
  const clip = `${id}p`;
  const mark = sportGlyphSvg(glyph);
  const gxf =
    glyph === "mark"
      ? "translate(18.4 21.5) scale(0.565)"
      : "translate(16.6 19.6) scale(0.64)";
  return [
    `<defs><linearGradient id="${id}" x1="18" y1="6" x2="46" y2="52"><stop stop-color="#fff" stop-opacity="0.32"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient><clipPath id="${clip}"><ellipse cx="32" cy="30" rx="16" ry="17"/></clipPath></defs>`,
    `<ellipse cx="32" cy="76.8" rx="8.5" ry="3.2" fill="#000" opacity="0.28"/>`,
    `<path d="${PIN_OVAL_PATH}" fill="${fill}"/>`,
    `<path d="${PIN_OVAL_PATH}" fill="url(#${id})"/>`,
    `<path d="${PIN_OVAL_PATH}" fill="none" stroke="#fff" stroke-width="2.8" stroke-linejoin="round"/>`,
    `<ellipse cx="32" cy="30" rx="16" ry="17" fill="#F4F1EC"/>`,
    `<g clip-path="url(#${clip})"><g transform="${gxf}">${mark}</g></g>`,
  ].join("");
}

function dropInner(fill: string): string {
  const body =
    "M32 76 C16 54 13 24 32 8 C51 24 48 54 32 76 Z";
  return [
    `<ellipse cx="32" cy="76.4" rx="8" ry="3" fill="#000" opacity="0.26"/>`,
    `<path d="${body}" fill="${fill}"/>`,
    `<path d="${body}" fill="none" stroke="#fff" stroke-width="2.8" stroke-linejoin="round"/>`,
    `<circle cx="32" cy="30" r="9.5" fill="#fff"/>`,
    `<circle cx="32" cy="30" r="5.4" fill="${fill}"/>`,
    `<circle cx="29.6" cy="27.6" r="1.9" fill="#fff" opacity="0.88"/>`,
  ].join("");
}

function meetInner(fill: string): string {
  return [
    `<circle cx="32" cy="32" r="18" fill="${fill}" opacity="0.16"/>`,
    `<g transform="translate(32 32) rotate(45)">`,
    `<rect x="-15" y="-15" width="30" height="30" rx="6" fill="#fff"/>`,
    `<rect x="-11.5" y="-11.5" width="23" height="23" rx="4.5" fill="${fill}"/>`,
    `</g>`,
    `<circle cx="26.2" cy="28.4" r="3.1" fill="#fff"/>`,
    `<path d="M22.4 35.2 A6.2 4.4 0 0 1 30 35.2 Z" fill="#fff"/>`,
    `<circle cx="37.8" cy="28.4" r="3.1" fill="#fff"/>`,
    `<path d="M34 35.2 A6.2 4.4 0 0 1 41.6 35.2 Z" fill="#fff"/>`,
  ].join("");
}

function stimmeInner(fill: string): string {
  return [
    `<rect x="12" y="10" width="40" height="28" rx="10" fill="#fff"/>`,
    `<path d="M20 38 Q16.5 50 14 54 Q24 46 28.5 38 Z" fill="#fff"/>`,
    `<rect x="15.5" y="13.5" width="33" height="21" rx="7.5" fill="${fill}"/>`,
    `<path d="M22 21.5 H41" stroke="#fff" stroke-width="2.2" stroke-linecap="round"/>`,
    `<path d="M22 27.5 H35" stroke="#fff" stroke-width="2.2" stroke-linecap="round"/>`,
  ].join("");
}

function flowInner(fill: string): string {
  return [
    `<circle cx="32" cy="32" r="14" fill="${fill}" opacity="0.2"/>`,
    `<circle cx="32" cy="32" r="8.5" fill="#fff"/>`,
    `<circle cx="32" cy="32" r="5" fill="${fill}"/>`,
    `<circle cx="30.4" cy="30.2" r="1.4" fill="#fff" opacity="0.85"/>`,
  ].join("");
}

function haloInner(fill: string): string {
  return [
    `<circle cx="32" cy="32" r="22" fill="${fill}" opacity="0.16"/>`,
    `<circle cx="32" cy="32" r="16" fill="none" stroke="${fill}" stroke-width="3" opacity="0.55"/>`,
  ].join("");
}

function circleInner(fill: string): string {
  return [
    `<circle cx="32" cy="32" r="14" fill="${fill}"/>`,
    `<circle cx="32" cy="32" r="14" fill="none" stroke="#fff" stroke-width="2.6"/>`,
  ].join("");
}

function startInner(fill: string): string {
  return [
    `<ellipse cx="32" cy="76.8" rx="8.2" ry="3" fill="#1A120C" opacity="0.32"/>`,
    `<path d="${PIN_OVAL_PATH}" fill="${fill}"/>`,
    `<path d="${PIN_OVAL_PATH}" fill="none" stroke="#fff" stroke-width="2.4" stroke-linejoin="round"/>`,
    `<ellipse cx="32" cy="30" rx="16.4" ry="16.4" fill="#F4F1EC"/>`,
    `<ellipse cx="27.4" cy="25.6" rx="6.4" ry="4.2" fill="#fff" opacity="0.42"/>`,
    `<path d="M26 21.2 L26 38.8 L43.4 30 Z" fill="#FF6A00"/>`,
  ].join("");
}

function finishInner(): string {
  return [
    `<ellipse cx="32" cy="76.8" rx="8.2" ry="3" fill="#1A120C" opacity="0.32"/>`,
    `<path d="${PIN_OVAL_PATH}" fill="#FF6A00"/>`,
    `<path d="${PIN_OVAL_PATH}" fill="none" stroke="#fff" stroke-width="2.4" stroke-linejoin="round"/>`,
    `<ellipse cx="32" cy="30" rx="16.4" ry="16.4" fill="#F4F1EC"/>`,
    `<ellipse cx="27.4" cy="25.6" rx="6.4" ry="4.2" fill="#fff" opacity="0.42"/>`,
    `<rect x="22.2" y="18" width="3.6" height="24" rx="1.4" fill="#1A120C"/>`,
    `<path d="M25.8 18.2 H42.8 L39.2 27.2 H25.8 Z" fill="#FF6A00"/>`,
  ].join("");
}

function poiKindMarkSvg(kind: MapPoiKind): string {
  if (kind === "trailhead") {
    return '<rect x="-10" y="-11" width="4" height="22" rx="1.4" fill="#1A120C"/><rect x="-6" y="-11" width="16.5" height="10.5" rx="1.8" fill="#FF6A00"/>';
  }
  if (kind === "viewpoint") {
    return '<path d="M-11 8 L-4.2 -2.4 L1.2 4.4 L6.4 -8 L11 8 Z" fill="#1A120C"/><circle cx="6.4" cy="-9.2" r="3" fill="#FF6A00"/>';
  }
  if (kind === "cafe") {
    return '<rect x="-9.2" y="-5.6" width="15" height="14" rx="3" fill="#1A120C"/><path d="M5.6 -2.4 C11.2 -2.4 11.2 7.2 5.6 7.2" fill="none" stroke="#1A120C" stroke-width="3.6" stroke-linecap="round"/><rect x="-6.4" y="-8.2" width="9.2" height="2.6" rx="1" fill="#FF6A00"/>';
  }
  if (kind === "culture") {
    return '<rect x="-11" y="5.8" width="22" height="4" fill="#1A120C"/><rect x="-10" y="-6.8" width="5.2" height="13.4" fill="#1A120C"/><rect x="-2.6" y="-6.8" width="5.2" height="13.4" fill="#1A120C"/><rect x="4.8" y="-6.8" width="5.2" height="13.4" fill="#1A120C"/><rect x="-11.2" y="-11.2" width="22.4" height="4.4" fill="#FF6A00"/>';
  }
  if (kind === "water") {
    return '<path d="M0 -10.4 C8.2 -1.2 9.2 4.6 0 10.4 C-9.2 4.6 -8.2 -1.2 0 -10.4 Z" fill="#1A120C"/><circle cx="-1.8" cy="1.2" r="2.6" fill="#FF6A00"/>';
  }
  if (kind === "transit") {
    return '<rect x="-10" y="-6.8" width="20" height="12.4" rx="3.4" fill="#1A120C"/><circle cx="-4.6" cy="8" r="2.8" fill="#1A120C"/><circle cx="4.6" cy="8" r="2.8" fill="#1A120C"/><rect x="-6.6" y="-3.6" width="6.2" height="4.6" rx="0.8" fill="#FF6A00"/>';
  }
  if (kind === "meetup") {
    return '<circle cx="-5.4" cy="-3.2" r="4.8" fill="#1A120C"/><circle cx="5.4" cy="-3.2" r="4.8" fill="#1A120C"/><circle cx="0" cy="5.6" r="3.6" fill="#FF6A00"/>';
  }
  return '<circle cx="0" cy="0" r="7.2" fill="#1A120C"/><circle cx="0" cy="0" r="3.6" fill="#FF6A00"/>';
}

function poiInner(fill: string, poiKind: MapPoiKind): string {
  const body =
    "M32 6 C45 6 52 16 52 27 L52 42 C52 54 40 66 32 76 C24 66 12 54 12 42 L12 27 C12 16 19 6 32 6 Z";
  return [
    `<ellipse cx="32" cy="76.8" rx="8.2" ry="3" fill="#000" opacity="0.32"/>`,
    `<path d="${body}" fill="${fill}"/>`,
    `<path d="${body}" fill="none" stroke="#fff" stroke-width="2.4" stroke-linejoin="round"/>`,
    `<ellipse cx="32" cy="30" rx="16.4" ry="16.4" fill="#F4F1EC"/>`,
    `<ellipse cx="27.4" cy="25.6" rx="6.4" ry="4.2" fill="#fff" opacity="0.42"/>`,
    `<ellipse cx="32" cy="30" rx="16.4" ry="16.4" fill="none" stroke="#FF6A00" stroke-width="3.2"/>`,
    `<g transform="translate(32 30)">${poiKindMarkSvg(poiKind)}</g>`,
  ].join("");
}

function viaInner(fill: string): string {
  return [
    `<circle cx="32" cy="32" r="16" fill="#F4F1EC"/>`,
    `<circle cx="32" cy="32" r="16" fill="none" stroke="${fill}" stroke-width="3.2"/>`,
  ].join("");
}

export function mapPinSvg(
  kind: MapPinKind,
  color?: string,
  glyph: MapPinGlyph = "mark",
  poiKind: MapPoiKind = "place"
): string {
  const { w, h } = mapPinDisplaySize(kind);
  if (kind === "tour") {
    const fill = safeFill(color, "#2A2E32");
    return svgWrap("0 0 64 80", w, h, tourInner(fill, glyph));
  }
  if (kind === "drop") {
    const fill = safeFill(color, "#FF6A00");
    return svgWrap("0 0 64 80", w, h, dropInner(fill));
  }
  if (kind === "poi") {
    return svgWrap(
      "0 0 64 80",
      w,
      h,
      poiInner(safeFill(color, "#2A2E32"), poiKind)
    );
  }
  if (kind === "start") {
    return svgWrap("0 0 64 80", w, h, startInner(safeFill(color, "#2E7D32")));
  }
  if (kind === "finish") {
    return svgWrap("0 0 64 80", w, h, finishInner());
  }
  if (kind === "via") {
    return svgWrap("0 0 64 64", w, h, viaInner(safeFill(color, "#FF6A00")));
  }
  const fill = safeFill(color, "#FF6A00");
  const inner =
    kind === "meet"
      ? meetInner(fill)
      : kind === "stimme"
        ? stimmeInner(fill)
        : kind === "flow"
          ? flowInner(fill)
          : kind === "halo"
            ? haloInner(fill)
            : circleInner(fill);
  return svgWrap("0 0 64 64", w, h, inner);
}
