/**
 * F-SEN-005 — Live-Hinweise (max. 6 Wörter), keine Ablese-Aufforderung.
 * Detaillierte Setup-Hinweise nur im Stand (< 3 km/h für > 10 s).
 */

export type LiveHint = {
  id: string;
  text: string; // ≤ 6 Wörter
  kind: "safety" | "bracketing" | "stand";
};

const WORD_LIMIT = 6;

export function clampHint(text: string): string {
  const words = text.trim().split(/\s+/);
  return words.slice(0, WORD_LIMIT).join(" ");
}

export function hintsFromMetrics(input: {
  speedKmh: number;
  standSeconds: number;
  impactJustDetected: boolean;
  bracketingRunJustCaptured?: number;
  hardImpactStreak: number;
}): LiveHint[] {
  const hints: LiveHint[] = [];

  if (input.bracketingRunJustCaptured) {
    hints.push({
      id: "bracket-run",
      text: clampHint(`Durchgang ${input.bracketingRunJustCaptured} erfasst`),
      kind: "bracketing",
    });
  }

  if (input.impactJustDetected && input.hardImpactStreak >= 3) {
    hints.push({
      id: "impact-streak",
      text: clampHint("Harte Schlagfolge erkannt"),
      kind: "safety",
    });
  }

  // Stand: detaillierter Hinweis erlaubt
  if (input.speedKmh < 3 && input.standSeconds > 10) {
    hints.push({
      id: "stand-setup",
      text: clampHint("Stand: Setup prüfen möglich"),
      kind: "stand",
    });
  }

  return hints;
}

/** Web Speech API Wrapper — fail silently */
export function speakHint(text: string): void {
  if (typeof window === "undefined") return;
  const synth = window.speechSynthesis;
  if (!synth) return;
  const u = new SpeechSynthesisUtterance(clampHint(text));
  u.lang = "de-DE";
  u.rate = 1.05;
  synth.cancel();
  synth.speak(u);
}
