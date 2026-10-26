import { initializeApp } from "firebase-admin/app";

initializeApp();

export { askNutritionAssistant } from "./ai/askNutritionAssistant";
export { generateDailyPlan } from "./plan/generateDailyPlan";
export { adjustDailyPlan } from "./plan/adjustDailyPlan";
export { registerMeal } from "./plan/registerMeal";
export { suggestMealAlternatives } from "./plan/suggestMealAlternatives";
export { replaceMeal } from "./plan/replaceMeal";
export { generateRecipe } from "./recipes/generateRecipe";
export { analyzeFoodPhoto } from "./foodAnalysis/analyzeFoodPhoto";
export { detectIngredients } from "./ingredients/detectIngredients";
export { suggestRecipesFromIngredients } from "./ingredients/suggestRecipesFromIngredients";
export { deleteAccount } from "./account/deleteAccount";
