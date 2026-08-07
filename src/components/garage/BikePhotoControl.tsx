"use client";

import { useRef, useState } from "react";
import { Camera, Link2 } from "lucide-react";
import { useAppStore } from "@/store/useAppStore";

/** Foto (Data-URL) oder URL setzen — lokal persistiert im Store */
export function BikePhotoControl({
  bikeId,
  photoUrl,
}: {
  bikeId: string;
  photoUrl?: string;
}) {
  const updateBike = useAppStore((s) => s.updateBike);
  const fileRef = useRef<HTMLInputElement>(null);
  const [urlDraft, setUrlDraft] = useState("");
  const [showUrl, setShowUrl] = useState(false);

  const onFile = (file: File | null) => {
    if (!file || !file.type.startsWith("image/")) return;
    if (file.size > 1_500_000) {
      // komprimieren via canvas
      const img = new Image();
      const reader = new FileReader();
      reader.onload = () => {
        img.onload = () => {
          const canvas = document.createElement("canvas");
          const max = 900;
          const scale = Math.min(1, max / Math.max(img.width, img.height));
          canvas.width = Math.round(img.width * scale);
          canvas.height = Math.round(img.height * scale);
          const ctx = canvas.getContext("2d");
          if (!ctx) return;
          ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
          updateBike(bikeId, { photoUrl: canvas.toDataURL("image/jpeg", 0.72) });
        };
        img.src = String(reader.result);
      };
      reader.readAsDataURL(file);
      return;
    }
    const reader = new FileReader();
    reader.onload = () => {
      updateBike(bikeId, { photoUrl: String(reader.result) });
    };
    reader.readAsDataURL(file);
  };

  return (
    <div className="relative overflow-hidden rounded-2xl border border-border bg-surface">
      {photoUrl ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={photoUrl}
          alt="Bike"
          className="h-40 w-full object-cover"
        />
      ) : (
        <div className="flex h-28 items-center justify-center bg-surface-elevated text-sm text-text-secondary">
          Noch kein Foto — Identität für die Garage
        </div>
      )}
      <div className="flex gap-2 p-2">
        <button
          type="button"
          onClick={() => fileRef.current?.click()}
          className="inline-flex flex-1 items-center justify-center gap-1.5 rounded-xl bg-muted px-2 py-2 text-xs font-medium"
        >
          <Camera className="h-3.5 w-3.5" /> Foto
        </button>
        <button
          type="button"
          onClick={() => setShowUrl((v) => !v)}
          className="inline-flex flex-1 items-center justify-center gap-1.5 rounded-xl bg-muted px-2 py-2 text-xs font-medium"
        >
          <Link2 className="h-3.5 w-3.5" /> URL
        </button>
        {photoUrl && (
          <button
            type="button"
            onClick={() => updateBike(bikeId, { photoUrl: undefined })}
            className="rounded-xl bg-muted px-2 py-2 text-xs"
          >
            Entfernen
          </button>
        )}
      </div>
      {showUrl && (
        <div className="flex gap-2 px-2 pb-2">
          <input
            value={urlDraft}
            onChange={(e) => setUrlDraft(e.target.value)}
            placeholder="https://…"
            className="flex-1 rounded-xl border border-border bg-surface-elevated px-3 py-2 text-xs"
          />
          <button
            type="button"
            className="rounded-xl bg-accent px-3 py-2 text-xs font-semibold text-white"
            onClick={() => {
              if (urlDraft.trim()) {
                updateBike(bikeId, { photoUrl: urlDraft.trim() });
                setShowUrl(false);
                setUrlDraft("");
              }
            }}
          >
            OK
          </button>
        </div>
      )}
      <input
        ref={fileRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={(e) => onFile(e.target.files?.[0] ?? null)}
      />
    </div>
  );
}
