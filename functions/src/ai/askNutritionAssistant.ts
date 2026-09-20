import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { getFirestore } from "firebase-admin/firestore";
import { zodTextFormat } from "openai/helpers/zod";
import { AI_MODELS, getOpenAiClient, openAiApiKey } from "../config/openai";
import { NutritionAssistantResponseSchema } from "./schema";
import { buildNutritionAssistantSystemPrompt } from "./prompts/nutritionAssistantV1";
import { checkNutritionAssistantSafety, SAFETY_FALLBACK_ANSWER } from "./safety";
import { consumeAiQuota, refundAiQuota } from "./quota";

const MAX_QUESTION_LENGTH = 500;
const QUOTA_FEATURE = "nutritionQa";

interface AskNutritionAssistantRequest {
  question: string;
}

interface AskNutritionAssistantResponse {
  answer: string;
  recommendsProfessionalConsult: boolean;
  safetyFallbackApplied: boolean;
  remainingToday: number;
}

/**
 * Answers a free-text nutrition question. First OpenAI-proxying Cloud
 * Function (Épica 5, tarea 5.1) — prueba el pipeline seguro completo:
 * Flutter -> token de Firebase Auth -> esta función -> validación de cuota ->
 * OpenAI -> validación estructurada/seguridad -> Flutter.
 *
 * Deliberadamente NO incluido todavía (tareas separadas, no asumir que esto
 * ya cubre todo):
 * - `enforceAppCheck: true` — diferido a la Épica 15 hasta que el cliente
 *   Flutter integre `firebase_app_check`; activarlo antes rechazaría todas
 *   las llamadas del cliente actual.
 * - Nada en `lib/` la llama todavía (Épica 5, tarea 5.3 — `AIService` en Dart).
 */
export const askNutritionAssistant = onCall<AskNutritionAssistantRequest, Promise<AskNutritionAssistantResponse>>(
  { secrets: [openAiApiKey], region: "us-central1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión para usar el asistente de nutrición.");
    }

    const question = request.data?.question?.trim();
    if (!question) {
      throw new HttpsError("invalid-argument", "La pregunta no puede estar vacía.");
    }
    if (question.length > MAX_QUESTION_LENGTH) {
      throw new HttpsError("invalid-argument", `La pregunta no puede superar ${MAX_QUESTION_LENGTH} caracteres.`);
    }

    // Nunca confiar en datos de perfil/premium enviados por el cliente — se
    // leen del propio documento del usuario autenticado (Instrucciones.md §70).
    const { goal, avoidFoods, isPremium } = await fetchMinimalProfile(request.auth.uid);

    // Consumir la cuota ANTES de llamar a OpenAI (Instrucciones.md §28-29) —
    // si esto lanza `resource-exhausted`, la función termina aquí sin gastar
    // ninguna llamada a OpenAI.
    const quota = await consumeAiQuota(request.auth.uid, isPremium, QUOTA_FEATURE);

    try {
      const openai = getOpenAiClient();
      const response = await openai.responses.parse({
        model: AI_MODELS.nutritionQa,
        input: [
          { role: "system", content: buildNutritionAssistantSystemPrompt({ goal, avoidFoods }) },
          { role: "user", content: question },
        ],
        text: { format: zodTextFormat(NutritionAssistantResponseSchema, "nutrition_assistant_response") },
      });

      const parsed = response.output_parsed;
      if (!parsed) {
        throw new Error("OpenAI response did not include parsed structured output.");
      }

      const safety = checkNutritionAssistantSafety(parsed, avoidFoods);
      if (!safety.safe) {
        logger.warn("askNutritionAssistant: safety layer rejected a response", { reason: safety.reason });
        return {
          answer: SAFETY_FALLBACK_ANSWER,
          recommendsProfessionalConsult: true,
          safetyFallbackApplied: true,
          remainingToday: quota.remainingToday,
        };
      }

      return {
        answer: parsed.answer,
        recommendsProfessionalConsult: parsed.recommendsProfessionalConsult,
        safetyFallbackApplied: false,
        remainingToday: quota.remainingToday,
      };
    } catch (error) {
      // La llamada a OpenAI falló después de consumir la cuota — se devuelve
      // ese cupo para que un error del proveedor no le cueste al usuario una
      // consulta real (ver comentario en `refundAiQuota`).
      await refundAiQuota(request.auth.uid, QUOTA_FEATURE);
      logger.error("askNutritionAssistant: OpenAI call failed", { message: (error as Error).message });
      throw new HttpsError("internal", "No se pudo generar una respuesta en este momento. Intenta de nuevo.");
    }
  },
);

async function fetchMinimalProfile(
  userId: string,
): Promise<{ goal: string | null; avoidFoods: string[]; isPremium: boolean }> {
  const doc = await getFirestore().collection("users").doc(userId).get();
  const data = doc.data();
  const onboarding = data?.onboarding as { goal?: string; avoidFoods?: string[] } | undefined;
  // `subscription.isPremium` no existe todavía — lo escribirá la Épica 13
  // (verificación server-side de recibos de compra). Hasta entonces esto es
  // siempre `false` para todos los usuarios, lo cual es seguro por defecto:
  // nada escribe este campo hoy, así que no hay nada que un cliente pueda
  // falsear. Nunca leer un `isPremium` que el cliente pueda escribir.
  const subscription = data?.subscription as { isPremium?: boolean } | undefined;
  return {
    goal: onboarding?.goal ?? null,
    avoidFoods: onboarding?.avoidFoods ?? [],
    isPremium: subscription?.isPremium ?? false,
  };
}
