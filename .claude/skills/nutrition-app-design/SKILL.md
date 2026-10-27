---
name: nutrition-app-design
description: Visual design fidelity rules for this nutrition app — respect the Claude Design canvas referenced by desing.md, reuse core theme tokens and widgets, no ad-hoc styling. Use whenever building or modifying any screen, widget, or visual element under lib/ (presentation layers, core/theme, core/widgets).
---

# Nutrition App — Design Fidelity

The visual/UX design is specified separately from the technical spec (`Instrucciones.md` section 61) in `desing.md`, which points to a Claude Design canvas project. **Do not invent an unrelated visual design.** Match what the canvas specifies unless there's a genuine technical reason not to, and say so explicitly if you deviate.

## Before building any screen or component

1. Read `documentation/design_system.md` first — it's the transcribed source of truth for colors, typography, spacing, radius, elevation, motion (including the mandatory "Motion patterns" catalog), and the 10-component library's status (built vs. deferred), pulled from the real Claude Design canvas (design sync succeeded 2026-09-11, see the `project-design-access` memory).
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

## Motion & animation — standing approval (user, 2026-10-25)

The user wants the app to feel very interactive and animated (benchmark: Fitia) and gave a **standing approval** to add motion that isn't drawn on the canvas, without asking each time. **This does NOT relax canvas fidelity** — the canvas stays mandatory for everything static; motion is a layer on top of it. Full plan: `TASKS.md` Epic 20.

- **Read `documentation/design_system.md` → "Motion patterns" before animating anything.** It has the principles and the pattern catalog (M01-M13: press, toggle, content swap, list stagger, screen transition, sheet, shared element, progress, skeleton, AI working, success, celebration, error), each with its exact spec and shared implementation.
- **The resting frame of every animation must be exactly the canvas screen.** Motion never adds elements, colors, shapes or decoration, and never changes layout or flow. A screen missing from the canvas is fetched first, not designed to have something to animate.
- **Use only catalog patterns, through their shared implementation** — don't hand-tune durations/offsets per screen, don't invent a new style of motion. Same situation = same animation everywhere. A genuinely new need → add a row to the catalog (plus its shared implementation and `AppMotion` tokens) in the same change, then reuse it.
- **Non-negotiable:** `AppMotion` tokens only; taps/toggles/cards ≤320ms (only progress and AI waits may run longer or loop); interruptible, never blocks input; reduce-motion (`MediaQuery.disableAnimations`) → 140ms fade, never removed; stable 60fps in profile mode on a real device; loops pause off-screen behind a `RepaintBoundary`; small asset files.
- **Still ask the user first:** celebration moments (M12 / MOTION-106) and anything that changes a screen's layout or flow.
- **Branded AI loader (MOTION-102) — approved approach "A":** static food illustrations (SVG, brand style, from the design canvas) cycled/animated in code with `flutter_animate`. Build the widget so its content can later be swapped for a Rive file without touching any screen.
- **Sources — any source is allowed** (own code, canvas SVGs, LottieFiles, Rive community, purchased packs, commissioned work), on two conditions: (1) the license allows commercial use in a paid app, checked per asset — unclear license = don't use it; no third-party logos/brands; (2) **every animation asset is recorded in the "Animation sources" table in `documentation/design_system.md`** (file, source/URL, author, license, date added) in the same change that adds it. Recolor to brand tokens where the format allows so mixed sources still look like one series.

## Platform look

Target both iOS and Android from one Flutter codebase using Material widgets themed to match the design system (colors/typography/shapes), rather than mixing Material and Cupertino widget trees — unless the design canvas explicitly calls for iOS-specific chrome, in which case confirm with the user before introducing Cupertino-specific widgets.
