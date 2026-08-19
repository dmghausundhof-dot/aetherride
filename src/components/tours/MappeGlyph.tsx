export type MappeGlyphName =
  | "distance"
  | "elevation"
  | "duration"
  | "loop"
  | "private"
  | "shared"
  | "mappe"
  | "stimmen"
  | "collection"
  | "ride"
  | "meet";

const SRC: Record<MappeGlyphName, string> = {
  distance: "/tours/glyph-distance.svg",
  elevation: "/tours/glyph-elevation.svg",
  duration: "/tours/glyph-duration.svg",
  loop: "/tours/glyph-loop.svg",
  private: "/tours/glyph-private.svg",
  shared: "/tours/glyph-shared.svg",
  mappe: "/tours/glyph-mappe.svg",
  stimmen: "/tours/glyph-stimmen.svg",
  collection: "/tours/glyph-collection.svg",
  ride: "/tours/glyph-ride.svg",
  meet: "/tours/glyph-meet.svg",
};

export function MappeGlyph({
  name,
  size = 16,
  className = "",
  alt = "",
}: {
  name: MappeGlyphName;
  size?: number;
  className?: string;
  alt?: string;
}) {
  return (
    <img
      src={SRC[name]}
      alt={alt}
      width={size}
      height={size}
      className={className}
      draggable={false}
    />
  );
}
