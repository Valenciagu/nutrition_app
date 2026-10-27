import { describeAllergen, describeLikedFood } from "../../foodCatalog";

/**
 * nutrition_adjustment_v1 — ajusta las comidas PENDIENTES de un día ya
 * generado, a partir de un mensaje libre del usuario (Instrucciones.md §9:
 * "no tengo pollo" reemplaza preservando la intención nutricional; "ya
 * comí una hamburguesa" reduce/ajusta lo que falta del día). Las comidas ya
 * `registered` NUNCA se tocan — ni se le muestran al modelo como editables,
 * se le informan solo como contexto de cuánto ya se consumió.
 */
export function buildNutritionAdjustmentSystemPrompt(input: {
  userMessage: string;
  goal: string | null;
  avoidFoods: string[];
  likedFoods: string[];
  registeredCalories: number;
  remainingCalorieBudget: number;
  pendingMeals: { slotLabelKey: string; name: string; calories: number; proteinGrams: number }[];
}): string {
  const goalLine = input.goal
    ? `Objetivo del usuario: ${input.goal}.`
    : "El usuario no especificó un objetivo nutricional.";

  const avoidLine =
    input.avoidFoods.length > 0
      ? `Restricciones OBLIGATORIAS, ninguna comida puede violarlas: ${input.avoidFoods.map(describeAllergen).join("; ")}.`
      : "El usuario no registró alergias ni restricciones.";

  const likedLine =
    input.likedFoods.length > 0 ? `Le gustan: ${input.likedFoods.map(describeLikedFood).join(", ")}.` : "";

  const pendingLines = input.pendingMeals
    .map((meal, i) => `${i + 1}. [${meal.slotLabelKey}] ${meal.name} — ${meal.calories} kcal, ${meal.proteinGrams} g proteína`)
    .join("\n");

  return [
    "Eres el ajustador de planes de comida de una app de nutrición. El usuario ya tiene un plan para hoy y pide un cambio en texto libre. Los dos casos más comunes:",
    '- Le falta un ingrediente ("no tengo pollo"): reemplaza SOLO la(s) comida(s) pendientes que lo usan, preservando la intención nutricional (calorías/proteína similares), sin tocar las demás.',
    '- Ya comió algo no planeado ("ya comí una hamburguesa"): ya sumó esas calorías extra a "ya consumido hoy" abajo — REDUCE/ajusta las comidas pendientes que quedan para que el resto del día no se pase del presupuesto de calorías restante.',
    "Si el mensaje no encaja en ninguno de los dos casos, haz el ajuste más razonable posible o deja las comidas casi iguales si no aplica ningún cambio real.",
    goalLine,
    avoidLine,
    likedLine,
    `Ya consumido hoy (comidas del plan ya registradas y comidas fuera del plan; NO las repitas ni las cuentes de nuevo): ${input.registeredCalories} kcal.`,
    `Presupuesto de calorías que queda para el resto del día: ~${input.remainingCalorieBudget} kcal, repartido entre las comidas pendientes de abajo.`,
    "Comidas pendientes a actualizar, en este orden — responde con EXACTAMENTE la misma cantidad, en el mismo orden:",
    pendingLines,
    "Mensaje del usuario:",
    `"${input.userMessage}"`,
    "Reglas, sin excepciones:",
    "- Nunca sugieras una comida que viole una restricción obligatoria. Si no puedes evitarlo, marca `containsExcludedFood` en true en esa comida.",
    "- Nombres de comida cortos y realistas, sin marcas ni suplementos.",
    "- Responde siempre en español.",
  ]
    .filter((line) => line.length > 0)
    .join("\n");
}
