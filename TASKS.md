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
- [x] FOUND-009 — Firebase project wiring. Done 2026-09-11: project `nutritionapp-eee08` created by the user, `flutterfire configure` run for android/ios/web, `lib/firebase_options.dart` generated, `main.dart` now calls `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`. Email/Password sign-in method enabled in the Firebase console by the user.
- [x] FOUND-010 — App entry point (`main.dart`): `ProviderScope`, `MaterialApp.router`, light+dark theme, localization delegates wired together.

Validated: `flutter analyze` clean, `flutter build web --debug` succeeds after both the initial scaffold and the design-token rebuild. Not yet run on an Android/iOS device/emulator (none attached in this environment) or manually eyeballed in a browser.

## Epic 2 — Authentication
- [x] Scaffold: `features/authentication/{data,domain,presentation}`.
- [x] Sign up / sign in / password reset (Firebase Auth email+password) — screens A1-A5 (Splash, Welcome, Login, SignUp, ForgotPassword).
- [x] Session persistence (Firebase Auth handles this natively) + sign out (temporary button on the Home placeholder).
- [x] Auth guard integrated into router (`redirect` + `ref.listen(authStateChangesProvider, ...)` driving `refreshListenable` — see `documentation/authentication.md` for why a naive independent-subscription `GoRouterRefreshStream` caused a race condition and was replaced).
- [ ] AUTH-101 — Account deletion entry point. Deferred to Epic 11 (Profile), where it has an actual home in the UI.
- [ ] AUTH-102 — Email verification flow. Deferred (Instrucciones.md: "when appropriate", not MVP-critical).
- [ ] AUTH-103 — Google/Apple social sign-in. Deferred: needs `google_sign_in`/`sign_in_with_apple` + OAuth/Apple Developer setup the user hasn't provided yet. **Ask the user before starting** this one (new deps + external console config).
- [ ] AUTH-104 — Real "open mail app" action on the password-reset-sent screen (needs `url_launcher`, not added yet).
- [ ] AUTH-105 — Real Terms/Privacy Policy content + links (needs legal copy from the user).
- [ ] AUTH-106 — Real guest-mode persistence once Onboarding/Plan (Epics 3/6) exist (currently "Seguir sin cuenta" just goes to Home with nothing saved).
- **FOUND-009 resolved 2026-09-11** — see above. Auth can now actually be exercised end-to-end; still not manually tested in a running app as of this note (analyze/build-only validation so far).
- Depends on: Foundation (Epic 1), design for Fase 2 Block A (done, see `documentation/design_screens_auth.md`). Block B (Onboarding, B1-B9) of the same canvas file is intentionally not read yet — will be read when Epic 3 starts.

## Epic 3 — Onboarding
- [x] Data model for onboarding answers (`OnboardingAnswers`: goal, sex, age, height, weight, unit system, activity level, liked foods, avoid foods, meal slots/schedule, cooking time/skill, budget level).
- [x] Onboarding flow screens B1-B7 (Fase 2 · Bloque B): objetivo, datos personales, actividad (con estimación de calorías en vivo), alimentos que gustan, alergias, ritmo de comidas, cocina+presupuesto.
- [x] Local draft persistence (`shared_preferences`) — needed because registration happens AFTER onboarding (confirmed with the user 2026-09-12), so there's no `userId` yet to own a Firestore doc while answering.
- [x] Migrate draft to Firestore (`users/{userId}`, merged) once a user actually signs in/up — wired in `app_router.dart`'s `ref.listen(authStateChangesProvider, ...)`.
- [x] `SelectableChip` (component 03/10, previously deferred to this epic) — built in `core/widgets/`.
- [x] Minimal Firestore security rules (`firestore.rules`, scoped to `users/{userId}` == own doc) — this is the app's first real Firestore write, so it couldn't ship with zero rules. Deployed 2026-09-12 (`firebase deploy --only firestore:rules`, run by the user; also created the project's Firestore database, added `.firebaserc` for the CLI's default project). Full review still deferred to Epic 15.
- [x] End-to-end manual verification (2026-09-12): user ran Welcome → Onboarding (all 7 steps) → sign up, and confirmed in the Firebase console that `users/{uid}` lands with the complete draft.
- [ ] ONBOARD-101 — B8 (generating, AI status) and B9 (plan ready, reveal with real macros/meals) are NOT built. They depend on real AI plan generation (Epic 5/6, not built yet) — faking that content would misrepresent what the AI actually produced. For now, completing B7 goes straight to `SignUpPage(hasPendingPlan: true)`. Revisit once Epic 6 exists.
- [ ] ONBOARD-102 — Allergy vs. intolerance severity isn't distinguished (the design's B5 mock doesn't show a per-item severity control) — currently one flat `avoidFoods` exclusion list. Revisit if the AI/recipe engine needs the distinction.
- [ ] ONBOARD-103 — Imperial unit display in B2 is a simple client-side conversion for display only; stored value is always metric (cm/kg). Fine for MVP, no known issue.
- Depends on: Epic 2 (done). Design: Fase 2 · Bloque B (done, see `documentation/design_screens_onboarding.md`). Decision confirmed with the user 2026-09-12: Onboarding runs BEFORE Signup/Guest (matches the design's proposed funnel and the `hasPendingPlan` hook already built into `SignUpPage` in Epic 2).

## Epic 4 — Home
- [x] Main app shell: 4 tabs + central camera (`StatefulShellRoute`) — navigation decision confirmed with the user 2026-09-12 (design's proposal over the original 5-tab brief; Progreso is no longer a tab, opens from Home's ring once Epic 6 exists).
- [x] Home screen, empty state (design's C3 · "primer día") — greeting, dimmed calorie ring using the goal calculated in Onboarding, 3 quick-action rows.
- [x] Loading state (C4, skeleton matching the real layout) and error state (`AppStateBlock.error`).
- [x] `ProgressRing` and `BottomNavigation` (components 05/10 and 09/10 of the base fiche system, previously deferred to this epic).
- [x] `QuickActionTile` (new component proposed by the design for this phase) — row variant only.
- [ ] Daily nutrition summary populated with real data (C1/C2: ring with actual macros, next-meal `MealCard`, `AISuggestionCard`, streak) — needs Epic 6 (daily plan/food log), not built. Faking this data would misrepresent the app; deferred honestly rather than mocked.
- [ ] `MealCard`, `MacroBar`, `AISuggestionCard` — deferred with the above, no real consumer yet.
- Depends on: Epic 3 (done — profile/goal exist), design Fase 3 (done, see `documentation/design_screens_home.md`). The populated states additionally depend on Epic 6 (daily plan data).

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
