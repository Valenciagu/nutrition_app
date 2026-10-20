# Design System Reference

Transcribed from the Claude Design canvas linked in `desing.md` (project `d3c0cd06-9d89-4ceb-b4b7-0f3f858d37c1`, files `Fase 1 - Fundamentos.dc.html` and `Fichas de componentes.dc.html`, read 2026-09-11). This is the source of truth for implementation — read this before `DesignSync`-fetching anything, and extend it when a new `Fase N` file gets read.

Transcribed so far (plus, since 2026-10-05, `Marca e iconos` — see "Brand, icons & imagery" below): Fase 1 (this file), Fichas de componentes (this file), Fase 2 Block A/Auth (`documentation/design_screens_auth.md`), Fase 2 Block B/Onboarding (`documentation/design_screens_onboarding.md`), Fase 3/Home (`documentation/design_screens_home.md`), Fase 4/Plan y Recetas (`documentation/design_screens_plan.md`, read 2026-09-20 at the start of Epic 6). `Fases 5-12 - Entrega final` — only its Fase 9/10 block (Progreso · Perfil, screens I1/J1) has been read so far, at the start of Epic 11; transcribed inline in `documentation/profile.md` rather than a dedicated `design_screens_*.md` (a single small block, not worth a whole new file). Its other blocks (Fase 5 Análisis de comida, Fase 6 Ingredientes, Fase 7 IA/Fase 8 Lista de compra, Fase 11 Premium, Fase 12 Pulido) remain unread — fetch when their epic starts. Also not yet read: `ios-frame.jsx`, `support.js`, `uploads/desygn.md.md`.

## Product design direction

"Cocina luminosa, no laboratorio" (a luminous kitchen, not a lab). Wide white base, strong type, bleed food photography, green used sparingly but consistently. Premium feel comes from spacing and hierarchy, not gradients/chrome.

Four rules that shape every screen:
1. **Green is a traffic light** — only for primary CTA, progress, achievement, healthy status. Never a decorative background or large surface.
2. **The AI has a voice, not control** — indigo + a status dot marks anything AI-generated, everywhere, without turning the app into a chat.
3. **Food leads** — the photo is the largest element on a screen; UI gets out of the way.
4. **Progress, never guilt** — going over a target is never shown in red; it's neutral + a rebalancing action. Red is reserved for actual system errors.

Open decisions (per the canvas, still pending real assets from the user): final wordmark/logo, icon set (proposal: Lucide or Phosphor, ~8-10 custom icons for food scanner/ingredients/recalculate-day/streak), real food photography (fixed recipe: natural side light, matte neutral background, 90° or 45° angle, clean simple plate, realistic portion, no hands/utensils; 1:1 for cards, 4:5 for recipe detail).

## Brand, icons & imagery (Epic 18 — canvas file `Marca e iconos.dc.html`, read 2026-10-05)

Delivered by Claude Design from the prompt in `documentation/claude_design_assets_prompt.md`. Files live in the canvas project under `brand/` and `icons/`.

- **Isotype "Plato en proporción"** (direction 1a, chosen over "Bowl y bocado" and "Plato con foco"): a plate seen from above split into one half and two quarters (the plate method — balance without counting grams; also echoes the progress rings). Two-tone: half `#0B8F55`, quarters `#17A86A`. Readable at 16 px; min size 16 px (isotype) / 12 px height (horizontal logo); clear space = ¼ of the diameter. Wrong uses: deforming, painting segments with macro colors, gradients/shadows.
- **Wordmark**: Plus Jakarta Sans ExtraBold 800, tracking −15/1000 em, converted to outlines (615×95 viewBox). Green `#0B8F55` on light, white on `#0B8F55` or dark.
- **Files in the repo** (imported 2026-10-05, c2pa `<metadata>` stripped from SVGs): `assets/brand/` — `isotype_color/white/mono.svg`, `wordmark_color/white.svg`, `app_icon_1024.png`, `app_icon_foreground.png`, `app_icon_background.png` (solid `#17A86A`, regenerated locally), `app_icon_dark_1024.png`, `splash_logo_1152.png`; `assets/icons/` — the 18 own icons. Launcher icons and native splash are generated from these (`pubspec.yaml`: `flutter_launcher_icons`, `flutter_native_splash`). Android notification icon: `android/app/src/main/res/drawable/ic_stat_notification.xml` (vector built from the isotype). **Still only in the canvas:** `logo_horizontal_*.svg`, `splash_logo.svg`, `notification_icon.svg`/`_96.png`. The PNGs still carry the c2pa chunk — harmless, strip before store release if wanted.
- **Own icons** (grid 24, stroke 1.75, `currentColor`, regular + fill): `food_scanner`, `ingredients_photo`, `recalculate_day`, `streak`, `ai_sparkle`, `macro_protein` (egg), `macro_carbs` (bread), `macro_fat` (drop), `macro_water` (glass). At 20 px Flutter scales the stroke to ≈1.46, matching the 1.5 rule without a separate file.
- **Decisions the canvas flagged (resolved as recommended unless noted):**
  - **Splash background is `#0B8F55`, not `#17A86A`** (the A1 splash carries white wordmark/tagline, and `#17A86A` fails AA with text). The app icon does use `#17A86A` (no text). The native splash should also be `#0B8F55` to avoid a color jump into the Flutter splash. *(Corrects the earlier prompt, which said `#17A86A`.)*
  - **Streak badge is amber** (`#C98A17` icon on `warningSurface`-like `#FDF3E2`, text `#7A4A00`), not green: a streak is consistency, not a health state. *Needs user confirmation.*
  - **Google button** must follow Google's branding, overriding Fase 2's generic social-button style: light = fill `#FFFFFF`, 1 px border `#747775`, text `#1F1F1F`; dark = `#131314` / `#8E918F` / `#E3E3E3`; Roboto Medium 14/20 (the single exception to the one-font rule); official 20×20 "G"; padding Android 12·G·10·text·12, iOS 16·G·12·text·16; height 52, pill. Apple: system `SignInWithAppleButton` (black on light, white/outlined on dark), SF font, at least as prominent as Google; Apple first on iOS, Google first on Android.
  - **Photography is briefs only** (no generated photos): one shared recipe (left window light at 45°, matte stone/linen `#E8E6E1`–`#D9D6CF`, 26 cm bone-white plate, no hands/cutlery, 5200 K). Hero: top-down bowl (brown rice, roasted chickpeas, carrot, avocado, red cabbage, lemon yogurt), bleed top-right, calm bottom third for the white fade. Goal series 1:1 at 45°, plate = 70 % of frame: lose fat (grilled chicken + big salad, green), gain muscle (salmon/steak + rice + egg + broccoli, reddish), maintain (literal plate method ½ roasted veg, ¼ chicken, ¼ potato/quinoa, golden), eat healthier (bowl of 5–6 ingredients: edamame, mango, radish, cabbage, quinoa, sesame; multicolor). Hatched placeholders stay until real photos exist.
  - **Alternative name "Mitad"** proposed (names what the isotype draws); all files still say NutritionApp. Trademark/domain availability unchecked. Not adopted.

## Color tokens

Implemented in `lib/core/theme/app_color_tokens.dart` as `AppColorTokens` (a `ThemeExtension`, light + dark). Access via `context.colors.xxx` (`AppColorTokensX`), never a raw hex value.

| Token | Light | Dark | Notes |
|---|---|---|---|
| `actionPrimary` | `#0B8F55` | `#3ED98C` | Primary 600 — only green valid with white text on top (4.6:1) |
| `actionPrimaryPressed` | `#076B40` | `#1F6B48`* | Primary 700 / pressed |
| `actionPrimaryStrong` | `#17A86A` | `#3ED98C`* | Primary 500 — fills without text, ring arcs, icons |
| `actionPrimarySurface` | `#E9F7F0` | `#1F6B48`* | Primary 50 — secondary-button hover bg |
| `onActionPrimarySurface` | `#076B40` | `#B8F5D6`** | Text/icon on top of `actionPrimarySurface` (selected pill/chip/card pattern) — NOT in the canvas, added 2026-09-20 after a dark-mode bug (see below) |
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

`**` = same as `*`, but this token itself doesn't exist in the canvas at all — it was split out of `actionPrimaryPressed` on 2026-09-20 after a real dark-mode bug (see `documentation/onboarding.md` "Bugs corregidos"): that token's dark value was identical to `actionPrimarySurface`, making text/icons drawn in one on a background of the other invisible. Confirm this value against the canvas too when possible.

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
- **Icons**: sizes 16/20/24/28/32, stroke 1.75 (or 1.5 at size 20). **Phosphor** (chosen 2026-10-05, delegated by the user) via `phosphor_flutter`; widgets use `AppIcons.*` (`core/constants/app_icons.dart`), never `Icons.*`. SVG assets go through `flutter_svg` with paths in `AppAssets`.
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
- Icon set decided (Phosphor, 2026-10-05). Still pending real assets: brand isotype/wordmark, launcher icon, Google "G", photography — see TASKS.md Epic 18.
- `AppButton`'s "success" checkmark micro-state isn't implemented.
- Photography direction is documented but no real assets exist yet — not blocking, only matters once a feature renders real food photos.
