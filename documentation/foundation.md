# Epic 1 — Project Foundation

## What this covers

The base architecture skeleton every feature builds on: dependencies, folder structure, error handling, localization, theming, routing, and networking. No product feature (auth, onboarding, home, etc.) exists yet — this is purely infrastructure.

## Key files

- `pubspec.yaml` — Riverpod (`flutter_riverpod`, `riverpod_annotation`), GoRouter, Dio, full Firebase suite (core/auth/firestore/storage/functions/app_check/analytics/crashlytics), `freezed`/`json_serializable` for future domain modeling, `flutter_localizations`/`intl` for i18n. `flutter: generate: true` enables ARB-based localization codegen.
- `l10n.yaml` — points `flutter gen-l10n` at `lib/core/localization/l10n/*.arb`, outputs generated classes to `lib/core/localization/generated/` (gitignored, regenerated on every build).
- `lib/core/errors/failure.dart` — sealed `Failure` hierarchy (`ServerFailure`, `NetworkFailure`, `AuthFailure`, `ValidationFailure`, `PermissionFailure`, `NotFoundFailure`, `AiValidationFailure`, `UnknownFailure`) for domain/presentation-facing errors.
- `lib/core/errors/app_exception.dart` — sealed `AppException` hierarchy (`ServerException`, `NetworkException`, `AuthException`, `CacheException`, `AiResponseException`) thrown by the data layer; repositories map these to `Failure`s.
- `lib/core/localization/l10n/app_es.arb` (template/primary) and `app_en.arb` — all user-facing strings live here, nowhere else.
- `lib/core/localization/app_localizations_ext.dart` — `context.l10n` extension, the only way widgets should read strings.
- `lib/core/theme/{app_color_tokens,app_typography,app_spacing,app_radius,app_elevation,app_motion,app_theme}.dart` — centralized design tokens (synced from the real design canvas, see `documentation/design_system.md`) and the light/dark `ThemeData` builder.
- `lib/core/router/app_router.dart` — single `routerProvider` (Riverpod `Provider<GoRouter>`), currently one route (`RoutePaths.root`) rendering `HomePlaceholderPage`.
- `lib/core/constants/route_paths.dart` — centralized route path constants; extended per feature.
- `lib/core/widgets/home_placeholder_page.dart` — temporary landing screen, to be deleted once `features/home` (Epic 4) exists.
- `lib/core/network/dio_client.dart` — single `dioClientProvider`, base URL from `--dart-define=API_BASE_URL`, timeout config, and an interceptor hook for the future auth-token attachment and non-sensitive error logging.
- `lib/main.dart` — `ProviderScope` → `MaterialApp.router`, wired to the theme, router, and localization delegates.

## Architecture/state-management notes

- All cross-cutting concerns (errors, theme, router, network, localization) are Riverpod `Provider`s or static token holders under `lib/core/` — no singletons via `GetIt` were needed for this layer.
- The router is intentionally minimal: as each feature is built, it will contribute its own `GoRoute`s here (and eventually `redirect` logic for auth/onboarding guards, once `features/authentication`/`features/onboarding` exist).

## Reused vs. new

Nothing to reuse yet (first code in the project). Everything here is the reusable foundation subsequent features are expected to build on rather than duplicate — see the `nutrition-app-architecture` skill.

## Known gaps

- **Design tokens are now the real synced values** (see `documentation/design_system.md`) — a few dark-mode container colors that weren't explicitly specified use a marked placeholder (`// TODO(design-sync)` in `app_color_tokens.dart`).
- **5 of the design system's 10 base components are deliberately deferred** (`SelectableChip`, `MealCard`, `ProgressRing`, `MacroBar`, `AIMessage`, `BottomNavigation`) to the epic that first needs them — see `documentation/design_system.md` for the built vs. deferred breakdown and why.
- **Firebase is not wired up** (FOUND-009): no `firebase_options.dart`, no `Firebase.initializeApp()` call. Needs a real Firebase project and an interactive `flutterfire configure` run.
- **No automated tests** — deferred to Epic 16 per explicit user request.

## Validation performed

- `flutter analyze` — no issues.
- `flutter build web --debug` — builds successfully (used as a compile/runtime smoke test; no Android/iOS emulator was attached in this environment to verify on-device).
