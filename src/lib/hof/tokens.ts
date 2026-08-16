/**
 * FlowLine design tokens — keep in sync with `src/app/globals.css`
 * and Flutter `AppColors` / `AppSpacing` / `AppRadius`.
 *
 * Orange = primary action, active chrome, route line.
 * Sage = success / nature.
 * Charcoal = text and dark surfaces.
 * `muted` here is **text**, not a fill. CSS `--muted` is a fill.
 */

export const HOF_TOKENS = {
  background: "#121215",
  surface: "#1E1E26",
  surfaceElevated: "#2A2A34",
  overlay: "#343440",
  hairline: "#484854",
  text: "#F2F2F2",
  /** Secondary text on dark — not CSS `--muted` (that is a fill). */
  mutedText: "#9CA3AF",
  orange: "#FF6A00",
  orangeHover: "#FF8533",
  onAccent: "#121215",
  sage: "#7A8B73",
  sageOnDark: "#7FA38D",
  sageOnLight: "#4F6B5A",
  warning: "#EAB308",
  error: "#EF4444",
  mapWarnFill: "#FFE0B2",
  mapWarnInk: "#B34700",
  charcoal: "#1F1F1F",
  radius: {
    chip: 12,
    card: 16,
    pill: 999,
  },
  grid: 4,
  space: {
    xxs: 2,
    xs: 4,
    s: 8,
    m: 12,
    l: 16,
    xl: 20,
    xxl: 24,
    xxxl: 32,
  },
} as const;

export type HofTokens = typeof HOF_TOKENS;
