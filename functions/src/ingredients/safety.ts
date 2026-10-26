import { checkRecipeSafety } from "../recipes/safety";
import type { SuggestedRecipe } from "./schema";

/**
 * Capa de seguridad determinística (Instrucciones.md §11, §38) para las
 * recetas sugeridas desde una foto de ingredientes. Reusa
 * `checkRecipeSafety` (Épica 7) tal cual — autorreporte, escaneo de
 * alérgenos ingrediente por ingrediente (incluidos los faltantes) y
 * consistencia de macros contra las calorías que la propia receta declara.
 *
 * A diferencia de `generateRecipe`, aquí hay 3 candidatas independientes:
 * se DESCARTAN las inseguras en vez de rechazar toda la respuesta. Solo si
 * no queda ninguna, la función lo trata como fallo (ver
 * `suggestRecipesFromIngredients.ts`).
 */
export function filterSafeSuggestedRecipes(recipes: SuggestedRecipe[], avoidFoodIds: string[]): SuggestedRecipe[] {
  return recipes.filter((recipe) => {
    const withMissing = {
      ...recipe,
      ingredients: [
        ...recipe.ingredients,
        ...recipe.missingIngredients.map((name) => ({ name, quantity: "-", substitutes: [] })),
      ],
    };
    return checkRecipeSafety(withMissing, avoidFoodIds, recipe.calories, recipe.proteinGrams).safe;
  });
}
