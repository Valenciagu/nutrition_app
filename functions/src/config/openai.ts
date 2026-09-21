import OpenAI from "openai";
import { defineSecret } from "firebase-functions/params";

/**
 * OpenAI API key — never stored in code, `.env` files, or the Flutter app
 * (Instrucciones.md §19-21). Set once per environment with:
 *   firebase functions:secrets:set OPENAI_API_KEY
 * For local emulator testing, Firebase reads it from `functions/.secret.local`
 * (gitignored) — never commit a real key there either.
 */
export const openAiApiKey = defineSecret("OPENAI_API_KEY");

let client: OpenAI | undefined;

/** Lazily creates the OpenAI client inside a function's execution, once the bound secret is readable. */
export function getOpenAiClient(): OpenAI {
  if (!client) {
    client = new OpenAI({ apiKey: openAiApiKey.value() });
  }
  return client;
}

/**
 * Centralized model routing (Instrucciones.md §77-78): pick models here, not
 * scattered across individual functions, so swapping models later doesn't
 * mean hunting through call sites. `gpt-5.6-luna` is OpenAI's lowest-cost
 * general text model per the current official pricing page
 * (developers.openai.com/api/docs/pricing, checked 2026-09-19) — appropriate
 * for a Q&A task, not the flagship reasoning tier.
 */
export const AI_MODELS = {
  nutritionQa: "gpt-5.6-luna",
  // Misma familia que `nutritionQa` hoy — clave propia para que un cambio de
  // routing futuro (Instrucciones.md §78: "Recipe generation → appropriate
  // general model") no obligue a tocar `generateRecipe.ts`.
  recipeGeneration: "gpt-5.6-luna",
  // `gpt-5.6-luna` ya es nativamente multimodal (acepta `input_image`,
  // Instrucciones.md §78: "Image analysis → vision-capable model") — clave
  // propia igual que `recipeGeneration`, no porque hoy sea un modelo
  // distinto, sino para poder enrutar análisis de imagen a un modelo
  // diferente en el futuro sin tocar `analyzeFoodPhoto.ts`.
  foodPhotoAnalysis: "gpt-5.6-luna",
} as const;
