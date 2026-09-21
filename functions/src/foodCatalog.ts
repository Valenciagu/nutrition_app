/**
 * Mismos IDs estables de `lib/features/onboarding/presentation/onboarding_catalog.dart`
 * (`likedFoodCatalogIds`/`allergenCatalogIds`) — no un import cruzado (Dart
 * y Node no comparten runtime), sino la misma convención de vocabulario a
 * propósito, igual que `slotLabelKey` en `PlannedMeal` reusa las claves de
 * `MealSlot`. Si el catálogo de Onboarding cambia, este mapa debe
 * actualizarse junto con él.
 *
 * Vive en la raíz de `functions/src/` (no dentro de `plan/`) porque tanto
 * `plan/` como `recipes/` lo necesitan — mover un archivo compartido a la
 * raíz en vez de que una feature importe de otra, mismo criterio que
 * `core/` en el árbol Dart.
 *
 * Las instrucciones de alérgenos son más explícitas que solo el ID en
 * inglés — le dicen al modelo QUÉ excluir en términos concretos, no solo
 * la categoría, porque la validación determinística real (buscar el ID
 * literal en el nombre de una comida) no es confiable a este nivel: una
 * comida llamada "Pasta alfredo" no contiene la palabra "gluten" ni
 * "lactose" aunque los tenga. Ver `plan/safety.ts` (a nivel de comida) y
 * `recipes/safety.ts` (a nivel de ingrediente, con `ALLERGEN_KEYWORDS`
 * abajo) para el resto de la defensa.
 */
export const ALLERGEN_INSTRUCTIONS: Record<string, string> = {
  lactose: "sin lácteos ni lactosa",
  gluten: "sin gluten (nada de trigo, cebada, centeno, pan o pasta tradicional)",
  nuts: "sin frutos secos",
  shellfish: "sin mariscos ni crustáceos",
  egg: "sin huevo",
  soy: "sin soya",
  fish: "sin pescado",
  sesame: "sin sésamo ni ajonjolí",
};

export function describeAllergen(id: string): string {
  return ALLERGEN_INSTRUCTIONS[id] ?? `sin ${id}`;
}

const LIKED_FOOD_LABELS: Record<string, string> = {
  chicken: "pollo",
  meat: "carne roja",
  fish: "pescado",
  eggs: "huevo",
  avocado: "aguacate",
  rice: "arroz",
  legumes: "legumbres",
  pasta: "pasta",
  tofu: "tofu",
};

export function describeLikedFood(id: string): string {
  return LIKED_FOOD_LABELS[id] ?? id;
}

/**
 * Palabras clave en español para el chequeo determinístico
 * ingrediente-por-ingrediente de `recipes/safety.ts` — a diferencia de
 * `ALLERGEN_INSTRUCTIONS` (que solo alimenta el prompt), esto se usa para
 * buscar coincidencias reales dentro de cada ingrediente que la IA generó.
 * Cierra el hueco de seguridad documentado en `documentation/plan.md`: el
 * nombre de una COMIDA como "Pasta alfredo" no contiene la palabra
 * "gluten", pero su lista de INGREDIENTES sí va a tener "harina de trigo" —
 * ahí es donde este chequeo aplica de verdad, algo que a nivel de
 * `plan/safety.ts` (sin ingredientes todavía) no era posible.
 *
 * Substring simple, igual criterio que `ai/safety.ts`
 * (`checkNutritionAssistantSafety`) — no tokenización por palabra completa.
 * Es una decisión deliberada: para alérgenos, un falso positivo (rechazar
 * una receta válida, p. ej. "panela" activando "pan") es el modo de fallo
 * seguro; un falso negativo (dejar pasar un alérgeno real) no lo es.
 */
export const ALLERGEN_KEYWORDS: Record<string, string[]> = {
  lactose: ["leche", "lácte", "lactea", "queso", "yogur", "mantequilla", "crema de leche", "nata"],
  gluten: ["trigo", "harina", "pan", "pasta", "cebada", "centeno", "gluten", "cuscús", "sémola", "avena"],
  nuts: ["nuez", "nueces", "almendra", "avellana", "maní", "cacahuate", "pistacho", "anacardo", "macadamia"],
  shellfish: ["camarón", "camarones", "langosta", "cangrejo", "marisco", "mejillón", "ostra", "langostino", "calamar"],
  egg: ["huevo"],
  soy: ["soya", "soja", "tofu", "edamame"],
  fish: ["pescado", "atún", "salmón", "bacalao", "trucha", "tilapia", "anchoa"],
  sesame: ["sésamo", "ajonjolí", "tahini"],
};

export function getAllergenKeywords(id: string): string[] {
  return ALLERGEN_KEYWORDS[id] ?? [id];
}
