import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { getFirestore } from "firebase-admin/firestore";
import { zodTextFormat } from "openai/helpers/zod";
import { AI_MODELS, getOpenAiClient, openAiApiKey } from "../config/openai";
import { consumeAiQuota, refundAiQuota } from "../ai/quota";
import {
  assertPhotoUsable,
  deletePhotoQuietly,
  photoAsDataUri,
  userPhotoFile,
  type StorageFile,
} from "../storage/userPhoto";
import { DetectedIngredientsSchema } from "./schema";
import { buildIngredientDetectionSystemPrompt } from "./prompts/ingredientDetectionV1";

const QUOTA_FEATURE = "ingredientDetection";
const PHOTO_FOLDER = "ingredientPhotos";

interface DetectIngredientsRequest {
  /** Id generado por el cliente, ya usado como nombre del archivo en Storage. */
  photoId: string;
}

interface DetectIngredientsResponse {
  isIngredientPhoto: boolean;
  ingredients: { name: string; confident: boolean }[];
  remainingToday: number;
}

/**
 * Épica 9, paso F1 (Fase 6 del canvas) — foto de nevera/despensa →
 * ingredientes visibles, cada uno con `confident`. Solo detecta: el usuario
 * revisa la lista (quita, confirma dudosos, añade) y las recetas se piden
 * después con `suggestRecipesFromIngredients`, sobre texto, sin volver a
 * mandar la foto.
 *
 * Mismo pipeline que `analyzeFoodPhoto` (Épica 8): el cliente sube a
 * `users/{uid}/ingredientPhotos/{photoId}.jpg`, la ruta se arma aquí desde
 * el `uid`, la foto viaja a OpenAI como `data:` URI y se borra al terminar
 * (`finally`), salga bien o mal.
 *
 * **Gratis por ahora (decisión del usuario, 2026-10-25)**: la especificación
 * la ubica como premium; sin suscripciones (Épica 13) se abre a todos con
 * su propio límite diario (`ingredientDetection` en `ai/quota.ts`).
 */
export const detectIngredients = onCall<DetectIngredientsRequest, Promise<DetectIngredientsResponse>>(
  { secrets: [openAiApiKey], region: "us-central1", invoker: "public", enforceAppCheck: true },
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
      return await detectFromStoredPhoto(request.auth.uid, file);
    } finally {
      await deletePhotoQuietly(file, "detectIngredients");
    }
  },
);

async function detectFromStoredPhoto(uid: string, file: StorageFile): Promise<DetectIngredientsResponse> {
  const userDoc = await getFirestore().collection("users").doc(uid).get();
  const isPremium = (userDoc.data()?.subscription as { isPremium?: boolean } | undefined)?.isPremium ?? false;
  const quota = await consumeAiQuota(uid, isPremium, QUOTA_FEATURE);

  try {
    const imageDataUri = await photoAsDataUri(file);
    const response = await getOpenAiClient().responses.parse({
      model: AI_MODELS.ingredientPhotoAnalysis,
      input: [
        { role: "system", content: buildIngredientDetectionSystemPrompt() },
        {
          role: "user",
          content: [
            { type: "input_text", text: "¿Qué ingredientes ves?" },
            { type: "input_image", image_url: imageDataUri, detail: "auto" },
          ],
        },
      ],
      text: { format: zodTextFormat(DetectedIngredientsSchema, "detected_ingredients") },
    });

    const parsed = response.output_parsed;
    if (!parsed) {
      throw new Error("Empty structured output from OpenAI.");
    }

    // Una foto sin ingredientes no es un error (igual que una foto sin
    // comida en Épica 8): la cuota ya se gastó en una llamada real.
    const ingredients = parsed.isIngredientPhoto ? dedupeByName(parsed.ingredients) : [];
    return {
      isIngredientPhoto: parsed.isIngredientPhoto && ingredients.length > 0,
      ingredients,
      remainingToday: quota.remainingToday,
    };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    await refundAiQuota(uid, QUOTA_FEATURE);
    const err = error as { message?: string; status?: number; code?: string; name?: string };
    logger.error(
      `detectIngredients: OpenAI call failed :: name=${err.name} status=${err.status} code=${err.code} message=${err.message}`,
    );
    throw new HttpsError("internal", "No se pudieron analizar tus ingredientes en este momento. Intenta de nuevo.");
  }
}

/** El modelo a veces repite un ingrediente; si alguna copia es segura, gana. */
function dedupeByName(items: { name: string; confident: boolean }[]): { name: string; confident: boolean }[] {
  const byKey = new Map<string, { name: string; confident: boolean }>();
  for (const item of items) {
    const name = item.name.trim();
    const key = name.toLowerCase();
    const existing = byKey.get(key);
    byKey.set(key, { name: existing?.name ?? name, confident: (existing?.confident ?? false) || item.confident });
  }
  return [...byKey.values()];
}
