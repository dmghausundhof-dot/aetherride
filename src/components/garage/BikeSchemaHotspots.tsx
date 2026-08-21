"use client";

import { planBikeSchema } from "@/lib/garage/schema/mapper";
import {
  schemaHiddenOpenCount,
  schemaHotspotQuiet,
  schemaInviteSlots,
} from "@/lib/garage/schema/invites";
import {
  SCHEMA_ASSET_PATH,
  SCHEMA_DOT_R,
  SCHEMA_HOTSPOTS,
  SCHEMA_VIEWBOX_H,
  SCHEMA_VIEWBOX_W,
  STATUS_COLORS,
  schemaFamilyOf,
  type HotspotStatus,
} from "@/lib/garage/schema/anchors";
import { slotLabel } from "@/lib/catalog/slots";
import { RAD_STAND_GROUND, RAD_STAND_HEADER } from "@/lib/garage/radMark";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import type { Bike, ComponentSlot } from "@/types";

export function BikeSchemaHotspots({
  bike,
  dueSlots = [],
  onTapSlot,
}: {
  bike: Bike;
  dueSlots?: ComponentSlot[];
  onTapSlot?: (slot: ComponentSlot) => void;
}) {
  const copy = useHofCopy();
  const lang = useChromeLang();
  const hasShock = bike.components.some(
    (c) => c.slot === "rear_shock" && !c.removedAt
  );
  const plan = planBikeSchema({
    category: bike.category,
    isEbike: bike.isEbike,
    hasRearShock: (bike.travelRearMm ?? 0) > 0 || hasShock,
  });
  if (!plan.template) return null;
  const src = SCHEMA_ASSET_PATH[plan.template];
  const anchors = SCHEMA_HOTSPOTS[schemaFamilyOf(plan.template)];
  const installed = new Set(
    bike.components.filter((c) => !c.removedAt).map((c) => c.slot)
  );
  const due = new Set(dueSlots);

  return (
    <div className="space-y-2" data-testid="bike-schema-hotspots">
      <p className="text-xs text-text-secondary">
        {copy.workshopSchemaHint}
      </p>
      <div className="flex flex-wrap gap-3 text-[11px] text-text-secondary">
        <span className="inline-flex items-center gap-1">
          <span
            className="inline-block h-2 w-2 rounded-full"
            style={{ background: STATUS_COLORS.ok }}
          />
          {copy.workshopSchemaLegendOk}
        </span>
        <span className="inline-flex items-center gap-1">
          <span
            className="inline-block h-2 w-2 rounded-full"
            style={{ background: STATUS_COLORS.missing }}
          />
          {copy.workshopSchemaLegendOpen}
        </span>
        <span className="inline-flex items-center gap-1">
          <span
            className="inline-block h-2 w-2 rounded-full"
            style={{ background: STATUS_COLORS.maintenance }}
          />
          {copy.workshopSchemaLegendDue}
        </span>
      </div>
      <div
        className="relative overflow-hidden rounded-2xl bg-[#121215]"
        data-testid="bike-schema-stage"
        style={{
          aspectRatio: `${SCHEMA_VIEWBOX_W} / ${SCHEMA_VIEWBOX_H}`,
        }}
      >
        <img
          src={RAD_STAND_GROUND}
          alt=""
          className="pointer-events-none absolute inset-0 h-full w-full object-cover"
          draggable={false}
        />
        <div
          className="absolute inset-2 overflow-hidden rounded-xl"
          style={{ background: "#F4F1EA" }}
        >
          <img
            src={src}
            alt=""
            className="pointer-events-none h-full w-full object-contain p-1"
            draggable={false}
          />
          {plan.hotspotSlots.map((slot) => {
            const a = anchors[slot];
            if (!a) return null;
            const status: HotspotStatus = due.has(slot)
              ? "maintenance"
              : installed.has(slot)
                ? "ok"
                : "missing";
            const quiet = schemaHotspotQuiet(slot, status);
            const dot = quiet ? SCHEMA_DOT_R * 0.62 : SCHEMA_DOT_R;
            return (
              <button
                key={slot}
                type="button"
                title={slotLabel(slot, lang)}
                aria-label={slotLabel(slot, lang)}
                onClick={() => onTapSlot?.(slot)}
                className="absolute -translate-x-1/2 -translate-y-1/2 rounded-full"
                style={{
                  left: `${(a.cx / SCHEMA_VIEWBOX_W) * 100}%`,
                  top: `${(a.cy / SCHEMA_VIEWBOX_H) * 100}%`,
                  width: 44,
                  height: 44,
                }}
              >
                <span
                  className="mx-auto mt-[18px] block rounded-full border border-zinc-900"
                  style={{
                    width: dot,
                    height: dot,
                    background: quiet ? "#C4BDB0" : STATUS_COLORS[status],
                    opacity: quiet ? 0.55 : 1,
                  }}
                />
              </button>
            );
          })}
        </div>
        <img
          src={RAD_STAND_HEADER}
          alt=""
          width={240}
          height={24}
          className="pointer-events-none absolute bottom-1 left-3 h-3.5 w-24"
          draggable={false}
        />
      </div>
      {(() => {
        const invite = schemaInviteSlots({
          hotspotSlots: plan.hotspotSlots,
          installed,
          due,
        });
        if (invite.length === 0) return null;
        const hidden = schemaHiddenOpenCount({
          hotspotSlots: plan.hotspotSlots,
          installed,
          due,
        });
        return (
          <div className="space-y-1">
            <div className="flex flex-wrap gap-1.5">
              {invite.map((slot) => (
                <button
                  key={`open-${slot}`}
                  type="button"
                  onClick={() => onTapSlot?.(slot)}
                  className="min-h-11 rounded-full border border-border px-2.5 py-1 text-[11px] font-semibold text-text-secondary"
                >
                  {slotLabel(slot, lang)}
                </button>
              ))}
            </div>
            {hidden > 0 ? (
              <p className="text-[11px] text-text-secondary">
                {copy.workshopSchemaMoreOnDots}
              </p>
            ) : null}
          </div>
        );
      })()}
    </div>
  );
}
