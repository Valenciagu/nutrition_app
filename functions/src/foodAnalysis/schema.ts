import { z } from "zod";

/**
 * Salida estructurada del modelo para `analyzeFoodPhoto` (prompt
 * `food_analysis_v1`). Todos los campos de comida son `.nullable()`, no
 * opcionales (OpenAI structured outputs exige que todo campo esté siempre
 * presente) — quedan en `null` en bloque cuando `isFoodPhoto` es `false`.
 *
 * `isFoodPhoto` es el primer chequeo de sanidad: una foto de una persona,
 * una pantalla o algo irreconocible NUNCA debe producir una estimación de
 * calorías inventada — Instrucciones.md §37-38 (nunca deserializar a ciegas
 * la salida de la IA) aplica también a "¿esto es lo que dice que es?", no
 * solo a la forma del JSON.
 */
export const FoodAnalysisSchema = z.object({
  isFoodPhoto: z.boolean().describe("false if the photo does not actually show food or a meal"),
  foodName: z.string().min(2).max(100).nullable(),
  portionDescription: z
    .string()
    .min(2)
    .max(120)
    .nullable()
    .describe("brief, concrete portion size estimate, e.g. 'a medium plate, ~300 g'"),
  estimatedCalories: z.number().int().min(0).max(3000).nullable(),
  estimatedProteinGrams: z.number().int().min(0).max(200).nullable(),
  estimatedCarbsGrams: z.number().int().min(0).max(300).nullable(),
  estimatedFatGrams: z.number().int().min(0).max(200).nullable(),
  confidence: z.enum(["low", "medium", "high"]).nullable(),
  uncertaintyNote: z
    .string()
    .min(10)
    .max(220)
    .nullable()
    .describe("short, plain-language caveat about estimate precision — required whenever isFoodPhoto is true"),
  containsExcludedFood: z
    .boolean()
    .describe("true if the food appears to contain any of the user's excluded allergens/foods, listed in the prompt"),
});

export type FoodAnalysis = z.infer<typeof FoodAnalysisSchema>;
