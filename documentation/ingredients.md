# Épica 9 — Foto de ingredientes → recetas

## Qué hace

"Tengo ingredientes": el usuario fotografía su nevera, despensa, compras o empaques. La app muestra los ingredientes que se ven y hasta 3 recetas de 1 ración hechas sobre todo con ellos (Instrucciones.md §7), cada una con lo que faltaría conseguir. Al tocar una receta se ve su detalle completo y se puede abrir el modo cocina.

Entradas: opción "Tengo ingredientes" de la hoja de cámara (C5) y fila nueva en las acciones rápidas de Home (C1).

**Gratis por ahora (decisión del usuario, 2026-10-25).** La especificación la pone como premium, pero las suscripciones (Épica 13) siguen postergadas por costo. Va abierta a todos con un límite diario propio y bajo: `ingredientAnalysis` en `functions/src/ai/quota.ts`, 3 al día gratis y 15 premium; la especificación ya pide "análisis limitados de fotos de ingredientes" en el plan gratis. Volverla premium es cambiar ese límite o agregar un chequeo de `isPremium` en la función; el cliente no cambia.

## Backend (`functions/src/ingredients/`)

- `suggestRecipesFromIngredients.ts` — callable con `enforceAppCheck`, timeout de 120 s. Mismo pipeline que `analyzeFoodPhoto`: el cliente sube a `users/{uid}/ingredientPhotos/{photoId}.jpg` y llama solo con `photoId`; la ruta se arma con el `uid`; la foto viaja a OpenAI como `data:` URI y **se borra al terminar** (`finally`), con la regla de 1 día del bucket como respaldo.
- `schema.ts` — `SuggestedRecipeSchema` extiende `GeneratedRecipeSchema` (Épica 7) con nombre, kcal, proteína y `missingIngredients`. La respuesta tiene la forma exacta de `Recipe.toJson()` más `missingIngredients`.
- `prompts/ingredientRecipesV1.ts` — solo ingredientes que de verdad se ven; básicos (sal, pimienta, aceite, agua) no cuentan como faltantes; ingredientes latinoamericanos; cada receta ≈ meta diaria / comidas del día del usuario (misma fórmula que el plan, `estimateDailyCalories`).
- `safety.ts` — `filterSafeSuggestedRecipes` reusa `checkRecipeSafety` (Épica 7): autorreporte, escaneo de alérgenos por ingrediente **incluyendo los faltantes**, y macros consistentes con las kcal. A diferencia de `generateRecipe`, descarta solo las recetas inseguras; si no queda ninguna, devuelve error y reembolsa la cuota.
- `storage/userPhoto.ts` (nuevo, compartido) — armar la ruta, validar tamaño, `data:` URI y borrado. Extraído de `analyzeFoodPhoto` al aparecer este segundo consumidor.
- `storage.rules` — la regla de subida ahora cubre `foodAnalyses` e `ingredientPhotos`, y nada más bajo `users/`.

Nada se guarda en Firestore: no existe una pantalla de "mis recetas" que vuelva a mostrarlas, así que serían datos sin consumidor.

## Cliente (`lib/features/ingredients/`)

- `IngredientSuggestions` / `SuggestedRecipe` — la receta es una `Recipe` normal más `missingIngredients`.
- `FirebaseIngredientAnalysisRepository` — sube y llama al callable (timeout de cliente de 120 s). El mapeo de errores de Storage se movió a `core/errors/firebase_storage_error_mapper.dart` (segundo consumidor).
- `IngredientAnalysisController` — no es `autoDispose`: volver desde una receta muestra las mismas sugerencias sin gastar otra consulta.
- `IngredientAnalysisPage` (`/ingredients`) — foto arriba con hoja encima (mismo esquema que `FoodAnalysisPage`): cargando, error con mensaje específico, "no vemos ingredientes", o ingredientes detectados + 3 `MealCard` + nota de que son sugerencias de IA.
- `SuggestedRecipePage` (`/ingredients/recipe`) — `RecipeDetailBody` + "Te falta conseguir" + solo "Empezar a cocinar" (no hay comida del plan que registrar).
- Modo cocina (`/ingredients/recipe/cook`) — `CookingModePage` con `mealId` opcional: sin él, "Terminar" solo cierra.

## Reusado vs. nuevo

Reusado: `MealCard` para listar recetas (el `RecipeCard` diferido sigue sin construirse), `RecipeInfoTag`, `AppStateBlock`, `RoundIconButton`, `CookingModePage`, el pipeline de foto de la Épica 8. Extraído para compartir: `RecipeDetailBody` (de D3), `recipeDifficultyLabel`, `pickPhotoAndOpen` (hoja de cámara), `storage/userPhoto.ts`, `mapFirebaseStorageException`.

Arreglo de paso: "Cocinar" en Home ahora alinea `selectedPlanDateProvider` a hoy. "Registrar" en D3/D5 usa ese día, y antes podía registrar en el día que mirara Plan.

## Pendiente / gaps

- **Diseño**: el canvas de Fase 6 (Ingredientes) no se pudo leer (Claude Design rechazó la sesión con 403; hace falta `/design-login`). Las pantallas usan solo componentes y tokens existentes; revisarlas contra el canvas cuando haya acceso.
- **Necesita despliegue**: `firebase deploy --only functions:suggestRecipesFromIngredients,functions:analyzeFoodPhoto,storage`. Sin desplegar la regla de Storage, la subida a `ingredientPhotos` falla con permiso denegado.
- Sin probar en un dispositivo ni contra OpenAI real.
- Tests: parseo del cliente y filtro de seguridad. Faltan tests de la función completa con OpenAI simulado y de `storage.rules`.
