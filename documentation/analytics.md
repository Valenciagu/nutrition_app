# Épica 14 — Analytics & Observability

Estado: **completa** (2026-09-21).

## Alcance (Instrucciones.md §48)

> Use appropriate: Crashlytics, Analytics, Logging. Do not log sensitive information. Analytics events should be centralized. Avoid hard-coded event names throughout the application.

Sin una sección numerada propia en `Instrucciones.md` más allá de §48 (Observability) — a diferencia de la mayoría de épicas anteriores, no hay un mock de diseño ni una feature de producto nueva aquí: es instrumentación transversal sobre features que ya existen. `firebase_analytics`/`firebase_crashlytics` ya eran dependencias declaradas desde la Épica 1 (`pubspec.yaml`) pero nunca se habían inicializado ni usado — esta épica las conecta de verdad.

## Crashlytics

`main.dart` → `_setupCrashlytics()`: `FlutterError.onError` y `PlatformDispatcher.instance.onError` reenvían a `FirebaseCrashlytics.instance`. `setCrashlyticsCollectionEnabled(!kDebugMode)` — desactivado en desarrollo (los crashes de la propia sesión de desarrollo no deben ensuciar el dashboard de un proyecto de Firebase compartido con el usuario), activo solo en builds release. Sin implementación web (paquete Android/iOS/macOS únicamente, igual que `flutter_local_notifications` de la Épica 12) — `_setupCrashlytics()` es no-op ahí vía `kIsWeb`. El plugin de Gradle (`com.google.firebase.crashlytics`) ya estaba aplicado en `android/` desde `flutterfire configure` (FOUND-009); no hizo falta tocar nada nativo.

## Analytics — eventos centralizados

`AnalyticsService` (`core/services/analytics/analytics_service.dart`) es un contrato con **un método tipado por evento**, no un `logEvent(String name, Map params)` genérico — así el nombre y la forma de cada evento viven en un solo sitio (`FirebaseAnalyticsService`, la única clase que conoce `firebase_analytics`), y un typo en un nombre de evento es un error de compilación, no un bug silencioso en producción descubierto semanas después en la consola de Firebase. Los nombres crudos viven en `core/constants/analytics_events.dart` (mismo patrón que `RoutePaths`/`FirestoreCollections`). `sign_up`/`login` usan los eventos recomendados de GA4 (`FirebaseAnalytics.logSignUp`/`.logLogin`) en vez de eventos propios, para aprovechar los reportes de embudo que Firebase ya construye para ellos.

Eventos instrumentados (11), cada uno en el punto de éxito real de su acción, no en el intento:

| Evento | Disparado en |
|---|---|
| `sign_up` / `login` | `AuthController.signUp`/`.signIn` (Épica 2) |
| `sign_out` | `AuthController.signOut` — también se dispara tras eliminar la cuenta (Épica 11), es un hecho real, no un error |
| `account_deleted` | `DeleteAccountController.deleteAccount` (Épica 11) |
| `onboarding_completed` | El `ref.listen(authStateChangesProvider)` de `app_router.dart`, pero SOLO si `migrateDraftToProfile` de verdad migró un borrador — antes devolvía `void`, ahora `bool`, precisamente para no reportar este evento en un login normal sin borrador pendiente |
| `plan_generated` / `plan_adjusted` | `GeneratePlanController`/`AdjustPlanController` (Épica 6) |
| `meal_registered` | `MealRegistrationController.setRegistered` — solo cuando `registered: true` (representa "el usuario comió esto", no cada toggle de deshacer) |
| `meal_replaced` | `MealAlternativesController.confirmReplacement` (D4, Épica 6) |
| `food_photo_analyzed` | `FoodAnalysisController.analyze` (Épica 8), con `is_food_photo: bool` como único parámetro |
| `reminders_enabled` | `NotificationSettingsSaveController.save` (Épica 12), solo si quedó activo Y con permiso concedido, con `active_type_count: int` |

**Deliberadamente NO instrumentado**: generación de recetas (`generateRecipe`, Épica 7) — el cliente no distingue si el backend generó una receta nueva o devolvió una ya cacheada (`getOrGenerateRecipe` es idempotente), así que un evento `recipe_generated` en cada apertura de D3 habría contado "vistas" como "generaciones", exactamente el tipo de dato fabricado que este proyecto evita en todos lados; instrumentarlo bien necesitaría que el backend devolviera esa distinción, fuera de alcance de esta tarea. Lista de compra (Épica 10): no hay una acción discreta de "generar" (es una lectura reactiva que se recalcula sola), y el screen-view ya cubriría "el usuario abrió la lista" si se construyera tracking de pantallas (ver gap abajo).

## Privacidad (Instrucciones.md §20, §48)

Ningún parámetro de evento lleva texto libre, nombre, email, ni contenido generado por la IA — solo booleanos/enteros ya no-sensibles (`is_food_photo`, `active_type_count`). `AnalyticsService` como contrato hace estructuralmente imposible que una feature futura mande un string arbitrario sin pasar por un método explícito y revisado aquí.

## Screen-view automático (resuelto 2026-09-21)

`firebase_analytics` trae `FirebaseAnalyticsObserver`, un `NavigatorObserver` que reporta automáticamente cada pantalla vista — depende de `RouteSettings.name`, que GoRouter solo puebla si cada `GoRoute` define `name:`. Originalmente descartado para v1 (ninguna ruta tenía `name:` y no había forma de confirmar en este entorno qué nombre terminaría reportando). Resuelto: cada `GoRoute` de `app_router.dart` ahora tiene un `name:` explícito y estable (`home`, `plan`, `recipe_detail`, `cooking_mode`, `grocery_list`, `ai_chat`, `profile`, `profile_edit_goal`, `profile_edit_preferences`, `profile_privacy`, `profile_notifications`, más las públicas `splash`/`welcome`/`onboarding`/`food_analysis`/`login`/`sign_up`/`forgot_password`), y `GoRouter.observers` incluye `FirebaseAnalyticsObserver(analytics: ref.read(firebaseAnalyticsProvider))`. El nombre reportado a Firebase sale directo de ese `name:`, no de un valor autogenerado — ya no queda el riesgo original de mandar nombres sin sentido. Pendiente: no verificado manualmente contra el DebugView de Firebase Analytics en un dispositivo real (sigue sin estar disponible en este entorno) — `flutter analyze`/`flutter build web --debug` solo confirman que compila y que el observer queda conectado, no que la consola muestra exactamente lo esperado.

## Validación

`flutter analyze` limpio. `flutter build web --debug` limpio — `firebase_crashlytics` no tiene soporte web (no-op vía `kIsWeb`, mismo patrón que `NotificationService`, Épica 12); `firebase_analytics` (incluyendo `FirebaseAnalyticsObserver`) sí lo tiene y se usa sin guard alguno, confirmado porque el build web compila limpio con el observer activo. Sin cambios en `functions/` — esta épica es enteramente del lado del cliente.
