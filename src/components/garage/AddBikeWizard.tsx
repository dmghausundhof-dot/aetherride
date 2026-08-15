"use client";

import { useMemo, useState } from "react";
import { listCatalogManufacturers, catalogGeometryForSize } from "@/lib/catalog/bikes";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import {
  EBIKE_CATEGORIES,
  MUSCLE_CATEGORIES,
  assistModeFor,
  coerceCategory,
  persistIsEbike,
  subtypeLabel,
  type BikeAssistMode,
} from "@/lib/garage/bikeAssist";
import { useAppStore } from "@/store/useAppStore";
import { notifyGarageBikeShopify, garageBikeInputFromBike } from "@/lib/shop/notifyGarageBikeShopify";
import type { BikeCategory, WheelSize } from "@/types";
import { X } from "lucide-react";

type Mode = "catalog" | "basic" | "import";

export function AddBikeWizard({
  onClose,
  initialMode = "catalog",
  initialCategory,
}: {
  onClose: () => void;
  initialMode?: Mode;
  initialCategory?: BikeCategory;
}) {
  const addBikeFromCatalog = useAppStore((s) => s.addBikeFromCatalog);
  const addBikeBasic = useAppStore((s) => s.addBikeBasic);
  const addBikeFromImport = useAppStore((s) => s.addBikeFromImport);
  const installComponent = useAppStore((s) => s.installComponent);
  const bikes = useAppStore((s) => s.bikes);
  const subscriptionTier = useAppStore((s) => s.subscriptionTier);
  const manufacturers = useMemo(() => listCatalogManufacturers(), []);

  const [mode, setMode] = useState<Mode>(initialMode);
  const [mfrId, setMfrId] = useState(manufacturers[0]?.id ?? "");
  const mfr = manufacturers.find((m) => m.id === mfrId);
  const [bikeId, setBikeId] = useState(mfr?.bikes[0]?.id ?? "");
  const catBike = mfr?.bikes.find((b) => b.id === bikeId);
  const [size, setSize] = useState(catBike?.frameSizeOptions[0] ?? "L");
  const geo = catalogGeometryForSize(catBike?.id ?? "", size);
  const [name, setName] = useState("");
  const [error, setError] = useState<string | null>(null);

  const seedCategory = initialCategory ?? "road";
  const [assistMode, setAssistMode] = useState<BikeAssistMode>(() =>
    assistModeFor(seedCategory)
  );
  const [basicCategory, setBasicCategory] = useState<BikeCategory>(
    seedCategory
  );
  const [travelF, setTravelF] = useState<number | "">("");
  const [travelR, setTravelR] = useState<number | "">("");
  const [wheel, setWheel] = useState<WheelSize>(
    seedCategory === "gravel" ? "650b" : seedCategory === "urban" || seedCategory === "road" || seedCategory === "etrekking" ? "700c" : "29"
  );
  const [hasLight, setHasLight] = useState(false);
  const [hasLock, setHasLock] = useState(false);
  const [hasRack, setHasRack] = useState(false);
  const [hasBags, setHasBags] = useState(false);
  const [importNote, setImportNote] = useState("");

  const freeBlocked = subscriptionTier === "free" && bikes.length >= 1;
  const subtypeOptions =
    assistMode === "ebike" ? EBIKE_CATEGORIES : MUSCLE_CATEGORIES;

  const showTravel =
    basicCategory === "mtb_trail" ||
    basicCategory === "mtb_am" ||
    basicCategory === "mtb_enduro" ||
    basicCategory === "dh" ||
    basicCategory === "emtb";
  const showCity =
    basicCategory === "urban" || basicCategory === "etrekking";
  const showBags = basicCategory === "gravel";

  const onAssistChange = (next: BikeAssistMode) => {
    setAssistMode(next);
    setBasicCategory((c) => coerceCategory(c, next));
  };

  const submit = () => {
    setError(null);
    if (freeBlocked) {
      setError("Im Free-Tarif nur ein Rad. Pro unter Profil freischalten.");
      return;
    }
    try {
      let createdId: string | undefined;
      if (mode === "catalog" && bikeId) {
        createdId = addBikeFromCatalog({
          catalogBikeId: bikeId,
          frameSize: size,
          name: name || undefined,
        });
      } else if (mode === "basic") {
        createdId = addBikeBasic({
          name: name || "Mein Rad",
          category: basicCategory,
          isEbike: persistIsEbike(basicCategory, assistMode),
          travelFrontMm: showTravel && travelF !== "" ? Number(travelF) : undefined,
          travelRearMm: showTravel && travelR !== "" ? Number(travelR) : undefined,
          wheelSizeFront: wheel,
          wheelSizeRear: wheel,
          frameSize: size,
        });
        if (createdId) {
          if (showCity && hasLight) {
            installComponent({ bikeId: createdId, slot: "light", freeText: "Licht" });
          }
          if (showCity && hasLock) {
            installComponent({ bikeId: createdId, slot: "lock", freeText: "Schloss" });
          }
          if (showCity && hasRack) {
            installComponent({ bikeId: createdId, slot: "rack", freeText: "Gepäckträger" });
          }
          if (showBags && hasBags) {
            installComponent({ bikeId: createdId, slot: "bags", freeText: "Taschen" });
          }
        }
      } else {
        createdId = addBikeFromImport({
          name: name || "Import-Bike",
          note: importNote || "GPX/FIT-Platzhalter ohne Komponenten",
        });
      }
      if (createdId) {
        const created = useAppStore.getState().bikes.find((b) => b.id === createdId);
        if (created) notifyGarageBikeShopify(garageBikeInputFromBike(created));
      }
      onClose();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Anlegen fehlgeschlagen");
    }
  };

  return (
    <div className="fixed inset-0 z-[60] flex items-end justify-center bg-black/60 p-0 sm:items-center sm:p-4">
      <div className="max-h-[90dvh] w-full max-w-lg overflow-y-auto rounded-t-2xl border border-border bg-surface p-4 sm:rounded-2xl">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-bold">Rad abstellen</h2>
          <button
            type="button"
            onClick={onClose}
            aria-label="Schließen"
            className="touch-target p-2"
          >
            <X className="h-5 w-5" aria-hidden />
          </button>
        </div>

        {freeBlocked && (
          <div className="mb-3 rounded-xl border border-warning/40 bg-warning/10 px-3 py-2 text-xs text-warning">
            Im Free-Tarif bereits ein Rad. Weitere Räder sind Pro — unter Profil
            freischalten.
          </div>
        )}
        {error && (
          <div className="mb-3 rounded-xl border border-error/40 bg-error/10 px-3 py-2 text-xs text-error">
            {error}
          </div>
        )}

        <p className="mb-2 text-xs text-text-secondary">
          Tipp: Mit „Aus Katalog“ sind Hersteller, Modell und Serienteile schon
          drin — du kannst alles später ändern.
        </p>

        <div className="mb-4 grid grid-cols-3 gap-2">
          {(
            [
              ["catalog", "Aus Katalog"],
              ["basic", "Selbst"],
              ["import", "GPX"],
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
            "Hersteller wählen — Serienteile (Gabel, Schaltung …) werden mitangelegt."}
          {mode === "basic" &&
            "Typ und Laufradgröße reichen. Teile kannst du später ergänzen."}
          {mode === "import" &&
            "GPX/FIT erzeugt ein Platzhalter-Bike — Teile später ergänzen."}
        </p>

        <label className="mb-3 block text-sm">
          Spitzname (optional)
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="z. B. Trail-Bike"
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
                    {b.isEbike ? " · E" : ""}
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
                <div className="font-medium text-text-primary">
                  {[
                    catBike.travelFrontMm != null &&
                    (catBike.travelFrontMm > 0 ||
                      (catBike.travelRearMm ?? 0) > 0)
                      ? `Federweg ${catBike.travelFrontMm}/${catBike.travelRearMm ?? "–"} mm`
                      : null,
                    `Laufrad ${catBike.wheelSizeFront}`,
                    catBike.isEbike ? "E-Bike" : null,
                    catBike.weightKgApprox != null
                      ? `ca. ${catBike.weightKgApprox.toFixed(1)} kg`
                      : null,
                  ]
                    .filter(Boolean)
                    .join(" · ")}
                </div>
                {geo && (
                    <div className="mt-1 tabular-nums">
                      Reach {geo.reachMm} mm · Stack {geo.stackMm} mm
                      {geo.setting ? ` · ${geo.setting}` : ""}
                    </div>
                  )}
                {Object.keys(catBike.oemComponents).length > 0 && (
                  <div className="mt-1">
                    {Object.keys(catBike.oemComponents).length} Serienteile
                    werden mitangelegt
                  </div>
                )}
              </div>
            )}
          </div>
        )}

        {mode === "basic" && (
          <div className="flex flex-col gap-3">
            <div>
              <span className="mb-1 block text-sm">Antrieb</span>
              <div className="grid grid-cols-2 gap-2">
                {(
                  [
                    ["muscle", "Muskel"],
                    ["ebike", "E-Bike"],
                  ] as const
                ).map(([id, label]) => (
                  <button
                    key={id}
                    type="button"
                    onClick={() => onAssistChange(id)}
                    className={`rounded-xl px-2 py-2 text-sm font-medium ${
                      assistMode === id
                        ? "bg-accent text-white"
                        : "bg-surface-elevated text-text-secondary"
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </div>
            </div>
            <label className="text-sm">
              {assistMode === "ebike" ? "E-Bike-Typ" : "Kategorie"}
              <select
                value={basicCategory}
                onChange={(e) =>
                  setBasicCategory(e.target.value as BikeCategory)
                }
                className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
              >
                {subtypeOptions.map((c) => (
                  <option key={`${assistMode}-${c}`} value={c}>
                    {subtypeLabel(c, assistMode)}
                  </option>
                ))}
              </select>
            </label>
            {showTravel && (
            <div className="grid grid-cols-2 gap-2">
              <label className="text-sm">
                Federweg vorn (mm)
                <input
                  type="number"
                  value={travelF}
                  onChange={(e) =>
                    setTravelF(e.target.value === "" ? "" : Number(e.target.value))
                  }
                  placeholder="nur wenn am Rad"
                  className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
                />
              </label>
              <label className="text-sm">
                Federweg hinten (mm)
                <input
                  type="number"
                  value={travelR}
                  onChange={(e) =>
                    setTravelR(e.target.value === "" ? "" : Number(e.target.value))
                  }
                  className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
                />
              </label>
            </div>
            )}
            {showCity && (
              <fieldset className="space-y-1 text-sm">
                <legend className="mb-1 text-text-secondary">
                  Am Rad — nur anhaken wenn wirklich da
                </legend>
                <label className="flex items-center gap-2">
                  <input type="checkbox" checked={hasLight} onChange={(e) => setHasLight(e.target.checked)} />
                  Licht
                </label>
                <label className="flex items-center gap-2">
                  <input type="checkbox" checked={hasLock} onChange={(e) => setHasLock(e.target.checked)} />
                  Schloss
                </label>
                <label className="flex items-center gap-2">
                  <input type="checkbox" checked={hasRack} onChange={(e) => setHasRack(e.target.checked)} />
                  Gepäckträger
                </label>
              </fieldset>
            )}
            {showBags && (
              <label className="flex items-center gap-2 text-sm">
                <input type="checkbox" checked={hasBags} onChange={(e) => setHasBags(e.target.checked)} />
                Taschen am Rad
              </label>
            )}
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
              placeholder="z. B. Notiz zum Platzhalter-Bike"
              className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
            />
            <span className="mt-1 block text-xs text-text-secondary">
              GPX/FIT-Routen importierst du unter Karte → Gespeichert.
              Hier entsteht nur ein Rad-Platzhalter ohne Komponenten — kein
              Track-Import.
            </span>
          </label>
        )}

        <button
          type="button"
          onClick={submit}
          className="mt-5 w-full rounded-xl bg-chrome py-3 font-semibold text-background"
        >
          Rad abstellen
        </button>
      </div>
    </div>
  );
}
