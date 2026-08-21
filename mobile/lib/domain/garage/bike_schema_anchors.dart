// G-SCH-01/02 — schema anchors (sync with src/lib/garage/schema/anchors.ts)
// viewBox 0 0 1000 500 · locked BB (400, 372) · ground Y 420

class SchemaAnchor {
  const SchemaAnchor({
    required this.cx,
    required this.cy,
    required this.hitR,
    required this.labelDe,
  });

  final double cx;
  final double cy;
  final double hitR;
  final String labelDe;
}

sealed class SchemaLayer {
  const SchemaLayer();
}

class SchemaLineLayer extends SchemaLayer {
  const SchemaLineLayer({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.stroke,
    required this.strokeWidth,
  });

  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final String stroke;
  final double strokeWidth;
}

class SchemaRectLayer extends SchemaLayer {
  const SchemaRectLayer({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rx,
    required this.fill,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double rx;
  final String fill;
}

const schemaViewBoxW = 1000.0;
const schemaViewBoxH = 500.0;
const schemaBbX = 400.0;
const schemaBbY = 372.0;
const schemaGroundY = 420.0;
const schemaDotR = 8.0;
const schemaHitRMin = 22.0;

const statusColorOk = 0xFF7A8B73;
const statusColorMaintenance = 0xFFEAB308;
const statusColorMissing = 0xFF9CA3AF;

const schemaAssetPath = <String, String>{
  'road': 'assets/garage/silhouettes/road.svg',
  'gravel': 'assets/garage/silhouettes/gravel.svg',
  'mtb': 'assets/garage/silhouettes/mtb.svg',
  'city': 'assets/garage/silhouettes/city.svg',
  'mtb_trail': 'assets/garage/silhouettes/mtb_trail.svg',
  'mtb_am': 'assets/garage/silhouettes/mtb_am.svg',
  'mtb_enduro': 'assets/garage/silhouettes/mtb_enduro.svg',
  'dh': 'assets/garage/silhouettes/dh.svg',
  'emtb': 'assets/garage/silhouettes/emtb.svg',
  'urban': 'assets/garage/silhouettes/urban.svg',
  'etrekking': 'assets/garage/silhouettes/etrekking.svg',
  'cargo': 'assets/garage/silhouettes/cargo.svg',
  'folding': 'assets/garage/silhouettes/folding.svg',
  'kids': 'assets/garage/silhouettes/kids.svg',
  'hiking': 'assets/garage/silhouettes/hiking.svg',
};

const schemaHotspots = <String, Map<String, SchemaAnchor>>{
  'road': {
    'tire_front': SchemaAnchor(cx: 220.0, cy: 420.0, hitR: 28.0, labelDe: 'Vorderrad'),
    'fork': SchemaAnchor(cx: 254.0, cy: 289.0, hitR: 28.0, labelDe: 'Gabel'),
    'brake_front': SchemaAnchor(cx: 242.0, cy: 365.0, hitR: 28.0, labelDe: 'Vorderradbremse'),
    'handlebar': SchemaAnchor(cx: 232.0, cy: 128.0, hitR: 28.0, labelDe: 'Lenker'),
    'stem': SchemaAnchor(cx: 260.0, cy: 143.0, hitR: 28.0, labelDe: 'Vorbau'),
    'frame': SchemaAnchor(cx: 365.3, cy: 227.3, hitR: 28.0, labelDe: 'Rahmen'),
    'seatpost': SchemaAnchor(cx: 408.0, cy: 262.0, hitR: 28.0, labelDe: 'Sattelstütze'),
    'saddle': SchemaAnchor(cx: 418.0, cy: 130.0, hitR: 28.0, labelDe: 'Sattel'),
    'crankset': SchemaAnchor(cx: 400.0, cy: 372.0, hitR: 28.0, labelDe: 'Kurbel'),
    'chain': SchemaAnchor(cx: 502.0, cy: 394.0, hitR: 28.0, labelDe: 'Kette'),
    'cassette': SchemaAnchor(cx: 618.0, cy: 408.0, hitR: 28.0, labelDe: 'Kassette'),
    'tire_rear': SchemaAnchor(cx: 604.0, cy: 420.0, hitR: 28.0, labelDe: 'Hinterrad'),
    'brake_rear': SchemaAnchor(cx: 576.0, cy: 362.0, hitR: 28.0, labelDe: 'Hinterradbremse'),
    'motor': SchemaAnchor(cx: 354.0, cy: 354.0, hitR: 28.0, labelDe: 'Motor'),
    'battery': SchemaAnchor(cx: 364.0, cy: 275.0, hitR: 28.0, labelDe: 'Akku'),
  },
  'gravel': {
    'tire_front': SchemaAnchor(cx: 220.0, cy: 420.0, hitR: 28.0, labelDe: 'Vorderrad'),
    'fork': SchemaAnchor(cx: 256.0, cy: 290.0, hitR: 28.0, labelDe: 'Gabel'),
    'brake_front': SchemaAnchor(cx: 242.0, cy: 365.0, hitR: 28.0, labelDe: 'Vorderradbremse'),
    'handlebar': SchemaAnchor(cx: 248.0, cy: 138.0, hitR: 28.0, labelDe: 'Lenker'),
    'stem': SchemaAnchor(cx: 270.0, cy: 149.0, hitR: 28.0, labelDe: 'Vorbau'),
    'frame': SchemaAnchor(cx: 368.0, cy: 229.0, hitR: 28.0, labelDe: 'Rahmen'),
    'seatpost': SchemaAnchor(cx: 412.0, cy: 263.5, hitR: 28.0, labelDe: 'Sattelstütze'),
    'saddle': SchemaAnchor(cx: 422.0, cy: 133.0, hitR: 28.0, labelDe: 'Sattel'),
    'crankset': SchemaAnchor(cx: 400.0, cy: 372.0, hitR: 28.0, labelDe: 'Kurbel'),
    'chain': SchemaAnchor(cx: 512.0, cy: 394.0, hitR: 28.0, labelDe: 'Kette'),
    'cassette': SchemaAnchor(cx: 638.0, cy: 408.0, hitR: 28.0, labelDe: 'Kassette'),
    'tire_rear': SchemaAnchor(cx: 624.0, cy: 420.0, hitR: 28.0, labelDe: 'Hinterrad'),
    'brake_rear': SchemaAnchor(cx: 596.0, cy: 362.0, hitR: 28.0, labelDe: 'Hinterradbremse'),
    'motor': SchemaAnchor(cx: 356.0, cy: 354.0, hitR: 28.0, labelDe: 'Motor'),
    'battery': SchemaAnchor(cx: 366.0, cy: 276.0, hitR: 28.0, labelDe: 'Akku'),
  },
  'mtb': {
    'tire_front': SchemaAnchor(cx: 220.0, cy: 420.0, hitR: 28.0, labelDe: 'Vorderrad'),
    'fork': SchemaAnchor(cx: 269.0, cy: 297.5, hitR: 28.0, labelDe: 'Gabel'),
    'brake_front': SchemaAnchor(cx: 242.0, cy: 365.0, hitR: 28.0, labelDe: 'Vorderradbremse'),
    'handlebar': SchemaAnchor(cx: 298.0, cy: 168.0, hitR: 28.0, labelDe: 'Lenker'),
    'stem': SchemaAnchor(cx: 308.0, cy: 171.5, hitR: 28.0, labelDe: 'Vorbau'),
    'frame': SchemaAnchor(cx: 382.7, cy: 231.7, hitR: 28.0, labelDe: 'Rahmen'),
    'seatpost': SchemaAnchor(cx: 430.0, cy: 260.0, hitR: 28.0, labelDe: 'Sattelstütze'),
    'saddle': SchemaAnchor(cx: 440.0, cy: 126.0, hitR: 28.0, labelDe: 'Sattel'),
    'crankset': SchemaAnchor(cx: 400.0, cy: 372.0, hitR: 28.0, labelDe: 'Kurbel'),
    'chain': SchemaAnchor(cx: 545.0, cy: 394.0, hitR: 28.0, labelDe: 'Kette'),
    'cassette': SchemaAnchor(cx: 704.0, cy: 408.0, hitR: 28.0, labelDe: 'Kassette'),
    'tire_rear': SchemaAnchor(cx: 690.0, cy: 420.0, hitR: 28.0, labelDe: 'Hinterrad'),
    'brake_rear': SchemaAnchor(cx: 662.0, cy: 362.0, hitR: 28.0, labelDe: 'Hinterradbremse'),
    'rear_shock': SchemaAnchor(cx: 457.0, cy: 224.0, hitR: 28.0, labelDe: 'Dämpfer'),
    'motor': SchemaAnchor(cx: 369.0, cy: 354.0, hitR: 28.0, labelDe: 'Motor'),
    'battery': SchemaAnchor(cx: 379.0, cy: 283.5, hitR: 28.0, labelDe: 'Akku'),
  },
  'city': {
    'tire_front': SchemaAnchor(cx: 220.0, cy: 420.0, hitR: 28.0, labelDe: 'Vorderrad'),
    'fork': SchemaAnchor(cx: 257.0, cy: 282.5, hitR: 28.0, labelDe: 'Gabel'),
    'brake_front': SchemaAnchor(cx: 242.0, cy: 365.0, hitR: 28.0, labelDe: 'Vorderradbremse'),
    'handlebar': SchemaAnchor(cx: 258.0, cy: 105.0, hitR: 28.0, labelDe: 'Lenker'),
    'stem': SchemaAnchor(cx: 276.0, cy: 125.0, hitR: 28.0, labelDe: 'Vorbau'),
    'frame': SchemaAnchor(cx: 370.7, cy: 212.3, hitR: 28.0, labelDe: 'Rahmen'),
    'seatpost': SchemaAnchor(cx: 418.0, cy: 246.0, hitR: 28.0, labelDe: 'Sattelstütze'),
    'saddle': SchemaAnchor(cx: 428.0, cy: 98.0, hitR: 28.0, labelDe: 'Sattel'),
    'crankset': SchemaAnchor(cx: 400.0, cy: 372.0, hitR: 28.0, labelDe: 'Kurbel'),
    'chain': SchemaAnchor(cx: 525.0, cy: 394.0, hitR: 28.0, labelDe: 'Kette'),
    'cassette': SchemaAnchor(cx: 664.0, cy: 408.0, hitR: 28.0, labelDe: 'Kassette'),
    'tire_rear': SchemaAnchor(cx: 650.0, cy: 420.0, hitR: 28.0, labelDe: 'Hinterrad'),
    'brake_rear': SchemaAnchor(cx: 622.0, cy: 362.0, hitR: 28.0, labelDe: 'Hinterradbremse'),
    'motor': SchemaAnchor(cx: 357.0, cy: 354.0, hitR: 28.0, labelDe: 'Motor'),
    'battery': SchemaAnchor(cx: 367.0, cy: 268.5, hitR: 28.0, labelDe: 'Akku'),
  },
};

const schemaLayers = <String, Map<String, SchemaLayer>>{
  'road': {
    'motor': SchemaRectLayer(x: 372.0, y: 334.0, width: 56.0, height: 32.0, rx: 6.0, fill: '#FF6A00'),
    'battery': SchemaRectLayer(x: 334.0, y: 245.0, width: 44.0, height: 22.0, rx: 4.0, fill: '#7A8B73'),
  },
  'gravel': {
    'motor': SchemaRectLayer(x: 372.0, y: 334.0, width: 56.0, height: 32.0, rx: 6.0, fill: '#FF6A00'),
    'battery': SchemaRectLayer(x: 336.0, y: 246.0, width: 44.0, height: 22.0, rx: 4.0, fill: '#7A8B73'),
  },
  'mtb': {
    'rear_shock': SchemaLineLayer(x1: 432.0, y1: 198.0, x2: 482.0, y2: 350.0, stroke: '#FF6A00', strokeWidth: 10.0),
    'motor': SchemaRectLayer(x: 372.0, y: 334.0, width: 56.0, height: 32.0, rx: 6.0, fill: '#FF6A00'),
    'battery': SchemaRectLayer(x: 349.0, y: 253.5, width: 44.0, height: 22.0, rx: 4.0, fill: '#7A8B73'),
  },
  'city': {
    'motor': SchemaRectLayer(x: 372.0, y: 334.0, width: 56.0, height: 32.0, rx: 6.0, fill: '#FF6A00'),
    'battery': SchemaRectLayer(x: 337.0, y: 238.5, width: 44.0, height: 22.0, rx: 4.0, fill: '#7A8B73'),
  },
};

const hikingAnchors = <String, SchemaAnchor>{
  'hiking_shoes': SchemaAnchor(cx: 280, cy: 380, hitR: 28, labelDe: 'Schuhe'),
  'hiking_pack': SchemaAnchor(cx: 500, cy: 200, hitR: 28, labelDe: 'Rucksack'),
  'hiking_poles': SchemaAnchor(cx: 720, cy: 280, hitR: 28, labelDe: 'Stöcke'),
};
