/** Tageszeit-Begrüßung für Home (Spec 4.7.1). */

export function timeOfDayGreeting(
  now = new Date(),
  languageCode = "de"
): string {
  const lang = languageCode.toLowerCase();
  const h = now.getHours();
  if (lang.startsWith("en")) {
    if (h < 5) return "Good night";
    if (h < 11) return "Good morning";
    if (h < 17) return "Good afternoon";
    if (h < 22) return "Good evening";
    return "Good night";
  }
  if (lang.startsWith("fr")) {
    if (h < 5) return "Bonne nuit";
    if (h < 18) return "Bonjour";
    if (h < 22) return "Bonsoir";
    return "Bonne nuit";
  }
  if (lang.startsWith("it")) {
    if (h < 5) return "Buona notte";
    if (h < 12) return "Buongiorno";
    if (h < 18) return "Buon pomeriggio";
    if (h < 22) return "Buonasera";
    return "Buona notte";
  }
  if (h < 5) return "Gute Nacht";
  if (h < 11) return "Guten Morgen";
  if (h < 17) return "Guten Tag";
  if (h < 22) return "Guten Abend";
  return "Gute Nacht";
}

export function greetingLine(
  displayName?: string | null,
  now = new Date(),
  languageCode = "de"
): string {
  const g = timeOfDayGreeting(now, languageCode);
  const name = displayName?.trim();
  return name ? `${g}, ${name}` : g;
}

export function avatarInitials(displayName?: string | null, email?: string | null): string {
  if (displayName?.trim()) {
    const parts = displayName.trim().split(/\s+/);
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return displayName.slice(0, 2).toUpperCase();
  }
  if (email?.includes("@")) {
    return email.slice(0, 2).toUpperCase();
  }
  return "AR";
}
