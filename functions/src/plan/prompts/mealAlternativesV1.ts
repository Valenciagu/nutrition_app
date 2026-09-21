import { describeAllergen, describeLikedFood } from "../../foodCatalog";

/**
 * meal_alternatives_v1 — 3 alternativas para UNA comida pendiente (D4:
 * "Otra cena para hoy"), con macros similares a la original. `filterHint`
 * es el chip que tocó el usuario ("Más rápido", "Más ligera") o un pedido
 * libre ("Pedir otra a la IA" → el usuario puede no escribir nada, en cuyo
 * caso solo se pide variedad).
 */
export function buildMealAlternativesSystemPrompt(input: {
  slotLabelKey: string;
  currentMealName: string;
  targetCalories: number;
  targetProteinGrams: number;
  avoidFoods: string[];
  likedFoods: string[];
  filterHint: string | null;
}): string {
  const avoidLine =
    input.avoidFoods.length > 0
      ? `Restricciones OBLIGATORIAS, ninguna alternativa puede violarlas: ${input.avoidFoods.map(describeAllergen).join("; ")}.`
      : "El usuario no registró alergias ni restricciones.";

  const likedLine =
    input.likedFoods.length > 0 ? `Le gustan: ${input.likedFoods.map(describeLikedFood).join(", ")}.` : "";

  const filterLine = input.filterHint ? `Preferencia para estas alternativas: ${input.filterHint}.` : "";

  return [
    `Genera exactamente 3 alternativas distintas entre sí para reemplazar "${input.currentMealName}" (franja: ${input.slotLabelKey}).`,
    `Cada alternativa debe tener macros similares a la original: ~${input.targetCalories} kcal y ~${input.targetProteinGrams} g de proteína (con algo de variación razonable entre las 3, no idénticas).`,
    "Mismos macros, con lo que ya tienes en casa: prioriza ingredientes comunes, no recetas exóticas.",
    avoidLine,
    likedLine,
    filterLine,
    "Reglas, sin excepciones:",
    "- Nunca sugieras una alternativa que viole una restricción obligatoria. Si no puedes evitarlo, marca `containsExcludedFood` en true en esa alternativa.",
    "- Nombres cortos y realistas, sin marcas ni suplementos.",
    "- Responde siempre en español.",
  ]
    .filter((line) => line.length > 0)
    .join("\n");
}
