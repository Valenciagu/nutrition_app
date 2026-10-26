import { randomUUID } from "node:crypto";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { getFirestore } from "firebase-admin/firestore";
import { zodTextFormat } from "openai/helpers/zod";
import { AI_MODELS, getOpenAiClient, openAiApiKey } from "../config/openai";
import { consumeAiQuota, refundAiQuota } from "../ai/quota";
import { estimateDailyCalories, type ActivityLevel, type Sex } from "../plan/calorieEstimate";
import {
  assertPhotoUsable,
  deletePhotoQuietly,
  photoAsDataUri,
  userPhotoFile,
  type StorageFile,
} from "../storage/userPhoto";
import { IngredientRecipesSchema } from "./schema";
import { buildIngredientRecipesSystemPrompt } from "./prompts/ingredientRecipesV1";
import { filterSafeSuggestedRecipes } from "./safety";

const QUOTA_FEATURE = "ingredientAnalysis";
const PHOTO_FOLDER = "ingredientPhotos";
/** Sin `mealSlots` en el perfil se asume el mismo default que Onboarding (B6). */
const DEFAULT_MEALS_PER_DAY = 4;

interface SuggestRecipesRequest {
  /** Id generado por el cliente, ya usado como nombre del archivo en Storage. */
  photoId: string;
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
  carbsGrams: number;
  fatGrams: number;
  ingredients: { name: string; quantity: string; substitutes: string[] }[];
  steps: { instruction: string; timerSeconds: number | null }[];
  missingIngredients: string[];
}

interface SuggestRecipesResponse {
  isIngredientPhoto: boolean;
  detectedIngredients: string[];
  recipes: SuggestedRecipeResponse[];
  remainingToday: number;
}

/**
 * Épica 9 — foto de nevera/despensa → ingredientes detectados + hasta 3
 * recetas (Instrucciones.md §7). Mismo pipeline que `analyzeFoodPhoto`
 * (Épica 8): el cliente sube la foto a Storage y llama solo con el id; la
 * ruta se arma aquí desde el `uid`; la foto viaja a OpenAI como `data:` URI
 * y se borra de Storage al terminar, salga bien o mal.
 *
 * **Gratis por ahora (decisión del usuario, 2026-10-25)**: la especificación
 * la ubica como premium, pero sin suscripciones (Épica 13) se abre a todos
 * con su propio límite diario (`ingredientAnalysis` en `ai/quota.ts`, que
 * ya distingue free/premium). Volverla premium es cambiar ese límite o
 * agregar un chequeo de `isPremium` aquí — nada del cliente.
 *
 * Nada se persiste en Firestore: las recetas sugeridas no tienen todavía
 * ninguna pantalla que las vuelva a mostrar (no hay "mis recetas"), así que
 * guardarlas sería dato sin consumidor. El cliente las tiene en memoria.
 */
export const suggestRecipesFromIngredients = onCall<SuggestRecipesRequest, Promise<SuggestRecipesResponse>>(
  { secrets: [openAiApiKey], region: "us-central1", invoker: "public", enforceAppCheck: true, timeoutSeconds: 120 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión para analizar tus ingredientes.");
    }

    const photoId = request.data?.photoId?.trim();
    if (!photoId) {
      throw new HttpsError("invalid-argument", "Falta `photoId`.");
    }

    const file = userPhotoFile(request.auth.uid, PHOTO_FOLDER, photoId);
    try {
      await assertPhotoUsable(file);
      return await suggestFromStoredPhoto(request.auth.uid, file);
    } finally {
      await deletePhotoQuietly(file, "suggestRecipesFromIngredients");
    }
  },
);

async function suggestFromStoredPhoto(uid: string, file: StorageFile): Promise<SuggestRecipesResponse> {
  const profile = await fetchProfile(uid);
  const quota = await consumeAiQuota(uid, profile.isPremium, QUOTA_FEATURE);

  try {
    const imageDataUri = await photoAsDataUri(file);
    const dailyCalories = estimateDailyCalories({
      sex: profile.sex ?? undefined,
      age: profile.age ?? undefined,
      heightCm: profile.heightCm ?? undefined,
      weightKg: profile.weightKg ?? undefined,
      activityLevel: profile.activityLevel,
    });
    const targetMealCalories = Math.round(dailyCalories / profile.mealsPerDay / 10) * 10;

    const response = await getOpenAiClient().responses.parse({
      model: AI_MODELS.ingredientPhotoAnalysis,
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
        {
          role: "user",
          content: [
            { type: "input_text", text: "¿Qué puedo cocinar con esto?" },
            { type: "input_image", image_url: imageDataUri, detail: "auto" },
          ],
        },
      ],
      text: { format: zodTextFormat(IngredientRecipesSchema, "ingredient_recipes") },
    });

    const parsed = response.output_parsed;
    if (!parsed) {
      throw new Error("Empty structured output from OpenAI.");
    }

    if (!parsed.isIngredientPhoto) {
      // Igual que una foto que no es comida en Épica 8: respuesta normal, no
      // error — la cuota ya se gastó en una llamada real a OpenAI.
      logger.info("suggestRecipesFromIngredients: photo did not show ingredients");
      return { isIngredientPhoto: false, detectedIngredients: [], recipes: [], remainingToday: quota.remainingToday };
    }

    const safeRecipes = filterSafeSuggestedRecipes(parsed.recipes, profile.avoidFoods);
    if (safeRecipes.length === 0) {
      await refundAiQuota(uid, QUOTA_FEATURE);
      logger.warn("suggestRecipesFromIngredients: safety layer rejected every suggested recipe", {
        generated: parsed.recipes.length,
      });
      throw new HttpsError(
        "internal",
        "No pudimos proponer recetas seguras con tus restricciones a partir de esta foto. Intenta con otra.",
      );
    }

    return {
      isIngredientPhoto: true,
      detectedIngredients: parsed.detectedIngredients,
      recipes: safeRecipes.map((recipe) => ({
        id: randomUUID(),
        name: recipe.name,
        description: recipe.description,
        servings: 1,
        prepTimeMinutes: recipe.prepTimeMinutes,
        difficulty: recipe.difficulty,
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
    throw new HttpsError("internal", "No se pudieron analizar tus ingredientes en este momento. Intenta de nuevo.");
  }
}

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
