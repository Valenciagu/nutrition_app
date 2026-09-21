import { getAllergenKeywords } from "../foodCatalog";
import type { GeneratedRecipe } from "./schema";

export interface RecipeSafetyResult {
  safe: boolean;
  reason?: "excluded_food_flagged" | "excluded_ingredient_detected" | "macros_inconsistent";
}

/**
 * Capa de seguridad determinística para una receta generada — nunca confiar
 * solo en el LLM (Instrucciones.md §11, §38). Tres chequeos:
 *
 * 1. Autorreporte del modelo (`containsExcludedFood`), igual que
 *    `plan/safety.ts`.
 * 2. NUEVO respecto a `plan/safety.ts`: un escaneo real ingrediente por
 *    ingrediente contra `ALLERGEN_KEYWORDS` — esto es lo que
 *    `plan/safety.ts` documentaba como pendiente ("un nombre de comida no
 *    contiene la palabra 'gluten' aunque la tenga") porque ahí no existía
 *    todavía una lista de ingredientes real. Aquí sí existe, así que este
 *    chequeo es la defensa fuerte de verdad, no solo la instrucción del
 *    prompt + la bandera autorreportada.
 * 3. Consistencia de macros: `proteinGrams`/`carbsGrams`/`fatGrams`
 *    (4/4/9 kcal por gramo) no puede desviarse demasiado de las `calories`
 *    ya fijadas por la `PlannedMeal` — protege contra una receta cuyos
 *    carbohidratos/grasas inventados no cuadran con las calorías reales.
 */
export function checkRecipeSafety(
  recipe: GeneratedRecipe,
  avoidFoodIds: string[],
  mealCalories: number,
  mealProteinGrams: number,
): RecipeSafetyResult {
  if (recipe.containsExcludedFood) {
    return { safe: false, reason: "excluded_food_flagged" };
  }

  const keywords = avoidFoodIds.flatMap(getAllergenKeywords).map((k) => k.toLowerCase());
  const ingredientNames = recipe.ingredients.map((i) => i.name.toLowerCase());
  if (keywords.some((keyword) => ingredientNames.some((name) => name.includes(keyword)))) {
    return { safe: false, reason: "excluded_ingredient_detected" };
  }

  const macroCalories = mealProteinGrams * 4 + recipe.carbsGrams * 4 + recipe.fatGrams * 9;
  const minAcceptable = mealCalories * 0.6;
  const maxAcceptable = mealCalories * 1.4;
  if (macroCalories < minAcceptable || macroCalories > maxAcceptable) {
    return { safe: false, reason: "macros_inconsistent" };
  }

  return { safe: true };
}
