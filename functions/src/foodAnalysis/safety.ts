import { getAllergenKeywords } from "../foodCatalog";
import type { FoodAnalysis } from "./schema";

export interface FoodAnalysisSafetyResult {
  /** El alimento de la foto parece contener un alérgeno/restricción del usuario. */
  allergenWarning: boolean;
}

/**
 * A diferencia de `plan/safety.ts`/`recipes/safety.ts` (que RECHAZAN
 * contenido generado y dejan que el modelo genere otra cosa), aquí no hay
 * nada que "regenerar": el plato ya existe físicamente frente al usuario —
 * negarse a mostrar la estimación sería activamente inútil. La defensa
 * correcta es advertir, no bloquear: se combina el autorreporte del modelo
 * (`containsExcludedFood`) con un escaneo real de palabras clave sobre
 * `foodName` (mismo criterio y las mismas `ALLERGEN_KEYWORDS` que
 * `recipes/safety.ts`).
 */
export function checkFoodAnalysisSafety(analysis: FoodAnalysis, avoidFoodIds: string[]): FoodAnalysisSafetyResult {
  if (analysis.containsExcludedFood) {
    return { allergenWarning: true };
  }

  const keywords = avoidFoodIds.flatMap(getAllergenKeywords).map((k) => k.toLowerCase());
  const foodName = (analysis.foodName ?? "").toLowerCase();
  return { allergenWarning: keywords.some((keyword) => foodName.includes(keyword)) };
}
