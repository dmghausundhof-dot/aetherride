import { catalogGeometryForSize } from "@/lib/catalog/bikes";
import type { BikeIdentityCopy } from "@/lib/i18n/bikeIdentityCopy";
import type { Bike } from "@/types";

/** Travel, wheels, catalog geometry — lived in BikeSchema, now on the Ausweis. */
export function bikeTechRows(
  bike: Bike,
  copy: BikeIdentityCopy
): [string, string][] {
  const rows: [string, string][] = [];
  if (bike.wheelSizeFront || bike.wheelSizeRear) {
    rows.push([
      copy.wheels,
      [bike.wheelSizeFront, bike.wheelSizeRear].filter(Boolean).join(" / "),
    ]);
  }
  if (bike.travelFrontMm != null) {
    rows.push([
      copy.travel,
      `${bike.travelFrontMm}/${bike.travelRearMm ?? "–"} mm`,
    ]);
  }
  const geo = catalogGeometryForSize(bike.catalogBikeId ?? "", bike.frameSize);
  if (geo) {
    rows.push(["Reach", `${geo.reachMm} mm`]);
    rows.push(["Stack", `${geo.stackMm} mm`]);
    if (geo.headAngleDeg != null) {
      rows.push([copy.headAngle, `${geo.headAngleDeg}°`]);
    }
    if (geo.chainstayMm != null) {
      rows.push([copy.chainstay, `${geo.chainstayMm} mm`]);
    }
    if (geo.wheelbaseMm != null) {
      rows.push([copy.wheelbase, `${geo.wheelbaseMm} mm`]);
    }
    if (geo.setting) rows.push([copy.geoSetting, geo.setting]);
  }
  if (bike.totalHours > 0) {
    rows.push([copy.hours, bike.totalHours.toFixed(1)]);
  }
  return rows;
}
