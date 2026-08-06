import type { CatalogManufacturer } from "@/types/garage";
import imported from "./imported.json";

/**
 * OEM-Bike-Katalog für F-GAR-001 Weg 1 (Hersteller → Modell → Jahr → Variante).
 * Vorbefüllung der Komponenten aus OEM-Ausstattung.
 * Zusätzliche Hersteller: `npm run catalog:import` → imported.json
 */
const BASE_CATALOG: CatalogManufacturer[] = [
  {
    id: "mfr-transition",
    name: "Transition",
    bikes: [
      {
        id: "cat-transition-spire-2024",
        name: "Spire",
        year: 2024,
        frameSizeOptions: ["S", "M", "L", "XL"],
        category: "mtb_enduro",
        travelFrontMm: 170,
        travelRearMm: 170,
        wheelSizeFront: "29",
        wheelSizeRear: "29",
        isEbike: false,
        weightKgApprox: 15.8,
        oemComponents: {
          frame: "cm-transition-spire-frame",
          fork: "cm-fox-36-factory-170",
          rear_shock: "cm-fox-float-x2-20565",
          headset: "cm-cane-creek-zs44-zs56",
          stem: "cm-renthal-apex-35",
          handlebar: "cm-renthal-fatbar-35",
          grips: "cm-odey-grips",
          seatpost: "cm-oneup-v3-dropper-31-6",
          saddle: "cm-sdg-belair",
          front_hub: "cm-dt-350-boost-front",
          rear_hub: "cm-dt-350-boost-rear-xd",
          front_rim: "cm-dt-xm1700-rim-front",
          rear_rim: "cm-dt-xm1700-rim-rear",
          tire_front: "cm-maxxis-assegai-29-25",
          tire_rear: "cm-maxxis-dhr2-29-24",
          cassette: "cm-sram-x0-cassette-xd",
          chain: "cm-sram-gx-chain",
          crankset: "cm-sram-x0-crank-dub",
          chainring: "cm-sram-x0-chainring-32",
          rear_derailleur: "cm-sram-x0-rd",
          shifter: "cm-sram-pod-controller",
          bottom_bracket: "cm-sram-dub-bsa73",
          brake_front: "cm-sram-code-rsc-front",
          brake_rear: "cm-sram-code-rsc-rear",
          rotor_front: "cm-sram-hs2-200-front",
          rotor_rear: "cm-sram-hs2-180-rear",
          brake_pads_front: "cm-sram-organic-pads",
          brake_pads_rear: "cm-sram-organic-pads-rear",
          pedals: "cm-ht-components-pedals",
        },
        frameAttributes: [],
        sourceUrl: "https://www.transitionbikes.com/",
      },
    ],
  },
  {
    id: "mfr-canyon",
    name: "Canyon",
    bikes: [
      {
        id: "cat-canyon-spectralon-2024",
        name: "Spectral:ON CF 8",
        year: 2024,
        frameSizeOptions: ["S", "M", "L", "XL"],
        category: "emtb",
        travelFrontMm: 160,
        travelRearMm: 150,
        wheelSizeFront: "29",
        wheelSizeRear: "29",
        isEbike: true,
        weightKgApprox: 23.5,
        oemComponents: {
          frame: "cm-canyon-spectralon-cf-frame",
          fork: "cm-rockshox-lyrik-160",
          rear_shock: "cm-rockshox-superdeluxe-23065",
          headset: "cm-cane-creek-zs44-zs56",
          stem: "cm-renthal-apex-35",
          handlebar: "cm-renthal-fatbar-35",
          grips: "cm-odey-grips",
          seatpost: "cm-oneup-v3-dropper-34-9",
          saddle: "cm-sdg-belair",
          front_hub: "cm-dt-350-boost-front",
          rear_hub: "cm-dt-350-boost-rear-xd",
          front_rim: "cm-dt-xm1700-rim-front",
          rear_rim: "cm-dt-xm1700-rim-rear",
          tire_front: "cm-maxxis-assegai-29-25",
          tire_rear: "cm-maxxis-dhr2-29-24",
          cassette: "cm-sram-x0-cassette-xd",
          chain: "cm-sram-gx-chain",
          crankset: "cm-sram-x0-crank-dub",
          chainring: "cm-sram-x0-chainring-32",
          rear_derailleur: "cm-sram-x0-rd",
          shifter: "cm-sram-pod-controller",
          bottom_bracket: "cm-sram-dub-bsa73",
          brake_front: "cm-sram-code-rsc-front",
          brake_rear: "cm-sram-code-rsc-rear",
          rotor_front: "cm-sram-hs2-200-front",
          rotor_rear: "cm-sram-hs2-180-rear",
          brake_pads_front: "cm-sram-organic-pads",
          brake_pads_rear: "cm-sram-organic-pads-rear",
          pedals: "cm-ht-components-pedals",
          motor: "cm-bosch-cx-gen5",
          battery: "cm-bosch-powertube-800",
          display: "cm-bosch-kiox-300",
        },
        frameAttributes: [],
        sourceUrl: "https://www.canyon.com/",
      },
    ],
  },
  {
    id: "mfr-specialized",
    name: "Specialized",
    bikes: [
      {
        id: "cat-specialized-diverge-2023",
        name: "Diverge Carbon",
        year: 2023,
        frameSizeOptions: ["49", "52", "54", "56", "58"],
        category: "gravel",
        travelFrontMm: 0,
        travelRearMm: 0,
        wheelSizeFront: "700c",
        wheelSizeRear: "700c",
        isEbike: false,
        weightKgApprox: 9.2,
        oemComponents: {
          frame: "cm-specialized-diverge-frame",
          tire_front: "cm-pathfinder-pro-700-42",
          tire_rear: "cm-pathfinder-pro-700-42",
        },
        frameAttributes: [],
        sourceUrl: "https://www.specialized.com/",
      },
    ],
  },
];

export const BIKE_CATALOG: CatalogManufacturer[] = [
  ...BASE_CATALOG,
  ...((imported.manufacturers || []) as CatalogManufacturer[]),
];

export function findCatalogBike(id: string) {
  for (const m of BIKE_CATALOG) {
    const bike = m.bikes.find((b) => b.id === id);
    if (bike) return { manufacturer: m, bike };
  }
  return undefined;
}

export function listCatalogManufacturers() {
  return BIKE_CATALOG;
}
