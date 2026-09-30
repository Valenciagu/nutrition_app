import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { getFirestore } from "firebase-admin/firestore";
import { zodTextFormat } from "openai/helpers/zod";
import { AI_MODELS, getOpenAiClient, openAiApiKey } from "../config/openai";
import { consumeAiQuota, refundAiQuota } from "../ai/quota";
import { MealAlternativesSchema, type GeneratedMeal } from "./schema";
import { buildMealAlternativesSystemPrompt } from "./prompts/mealAlternativesV1";

const QUOTA_FEATURE = "mealAlternatives";
const MAX_FILTER_LENGTH = 100;

interface SuggestMealAlternativesRequest {
  date: string;
  mealId: string;
  /** Texto del chip tocado ("Más rápido"/"Más ligera") o un pedido libre. Opcional. */
  filterHint?: string;
}

interface AlternativeResponse {
  name: string;
  calories: number;
  proteinGrams: number;
}

interface SuggestMealAlternativesResponse {
  mealId: string;
  alternatives: AlternativeResponse[];
  remainingToday: number;
}

/**
 * D4 — genera 3 alternativas para UNA comida pendiente del plan, con
 * macros similares. No persiste nada en el plan todavía — las 3
 * alternativas se guardan como un campo efímero (`candidates`) dentro de
 * la propia comida en Firestore, para que `replaceMeal` pueda confirmarlas
 * sin que el cliente tenga que reenviar contenido generado por la IA (ver
 * `replaceMeal.ts`).
 */
export const suggestMealAlternatives = onCall<SuggestMealAlternativesRequest, Promise<SuggestMealAlternativesResponse>>(
  { secrets: [openAiApiKey], region: "us-central1", invoker: "public", enforceAppCheck: true },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const date = request.data?.date?.trim();
    const mealId = request.data?.mealId?.trim();
    if (!date || !mealId) {
      throw new HttpsError("invalid-argument", "Faltan `date` o `mealId`.");
    }
    const filterHint = request.data?.filterHint?.trim() || null;
    if (filterHint && filterHint.length > MAX_FILTER_LENGTH) {
      throw new HttpsError("invalid-argument", `El filtro no puede superar ${MAX_FILTER_LENGTH} caracteres.`);
    }

    const planRef = getFirestore().collection("users").doc(request.auth.uid).collection("nutritionPlans").doc(date);
    const planDoc = await planRef.get();
    if (!planDoc.exists) {
      throw new HttpsError("not-found", "No hay un plan para esa fecha.");
    }

    const meals = (planDoc.data()?.meals as Array<Record<string, unknown>>) ?? [];
    const mealIndex = meals.findIndex((meal) => meal.id === mealId);
    if (mealIndex === -1) {
      throw new HttpsError("not-found", "Esa comida no existe en el plan de ese día.");
    }
    const meal = meals[mealIndex];
    if (meal.status !== "pending") {
      throw new HttpsError("failed-precondition", "Solo se pueden reemplazar comidas pendientes.");
    }

    const profile = await fetchAllergenProfile(request.auth.uid);
    const quota = await consumeAiQuota(request.auth.uid, profile.isPremium, QUOTA_FEATURE);

    try {
      const openai = getOpenAiClient();
      const response = await openai.responses.parse({
        model: AI_MODELS.nutritionQa,
        input: [
          {
            role: "system",
            content: buildMealAlternativesSystemPrompt({
              slotLabelKey: meal.slotLabelKey as string,
              currentMealName: meal.name as string,
              targetCalories: meal.calories as number,
              targetProteinGrams: meal.proteinGrams as number,
              avoidFoods: profile.avoidFoods,
              likedFoods: profile.likedFoods,
              filterHint,
            }),
          },
          { role: "user", content: filterHint ?? "Dame variedad, cualquier alternativa razonable." },
        ],
        text: { format: zodTextFormat(MealAlternativesSchema, "meal_alternatives") },
      });

      const parsed = response.output_parsed;
      if (!parsed) {
        throw new Error("OpenAI response did not include parsed structured output.");
      }

      // Filtra las que se auto-marcan inseguras en vez de fallar todo el
      // pedido — es una lista de sugerencias, no el plan canónico; si
      // sobra al menos una alternativa segura, vale la pena mostrarla.
      const safeAlternatives = parsed.alternatives.filter((alt) => !alt.containsExcludedFood);
      if (safeAlternatives.length === 0) {
        await refundAiQuota(request.auth.uid, QUOTA_FEATURE);
        logger.warn("suggestMealAlternatives: all alternatives flagged unsafe");
        throw new HttpsError("internal", "No se pudieron generar alternativas seguras con tus restricciones.");
      }

      const candidates: AlternativeResponse[] = safeAlternatives.map((alt: GeneratedMeal) => ({
        name: alt.name,
        calories: alt.calories,
        proteinGrams: alt.proteinGrams,
      }));

      meals[mealIndex] = { ...meal, candidates };
      await planRef.update({ meals });

      return { mealId, alternatives: candidates, remainingToday: quota.remainingToday };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      await refundAiQuota(request.auth.uid, QUOTA_FEATURE);
      logger.error("suggestMealAlternatives: OpenAI call failed", { message: (error as Error).message });
      throw new HttpsError("internal", "No se pudieron generar alternativas en este momento. Intenta de nuevo.");
    }
  },
);

async function fetchAllergenProfile(userId: string): Promise<{
  avoidFoods: string[];
  likedFoods: string[];
  isPremium: boolean;
}> {
  const doc = await getFirestore().collection("users").doc(userId).get();
  const data = doc.data();
  const onboarding = data?.onboarding as { avoidFoods?: string[]; likedFoods?: string[] } | undefined;
  const subscription = data?.subscription as { isPremium?: boolean } | undefined;
  return {
    avoidFoods: onboarding?.avoidFoods ?? [],
    likedFoods: onboarding?.likedFoods ?? [],
    isPremium: subscription?.isPremium ?? false,
  };
}
