# Épica 16 — Tests (primera pasada, 2026-10-19)

Pasada dedicada, como se había acordado (no tests por feature). Prioridad: lógica pura con reglas de negocio reales, la capa de seguridad de la IA y las reglas de Firestore, que protegen datos que el cliente no debe tocar.

## Cómo correrlos

| Qué | Comando | Dónde |
|---|---|---|
| Dart (unitarios) | `flutter test` | raíz |
| Backend (unitarios) | `npm test` | `functions/` |
| Reglas de Firestore | `npm run test:rules` | `functions/` — levanta el emulador con `firebase emulators:exec` (necesita Java); usa un projectId `demo-*`, nunca toca el proyecto real |

El backend usa el runner propio de Node (`node:test`), sin agregar Jest/Mocha. Los tests se compilan con `tsconfig.test.json` a `functions/test-build/` (en `.gitignore` y en el `ignore` de `firebase.json`, así que nunca se despliegan).

## Qué cubren

**Dart (`test/`)**
- `core/utils` — `compareVersions` (versión mínima), `Validators`.
- `core/errors` — `mapFirebaseFunctionsException`: cada código de `HttpsError` → su `Failure`.
- `core/localization` — `messageForError`: cada `Failure` → su mensaje.
- `features/plan` — `computeStreak` (hoy sin registros, huecos, cambio de mes), `detectRepeatedMealsDay`, `NutritionPlan` (`registeredCalories`, JSON de ida y vuelta, `timeLabel`).
- `features/onboarding` — `estimateDailyCalories` con valores calculados a mano.
- `features/grocery_list` — `categorizeIngredient`, incluida la regresión de "fresas"/"queso fresco".
- `features/notifications` — `isInQuietHours`, incluido el rango que cruza medianoche.

**Backend (`functions/test/`)**
- `safety.test.ts` — las 4 capas de seguridad: plan (rango de calorías, autorreporte), receta (escaneo de alérgenos por ingrediente, macros vs. calorías), foto (advierte sin bloquear), asistente (alimento evitado, instrucciones de medicación).
- `calorieEstimate.test.ts` — **paridad con Dart**: mismos casos y mismos resultados que el test de Dart. Si alguien cambia la fórmula en un solo lado, uno de los dos falla.

**Reglas (`functions/test/rules/firestore.rules-spec.ts`)**
- Nadie puede escribirse `subscription.isPremium` (al crear, al actualizar, ni con `merge`).
- Escribir campos permitidos sigue funcionando aunque exista `subscription`.
- Aislamiento entre usuarios y sin sesión; el cliente no borra su documento.
- `aiUsage` invisible; `nutritionPlans`/`recipes` solo lectura del dueño; `shoppingLists` solo `checkedItems` como lista.

## Bug real encontrado

`categorizeIngredient` buscaba subcadenas: "res" (carne de res) atrapaba "fresas" y "queso fresco" como Proteína. Ahora busca por inicio de palabra (sigue cubriendo plurales).

## Pendiente

- Widget tests de pantallas: necesitan mocks de Firebase (`fake_cloud_firestore`, `firebase_auth_mocks`, dependencias nuevas). Se dejó fuera de esta pasada.
- Integration tests en dispositivo.
- Tests de las Cloud Functions completas (con OpenAI mockeado) y de `storage.rules`.
