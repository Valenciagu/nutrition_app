import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, type DocumentReference } from "firebase-admin/firestore";
import {
  MAX_EXTRA_MEALS_PER_DAY,
  nameMatchesAvoidedFoods,
  parseDateKey,
  parseManualMacros,
  parseMealName,
  type ExtraMealMacros,
} from "./input";

interface LogExtraMealRequest {
  /** Día local del usuario, YYYY-MM-DD (mismo formato que `nutritionPlans`). */
  date: string;
  source: "manual" | "photo";
  /** `manual`: lo que el usuario escribió. */
  name?: string;
  calories?: number;
  proteinGrams?: number;
  carbsGrams?: number | null;
  fatGrams?: number | null;
  /** `photo`: id de `users/{uid}/foodAnalyses/{analysisId}` (Épica 8). */
  analysisId?: string;
}

export interface ExtraMealDoc {
  id: string;
  date: string;
  name: string;
  source: "manual" | "photo";
  /** Macros de la porción 1 — lo que cuenta es `base × portion` (ver `editExtraMeal`). */
  base: ExtraMealMacros;
  portion: number;
  allergenWarning: boolean;
  analysisId: string | null;
  createdAt: string;
}

/**
 * LOG-101 — registra una "comida extra": algo comido fuera del plan, que
 * suma al día igual que una comida registrada del plan (decisión
 * 2026-10-25, ver TASKS.md Épica 19). Documento
 * `users/{uid}/extraMeals/{id}`; el cliente solo lo lee
 * (`firestore.rules`), toda escritura pasa por aquí o por `editExtraMeal`.
 *
 * Dos orígenes:
 * - `manual` ("Registrar sin foto", LOG-105): nombre y macros los da el
 *   usuario, acotados en `input.ts`. El aviso de alérgeno sale de escanear
 *   el nombre contra sus `avoidFoods`.
 * - `photo` ("Registrar comida" de E2, LOG-102): las cifras NO las manda el
 *   cliente — se leen del análisis que ya guardó `analyzeFoodPhoto`, así
 *   que lo registrado es exactamente lo que estimó la IA. El id
 *   `photo_{analysisId}` hace la operación idempotente: registrar dos veces
 *   el mismo análisis devuelve el mismo documento.
 *
 * Sin IA: no consume cuota. El tope diario (`MAX_EXTRA_MEALS_PER_DAY`)
 * solo acota cuántos documentos puede crear un cliente.
 */
export const logExtraMeal = onCall<LogExtraMealRequest, Promise<ExtraMealDoc>>(
  { region: "us-central1", invoker: "public", enforceAppCheck: true },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
    }
    const uid = request.auth.uid;
    const data = (request.data ?? {}) as unknown as Record<string, unknown>;
    const date = parseDateKey(data.date);

    const db = getFirestore();
    const userRef = db.collection("users").doc(uid);
    const extraMeals = userRef.collection("extraMeals");

    let docRef: DocumentReference;
    let fields: Omit<ExtraMealDoc, "id" | "createdAt">;

    if (data.source === "photo") {
      const analysisId = typeof data.analysisId === "string" ? data.analysisId.trim() : "";
      if (!analysisId) {
        throw new HttpsError("invalid-argument", "Falta `analysisId`.");
      }
      const analysis = (await userRef.collection("foodAnalyses").doc(analysisId).get()).data();
      if (!analysis || analysis.isFoodPhoto !== true || typeof analysis.calories !== "number") {
        throw new HttpsError("failed-precondition", "Ese análisis no tiene una comida que registrar.");
      }
      docRef = extraMeals.doc(`photo_${analysisId}`);
      fields = {
        date,
        name: String(analysis.foodName ?? "").slice(0, 80) || "Comida",
        source: "photo",
        base: {
          calories: analysis.calories,
          proteinGrams: typeof analysis.proteinGrams === "number" ? analysis.proteinGrams : 0,
          carbsGrams: typeof analysis.carbsGrams === "number" ? analysis.carbsGrams : null,
          fatGrams: typeof analysis.fatGrams === "number" ? analysis.fatGrams : null,
        },
        portion: 1,
        allergenWarning: analysis.allergenWarning === true,
        analysisId,
      };
    } else if (data.source === "manual") {
      const name = parseMealName(data.name);
      const avoidFoods = ((await userRef.get()).data()?.onboarding as { avoidFoods?: string[] } | undefined)?.avoidFoods ?? [];
      docRef = extraMeals.doc();
      fields = {
        date,
        name,
        source: "manual",
        base: parseManualMacros(data),
        portion: 1,
        allergenWarning: nameMatchesAvoidedFoods(name, avoidFoods),
        analysisId: null,
      };
    } else {
      throw new HttpsError("invalid-argument", "`source` debe ser `manual` o `photo`.");
    }

    return db.runTransaction(async (tx) => {
      const existing = await tx.get(docRef);
      if (existing.exists) {
        return existing.data() as ExtraMealDoc;
      }
      const sameDay = await tx.get(extraMeals.where("date", "==", date).limit(MAX_EXTRA_MEALS_PER_DAY));
      if (sameDay.size >= MAX_EXTRA_MEALS_PER_DAY) {
        throw new HttpsError("resource-exhausted", "Llegaste al máximo de comidas extra para este día.");
      }
      const doc: ExtraMealDoc = { id: docRef.id, ...fields, createdAt: new Date().toISOString() };
      tx.set(docRef, doc);
      return doc;
    });
  },
);
