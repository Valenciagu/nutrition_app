import { z } from "zod";

/**
 * Salida estructurada del modelo para `generateDailyPlan` (prompt
 * `nutrition_plan_v1`). El modelo SOLO genera esto — no el
 * `slotLabelKey`/hora de cada comida (eso viene determinísticamente de
 * `mealSlots` del propio usuario, ver `generateDailyPlan.ts`) — así se
 * elimina de raíz la posibilidad de que el modelo devuelva una comida con
 * la etiqueta de horario equivocada. Instrucciones.md §37-38: nunca
 * deserializar a ciegas la salida de la IA.
 */
export const GeneratedMealSchema = z.object({
  name: z.string().min(3).max(80),
  calories: z.number().int().min(50).max(2500),
  proteinGrams: z.number().int().min(0).max(200),
  containsExcludedFood: z
    .boolean()
    .describe("true if this meal contains any of the user's excluded allergens/foods, listed in the prompt"),
});

export const NutritionPlanGenerationSchema = z.object({
  meals: z.array(GeneratedMealSchema).min(1).max(6),
});

/** D4 — 3 alternativas para UNA comida (`suggestMealAlternatives`). */
export const MealAlternativesSchema = z.object({
  alternatives: z.array(GeneratedMealSchema).min(3).max(3),
});

export type GeneratedMeal = z.infer<typeof GeneratedMealSchema>;
export type NutritionPlanGeneration = z.infer<typeof NutritionPlanGenerationSchema>;
export type MealAlternatives = z.infer<typeof MealAlternativesSchema>;
