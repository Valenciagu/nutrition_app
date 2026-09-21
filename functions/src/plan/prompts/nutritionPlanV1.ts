import { describeAllergen, describeLikedFood } from "../../foodCatalog";

/**
 * nutrition_plan_v1 — prompt de sistema centralizado y versionado
 * (Instrucciones.md §76). Bump a `nutritionPlanV2.ts` para cambios de
 * comportamiento en vez de editar este en silencio.
 */
export function buildNutritionPlanSystemPrompt(input: {
  goal: string | null;
  activityLevel: string;
  targetCalories: number;
  avoidFoods: string[];
  likedFoods: string[];
  cookingTimePreference: string | null;
  budgetLevel: string | null;
  slotLabelKeys: string[];
}): string {
  const goalLine = input.goal
    ? `Objetivo del usuario: ${input.goal}.`
    : "El usuario no especificó un objetivo nutricional; asume un plan de alimentación saludable general.";

  const avoidLine =
    input.avoidFoods.length > 0
      ? `Restricciones OBLIGATORIAS, ninguna comida puede violarlas: ${input.avoidFoods.map(describeAllergen).join("; ")}.`
      : "El usuario no registró alergias ni restricciones alimentarias.";

  const likedLine =
    input.likedFoods.length > 0
      ? `Al usuario le gustan estos alimentos — priorízalos cuando tenga sentido: ${input.likedFoods.map(describeLikedFood).join(", ")}.`
      : "";

  const cookingLine = input.cookingTimePreference
    ? `Preferencia de tiempo de cocina: ${input.cookingTimePreference}.`
    : "";

  const budgetLine = input.budgetLevel ? `Nivel de presupuesto: ${input.budgetLevel}.` : "";

  return [
    "Eres el generador de planes de comida de una app de nutrición. Generas UNA comida por cada franja horaria del día del usuario, en el mismo orden en que se te dan las franjas.",
    goalLine,
    `Nivel de actividad: ${input.activityLevel}.`,
    `Meta total de calorías del día: aproximadamente ${input.targetCalories} kcal, repartidas entre las ${input.slotLabelKeys.length} comidas (franjas: ${input.slotLabelKeys.join(", ")}) de forma razonable — no todas iguales, ajusta según el tipo de comida (el desayuno y las meriendas suelen pesar menos que el almuerzo o la cena).`,
    avoidLine,
    likedLine,
    cookingLine,
    budgetLine,
    "Reglas, sin excepciones:",
    "- Nunca sugieras una comida que viole una restricción obligatoria. Si por alguna razón no puedes evitarlo, marca `containsExcludedFood` en true en esa comida.",
    "- Cada comida debe tener un nombre corto y realista (ej. 'Pollo al limón con brócoli'), no una descripción larga.",
    "- No inventes suplementos ni productos de marca.",
    "- Responde siempre en español.",
  ]
    .filter((line) => line.length > 0)
    .join("\n");
}
