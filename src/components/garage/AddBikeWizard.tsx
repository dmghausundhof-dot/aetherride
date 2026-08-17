"use client";

import { useMemo, useState } from "react";
import {
  listCatalogManufacturers,
  catalogGeometryForSize,
  findCatalogBike,
} from "@/lib/catalog/bikes";
import { searchCatalogBikes } from "@/lib/catalog/identify";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import {
  assistModeFor,
  categoryPickGroups,
  coerceCategory,
  persistIsEbike,
  subtypeLabel,
  type BikeAssistMode,
} from "@/lib/garage/bikeAssist";
import { hofSportLabel } from "@/lib/home/hofSportLabel";
import { useAppStore } from "@/store/useAppStore";
import { notifyGarageBikeShopify, garageBikeInputFromBike } from "@/lib/shop/notifyGarageBikeShopify";
import { useHofCopy } from "@/hooks/useHofCopy";
import type { BikeCategory, WheelSize } from "@/types";
import { X } from "lucide-react";

function defaultWheelFor(c: BikeCategory): WheelSize {
  if (c === "gravel") return "650b";
  if (
    c === "urban" ||
    c === "road" ||
    c === "etrekking" ||
    c === "cargo" ||
    c === "folding" ||
    c === "kids"
  ) {
    return "700c";
  }
  return "29";
}

type Mode = "catalog" | "basic" | "import";

export function AddBikeWizard({
  onClose,
  initialMode = "basic",
  initialCategory,
}: {
  onClose: () => void;
  initialMode?: Mode;
  initialCategory?: BikeCategory;
}) {
  const copy = useHofCopy();

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

  const seedCategory = initialCategory ?? "urban";
  const [assistMode, setAssistMode] = useState<BikeAssistMode>(() =>
    assistModeFor(seedCategory)
  );
  const [basicCategory, setBasicCategory] = useState<BikeCategory>(
    seedCategory
  );
  const [travelF, setTravelF] = useState<number | "">("");
  const [travelR, setTravelR] = useState<number | "">("");
  const [wheel, setWheel] = useState<WheelSize>(defaultWheelFor(seedCategory));
  const [hasLight, setHasLight] = useState(false);
  const [hasLock, setHasLock] = useState(false);
  const [hasRack, setHasRack] = useState(false);
  const [hasBags, setHasBags] = useState(false);
  const [importNote, setImportNote] = useState("");
  const [includeOemKit, setIncludeOemKit] = useState(false);
  const [catalogQuery, setCatalogQuery] = useState("");
  const catalogHits = useMemo(
    () => searchCatalogBikes(catalogQuery, 8),
    [catalogQuery]
  );

  const freeBlocked = subscriptionTier === "free" && bikes.length >= 1;
  const pickGroups = categoryPickGroups(assistMode);

  const showTravel =
    basicCategory === "mtb_trail" ||
    basicCategory === "mtb_am" ||
    basicCategory === "mtb_enduro" ||
    basicCategory === "dh" ||
    basicCategory === "emtb";
  const showCity =
    basicCategory === "urban" ||
    basicCategory === "etrekking" ||
    basicCategory === "cargo" ||
    basicCategory === "folding" ||
    basicCategory === "kids";
  const showBags = basicCategory === "gravel";

  const onAssistChange = (next: BikeAssistMode) => {
    setAssistMode(next);
    setBasicCategory((c) => {
      const coerced = coerceCategory(c, next);
      setWheel(defaultWheelFor(coerced));
      return coerced;
    });
  };

  const submit = () => {
    setError(null);
    if (freeBlocked) {
      setError("Im Free-Tarif nur ein Rad. Pro unter Profil freischalten.");
      return;
    }
    try {
      let createdId: string | undefined;
      if (mode === "catalog") {
        if (!bikeId) {
          setError("Bitte ein Modell suchen oder aus der Liste wählen.");
          return;
        }
        createdId = addBikeFromCatalog({
          catalogBikeId: bikeId,
          frameSize: size,
          name: name || undefined,
          includeOemKit,
        });
      } else if (mode === "basic") {
        createdId = addBikeBasic({
          name: name.trim(),
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
          <h2 className="text-lg font-bold">{copy.workshopAdd}</h2>
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
          Default ist dein Rad. Katalog ist Suche — Serienteile nur mit
          Häkchen.
        </p>

        <div className="mb-4 grid grid-cols-3 gap-2">
          {(
            [
              ["basic", "Mein Rad"],
              ["catalog", "Katalog"],
              ["import", "GPX"],
            ] as const
          ).map(([id, label]) => (
            <button
              key={id}
              type="button"
              onClick={() => setMode(id)}
              className={`rounded-xl px-2 py-2 text-sm font-medium ${
                mode === id
                  ? "bg-accent text-on-accent"
                  : "bg-surface-elevated text-text-secondary"
              }`}
            >
              {label}
            </button>
          ))}
        </div>

        <p className="mb-3 text-xs text-text-secondary">
          {mode === "catalog" &&
            "Suche nach Marke und Modell. Identität immer, Kit nur wenn du es übernimmst."}
          {mode === "basic" &&
            "Typ und Laufradgröße reichen. Teile kannst du später selbst anlegen."}
          {mode === "import" &&
            "GPX/FIT erzeugt ein Platzhalter-Bike — Teile später ergänzen."}
        </p>

        <label className="mb-3 block text-sm">
          Spitzname (optional)
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder={
              mode === "basic"
                ? hofSportLabel(
                    basicCategory,
                    persistIsEbike(basicCategory, assistMode)
                  )
                : "z. B. Trail"
            }
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>

        {mode === "catalog" && (
          <div className="flex flex-col gap-3">
            <label className="text-sm">
              Suche
              <input
                value={catalogQuery}
                onChange={(e) => setCatalogQuery(e.target.value)}
                placeholder="Focus JAM², Canyon Grizl …"
                className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
              />
            </label>
            {catalogQuery.trim().length >= 2 && (
              <ul className="max-h-40 overflow-y-auto rounded-xl border border-border">
                {catalogHits.length === 0 ? (
                  <li className="px-3 py-2 text-xs text-text-secondary">
                    Kein Treffer — unter „Mein Rad“ selbst anlegen.
                  </li>
                ) : (
                  catalogHits.map((h) => (
                    <li key={h.id}>
                      <button
                        type="button"
                        onClick={() => {
                          const found = findCatalogBike(h.id);
                          if (!found) return;
                          setMfrId(found.manufacturer.id);
                          setBikeId(found.bike.id);
                          setSize(found.bike.frameSizeOptions[0] ?? "L");
                          setCatalogQuery("");
                        }}
                        className="w-full px-3 py-2 text-left text-sm hover:bg-surface-elevated"
                      >
                        {h.manufacturerName} {h.name} ({h.year})
                        {h.isEbike ? " · E" : ""}
                      </button>
                    </li>
                  ))
                )}
              </ul>
            )}
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
                <div className="font-medium text-foreground">
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
                  <label className="mt-2 flex items-start gap-2 text-xs text-foreground">
                    <input
                      type="checkbox"
                      className="mt-0.5"
                      checked={includeOemKit}
                      onChange={(e) => setIncludeOemKit(e.target.checked)}
                    />
                    <span>
                      Serienteile übernehmen ({Object.keys(catBike.oemComponents).length}{" "}
                      Slots). Sonst nur Identität — Teile selbst anlegen.
                    </span>
                  </label>
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
                        ? "bg-accent text-on-accent"
                        : "bg-surface-elevated text-text-secondary"
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </div>
            </div>
            <div>
              <span className="mb-1 block text-sm">
                {assistMode === "ebike" ? "E-Bike-Typ" : "Welches Rad"}
              </span>
              <div className="space-y-3">
                {pickGroups.map((g) => (
                  <div key={g.id}>
                    <div className="mb-1 text-[11px] font-bold tracking-wide text-text-secondary">
                      {g.label}
                    </div>
                    <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
                      {g.categories.map((c) => {
                        const on = basicCategory === c;
                        return (
                          <button
                            key={`${assistMode}-${c}`}
                            type="button"
                            onClick={() => {
                              setBasicCategory(c);
                              setWheel(defaultWheelFor(c));
                            }}
                            className={`rounded-xl px-2 py-2.5 text-left text-sm font-medium ${
                              on
                                ? "bg-accent text-on-accent"
                                : "bg-surface-elevated text-text-secondary"
                            }`}
                          >
                            {subtypeLabel(c, assistMode)}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                ))}
              </div>
            </div>
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
          className="mt-5 w-full rounded-xl bg-chrome py-3 font-semibold text-on-accent"
        >
          {copy.workshopAdd}
        </button>
      </div>
    </div>
  );
}
