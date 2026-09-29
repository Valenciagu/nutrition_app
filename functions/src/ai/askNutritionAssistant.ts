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
const MAX_HISTORY_TURNS = 6;
const QUOTA_FEATURE = "nutritionQa";

interface HistoryTurn {
  question: string;
  answer: string;
}

interface AskNutritionAssistantRequest {
  question: string;
  /**
   * Turnos previos de la MISMA conversación, más recientes al final — el
   * cliente los reenvía en cada llamada (no hay estado de conversación en
   * el servidor; ver el nuevo `features/ai_assistant/` en Flutter, que
   * resuelve la pregunta abierta de dónde vive un chat de IA general — ver
   * "Open questions" en `TASKS.md`). Igual de no confiable que `question`:
   * se valida longitud y cantidad exactamente igual, nunca se asume que el
   * cliente reenvía fielmente lo que esta misma función respondió antes.
   */
  history?: HistoryTurn[];
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
 * `history` (opcional) le da continuidad de conversación al chat de IA
 * (`lib/features/ai_assistant/`) sin que el servidor tenga que guardar
 * estado — cada turno previo se reenvía como contexto de la llamada a
 * OpenAI, se descarta después. Sin memoria persistida a propósito: no hay
 * ninguna colección de Firestore para historial de chat (v1, ver
 * `documentation/ai_assistant.md`).
 *
 * Deliberadamente NO incluido todavía (tareas separadas, no asumir que esto
 * ya cubre todo):
 * - `enforceAppCheck: true` — diferido a la Épica 15 hasta que el cliente
 *   Flutter integre `firebase_app_check` con proveedores reales; activarlo
 *   antes rechazaría todas las llamadas del cliente actual (ver
 *   `documentation/security_review.md`).
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

    const history = validateHistory(request.data?.history);

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
          ...history.flatMap(
            (turn) =>
              [
                { role: "user", content: turn.question },
                { role: "assistant", content: turn.answer },
              ] as const,
          ),
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

/**
 * Valida (nunca confía a ciegas en) el historial de conversación que manda
 * el cliente — mismo criterio que `question`: cada turno se recorta y se
 * limita en longitud, y se rechaza toda la llamada si hay demasiados turnos
 * o alguno excede el límite, en vez de truncar en silencio (Instrucciones.md
 * §30, input validation).
 */
function validateHistory(raw: unknown): HistoryTurn[] {
  if (raw === undefined || raw === null) return [];
  if (!Array.isArray(raw)) {
    throw new HttpsError("invalid-argument", "`history` debe ser una lista.");
  }
  if (raw.length > MAX_HISTORY_TURNS) {
    throw new HttpsError("invalid-argument", `\`history\` no puede tener más de ${MAX_HISTORY_TURNS} turnos.`);
  }

  return raw.map((entry) => {
    const question = typeof entry?.question === "string" ? entry.question.trim() : "";
    const answer = typeof entry?.answer === "string" ? entry.answer.trim() : "";
    if (!question || !answer) {
      throw new HttpsError("invalid-argument", "Cada turno de `history` necesita `question` y `answer`.");
    }
    if (question.length > MAX_QUESTION_LENGTH || answer.length > MAX_QUESTION_LENGTH * 2) {
      throw new HttpsError("invalid-argument", "Un turno de `history` supera la longitud permitida.");
    }
    return { question, answer };
  });
}

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
