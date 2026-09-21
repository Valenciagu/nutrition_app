import { z } from "zod";

/**
 * Salida estructurada del modelo para `generateRecipe` (prompt
 * `recipe_generation_v1`). Deliberadamente NO incluye `calories` ni
 * `proteinGrams`: esos ya se conocen de forma determinística de la
 * `PlannedMeal` que originó la receta (Épica 6) — pedírselos de nuevo al
 * modelo solo abriría la puerta a que el kcal mostrado en el plan (D1) y en
 * el detalle de receta (D3) queden desincronizados. El modelo solo aporta lo
 * que todavía no se sabe: descripción, tiempo, dificultad, carbos/grasas,
 * ingredientes y pasos. `servings` tampoco se pide — siempre es 1 (ver
 * `generateRecipe.ts`), igual al criterio "Ingredientes · 1 ración" del
 * diseño (D3, `documentation/design_screens_plan.md`).
 */
export const GeneratedRecipeIngredientSchema = z.object({
  name: z.string().min(2).max(60),
  quantity: z.string().min(1).max(30),
  substitutes: z.array(z.string().min(2).max(60)).max(3),
});

export const GeneratedRecipeStepSchema = z.object({
  instruction: z.string().min(5).max(240),
  /** `null` si el paso no implica esperar nada (p. ej. "pica la cebolla"). */
  timerSeconds: z.number().int().min(10).max(3600).nullable(),
});

export const GeneratedRecipeSchema = z.object({
  description: z.string().min(10).max(200),
  prepTimeMinutes: z.number().int().min(5).max(180),
  difficulty: z.enum(["easy", "medium", "hard"]),
  carbsGrams: z.number().int().min(0).max(300),
  fatGrams: z.number().int().min(0).max(200),
  ingredients: z.array(GeneratedRecipeIngredientSchema).min(2).max(12),
  steps: z.array(GeneratedRecipeStepSchema).min(2).max(12),
  containsExcludedFood: z
    .boolean()
    .describe("true if any ingredient contains one of the user's excluded allergens/foods, listed in the prompt"),
});

export type GeneratedRecipe = z.infer<typeof GeneratedRecipeSchema>;
