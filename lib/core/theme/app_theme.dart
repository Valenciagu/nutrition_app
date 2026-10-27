import 'package:flutter/material.dart';

import 'app_color_tokens.dart';
import 'app_page_transitions.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// Builds the app's light/dark [ThemeData] from the synced design tokens.
/// Widgets should prefer `context.colors.*` ([AppColorTokensX]) and
/// `AppTypography.*` directly over reading `Theme.of(context).textTheme`,
/// since the design's scale (titleS, numericXl, ...) doesn't map 1:1 onto
/// Flutter's default [TextTheme] slot names — the mapping below exists so
/// stock Material widgets (AppBar, SnackBar, dialogs, ...) still look right
/// before every screen has a purpose-built `core/widgets` equivalent.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, AppColorTokens.light);

  static ThemeData dark() => _build(Brightness.dark, AppColorTokens.dark);

  static ThemeData _build(Brightness brightness, AppColorTokens tokens) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.actionPrimary,
      onPrimary: tokens.onActionPrimary,
      secondary: tokens.aiActionSurface,
      onSecondary: tokens.onAiAction,
      error: tokens.error,
      onError: brightness == Brightness.light ? Colors.white : tokens.textPrimary,
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
    );

    final textTheme = TextTheme(
      displayLarge: AppTypography.display.copyWith(color: tokens.textPrimary),
      headlineLarge: AppTypography.titleL.copyWith(color: tokens.textPrimary),
      titleLarge: AppTypography.titleM.copyWith(color: tokens.textPrimary),
      titleMedium: AppTypography.titleS.copyWith(color: tokens.textPrimary),
      bodyLarge: AppTypography.bodyL.copyWith(color: tokens.textPrimary),
      bodyMedium: AppTypography.bodyM.copyWith(color: tokens.textSecondary),
      labelLarge: AppTypography.label.copyWith(color: tokens.textPrimary),
      labelSmall: AppTypography.overline.copyWith(color: tokens.textSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.background,
      textTheme: textTheme,
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.background,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleS.copyWith(color: tokens.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: tokens.border),
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: tokens.border),
        ),
      ),
      splashFactory: NoSplash.splashFactory,
      // M05 (catálogo "Motion patterns"). iOS conserva la transición nativa
      // a propósito: el shared axis no tiene el gesto de deslizar desde el
      // borde para volver, y quitarlo sería peor que cualquier ganancia
      // visual (excepción de plataforma documentada en design_system.md).
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(fillColor: tokens.background),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
