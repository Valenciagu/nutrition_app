# Task Board — AI Nutrition App

Single source of truth for what's planned, in progress, and done. Work proceeds one task at a time per `.claude/skills/nutrition-app-workflow`. See `PROJECT_CONTEXT.md` for what currently exists, and `documentation/<feature>.md` for per-feature detail.

Legend: `[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked

---

## Epic 0 — Product & Architecture
- [x] EPIC0-001 — Read `Instrucciones.md`, define process, create `.claude/skills/` (workflow, architecture, security, design), `TASKS.md`, `PROJECT_CONTEXT.md`, `documentation/`.
- [x] EPIC0-002 — Sync the visual design system from the Claude Design canvas (`desing.md`) via `DesignSync`. Done: read `Fase 1 - Fundamentos.dc.html` and `Fichas de componentes.dc.html`, transcribed into `documentation/design_system.md`. Remaining canvas files (`Fase 2/3/4`, `Fases 5-12`) will be read/transcribed when the corresponding epic starts.

## Epic 1 — Project Foundation
- [x] FOUND-001 — Configure `pubspec.yaml` dependencies (Riverpod, GoRouter, Dio, Firebase packages, localization/intl, freezed/json_serializable).
- [x] FOUND-002 — Create `lib/core/` folder skeleton (constants, errors, extensions, localization, network, router, theme, utils, widgets, services).
- [x] FOUND-003 — Core error handling (`Failure`/`AppException` types).
- [x] FOUND-004 — Localization system: ARB files (`app_es.arb`, `app_en.arb`) + generated `AppLocalizations` + `context.l10n` extension. Enforces the "no hardcoded labels" rule.
- [x] FOUND-005 — Theme tokens rebuilt with the **real synced design** (colors light+dark as `AppColorTokens` ThemeExtension, typography via `google_fonts` Plus Jakarta Sans, spacing/radius/elevation/motion scales). See `documentation/design_system.md`.
- [x] FOUND-006 — Router skeleton: single `GoRouter` instance + centralized route name constants + temporary placeholder home page.
- [x] FOUND-007 — Network client skeleton: single Dio instance + interceptor hook (auth header TODO, error logging without secrets).
- [~] FOUND-008 — Core reusable widgets from "Fichas de componentes" (10 components, closed system). Built so far: `AppButton`, `AppTextField`, `AppCard`, `AppStateBlock` (empty/loading/error), `AppSkeletonBar`, `showAppBottomSheet`. Deferred (still core/widgets, not skipped): `SelectableChip` (→ Epic 3), `MealCard`/`ProgressRing`/`MacroBar` (→ Epic 4), `AIMessage` (→ Epic 5), `BottomNavigation` (→ once 2+ tab features exist). Rationale for deferral in `documentation/design_system.md`.
- [ ] FOUND-009 — Firebase project wiring (`firebase_core` init, `flutterfire configure`). **Needs user action**: a Firebase project must exist and the user must run the FlutterFire CLI login interactively.
- [x] FOUND-010 — App entry point (`main.dart`): `ProviderScope`, `MaterialApp.router`, light+dark theme, localization delegates wired together.

Validated: `flutter analyze` clean, `flutter build web --debug` succeeds after both the initial scaffold and the design-token rebuild. Not yet run on an Android/iOS device/emulator (none attached in this environment) or manually eyeballed in a browser.

## Epic 2 — Authentication
- [x] Scaffold: `features/authentication/{data,domain,presentation}`.
- [x] Sign up / sign in / password reset (Firebase Auth email+password) — screens A1-A5 (Splash, Welcome, Login, SignUp, ForgotPassword).
- [x] Session persistence (Firebase Auth handles this natively) + sign out (temporary button on the Home placeholder).
- [x] Auth guard integrated into router (`redirect` + `GoRouterRefreshStream`).
- [ ] AUTH-101 — Account deletion entry point. Deferred to Epic 11 (Profile), where it has an actual home in the UI.
- [ ] AUTH-102 — Email verification flow. Deferred (Instrucciones.md: "when appropriate", not MVP-critical).
- [ ] AUTH-103 — Google/Apple social sign-in. Deferred: needs `google_sign_in`/`sign_in_with_apple` + OAuth/Apple Developer setup the user hasn't provided yet. **Ask the user before starting** this one (new deps + external console config).
- [ ] AUTH-104 — Real "open mail app" action on the password-reset-sent screen (needs `url_launcher`, not added yet).
- [ ] AUTH-105 — Real Terms/Privacy Policy content + links (needs legal copy from the user).
- [ ] AUTH-106 — Real guest-mode persistence once Onboarding/Plan (Epics 3/6) exist (currently "Seguir sin cuenta" just goes to Home with nothing saved).
- **Hard runtime dependency: FOUND-009 (Firebase project).** The feature compiles and analyzes clean, but can't actually sign in/up until a real Firebase project is connected — `main.dart` shows a developer-facing "Firebase not configured" screen in the meantime (see `documentation/authentication.md`).
- Depends on: Foundation (Epic 1), design for Fase 2 Block A (done, see `documentation/design_screens_auth.md`). Block B (Onboarding, B1-B9) of the same canvas file is intentionally not read yet — will be read when Epic 3 starts.

## Epic 3 — Onboarding
- [ ] Data model for onboarding answers (age, sex, height, weight, activity level, goal, preferences, allergies, intolerances, meals/day, cooking ability/equipment, time, budget, country, health conditions).
- [ ] Onboarding flow screens (Fase 2 design).
- [ ] Persist profile to Firestore (`users/{userId}`).
- Depends on: Epic 2 (needs an authenticated user), design.

## Epic 4 — Home
- [ ] Daily nutrition summary.
- [ ] Reusable `MealCard`.
- [ ] Loading / error / empty states.
- Depends on: Epic 3 (profile/goal exist), Epic 6 (daily plan data), design (Fase 3).

## Epic 5 — AI Nutrition Assistant (backend)
- [ ] Cloud Function(s) proxying OpenAI, with auth validation, structured-output parsing, safety validation layer.
- [ ] AI usage quota enforcement (free vs premium) server-side.
- [ ] Client-side `AIService` abstraction (model-agnostic).
- Depends on: Foundation, Firebase Functions project setup.

## Epic 6 — Meal Planning / Daily Plan
- [ ] Daily plan domain model + Firestore schema (`users/{userId}/nutritionPlans/{planId}`).
- [ ] Plan generation via AI assistant (Epic 5) with deterministic safety layer.
- [ ] Adaptive adjustments ("no tengo pollo", "ya comí una hamburguesa").
- Depends on: Epic 5, design (Fase 4).

## Epic 7 — Recipes
- [ ] Recipe domain model (ingredients, quantities, steps, macros, substitutions).
- [ ] Recipe generation via AI assistant.
- [ ] `RecipeCard` reusable component.
- Depends on: Epic 5, design (Fase 4).

## Epic 8 — Food Photo Analysis
- [ ] Image capture/upload (compressed, validated) → Storage.
- [ ] Cloud Function: vision-capable model analysis → structured macro/calorie estimate with uncertainty messaging.
- [ ] `FoodAnalysisResultCard`.
- Depends on: Epic 5, Storage rules (security skill).

## Epic 9 — Ingredient Photo Analysis (Premium)
- [ ] Same pipeline as Epic 8, applied to fridge/pantry photos → recipe suggestions.
- Depends on: Epic 8, Epic 13 (premium gating).

## Epic 10 — Grocery List
- [ ] Generate grouped shopping list from plan/recipes.
- [ ] Mark purchased/already-available; adapt list accordingly.
- Depends on: Epic 6/7.

## Epic 11 — Profile
- [ ] View/edit profile & preferences.
- [ ] Data/account deletion flow (privacy requirement).

## Epic 12 — Notifications
- [ ] Meal/plan/shopping/progress reminders respecting quiet hours, timezone, opt-in.

## Epic 13 — Subscriptions
- [ ] Platform billing integration (App Store/Play) for the 4 plans (monthly/2mo/3mo/annual).
- [ ] Server-side receipt validation → trusted premium flag in Firestore.
- [ ] Free vs premium gating across features (never client-trusted).

## Epic 14 — Analytics
- [ ] Centralized analytics event constants + Firebase Analytics wiring.

## Epic 15 — Security Hardening
- [ ] Firestore & Storage rules review, App Check rollout, rate limiting review.

## Epic 16 — Testing (deferred to the end per user request)
- [ ] Unit/widget/integration tests, Firestore rules tests, AI validation tests — added as a dedicated pass near project completion, not per-feature.

## Epic 17 — Production Release
- [ ] Full security review (Instrucciones.md §80), store listing prep, release builds.

---

## Currently in progress
Design is synced and the theme + first 5 core widgets are built. Epic 1 (Foundation) is essentially done except FOUND-009 (needs a Firebase project + interactive `flutterfire configure` from the user). Ready to start Epic 2 (Authentication) — it only needs `AppButton`/`AppTextField`/`AppStateBlock`, all of which now exist.

## Open questions / decisions needed from the user
- Firebase project: does one already exist, or should we plan its creation together when we reach FOUND-009?
- OpenAI backend: confirm Cloud Functions (Node/Python) as the runtime for Epic 5, or another backend if preferred.
