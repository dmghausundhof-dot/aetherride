import { CHROME_MARK_SRC, type ChromeMarkName } from "@/lib/chrome/chromeMarks";
import { cn } from "@/lib/utils";

export type { ChromeMarkName };

/** Two-color FlowLine mark, or a currentColor silhouette for chrome/chips. */
export function ChromeGlyph({
  name,
  size = 16,
  current = false,
  className = "",
  alt = "",
}: {
  name: ChromeMarkName;
  size?: number;
  current?: boolean;
  className?: string;
  alt?: string;
}) {
  const src = CHROME_MARK_SRC[name];
  if (current) {
    return (
      <span
        aria-hidden
        className={cn("inline-block shrink-0 bg-current", className)}
        style={{
          width: size,
          height: size,
          WebkitMaskImage: `url(${src})`,
          WebkitMaskRepeat: "no-repeat",
          WebkitMaskPosition: "center",
          WebkitMaskSize: "contain",
          maskImage: `url(${src})`,
          maskRepeat: "no-repeat",
          maskPosition: "center",
          maskSize: "contain",
        }}
      />
    );
  }
  return (
    <img
      src={src}
      alt={alt}
      width={size}
      height={size}
      className={className}
      draggable={false}
    />
  );
}
