# Épica 3 — Onboarding

## Qué hace

Flujo conversacional de 7 pasos (B1-B7) que recoge objetivo, datos personales, nivel de actividad, alimentos que le gustan al usuario, alergias/intolerancias, ritmo de comidas y preferencias de cocina/presupuesto. Se activa desde Welcome ("Empezar"), vive en una sola ruta (`/onboarding`) con navegación interna entre pasos, y termina llevando a `SignUpPage(hasPendingPlan: true)`.

**Decisión de producto confirmada con el usuario (2026-09-12): el registro ocurre DESPUÉS del onboarding**, como propone el diseño (B9 → A4). Por eso las respuestas se guardan localmente mientras se completan (no hay `userId` todavía) y se migran a Firestore recién cuando el usuario se registra o inicia sesión.

**Estado: B1-B7 construidos y confirmados funcionando de punta a punta** (2026-09-12) — el usuario completó el flujo real (Welcome → Onboarding → registro) y verificó en la consola de Firebase que `users/{uid}` queda con el borrador completo (`isComplete: true`, todas las respuestas). `firestore.rules` desplegadas (`firebase deploy --only firestore:rules`) — esa misma corrida creó la base de datos de Firestore del proyecto (no existía todavía). B8 (generando) y B9 (plan listo) del diseño NO están implementados — dependen de generación real de un plan por IA (Épica 5/6, no construida); ver `documentation/design_screens_onboarding.md`.

## Archivos clave

- `lib/features/onboarding/domain/entities/onboarding_answers.dart` — `OnboardingAnswers` (todo opcional hasta completar B7) + enums (`NutritionGoal`, `Sex`, `ActivityLevel`, `CookingTimePreference`, `CookingSkillLevel`, `BudgetLevel`, `UnitSystem`) + `MealSlot` + `defaultMealSlotsFor(count)`.
- `lib/features/onboarding/domain/calorie_estimate.dart` — estimación de calorías (Mifflin-St Jeor + factor de actividad), matemática determinista, NO una llamada a IA — usada solo como feedback en vivo en B3.
- `lib/features/onboarding/domain/repositories/onboarding_repository.dart` — contrato: `saveDraft`/`loadDraft`/`clearDraft` (siempre local) + `migrateDraftToProfile(userId)` (el único método que toca Firestore).
- `lib/features/onboarding/data/` — `OnboardingLocalDataSource` (única clase que importa `shared_preferences`, guarda un blob JSON), `OnboardingRemoteDataSource` (única clase que escribe en Firestore, `users/{userId}` con `merge: true`), `OnboardingRepositoryImpl`.
- `lib/features/onboarding/presentation/providers/onboarding_providers.dart` — `onboardingControllerProvider` (`Notifier<OnboardingAnswers>`, un `setXxx` por campo + `complete()`), `onboardingStepIndexProvider` (navegación entre pasos, separado de las respuestas).
- `lib/features/onboarding/presentation/onboarding_catalog.dart` — IDs estables + lookup de labels localizados para el catálogo de alimentos (B4) y alérgenos (B5).
- `lib/features/onboarding/presentation/pages/onboarding_page.dart` — shell del wizard: `StepHeader` + el paso actual, navegación interna vía `onboardingStepIndexProvider`.
- `lib/features/onboarding/presentation/pages/steps/` — un archivo por paso (`goal_step.dart`, `personal_data_step.dart`, `activity_level_step.dart`, `liked_foods_step.dart`, `allergies_step.dart`, `meal_rhythm_step.dart`, `cooking_budget_step.dart`).
- `lib/features/onboarding/presentation/widgets/` — `StepHeader`, `OnboardingOptionCard` (tarjeta de opción única con/sin foto, B1/B3), `WheelValueField` + `showIntWheelPicker`/`showDoubleWheelPicker` (selector de rueda para B2/B6, sin dependencias nuevas — usa `CupertinoPicker` del SDK).
- `lib/core/widgets/selectable_chip.dart` — componente 03/10 de las fichas base (`SelectableChip`), diferido desde la Épica 1 hasta esta épica; variante `negative` para el caso de exclusión de B5.
- `lib/core/router/app_router.dart` — ruta `/onboarding`; `ref.listen(authStateChangesProvider, ...)` dispara `migrateDraftToProfile` al pasar de "sin sesión" a "con sesión" (login o signup, sin importar cuál).
- `firestore.rules` — reglas mínimas (`users/{userId}` == propio usuario) para la primera escritura real a Firestore del proyecto. Desplegadas 2026-09-12 (`firebase deploy --only firestore:rules`, corrido por el usuario — esa corrida también creó la base de datos de Firestore, que no existía).

Diseño: `documentation/design_screens_onboarding.md`.

## Notas de arquitectura

- **Persistencia local antes que Firestore**: dado que el registro es posterior al onboarding, no existe `userId` mientras se completan B1-B7. `shared_preferences` (única dependencia nueva de esta épica, justificada en `pubspec.yaml`) guarda un blob JSON en cada cambio de respuesta — perder un guardado a mitad de un paso no es crítico (el usuario puede repetirlo).
- **Migración centralizada en el router**: `migrateDraftToProfile` se llama desde `app_router.dart`'s `ref.listen(authStateChangesProvider, ...)`, no desde `AuthController` ni desde `SignUpPage`. Esto evita que la feature `authentication` importe `onboarding` (o viceversa) — el router es la capa de composición que ya conoce ambas features (mismo criterio usado para `HomePlaceholderPage.onSignOut`).
- **`hasPendingPlan` ya existía**: `SignUpPage` construyó este parámetro en la Épica 2 anticipando exactamente este flujo (mostrar el banner "tu plan ya está calculado"). El router ahora lo alimenta de verdad desde `onboardingControllerProvider`.
- **Auto-avance en selección única pura**: B1 y B3 avanzan solos 180ms después de tocar una opción (regla explícita del diseño). B6/B7, aunque tienen controles de selección única (comidas/día, tiempo de cocina), son pasos compuestos con más de una pregunta — se mantienen con botón "Continuar" explícito.
- **Selector de rueda sin dependencias nuevas**: `WheelValueField` usa `CupertinoPicker` (parte del SDK de Flutter, no un paquete nuevo) para Edad/Altura/Peso (B2) y horarios de comida (B6), tal como especifica el diseño ("selector de rueda, no el teclado numérico").

## Reusado vs. nuevo

Reusado: `AppButton`, tokens de tema, `context.l10n`. Nuevo en `core/widgets/` (parte de las 10 fichas base, no específico de esta feature): `SelectableChip`. Nuevo y específico de este flujo (justificado — ningún otro flujo por pasos existe todavía): `StepHeader`, `OnboardingOptionCard`, `WheelValueField`.

## Known gaps (señalados, no decididos en silencio)

- **B8/B9 no implementados** — dependen de la generación real de un plan por IA (Épica 5/6). Completar B7 hoy lleva directo a `SignUpPage(hasPendingPlan: true)`, saltándose el estado de carga y la revelación del plan que muestra el diseño. Se implementará cuando exista el backend de IA.
- **Alergia vs. intolerancia no distinguidas por severidad** — el mock del diseño (B5) no muestra un control por ítem para marcar cuál es cuál; se guarda todo en una sola lista `avoidFoods` de exclusión. Revisar si el motor de recetas (Épica 5/6/7) necesita la distinción real.
- **Horarios por defecto para 3/5/6 comidas/día son una interpolación propia** — el diseño solo especifica el caso de 4 comidas. Ver `defaultMealSlotsFor` en `onboarding_answers.dart`.
- **Presupuesto semanal es un nivel discreto (4 posiciones), no un monto libre** — el diseño muestra un slider con una sola etiqueta+rango por posición, no un campo de moneda; no hay requisito de localización de precio en `Instrucciones.md`.
- **Conversión a Imperial es solo de visualización** — el valor guardado siempre es métrico (cm/kg); no hay known issue, pero si se necesitara guardar la preferencia de unidad real del usuario para mostrarla en otras pantallas, ya existe `answers.unitSystem`.
- **Catálogo de alimentos/alérgenos es una lista corta y curada en código** (`onboarding_catalog.dart`), no respaldada por Firestore — suficiente para el MVP, crecerá cuando exista un catálogo real (fuera del alcance de esta épica).
- **Sin tests** — diferido a la Épica 16 por pedido explícito del usuario.
