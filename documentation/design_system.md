# Design System Reference

Transcribed from the Claude Design canvas linked in `desing.md` (project `d3c0cd06-9d89-4ceb-b4b7-0f3f858d37c1`, files `Fase 1 - Fundamentos.dc.html` and `Fichas de componentes.dc.html`, read 2026-09-11). This is the source of truth for implementation — read this before `DesignSync`-fetching anything, and extend it when a new `Fase N` file gets read.

Not yet transcribed: `Fase 2 - Auth y Onboarding`, `Fase 3 - Home`, `Fase 4 - Plan y Recetas`, `Fases 5-12 - Entrega final`, `ios-frame.jsx`, `support.js`, `uploads/desygn.md.md`. Fetch and add a section here when a feature needs one of those.

## Product design direction

"Cocina luminosa, no laboratorio" (a luminous kitchen, not a lab). Wide white base, strong type, bleed food photography, green used sparingly but consistently. Premium feel comes from spacing and hierarchy, not gradients/chrome.

Four rules that shape every screen:
1. **Green is a traffic light** — only for primary CTA, progress, achievement, healthy status. Never a decorative background or large surface.
2. **The AI has a voice, not control** — indigo + a status dot marks anything AI-generated, everywhere, without turning the app into a chat.
3. **Food leads** — the photo is the largest element on a screen; UI gets out of the way.
4. **Progress, never guilt** — going over a target is never shown in red; it's neutral + a rebalancing action. Red is reserved for actual system errors.

Open decisions (per the canvas, still pending real assets from the user): final wordmark/logo, icon set (proposal: Lucide or Phosphor, ~8-10 custom icons for food scanner/ingredients/recalculate-day/streak), real food photography (fixed recipe: natural side light, matte neutral background, 90° or 45° angle, clean simple plate, realistic portion, no hands/utensils; 1:1 for cards, 4:5 for recipe detail).

## Color tokens

Implemented in `lib/core/theme/app_color_tokens.dart` as `AppColorTokens` (a `ThemeExtension`, light + dark). Access via `context.colors.xxx` (`AppColorTokensX`), never a raw hex value.

| Token | Light | Dark | Notes |
|---|---|---|---|
| `actionPrimary` | `#0B8F55` | `#3ED98C` | Primary 600 — only green valid with white text on top (4.6:1) |
| `actionPrimaryPressed` | `#076B40` | `#1F6B48`* | Primary 700 / pressed |
| `actionPrimaryStrong` | `#17A86A` | `#3ED98C`* | Primary 500 — fills without text, ring arcs, icons |
| `actionPrimarySurface` | `#E9F7F0` | `#1F6B48`* | Primary 50 — secondary-button hover bg |
| `onActionPrimary` | `#FFFFFF` | `#06301D` | |
| `aiActionSurface` / `onAiAction` | `#EEEDFB` / `#332D93` | `#262163` / `#CFCCFA` | Lighter indigo "AI action" button fill |
| `background` | `#F7F8F7` | `#0C110F` | |
| `surface` | `#FFFFFF` | `#141A17` | |
| `surfaceElevated` | `#FFFFFF` (+e2 shadow) | `#1C2420` | Dark expresses elevation via surface color, not shadow |
| `border` | `#E4E7E5` | `#2A332E` | |
| `textPrimary` | `#101512` | `#F2F5F3` | |
| `textSecondary` | `#5B635E` | `#A3ADA7` | |
| `textDisabled` | `#A2A9A5` | `#646E68` | |
| `success` / `successSurface` | `#0B8F55` / `#E9F7F0` | `#3ED98C` / `#1F6B48`* | Same as primary — success *is* green |
| `warning` / `warningSurface` | `#B26B00` / `#FDF3E2` | `#E8B45C` / *(placeholder)* | |
| `error` / `errorSurface` | `#C0372F` / `#FCEDEC` | `#F0736A` / *(placeholder)* | |
| `info` / `infoSurface` | `#1A6FB8` / `#E8F1F9` | `#6BB6F0` / *(placeholder)* | |
| `macroProtein` | `#0B8F55` | `#3ED98C`* | Fixed order always: protein, carbs, fat, water |
| `macroCarbs` | `#C98A17` | `#E8B45C`* | |
| `macroFat` | `#4740C4` | `#9D98F5` | |
| `macroWater` | `#1A6FB8` | `#6BB6F0` | |

`*` = not explicitly given for dark in the canvas; a reasonable placeholder was chosen (see `// TODO(design-sync)` in `app_color_tokens.dart`) — confirm before shipping a real dark-mode screen.

Semantic colors (macro, success/warning/error/info) always pair with a text label — color is never the only carrier of meaning.

## Typography

Single family: **Plus Jakarta Sans** (via `google_fonts` package — see `pubspec.yaml`), 6 weights, tabular figures for all nutrition numbers. Implemented in `lib/core/theme/app_typography.dart`.

| Token | Size/Line-height | Weight | Letter-spacing | Use |
|---|---|---|---|---|
| `display` | 40/44 | 800 | -3% | Hero numbers |
| `titleL` | 30/36 | 700 | -2% | Screen titles |
| `titleM` | 22/28 | 700 | -1% | Section titles |
| `titleS` | 17/23 | 600 | — | Card titles |
| `bodyL` | 16/25 | 400 | — | Default app text |
| `bodyM` | 14/22 | 400 | — | Secondary text/descriptions |
| `label` | 15/18 | 600 | — | Button labels |
| `overline` | 11.5/~15 | 600 | +8%, uppercase | Section headers |
| `numericXl` | 46/46, tabular | 800 | -3% | The one main metric per screen (e.g. kcal left) |
| `numericM` | 26/26, tabular | 700 | — | Secondary metrics (macros row) |

Thousands separator resolves by locale (`.` es-ES, `,` en-US) — never hardcoded; use `NumberFormat` from `intl` when formatting, not manual string interpolation.

Standard `TextTheme` slot mapping (for stock Material widgets) is in `AppTheme._build`: `displayLarge`→display, `headlineLarge`→titleL, `titleLarge`→titleM, `titleMedium`→titleS, `bodyLarge`→bodyL, `bodyMedium`→bodyM, `labelLarge`→label, `labelSmall`→overline.

## Spacing, radius, elevation, motion

Implemented in `app_spacing.dart`, `app_radius.dart`, `app_elevation.dart`, `app_motion.dart`.

- **Spacing** (base 4): 2, 4 (icon gap), 8, 12 (intra-card), 16 (card padding), 20 (screen margin), 24 (between blocks), 32 (between sections), 40, 48, 64 (hero/empty).
- **Radius**: xs 4, sm 8, md 12, lg 16, xl 20, sheet 28 (top corners only), full 999 (buttons/chips always use `full`; cards use `lg`/`xl`; images inside a card use `md`).
- **Elevation**: e0 flat, e1 card, e2 float, e3 sheet, e4 dialog — light mode uses shadow; dark mode uses surface-color + border instead.
- **Component heights**: button lg/md/sm = 52/44/36, field 56, chip 36, app bar 56, bottom nav 64 (+ safe area), FAB 60, list item 64, tab 44. Touch target minimum is always 48×48 regardless of visual size.
- **Icons**: sizes 16/20/24/28/32, stroke 1.75 (or 1.5 at size 20). Icon set not yet chosen (Lucide/Phosphor proposal pending the user).
- **Borders**: hairline 1, selected 1.5, focus 2.
- **Motion durations**: instant 80ms (tap feedback), fast 140ms (chips/toggles), base 220ms (cards/sheets), slow 320ms (screen transitions), progress 600ms (rings/bars). Nothing exceeds 320ms except progress/AI. Everything must be interruptible; reduce-motion swaps movement for a 140ms fade, never removes it entirely.
- **Curves**: standard `cubic-bezier(.2,0,0,1)`, enter `cubic-bezier(0,0,0,1)`, exit `cubic-bezier(.3,0,1,1)`.
- **Breakpoints**: compact <360 (1 col, -1 type step), base 360-429, large 430-599, expanded ≥600 (2 col/tablet).

## Components — status

The canvas defines exactly 10 base components ("lo que no está aquí se construye combinando estos, no creando uno nuevo" — closed system). Status in this codebase:

| # | Component | Status | File |
|---|---|---|---|
| 01 | Button | **Built** | `core/widgets/app_button.dart` (`AppButton`) |
| 02 | TextField | **Built** | `core/widgets/app_text_field.dart` (`AppTextField`) |
| 03 | SelectableChip | Deferred to Epic 3 (Onboarding) | — |
| 04 | MealCard | Deferred to Epic 4 (Home) | — |
| 05 | ProgressRing | Deferred to Epic 4 (Home) | — |
| 06 | MacroBar | Deferred to Epic 4 (Home) | — |
| 07 | AIMessage | Deferred to Epic 5 (AI Assistant) | — |
| 08 | BottomSheet | **Built** (chrome/helper only) | `core/widgets/app_bottom_sheet.dart` (`showAppBottomSheet`) |
| 09 | BottomNavigation | Deferred until 2+ tab features exist | — |
| 10 | StateBlock | **Built** (empty/loading/error) | `core/widgets/app_state_block.dart` (`AppStateBlock`) |

Plus two generic surfaces implied by the foundations doc but not literally one of the 10: `AppCard` (`core/widgets/app_card.dart`) and `AppSkeletonBar` (`core/widgets/app_skeleton.dart`, the shimmer primitive `AppStateBlock.loading` uses).

**Why defer 03/04/05/06/07/09 now:** they're real, specified components, not skipped — but building them before a consumer feature exists risks getting API shape wrong (e.g. `MealCard`'s swipe actions depend on Plan feature interactions that don't exist yet). They'll be built as part of the epic that first needs them, still living in `core/widgets/` (not duplicated per-feature) per the reuse-first rule.

### Button (`AppButton`)

4 hierarchies + 1 specialized: `primary`, `secondary`, `neutral`, `text`, `aiAction`. Never two `primary` buttons on one screen. Height 52/44/36 (lg/md/sm), radius `full`, horizontal padding 26/20/16, label 15/600 (lg) or 14/600 (md/sm), icon 20 (stroke 1.5), touch target always ≥48 even if the button itself is 44. States: default, pressed (scale .97 + darker fill, 80ms), focus (2px ring, 2px offset), disabled (fill `border` color, text `textDisabled` — never disable on tap, use loading instead), loading (16px spinner replaces the leading slot, label stays, width doesn't jump). A `success` micro-animation (checkmark, 600ms) from the canvas is **not implemented yet** — flagged as a gap.

### TextField (`AppTextField`)

Label always external/above (never a placeholder-as-label). Kinds: text, numeric+unit, search, password. Height 56, radius 14, border 1→2 on focus (no height change). Validation is blur-time only — the caller passes `errorText` from a controller's focus-loss handler, this widget never validates on keystroke itself. Error replaces helper text (never both).

### StateBlock (`AppStateBlock`)

Three named constructors: `.empty`, `.loading`, `.error`. Loading defaults to a 3-line shimmer skeleton (`AppSkeletonBar`, 1.3s shimmer) or accepts a custom `skeleton` matching real content shape. Error shows cause + what to do + a retry button (reuses `AppButton.secondary` with an `accentColorOverride` of `colors.error` — see "why no destructive variant" below). Empty is centered, no illustration, always paired with the resolving action.

### Why `AppButton` has no dedicated "destructive/error" variant

The canvas is explicit that Button is a closed 4-hierarchy system. The error-colored "Reintentar" button (in the StateBlock error card) has the exact same anatomy as `secondary` (outline, `full` radius, same height) — only the accent color changes contextually. Rather than adding a 6th variant, `AppButton` exposes `accentColorOverride` as a narrow escape hatch for `secondary`/`text`, used so far only by `AppStateBlock.error`.

### BottomSheet (`showAppBottomSheet`)

Chrome only (scrim `rgba(16,21,18,.42)`, radius 28 top, 44×5 handle, optional title, safe-area bottom padding 20+). Heights: `auto` (content-sized), `half` (60%), `full` (92% — never 100%). Approved uses per the canvas: camera capture action, replace a meal, substitute an ingredient, contextual paywall, adjust a quantity. Not for destructive confirmations (use a centered dialog) or multi-step flows (use a pushed screen).

## Known gaps / follow-ups

- Dark-mode placeholder colors noted with `*` above need confirming once a real dark-mode screen is built.
- Icon set undecided (Lucide vs Phosphor) — nothing in `core/widgets` hardcodes an icon package yet; current placeholders use Flutter's built-in `Icons`.
- `AppButton`'s "success" checkmark micro-state isn't implemented.
- Photography direction is documented but no real assets exist yet — not blocking, only matters once a feature renders real food photos.
