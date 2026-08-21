/**
 * Sign-in chrome. Headings follow Flutter ARB where keys exist.
 */
import type { ChromeLang } from "./chromeLang";

export type AuthCopy = {
  email: string;
  password: string;
  passwordPh: string;
  show: string;
  hide: string;
  signIn: string;
  register: string;
  forgot: string;
  google: string;
  apple: string;
  loginFailed: string;
  registerFailed: string;
  resetFailed: string;
  oauthUnavailable: string;
  oauthEnable: string;
  needEmail: string;
  resetSent: string;
  confirmEmail: string;
  error: string;
  emailRequired: string;
  emailPasswordRequired: string;
  emailPasswordMin: string;
};

const DE: AuthCopy = {
  email: "E-Mail",
  password: "Passwort",
  passwordPh: "Passwort (min. 8)",
  show: "Zeigen",
  hide: "Verbergen",
  signIn: "Anmelden",
  register: "Registrieren",
  forgot: "Passwort vergessen?",
  google: "Google",
  apple: "Apple",
  loginFailed: "Login fehlgeschlagen",
  registerFailed: "Registrierung fehlgeschlagen",
  resetFailed: "Reset fehlgeschlagen",
  oauthUnavailable: "OAuth nicht verfügbar",
  oauthEnable: "OAuth: Provider in Supabase aktivieren",
  needEmail: "Bitte zuerst die E-Mail eintragen.",
  resetSent: "Wenn das Konto existiert, kommt eine E-Mail zum Zurücksetzen.",
  confirmEmail: "Bitte E-Mail bestätigen, dann anmelden.",
  error: "Fehler",
  emailRequired: "E-Mail erforderlich",
  emailPasswordRequired: "E-Mail und Passwort erforderlich",
  emailPasswordMin: "E-Mail und Passwort (min. 8 Zeichen) erforderlich",
};

const EN: AuthCopy = {
  email: "Email",
  password: "Password",
  passwordPh: "Password (min. 8)",
  show: "Show",
  hide: "Hide",
  signIn: "Sign in",
  register: "Register",
  forgot: "Forgot password?",
  google: "Google",
  apple: "Apple",
  loginFailed: "Sign-in failed",
  registerFailed: "Registration failed",
  resetFailed: "Reset failed",
  oauthUnavailable: "OAuth unavailable",
  oauthEnable: "OAuth: enable the provider in Supabase",
  needEmail: "Enter your email first.",
  resetSent: "If the account exists, you will get a reset email.",
  confirmEmail: "Confirm the email, then sign in.",
  error: "Error",
  emailRequired: "Email required",
  emailPasswordRequired: "Email and password required",
  emailPasswordMin: "Email and password (min. 8 characters) required",
};

const FR: AuthCopy = {
  email: "E-mail",
  password: "Mot de passe",
  passwordPh: "Mot de passe (min. 8)",
  show: "Afficher",
  hide: "Masquer",
  signIn: "Se connecter",
  register: "S'inscrire",
  forgot: "Mot de passe oublié ?",
  google: "Google",
  apple: "Apple",
  loginFailed: "Connexion échouée",
  registerFailed: "Inscription échouée",
  resetFailed: "Reset échoué",
  oauthUnavailable: "OAuth indisponible",
  oauthEnable: "OAuth : active le provider dans Supabase",
  needEmail: "Saisis d’abord l’e-mail.",
  resetSent: "Si le compte existe, un e-mail de réinitialisation arrive.",
  confirmEmail: "Confirme l’e-mail, puis connecte-toi.",
  error: "Erreur",
  emailRequired: "E-mail requis",
  emailPasswordRequired: "E-mail et mot de passe requis",
  emailPasswordMin: "E-mail et mot de passe (min. 8 caractères) requis",
};

const IT: AuthCopy = {
  email: "E-mail",
  password: "Password",
  passwordPh: "Password (min. 8)",
  show: "Mostra",
  hide: "Nascondi",
  signIn: "Accedi",
  register: "Registrati",
  forgot: "Password dimenticata?",
  google: "Google",
  apple: "Apple",
  loginFailed: "Accesso non riuscito",
  registerFailed: "Registrazione non riuscita",
  resetFailed: "Reset non riuscito",
  oauthUnavailable: "OAuth non disponibile",
  oauthEnable: "OAuth: attiva il provider in Supabase",
  needEmail: "Inserisci prima l’e-mail.",
  resetSent: "Se l’account esiste, arriva un’e-mail per reimpostare.",
  confirmEmail: "Conferma l’e-mail, poi accedi.",
  error: "Errore",
  emailRequired: "E-mail obbligatoria",
  emailPasswordRequired: "E-mail e password obbligatorie",
  emailPasswordMin: "E-mail e password (min. 8 caratteri) obbligatorie",
};

const NL: AuthCopy = {
  email: "E-mail",
  password: "Wachtwoord",
  passwordPh: "Wachtwoord (min. 8)",
  show: "Tonen",
  hide: "Verbergen",
  signIn: "Inloggen",
  register: "Registreren",
  forgot: "Wachtwoord vergeten?",
  google: "Google",
  apple: "Apple",
  loginFailed: "Inloggen mislukt",
  registerFailed: "Registreren mislukt",
  resetFailed: "Reset mislukt",
  oauthUnavailable: "OAuth niet beschikbaar",
  oauthEnable: "OAuth: zet de provider aan in Supabase",
  needEmail: "Vul eerst het e-mailadres in.",
  resetSent: "Als het account bestaat, krijg je een reset-mail.",
  confirmEmail: "Bevestig de e-mail, log daarna in.",
  error: "Fout",
  emailRequired: "E-mail verplicht",
  emailPasswordRequired: "E-mail en wachtwoord verplicht",
  emailPasswordMin: "E-mail en wachtwoord (min. 8 tekens) verplicht",
};

const BY: Record<ChromeLang, AuthCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function authCopy(lang: ChromeLang = "de"): AuthCopy {
  return BY[lang] ?? DE;
}

/** API still throws German; the card maps known keys. */
export function presentAuthError(de: string, lang: ChromeLang = "de"): string {
  const c = authCopy(lang);
  if (de === DE.emailRequired) return c.emailRequired;
  if (de === DE.emailPasswordRequired) return c.emailPasswordRequired;
  if (de === DE.emailPasswordMin) return c.emailPasswordMin;
  if (de === DE.loginFailed) return c.loginFailed;
  if (de === DE.registerFailed) return c.registerFailed;
  if (de === DE.resetFailed) return c.resetFailed;
  if (de === DE.oauthUnavailable) return c.oauthUnavailable;
  if (de === DE.oauthEnable) return c.oauthEnable;
  return de;
}
