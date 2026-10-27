import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { getFirestore, type CollectionReference } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { getAuth } from "firebase-admin/auth";

/**
 * Subcolecciones bajo `users/{uid}` que hay que borrar a mano —
 * Firestore NO borra subcolecciones en cascada al borrar el documento padre.
 * Mantener esta lista al día con cada nueva subcolección de usuario
 * (Instrucciones.md §69 tiene el inventario canónico).
 */
const USER_SUBCOLLECTIONS = ["nutritionPlans", "recipes", "aiUsage", "shoppingLists", "foodAnalyses", "extraMeals"];

/**
 * Elimina la cuenta del usuario autenticado y TODOS sus datos —
 * Instrucciones.md §33-34 (privacidad: borrado de cuenta/datos). Solo borra
 * al propio `request.auth.uid`, nunca un uid que mande el cliente (no hay
 * ningún parámetro de entrada — el objetivo es siempre quien llama).
 *
 * Todo corre con el Admin SDK (bypassa reglas de Firestore/Storage) porque
 * ningún cliente debería poder borrar sub-colecciones ajenas ni su propio
 * usuario de Firebase Auth directamente. Usar el Admin SDK para borrar el
 * usuario de Auth también evita depender de una re-autenticación reciente
 * del lado del cliente (`user.delete()` del SDK de cliente la exige; el
 * Admin SDK no).
 *
 * Orden: subcolecciones → documento `users/{uid}` → archivos de Storage
 * (best-effort, un fallo aquí no debe impedir borrar la cuenta) → usuario de
 * Auth (al final: si algo antes falla, el usuario todavía puede reintentar
 * con la misma sesión).
 */
export const deleteAccount = onCall<void, Promise<{ deleted: true }>>(
  { region: "us-central1", invoker: "public", enforceAppCheck: true },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión para eliminar tu cuenta.");
    }
    const uid = request.auth.uid;

    try {
      const db = getFirestore();
      const userRef = db.collection("users").doc(uid);

      for (const subcollection of USER_SUBCOLLECTIONS) {
        await deleteCollection(userRef.collection(subcollection));
      }
      await userRef.delete();

      try {
        await getStorage().bucket().deleteFiles({ prefix: `users/${uid}/` });
      } catch (error) {
        logger.warn("deleteAccount: Storage cleanup failed, continuing", { uid, message: (error as Error).message });
      }

      await getAuth().deleteUser(uid);

      return { deleted: true };
    } catch (error) {
      logger.error("deleteAccount: failed", { uid, message: (error as Error).message });
      throw new HttpsError("internal", "No se pudo eliminar la cuenta en este momento. Intenta de nuevo.");
    }
  },
);

/** Patrón estándar de borrado recursivo por lotes (Firestore Admin SDK no tiene un `deleteCollection` nativo). */
async function deleteCollection(collectionRef: CollectionReference, batchSize = 200): Promise<void> {
  const snapshot = await collectionRef.limit(batchSize).get();
  if (snapshot.empty) return;

  const batch = collectionRef.firestore.batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();

  if (snapshot.size === batchSize) {
    await deleteCollection(collectionRef, batchSize);
  }
}
