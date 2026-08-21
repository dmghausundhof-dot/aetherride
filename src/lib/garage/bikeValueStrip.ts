/** Shared strip helpers — keep in sync with mobile/lib/domain/garage/bike_value_strip_plan.dart */

export function formatStripCount(
  value: number,
  dash: string,
  decimals = 0
): string {
  if (!Number.isFinite(value) || value <= 0) return dash;
  return decimals === 0 ? String(Math.round(value)) : value.toFixed(decimals);
}

/** Same day.month.year as App BikeOwner.formatDate — compact on the strip. */
export function formatStripDate(iso: string): string {
  const p = iso.trim().split("-");
  if (p.length !== 3) return iso.trim();
  return `${p[2]}.${p[1]}.${p[0]}`;
}

export type StripServiceKind = "appointment" | "care" | "empty";
export type StripIntervalStatus = "overdue" | "due_soon";

export function planStripService(input: {
  appointmentLabel?: string | null;
  intervalStatus?: StripIntervalStatus | null;
  intervalRemaining?: string | null;
  appointmentCaption: string;
  careCaption: string;
  dueNow: string;
  dash: string;
}): { kind: StripServiceKind; caption: string; value: string } {
  const appt = input.appointmentLabel?.trim();
  if (appt) {
    return {
      kind: "appointment",
      caption: input.appointmentCaption,
      value: appt,
    };
  }
  if (input.intervalStatus === "overdue") {
    return {
      kind: "care",
      caption: input.careCaption,
      value: input.dueNow,
    };
  }
  const rem = input.intervalRemaining?.trim();
  if (input.intervalStatus === "due_soon" && rem) {
    return {
      kind: "care",
      caption: input.careCaption,
      value: rem.split(" · ")[0] ?? rem,
    };
  }
  return {
    kind: "empty",
    caption: input.appointmentCaption,
    value: input.dash,
  };
}
