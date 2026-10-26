# Épica 9 — Foto de ingredientes → recetas ("Tengo ingredientes")

## Qué hace

El usuario fotografía su nevera, despensa, compras o empaques. Flujo en dos pasos, tal como lo define el canvas (Fase 6):

1. **F1 · Ingredientes detectados** — la foto arriba y la lista de lo que se ve, **editable**: quitar (✕), confirmar los dudosos (borde punteado, "Arroz · ¿seguro?") y "+ Añadir" a mano. "Ver recetas posibles" sigue solo con los confirmados.
2. **F2 · Recetas con lo que tienes** — "3 recetas para ti". Cada una lleva un badge "Tienes todo" (verde) o "Te falta N" (ámbar), kcal · proteína · minutos y, si falta algo, "Añadir X a la lista de compra" en un toque. "Pedir más ideas a la IA" trae otras recetas distintas sin volver a mandar la foto.

Al tocar una receta se ve su detalle completo (cuerpo de D3 + "Te falta conseguir") y se puede abrir el modo cocina.

Entradas: opción "Tengo ingredientes" de la hoja de cámara (C5) y fila en las acciones rápidas de Home (C1).

**Gratis por ahora (decisión del usuario, 2026-10-25).** La especificación la pone como premium, pero las suscripciones (Épica 13) siguen postergadas por costo. Va abierta a todos con límites diarios propios en `functions/src/ai/quota.ts`: `ingredientDetection` (fotos, 3/15) e `ingredientRecipes` (recetas, 6/30, más alto porque "más ideas" lo repite). Volverla premium es cambiar esos límites o agregar un chequeo de `isPremium`; el cliente no cambia.

## Diseño (canvas `Fases 5-12 - Entrega final.dc.html`, Fase 6, leído 2026-10-26)

- "Mismo motor visual que el análisis de comida, distinto resultado: en vez de una estimación, una lista editable de ingredientes que produce recetas."
- **F1**: foto de 270 de alto con botón volver. Título "Encontramos N ingredientes" (800, 23) y subtítulo "Quita lo que no tengas y añade lo que falte." Chips de 40 de alto, tipo píldora: seguros con borde verde de 1.5, fondo `actionPrimarySurface`, texto verde oscuro y "✕" al 60 %; dudosos con borde punteado y texto secundario; "+ Añadir" con borde normal y texto verde. Debajo, una caja de nota (fondo `background`, radio 16): "Los ingredientes con borde punteado son dudosos: confírmalos o quítalos." Al pie, CTA primario "Ver recetas posibles". Nota del canvas: "La confianza del modelo se expresa con el borde, no con porcentajes."
- **F2**: fondo `background`. Cabecera con ← y título "3 recetas para ti" (800, 22). Tarjetas blancas de radio 20: las dos primeras grandes (foto de 130 con badge arriba a la izquierda, nombre 700/16.5, meta 500/12.5 en gris, enlace verde a la lista de compra) y la tercera compacta (miniatura de 66 y nombre + kcal · proteína). Al final, botón de acción de IA (índigo) "Pedir más ideas a la IA". Nota del canvas: "Un badge dice si puedes cocinarla ya; 'te falta 1' enlaza con la lista de compra en un toque."
- **Fase 12** (accesibilidad): todo estado lleva texto además de color (los badges y los chips dudosos lo cumplen).

**Desviaciones, documentadas:**

- Los chips dudosos también llevan "✕". El canvas no lo dibuja, pero sin él la única forma de quitar uno dudoso sería confirmarlo primero, y el propio canvas pide "confírmalos o quítalos". Tocar el chip lo confirma.
- Las recetas no tienen foto real (ninguna función genera fotos de receta): la zona de foto es el placeholder rayado, igual que D3.
- La versión anterior de esta pantalla (2026-10-25, construida sin acceso al canvas) era de un solo paso, con la lista fija y `MealCard`. Se reemplazó por F1/F2.

## Backend (`functions/src/ingredients/`)

- `detectIngredients.ts` — F1. Callable con `enforceAppCheck`. Mismo pipeline que `analyzeFoodPhoto`: el cliente sube a `users/{uid}/ingredientPhotos/{photoId}.jpg` y llama solo con `photoId`; la ruta se arma con el `uid`; la foto va a OpenAI como `data:` URI y **se borra al terminar** (`finally`, con la regla de 1 día del bucket como respaldo). Devuelve `{name, confident}[]`, sin duplicados (si alguna copia es segura, gana).
- `suggestRecipesFromIngredients.ts` — F2. Callable de **texto** (sin foto, timeout de 120 s): `{ingredients, excludeRecipeNames}` → hasta 3 recetas con la forma de `Recipe.toJson()` + `missingIngredients`. Cada receta ≈ meta diaria / comidas del día (`estimateDailyCalories`, la misma fórmula que el plan).
- `input.ts` — `sanitizeNameList`: los nombres que manda el cliente (el usuario puede escribir ingredientes) se limpian y acotan (30 ingredientes, 12 exclusiones, 80 caracteres). El prompt los recibe como JSON y los declara datos, no instrucciones.
- `safety.ts` — `filterSafeSuggestedRecipes` reusa `checkRecipeSafety` (Épica 7): autorreporte, alérgenos por ingrediente **incluidos los faltantes**, y macros consistentes. Descarta solo las inseguras; si no queda ninguna, error y reembolso de cuota.
- `prompts/ingredientDetectionV1.ts`, `prompts/ingredientRecipesV1.ts`. Modelos: `AI_MODELS.ingredientPhotoAnalysis` (visión) y `recipeGeneration` (texto).
- `storage/userPhoto.ts` (compartido con `analyzeFoodPhoto`), `storage.rules` (subidas solo a `foodAnalyses` e `ingredientPhotos`).

Nada de esto se guarda en Firestore: no existe una pantalla de "mis recetas".

## Lista de compra (Épica 10, extendida)

"Añadir X a la lista de compra" escribe en `users/{uid}/shoppingLists/{weekKey}.extraItems` (`arrayUnion`, sin duplicados). `firestore.rules` permite ahora `checkedItems` y `extraItems`, ambas listas y opcionales, con `extraItems` acotada a 100 (con test de reglas). `groceryListProvider` mezcla esos ítems con los que salen de las recetas del plan; si ya estaban por una receta, no se duplican, y los manuales no muestran línea de origen. Se marcan como comprados igual que el resto. Todavía no se pueden borrar desde la lista.

## Cliente (`lib/features/ingredients/`)

- Entidades: `DetectedIngredient` (`name`, `confident`), `IngredientDetection`, `SuggestedRecipe` (`Recipe` + `missingIngredients`), `IngredientRecipeSuggestions`.
- `FirebaseIngredientAnalysisRepository` — `detectIngredients` (Storage + callable) y `suggestRecipes` (callable de texto).
- Providers, ninguno `autoDispose` para que volver atrás no gaste otra consulta; una foto nueva los reinicia:
  - `ingredientDetectionControllerProvider` — F1.
  - `ingredientListProvider` — la lista editable. Solo `confirmedNames` va a las recetas; añadir a mano confirma, ignora vacíos y repetidos, y confirma un dudoso repetido.
  - `ingredientRecipesControllerProvider` — F2. `moreIdeas()` excluye todo lo ya mostrado en la sesión, no solo la última tanda.
- Pantallas: `IngredientDetectionPage` (`/ingredients`), `IngredientRecipesPage` (`/ingredients/recipes`), `SuggestedRecipePage` (`/ingredients/recipe`) y `CookingModePage` sin `mealId` (`/ingredients/recipe/cook`).
- `IngredientChip` (nuevo, de la feature): no es `SelectableChip`, que alterna una selección; este quita o confirma, y lleva el borde punteado propio (`_DashedPillPainter`; Flutter no trae `BorderStyle.dashed`).
- Analytics: `ingredient_photo_analyzed` (`is_ingredient_photo`, `ingredient_count`).

Reusado: `RecipeDetailBody`/`RecipeInfoTag` (extraídos de D3), `CookingModePage`, `AppStateBlock`, `AppButton` (variante `aiAction`), `HatchedPlaceholder`, `showAppBottomSheet` + `AppTextField` para "+ Añadir", el pipeline de foto de la Épica 8.

## Pendiente / gaps

- **Desplegado por el usuario el 2026-10-26**: las tres funciones, `firestore.rules` y `storage.rules`.
- Sin probar en un dispositivo ni contra OpenAI real.
- Borrar ítems manuales desde la lista de compra.
- Tests: parseo, lista editable, filtro de seguridad, `sanitizeNameList` y reglas de `extraItems`. Faltan tests de las funciones completas con OpenAI simulado y widget tests de F1/F2.
