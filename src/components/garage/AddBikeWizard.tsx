"use client";

import { useMemo, useState } from "react";
import { listCatalogManufacturers } from "@/lib/catalog/bikes";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { useAppStore } from "@/store/useAppStore";
import type { BikeCategory, WheelSize } from "@/types";
import { X } from "lucide-react";

type Mode = "catalog" | "basic" | "import";

const CATEGORIES: BikeCategory[] = [
  "mtb_trail",
  "mtb_am",
  "mtb_enduro",
  "dh",
  "gravel",
  "road",
  "urban",
  "emtb",
  "etrekking",
  "hiking",
];

export function AddBikeWizard({ onClose }: { onClose: () => void }) {
  const addBikeFromCatalog = useAppStore((s) => s.addBikeFromCatalog);
  const addBikeBasic = useAppStore((s) => s.addBikeBasic);
  const addBikeFromImport = useAppStore((s) => s.addBikeFromImport);
  const manufacturers = useMemo(() => listCatalogManufacturers(), []);

  const [mode, setMode] = useState<Mode>("catalog");
  const [mfrId, setMfrId] = useState(manufacturers[0]?.id ?? "");
  const mfr = manufacturers.find((m) => m.id === mfrId);
  const [bikeId, setBikeId] = useState(mfr?.bikes[0]?.id ?? "");
  const catBike = mfr?.bikes.find((b) => b.id === bikeId);
  const [size, setSize] = useState(catBike?.frameSizeOptions[0] ?? "L");
  const [name, setName] = useState("");

  const [basicCategory, setBasicCategory] = useState<BikeCategory>("mtb_am");
  const [travelF, setTravelF] = useState(150);
  const [travelR, setTravelR] = useState(140);
  const [wheel, setWheel] = useState<WheelSize>("29");
  const [importNote, setImportNote] = useState("");

  const submit = () => {
    if (mode === "catalog" && bikeId) {
      addBikeFromCatalog({
        catalogBikeId: bikeId,
        frameSize: size,
        name: name || undefined,
      });
    } else if (mode === "basic") {
      addBikeBasic({
        name: name || "Mein Bike",
        category: basicCategory,
        travelFrontMm: travelF,
        travelRearMm: travelR,
        wheelSizeFront: wheel,
        wheelSizeRear: wheel,
        frameSize: size,
      });
    } else {
      addBikeFromImport({
        name: name || "Import-Bike",
        note: importNote || "GPX/FIT-Platzhalter ohne Komponenten",
      });
    }
    onClose();
  };

  return (
    <div className="fixed inset-0 z-[60] flex items-end justify-center bg-black/60 p-0 sm:items-center sm:p-4">
      <div className="max-h-[90dvh] w-full max-w-lg overflow-y-auto rounded-t-2xl border border-border bg-surface p-4 sm:rounded-2xl">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-bold">Bike anlegen</h2>
          <button type="button" onClick={onClose} className="touch-target p-2">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="mb-4 grid grid-cols-3 gap-2">
          {(
            [
              ["catalog", "Katalog"],
              ["basic", "Basis"],
              ["import", "Import"],
            ] as const
          ).map(([id, label]) => (
            <button
              key={id}
              type="button"
              onClick={() => setMode(id)}
              className={`rounded-xl px-2 py-2 text-sm font-medium ${
                mode === id
                  ? "bg-accent text-white"
                  : "bg-surface-elevated text-text-secondary"
              }`}
            >
              {label}
            </button>
          ))}
        </div>

        <p className="mb-3 text-xs text-text-secondary">
          {mode === "catalog" &&
            "OEM-Ausstattung wird vollständig vorbefüllt (F-GAR-001 Weg 1)."}
          {mode === "basic" &&
            "Kategorie + Federweg + Laufradgröße – Komponenten später ergänzen."}
          {mode === "import" &&
            "GPX/FIT erzeugt ein Platzhalter-Bike ohne Komponenten."}
        </p>

        <label className="mb-3 block text-sm">
          Name
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Optional"
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>

        {mode === "catalog" && (
          <div className="flex flex-col gap-3">
            <label className="text-sm">
              Hersteller
              <select
                value={mfrId}
                onChange={(e) => {
                  setMfrId(e.target.value);
                  const m = manufacturers.find((x) => x.id === e.target.value);
                  setBikeId(m?.bikes[0]?.id ?? "");
                  setSize(m?.bikes[0]?.frameSizeOptions[0] ?? "L");
                }}
                className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
              >
                {manufacturers.map((m) => (
                  <option key={m.id} value={m.id}>
                    {m.name}
                  </option>
                ))}
              </select>
            </label>
            <label className="text-sm">
              Modell / Jahr
              <select
                value={bikeId}
                onChange={(e) => {
                  setBikeId(e.target.value);
                  const b = mfr?.bikes.find((x) => x.id === e.target.value);
                  setSize(b?.frameSizeOptions[0] ?? "L");
                }}
                className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
              >
                {mfr?.bikes.map((b) => (
                  <option key={b.id} value={b.id}>
                    {b.name} ({b.year}) · {bikeCategoryLabel(b.category)}
                  </option>
                ))}
              </select>
            </label>
            <label className="text-sm">
              Rahmengröße
              <select
                value={size}
                onChange={(e) => setSize(e.target.value)}
                className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
              >
                {catBike?.frameSizeOptions.map((s) => (
                  <option key={s} value={s}>
                    {s}
                  </option>
                ))}
              </select>
            </label>
            {catBike && (
              <div className="rounded-xl bg-surface-elevated p-3 text-xs text-text-secondary">
                {catBike.travelFrontMm
                  ? `${catBike.travelFrontMm}/${catBike.travelRearMm} mm · `
                  : ""}
                {catBike.wheelSizeFront}
                {catBike.isEbike ? " · E-Bike" : ""} ·{" "}
                {Object.keys(catBike.oemComponents).length} OEM-Komponenten
              </div>
            )}
          </div>
        )}

        {mode === "basic" && (
          <div className="flex flex-col gap-3">
            <label className="text-sm">
              Kategorie
              <select
                value={basicCategory}
                onChange={(e) =>
                  setBasicCategory(e.target.value as BikeCategory)
                }
                className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
              >
                {CATEGORIES.map((c) => (
                  <option key={c} value={c}>
                    {bikeCategoryLabel(c)}
                  </option>
                ))}
              </select>
            </label>
            <div className="grid grid-cols-2 gap-2">
              <label className="text-sm">
                Federweg vorn
                <input
                  type="number"
                  value={travelF}
                  onChange={(e) => setTravelF(Number(e.target.value))}
                  className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
                />
              </label>
              <label className="text-sm">
                Federweg hinten
                <input
                  type="number"
                  value={travelR}
                  onChange={(e) => setTravelR(Number(e.target.value))}
                  className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
                />
              </label>
            </div>
            <label className="text-sm">
              Laufradgröße
              <select
                value={wheel}
                onChange={(e) => setWheel(e.target.value as WheelSize)}
                className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
              >
                <option value="29">29″</option>
                <option value="27_5">27,5″</option>
                <option value="700c">700c</option>
                <option value="650b">650b</option>
              </select>
            </label>
          </div>
        )}

        {mode === "import" && (
          <label className="block text-sm">
            Hinweis / Dateiname
            <textarea
              value={importNote}
              onChange={(e) => setImportNote(e.target.value)}
              rows={3}
              placeholder="z. B. tour-alps-2026.gpx"
              className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
            />
          </label>
        )}

        <button
          type="button"
          onClick={submit}
          className="mt-5 w-full rounded-xl bg-accent py-3 font-semibold text-white"
        >
          Bike erstellen
        </button>
      </div>
    </div>
  );
}
