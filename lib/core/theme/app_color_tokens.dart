import 'package:flutter/material.dart';

/// Semantic color tokens synced from the design system
/// ("Fase 1 - Fundamentos.dc.html" > 02/03 Color, 09 Design tokens).
///
/// Screens/widgets must always read colors through this extension
/// (`Theme.of(context).extension<AppColorTokens>()!` or the `context.colors`
/// shortcut) — never a raw hex value. The design's two-level naming
/// (primitive `green.600` vs semantic `color.action.primary`) maps here to
/// one flat semantic token set per brightness; light/dark are two data
/// instances of the same shape, not two code paths.
@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.actionPrimary,
    required this.actionPrimaryPressed,
    required this.actionPrimaryStrong,
    required this.actionPrimarySurface,
    required this.onActionPrimarySurface,
    required this.onActionPrimary,
    required this.aiActionSurface,
    required this.onAiAction,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.success,
    required this.successSurface,
    required this.warning,
    required this.warningSurface,
    required this.error,
    required this.errorSurface,
    required this.info,
    required this.infoSurface,
    required this.macroProtein,
    required this.macroCarbs,
    required this.macroFat,
    required this.macroWater,
  });

  /// Primary 600 — the only green valid for surfaces with white text on top
  /// (4.6:1 contrast). Main CTA background, links, selected states.
  final Color actionPrimary;

  /// Primary 700 — pressed/active state of [actionPrimary].
  final Color actionPrimaryPressed;

  /// Primary 500 — fills without text, progress ring arcs, icons on white.
  final Color actionPrimaryStrong;

  /// Primary 50 — secondary-button hover/pressed background, light accents.
  final Color actionPrimarySurface;

  /// Text/icon color for content drawn ON TOP OF [actionPrimarySurface] —
  /// the selected-state pattern (pill/chip/card: tinted background + this
  /// as text color) used across `SelectableChip`, `OnboardingOptionCard`,
  /// and similar widgets. Distinct on purpose from [actionPrimaryPressed]:
  /// that token is the pressed/active state of a *solid* `actionPrimary`
  /// button background, a different semantic that happens to want a
  /// similarly dark green in light mode — but not in dark mode, where
  /// reusing it here made this text render invisible (bug found via manual
  /// testing 2026-09-20: dark `actionPrimaryPressed` and
  /// `actionPrimarySurface` are the same placeholder hex, so text drawn in
  /// one on a background of the other disappeared completely). Keep these
  /// two tokens separate even if a future design sync gives them the same
  /// value again — the call sites' intent differs.
  final Color onActionPrimarySurface;

  final Color onActionPrimary;

  /// The lighter indigo "AI action" button fill (Fichas de componentes > 01
  /// Button). The stronger solid indigo used for AIMessage suggestion chips
  /// belongs to that (not-yet-built) component, not this token.
  final Color aiActionSurface;
  final Color onAiAction;

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;

  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  final Color success;
  final Color successSurface;
  final Color warning;
  final Color warningSurface;
  final Color error;
  final Color errorSurface;
  final Color info;
  final Color infoSurface;

  /// Fixed macro color order per design rule: protein, carbs, fat, water.
  /// Color is never the only carrier of meaning — always pair with a label.
  final Color macroProtein;
  final Color macroCarbs;
  final Color macroFat;
  final Color macroWater;

  static const light = AppColorTokens(
    actionPrimary: Color(0xFF0B8F55),
    actionPrimaryPressed: Color(0xFF076B40),
    actionPrimaryStrong: Color(0xFF17A86A),
    actionPrimarySurface: Color(0xFFE9F7F0),
    // Igual al valor de `actionPrimaryPressed` de arriba — mismo hex, cero
    // cambio visual en modo claro, donde este patrón ya funcionaba bien.
    onActionPrimarySurface: Color(0xFF076B40),
    onActionPrimary: Color(0xFFFFFFFF),
    aiActionSurface: Color(0xFFEEEDFB),
    onAiAction: Color(0xFF332D93),
    background: Color(0xFFF7F8F7),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    border: Color(0xFFE4E7E5),
    textPrimary: Color(0xFF101512),
    textSecondary: Color(0xFF5B635E),
    textDisabled: Color(0xFFA2A9A5),
    success: Color(0xFF0B8F55),
    successSurface: Color(0xFFE9F7F0),
    warning: Color(0xFFB26B00),
    warningSurface: Color(0xFFFDF3E2),
    error: Color(0xFFC0372F),
    errorSurface: Color(0xFFFCEDEC),
    info: Color(0xFF1A6FB8),
    infoSurface: Color(0xFFE8F1F9),
    macroProtein: Color(0xFF0B8F55),
    macroCarbs: Color(0xFFC98A17),
    macroFat: Color(0xFF4740C4),
    macroWater: Color(0xFF1A6FB8),
  );

  // TODO(design-sync): dark-mode `actionPrimaryPressed`, `onActionPrimarySurface`,
  // and the *Surface (container) pairs for warning/error/info/macros, weren't
  // given explicit dark values in Fase 1 (only foreground colors were). The
  // values below are reasonable placeholders — confirm against the canvas
  // before shipping a real dark-mode screen. `onActionPrimarySurface` in
  // particular is a value chosen by Claude (light mint, modeled on the
  // confirmed `onAiAction`/`aiActionSurface` light-foreground-on-dark-tint
  // relationship below), not something read off the canvas — it did NOT
  // exist as a token before 2026-09-20; it was split out from
  // `actionPrimaryPressed` specifically because that token's dark value
  // was identical to `actionPrimarySurface`, making any text using it on
  // that background invisible (see the doc-comment above).
  static const dark = AppColorTokens(
    actionPrimary: Color(0xFF3ED98C),
    actionPrimaryPressed: Color(0xFF1F6B48),
    actionPrimaryStrong: Color(0xFF3ED98C),
    actionPrimarySurface: Color(0xFF1F6B48),
    onActionPrimarySurface: Color(0xFFB8F5D6),
    onActionPrimary: Color(0xFF06301D),
    aiActionSurface: Color(0xFF262163),
    onAiAction: Color(0xFFCFCCFA),
    background: Color(0xFF0C110F),
    surface: Color(0xFF141A17),
    surfaceElevated: Color(0xFF1C2420),
    border: Color(0xFF2A332E),
    textPrimary: Color(0xFFF2F5F3),
    textSecondary: Color(0xFFA3ADA7),
    textDisabled: Color(0xFF646E68),
    success: Color(0xFF3ED98C),
    successSurface: Color(0xFF1F6B48),
    warning: Color(0xFFE8B45C),
    warningSurface: Color(0xFF1C2420),
    error: Color(0xFFF0736A),
    errorSurface: Color(0xFF1C2420),
    info: Color(0xFF6BB6F0),
    infoSurface: Color(0xFF1C2420),
    macroProtein: Color(0xFF3ED98C),
    macroCarbs: Color(0xFFE8B45C),
    macroFat: Color(0xFF9D98F5),
    macroWater: Color(0xFF6BB6F0),
  );

  @override
  AppColorTokens copyWith({
    Color? actionPrimary,
    Color? actionPrimaryPressed,
    Color? actionPrimaryStrong,
    Color? actionPrimarySurface,
    Color? onActionPrimarySurface,
    Color? onActionPrimary,
    Color? aiActionSurface,
    Color? onAiAction,
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? success,
    Color? successSurface,
    Color? warning,
    Color? warningSurface,
    Color? error,
    Color? errorSurface,
    Color? info,
    Color? infoSurface,
    Color? macroProtein,
    Color? macroCarbs,
    Color? macroFat,
    Color? macroWater,
  }) {
    return AppColorTokens(
      actionPrimary: actionPrimary ?? this.actionPrimary,
      actionPrimaryPressed: actionPrimaryPressed ?? this.actionPrimaryPressed,
      actionPrimaryStrong: actionPrimaryStrong ?? this.actionPrimaryStrong,
      actionPrimarySurface: actionPrimarySurface ?? this.actionPrimarySurface,
      onActionPrimarySurface: onActionPrimarySurface ?? this.onActionPrimarySurface,
      onActionPrimary: onActionPrimary ?? this.onActionPrimary,
      aiActionSurface: aiActionSurface ?? this.aiActionSurface,
      onAiAction: onAiAction ?? this.onAiAction,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      success: success ?? this.success,
      successSurface: successSurface ?? this.successSurface,
      warning: warning ?? this.warning,
      warningSurface: warningSurface ?? this.warningSurface,
      error: error ?? this.error,
      errorSurface: errorSurface ?? this.errorSurface,
      info: info ?? this.info,
      infoSurface: infoSurface ?? this.infoSurface,
      macroProtein: macroProtein ?? this.macroProtein,
      macroCarbs: macroCarbs ?? this.macroCarbs,
      macroFat: macroFat ?? this.macroFat,
      macroWater: macroWater ?? this.macroWater,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColorTokens(
      actionPrimary: l(actionPrimary, other.actionPrimary),
      actionPrimaryPressed: l(actionPrimaryPressed, other.actionPrimaryPressed),
      actionPrimaryStrong: l(actionPrimaryStrong, other.actionPrimaryStrong),
      actionPrimarySurface: l(actionPrimarySurface, other.actionPrimarySurface),
      onActionPrimarySurface: l(onActionPrimarySurface, other.onActionPrimarySurface),
      onActionPrimary: l(onActionPrimary, other.onActionPrimary),
      aiActionSurface: l(aiActionSurface, other.aiActionSurface),
      onAiAction: l(onAiAction, other.onAiAction),
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceElevated: l(surfaceElevated, other.surfaceElevated),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textDisabled: l(textDisabled, other.textDisabled),
      success: l(success, other.success),
      successSurface: l(successSurface, other.successSurface),
      warning: l(warning, other.warning),
      warningSurface: l(warningSurface, other.warningSurface),
      error: l(error, other.error),
      errorSurface: l(errorSurface, other.errorSurface),
      info: l(info, other.info),
      infoSurface: l(infoSurface, other.infoSurface),
      macroProtein: l(macroProtein, other.macroProtein),
      macroCarbs: l(macroCarbs, other.macroCarbs),
      macroFat: l(macroFat, other.macroFat),
      macroWater: l(macroWater, other.macroWater),
    );
  }
}

/// Shortcut: `context.colors.actionPrimary` instead of
/// `Theme.of(context).extension<AppColorTokens>()!.actionPrimary`.
extension AppColorTokensX on BuildContext {
  AppColorTokens get colors => Theme.of(this).extension<AppColorTokens>()!;
}
