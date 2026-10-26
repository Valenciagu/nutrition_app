import { z } from "zod";
import { GeneratedRecipeSchema } from "../recipes/schema";

/**
 * Una receta sugerida a partir de una foto de ingredientes (Épica 9). Reusa
 * `GeneratedRecipeSchema` (Épica 7) y le agrega lo que una receta de plan ya
 * trae fijo desde `PlannedMeal` — nombre, calorías y proteína — más
 * `missingIngredients`: lo que el usuario tendría que conseguir aparte de lo
 * que se ve en la foto (vacío si alcanza con eso + básicos de despensa).
 */
export const SuggestedRecipeSchema = GeneratedRecipeSchema.extend({
  name: z.string().min(3).max(80),
  calories: z.number().int().min(150).max(1500),
  proteinGrams: z.number().int().min(0).max(150),
  missingIngredients: z
    .array(z.string().min(2).max(60))
    .max(6)
    .describe("ingredients the recipe needs that are NOT visible in the photo (salt, oil and water don't count)"),
});

export const IngredientRecipesSchema = z.object({
  isIngredientPhoto: z
    .boolean()
    .describe("false if the photo does not show food ingredients (fridge, pantry, groceries, packages)"),
  detectedIngredients: z
    .array(z.string().min(2).max(60))
    .max(25)
    .describe("ingredients you can actually see, in Spanish, most relevant first; empty if isIngredientPhoto is false"),
  recipes: z.array(SuggestedRecipeSchema).max(3).describe("exactly 3 when isIngredientPhoto is true, empty otherwise"),
});

export type SuggestedRecipe = z.infer<typeof SuggestedRecipeSchema>;
export type IngredientRecipes = z.infer<typeof IngredientRecipesSchema>;
