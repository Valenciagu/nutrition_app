---
name: nutrition-app-architecture
description: Clean Architecture, Riverpod, GoRouter, reuse-first, naming and localization rules for this Flutter nutrition app. Use whenever creating or modifying widgets, providers, repositories, use cases, routes, constants, or any new file under lib/.
---

# Nutrition App — Architecture Patterns

Derived from `Instrucciones.md` (sections 15-18, 41-45, 59-60, 71-74). Full detail lives there; this skill is the enforceable checklist.

## Folder structure (feature-oriented Clean Architecture)

```
lib/
  core/
    constants/     # firestore collection names, route names, limits, analytics event names — grouped logically, never one giant class
    errors/        # Failure / AppException types shared across features
    extensions/
    localization/  # AppStrings (or generated ARB delegate) — the ONLY place user-facing text is defined
    network/       # single Dio client + interceptors
    router/        # single GoRouter instance + route name constants
    theme/         # colors, typography, spacing tokens — sourced from the design system
    utils/
    widgets/       # AppButton, AppTextField, AppCard, AppLoading, AppErrorView, AppEmptyState, AppScaffold, etc.
    services/
  features/
    <feature>/
      data/        # DTOs/*Model, data sources, repository implementations, mappers
      domain/      # entities, repository contracts, use cases (only when meaningful)
      presentation/ # screens, widgets, Riverpod providers/controllers
```

## Reuse-first rule (strict)

Before creating any widget, service, utility, validator, constant, or repository abstraction: search `lib/core/` and existing `lib/features/*` for something reusable. Extend via a clean API (parameters, variants) before creating a new component. If you still create something new that resembles an existing one, state explicitly why the existing one didn't fit.

Never create feature-prefixed duplicates of a core widget (e.g. `HomeButton`, `RecipeButton`) when `AppPrimaryButton`/`AppButton` already exists — parameterize instead.

## State management — Riverpod only

Use Riverpod consistently for state. Don't introduce another state-management approach. Keep business logic in providers/controllers or the domain layer, not in widgets. Choose the provider type (`Provider`, `NotifierProvider`, `FutureProvider`, `StreamProvider`, etc.) based on the actual data-flow shape, not by default habit.

## Navigation — GoRouter only

One centralized `GoRouter` instance in `core/router/`. Route paths/names are constants, never inline string literals scattered across the app. Auth/onboarding guards live in the router's redirect logic, not scattered in widgets.

## Networking — Dio only

One centralized Dio client in `core/network/` with interceptors for auth headers, logging (never logging secrets/tokens/PII), error mapping, and timeouts. Do not instantiate ad-hoc Dio/http clients inside features.

## Naming — English identifiers, Spanish UI text, Spanish comments

All Dart identifiers (classes, methods, variables, files) are in English, regardless of the fact the app ships in Spanish first. Example: `NutritionPlan`, not `PlanNutricional`.

Code comments may be written in Spanish (explicit user preference) — identifiers stay English either way. Doc-comments (`///`) on public core APIs may also be Spanish; keep them wherever the "why", not the "what", genuinely needs explaining (see the project's general no-comments-unless-non-obvious rule).

## Localization — no hardcoded labels (explicit project rule)

**Every user-facing string must come from a centralized class/system inside `lib/core/localization/`, never written inline in a widget.** This is a strict, explicitly-requested project rule — do not write `Text('¿Qué quieres comer hoy?')` directly. Instead:

- Prefer Flutter's standard ARB-based localization (`app_es.arb`, `app_en.arb` under `lib/core/localization/l10n/`, generated `AppLocalizations`), consumed as `context.l10n.someKey` (via an extension) or `AppLocalizations.of(context)!.someKey`.
- Every new label needed by a feature gets a new ARB key + English default text description; never a literal string in the widget tree.
- This applies to buttons, dialogs, error messages, empty states, validation messages — everything user-visible.

## Domain vs. data separation

Keep Firebase/Dio-specific models (`UserProfileModel`, `UserProfileDocument`) out of the domain layer. Domain entities (`UserProfile`) stay plain Dart. Repositories in `domain/` are abstract contracts; implementations live in `data/`.

## Constants

Group related constants together (e.g. `FirestoreCollections`, `RouteNames`, `AiLimits`) instead of one catch-all `AppConstants` god class.
