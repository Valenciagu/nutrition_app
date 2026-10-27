import { randomUUID } from "node:crypto";
import type { DishCategory } from "../dishCategory";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { getFirestore } from "firebase-admin/firestore";
import { zodTextFormat } from "openai/helpers/zod";
import { AI_MODELS, getOpenAiClient, openAiApiKey } from "../config/openai";
import { consumeAiQuota, refundAiQuota } from "../ai/quota";
import { estimateDailyCalories, type ActivityLevel, type Sex } from "../plan/calorieEstimate";
import { IngredientRecipesSchema } from "./schema";
import { buildIngredientRecipesSystemPrompt } from "./prompts/ingredientRecipesV1";
import { filterSafeSuggestedRecipes } from "./safety";
import { sanitizeNameList } from "./input";

const QUOTA_FEATURE = "ingredientRecipes";
/** Sin `mealSlots` en el perfil se asume el mismo default que Onboarding (B6). */
const DEFAULT_MEALS_PER_DAY = 4;
const MAX_INGREDIENTS = 30;
const MAX_EXCLUDED_RECIPES = 12;

interface SuggestRecipesRequest {
  /** La lista ya revisada por el usuario en F1 (detectados + añadidos a mano). */
  ingredients: string[];
  /** Recetas ya mostradas — "Pedir más ideas a la IA" pide otras distintas. */
  excludeRecipeNames?: string[];
}

/** Misma forma que `Recipe.toJson()` (Épica 7) + `missingIngredients`. */
interface SuggestedRecipeResponse {
  id: string;
  name: string;
  description: string;
  servings: number;
  prepTimeMinutes: number;
  difficulty: "easy" | "medium" | "hard";
  calories: number;
  proteinGrams: number;
  dishCategory: DishCategory;
  carbsGrams: number;
  fatGrams: number;
  ingredients: { name: string; quantity: string; substitutes: string[] }[];
  steps: { instruction: string; timerSeconds: number | null }[];
  missingIngredients: string[];
}

interface SuggestRecipesResponse {
  recipes: SuggestedRecipeResponse[];
  remainingToday: number;
}

/**
 * Épica 9, paso F2 (Fase 6 del canvas) — lista de ingredientes revisada →
 * hasta 3 recetas de 1 ración (Instrucciones.md §7), cada una con lo que
 * falta conseguir. Sobre texto, sin foto: por eso "Pedir más ideas" puede
 * repetirse (con `excludeRecipeNames`) sin volver a subir ni analizar nada.
 *
 * Seguridad: cada receta pasa por `filterSafeSuggestedRecipes` (alérgenos
 * también en los faltantes, macros consistentes); se descartan solo las
 * inseguras y, si no queda ninguna, error + reembolso. Los nombres que manda
 * el cliente se acotan (`sanitizeNameList`) y el prompt los trata como datos.
 *
 * Nada se persiste: no existe una pantalla de "mis recetas" que vuelva a
 * mostrarlas. Gratis por ahora con su propio límite (`ingredientRecipes`).
 */
export const suggestRecipesFromIngredients = onCall<SuggestRecipesRequest, Promise<SuggestRecipesResponse>>(
  { secrets: [openAiApiKey], region: "us-central1", invoker: "public", enforceAppCheck: true, timeoutSeconds: 120 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión para ver recetas.");
    }

    const ingredients = sanitizeNameList(request.data?.ingredients, MAX_INGREDIENTS);
    if (ingredients.length === 0) {
      throw new HttpsError("invalid-argument", "Agrega al menos un ingrediente.");
    }
    const excludeRecipeNames = sanitizeNameList(request.data?.excludeRecipeNames, MAX_EXCLUDED_RECIPES);

    const uid = request.auth.uid;
    const profile = await fetchProfile(uid);
    const quota = await consumeAiQuota(uid, profile.isPremium, QUOTA_FEATURE);

    try {
      const dailyCalories = estimateDailyCalories({
        sex: profile.sex ?? undefined,
        age: profile.age ?? undefined,
        heightCm: profile.heightCm ?? undefined,
        weightKg: profile.weightKg ?? undefined,
        activityLevel: profile.activityLevel,
      });
      const targetMealCalories = Math.round(dailyCalories / profile.mealsPerDay / 10) * 10;

      const response = await getOpenAiClient().responses.parse({
        model: AI_MODELS.recipeGeneration,
        input: [
          {
            role: "system",
            content: buildIngredientRecipesSystemPrompt({
              targetMealCalories,
              avoidFoods: profile.avoidFoods,
              likedFoods: profile.likedFoods,
              cookingTimePreference: profile.cookingTimePreference,
              budgetLevel: profile.budgetLevel,
            }),
          },
          { role: "user", content: JSON.stringify({ ingredients, excludeRecipeNames }) },
        ],
        text: { format: zodTextFormat(IngredientRecipesSchema, "ingredient_recipes") },
      });

      const parsed = response.output_parsed;
      if (!parsed) {
        throw new Error("Empty structured output from OpenAI.");
      }

      const safeRecipes = filterSafeSuggestedRecipes(parsed.recipes, profile.avoidFoods);
      if (safeRecipes.length === 0) {
        await refundAiQuota(uid, QUOTA_FEATURE);
        logger.warn("suggestRecipesFromIngredients: safety layer rejected every suggested recipe", {
          generated: parsed.recipes.length,
        });
        throw new HttpsError(
          "internal",
          "No pudimos proponer recetas seguras con tus restricciones y estos ingredientes. Prueba con otros.",
        );
      }

      return {
        recipes: safeRecipes.map((recipe) => ({
          id: randomUUID(),
          name: recipe.name,
          description: recipe.description,
          servings: 1,
          prepTimeMinutes: recipe.prepTimeMinutes,
          difficulty: recipe.difficulty,
          dishCategory: recipe.dishCategory,
          calories: recipe.calories,
          proteinGrams: recipe.proteinGrams,
          carbsGrams: recipe.carbsGrams,
          fatGrams: recipe.fatGrams,
          ingredients: recipe.ingredients,
          steps: recipe.steps,
          missingIngredients: recipe.missingIngredients,
        })),
        remainingToday: quota.remainingToday,
      };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      await refundAiQuota(uid, QUOTA_FEATURE);
      const err = error as { message?: string; status?: number; code?: string; name?: string };
      logger.error(
        `suggestRecipesFromIngredients: OpenAI call failed :: name=${err.name} status=${err.status} code=${err.code} message=${err.message}`,
      );
      throw new HttpsError("internal", "No se pudieron generar recetas en este momento. Intenta de nuevo.");
    }
  },
);

async function fetchProfile(userId: string): Promise<{
  sex: Sex | null;
  age: number | null;
  heightCm: number | null;
  weightKg: number | null;
  activityLevel: ActivityLevel;
  avoidFoods: string[];
  likedFoods: string[];
  mealsPerDay: number;
  cookingTimePreference: string | null;
  budgetLevel: string | null;
  isPremium: boolean;
}> {
  const doc = await getFirestore().collection("users").doc(userId).get();
  const data = doc.data();
  const onboarding = data?.onboarding as
    | {
        sex?: string;
        age?: number;
        heightCm?: number;
        weightKg?: number;
        activityLevel?: string;
        avoidFoods?: string[];
        likedFoods?: string[];
        mealSlots?: unknown[];
        cookingTimePreference?: string;
        budgetLevel?: string;
      }
    | undefined;
  const subscription = data?.subscription as { isPremium?: boolean } | undefined;

  return {
    sex: (onboarding?.sex as Sex | undefined) ?? null,
    age: onboarding?.age ?? null,
    heightCm: onboarding?.heightCm ?? null,
    weightKg: onboarding?.weightKg ?? null,
    activityLevel: (onboarding?.activityLevel as ActivityLevel | undefined) ?? "moderate",
    avoidFoods: onboarding?.avoidFoods ?? [],
    likedFoods: onboarding?.likedFoods ?? [],
    mealsPerDay: onboarding?.mealSlots?.length || DEFAULT_MEALS_PER_DAY,
    cookingTimePreference: onboarding?.cookingTimePreference ?? null,
    budgetLevel: onboarding?.budgetLevel ?? null,
    isPremium: subscription?.isPremium ?? false,
  };
}
