"use client";

import { useEffect, useRef, useState } from "react";
import { RadGlyph } from "@/components/garage/RadGlyph";
import { RadStandFrame } from "@/components/garage/RadStandFrame";
import {
  standPhotoIsRemote,
  standPhotoNeedsCrop,
  standPhotoSourceRect,
} from "@/lib/garage/standPhoto";
import { radSilhouetteSrc } from "@/lib/garage/radMark";
import { useAppStore } from "@/store/useAppStore";
import { useHofCopy } from "@/hooks/useHofCopy";
import type { Bike } from "@/types";

function cropToStandJpeg(img: HTMLImageElement): string {
  const crop = standPhotoSourceRect(img.width, img.height);
  const max = 1200;
  const scale = Math.min(1, max / Math.max(crop.sw, crop.sh));
  const canvas = document.createElement("canvas");
  canvas.width = Math.max(1, Math.round(crop.sw * scale));
  canvas.height = Math.max(1, Math.round(crop.sh * scale));
  const ctx = canvas.getContext("2d");
  if (!ctx) return "";
  ctx.drawImage(
    img,
    crop.sx,
    crop.sy,
    crop.sw,
    crop.sh,
    0,
    0,
    canvas.width,
    canvas.height
  );
  return canvas.toDataURL("image/jpeg", 0.78);
}

/** Bühne im Stand — Foto oder Silhouette, Kamera als Overlay. */
export function BikePhotoControl({
  bikeId,
  photoUrl,
  bike,
}: {
  bikeId: string;
  photoUrl?: string;
  bike?: Bike;
}) {
  const updateBike = useAppStore((s) => s.updateBike);
  const fileRef = useRef<HTMLInputElement>(null);
  const [broken, setBroken] = useState(false);
  const copy = useHofCopy();

  const silhouette = bike ? radSilhouetteSrc(bike) : undefined;
  const usingPhoto = Boolean(photoUrl) && !broken;
  const src = usingPhoto ? photoUrl : silhouette;
  const remotePhoto = usingPhoto && standPhotoIsRemote(photoUrl);

  useEffect(() => {
    if (!photoUrl?.startsWith("data:")) return;
    let cancelled = false;
    const img = new Image();
    img.onload = () => {
      if (cancelled || !standPhotoNeedsCrop(img.width, img.height)) return;
      const next = cropToStandJpeg(img);
      if (!next) return;
      updateBike(bikeId, { photoUrl: next });
    };
    img.src = photoUrl;
    return () => {
      cancelled = true;
    };
  }, [photoUrl, bikeId, updateBike]);

  const onFile = (file: File | null) => {
    if (!file || !file.type.startsWith("image/")) return;
    setBroken(false);
    const img = new Image();
    const reader = new FileReader();
    reader.onload = () => {
      img.onload = () => {
        const next = cropToStandJpeg(img);
        if (!next) return;
        updateBike(bikeId, { photoUrl: next });
      };
      img.src = String(reader.result);
    };
    reader.readAsDataURL(file);
  };

  if (!src) return null;

  return (
    <div className="relative">
      <RadStandFrame
        src={src}
        alt={bike ? `${bike.name} Seitenprofil` : "Rad"}
        photo={usingPhoto}
        heightClass="h-44"
        onError={() => setBroken(true)}
      >
        {bike?.isActive ? (
          <span className="absolute left-2 top-2 rounded-full bg-chrome px-2 py-0.5 text-[10px] font-bold text-on-accent">
            Aktiv
          </span>
        ) : null}
        <div className="absolute right-2 top-2 flex gap-1">
          <button
            type="button"
            onClick={() => fileRef.current?.click()}
            className="rounded-full bg-black/45 p-2 backdrop-blur-sm"
            aria-label="Foto"
          >
            <RadGlyph name="photo" size={14} />
          </button>
          {photoUrl ? (
            <button
              type="button"
              onClick={() => {
                setBroken(false);
                updateBike(bikeId, { photoUrl: undefined });
              }}
              className="rounded-full bg-black/45 px-2 py-2 text-[10px] font-semibold text-white/80"
            >
              ×
            </button>
          ) : null}
        </div>
        {remotePhoto ? (
          <button
            type="button"
            data-testid="stand-photo-retake"
            onClick={() => fileRef.current?.click()}
            className="absolute inset-x-2 bottom-7 rounded-xl bg-black/55 px-3 py-2 text-left backdrop-blur-sm"
          >
            <span className="block text-[11px] font-bold text-white">
              {copy.workshopPhotoRetake}
            </span>
            <span className="mt-0.5 block text-[10px] leading-snug text-white/80">
              {copy.workshopPhotoRetakeHint}
            </span>
          </button>
        ) : null}
      </RadStandFrame>
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
