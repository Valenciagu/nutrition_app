import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { getFirestore } from "firebase-admin/firestore";
import { zodTextFormat } from "openai/helpers/zod";
import { AI_MODELS, getOpenAiClient, openAiApiKey } from "../config/openai";
import { consumeAiQuota, refundAiQuota } from "../ai/quota";
import { estimateDailyCalories, type ActivityLevel, type Sex } from "./calorieEstimate";
import { NutritionPlanGenerationSchema } from "./schema";
import { buildNutritionAdjustmentSystemPrompt } from "./prompts/nutritionAdjustmentV1";
import { checkPlanSafety } from "./safety";

const QUOTA_FEATURE = "planAdjustment";
const MAX_MESSAGE_LENGTH = 300;

interface StoredMeal {
  id: string;
  slotLabelKey: string;
  scheduledHour: number;
  scheduledMinute: number;
  name: string;
  calories: number;
  proteinGrams: number;
  status: "pending" | "registered";
  recipeId: string | null;
}

interface AdjustDailyPlanRequest {
  date: string;
  message: string;
}

interface AdjustDailyPlanResponse {
  date: string;
  meals: StoredMeal[];
  generatedAt: string;
  remainingToday: number;
}

/**
 * Ajusta las comidas pendientes de un plan ya generado a partir de un
 * mensaje libre del usuario — Épica 6, PLAN-004 (Instrucciones.md §9:
 * "no tengo pollo" / "ya comí una hamburguesa"). Reusa la mayor parte de
 * `generateDailyPlan`: mismo esquema estructurado, misma capa de
 * seguridad, mismo formato de documento. Las comidas ya `registered`
 * nunca se tocan.
 */
export const adjustDailyPlan = onCall<AdjustDailyPlanRequest, Promise<AdjustDailyPlanResponse>>(
  { secrets: [openAiApiKey], region: "us-central1", invoker: "public", enforceAppCheck: true },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión para ajustar tu plan.");
    }

    const date = request.data?.date?.trim();
    const message = request.data?.message?.trim();
    if (!date) {
      throw new HttpsError("invalid-argument", "Falta `date`.");
    }
    if (!message) {
      throw new HttpsError("invalid-argument", "El mensaje no puede estar vacío.");
    }
    if (message.length > MAX_MESSAGE_LENGTH) {
      throw new HttpsError("invalid-argument", `El mensaje no puede superar ${MAX_MESSAGE_LENGTH} caracteres.`);
    }

    const planRef = getFirestore().collection("users").doc(request.auth.uid).collection("nutritionPlans").doc(date);
    const planDoc = await planRef.get();
    if (!planDoc.exists) {
      throw new HttpsError("failed-precondition", "No hay un plan para esa fecha todavía.");
    }

    const allMeals = (planDoc.data()?.meals as StoredMeal[]) ?? [];
    const registeredMeals = allMeals.filter((meal) => meal.status === "registered");
    const pendingMeals = allMeals.filter((meal) => meal.status === "pending");
    if (pendingMeals.length === 0) {
      throw new HttpsError("failed-precondition", "No quedan comidas pendientes por ajustar hoy.");
    }

    const profile = await fetchOnboardingProfile(request.auth.uid);
    const targetCalories = estimateDailyCalories({
      sex: profile.sex ?? undefined,
      age: profile.age ?? undefined,
      heightCm: profile.heightCm ?? undefined,
      weightKg: profile.weightKg ?? undefined,
      activityLevel: profile.activityLevel,
    });
    const registeredCalories = registeredMeals.reduce((sum, meal) => sum + meal.calories, 0);
    const remainingCalorieBudget = Math.max(targetCalories - registeredCalories, 300);

    const quota = await consumeAiQuota(request.auth.uid, profile.isPremium, QUOTA_FEATURE);

    try {
      const openai = getOpenAiClient();
      const response = await openai.responses.parse({
        model: AI_MODELS.nutritionQa,
        input: [
          {
            role: "system",
            content: buildNutritionAdjustmentSystemPrompt({
              userMessage: message,
              goal: profile.goal,
              avoidFoods: profile.avoidFoods,
              likedFoods: profile.likedFoods,
              registeredCalories,
              remainingCalorieBudget,
              pendingMeals: pendingMeals.map((meal) => ({
                slotLabelKey: meal.slotLabelKey,
                name: meal.name,
                calories: meal.calories,
                proteinGrams: meal.proteinGrams,
              })),
            }),
          },
          { role: "user", content: message },
        ],
        text: { format: zodTextFormat(NutritionPlanGenerationSchema, "nutrition_plan_generation") },
      });

      const parsed = response.output_parsed;
      if (!parsed || parsed.meals.length !== pendingMeals.length) {
        throw new Error(
          `Unexpected meal count: expected ${pendingMeals.length}, got ${parsed?.meals.length ?? "none"}.`,
        );
      }

      const safety = checkPlanSafety(parsed.meals, remainingCalorieBudget);
      if (!safety.safe) {
        await refundAiQuota(request.auth.uid, QUOTA_FEATURE);
        logger.warn("adjustDailyPlan: safety layer rejected an adjustment", { reason: safety.reason });
        throw new HttpsError(
          "internal",
          "No se pudo ajustar tu plan de forma segura con tus restricciones. Intenta reformular el mensaje.",
        );
      }

      const updatedPending: StoredMeal[] = pendingMeals.map((meal, index) => ({
        ...meal,
        name: parsed.meals[index].name,
        calories: parsed.meals[index].calories,
        proteinGrams: parsed.meals[index].proteinGrams,
      }));

      // El orden final respeta el orden original del plan (por horario), no
      // el orden en que se separaron registradas/pendientes.
      const updatedById = new Map(
        [...registeredMeals, ...updatedPending].map((meal) => [meal.id, meal] as const),
      );
      const meals = allMeals.map((meal) => updatedById.get(meal.id)!);

      const generatedAt = new Date().toISOString();
      await planRef.set({ date, meals, generatedAt });

      return { date, meals, generatedAt, remainingToday: quota.remainingToday };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      await refundAiQuota(request.auth.uid, QUOTA_FEATURE);
      logger.error("adjustDailyPlan: OpenAI call failed", { message: (error as Error).message });
      throw new HttpsError("internal", "No se pudo ajustar el plan en este momento. Intenta de nuevo.");
    }
  },
);

async function fetchOnboardingProfile(userId: string): Promise<{
  goal: string | null;
  sex: Sex | null;
  age: number | null;
  heightCm: number | null;
  weightKg: number | null;
  activityLevel: ActivityLevel;
  avoidFoods: string[];
  likedFoods: string[];
  isPremium: boolean;
}> {
  const doc = await getFirestore().collection("users").doc(userId).get();
  const data = doc.data();
  const onboarding = data?.onboarding as
    | {
        goal?: string;
        sex?: string;
        age?: number;
        heightCm?: number;
        weightKg?: number;
        activityLevel?: string;
        avoidFoods?: string[];
        likedFoods?: string[];
      }
    | undefined;
  const subscription = data?.subscription as { isPremium?: boolean } | undefined;

  return {
    goal: onboarding?.goal ?? null,
    sex: (onboarding?.sex as Sex | undefined) ?? null,
    age: onboarding?.age ?? null,
    heightCm: onboarding?.heightCm ?? null,
    weightKg: onboarding?.weightKg ?? null,
    activityLevel: (onboarding?.activityLevel as ActivityLevel | undefined) ?? "moderate",
    avoidFoods: onboarding?.avoidFoods ?? [],
    likedFoods: onboarding?.likedFoods ?? [],
    isPremium: subscription?.isPremium ?? false,
  };
}
