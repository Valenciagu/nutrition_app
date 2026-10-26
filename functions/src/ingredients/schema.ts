import { z } from "zod";
import { GeneratedRecipeSchema } from "../recipes/schema";

/**
 * F1 (Fase 6): lo que se ve en la foto. `confident: false` = el modelo duda
 * (tapado, borroso, se parece a otra cosa) — la app lo muestra con borde
 * punteado para que el usuario lo confirme o lo quite, en vez de un
 * porcentaje (decisión del canvas).
 */
export const DetectedIngredientsSchema = z.object({
  isIngredientPhoto: z
    .boolean()
    .describe("false if the photo does not show food ingredients (fridge, pantry, groceries, packages)"),
  ingredients: z
    .array(
      z.object({
        name: z.string().min(2).max(40).describe("generic ingredient name in Spanish, no brands, e.g. 'Huevos'"),
        confident: z.boolean().describe("false when it is partly hidden, blurry or could be something else"),
      }),
    )
    .max(25)
    .describe("only what is actually visible, most relevant first; empty if isIngredientPhoto is false"),
});

/**
 * Una receta sugerida (F2). Reusa `GeneratedRecipeSchema` (Épica 7) y le
 * agrega lo que una receta de plan ya trae fijo desde `PlannedMeal` —
 * nombre, calorías y proteína — más `missingIngredients`: lo que haría falta
 * además de la lista del usuario (vacío = badge "Tienes todo").
 */
export const SuggestedRecipeSchema = GeneratedRecipeSchema.extend({
  name: z.string().min(3).max(80),
  calories: z.number().int().min(150).max(1500),
  proteinGrams: z.number().int().min(0).max(150),
  missingIngredients: z
    .array(z.string().min(2).max(40))
    .max(6)
    .describe("ingredients the recipe needs that are NOT in the user's list (salt, pepper, oil and water don't count)"),
});

export const IngredientRecipesSchema = z.object({
  recipes: z.array(SuggestedRecipeSchema).min(1).max(3),
});

export type DetectedIngredients = z.infer<typeof DetectedIngredientsSchema>;
export type SuggestedRecipe = z.infer<typeof SuggestedRecipeSchema>;
export type IngredientRecipes = z.infer<typeof IngredientRecipesSchema>;
