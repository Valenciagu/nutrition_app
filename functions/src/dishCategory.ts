import { z } from "zod";

/**
 * RECIPE-101 — tipo de plato, de una lista CERRADA. Cada comida/receta que
 * genera la IA elige uno, y el cliente lo convierte en una foto ilustrativa
 * (`assets/images/dish_<categoría>.jpg`). Así el número de fotos no crece
 * con las combinaciones de ingredientes: hay una por categoría.
 *
 * Mantener en sincronía con `DishCategory` en
 * `lib/features/recipes/domain/entities/dish_category.dart` — un valor que
 * el cliente no conoce se muestra con el placeholder rayado, nunca rompe.
 */
export const DISH_CATEGORIES = [
  "salad",
  "bowl",
  "soup",
  "pasta",
  "rice",
  "protein_plate",
  "fish",
  "eggs",
  "wrap_sandwich",
  "tacos_arepa",
  "oats_yogurt",
  "smoothie",
  "toast",
  "snack_fruit",
  "dessert",
  "stir_fry",
] as const;

export type DishCategory = (typeof DISH_CATEGORIES)[number];

export const DishCategorySchema = z
  .enum(DISH_CATEGORIES)
  .describe(
    "the dish type that best matches how it is served, for an illustrative photo: " +
      "salad, bowl (grain/rice bowl), soup (soup or cream), pasta, rice (fried/stir-fried rice or rice dish), " +
      "protein_plate (meat or chicken with sides), fish (fish or seafood), eggs (eggs/omelette), " +
      "wrap_sandwich, tacos_arepa (tacos, arepas, quesadillas, empanadas), oats_yogurt (oatmeal, yogurt, granola), " +
      "smoothie, toast, snack_fruit (fruit or light snack), dessert, stir_fry (wok/sautéed vegetables)",
  );
