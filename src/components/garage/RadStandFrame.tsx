import type { ReactNode } from "react";
import { RAD_STAND_GROUND, RAD_STAND_HEADER } from "@/lib/garage/radMark";

/** Shared stand stage — ground, bike, rail. Used on Hof, Box and the rail. */
export function RadStandFrame({
  src,
  alt,
  photo = false,
  heightClass = "h-44",
  children,
  onError,
}: {
  src: string;
  alt: string;
  photo?: boolean;
  heightClass?: string;
  children?: ReactNode;
  onError?: () => void;
}) {
  return (
    <div className={`relative overflow-hidden bg-[#121215] ${heightClass}`}>
      {photo ? null : (
        <img
          src={RAD_STAND_GROUND}
          alt=""
          className="absolute inset-0 h-full w-full object-cover"
          draggable={false}
        />
      )}
      {photo ? null : (
        <div
          aria-hidden
          className="pointer-events-none absolute inset-x-0 bottom-0 h-16 bg-gradient-to-t from-[#E57532]/16 to-transparent"
        />
      )}
      <img
        src={src}
        alt={alt}
        onError={onError}
        className={
          photo
            ? "relative h-full w-full object-cover object-[center_72%]"
            : "relative mx-auto h-full w-auto max-w-[92%] object-contain py-2"
        }
        draggable={false}
      />
      <img
        src={RAD_STAND_HEADER}
        alt=""
        width={240}
        height={24}
        className="pointer-events-none absolute bottom-1 left-3 h-3.5 w-24"
        draggable={false}
      />
      {children}
    </div>
  );
}
