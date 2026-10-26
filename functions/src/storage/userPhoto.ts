import { HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { getStorage } from "firebase-admin/storage";

// Debe coincidir con el límite de `storage.rules` — ver ese archivo.
export const MAX_IMAGE_BYTES = 10 * 1024 * 1024;

export type StorageFile = ReturnType<ReturnType<ReturnType<typeof getStorage>["bucket"]>["file"]>;

/**
 * Referencia a una foto que el cliente ya subió a
 * `users/{uid}/{folder}/{photoId}.jpg`. La ruta se arma SIEMPRE aquí, a
 * partir del `uid` autenticado — nunca se acepta una ruta del cliente
 * (Instrucciones.md §70). Extraído de `analyzeFoodPhoto` (Épica 8) al
 * aparecer su segundo consumidor, `suggestRecipesFromIngredients` (Épica 9).
 */
export function userPhotoFile(uid: string, folder: string, photoId: string): StorageFile {
  return getStorage().bucket().file(`users/${uid}/${folder}/${photoId}.jpg`);
}

/** `not-found` si no existe, `invalid-argument` si supera [MAX_IMAGE_BYTES]. */
export async function assertPhotoUsable(file: StorageFile): Promise<void> {
  const [exists] = await file.exists();
  if (!exists) {
    throw new HttpsError("not-found", "No se encontró la foto. Intenta subirla de nuevo.");
  }
  const [metadata] = await file.getMetadata();
  if (Number(metadata.size ?? 0) > MAX_IMAGE_BYTES) {
    throw new HttpsError("invalid-argument", "La foto es demasiado grande.");
  }
}

/**
 * La foto como `data:` URI para OpenAI — nunca una URL firmada/pública
 * (Instrucciones.md §68). La imagen no sale de Google salvo hacia OpenAI.
 */
export async function photoAsDataUri(file: StorageFile): Promise<string> {
  const [[buffer], [metadata]] = await Promise.all([file.download(), file.getMetadata()]);
  const contentType = (metadata.contentType as string | undefined) ?? "image/jpeg";
  return `data:${contentType};base64,${buffer.toString("base64")}`;
}

/**
 * Retención (Instrucciones.md §68): ninguna pantalla vuelve a mostrar una
 * foto ya analizada, así que se borra al terminar. Nunca hace fallar la
 * llamada — si falla, la regla de ciclo de vida del bucket
 * (`storage-lifecycle.json`, borra `users/` tras 1 día) es la red.
 */
export async function deletePhotoQuietly(file: StorageFile, context: string): Promise<void> {
  try {
    await file.delete({ ignoreNotFound: true });
  } catch (error) {
    logger.warn(`${context}: could not delete photo, lifecycle rule will`, {
      path: file.name,
      message: (error as Error).message,
    });
  }
}
