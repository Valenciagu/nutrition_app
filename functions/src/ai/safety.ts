import type { NutritionAssistantResponse } from "./schema";

const MEDICATION_PATTERNS = [
  /deja(r)?\s+(de\s+)?tomar/i,
  /suspende(r)?\s+(tu|el|la)?\s*(medicamento|medicina|pastilla|f[aá]rmaco)/i,
  /cambia(r)?\s+(tu\s+)?dosis/i,
  /stop taking/i,
  /change your dosage/i,
];

export interface SafetyCheckResult {
  safe: boolean;
  reason?: "restricted_food_mentioned" | "medication_instruction_detected";
}

/**
 * Deterministic safety net layered on top of the model's own self-reported
 * flags — never rely solely on the LLM to judge whether a recommendation is
 * safe (Instrucciones.md §11, §38). Runs after schema validation, before the
 * response ever reaches Flutter.
 */
export function checkNutritionAssistantSafety(
  response: NutritionAssistantResponse,
  avoidFoods: string[],
): SafetyCheckResult {
  if (response.mentionsRestrictedFood) {
    return { safe: false, reason: "restricted_food_mentioned" };
  }

  const lowerAnswer = response.answer.toLowerCase();
  for (const food of avoidFoods) {
    const trimmed = food.trim().toLowerCase();
    if (trimmed.length > 0 && lowerAnswer.includes(trimmed)) {
      return { safe: false, reason: "restricted_food_mentioned" };
    }
  }

  if (MEDICATION_PATTERNS.some((pattern) => pattern.test(response.answer))) {
    return { safe: false, reason: "medication_instruction_detected" };
  }

  return { safe: true };
}

/** Shown when the safety layer rejects a response — never display invalid/unsafe content (Instrucciones.md §38). */
export const SAFETY_FALLBACK_ANSWER =
  "No puedo responder esa pregunta con seguridad en este momento. Intenta reformularla, o consulta a un profesional de la salud si se trata de un tema médico.";
