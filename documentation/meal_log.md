# Comidas fuera del plan (Épica 19 · LOG-101, LOG-102, LOG-105)

Construido el 2026-10-26. Hasta ahora solo las comidas del plan (`PlannedMeal`, con horario fijo) podían contar en el día. Una foto analizada se guardaba pero nadie la leía, "Registrar sin foto" decía "muy pronto" y Home no tenía forma de saber que el usuario comió algo imprevisto. Este trabajo agrega ese concepto: la **comida extra**.

## Decisiones (delegadas a Claude por el usuario, 2026-10-25)

- **Cuenta para la meta del día.** Lo libre = meta − (comidas del plan registradas + comidas extra). Un tracker que ignora lo que de verdad se comió daría una foto falsa del día.
- **Se puede borrar siempre y editar solo la porción.** Los macros se escalan desde los valores base. Qué se comió no se edita: se borra y se registra de nuevo, para que una estimación de la IA no termine mezclada con cifras escritas a mano.
- Toda escritura pasa por Cloud Functions, nunca por el cliente directo.

## Datos

`users/{uid}/extraMeals/{id}`. El cliente solo lee; `firestore.rules` prohíbe escribir (con test de reglas):

| Campo | Qué es |
|---|---|
| `date` | Día local del usuario, YYYY-MM-DD (igual que `nutritionPlans`) |
| `name` | Lo que se comió |
| `source` | `manual` o `photo` (`voice`/`barcode` llegarán con LOG-103/104) |
| `base` | `{calories, proteinGrams, carbsGrams?, fatGrams?}` de la porción 1 |
| `portion` | 0,25–5, en pasos de 0,25 |
| `allergenWarning` | Aviso, no rechazo: la comida ya se comió |
| `analysisId` | Solo en las de foto |
| `createdAt` | ISO 8601 |

Lo que cuenta (`calories`, `proteinGrams`…) se deriva de `base × portion`; no se guarda escalado, así que cambiar la porción varias veces no acumula redondeos. La subcolección está en la lista de `deleteAccount`.

## Backend (`functions/src/mealLog/`)

- `logExtraMeal` — `{date, source, …}`.
  - `manual`: nombre (2–80) y kcal (obligatorias, ≤5000); proteína (0 por defecto), carbos y grasas opcionales. El aviso de alérgeno sale de escanear el nombre con `ALLERGEN_KEYWORDS` (mismo criterio que `recipes/safety.ts`).
  - `photo`: recibe solo `analysisId`. Las cifras y el aviso se copian del documento `foodAnalyses` ya guardado, así que el cliente no puede inflarlas ni bajarlas. El id `photo_{analysisId}` lo hace idempotente: dos toques no registran dos comidas.
  - `date` debe estar entre hoy−2 y hoy+1 (UTC): el servidor no sabe la zona horaria del usuario.
  - Tope de 30 por día, en una transacción (acota documentos, no es una regla nutricional).
  - Sin IA, así que no consume cuota.
- `editExtraMeal` — `{mealId, portion}` o `{mealId, delete: true}`. Borrar algo que ya no existe no es un error.
- Validación en `input.ts`, con tests en `functions/test/mealLogInput.test.ts`.

**Desplegado por el usuario el 2026-10-26** (`firebase deploy --only functions,firestore:rules`).

## Cliente (`lib/features/meal_log/`)

- `ExtraMeal` (entidad) y `DayIntake` + `dayIntake(plan, extras)`: la única suma de "lo comido", usada por Home y por D1 para que nunca se contradigan.
- `FirebaseExtraMealRepository`: lee por igualdad de `date` (sin `orderBy`, sin índice compuesto; ordena en el cliente) y escribe con las dos funciones.
- `extraMealsForDateProvider` (familia por fecha) y `extraMealControllerProvider` (registrar manual o desde foto, cambiar porción, borrar). Cada operación invalida toda la familia.
- **`LogMealPage`** (`/log-meal`): "Registrar sin foto" de la hoja de cámara. El canvas no tiene mock de este formulario (Fase 5 solo nombra la salida "Escribir qué comí" de E3), así que se armó con `AppTextField`/`AppButton`. Solo las kcal son obligatorias. Un invitado va a crear cuenta, igual que con las fotos.
- **"Registrar comida"** bajo el resultado del análisis de foto (canvas E2).
- **`ExtraMealsSection`** en D1: "Fuera del plan", entre las comidas del plan y las acciones. También aparece en un día sin plan. Usa `MealCard` con tratamiento de registrada, porque ya se comió. Tocar una abre una hoja (uso aprobado: "ajustar una cantidad") con la porción −/+ y las cifras recalculadas en vivo, "Guardar" y "Eliminar" con diálogo de confirmación.
- **Home**: el anillo y las cifras de kcal, proteína y comidas incluyen las comidas extra. Sin plan hoy (C3), el anillo se enciende si ya hay alguna.
- **D1**: las kcal del encabezado incluyen las extra; el contador "x de y comidas registradas" sigue siendo solo del plan.
- Analytics: `extra_meal_logged` (`source`).
- Tests: `test/features/meal_log/extra_meal_test.dart`.

## Pendiente

- Probar en un dispositivo.
- ~~Racha~~ y ~~C2~~: hechos el 2026-10-26 (ver `documentation/home.md`). `adjustDailyPlan` también descuenta las comidas extra del presupuesto del día.
- E3 ("Escribir qué comí") no existe como pantalla. Cuando exista, su salida debe abrir `LogMealPage`.
- LOG-103 (voz) y LOG-104 (código de barras) alimentan este mismo modelo.
