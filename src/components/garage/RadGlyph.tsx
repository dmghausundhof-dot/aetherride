import { RAD_MARK_SRC, type RadMarkName } from "@/lib/garage/radMark";

export function RadGlyph({
  name,
  size = 16,
  className = "",
  alt = "",
}: {
  name: RadMarkName;
  size?: number;
  className?: string;
  alt?: string;
}) {
  return (
    <img
      src={RAD_MARK_SRC[name]}
      alt={alt}
      width={size}
      height={size}
      className={className}
      draggable={false}
    />
  );
}
