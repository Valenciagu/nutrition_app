# Épica 4 — Home

## Qué hace

Shell principal de la app: 4 tabs (Home, Plan, IA, Perfil) + botón de cámara central, usando `StatefulShellRoute` de GoRouter para que cada tab mantenga su propia pila de navegación. Home muestra el estado "primer día" (C3 del diseño): saludo, anillo de calorías apagado con la meta calculada en el Onboarding, y 3 accesos rápidos. Plan e IA son placeholders (`ComingSoonPage`) hasta las Épicas 6 y 5; Perfil aloja temporalmente el botón de cerrar sesión hasta la Épica 11.

**Decisión de navegación confirmada con el usuario (2026-09-12): 4 tabs + cámara central**, como propone el diseño (Home · Plan · [cámara] · IA · Perfil), en vez de los 5 tabs del brief original. Progreso ya no es tab — se abrirá desde el anillo de Home cuando exista (Épica 6).

**Estado: compilando limpio** (`flutter analyze`, `flutter build web --debug`). No probado manualmente todavía por el usuario.

## Por qué solo se construyó el estado "empty" de Home

El diseño (`documentation/design_screens_home.md`) especifica 6 estados. De esos, C1 (poblado, con la comida siguiente real) y C2 (con sugerencia de la IA tras una comida imprevista) necesitan un plan diario y seguimiento de macros reales — eso es la Épica 6, que no existe. Construirlos ahora significaría inventar datos (un "540 kcal, 42g proteína" que no sale de ningún lado real), lo cual violaría la misma regla que ya aplicamos al diferir B8/B9 del Onboarding. Como ningún usuario de la app tiene todavía seguimiento diario real, el estado "primer día" (C3) ES el estado real de Home hoy — no es una limitación de esta épica, es honesto con lo que existe.

## Archivos clave

- `lib/core/router/main_shell.dart` — `MainShell`, envuelve el `StatefulNavigationShell` de GoRouter con `BottomNavigation` + el botón de cámara.
- `lib/core/router/app_router.dart` — `StatefulShellRoute.indexedStack` con 4 `StatefulShellBranch` (uno por tab); reemplaza la única `GoRoute` de `root` que apuntaba a `HomePlaceholderPage` (borrado).
- `lib/core/widgets/bottom_navigation.dart` — componente 09/10 de las fichas base (`BottomNavigation`), con el botón de cámara central integrado.
- `lib/core/widgets/progress_ring.dart` — componente 05/10 (`ProgressRing`), con modo `dimmed` para el anillo "apagado" de C3.
- `lib/core/widgets/quick_action_tile.dart` — uno de los dos componentes nuevos que propone Fase 3 (fila icono+título+subtítulo+chevron). Solo se construyó la variante de fila (la usada en C3); la variante de grid 2x2 (C1) se difiere junto con `MealCard`/`MacroBar`/`AISuggestionCard` a la Épica 6.
- `lib/core/widgets/coming_soon_page.dart` — placeholder genérico para Plan/IA. Reemplaza a `home_placeholder_page.dart` (Épica 1, borrado).
- `lib/core/widgets/profile_placeholder_page.dart` — placeholder de Perfil, aloja "Cerrar sesión" (antes vivía en el placeholder de Home).
- `lib/features/home/presentation/providers/home_providers.dart` — `homeDailyCalorieGoalProvider`: calcula la meta de kcal reusando `estimateDailyCalories` de Onboarding, leyendo de Firestore (con sesión) o del `onboardingControllerProvider` en memoria (invitado).
- `lib/features/home/presentation/pages/home_page.dart` — `HomePage` (estado C3) + `_HomeSkeleton` (estado C4).
- `lib/features/home/presentation/widgets/camera_action_sheet.dart` — `showCameraActionSheet`, la hoja de acción C5 (3 opciones + Cancelar).
- `lib/core/constants/route_paths.dart` — `plan`, `ai`, `profile` agregados; `guestAccessibleRoutes` ahora incluye las 4 tabs.

Diseño: `documentation/design_screens_home.md`.

## Notas de arquitectura

- **`StatefulShellRoute` en vez de una `GoRoute` simple**: cada tab necesita su propia pila de navegación (p. ej. entrar a una receta desde Plan y volver sin perder el scroll de Home) — es el patrón estándar de GoRouter para bottom-nav con estado independiente por tab, ya incluido en `go_router: ^14.6.2` (no se agregó ninguna dependencia nueva).
- **`homeDailyCalorieGoalProvider` cruza a `features/onboarding`**: importa `calorie_estimate.dart` y `OnboardingAnswers` (dominio puro, sin UI) — deliberado y documentado, no un acoplamiento de presentación. Alternativa descartada: duplicar la fórmula en `home` — peor, dos lugares que mantener sincronizados.
- **Botón de cámara no es una ruta**: vive en `MainShell`, no en `route_paths.dart` — abre una hoja de acción (`showCameraActionSheet`), no navega a ninguna pantalla propia.
- **Ningún tap sin feedback**: Plan/Lista de compra/IA en "Empieza por aquí", y las 3 opciones de la hoja de cámara, muestran un `SnackBar` "Muy pronto" en vez de no hacer nada — la lección del bug de "Empezar" en Welcome (Épica 2/3) fue justamente esa: un tap sin ningún feedback se percibe como un bug, no como "función no disponible".

## Reusado vs. nuevo

Reusado: `AppButton`, `AppSkeletonBar`, `AppStateBlock`, `showAppBottomSheet`, tokens de tema, `estimateDailyCalories`/`OnboardingAnswers` (de Onboarding). Nuevo, parte de las 10 fichas base (no específico de esta feature): `ProgressRing`, `BottomNavigation`. Nuevo y propuesto por el propio diseño de esta fase: `QuickActionTile` (solo variante de fila). Nuevo y específico de esta feature: `ComingSoonPage`, `ProfilePlaceholderPage` (ambos temporales, se borran cuando sus épicas reales existan).

## Known gaps (señalados, no decididos en silencio)

- **C1/C2 (Home poblado) no implementados** — dependen de la Épica 6 (plan diario real). Ver arriba.
- **`MealCard`, `MacroBar`, `AISuggestionCard` no construidos** — mismo motivo; se construirán junto con Épica 6, cuando exista el primer consumidor real de cada uno.
- **Racha ("12 días seguidos") no implementada** — necesita seguimiento diario real (Épica 6).
- **Perfil es un placeholder temporal** que solo aloja "Cerrar sesión" — el resto (ver/editar perfil, eliminar cuenta) es la Épica 11.
- **La cámara central no analiza fotos de verdad** — cada opción de la hoja muestra un snackbar "Muy pronto" (Épicas 8/9 no existen).
- **Sin tests** — diferido a la Épica 16 por pedido explícito del usuario.
