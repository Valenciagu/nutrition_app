import { HttpsError } from "firebase-functions/v2/https";
import { getAllergenKeywords } from "../foodCatalog";

/** Tope de comidas extra por día — acota el documento/consulta, no es una regla nutricional. */
export const MAX_EXTRA_MEALS_PER_DAY = 30;

/** Porción relativa a lo registrado (1 = tal cual). Fuera de este rango es casi seguro un error de toque. */
export const MIN_PORTION = 0.25;
export const MAX_PORTION = 5;

/** Macros "base" de una comida extra — los de la porción 1. */
export interface ExtraMealMacros {
  calories: number;
  proteinGrams: number;
  carbsGrams: number | null;
  fatGrams: number | null;
}

const DATE_KEY = /^\d{4}-\d{2}-\d{2}$/;
const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * `date` es el día LOCAL del usuario (YYYY-MM-DD, como `nutritionPlans`) —
 * el servidor no conoce su zona horaria, así que solo se acepta un día
 * cercano a "hoy" en UTC: hasta 2 días atrás (registrar lo de ayer por la
 * noche) y 1 adelante (husos horarios por delante de UTC). Evita llenar
 * días arbitrarios sin impedir el uso normal.
 */
export function parseDateKey(raw: unknown, now: Date = new Date()): string {
  const date = typeof raw === "string" ? raw.trim() : "";
  if (!DATE_KEY.test(date)) {
    throw new HttpsError("invalid-argument", "`date` debe ser YYYY-MM-DD.");
  }
  const parsed = Date.parse(`${date}T00:00:00Z`);
  const todayUtc = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
  if (Number.isNaN(parsed) || parsed < todayUtc - 2 * DAY_MS || parsed > todayUtc + DAY_MS) {
    throw new HttpsError("invalid-argument", "Solo se pueden registrar comidas de hoy o de los últimos días.");
  }
  return date;
}

export function parseMealName(raw: unknown): string {
  const name = typeof raw === "string" ? raw.trim().replace(/\s+/g, " ") : "";
  if (name.length < 2 || name.length > 80) {
    throw new HttpsError("invalid-argument", "El nombre debe tener entre 2 y 80 caracteres.");
  }
  return name;
}

function parseBoundedInt(raw: unknown, field: string, max: number): number {
  if (typeof raw !== "number" || !Number.isFinite(raw) || raw < 0 || raw > max) {
    throw new HttpsError("invalid-argument", `\`${field}\` debe ser un número entre 0 y ${max}.`);
  }
  return Math.round(raw);
}

function parseOptionalInt(raw: unknown, field: string, max: number): number | null {
  return raw === undefined || raw === null ? null : parseBoundedInt(raw, field, max);
}

/** Entrada manual ("Registrar sin foto"): kcal obligatoria, proteína por defecto 0, carbos/grasas opcionales. */
export function parseManualMacros(data: Record<string, unknown>): ExtraMealMacros {
  return {
    calories: parseBoundedInt(data.calories, "calories", 5000),
    proteinGrams: data.proteinGrams === undefined || data.proteinGrams === null ? 0 : parseBoundedInt(data.proteinGrams, "proteinGrams", 500),
    carbsGrams: parseOptionalInt(data.carbsGrams, "carbsGrams", 1000),
    fatGrams: parseOptionalInt(data.fatGrams, "fatGrams", 500),
  };
}

export function parsePortion(raw: unknown): number {
  if (typeof raw !== "number" || !Number.isFinite(raw) || raw < MIN_PORTION || raw > MAX_PORTION) {
    throw new HttpsError("invalid-argument", `\`portion\` debe estar entre ${MIN_PORTION} y ${MAX_PORTION}.`);
  }
  // Pasos de 0,25 — los únicos que ofrece la UI; redondear evita flotantes raros guardados.
  return Math.round(raw * 4) / 4;
}

/**
 * Mismo escaneo por subcadena que `recipes/safety.ts` sobre el NOMBRE de lo
 * que el usuario escribió — solo genera un aviso (como `analyzeFoodPhoto`):
 * la comida ya se comió, no hay nada que rechazar.
 */
export function nameMatchesAvoidedFoods(name: string, avoidFoodIds: string[]): boolean {
  const lower = name.toLowerCase();
  return avoidFoodIds.flatMap(getAllergenKeywords).some((keyword) => lower.includes(keyword.toLowerCase()));
}
