import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { parsePortion } from "./input";

interface EditExtraMealRequest {
  mealId: string;
  /** Nueva porción (0,25–5, pasos de 0,25). Se ignora si `delete` es true. */
  portion?: number;
  delete?: boolean;
}

interface EditExtraMealResponse {
  mealId: string;
  deleted: boolean;
  portion: number | null;
}

/**
 * LOG-101 — lo único editable de una comida extra (decisión 2026-10-25,
 * TASKS.md Épica 19): la **porción** (los macros se escalan desde `base`,
 * que nunca se toca) o **borrarla**. Qué se comió no se edita: para
 * cambiarlo se borra y se vuelve a registrar — así una estimación de la IA
 * no termina mezclada con cifras escritas a mano.
 */
export const editExtraMeal = onCall<EditExtraMealRequest, Promise<EditExtraMealResponse>>(
  { region: "us-central1", invoker: "public", enforceAppCheck: true },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
    }
    const mealId = typeof request.data?.mealId === "string" ? request.data.mealId.trim() : "";
    if (!mealId || mealId.includes("/")) {
      throw new HttpsError("invalid-argument", "Falta `mealId`.");
    }

    const docRef = getFirestore().collection("users").doc(request.auth.uid).collection("extraMeals").doc(mealId);

    if (request.data?.delete === true) {
      // Borrar algo que ya no existe deja el mismo resultado: no es un error.
      await docRef.delete();
      return { mealId, deleted: true, portion: null };
    }

    const portion = parsePortion(request.data?.portion);
    const doc = await docRef.get();
    if (!doc.exists) {
      throw new HttpsError("not-found", "Esa comida ya no existe.");
    }
    await docRef.update({ portion });
    return { mealId, deleted: false, portion };
  },
);
