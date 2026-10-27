import { test } from "node:test";
import assert from "node:assert/strict";
import { checkPlanSafety } from "../src/plan/safety";
import { checkRecipeSafety } from "../src/recipes/safety";
import { checkFoodAnalysisSafety } from "../src/foodAnalysis/safety";
import { checkNutritionAssistantSafety } from "../src/ai/safety";
import type { GeneratedMeal } from "../src/plan/schema";
import type { GeneratedRecipe } from "../src/recipes/schema";
import type { FoodAnalysis } from "../src/foodAnalysis/schema";
import { filterSafeSuggestedRecipes } from "../src/ingredients/safety";
import type { SuggestedRecipe } from "../src/ingredients/schema";
import { sanitizeNameList } from "../src/ingredients/input";

test("ingredientes: la lista del cliente se limpia y se acota", () => {
  assert.deepEqual(sanitizeNameList(["  Huevos ", "huevos", "", 3, "Tomate   cherry", null], 10), ["Huevos", "Tomate cherry"]);
  assert.deepEqual(sanitizeNameList("Huevos", 10), []);
  assert.equal(sanitizeNameList(["a", "b", "c"], 2).length, 2);
  assert.equal(sanitizeNameList(["x".repeat(500)], 1)[0].length, 80);
});

const meal = (calories: number, containsExcludedFood = false): GeneratedMeal => ({
  name: "Comida",
  calories,
  proteinGrams: 20,
  dishCategory: "protein_plate",
  containsExcludedFood,
});

test("plan: acepta un total dentro de ±40% del objetivo", () => {
  assert.deepEqual(checkPlanSafety([meal(700), meal(700), meal(600)], 2000), { safe: true });
});

test("plan: rechaza un total absurdo por debajo o por encima", () => {
  assert.equal(checkPlanSafety([meal(400)], 2000).reason, "calorie_total_out_of_range");
  assert.equal(checkPlanSafety([meal(2500), meal(2500)], 2000).reason, "calorie_total_out_of_range");
});

test("plan: rechaza una comida autorreportada con alimento excluido", () => {
  assert.equal(checkPlanSafety([meal(2000, true)], 2000).reason, "excluded_food_flagged");
});

const recipe = (overrides: Partial<GeneratedRecipe> = {}): GeneratedRecipe => ({
  description: "Una receta de prueba",
  prepTimeMinutes: 20,
  difficulty: "easy",
  dishCategory: "bowl",
  carbsGrams: 50,
  fatGrams: 15,
  ingredients: [
    { name: "Pechuga de pollo", quantity: "150 g", substitutes: [] },
    { name: "Arroz", quantity: "1 taza", substitutes: [] },
  ],
  steps: [
    { instruction: "Cocina el arroz.", timerSeconds: 900 },
    { instruction: "Asa el pollo.", timerSeconds: null },
  ],
  containsExcludedFood: false,
  ...overrides,
});

test("receta: macros consistentes con las calorías pasan", () => {
  // 30*4 + 50*4 + 15*9 = 455 kcal frente a 450.
  assert.deepEqual(checkRecipeSafety(recipe(), [], 450, 30), { safe: true });
});

test("receta: detecta un ingrediente con alérgeno aunque el modelo no lo marque", () => {
  const withBread = recipe({
    ingredients: [
      { name: "Pan integral", quantity: "2", substitutes: [] },
      { name: "Huevo", quantity: "1", substitutes: [] },
    ],
  });
  assert.equal(checkRecipeSafety(withBread, ["gluten"], 450, 30).reason, "excluded_ingredient_detected");
  assert.equal(checkRecipeSafety(withBread, ["egg"], 450, 30).reason, "excluded_ingredient_detected");
});

test("receta: un id de restricción desconocido se busca literal", () => {
  assert.equal(checkRecipeSafety(recipe(), ["arroz"], 450, 30).reason, "excluded_ingredient_detected");
});

test("receta: macros que no cuadran con las calorías se rechazan", () => {
  assert.equal(checkRecipeSafety(recipe({ carbsGrams: 200, fatGrams: 100 }), [], 450, 30).reason, "macros_inconsistent");
});

const suggested = (name: string, overrides: Partial<SuggestedRecipe> = {}): SuggestedRecipe => ({
  ...recipe(),
  name,
  calories: 455,
  proteinGrams: 30,
  missingIngredients: [],
  ...overrides,
});

test("ingredientes: descarta solo las recetas inseguras y conserva el resto", () => {
  const safe = suggested("Arroz con pollo");
  const flagged = suggested("Con maní", { containsExcludedFood: true });
  const badMacros = suggested("Rara", { calories: 1500 });
  assert.deepEqual(
    filterSafeSuggestedRecipes([safe, flagged, badMacros], []).map((r) => r.name),
    ["Arroz con pollo"],
  );
});

test("ingredientes: un alérgeno en lo que falta comprar también descarta la receta", () => {
  const needsBread = suggested("Sándwich", { missingIngredients: ["Pan tajado"] });
  assert.deepEqual(filterSafeSuggestedRecipes([needsBread], ["gluten"]), []);
  assert.equal(filterSafeSuggestedRecipes([needsBread], []).length, 1);
});

const analysis = (foodName: string | null, containsExcludedFood = false): FoodAnalysis => ({
  isFoodPhoto: true,
  foodName,
  portionDescription: "un plato",
  estimatedCalories: 500,
  estimatedProteinGrams: 20,
  estimatedCarbsGrams: 60,
  estimatedFatGrams: 15,
  confidence: "medium",
  uncertaintyNote: "Estimación aproximada.",
  containsExcludedFood,
});

test("foto: advierte (no bloquea) por palabra clave en el nombre", () => {
  assert.deepEqual(checkFoodAnalysisSafety(analysis("Pasta con queso"), ["lactose"]), { allergenWarning: true });
  assert.deepEqual(checkFoodAnalysisSafety(analysis("Ensalada verde"), ["lactose"]), { allergenWarning: false });
});

test("foto: respeta el autorreporte y tolera nombre nulo", () => {
  assert.deepEqual(checkFoodAnalysisSafety(analysis(null, true), []), { allergenWarning: true });
  assert.deepEqual(checkFoodAnalysisSafety(analysis(null), ["nuts"]), { allergenWarning: false });
});

test("asistente: bloquea respuestas que mencionan un alimento evitado o instrucciones de medicación", () => {
  const ok = { answer: "Prueba una ensalada con pollo.", mentionsRestrictedFood: false };
  assert.deepEqual(checkNutritionAssistantSafety(ok as never, ["maní"]), { safe: true });

  const peanut = { answer: "Agrega maní tostado.", mentionsRestrictedFood: false };
  assert.equal(checkNutritionAssistantSafety(peanut as never, ["Maní "]).reason, "restricted_food_mentioned");

  const meds = { answer: "Puedes dejar de tomar tu medicamento.", mentionsRestrictedFood: false };
  assert.equal(checkNutritionAssistantSafety(meds as never, []).reason, "medication_instruction_detected");
});
