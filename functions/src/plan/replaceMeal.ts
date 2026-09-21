import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

interface ReplaceMealRequest {
  date: string;
  mealId: string;
  /** Índice dentro de `candidates` (0-2) devuelto por `suggestMealAlternatives`. */
  candidateIndex: number;
}

interface ReplaceMealResponse {
  date: string;
  mealId: string;
  name: string;
  calories: number;
  proteinGrams: number;
}

/**
 * D4 — confirma UNA de las alternativas generadas por
 * `suggestMealAlternatives` (identificada por índice, nunca por contenido
 * reenviado por el cliente) y la escribe como la comida real. Sin esto,
 * `replaceMeal` tendría que confiar en que el cliente reenvíe fielmente el
 * `name`/`calories`/`proteinGrams` que el servidor generó momentos antes —
 * en vez de eso, el servidor ya los tiene guardados (`candidates`, escrito
 * por `suggestMealAlternatives`) y solo hay que elegir cuál.
 */
export const replaceMeal = onCall<ReplaceMealRequest, Promise<ReplaceMealResponse>>(
  { region: "us-central1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const date = request.data?.date?.trim();
    const mealId = request.data?.mealId?.trim();
    const candidateIndex = request.data?.candidateIndex;
    if (!date || !mealId || typeof candidateIndex !== "number") {
      throw new HttpsError("invalid-argument", "Faltan `date`, `mealId` o `candidateIndex`.");
    }

    const planRef = getFirestore().collection("users").doc(request.auth.uid).collection("nutritionPlans").doc(date);
    const planDoc = await planRef.get();
    if (!planDoc.exists) {
      throw new HttpsError("not-found", "No hay un plan para esa fecha.");
    }

    const meals = (planDoc.data()?.meals as Array<Record<string, unknown>>) ?? [];
    const mealIndex = meals.findIndex((meal) => meal.id === mealId);
    if (mealIndex === -1) {
      throw new HttpsError("not-found", "Esa comida no existe en el plan de ese día.");
    }

    const meal = meals[mealIndex];
    const candidates = (meal.candidates as Array<{ name: string; calories: number; proteinGrams: number }>) ?? [];
    const chosen = candidates[candidateIndex];
    if (!chosen) {
      throw new HttpsError(
        "failed-precondition",
        "No hay alternativas generadas para esa comida todavía — pide alternativas primero.",
      );
    }

    meals[mealIndex] = {
      ...meal,
      name: chosen.name,
      calories: chosen.calories,
      proteinGrams: chosen.proteinGrams,
      candidates: [],
    };
    await planRef.update({ meals });

    return { date, mealId, name: chosen.name, calories: chosen.calories, proteinGrams: chosen.proteinGrams };
  },
);
