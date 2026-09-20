# Project Context — AI Nutrition App

Always-current snapshot of what this app actually contains. Read this first when resuming work. Updated after every completed task/feature — see `.claude/skills/nutrition-app-workflow`. For the full spec, see `Instrucciones.md`; for task status, see `TASKS.md`; for per-feature detail, see `documentation/`.

_Last updated: 2026-09-20 — Epic 5 complete (AI5-001/002/003: Cloud Functions backend scaffold, first OpenAI-proxying function, server-side AI usage quota, and the Dart `AIService` abstraction)._

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
- **Epic 2 (Authentication) is built and connected to a real Firebase project** — see `documentation/authentication.md` and `documentation/design_screens_auth.md`. Email/password sign-in, sign-up, password reset, session-aware router redirect, all 5 Auth screens (Splash, Welcome, Login, SignUp, ForgotPassword). Manually tested by the user; 3 bugs found and fixed (see "Known blockers" below).
- **Epic 3 (Onboarding) is built and confirmed working end-to-end** (2026-09-12) — see `documentation/onboarding.md` and `documentation/design_screens_onboarding.md`. The 7-step conversational flow (B1-B7: objetivo, datos personales, actividad, alimentos que gustan, alergias, ritmo de comidas, cocina+presupuesto), local draft persistence (`shared_preferences`, since registration happens AFTER onboarding), and migration of the completed draft to Firestore (`users/{userId}`) once the user actually signs in/up. The user ran the real flow (Welcome → Onboarding → sign up) and verified in the Firebase console that `users/{uid}` lands with the full completed draft. B8/B9 (AI plan generation/reveal) are NOT built — they depend on Epic 5/6.
- `lib/features/` now has two features: `authentication/{data,domain,presentation}`, `onboarding/{data,domain,presentation}`. Home, nutrition, recipes, etc. don't exist yet.
- **First real Firestore write in the app** (Onboarding's migration step) — added minimal `firestore.rules` (`users/{userId}` == own doc only) so it doesn't ship unprotected. Deployed 2026-09-12 (`firebase deploy --only firestore:rules`) — that run also created the project's Firestore database, which didn't exist yet. A `.firebaserc` (default project `nutritionapp-eee08`) was added so the Firebase CLI knows which project to target. Full rules review still deferred to Epic 15.
- **Epic 4 (Home) is built** — see `documentation/home.md` and `documentation/design_screens_home.md`. Main app shell: 4 tabs + central camera (`StatefulShellRoute` — navigation decision confirmed with the user 2026-09-12, replacing the original 5-tab brief). Home shows the design's "primer día" empty state (dimmed calorie ring with the goal from Onboarding, 3 quick-action rows) plus loading/error states; Plan and IA tabs are `ComingSoonPage` placeholders (Epic 5/6 not built), Perfil hosts the sign-out button temporarily (Epic 11 not built). The populated Home states (real macros, next meal, AI suggestions, streak) are NOT built — they need Epic 6's daily plan data; faking that content was rejected as misleading, same call as Onboarding's B8/B9. `flutter analyze` clean, `flutter build web --debug` succeeds; **still not manually tested by the user as of 2026-09-19** (a pending fix for a camera-button crash — negative `Container.margin` assertion, replaced with `Transform.translate` — sits uncommitted in `lib/core/widgets/bottom_navigation.dart`, likely found during that not-yet-completed manual pass). A bug list from the user is expected but not delivered yet (as of 2026-09-19); the user chose to proceed to Epic 5 first and address bugs later.
- **Epic 5 (AI backend) is complete** — see `documentation/ai_backend.md`. New `functions/` subproject (first non-Dart code in the repo): Firebase Cloud Functions v2, Node 22 + TypeScript. First real function `askNutritionAssistant` (free-text nutrition Q&A) — Firebase-Auth-gated, reads `goal`/`avoidFoods`/`isPremium` server-side from `users/{uid}` (never trusts client-sent profile data), enforces a per-user daily AI usage quota (`users/{uid}/aiUsage/{yyyy-mm-dd}`, atomic Firestore transaction, refunded on OpenAI failure — `functions/src/ai/quota.ts`), calls OpenAI's Responses API with structured output (`zod`/`zodTextFormat`, model `gpt-5.6-luna` centralized in `functions/src/config/openai.ts`), and runs a deterministic safety layer (checks the model's own flags AND independently scans for the user's excluded foods / medication-change language) before ever returning a response. OpenAI key via Firebase Secret Manager (`defineSecret`), never in code. `firestore.rules` documents that `aiUsage` is intentionally left unmatched (denied to the client by default — only Cloud Functions touch it via the Admin SDK). `isPremium` reads `users/{uid}.subscription.isPremium`, a field nothing writes yet (Epic 13 doesn't exist) — safe default of `free` for everyone today, ready for Epic 13 to start writing it. On the Flutter side, `lib/core/services/ai/` now has an `AIService` abstract contract + `FirebaseAiService` implementation (calls the callable, maps `FirebaseFunctionsException` codes to the existing `Failure` hierarchy, adding one new `AiQuotaExceededFailure`) — deliberately with **no UI consumer yet** (the "IA" tab stays `ComingSoonPage`; no epic in the backlog explicitly owns a general AI chat screen, see "Open questions" in `TASKS.md`). Backend compiles clean (`tsc --noEmit`) but **not deployed** — needs the user to run `firebase functions:secrets:set OPENAI_API_KEY` and confirm `firebase deploy --only functions` (not run by Claude — cost/shared-project action). `flutter analyze` clean and `flutter build web --debug` succeeds (epic checkpoint, 2026-09-20).

## Known blockers

- **Firebase project — resolved 2026-09-11.** Project `nutritionapp-eee08` is connected (`lib/firebase_options.dart`, `android/app/google-services.json`). `main.dart` calls `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`. Email/Password sign-in is enabled in the console. iOS's `GoogleService-Info.plist` wasn't generated (flutterfire configure ran from Windows) but this doesn't block Auth — `firebase_options.dart` supplies iOS options directly in Dart; regenerate via `flutterfire configure` from a Mac if a native iOS file ends up being required later (e.g. for Crashlytics).
- **Auth follow-ups explicitly deferred** (see `TASKS.md` Epic 2 for the full list): Google/Apple sign-in (needs new deps + OAuth setup — ask the user first), real "open mail app" action (needs `url_launcher`), real Terms/Privacy content, account deletion (belongs in Epic 11/Profile), real guest-mode persistence (needs Epic 3/6).
- **3 Auth bugs found via manual testing, all fixed** (see `documentation/authentication.md` "Notas de arquitectura" for full detail on each): (1) Splash stuck forever — router redirect logic gap + a real race condition between two independent `authStateChanges()` subscriptions, fixed by unifying on `ref.listen(authStateChangesProvider, ...)`. (2) "Empezar" on Welcome did nothing — `redirect` bounced unauthenticated navigation to `root` back to Welcome. (3) Fixing (2) naively (always letting `root` through without a session) broke "Cerrar sesión" — it no longer returned to Welcome, since a guest and a just-signed-out user both look like "no session" to the router. Fixed (2)+(3) together with a `guestModeProvider` (`auth_providers.dart`) that the router checks instead of just "no session + root": set `true` by Welcome/Onboarding-completion's guest actions, reset to `false` in `AuthController.signOut()`.
Design sync is no longer a blocker (resolved 2026-09-11) — see `documentation/design_system.md` and the `project-design-access` memory for how to pull the remaining canvas files when needed. Fase 2's Block A (Auth) is transcribed in `documentation/design_screens_auth.md`; Block B (Onboarding) is transcribed in `documentation/design_screens_onboarding.md`.

## Folder structure (current)

```
lib/
  core/
    constants/     route_paths.dart
    errors/        failure.dart, app_exception.dart
    extensions/    (empty — populated as needed)
    localization/  l10n/{app_es.arb,app_en.arb}, generated/ (gitignored), app_localizations_ext.dart
    network/       dio_client.dart
    router/        app_router.dart, main_shell.dart (StatefulShellRoute chrome)
    services/      firebase_instances.dart, ai/{ai_service.dart, firebase_ai_service.dart, nutrition_assistant_answer.dart}
    theme/         app_color_tokens.dart, app_typography.dart, app_spacing.dart, app_radius.dart, app_elevation.dart, app_motion.dart, app_theme.dart
    utils/         validators.dart
    widgets/       app_button.dart, app_text_field.dart, app_card.dart, app_state_block.dart, app_skeleton.dart, app_bottom_sheet.dart, selectable_chip.dart, progress_ring.dart, quick_action_tile.dart, bottom_navigation.dart, coming_soon_page.dart (temporary), profile_placeholder_page.dart (temporary), firebase_setup_required_page.dart
  features/
    authentication/
      domain/      entities/auth_user.dart, repositories/auth_repository.dart
      data/        datasources/firebase_auth_data_source.dart, repositories/auth_repository_impl.dart
      presentation/
        providers/auth_providers.dart
        auth_error_presentation.dart
        pages/     splash_page.dart, welcome_page.dart, login_page.dart, sign_up_page.dart, forgot_password_page.dart
        widgets/   auth_back_button.dart, legal_notice_text.dart, legal_acceptance_checkbox.dart, password_strength_indicator.dart
    onboarding/
      domain/      entities/onboarding_answers.dart, repositories/onboarding_repository.dart, calorie_estimate.dart
      data/        datasources/onboarding_local_data_source.dart, onboarding_remote_data_source.dart, repositories/onboarding_repository_impl.dart
      presentation/
        providers/onboarding_providers.dart
        onboarding_catalog.dart
        pages/     onboarding_page.dart (wizard shell), steps/{goal,personal_data,activity_level,liked_foods,allergies,meal_rhythm,cooking_budget}_step.dart
        widgets/   step_header.dart, onboarding_option_card.dart, wheel_value_field.dart
    home/
      presentation/
        providers/home_providers.dart
        pages/     home_page.dart
        widgets/   camera_action_sheet.dart
  main.dart

functions/                    (Firebase Cloud Functions v2, Node 22 + TypeScript — separate from the Dart tree)
  src/
    index.ts                  exports all functions, initializes firebase-admin
    config/openai.ts          OpenAI secret + client + centralized model routing
    ai/
      askNutritionAssistant.ts  the onCall function
      schema.ts                zod structured-output contract
      safety.ts                deterministic post-validation safety layer
      quota.ts                 per-user daily AI usage quota (Firestore transaction)
      prompts/nutritionAssistantV1.ts  centralized, versioned system prompt
```

## Features implemented

- **Authentication** (Epic 2) — see `documentation/authentication.md`. Email/password sign-in/up/reset, session-aware routing.
- **Onboarding** (Epic 3) — see `documentation/onboarding.md`. 7-step conversational flow (B1-B7), local draft persistence, Firestore migration on signup/login. B8/B9 (AI plan generation/reveal) deferred to Epic 5/6.
- **Home** (Epic 4) — see `documentation/home.md`. Main app shell (4 tabs + camera), Home's empty/loading/error states. Populated states deferred to Epic 6.
- **AI backend** (Epic 5, complete) — see `documentation/ai_backend.md`. `askNutritionAssistant` Cloud Function: secure OpenAI proxy with auth validation, per-user daily quota, structured output, and a deterministic safety layer. Plus `AIService`/`FirebaseAiService` on the Flutter side. Not yet deployed; no UI screen calls `AIService` yet (deliberate — no epic owns that screen).

Foundation-only docs: `documentation/foundation.md` and `documentation/design_system.md`.

## Reusable component registry

- Core: `AppButton`, `AppTextField`, `AppCard`, `AppStateBlock` (+ `AppSkeletonBar`), `showAppBottomSheet`, `SelectableChip`, `ProgressRing`, `BottomNavigation`, `QuickActionTile` (row variant only), `Validators` (`core/utils`). Not yet built (deferred to Epic 6, when real plan/macro data exists — see `documentation/design_system.md` and `documentation/home.md`): `MealCard`, `MacroBar`, `AIMessage`, `QuickActionTile`'s grid variant.
- Feature (authentication): `AuthBackButton`, `LegalNoticeText`, `LegalAcceptanceCheckbox`, `PasswordStrengthIndicator` — specific enough to this feature's forms that they weren't promoted to `core/widgets`; revisit if another feature needs something similar.
- Feature (onboarding): `StepHeader` (back + progress + counter, proposed by the design's own notes as the one new component this flow needs), `OnboardingOptionCard`, `WheelValueField` (+ `showIntWheelPicker`/`showDoubleWheelPicker`) — all specific to this step-flow's UI, not part of the 10-component base system.
