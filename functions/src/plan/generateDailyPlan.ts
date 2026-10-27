import { randomUUID } from "node:crypto";
import type { DishCategory } from "../dishCategory";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { getFirestore } from "firebase-admin/firestore";
import { zodTextFormat } from "openai/helpers/zod";
import { AI_MODELS, getOpenAiClient, openAiApiKey } from "../config/openai";
import { consumeAiQuota, refundAiQuota } from "../ai/quota";
import { estimateDailyCalories, type ActivityLevel, type Sex } from "./calorieEstimate";
import { NutritionPlanGenerationSchema } from "./schema";
import { buildNutritionPlanSystemPrompt } from "./prompts/nutritionPlanV1";
import { checkPlanSafety } from "./safety";

const QUOTA_FEATURE = "planGeneration";
const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

interface MealSlot {
  labelKey: string;
  hour: number;
  minute: number;
}

interface OnboardingProfile {
  goal: string | null;
  sex: Sex | null;
  age: number | null;
  heightCm: number | null;
  weightKg: number | null;
  activityLevel: ActivityLevel;
  avoidFoods: string[];
  likedFoods: string[];
  mealSlots: MealSlot[];
  cookingTimePreference: string | null;
  budgetLevel: string | null;
  isPremium: boolean;
}

interface GenerateDailyPlanRequest {
  /** YYYY-MM-DD; por defecto hoy (UTC). Permite (re)generar un día específico sin un endpoint de lote aparte. */
  date?: string;
}

interface PlannedMealResponse {
  id: string;
  slotLabelKey: string;
  scheduledHour: number;
  scheduledMinute: number;
  name: string;
  calories: number;
  proteinGrams: number;
  /** RECIPE-101 — foto ilustrativa por tipo de plato. */
  dishCategory: DishCategory;
  status: "pending";
  recipeId: null;
}

interface GenerateDailyPlanResponse {
  date: string;
  meals: PlannedMealResponse[];
  generatedAt: string;
  remainingToday: number;
}

/**
 * Genera (y persiste) el plan de comidas de un día para el usuario
 * autenticado — Épica 6, tarea PLAN-002. Pipeline seguro completo, mismo
 * patrón que `askNutritionAssistant` (Épica 5): Flutter -> Auth ->
 * cuota -> contexto -> OpenAI -> validación estructurada/seguridad ->
 * Firestore -> Flutter.
 *
 * El documento escrito (`users/{uid}/nutritionPlans/{date}`) tiene
 * EXACTAMENTE la forma de `NutritionPlan.toJson()` en
 * `lib/features/plan/domain/entities/nutrition_plan.dart` — incluye
 * `generatedAt` como string ISO-8601, no un `Timestamp` nativo de
 * Firestore, a propósito, para que un futuro repositorio Dart pueda hacer
 * `NutritionPlan.fromJson(doc.data())` directo, sin un mapper aparte.
 *
 * `enforceAppCheck: true` añadido en la Épica 15 (2026-09-30) — ver
 * `main.dart` (proveedor de depuración por ahora) y
 * `documentation/security_review.md`.
 */
export const generateDailyPlan = onCall<GenerateDailyPlanRequest, Promise<GenerateDailyPlanResponse>>(
  { secrets: [openAiApiKey], region: "us-central1", invoker: "public", enforceAppCheck: true },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión para generar un plan.");
    }

    const date = request.data?.date?.trim() || todayKey();
    if (!DATE_PATTERN.test(date)) {
      throw new HttpsError("invalid-argument", "La fecha debe tener el formato YYYY-MM-DD.");
    }

    const profile = await fetchOnboardingProfile(request.auth.uid);
    if (profile.mealSlots.length === 0) {
      throw new HttpsError(
        "failed-precondition",
        "Completa tu perfil (Onboarding) antes de generar un plan de comidas.",
      );
    }

    const targetCalories = estimateDailyCalories({
      sex: profile.sex ?? undefined,
      age: profile.age ?? undefined,
      heightCm: profile.heightCm ?? undefined,
      weightKg: profile.weightKg ?? undefined,
      activityLevel: profile.activityLevel,
    });

    const quota = await consumeAiQuota(request.auth.uid, profile.isPremium, QUOTA_FEATURE);

    try {
      const openai = getOpenAiClient();
      const response = await openai.responses.parse({
        model: AI_MODELS.nutritionQa,
        input: [
          {
            role: "system",
            content: buildNutritionPlanSystemPrompt({
              goal: profile.goal,
              activityLevel: profile.activityLevel,
              targetCalories,
              avoidFoods: profile.avoidFoods,
              likedFoods: profile.likedFoods,
              cookingTimePreference: profile.cookingTimePreference,
              budgetLevel: profile.budgetLevel,
              slotLabelKeys: profile.mealSlots.map((slot) => slot.labelKey),
            }),
          },
          {
            role: "user",
            content: `Genera exactamente ${profile.mealSlots.length} comidas, una por cada franja, en este orden: ${profile.mealSlots
              .map((slot) => slot.labelKey)
              .join(", ")}.`,
          },
        ],
        text: { format: zodTextFormat(NutritionPlanGenerationSchema, "nutrition_plan_generation") },
      });

      const parsed = response.output_parsed;
      if (!parsed || parsed.meals.length !== profile.mealSlots.length) {
        throw new Error(
          `Unexpected meal count: expected ${profile.mealSlots.length}, got ${parsed?.meals.length ?? "none"}.`,
        );
      }

      const safety = checkPlanSafety(parsed.meals, targetCalories);
      if (!safety.safe) {
        await refundAiQuota(request.auth.uid, QUOTA_FEATURE);
        logger.warn("generateDailyPlan: safety layer rejected a generated plan", { reason: safety.reason });
        throw new HttpsError(
          "internal",
          "No se pudo generar un plan seguro con tus restricciones en este momento. Intenta de nuevo.",
        );
      }

      const meals: PlannedMealResponse[] = profile.mealSlots.map((slot, index) => ({
        id: randomUUID(),
        slotLabelKey: slot.labelKey,
        scheduledHour: slot.hour,
        scheduledMinute: slot.minute,
        name: parsed.meals[index].name,
        calories: parsed.meals[index].calories,
        proteinGrams: parsed.meals[index].proteinGrams,
        dishCategory: parsed.meals[index].dishCategory,
        status: "pending",
        recipeId: null,
      }));

      const generatedAt = new Date().toISOString();
      const planDoc = { date, meals, generatedAt };

      await getFirestore().collection("users").doc(request.auth.uid).collection("nutritionPlans").doc(date).set(planDoc);

      return { ...planDoc, remainingToday: quota.remainingToday };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      await refundAiQuota(request.auth.uid, QUOTA_FEATURE);
      logger.error("generateDailyPlan: OpenAI call failed", { message: (error as Error).message });
      throw new HttpsError("internal", "No se pudo generar el plan en este momento. Intenta de nuevo.");
    }
  },
);

async function fetchOnboardingProfile(userId: string): Promise<OnboardingProfile> {
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
        mealSlots?: MealSlot[];
        cookingTimePreference?: string;
        budgetLevel?: string;
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
    mealSlots: onboarding?.mealSlots ?? [],
    cookingTimePreference: onboarding?.cookingTimePreference ?? null,
    budgetLevel: onboarding?.budgetLevel ?? null,
    isPremium: subscription?.isPremium ?? false,
  };
}

function todayKey(): string {
  return new Date().toISOString().slice(0, 10);
}
