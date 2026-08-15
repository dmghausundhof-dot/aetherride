/**
 * Public legal copy helpers. Never invent TMG identity (name, address, register).
 * Contact email already used on the site: hello@aetherride.app
 */

export const DEFAULT_LEGAL_EMAIL = "hello@aetherride.app";

export function legalContactEmail(): string {
  return process.env.NEXT_PUBLIC_LEGAL_EMAIL?.trim() || DEFAULT_LEGAL_EMAIL;
}

export function legalImprintText(): string | null {
  const v = process.env.NEXT_PUBLIC_LEGAL_IMPRINT?.trim();
  return v || null;
}

export function legalPrivacyOverride(): string | null {
  const v = process.env.NEXT_PUBLIC_LEGAL_PRIVACY?.trim();
  return v || null;
}

export function legalWithdrawalOverride(): string | null {
  const v = process.env.NEXT_PUBLIC_LEGAL_WITHDRAWAL?.trim();
  return v || null;
}

export function hasTmgImprint(): boolean {
  return legalImprintText() !== null;
}
