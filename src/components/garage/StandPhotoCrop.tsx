"use client";

import { useState } from "react";
import { RadStandFrame } from "@/components/garage/RadStandFrame";
import { standPhotoObjectPosition } from "@/lib/garage/standPhoto";
import { useHofCopy } from "@/hooks/useHofCopy";

/** Pan the photo on the 2:1 stand before saving the crop. */
export function StandPhotoCrop({
  src,
  tall,
  yBias,
  xBias,
  onYBias,
  onXBias,
  onConfirm,
  onCancel,
  onRotate,
}: {
  src: string;
  tall: boolean;
  yBias: number;
  xBias: number;
  onYBias: (v: number) => void;
  onXBias: (v: number) => void;
  onConfirm: () => void;
  onCancel: () => void;
  onRotate?: () => void;
}) {
  const copy = useHofCopy();
  const [drag, setDrag] = useState<{ x: number; y: number } | null>(null);

  return (
    <div
      className="fixed inset-0 z-[90] flex items-end justify-center bg-black/60 p-0 sm:items-center sm:p-4"
      role="dialog"
      aria-modal
      aria-labelledby="stand-photo-crop-title"
      data-testid="stand-photo-crop"
      onClick={onCancel}
    >
      <div
        className="w-full max-w-md rounded-t-2xl border border-border bg-surface p-5 sm:rounded-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <h3 id="stand-photo-crop-title" className="text-lg font-bold">
          {copy.workshopPhotoCropTitle}
        </h3>
        <p className="mt-1 text-sm text-text-secondary">
          {copy.workshopPhotoCropHint}
        </p>
        <div
          className="mt-3 cursor-grab active:cursor-grabbing"
          onPointerDown={(e) => {
            (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
            setDrag({ x: e.clientX, y: e.clientY });
          }}
          onPointerMove={(e) => {
            if (!drag) return;
            const dx = e.clientX - drag.x;
            const dy = e.clientY - drag.y;
            setDrag({ x: e.clientX, y: e.clientY });
            const box = (e.currentTarget as HTMLElement).getBoundingClientRect();
            if (tall) {
              onYBias(Math.min(1, Math.max(0, yBias - dy / box.height)));
            } else {
              onXBias(Math.min(1, Math.max(0, xBias - dx / box.width)));
            }
          }}
          onPointerUp={() => setDrag(null)}
          onPointerCancel={() => setDrag(null)}
        >
          <RadStandFrame
            src={src}
            alt=""
            photo
            heightClass="aspect-[2/1]"
            objectPosition={standPhotoObjectPosition(yBias, xBias)}
          />
        </div>
        <button
          type="button"
          data-testid="stand-photo-crop-save"
          onClick={onConfirm}
          className="mt-4 w-full rounded-xl bg-chrome py-3 text-sm font-semibold text-on-accent"
        >
          {copy.workshopPhotoCropSave}
        </button>
        {onRotate ? (
          <button
            type="button"
            data-testid="stand-photo-crop-rotate"
            onClick={onRotate}
            className="mt-2 w-full rounded-xl border border-border py-3 text-sm font-semibold"
          >
            {copy.workshopPhotoRotate}
          </button>
        ) : null}
      </div>
    </div>
  );
}
