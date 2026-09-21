import type { GeneratedMeal } from "./schema";

export interface PlanSafetyResult {
  safe: boolean;
  reason?: "excluded_food_flagged" | "calorie_total_out_of_range";
}

/**
 * Capa de seguridad determinística para el plan generado — nunca confiar
 * solo en el LLM (Instrucciones.md §11, §38). Dos chequeos:
 *
 * 1. Ninguna comida puede haberse auto-marcado `containsExcludedFood`. A
 *    diferencia de `askNutritionAssistant` (Épica 5), aquí NO se hace
 *    además un chequeo de substring del nombre contra la lista de
 *    alérgenos — un nombre de comida como "Pasta alfredo" no contiene la
 *    palabra "gluten" ni "lactose" aunque los tenga, así que ese chequeo
 *    daría una falsa sensación de seguridad. La defensa real aquí es la
 *    instrucción explícita del prompt + esta bandera auto-reportada;
 *    quedará un chequeo determinístico fuerte de verdad (ingrediente por
 *    ingrediente) cuando exista `Recipe` (Épica 7) — ver
 *    `documentation/plan.md`.
 * 2. La suma de calorías del plan no puede desviarse demasiado del
 *    objetivo calculado — protege contra un plan nutricionalmente
 *    absurdo (p. ej. 400 kcal totales o 6000 kcal totales).
 */
export function checkPlanSafety(meals: GeneratedMeal[], targetCalories: number): PlanSafetyResult {
  if (meals.some((meal) => meal.containsExcludedFood)) {
    return { safe: false, reason: "excluded_food_flagged" };
  }

  const totalCalories = meals.reduce((sum, meal) => sum + meal.calories, 0);
  const minAcceptable = targetCalories * 0.6;
  const maxAcceptable = targetCalories * 1.4;
  if (totalCalories < minAcceptable || totalCalories > maxAcceptable) {
    return { safe: false, reason: "calorie_total_out_of_range" };
  }

  return { safe: true };
}
