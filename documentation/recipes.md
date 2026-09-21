# Épica 7 — Recetas

Estado: **completa** (2026-09-20).

## Qué existe hoy

Solo el modelo de dominio, en `lib/features/recipes/domain/entities/`:

- **`Recipe`** — receta completa: `id`, `name`, `description`, `servings`, `prepTimeMinutes`, `difficulty` (`RecipeDifficulty`: `easy`/`medium`/`hard`), `calories`/`proteinGrams`/`carbsGrams`/`fatGrams`, `ingredients` (`List<RecipeIngredient>`), `steps` (`List<RecipeStep>`). Cubre Instrucciones.md §8 completo.
- **`RecipeIngredient`** — `name`, `quantity` (texto libre, p. ej. `"200 g"`), `substitutes` (`List<String>`, posibles sustituciones — Instrucciones.md §8 último punto).
- **`RecipeStep`** — `instruction`, `timerSeconds` (`int?`, `null` si el paso no implica esperar) — pensado para D5 (modo cocina).

Mismo patrón que `NutritionPlan`/`PlannedMeal` (Épica 6): Dart plano, sin `freezed`, `toJson`/`fromJson`/`copyWith` escritos a mano.

## Esquema de Firestore (decidido, no implementado todavía)

`users/{userId}/recipes/{recipeId}` — Instrucciones.md §69, propiedad del usuario (igual criterio que `nutritionPlans`). `PlannedMeal.recipeId` (Épica 6) es el puente opcional desde una comida del plan hacia la receta completa.

## Decisiones de alcance de esta tarea

1. **Solo modelo de dominio** — sin repositorio, sin Cloud Function de generación, sin UI. Mismo criterio que PLAN-001 (Épica 6, tarea 6.1): fijar la forma del esquema antes de comprometerla en un prompt de IA.
2. **`quantity` es texto libre, no `amount`+`unit` estructurado** — evita construir un sistema de conversión/agregación de unidades que ninguna pantalla necesita hoy. Si la Épica 10 (lista de compra) necesita sumar cantidades entre recetas (p. ej. "2 tomates" + "3 tomates"), revisar ahí — no antes.
3. **Sin `imageUrl`** — ninguna función genera fotos de receta todavía, y el diseño (D2/D3) pide explícitamente un placeholder rayado, nunca un campo vacío simulando una foto que no existe.

## Generación de receta vía IA (`generateRecipe`)

Nueva Cloud Function `functions/src/recipes/generateRecipe.ts` — mismo pipeline seguro que `generateDailyPlan`/`adjustDailyPlan`: Flutter (futuro) → Auth → cuota (`recipeGeneration`, 5/día free · 20/día premium) → contexto → OpenAI → validación estructurada/seguridad → Firestore.

**Trigger**: `{date, mealId}` — una receta se genera para una comida concreta ya existente en el plan del usuario, no de forma independiente.

**Idempotente por comida**: si `PlannedMeal.recipeId` ya apunta a un documento existente en `users/{uid}/recipes/`, la función lo devuelve directo, sin llamar a OpenAI ni consumir cuota. Evita recobrar cada vez que el usuario abre D3. Si `recipeId` apunta a un documento que ya no existe (dato inconsistente), se regenera en vez de fallar.

**`calories`/`proteinGrams` nunca los genera el modelo** — se copian directo de la `PlannedMeal` ya conocida. Es la decisión de diseño central de esta tarea: si el modelo pudiera inventar sus propias calorías/proteína para la receta, D1 (plan) y D3 (receta) podrían mostrar kcal distintos para la misma comida. El modelo solo aporta lo que de verdad es nuevo: descripción, tiempo de preparación, dificultad, carbohidratos/grasas, ingredientes y pasos. `servings` tampoco se le pide al modelo — siempre es 1, igual al "Ingredientes · 1 ración" del diseño (D3).

**Cierra un hueco de seguridad documentado en la Épica 6**: `plan/safety.ts` (Épica 6) documentaba que no podía hacer un chequeo real ingrediente-por-ingrediente porque el nombre de una comida ("Pasta alfredo") no contiene literalmente la palabra "gluten" aunque la tenga — la única defensa ahí era la instrucción del prompt + la bandera autorreportada del modelo. Ahora que `generateRecipe` sí produce una lista real de ingredientes, `recipes/safety.ts` añade un tercer chequeo determinístico de verdad: escanea cada nombre de ingrediente contra `ALLERGEN_KEYWORDS` (palabras clave en español por alérgeno, en el nuevo `functions/src/foodCatalog.ts`). Substring simple, a propósito — mismo criterio que `ai/safety.ts` (Épica 5): para alérgenos, un falso positivo (rechazar una receta válida) es el modo de fallo seguro, uno negativo no lo es. Un cuarto chequeo valida que `proteinGrams*4 + carbsGrams*4 + fatGrams*9` no se desvíe demasiado de las `calories` ya fijadas (consistencia de macros).

**Nota**: este chequeo real solo existe una vez que el usuario abre el detalle de una comida y se genera su receta (D3) — un plan (D1) recién generado, cuyo usuario nunca abrió ninguna receta, sigue dependiendo solo del autorreporte del modelo a nivel de "comida". Ver `TASKS.md` "Open questions" para la discusión de generación eager vs. lazy.

`foodCatalog.ts` se movió de `functions/src/plan/` a `functions/src/` (raíz) porque ahora lo usan tanto `plan/` como `recipes/` — un archivo compartido sube a la raíz en vez de que una feature importe de otra, mismo criterio que `core/` en el árbol Dart.

Documento escrito: `users/{userId}/recipes/{recipeId}`, con la forma exacta de `Recipe.toJson()` — un futuro repositorio Dart puede hacer `Recipe.fromJson(doc.data())` directo. También actualiza `meals[index].recipeId` en el documento del plan del día (actualización de un elemento de array, mismo patrón que `registerMeal`, no una escritura directa del cliente). `firestore.rules` actualizado: el cliente puede leer sus propias recetas, nunca escribirlas.

`tsc`/`npm run build` limpios. **Alcance deliberadamente igual a PLAN-002 (Épica 6)**: solo backend — sin repositorio Dart, sin provider, sin UI todavía.

## Lado Dart (repositorio, provider, D3, D5)

`RecipeRepository`/`FirebaseRecipeRepository` (`lib/features/recipes/{domain,data}/repositories/`) — un solo método, `getOrGenerateRecipe`, llama al callable `generateRecipe` y no hace lecturas directas a Firestore (el callable ya devuelve la receta completa, cacheada o recién generada). `recipeProvider` es un `FutureProvider.autoDispose.family<Recipe, ({String date, String mealId})>` — se indexa por `(date, mealId)`, no por `recipeId`, porque D3 se navega ANTES de saber si ya existe una receta generada; el backend decide.

**D3 (Detalle de receta)** — `RecipeDetailPage`, anidada bajo el tab Plan (`RoutePaths.recipeDetailPath`, no una tab nueva) para que el back nativo funcione sin lógica extra. Foto grande (`HatchedPlaceholder`, nuevo widget compartido extraído del pintor de rayas antes privado de `MealCard`) con la hoja blanca montada encima vía `Transform.translate` (nunca un `margin` negativo — BUG-H01). Título, 3 chips (tiempo, dificultad, "Alta en proteína" si aplica — umbral ≥30% de las calorías, calculado en el cliente, no por la IA), fila de 4 `_MacroStatTile` (kcal/proteína/carbos/grasas, coloreados con `macroProtein`/`macroCarbs`/`macroFat`), lista de ingredientes (con sustitutos como texto secundario si la IA propuso alguno). Footer fijo: "Empezar a cocinar" (→ D5) + "Registrar" (marca la comida como comida directo, mismo `mealRegistrationControllerProvider` de la Épica 6, y cierra la pantalla al terminar).

Se llega a D3 desde un nuevo tercer renglón "Ver receta" en la hoja de acciones de una comida pendiente en D1 (`plan_page.dart`), antes de "Marcar como comido"/"Buscar otra opción".

**D5 (Modo cocina)** — `CookingModePage`, anidada bajo D3, recibe la `Recipe` ya cargada vía `extra` de GoRouter (no la vuelve a pedir — evita depender de que el provider `.autoDispose` de D3 siga vivo al navegar). Header con "✕", barra de progreso y contador "N/total". Paso actual: foto placeholder, "Paso N" + instrucción grande. Temporizador real (`Timer.periodic`, cancelado correctamente en `dispose()`) solo cuando el paso tiene `timerSeconds`. Footer "Anterior"/"Siguiente paso"; en el último paso el botón cambia a "Terminar", registra la comida y vuelve al plan.

**Decisiones de alcance, documentadas no adivinadas**:

- **Sin botón de favorito** (♡ en el mock) — no existe ningún concepto de "favorito" en el backend/dominio; un botón que solo cambia de color sin persistir nada sería una función que aparenta funcionar y no funciona, justo lo que este proyecto evita.
- **El link "Sustituir" del diseño no abre una hoja nueva** — se interpretó como mostrar los `substitutes` de cada ingrediente como texto secundario de solo lectura. El diseño apunta ese link a "D4", pero D4 ya está definido en el propio documento como "Reemplazar comida" (una comida completa, no un ingrediente) — reusarlo tal cual para sustituir un ingrediente habría sido forzar la referencia.
- **D3 no lista `Recipe.steps` en su propio cuerpo** — coincide con la transcripción del diseño, que en D3 solo describe la sección de ingredientes; los pasos son contenido exclusivo de D5.
- **`RecipeCard` no se construyó** — ningún flujo del backlog lista/navega varias recetas (D3 es una pantalla de detalle de UNA receta, no una tarjeta dentro de una lista); construirlo ahora sería un componente sin consumidor real, mismo criterio que `MacroBar`/`AIMessage` en Épicas anteriores.

`flutter analyze` y `flutter build web --debug` limpios.
