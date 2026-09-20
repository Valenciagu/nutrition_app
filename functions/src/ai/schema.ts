import { z } from "zod";

/**
 * Structured output contract for `askNutritionAssistant` (prompt version
 * nutrition_assistant_v1). The backend validates every field before it ever
 * reaches Flutter — never blindly deserialize untrusted AI output
 * (Instrucciones.md §37-38).
 */
export const NutritionAssistantResponseSchema = z.object({
  answer: z.string().min(1).max(2000),
  mentionsRestrictedFood: z
    .boolean()
    .describe("true if the answer suggests or mentions any food the user must avoid"),
  recommendsProfessionalConsult: z
    .boolean()
    .describe("true if a doctor or registered dietitian should be consulted for this question"),
});

export type NutritionAssistantResponse = z.infer<typeof NutritionAssistantResponseSchema>;
