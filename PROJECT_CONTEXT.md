# Project Context — AI Nutrition App

Always-current snapshot of what this app actually contains. Read this first when resuming work. Updated after every completed task/feature — see `.claude/skills/nutrition-app-workflow`. For the full spec, see `Instrucciones.md`; for task status, see `TASKS.md`; for per-feature detail, see `documentation/`.

_Last updated: 2026-09-11 — after syncing the real design system and rebuilding the theme + first core widgets._

## What this app is

An AI-powered personal nutrition assistant (Flutter, iOS + Android, Spanish-first) that builds personalized meal plans, recipes, and grocery lists, analyzes food photos, and adapts to what the user actually eats — not a rigid static diet generator. Full product spec in `Instrucciones.md`.

## Tech stack (decided, per `Instrucciones.md`)

- Flutter/Dart, Clean Architecture, feature-oriented (`lib/core/` + `lib/features/<feature>/{data,domain,presentation}`)
- State management: Riverpod
- Navigation: GoRouter
- HTTP: Dio (for any non-Firebase backend calls)
- Backend: Firebase (Auth, Firestore, Storage, Cloud Functions, App Check, Analytics, Crashlytics)
- AI: OpenAI, called only from Cloud Functions — never from the Flutter client directly
- Localization: Flutter ARB-based `AppLocalizations`, Spanish first, English-ready

## Current status

- Process/tooling set up:
  - `.claude/skills/nutrition-app-workflow` — task process (this file, `TASKS.md`, `documentation/`).
  - `.claude/skills/nutrition-app-architecture` — Clean Architecture / Riverpod / GoRouter / reuse / localization rules.
  - `.claude/skills/nutrition-app-security` — secrets, Firebase rules, OpenAI proxying, subscription trust rules.
  - `.claude/skills/nutrition-app-design` — visual fidelity to the `desing.md` Claude Design canvas.
  - `TASKS.md` — full epic/task backlog.
- **The real visual design is synced** — see `documentation/design_system.md` (colors, typography, spacing, radius, elevation, motion, and the 10-component library status). Source: the Claude Design canvas in `desing.md`, `Fase 1 - Fundamentos` and `Fichas de componentes` read so far; remaining `Fase 2/3/4`/`Fases 5-12` files get read when their epic starts.
- **Epic 1 (Foundation) is scaffolded and theme-complete** — see `documentation/foundation.md` and `documentation/design_system.md`. Summary:
  - Dependencies configured: `flutter_riverpod`, `go_router`, `dio`, full Firebase suite (not yet initialized — see blockers), `freezed`/`json_serializable`, ARB-based localization, `google_fonts` (Plus Jakarta Sans).
  - `lib/core/` populated: `errors/` (`Failure`/`AppException` hierarchies), `localization/` (ES/EN ARB files + generated `AppLocalizations` + `context.l10n` extension — **no hardcoded UI strings anywhere**), `theme/` (`AppColorTokens` light+dark `ThemeExtension`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppElevation`, `AppMotion`, real synced values — no more placeholders), `router/` (single `GoRouter` via `routerProvider`, one route rendering a temporary `HomePlaceholderPage`), `network/` (single `dioClientProvider`), `constants/route_paths.dart`.
  - `lib/core/widgets/` has the first 5 of the design system's 10 base components: `AppButton`, `AppTextField`, `AppCard`, `AppStateBlock` (empty/loading/error), `AppSkeletonBar`, plus `showAppBottomSheet`. The other 5 (`SelectableChip`, `MealCard`, `ProgressRing`, `MacroBar`, `AIMessage`, `BottomNavigation`) are deliberately deferred to the epic that first needs them (see `documentation/design_system.md` "Components — status").
  - `lib/main.dart` wires `ProviderScope` → `MaterialApp.router` with light+dark theme (`ThemeMode.system`) + router + localization.
  - `lib/features/` exists as an empty directory, ready for the first feature.
  - Validated via `flutter analyze` (clean) and `flutter build web --debug` (succeeds), both before and after the design-token rebuild. Not yet run on Android/iOS device/emulator, or manually eyeballed in a browser.
- **No product feature exists yet** (auth, onboarding, home, nutrition, recipes, etc.) — `lib/features/` is empty. Epic 2 (Authentication) is next and only depends on `AppButton`/`AppTextField`/`AppStateBlock`, all already built.

## Known blockers

- **Firebase project (FOUND-009):** no Firebase project has been created/connected yet. Needs the user to either point us at an existing project or create one; `flutterfire configure` requires interactive login.

Design sync is no longer a blocker (resolved 2026-09-11) — see `documentation/design_system.md` and the `project-design-access` memory for how to pull the remaining canvas files when needed.

## Folder structure (current)

```
lib/
  core/
    constants/     route_paths.dart
    errors/        failure.dart, app_exception.dart
    extensions/    (empty — populated as needed)
    localization/  l10n/{app_es.arb,app_en.arb}, generated/ (gitignored), app_localizations_ext.dart
    network/       dio_client.dart
    router/        app_router.dart
    services/      (empty — populated as needed)
    theme/         app_color_tokens.dart, app_typography.dart, app_spacing.dart, app_radius.dart, app_elevation.dart, app_motion.dart, app_theme.dart
    utils/         (empty — populated as needed)
    widgets/       app_button.dart, app_text_field.dart, app_card.dart, app_state_block.dart, app_skeleton.dart, app_bottom_sheet.dart, home_placeholder_page.dart (temporary, see documentation/foundation.md)
  features/        (empty, ready for Epic 2+)
  main.dart
```

## Features implemented

_None yet — Foundation only. See `documentation/foundation.md` and `documentation/design_system.md`._

## Reusable component registry

- Core: `AppButton`, `AppTextField`, `AppCard`, `AppStateBlock` (+ `AppSkeletonBar`), `showAppBottomSheet`. Not yet built (deferred to the epic that needs them — see `documentation/design_system.md`): `SelectableChip`, `MealCard`, `ProgressRing`, `MacroBar`, `AIMessage`, `BottomNavigation`.
- Feature: none yet.
