import { describeAllergen, describeLikedFood } from "../../foodCatalog";

/**
 * recipe_generation_v1 — prompt de sistema centralizado y versionado
 * (Instrucciones.md §76). Genera la receta completa de UNA comida ya
 * existente en el plan del usuario (nombre/calorías/proteína ya fijos, ver
 * `generateRecipe.ts` y `schema.ts`).
 */
export function buildRecipeGenerationSystemPrompt(input: {
  mealName: string;
  targetCalories: number;
  targetProteinGrams: number;
  avoidFoods: string[];
  likedFoods: string[];
  cookingTimePreference: string | null;
  budgetLevel: string | null;
}): string {
  const avoidLine =
    input.avoidFoods.length > 0
      ? `Restricciones OBLIGATORIAS, ningún ingrediente puede violarlas: ${input.avoidFoods.map(describeAllergen).join("; ")}.`
      : "El usuario no registró alergias ni restricciones alimentarias.";

  const likedLine =
    input.likedFoods.length > 0
      ? `Al usuario le gustan estos alimentos — priorízalos como ingredientes cuando tenga sentido: ${input.likedFoods.map(describeLikedFood).join(", ")}.`
      : "";

  const cookingLine = input.cookingTimePreference
    ? `Preferencia de tiempo de cocina: ${input.cookingTimePreference}.`
    : "";

  const budgetLine = input.budgetLevel ? `Nivel de presupuesto: ${input.budgetLevel}.` : "";

  return [
    `Eres el generador de recetas de una app de nutrición. Genera la receta completa para preparar exactamente "${input.mealName}", para 1 ración.`,
    `Esta receta, para 1 ración, debe aportar aproximadamente ${input.targetCalories} kcal y ${input.targetProteinGrams} g de proteína en total (ya fijos — reparte los carbohidratos y grasas que generes de forma consistente con esas calorías: 4 kcal/g proteína, 4 kcal/g carbohidrato, 9 kcal/g grasa).`,
    avoidLine,
    likedLine,
    cookingLine,
    budgetLine,
    "Reglas, sin excepciones:",
    "- Nunca incluyas un ingrediente que viole una restricción obligatoria. Si por alguna razón no puedes evitarlo, marca `containsExcludedFood` en true.",
    "- Ingredientes con nombre + cantidad concreta (ej. 'Pechuga de pollo' / '200 g'), sin viñetas ni numeración en el texto.",
    "- Pasos claros y cortos, en orden real de preparación; usa `timerSeconds` solo en pasos que de verdad implican esperar (hornear, hervir, marinar), y déjalo en null en los demás (cortar, mezclar, servir).",
    "- No inventes suplementos ni productos de marca.",
    "- Responde siempre en español.",
  ]
    .filter((line) => line.length > 0)
    .join("\n");
}
