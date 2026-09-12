---
name: nutrition-app-design
description: Visual design fidelity rules for this nutrition app — respect the Claude Design canvas referenced by desing.md, reuse core theme tokens and widgets, no ad-hoc styling. Use whenever building or modifying any screen, widget, or visual element under lib/ (presentation layers, core/theme, core/widgets).
---

# Nutrition App — Design Fidelity

The visual/UX design is specified separately from the technical spec (`Instrucciones.md` section 61) in `desing.md`, which points to a Claude Design canvas project. **Do not invent an unrelated visual design.** Match what the canvas specifies unless there's a genuine technical reason not to, and say so explicitly if you deviate.

## Before building any screen or component

1. Read `documentation/design_system.md` first — it's the transcribed source of truth for colors, typography, spacing, radius, elevation, motion, and the 10-component library's status (built vs. deferred), pulled from the real Claude Design canvas (design sync succeeded 2026-09-11, see the `project-design-access` memory).
2. If the feature you're building isn't covered yet (its `Fase N - ...` file hasn't been read — check the "Not yet transcribed" list at the top of `design_system.md`), fetch it via `DesignSync get_file` (projectId `d3c0cd06-9d89-4ceb-b4b7-0f3f858d37c1`, see the memory for details) and add a section to `design_system.md` before writing widget code — don't fabricate pixel-level detail, and don't re-fetch files already transcribed there.
3. Reuse tokens from `core/theme/` (`AppColorTokens` via `context.colors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppElevation`, `AppMotion`) — never a raw hex/number. If a needed token is genuinely missing from both the theme files and `design_system.md`, that's a real gap: fetch the source file rather than inventing a value.

## Reuse over redesign

- Reusable visual components (buttons, cards, inputs, chips, bottom sheets, loading/empty/error states) belong in `core/widgets/`, sourced from `Fichas de componentes.dc.html`. Never rebuild a one-off version of an existing core component inside a feature's `presentation/` folder.
- All colors, spacing, radii, and text styles come from `core/theme/` tokens — never a raw hex color or magic `EdgeInsets` number copy-pasted across widgets. If a token is missing, add it to the theme, don't inline it.
- All user-facing copy comes from the localization layer (`core/localization/`) per the `nutrition-app-architecture` skill — the design canvas gives you the Spanish copy to put into the ARB file, not into the widget.

## Screens map (from desing.md)

- `Fichas de componentes.dc.html` — the component library / design system reference. This is the ground truth for `core/widgets/` and `core/theme/`.
- `Fase 1 - Fundamentos.dc.html` — foundational screens/patterns.
- `Fase 2 - Auth y Onboarding.dc.html` — `features/authentication`, `features/onboarding`.
- `Fase 3 - Home.dc.html` — `features/home`.
- `Fase 4 - Plan y Recetas.dc.html` — `features/nutrition` (daily plan), `features/recipes`.
- `Fases 5-12 - Entrega final.dc.html` — remaining features (food analysis, shopping list, profile, subscriptions, notifications, etc.) through final delivery polish.
- `ios-frame.jsx` / `support.js` — likely presentation/preview scaffolding for the design canvas itself, not app code to port literally; treat as reference only.
- `uploads/desygn.md.md` — supplementary design notes; read if present when syncing.

## Platform look

Target both iOS and Android from one Flutter codebase using Material widgets themed to match the design system (colors/typography/shapes), rather than mixing Material and Cupertino widget trees — unless the design canvas explicitly calls for iOS-specific chrome, in which case confirm with the user before introducing Cupertino-specific widgets.
