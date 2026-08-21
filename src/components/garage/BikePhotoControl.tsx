"use client";

import { useEffect, useRef, useState } from "react";
import { RadGlyph } from "@/components/garage/RadGlyph";
import { RadStandFrame } from "@/components/garage/RadStandFrame";
import { StandPhotoCrop } from "@/components/garage/StandPhotoCrop";
import {
  STAND_PHOTO_RATIO,
  STAND_PHOTO_X_BIAS,
  STAND_PHOTO_Y_BIAS,
  standPhotoIsRemote,
  standPhotoNeedsCrop,
  standPhotoSourceRect,
} from "@/lib/garage/standPhoto";
import { radSilhouetteSrc } from "@/lib/garage/radMark";
import { useAppStore } from "@/store/useAppStore";
import { useHofCopy } from "@/hooks/useHofCopy";
import type { Bike } from "@/types";

function cropToStandJpeg(
  img: HTMLImageElement,
  yBias = STAND_PHOTO_Y_BIAS,
  xBias = STAND_PHOTO_X_BIAS
): string {
  const crop = standPhotoSourceRect(
    img.width,
    img.height,
    STAND_PHOTO_RATIO,
    yBias,
    xBias
  );
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

function rotateImage90(
  img: HTMLImageElement
): Promise<{ src: string; img: HTMLImageElement }> {
  const canvas = document.createElement("canvas");
  canvas.width = img.height;
  canvas.height = img.width;
  const ctx = canvas.getContext("2d");
  if (!ctx) return Promise.reject(new Error("canvas"));
  ctx.translate(canvas.width / 2, canvas.height / 2);
  ctx.rotate(Math.PI / 2);
  ctx.drawImage(img, -img.width / 2, -img.height / 2);
  const src = canvas.toDataURL("image/jpeg", 0.85);
  return new Promise((resolve, reject) => {
    const next = new Image();
    next.onload = () => resolve({ src, img: next });
    next.onerror = () => reject(new Error("rotate"));
    next.src = src;
  });
}

function loadCorsImage(url: string): Promise<HTMLImageElement | null> {
  return new Promise((resolve) => {
    const img = new Image();
    img.crossOrigin = "anonymous";
    img.onload = () => resolve(img);
    img.onerror = () => resolve(null);
    img.src = url;
  });
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
  const [crop, setCrop] = useState<{
    src: string;
    img: HTMLImageElement;
    yBias: number;
    xBias: number;
  } | null>(null);
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

  const applyCrop = (img: HTMLImageElement, yBias: number, xBias: number) => {
    try {
      const next = cropToStandJpeg(img, yBias, xBias);
      if (!next) return;
      updateBike(bikeId, { photoUrl: next });
    } catch {
      /* CORS-tainted remote canvas */
    }
  };

  const onFile = (file: File | null) => {
    if (!file || !file.type.startsWith("image/")) return;
    setBroken(false);
    const img = new Image();
    const reader = new FileReader();
    reader.onload = () => {
      const dataUrl = String(reader.result);
      img.onload = () => {
        setCrop({
          src: dataUrl,
          img,
          yBias: STAND_PHOTO_Y_BIAS,
          xBias: STAND_PHOTO_X_BIAS,
        });
      };
      img.src = dataUrl;
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
      </RadStandFrame>
      {remotePhoto ? (
        <div className="m-3 flex flex-col gap-2">
          <button
            type="button"
            data-testid="stand-photo-place"
            onClick={() => {
              void (async () => {
                if (!photoUrl) return;
                const img = await loadCorsImage(photoUrl);
                if (!img) {
                  fileRef.current?.click();
                  return;
                }
                setCrop({
                  src: photoUrl,
                  img,
                  yBias: STAND_PHOTO_Y_BIAS,
                  xBias: STAND_PHOTO_X_BIAS,
                });
              })();
            }}
            className="rounded-xl border border-border px-3 py-2 text-left"
          >
            <span className="block text-[11px] font-bold">
              {copy.workshopPhotoPlace}
            </span>
            <span className="mt-0.5 block text-[10px] leading-snug text-text-secondary">
              {copy.workshopPhotoCropHint}
            </span>
          </button>
          <button
            type="button"
            data-testid="stand-photo-retake"
            onClick={() => fileRef.current?.click()}
            className="rounded-xl border border-border px-3 py-2 text-left text-[11px] font-bold"
          >
            {copy.workshopPhotoRetake}
          </button>
        </div>
      ) : null}
      <input
        ref={fileRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={(e) => onFile(e.target.files?.[0] ?? null)}
      />
      {crop ? (
        <StandPhotoCrop
          src={crop.src}
          tall={crop.img.width / crop.img.height < STAND_PHOTO_RATIO}
          yBias={crop.yBias}
          xBias={crop.xBias}
          onYBias={(yBias) => setCrop({ ...crop, yBias })}
          onXBias={(xBias) => setCrop({ ...crop, xBias })}
          onConfirm={() => {
            applyCrop(crop.img, crop.yBias, crop.xBias);
            setCrop(null);
          }}
          onRotate={() => {
            void rotateImage90(crop.img).then(({ src, img }) => {
              setCrop({
                src,
                img,
                yBias: STAND_PHOTO_Y_BIAS,
                xBias: STAND_PHOTO_X_BIAS,
              });
            });
          }}
          onCancel={() => {
            applyCrop(crop.img, STAND_PHOTO_Y_BIAS, STAND_PHOTO_X_BIAS);
            setCrop(null);
          }}
        />
      ) : null}
    </div>
  );
}
