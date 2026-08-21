"use client";

import { useState } from "react";
import { useAppStore } from "@/store/useAppStore";
import { useChromeLang } from "@/hooks/useChromeLang";
import { bikeIdentityCopy } from "@/lib/i18n/bikeIdentityCopy";
import {
  formatIdentityDate,
  identityIsEmpty,
  normalizeBikeIdentity,
} from "@/lib/garage/bikeIdentity";
import { RadGlyph } from "@/components/garage/RadGlyph";
import { bikeTechRows } from "@/lib/garage/bikeTech";
import { RAD_STAND_GROUND } from "@/lib/garage/radMark";
import type { Bike } from "@/types";

export function BikeIdentityCard({ bike }: { bike: Bike }) {
  const lang = useChromeLang();
  const copy = bikeIdentityCopy(lang);
  const updateBike = useAppStore((s) => s.updateBike);
  const [open, setOpen] = useState(false);
  const [copied, setCopied] = useState(false);
  const [techOpen, setTechOpen] = useState(false);

  const tech = bikeTechRows(bike, copy);
  const empty =
    identityIsEmpty(bike) && !bike.year && !bike.frameSize && tech.length === 0;

  const rows: [string, string][] = [];
  if (bike.year) rows.push([copy.year, String(bike.year)]);
  if (bike.frameSize) rows.push([copy.frameSize, bike.frameSize]);
  if (bike.color) rows.push([copy.color, bike.color]);
  if (bike.weightKg != null) rows.push([copy.weight, bike.weightKg.toFixed(1)]);
  if (bike.purchasedAt) rows.push([copy.purchasedAt, formatIdentityDate(bike.purchasedAt)]);
  if (bike.purchasedFrom) rows.push([copy.purchasedFrom, bike.purchasedFrom]);
  if (bike.purchasePriceEur != null) {
    rows.push([copy.price, `${bike.purchasePriceEur.toFixed(0)} €`]);
  }
  if (bike.insuranceName) rows.push([copy.insurance, bike.insuranceName]);
  if (bike.insurancePolicy) rows.push([copy.policy, bike.insurancePolicy]);
  if (bike.keyNumber) rows.push([copy.keyNumber, bike.keyNumber]);
  if (bike.notes) rows.push([copy.notes, bike.notes]);

  const copySerial = async () => {
    if (!bike.serialNumber) return;
    try {
      await navigator.clipboard.writeText(bike.serialNumber);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1600);
    } catch {
      /* clipboard may be blocked */
    }
  };

  return (
    <section
      data-testid="bike-identity-card"
      className="rounded-2xl border border-border bg-surface p-4"
    >
      <div className="flex items-start justify-between gap-3">
        <div>
          <h3 className="flex items-center gap-2 text-sm font-semibold">
            <RadGlyph name="identity" size={16} />
            {copy.title}
          </h3>
          <p className="mt-0.5 text-xs text-text-secondary">{copy.hint}</p>
        </div>
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="shrink-0 rounded-xl border border-border px-3 py-1.5 text-xs font-semibold hover:border-chrome/40"
        >
          {empty ? copy.add : copy.edit}
        </button>
      </div>

      {empty ? (
        <div className="relative mt-3 overflow-hidden rounded-xl border border-dashed border-border px-3 py-4">
          <img
            src={RAD_STAND_GROUND}
            alt=""
            className="pointer-events-none absolute inset-0 h-full w-full object-cover opacity-40"
            draggable={false}
          />
          <p className="relative text-sm text-text-secondary">{copy.empty}</p>
        </div>
      ) : (
        <div className="mt-3 space-y-2">
          {bike.serialNumber ? (
            <div className="relative overflow-hidden rounded-xl bg-[#121215] px-3 py-2.5">
              <img
                src={RAD_STAND_GROUND}
                alt=""
                className="pointer-events-none absolute inset-0 h-full w-full object-cover opacity-50"
                draggable={false}
              />
              <div className="relative flex items-center gap-2">
              <code className="flex-1 break-all text-base font-bold tracking-wide text-[#F4F1EC]">
                {bike.serialNumber}
              </code>
              <button
                type="button"
                onClick={() => void copySerial()}
                className="rounded-lg border border-white/15 px-2 py-1 text-[11px] font-semibold text-[#F4F1EC]/80 hover:border-chrome/60"
              >
                {copied ? copy.serialCopied : copy.serial}
              </button>
              </div>
            </div>
          ) : null}
          {rows.map(([k, v]) => (
            <div key={k} className="flex justify-between gap-3 text-xs">
              <dt className="text-text-secondary">{k}</dt>
              <dd className="text-right font-medium">{v}</dd>
            </div>
          ))}
          {(() => {
            if (tech.length === 0) return null;
            return (
              <div className="border-t border-border pt-2">
                <button
                  type="button"
                  onClick={() => setTechOpen((v) => !v)}
                  className="flex w-full items-center justify-between text-left text-sm font-semibold"
                >
                  {copy.techDetails}
                  <span className="text-xs font-normal text-text-secondary">
                    {techOpen ? "×" : copy.techHint}
                  </span>
                </button>
                {techOpen ? (
                  <dl className="mt-2 space-y-1.5">
                    {tech.map(([k, v]) => (
                      <div key={k} className="flex justify-between gap-3 text-xs">
                        <dt className="text-text-secondary">{k}</dt>
                        <dd className="font-medium tabular-nums">{v}</dd>
                      </div>
                    ))}
                  </dl>
                ) : null}
              </div>
            );
          })()}
        </div>
      )}
      <p className="mt-3 text-[11px] text-text-secondary">{copy.privateHint}</p>

      {open ? (
        <IdentityEditor bike={bike} onClose={() => setOpen(false)} onSave={updateBike} />
      ) : null}
    </section>
  );
}

function IdentityEditor({
  bike,
  onClose,
  onSave,
}: {
  bike: Bike;
  onClose: () => void;
  onSave: (id: string, data: Partial<Bike>) => void;
}) {
  const lang = useChromeLang();
  const copy = bikeIdentityCopy(lang);
  const [name, setName] = useState(bike.name);
  const [year, setYear] = useState(bike.year?.toString() ?? "");
  const [frameSize, setFrameSize] = useState(bike.frameSize ?? "");
  const [serial, setSerial] = useState(bike.serialNumber ?? "");
  const [color, setColor] = useState(bike.color ?? "");
  const [weight, setWeight] = useState(bike.weightKg?.toString() ?? "");
  const [purchasedAt, setPurchasedAt] = useState(bike.purchasedAt ?? "");
  const [purchasedFrom, setPurchasedFrom] = useState(bike.purchasedFrom ?? "");
  const [price, setPrice] = useState(bike.purchasePriceEur?.toString() ?? "");
  const [insurance, setInsurance] = useState(bike.insuranceName ?? "");
  const [policy, setPolicy] = useState(bike.insurancePolicy ?? "");
  const [keyNumber, setKeyNumber] = useState(bike.keyNumber ?? "");
  const [notes, setNotes] = useState(bike.notes ?? "");
  const [photoUrl, setPhotoUrl] = useState(
    bike.photoUrl?.startsWith("http") ? bike.photoUrl : ""
  );

  const save = () => {
    const yearN = Number(year);
    const id = normalizeBikeIdentity({
      serialNumber: serial,
      color,
      weightKg: weight ? Number(weight.replace(",", ".")) : undefined,
      notes,
      purchasedAt,
      purchasedFrom,
      purchasePriceEur: price ? Number(price.replace(",", ".")) : undefined,
      insuranceName: insurance,
      insurancePolicy: policy,
      keyNumber,
    });
    onSave(bike.id, {
      name: name.trim() || bike.name,
      year: Number.isFinite(yearN) && yearN >= 1980 ? yearN : undefined,
      frameSize: frameSize.trim() || undefined,
      photoUrl: photoUrl.trim() || undefined,
      ...id,
    });
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/50 p-4 sm:items-center">
      <div
        role="dialog"
        aria-label={copy.edit}
        className="max-h-[90vh] w-full max-w-md overflow-y-auto rounded-2xl border border-border bg-surface p-4"
      >
        <h3 className="text-base font-semibold">{copy.edit}</h3>
        <p className="mt-1 text-xs text-text-secondary">{copy.hint}</p>
        <div className="mt-3 grid gap-2">
          <Field label={copy.name} value={name} onChange={setName} />
          <div className="grid grid-cols-2 gap-2">
            <Field label={copy.year} value={year} onChange={setYear} type="number" />
            <Field label={copy.frameSize} value={frameSize} onChange={setFrameSize} />
          </div>
          <Field label={copy.serial} value={serial} onChange={setSerial} hint={copy.serialHint} />
          <div className="grid grid-cols-2 gap-2">
            <Field label={copy.color} value={color} onChange={setColor} />
            <Field label={copy.weight} value={weight} onChange={setWeight} />
          </div>
          <Field label={copy.purchasedAt} value={purchasedAt} onChange={setPurchasedAt} type="date" />
          <Field label={copy.purchasedFrom} value={purchasedFrom} onChange={setPurchasedFrom} />
          <Field label={copy.price} value={price} onChange={setPrice} />
          <Field label={copy.insurance} value={insurance} onChange={setInsurance} />
          <Field label={copy.policy} value={policy} onChange={setPolicy} />
          <Field label={copy.keyNumber} value={keyNumber} onChange={setKeyNumber} />
          <Field
            label={copy.photoUrl}
            value={photoUrl}
            onChange={setPhotoUrl}
            hint={copy.photoUrlHint}
          />
          <label className="text-sm">
            {copy.notes}
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={3}
              className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
            />
          </label>
        </div>
        <p className="mt-2 text-[11px] text-text-secondary">{copy.privateHint}</p>
        <div className="mt-4 flex justify-end gap-2">
          <button
            type="button"
            onClick={onClose}
            className="rounded-xl px-3 py-2 text-sm text-text-secondary"
          >
            ×
          </button>
          <button
            type="button"
            onClick={save}
            className="rounded-xl bg-accent px-4 py-2 text-sm font-semibold text-on-accent"
          >
            {copy.save}
          </button>
        </div>
      </div>
    </div>
  );
}

function Field({
  label,
  value,
  onChange,
  type = "text",
  hint,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  type?: string;
  hint?: string;
}) {
  return (
    <label className="text-sm">
      {label}
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
      />
      {hint ? <span className="mt-0.5 block text-[11px] text-text-secondary">{hint}</span> : null}
    </label>
  );
}
