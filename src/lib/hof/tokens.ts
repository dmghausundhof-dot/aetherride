/**
 * Web Hof tokens — keep in sync with Flutter `AppColors` / `AppSpacing` /
 * `AppRadius` and `src/app/globals.css`.
 *
 * Orange is Rausfahren only. Mint is active chrome.
 */

export const HOF_TOKENS = {
  background: "#0A1210",
  surface: "#14201C",
  surfaceElevated: "#1A2A24",
  hairline: "#2A3D34",
  mint: "#81C995",
  forest: "#1A5C45",
  text: "#E8EEEA",
  muted: "#9AABA2",
  orange: "#FF6B35",
  orangeHover: "#FF8555",
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
