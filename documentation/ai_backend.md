# Épica 5 — Backend de IA (Cloud Functions)

## Qué hace

Proyecto Node/TypeScript en `functions/` (Firebase Cloud Functions v2) que expone OpenAI de forma segura a la app. El Flutter client nunca llama a OpenAI directamente ni conoce la API key — llama a una función `onCall` autenticada, que valida, arma el contexto, llama a OpenAI, valida la salida y recién entonces responde.

**Tarea 5.1 (completada): primera función real, `askNutritionAssistant`** — responde preguntas de nutrición en texto libre. Es el primer caso vertical porque, de las capacidades del asistente listadas en `Instrucciones.md` §5, es la única que no depende de modelos de datos de Épicas 6/7/8 (que todavía no existen).

**Tarea 5.2 (completada): cuota diaria de uso de IA, server-side**, ver más abajo.

**Tarea 5.3 (completada): abstracción `AIService` del lado de Flutter**, ver más abajo. Con esto, la Épica 5 queda completa — las 3 tareas de `TASKS.md` están hechas. Nada en la UI la consume todavía (el tab "IA" sigue siendo `ComingSoonPage`); eso es una decisión de producto/UI deliberadamente fuera del alcance de esta épica, ver "Decisión de alcance" más abajo.

## Por qué `askNutritionAssistant` sigue sin ser "a prueba de abuso" al 100%

`request.auth` (Firebase Auth) y ahora la cuota diaria (`consumeAiQuota`) protegen la función — cumple "no permitir consumo anónimo/ilimitado de OpenAI" (`Instrucciones.md` §28-29). Lo que falta es `enforceAppCheck: true` — se difiere a la Épica 15 porque el cliente Flutter todavía no integra `firebase_app_check` (ya está en `pubspec.yaml` pero no inicializado); activarlo antes rechazaría toda llamada real. Está comentado directamente en `askNutritionAssistant.ts`.

## Cuota de uso de IA (Tarea 5.2)

- `functions/src/ai/quota.ts` — `consumeAiQuota(userId, isPremium, feature)`: transacción atómica de Firestore que lee-y-consume un cupo diario antes de llamar a OpenAI. Si el usuario ya alcanzó su límite, lanza `HttpsError('resource-exhausted', ...)` **antes** de gastar ninguna llamada a OpenAI.
- Almacenamiento: `users/{uid}/aiUsage/{yyyy-mm-dd}`, un campo entero plano por feature (hoy solo `nutritionQa`). Deliberadamente NO un mapa anidado tipo `{ counts: { nutritionQa: n } }` — el `set(..., {merge:true})` de Firestore no garantiza un merge recursivo confiable de mapas anidados entre versiones del SDK (verificado antes de implementar, no supuesto); un campo plano de nivel superior sí tiene semántica de merge bien definida.
- Límites: `DAILY_LIMITS` en `quota.ts` — `nutritionQa: { free: 10, premium: 50 }`. **Números placeholder de MVP** — `Instrucciones.md` no fija cifras exactas (§28 solo exige que existan y se apliquen server-side), así que estos son un punto de partida razonable, centralizado en un solo lugar para poder ajustarlo sin tocar la lógica de la función.
- `isPremium`: se lee de `users/{uid}.subscription.isPremium`, campo que **todavía no escribe nadie** (Épica 13 — Suscripciones — no existe). Por eso hoy todo usuario es `free` por defecto, lo cual es seguro (no hay ningún camino para que un cliente falsifique el campo porque nada lo escribe aún). Cuando la Épica 13 valide compras server-side, solo necesita empezar a escribir ese campo — la cuota ya está lista para usarlo.
- `refundAiQuota`: si la llamada a OpenAI falla después de consumir el cupo, se devuelve ese cupo (best-effort, no transaccional con el consumo original) para que un error del proveedor no le cueste al usuario una consulta real.
- `firestore.rules` deja `users/{userId}/aiUsage/{date}` **sin match explícito** a propósito — Firestore deniega por defecto lo que no está matcheado, así que el cliente nunca puede leer ni escribir directamente su contador. Las Cloud Functions lo tocan vía Admin SDK (que ignora las reglas); el cliente recibe `remainingToday` como parte de la respuesta de `askNutritionAssistant`, no leyendo Firestore directamente.
- Reusable para el resto de la épica: cualquier función futura (Épicas 6-9) que llame a OpenAI puede reusar `consumeAiQuota`/`refundAiQuota` agregando su propia entrada en `DAILY_LIMITS` con un nuevo nombre de `feature` — no hace falta rediseñar nada.

## `AIService` del lado de Flutter (Tarea 5.3)

- `lib/core/services/ai/ai_service.dart` — abstracción `AIService` (Instrucciones.md §77: "Create an abstraction that allows model changes later... Model selection should happen in a configurable layer"). Hoy un solo método, `askNutritionQuestion(String question)`, porque es la única función de IA desplegada; cada Cloud Function de IA nueva (Épicas 6-9) agrega su propio método aquí, no una interfaz separada.
- `lib/core/services/ai/nutrition_assistant_answer.dart` — entidad de dominio puro (`answer`, `recommendsProfessionalConsult`, `safetyFallbackApplied`, `remainingToday`), sin nada de `cloud_functions`.
- `lib/core/services/ai/firebase_ai_service.dart` — `FirebaseAiService implements AIService`: única frontera del cliente que conoce el nombre de la función (`askNutritionAssistant`) y la forma cruda de su respuesta. Mapea `FirebaseFunctionsException.code` a los `Failure` ya existentes en `core/errors` (`unauthenticated`→`AuthFailure`, `invalid-argument`→`ValidationFailure`, `resource-exhausted`→`AiQuotaExceededFailure` — nuevo, agregado en esta tarea —, `unavailable`/`deadline-exceeded`→`NetworkFailure`, cualquier otro→`ServerFailure`); una respuesta con forma inesperada se traduce a `AiValidationFailure` (ya existía, pensado justo para esto desde la Épica 1). Expone `aiServiceProvider` (Riverpod).
- `lib/core/services/firebase_instances.dart` — nuevo `firebaseFunctionsProvider` (instancia cruda, región por defecto `us-central1`, la misma que usa la función desplegada).
- No se creó una capa `data source` + `repository` separada (a diferencia de `authentication`/`onboarding`): `AIService` ya cumple ese rol con una sola llamada real y sin necesidad de componer varias fuentes — separar más sería una capa sin propósito. Sí sigue el mismo patrón de contrato abstracto + implementación concreta que el resto del proyecto, por la razón que pide Instrucciones.md §77 (poder cambiar de implementación/modelo sin tocar quien lo consume).

### Decisión de alcance: sin UI todavía

`TASKS.md` (Épica 5) solo pedía la abstracción del cliente, no una pantalla — el tab "IA" del shell principal (Épica 4) sigue siendo `ComingSoonPage`. Construir un chat mínimo ahora habría sido alcance nuevo no pedido, y sin un caso de uso real definido (¿pantalla de chat suelta? ¿integrado a Plan/Épica 6?) habría significado inventar una UI para poder "probar algo", el mismo patrón que ya se evitó a propósito en Onboarding B8/B9 y en los estados poblados de Home. `AIService` queda listo y compilando (`flutter analyze` limpio) para que la primera pantalla real que lo necesite (una futura decisión de producto) lo consuma directamente.

## Archivos clave

- `functions/package.json` — dependencias: `firebase-functions`, `firebase-admin`, `openai`, `zod`. Runtime Node 22.
- `functions/src/index.ts` — inicializa `firebase-admin` y exporta las funciones.
- `functions/src/config/openai.ts` — `defineSecret("OPENAI_API_KEY")` (Secret Manager, nunca en código/`.env`), cliente OpenAI perezoso, y `AI_MODELS` (routing de modelos centralizado, hoy solo `nutritionQa: "gpt-5.6-luna"` — el modelo de texto más económico del catálogo actual de OpenAI, confirmado contra la documentación oficial vigente el 2026-09-19, no memoria desactualizada).
- `functions/src/ai/prompts/nutritionAssistantV1.ts` — prompt de sistema centralizado y versionado (`nutrition_assistant_v1`); inyecta `goal`/`avoidFoods` del usuario y las reglas de seguridad médica (no diagnosticar, no recomendar cambios de medicación, etc.).
- `functions/src/ai/schema.ts` — esquema `zod` de la salida estructurada (`answer`, `mentionsRestrictedFood`, `recommendsProfessionalConsult`).
- `functions/src/ai/safety.ts` — capa de seguridad determinística que corre DESPUÉS de la validación de esquema: revisa la bandera que reporta el propio modelo Y además busca directamente los `avoidFoods` del usuario en el texto de la respuesta (defensa en profundidad, no confiar solo en el LLM), y un patrón de regex para instrucciones de medicación. Si algo falla, se devuelve `SAFETY_FALLBACK_ANSWER` en vez de la respuesta cruda.
- `functions/src/ai/quota.ts` — `consumeAiQuota`/`refundAiQuota`, ver "Cuota de uso de IA" arriba.
- `functions/src/ai/askNutritionAssistant.ts` — la función `onCall`: exige auth, valida longitud de la pregunta (máx. 500 caracteres), lee `goal`/`avoidFoods`/`isPremium` desde Firestore (nunca del cliente), consume cuota, llama a `openai.responses.parse` (Responses API, salida estructurada vía `zodTextFormat`), corre la capa de seguridad, y devuelve `{ answer, recommendsProfessionalConsult, safetyFallbackApplied, remainingToday }`.
- `firebase.json` — nuevo bloque `functions` (source `functions`, build `npm run build` como predeploy).
- `firestore.rules` — comentario explícito documentando que `users/{userId}/aiUsage/{date}` queda sin match a propósito (denegado por defecto para el cliente).

## Notas de arquitectura

- **Responses API, no Chat Completions** — es la API actualmente recomendada por OpenAI para salida estructurada (`openai.responses.parse` + `zodTextFormat`), confirmado contra la documentación oficial vigente al implementar esta tarea.
- **Minimización de datos** (`Instrucciones.md` §35): la función solo lee y envía `goal` + `avoidFoods` del perfil, no el documento completo de `users/{uid}` (que también tiene edad, peso, horarios de comida, etc. — irrelevantes para esta pregunta).
- **Perfil leído server-side, nunca confiado del cliente** (`Instrucciones.md` §70): el `request.data` del cliente solo trae `question`; `goal`/`avoidFoods` se leen de Firestore usando `request.auth.uid` verificado por Firebase, no un campo que el cliente pueda falsificar.
- **CORS**: no requiere configuración manual — las funciones `onCall` (a diferencia de `onRequest`) manejan el preflight/CORS automáticamente vía el SDK cliente de Firebase.
- **Prompt versionado, no embebido en Flutter** (`Instrucciones.md` §76): vive en `functions/src/ai/prompts/nutritionAssistantV1.ts`; un cambio de comportamiento debería crear `nutritionAssistantV2.ts`, no editar este en silencio.

## Cómo desplegar / probar (para el usuario, no ejecutado por Claude)

1. Configurar la API key una sola vez (no se comparte en el chat): `firebase functions:secrets:set OPENAI_API_KEY`.
2. Para el emulador local, Firebase la lee de `functions/.secret.local` (gitignored) — se puede generar corriendo `firebase functions:secrets:access OPENAI_API_KEY` o creándolo a mano con el mismo valor.
3. `npm --prefix functions run build` ya corre como `predeploy`; `firebase deploy --only functions` despliega. No ejecutado en esta sesión — requiere que el usuario confirme (acción con costo/efecto en un proyecto compartido).

## Reusado vs. nuevo

Reusado: proyecto Firebase `nutritionapp-eee08` ya conectado, esquema `users/{uid}.onboarding` de la Épica 3, `cloud_functions`/`firebase_app_check` (declarados en `pubspec.yaml` desde la Épica 1; `firebase_app_check` activado en la Épica 15, ver `documentation/security_review.md`), el patrón contrato-abstracto + implementación de `authentication`/`onboarding`, y los tipos `Failure`/`AppException` de `core/errors` (`AiValidationFailure` ya existía, pensado para esto desde la Épica 1). Nuevo: todo `functions/` (subproyecto Node/TS independiente del árbol Dart) — es la primera vez que el repo tiene código fuera de Flutter; `lib/core/services/ai/` (`AIService`, `FirebaseAiService`, `NutritionAssistantAnswer`); `AiQuotaExceededFailure` en `core/errors/failure.dart`.

## Known gaps (señalados, no decididos en silencio)

- **Límites de `DAILY_LIMITS` son placeholders de producto** — 10/50 por día no vienen de `Instrucciones.md`; ajustar libremente cuando haya datos reales de uso/costo.
- **Sin tests** — diferido a la Épica 16 por pedido explícito del usuario.

Resueltos desde que se escribió esta nota: la UI sí usa `AIService` (`AiChatPage`, ver `documentation/ai_assistant.md`, AI5-004); `enforceAppCheck: true` está activo en las 9 funciones callable (Épica 15, 2026-09-30); el backend está desplegado a producción (2026-09-29, secret `OPENAI_API_KEY` configurado) — ver `documentation/security_review.md`.
