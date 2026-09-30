import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

interface RegisterMealRequest {
  date: string;
  mealId: string;
  /** Por defecto true — permite también "desregistrar" (deshacer un toque accidental). */
  registered?: boolean;
}

interface RegisterMealResponse {
  date: string;
  mealId: string;
  status: "pending" | "registered";
}

/**
 * Marca (o desmarca) una comida del plan de un día como consumida. Función
 * separada de `generateDailyPlan`/`adjustDailyPlan` a propósito — no una
 * escritura directa del cliente a Firestore — para poder validar que el
 * `mealId` pertenece de verdad al plan del usuario sin necesitar reglas de
 * Firestore que validen un elemento dentro de un array (Firestore no lo
 * hace bien). Nada de IA aquí, así que no consume cuota
 * (`functions/src/ai/quota.ts`) — es una operación determinística y barata.
 */
export const registerMeal = onCall<RegisterMealRequest, Promise<RegisterMealResponse>>(
  { region: "us-central1", invoker: "public" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const date = request.data?.date?.trim();
    const mealId = request.data?.mealId?.trim();
    if (!date || !mealId) {
      throw new HttpsError("invalid-argument", "Faltan `date` o `mealId`.");
    }
    const registered = request.data?.registered ?? true;

    const docRef = getFirestore().collection("users").doc(request.auth.uid).collection("nutritionPlans").doc(date);
    const doc = await docRef.get();
    if (!doc.exists) {
      throw new HttpsError("not-found", "No hay un plan para esa fecha.");
    }

    const meals = (doc.data()?.meals as Array<Record<string, unknown>>) ?? [];
    const index = meals.findIndex((meal) => meal.id === mealId);
    if (index === -1) {
      throw new HttpsError("not-found", "Esa comida no existe en el plan de ese día.");
    }

    meals[index] = { ...meals[index], status: registered ? "registered" : "pending" };
    await docRef.update({ meals });

    return { date, mealId, status: registered ? "registered" : "pending" };
  },
);
