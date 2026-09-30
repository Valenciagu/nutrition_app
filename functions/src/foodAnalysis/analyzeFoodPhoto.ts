import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { zodTextFormat } from "openai/helpers/zod";
import { AI_MODELS, getOpenAiClient, openAiApiKey } from "../config/openai";
import { consumeAiQuota, refundAiQuota } from "../ai/quota";
import { FoodAnalysisSchema } from "./schema";
import { buildFoodAnalysisSystemPrompt } from "./prompts/foodAnalysisV1";
import { checkFoodAnalysisSafety } from "./safety";

const QUOTA_FEATURE = "foodAnalysis";
// Debe coincidir con el límite de `storage.rules` — ver ese archivo.
const MAX_IMAGE_BYTES = 10 * 1024 * 1024;

interface AnalyzeFoodPhotoRequest {
  /** Id generado por el cliente (`firestore.collection(...).doc().id`), ya
   * usado como nombre del archivo subido a Storage. */
  analysisId: string;
}

interface AnalyzeFoodPhotoResponse {
  id: string;
  isFoodPhoto: boolean;
  foodName: string | null;
  portionDescription: string | null;
  calories: number | null;
  proteinGrams: number | null;
  carbsGrams: number | null;
  fatGrams: number | null;
  confidence: "low" | "medium" | "high" | null;
  uncertaintyNote: string | null;
  allergenWarning: boolean;
  analyzedAt: string;
  remainingToday: number;
}

/**
 * Analiza una foto de comida ya subida a Storage — Épica 8. El cliente sube
 * primero (los archivos son grandes para pasarlos por un callable) y luego
 * llama a esta función solo con el `analysisId`; la ruta de Storage se arma
 * SIEMPRE server-side a partir de `request.auth.uid`, nunca se confía en
 * una ruta que mande el cliente (Instrucciones.md §70).
 *
 * La imagen nunca sale de Google: se descarga con el Admin SDK (bypassa
 * `storage.rules`, funciona sobre un archivo privado) y se manda a OpenAI
 * como `data:` URI en base64 — nunca se genera una URL firmada/pública
 * (Instrucciones.md §68 "Avoid exposing public URLs unnecessarily").
 *
 * A diferencia de `generateDailyPlan`/`generateRecipe`, esta función NUNCA
 * "rechaza y regenera": el plato ya existe frente al usuario, no hay nada
 * que regenerar. Un alérgeno detectado se devuelve como advertencia
 * (`allergenWarning`), no como error — ver `safety.ts`. Una foto que no
 * muestra comida (`isFoodPhoto: false`) sí es un caso real de "sin
 * estimación útil", pero se devuelve como respuesta normal (como
 * `askNutritionAssistant`'s fallback de seguridad), no como `HttpsError` —
 * la cuota ya se gastó en una llamada real a OpenAI.
 *
 * Solo se persiste en Firestore (`users/{uid}/foodAnalyses/{analysisId}`)
 * un análisis que sí reconoció comida — no vale la pena un documento por
 * cada intento fallido. La foto en Storage no se borra en ese caso (gap
 * documentado, ver `documentation/food_analysis.md`).
 */
export const analyzeFoodPhoto = onCall<AnalyzeFoodPhotoRequest, Promise<AnalyzeFoodPhotoResponse>>(
  { secrets: [openAiApiKey], region: "us-central1", invoker: "public", enforceAppCheck: true },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión para analizar una foto.");
    }

    const analysisId = request.data?.analysisId?.trim();
    if (!analysisId) {
      throw new HttpsError("invalid-argument", "Falta `analysisId`.");
    }

    const storagePath = `users/${request.auth.uid}/foodAnalyses/${analysisId}.jpg`;
    const file = getStorage().bucket().file(storagePath);
    const [exists] = await file.exists();
    if (!exists) {
      throw new HttpsError("not-found", "No se encontró la foto. Intenta subirla de nuevo.");
    }

    const [metadata] = await file.getMetadata();
    const size = Number(metadata.size ?? 0);
    if (size > MAX_IMAGE_BYTES) {
      throw new HttpsError("invalid-argument", "La foto es demasiado grande.");
    }

    const profile = await fetchMinimalProfile(request.auth.uid);
    const quota = await consumeAiQuota(request.auth.uid, profile.isPremium, QUOTA_FEATURE);

    try {
      const [buffer] = await file.download();
      const base64Image = buffer.toString("base64");
      const contentType = (metadata.contentType as string | undefined) ?? "image/jpeg";

      const openai = getOpenAiClient();
      const response = await openai.responses.parse({
        model: AI_MODELS.foodPhotoAnalysis,
        input: [
          { role: "system", content: buildFoodAnalysisSystemPrompt({ avoidFoods: profile.avoidFoods }) },
          {
            role: "user",
            content: [
              { type: "input_text", text: "Analiza esta foto de comida." },
              { type: "input_image", image_url: `data:${contentType};base64,${base64Image}`, detail: "auto" },
            ],
          },
        ],
        text: { format: zodTextFormat(FoodAnalysisSchema, "food_analysis") },
      });

      const parsed = response.output_parsed;
      if (!parsed) {
        throw new Error("Empty structured output from OpenAI.");
      }

      const analyzedAt = new Date().toISOString();

      if (!parsed.isFoodPhoto) {
        logger.info("analyzeFoodPhoto: photo did not show recognizable food", { analysisId });
        return {
          id: analysisId,
          isFoodPhoto: false,
          foodName: null,
          portionDescription: null,
          calories: null,
          proteinGrams: null,
          carbsGrams: null,
          fatGrams: null,
          confidence: null,
          uncertaintyNote: null,
          allergenWarning: false,
          analyzedAt,
          remainingToday: quota.remainingToday,
        };
      }

      const safety = checkFoodAnalysisSafety(parsed, profile.avoidFoods);
      const result: AnalyzeFoodPhotoResponse = {
        id: analysisId,
        isFoodPhoto: true,
        foodName: parsed.foodName,
        portionDescription: parsed.portionDescription,
        calories: parsed.estimatedCalories,
        proteinGrams: parsed.estimatedProteinGrams,
        carbsGrams: parsed.estimatedCarbsGrams,
        fatGrams: parsed.estimatedFatGrams,
        confidence: parsed.confidence,
        uncertaintyNote: parsed.uncertaintyNote,
        allergenWarning: safety.allergenWarning,
        analyzedAt,
        remainingToday: quota.remainingToday,
      };

      await getFirestore()
        .collection("users")
        .doc(request.auth.uid)
        .collection("foodAnalyses")
        .doc(analysisId)
        .set({ ...result, imagePath: storagePath });

      return result;
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      await refundAiQuota(request.auth.uid, QUOTA_FEATURE);
      const err = error as { message?: string; status?: number; code?: string; type?: string; name?: string };
      logger.error(
        `analyzeFoodPhoto: OpenAI call failed :: name=${err.name} status=${err.status} code=${err.code} type=${err.type} message=${err.message}`,
      );
      throw new HttpsError("internal", "No se pudo analizar la foto en este momento. Intenta de nuevo.");
    }
  },
);

async function fetchMinimalProfile(userId: string): Promise<{ avoidFoods: string[]; isPremium: boolean }> {
  const doc = await getFirestore().collection("users").doc(userId).get();
  const data = doc.data();
  const onboarding = data?.onboarding as { avoidFoods?: string[] } | undefined;
  const subscription = data?.subscription as { isPremium?: boolean } | undefined;
  return {
    avoidFoods: onboarding?.avoidFoods ?? [],
    isPremium: subscription?.isPremium ?? false,
  };
}
