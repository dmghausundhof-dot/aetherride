/** Tageszeit-Begrüßung für Home (Spec 4.7.1). */

export function timeOfDayGreeting(now = new Date()): string {
  const h = now.getHours();
  if (h < 5) return "Gute Nacht";
  if (h < 11) return "Guten Morgen";
  if (h < 17) return "Guten Tag";
  if (h < 22) return "Guten Abend";
  return "Gute Nacht";
}

export function greetingLine(displayName?: string | null, now = new Date()): string {
  const g = timeOfDayGreeting(now);
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
