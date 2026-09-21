# Épica 10 — Lista de compra

Estado: **completa** (2026-09-20), alcance v1 (ver "Deliberadamente fuera de alcance" abajo).

## Qué hace

Desde D1, la fila "Generar lista de compra" abre la lista de la semana actual (lun-vie, misma semana que D2): ingredientes agrupados por categoría (Proteína/Carbohidratos/Frutas/Verduras/Lácteos/Otros — Instrucciones.md §10), con checkbox para marcar "ya tengo/compré".

## Por qué no hay una Cloud Function nueva

Esta es la primera feature de IA-adyacente del proyecto que **no necesita IA ni backend propio**. Los ingredientes ya existen en Firestore — son `Recipe.ingredients` de las recetas que el usuario ya generó (Épica 7) para las comidas pendientes de su plan (Épica 6) — y las reglas de esos dos ya dejan al cliente leerlos directo. Armar la lista es pura agregación:

```
weekPlansProvider (ya existe, Épica 6) → comidas PENDIENTES de la semana
  → las que tienen `recipeId` → leer sus `Recipe` directo de Firestore
  → agrupar `RecipeIngredient`s por nombre normalizado
  → categorizar determinísticamente (sin IA — ver `grocery_categorizer.dart`)
```

Nada de esto pasa por `functions/` ni consume cuota de IA.

## Decisión central: NO se inventan ingredientes para comidas sin receta

`generateRecipe` (Épica 7) es perezoso — se genera solo cuando el usuario abre el detalle de una comida (D3). La mayoría de las comidas de un plan recién generado NO tienen una `Recipe` generada todavía. Dos caminos posibles:

1. Generar recetas para TODAS las comidas sin receta al construir la lista (N llamadas a OpenAI, lento, cuesta cuota solo por ver una lista de compra).
2. Solo agregar ingredientes de recetas que YA existen, y listar aparte las comidas sin receta como un aviso con acción ("toca para generar su receta").

Se eligió **2**: es instantáneo, gratis, y nunca le muestra al usuario un ingrediente que la IA no generó de verdad para esa comida específica — mismo principio anti-invención que el resto del proyecto (Instrucciones.md §37-38). La lista crece en precisión a medida que el usuario abre más recetas, en vez de mentir desde el día uno.

## Cantidades: sin suma numérica

`RecipeIngredient.quantity` es texto libre (`"200 g"`, `"2 unidades"` — decisión de la Épica 7, ver `documentation/recipes.md`). Si el mismo ingrediente aparece en dos recetas de la semana, NO se suman (`"200 g" + "150 g"` no es una operación segura sobre texto libre) — se listan una al lado de la otra en `GroceryItem.sources`, cada una con su comida/día de origen, para que el usuario las combine mentalmente. Revisar si vale la pena un sistema de unidades real si esto resulta insuficiente en uso real.

## "Comprado" vs. "ya lo tenía" — un solo estado

Instrucciones.md §10 pide poder marcar productos como "purchased" O "already available" — ambos casos significan lo mismo para la lista ("no necesito comprarlo"), así que es un solo booleano (`checked`) en vez de dos estados separados.

## Persistencia — sin Cloud Function tampoco

`users/{uid}/shoppingLists/{weekKey}` (`weekKey` = lunes de la semana, YYYY-MM-DD) — a diferencia de `nutritionPlans`/`recipes` (contenido generado por IA, el cliente nunca los escribe), esto es solo preferencia propia del usuario, así que `firestore.rules` le permite **escritura directa** (validada: solo el campo `checkedItems`, siempre una lista). `FieldValue.arrayUnion`/`arrayRemove` para marcar/desmarcar sin necesitar leer antes de escribir.

## Flutter (`lib/features/grocery_list/`)

- `GroceryCategory` + `GroceryItem`/`GroceryItemSource` (dominio) — `GroceryItemSource` guarda datos crudos (cantidad, `slotLabelKey`, fecha), NO un texto ya formateado: el texto final ("200 g · Almuerzo · lun") lo arma la UI, que es quien tiene `AppLocalizations`/locale a mano (un `FutureProvider` no debería depender de eso).
- `categorizeIngredient` — clasificación determinística por palabras clave en español, mismo patrón (y misma justificación: un falso positivo aquí es solo estético) que `ALLERGEN_KEYWORDS` del backend.
- `GroceryListRepository`/`FirebaseGroceryListRepository` — lee recetas por id directo de Firestore (`Future.wait`, mismo patrón que `FirebasePlanRepository.getPlansForDates`), lee/escribe el estado marcado.
- `groceryListProvider` (`FutureProvider.autoDispose<GroceryListData>`) hace toda la agregación; `groceryItemCheckControllerProvider` solo invalida esto al marcar/desmarcar (no releer recetas por un toggle sería más eficiente pero se aceptó la releída completa por simplicidad — es barata, sin IA de por medio).
- `GroceryListPage` — sin mock propio en el canvas de diseño (Fase 4 solo define la fila de D1 que navega aquí); construida con los tokens ya sincronizados del sistema de diseño.

## Deliberadamente fuera de alcance (v1)

- **Ajuste por texto libre** ("ya tengo arroz y huevos") — Instrucciones.md §10 lo describe explícitamente como algo que el sistema "eventually" debe soportar, no un requisito de v1. Necesitaría una Cloud Function nueva (interpretar el mensaje, decidir qué ítems marcar) — se deja para cuando haya señal real de que el toggle manual no alcanza.
- **Suma numérica de cantidades entre recetas** — ver arriba.
- **Rango de fechas configurable** — siempre "esta semana" (lun-vie), igual que D2; no hay forma de pedir la lista de una semana distinta o de un rango custom.

`flutter analyze` y `flutter build web --debug` limpios. Sin cambios en `functions/` — esta épica no toca el backend.
