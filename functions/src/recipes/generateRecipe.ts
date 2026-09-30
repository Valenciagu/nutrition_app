import { randomUUID } from "node:crypto";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { getFirestore } from "firebase-admin/firestore";
import { zodTextFormat } from "openai/helpers/zod";
import { AI_MODELS, getOpenAiClient, openAiApiKey } from "../config/openai";
import { consumeAiQuota, refundAiQuota } from "../ai/quota";
import { GeneratedRecipeSchema } from "./schema";
import { buildRecipeGenerationSystemPrompt } from "./prompts/recipeGenerationV1";
import { checkRecipeSafety } from "./safety";

const QUOTA_FEATURE = "recipeGeneration";
const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

interface GenerateRecipeRequest {
  date: string;
  mealId: string;
}

interface RecipeResponse {
  id: string;
  name: string;
  description: string;
  servings: number;
  prepTimeMinutes: number;
  difficulty: "easy" | "medium" | "hard";
  calories: number;
  proteinGrams: number;
  carbsGrams: number;
  fatGrams: number;
  ingredients: { name: string; quantity: string; substitutes: string[] }[];
  steps: { instruction: string; timerSeconds: number | null }[];
}

interface StoredMeal {
  id: string;
  name: string;
  calories: number;
  proteinGrams: number;
  recipeId: string | null;
}

/**
 * Genera (o reutiliza) la receta completa de una comida del plan del
 * usuario — Épica 7. A diferencia de `generateDailyPlan`/`adjustDailyPlan`,
 * es idempotente por comida: si `PlannedMeal.recipeId` ya existe, devuelve
 * la receta ya guardada sin llamar a OpenAI ni consumir cuota — evita
 * regenerar (y volver a cobrar) la misma receta cada vez que el usuario
 * entra al detalle (D3).
 *
 * Documento escrito: `users/{uid}/recipes/{recipeId}`
 * (Instrucciones.md §69), con la forma exacta de `Recipe.toJson()`
 * (`lib/features/recipes/domain/entities/recipe.dart`) — así un futuro
 * repositorio Dart puede hacer `Recipe.fromJson(doc.data())` directo.
 * También actualiza `meals[index].recipeId` en
 * `users/{uid}/nutritionPlans/{date}` — mismo patrón de actualización de un
 * elemento de array que `registerMeal.ts` (no una escritura directa desde
 * Flutter, para no depender de reglas de Firestore a nivel de elemento de
 * array).
 *
 * `calories`/`proteinGrams` de la receta NUNCA vienen del modelo — se
 * copian de la `PlannedMeal` ya existente, así D1 (plan) y D3 (receta)
 * nunca pueden mostrar kcal distintos para la misma comida. Ver
 * `schema.ts` para el resto de esta decisión.
 */
export const generateRecipe = onCall<GenerateRecipeRequest, Promise<RecipeResponse>>(
  { secrets: [openAiApiKey], region: "us-central1", invoker: "public" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión para ver una receta.");
    }

    const date = request.data?.date?.trim();
    const mealId = request.data?.mealId?.trim();
    if (!date || !DATE_PATTERN.test(date)) {
      throw new HttpsError("invalid-argument", "La fecha debe tener el formato YYYY-MM-DD.");
    }
    if (!mealId) {
      throw new HttpsError("invalid-argument", "Falta `mealId`.");
    }

    const db = getFirestore();
    const planRef = db.collection("users").doc(request.auth.uid).collection("nutritionPlans").doc(date);
    const planDoc = await planRef.get();
    if (!planDoc.exists) {
      throw new HttpsError("not-found", "No hay un plan para esa fecha.");
    }

    const meals = (planDoc.data()?.meals as StoredMeal[]) ?? [];
    const mealIndex = meals.findIndex((m) => m.id === mealId);
    if (mealIndex === -1) {
      throw new HttpsError("not-found", "Esa comida no existe en el plan de ese día.");
    }
    const meal = meals[mealIndex];

    const recipesCollection = db.collection("users").doc(request.auth.uid).collection("recipes");

    if (meal.recipeId) {
      const existing = await recipesCollection.doc(meal.recipeId).get();
      if (existing.exists) {
        return existing.data() as RecipeResponse;
      }
      logger.warn("generateRecipe: recipeId pointed to a missing document, regenerating", {
        recipeId: meal.recipeId,
      });
    }

    const profile = await fetchOnboardingProfile(request.auth.uid);
    // No se captura `remainingToday`: a diferencia de
    // `generateDailyPlan`/`adjustDailyPlan`, la respuesta de esta función
    // debe tener EXACTAMENTE la misma forma tanto si generó una receta nueva
    // como si devolvió una ya cacheada (`existing.data()` arriba) — agregar
    // un campo extra solo en la rama de generación rompería esa simetría.
    await consumeAiQuota(request.auth.uid, profile.isPremium, QUOTA_FEATURE);

    try {
      const openai = getOpenAiClient();
      const response = await openai.responses.parse({
        model: AI_MODELS.recipeGeneration,
        input: [
          {
            role: "system",
            content: buildRecipeGenerationSystemPrompt({
              mealName: meal.name,
              targetCalories: meal.calories,
              targetProteinGrams: meal.proteinGrams,
              avoidFoods: profile.avoidFoods,
              likedFoods: profile.likedFoods,
              cookingTimePreference: profile.cookingTimePreference,
              budgetLevel: profile.budgetLevel,
            }),
          },
          { role: "user", content: `Genera la receta de "${meal.name}".` },
        ],
        text: { format: zodTextFormat(GeneratedRecipeSchema, "recipe_generation") },
      });

      const parsed = response.output_parsed;
      if (!parsed) {
        throw new Error("Empty structured output from OpenAI.");
      }

      const safety = checkRecipeSafety(parsed, profile.avoidFoods, meal.calories, meal.proteinGrams);
      if (!safety.safe) {
        await refundAiQuota(request.auth.uid, QUOTA_FEATURE);
        logger.warn("generateRecipe: safety layer rejected a generated recipe", { reason: safety.reason });
        throw new HttpsError(
          "internal",
          "No se pudo generar una receta segura con tus restricciones en este momento. Intenta de nuevo.",
        );
      }

      const recipe: RecipeResponse = {
        id: randomUUID(),
        name: meal.name,
        description: parsed.description,
        servings: 1,
        prepTimeMinutes: parsed.prepTimeMinutes,
        difficulty: parsed.difficulty,
        calories: meal.calories,
        proteinGrams: meal.proteinGrams,
        carbsGrams: parsed.carbsGrams,
        fatGrams: parsed.fatGrams,
        ingredients: parsed.ingredients,
        steps: parsed.steps,
      };

      await recipesCollection.doc(recipe.id).set(recipe);
      meals[mealIndex] = { ...meal, recipeId: recipe.id };
      await planRef.update({ meals });

      return recipe;
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      await refundAiQuota(request.auth.uid, QUOTA_FEATURE);
      logger.error("generateRecipe: OpenAI call failed", { message: (error as Error).message });
      throw new HttpsError("internal", "No se pudo generar la receta en este momento. Intenta de nuevo.");
    }
  },
);

async function fetchOnboardingProfile(userId: string): Promise<{
  avoidFoods: string[];
  likedFoods: string[];
  cookingTimePreference: string | null;
  budgetLevel: string | null;
  isPremium: boolean;
}> {
  const doc = await getFirestore().collection("users").doc(userId).get();
  const data = doc.data();
  const onboarding = data?.onboarding as
    | {
        avoidFoods?: string[];
        likedFoods?: string[];
        cookingTimePreference?: string;
        budgetLevel?: string;
      }
    | undefined;
  const subscription = data?.subscription as { isPremium?: boolean } | undefined;

  return {
    avoidFoods: onboarding?.avoidFoods ?? [],
    likedFoods: onboarding?.likedFoods ?? [],
    cookingTimePreference: onboarding?.cookingTimePreference ?? null,
    budgetLevel: onboarding?.budgetLevel ?? null,
    isPremium: subscription?.isPremium ?? false,
  };
}
