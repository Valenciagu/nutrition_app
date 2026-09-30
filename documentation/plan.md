# Épica 6 — Plan de comidas (Meal Planning / Daily Plan) — COMPLETA

## Qué hace

- **Tarea 6.1**: modelo de dominio puro — `NutritionPlan` (un día) y `PlannedMeal` (una comida dentro de ese día).
- **PLAN-002**: generación real del plan por IA (`generateDailyPlan`).
- **PLAN-003/005**: repositorio Dart + pantalla D1 real (plan del día) — reemplaza el `ComingSoonPage` del tab "Plan".
- **PLAN-004**: ajustes adaptativos por IA ("no tengo pollo", "ya comí una hamburguesa" — Instrucciones.md §9) vía `adjustDailyPlan`.
- **PLAN-006**: marcar una comida como consumida (`registerMeal`), vista semanal D2, y la hoja de reemplazar comida D4 (`suggestMealAlternatives` + `replaceMeal`).

Diseño: `documentation/design_screens_plan.md` (Fase 4 · Plan y recetas, 5 pantallas D1-D5). El modo cocina (D5) queda confirmado en alcance pero vive en la Épica 7 (se llega a él desde el detalle de receta, que tampoco existe todavía).

## Archivos clave

**Dominio** (`lib/features/plan/domain/`):
- `entities/planned_meal.dart` — `PlannedMeal` + `MealStatus` (`pending`/`registered`).
- `entities/nutrition_plan.dart` — `NutritionPlan` (plan de un día + lista de `PlannedMeal`).
- `entities/meal_alternative.dart` — `MealAlternative` (D4, efímera, no se persiste hasta confirmarse).
- `repositories/plan_repository.dart` — contrato `PlanRepository`, un método por Cloud Function real.

**Datos**: `data/repositories/firebase_plan_repository.dart` — `FirebasePlanRepository`, única implementación, sin capa de "data source" aparte (mismo criterio que `FirebaseAiService`, Épica 5).

**Presentación**:
- `presentation/providers/plan_providers.dart` — repositorio, fecha/vista seleccionada, y un `AsyncNotifier` por acción (generar, ajustar, registrar, alternativas) — mismo patrón que `AuthController`.
- `presentation/widgets/day_strip.dart` — selector de 5 días (D1/D2).
- `presentation/widgets/week_plan_view.dart` — D2.
- `presentation/widgets/replace_meal_sheet.dart` — D4.
- `presentation/widgets/adjust_plan_sheet.dart` — entrada de texto libre para PLAN-004.
- `presentation/pages/plan_page.dart` — `PlanPage`, orquesta todo lo anterior.

**Core nuevo/extendido**: `lib/core/widgets/meal_card.dart` (`MealCard`, 10/10 del sistema base de componentes), `lib/core/errors/firebase_functions_error_mapper.dart`, `lib/core/utils/date_key.dart`; `AppStateBlock.empty` (+`isActionLoading`) y `QuickActionTile` (`subtitle` opcional) extendidos, no forkeados.

**Backend** (`functions/src/plan/`):
- `generateDailyPlan.ts` — genera y persiste el plan de un día.
- `adjustDailyPlan.ts` — ajusta las comidas pendientes de un plan ya generado.
- `registerMeal.ts` — marca/desmarca una comida como consumida (sin IA, sin cuota).
- `suggestMealAlternatives.ts` — 3 alternativas para una comida pendiente.
- `replaceMeal.ts` — confirma una alternativa generada.
- `calorieEstimate.ts`, `foodCatalog.ts`, `schema.ts`, `safety.ts`, `prompts/{nutritionPlanV1,nutritionAdjustmentV1,mealAlternativesV1}.ts` — infraestructura compartida entre las funciones de IA de arriba.

## Esquema de Firestore

`users/{userId}/nutritionPlans/{yyyy-mm-dd}` — **un documento por día**, no por semana (Instrucciones.md §23 — evitar documentos no acotados y escrituras excesivas). Reemplazar, registrar o pedir alternativas para una comida solo toca el día que cambia; D2 lee 5 documentos (uno por día visible), no una query de rango sobre un blob semanal. Mismo patrón que `aiUsage/{yyyy-mm-dd}` (Épica 5).

`PlannedMeal` denormaliza `name`/`calories`/`proteinGrams` directamente en la comida — el plan completo de un día se lee con una sola lectura de Firestore, sin N+1 queries a recetas. `recipeId` es el puente opcional hacia la `Recipe` completa que construirá la Épica 7 (hoy siempre `null`).

**Campo efímero `candidates`** (solo mientras existe una hoja D4 abierta para esa comida): `suggestMealAlternatives` lo escribe con las 3 alternativas generadas; `replaceMeal` lo lee, aplica la elegida por índice, y lo vacía. No es parte del contrato `PlannedMeal.toJson()`/`fromJson()` del lado Dart — `fromJson` simplemente ignora esta clave extra al no leerla, así que no hace falta modelarla en el dominio.

## Generación y ajuste del plan por IA (PLAN-002/004)

- Pipeline segura, igual patrón que `askNutritionAssistant` (Épica 5): auth → perfil server-side → cuota → OpenAI → validación estructurada/seguridad → Firestore → cliente.
- `calorieEstimate.ts` — **port exacto a TypeScript** de `estimateDailyCalories` (Dart, `lib/features/onboarding/domain/calorie_estimate.dart`). No hay forma de compartir código entre Flutter y Node — si la fórmula cambia en un lado, hay que replicarla en el otro. El objetivo de calorías se calcula server-side y se le pasa a la IA como un solo número, **nunca la edad/peso/altura crudos** (mejor minimización de datos que Instrucciones.md §35 pide).
- `foodCatalog.ts` — mapea los IDs de catálogo de `onboarding_catalog.dart` a instrucciones concretas para el prompt (p. ej. `gluten` → "sin gluten (nada de trigo, cebada, centeno, pan o pasta tradicional)").
- La IA SOLO genera `{ name, calories, proteinGrams, containsExcludedFood }` por comida — nunca `slotLabelKey` ni hora (vienen determinísticamente de `mealSlots` del usuario, o de la comida original en `adjustDailyPlan`/`suggestMealAlternatives`). Elimina de raíz la clase de bug "la IA devolvió la etiqueta de horario equivocada".
- `safety.ts` — dos chequeos determinísticos: ninguna comida puede auto-reportar `containsExcludedFood: true`, y la suma de calorías no puede desviarse más de ±40% del objetivo. **Limitación reconocida, no oculta**: sin chequeo de substring del nombre contra alérgenos (un nombre como "Pasta alfredo" no contiene la palabra "gluten" aunque la tenga) — la defensa real es la instrucción del prompt + la bandera auto-reportada; un chequeo ingrediente-por-ingrediente de verdad necesita `Recipe` (Épica 7).
- **`adjustDailyPlan` reusa el mismo esquema/capa de seguridad que `generateDailyPlan`**, con un prompt distinto (`nutritionAdjustmentV1.ts`): solo toca las comidas `pending`, nunca las `registered`; el presupuesto de calorías restante (`target - ya consumido`) reemplaza el objetivo diario completo como referencia de la capa de seguridad.
- **Cuota** (`functions/src/ai/quota.ts`): `planGeneration` (3/día free, 10/día premium — más cara que una pregunta de texto libre), `planAdjustment` y `mealAlternatives` (5/día free, 20/día premium — tocan menos comidas). `registerMeal`/`replaceMeal` no consumen cuota: son escrituras determinísticas sin IA.
- Persistencia: el documento escrito tiene EXACTAMENTE la forma de `NutritionPlan.toJson()` (`generatedAt` como string ISO-8601, no `Timestamp` nativo) — el repositorio Dart hace `NutritionPlan.fromJson(doc.data())` directo, sin mapper aparte.
- Reglas de Firestore: lectura permitida al dueño, **escritura del cliente bloqueada por completo** (`allow write: if false`) — todo el contenido del plan (generación, ajuste, registro, reemplazo) pasa por una Cloud Function con Admin SDK, nunca una escritura directa del cliente.

## D4 — sugerir y confirmar alternativas sin que el cliente reenvíe contenido de la IA

`suggestMealAlternatives` NO devuelve las 3 alternativas para que el cliente las reenvíe tal cual a `replaceMeal` (eso obligaría a confiar en un payload que el cliente pudo alterar). En cambio: las escribe en el campo efímero `candidates` de la comida en Firestore, y `replaceMeal` recibe solo un `candidateIndex` (0-2) — lee las candidatas guardadas server-side, aplica la elegida, y limpia el campo. El cliente nunca puede inyectar contenido de comida arbitrario; solo elige un índice entre lo que el servidor ya generó y validó.

Las alternativas que se auto-reportan inseguras (`containsExcludedFood: true`) se filtran de la lista en vez de fallar todo el pedido — si sobra al menos una alternativa segura, vale la pena mostrarla; si las 3 fallan, ahí sí se rechaza la solicitud completa.

## Pantalla D1 (Plan del día) y D2 (Plan semanal)

- **Plan requiere cuenta real, a diferencia de Home**: no existe ningún camino de invitado con datos locales — todas las Cloud Functions de esta feature y las reglas de Firestore exigen `request.auth`. `PlanPage` muestra un estado de invitado dedicado con un botón a `SignUpPage`.
- **`DayStrip`**: 5 días lun-vie de la semana actual (tal como especifica el diseño, sin fin de semana) — usa `intl`'s `DateFormat` para nombres de día localizados, sin agregar claves ARB nuevas para eso.
- **"Próxima comida" (tratamiento elevado, D1) es la primera comida `pending` en el orden del plan** — no se recalcula contra la hora actual del dispositivo, para que el tratamiento visual no cambie solo porque pasó un minuto con la pantalla abierta.
- **Toque en una comida**: registrada → se desmarca directo (un solo "deshacer" sin ambigüedad); pendiente → abre una hoja con 2 acciones ("Marcar como comido" / "Buscar otra opción", esta última abre D4).
- **"Ajustar mi plan con IA"**: fila nueva (estilo IA, `aiActionSurface`) que abre una hoja con un campo de texto libre — la superficie mínima honesta para exponer `adjustDailyPlan` sin inventar una UI de chat completa; no es parte del mock de Fase 4 (esa fase no cubre esta interacción).
- **D2 (semanal) incluye la tarjeta de sugerencia del mock** (resuelto 2026-09-29, antes deferida por necesitar detectar repeticiones entre días): `detectRepeatedMealsDay` (`features/plan/domain/repeated_meals_detector.dart`, función pura sin estado) recorre lunes→viernes y marca el primer día con ≥3 comidas cuyo nombre (normalizado) también aparece en el plan de otro día de la misma semana — sin llamada a IA ni nuevo Cloud Function, pura agregación sobre datos ya leídos por `weekPlansProvider` (mismo criterio que la lista de compra, Épica 10). El botón "Renovar el {día}" NO ejecuta nada a ciegas: navega a D1 con ese día seleccionado (mismo camino que tocar el día) y abre la hoja de "Ajustar mi plan con IA" ya existente (PLAN-004), precargada con un mensaje que nombra las comidas repetidas reales — el usuario sigue viendo y confirmando el texto exacto antes de gastar una llamada a la IA, reusando `adjustDailyPlan` tal cual sin tocar el backend. La tarjeta no usa `AppButtonVariant.aiAction` para el botón (su fondo es exactamente `aiActionSurface`, el mismo color que el fondo de esta tarjeta — quedaría invisible encima) ni inventa un hex nuevo para el "indigo sólido" que pide el mock (ese token de `AIMessage` sigue sin confirmarse, componente deferido): en su lugar invierte los dos tokens de IA ya validados (fondo `onAiAction`, texto `aiActionSurface`), documentado en el propio widget. Tocar un día cambia a la vista D1 con esa fecha seleccionada. El toggle "Semana"/"Día" alterna entre D1 y D2 dentro del mismo tab (sin ruta nueva), igual que en el diseño.
- **"Generar lista de compra"** sigue mostrando "Muy pronto" (Épica 10, no construida).

## Notas de arquitectura

- **Sin `freezed`**: aunque está en `pubspec.yaml`, ningún archivo del proyecto lo usa — se siguió el patrón ya establecido por `OnboardingAnswers` (clase inmutable, `toJson`/`fromJson`/`copyWith` escritos a mano) por consistencia.
- **`slotLabelKey` reusa el vocabulario de Onboarding** (`MealSlot.labelKey` de B6) — convención compartida a propósito, no un import cruzado entre features; mismo criterio que `homeDailyCalorieGoalProvider` (`documentation/home.md`).
- **`NutritionPlan.registeredCalories` es un getter derivado**, no un campo persistido — evita que un total guardado quede desincronizado (Instrucciones.md §23).
- **Un día sin plan generado no es un `NutritionPlan` con `meals: []` guardado** — es la ausencia del documento para esa fecha.
- **Un `AsyncNotifier` por acción del usuario** (generar, ajustar, registrar, alternativas), cada uno invalidando `planForDateProvider` al terminar con éxito — mismo patrón ya usado por `AuthController`/`OnboardingController`, aplicado consistentemente a las 4 acciones nuevas de esta épica.

## Reusado vs. nuevo

Reusado: el patrón de entidad inmutable de `OnboardingAnswers`, el vocabulario `labelKey` de `MealSlot`, el patrón de documento-por-día de `aiUsage`, toda la infraestructura de IA de la Épica 5 (`AI_MODELS`, `getOpenAiClient`, `consumeAiQuota`/`refundAiQuota`, el patrón de prompt versionado + esquema `zod` + capa de seguridad determinística), el perfil de Onboarding en Firestore, `mealSlotLabel` de `onboarding_catalog.dart`, el patrón `AsyncNotifier` de `AuthController`, `AppStateBlock`/`AppButton`/`QuickActionTile`/`SelectableChip`/`showAppBottomSheet` (extendidos donde hizo falta, nunca forkeados), `intl`. Nuevo: `features/plan` completo, `functions/src/plan/` (todo el subárbol), `MealCard` (`core/widgets`), `mapFirebaseFunctionsException` (`core/errors`), `dateKey` (`core/utils`).

## Known gaps (señalados, no decididos en silencio)

- **Capa de seguridad sin chequeo ingrediente-por-ingrediente** — ver arriba; necesita `Recipe` (Épica 7).
- **Sin lista de compra** — cubierto por la Épica 10 (v1 scope), ver `documentation/grocery_list.md`.
- **Backend desplegado a producción** (2026-09-29) con `enforceAppCheck: true` en las 9 funciones callable (Épica 15, 2026-09-30) — ver `documentation/security_review.md`.
- **Sin tests** — diferido a la Épica 16 por pedido explícito del usuario.
