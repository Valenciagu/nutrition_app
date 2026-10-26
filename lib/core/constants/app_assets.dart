/// Rutas de assets empaquetados. Declarados en `pubspec.yaml`
/// (`assets/brand/`, `assets/icons/`, `assets/images/`). Origen: canvas
/// "Marca e iconos" (ver `documentation/design_system.md`, sección Marca).
abstract final class AppAssets {
  static const String isotypeColor = 'assets/brand/isotype_color.svg';
  static const String isotypeWhite = 'assets/brand/isotype_white.svg';
  static const String isotypeMono = 'assets/brand/isotype_mono.svg';
  static const String wordmarkColor = 'assets/brand/wordmark_color.svg';
  static const String wordmarkWhite = 'assets/brand/wordmark_white.svg';

  /// "G" oficial del kit "Sign in with Google" (signin-assets.zip de
  /// developers.google.com/identity/branding-guidelines), recortada SIN
  /// redibujar del PNG @4x del botón cuadrado sin texto: 80x80 px = 20 lógicos.
  /// PNG y no SVG porque el SVG oficial usa foreignObject/degradado
  /// cónico/desenfoque, que flutter_svg no dibuja. Una por tema porque el
  /// fondo del recorte es el relleno oficial del botón (#FFFFFF / #131314).
  static const String googleGLight = 'assets/brand/google_g_light.png';
  static const String googleGDark = 'assets/brand/google_g_dark.png';

  // Iconos propios (grilla 24, trazo 1.75, `currentColor`). `Fill` es la
  // variante rellena; úsense con `AppSvgIcon`, no con `Icon`.
  static const String iconFoodScanner = 'assets/icons/food_scanner_regular.svg';
  static const String iconFoodScannerFill = 'assets/icons/food_scanner_fill.svg';
  static const String iconIngredientsPhoto = 'assets/icons/ingredients_photo_regular.svg';
  static const String iconIngredientsPhotoFill = 'assets/icons/ingredients_photo_fill.svg';
  static const String iconRecalculateDay = 'assets/icons/recalculate_day_regular.svg';
  static const String iconRecalculateDayFill = 'assets/icons/recalculate_day_fill.svg';
  static const String iconStreak = 'assets/icons/streak_regular.svg';
  static const String iconStreakFill = 'assets/icons/streak_fill.svg';
  static const String iconAiSparkle = 'assets/icons/ai_sparkle_regular.svg';
  static const String iconAiSparkleFill = 'assets/icons/ai_sparkle_fill.svg';
  static const String iconMacroProtein = 'assets/icons/macro_protein_regular.svg';
  static const String iconMacroProteinFill = 'assets/icons/macro_protein_fill.svg';
  static const String iconMacroCarbs = 'assets/icons/macro_carbs_regular.svg';
  static const String iconMacroCarbsFill = 'assets/icons/macro_carbs_fill.svg';
  static const String iconMacroFat = 'assets/icons/macro_fat_regular.svg';
  static const String iconMacroFatFill = 'assets/icons/macro_fat_fill.svg';
  static const String iconMacroWater = 'assets/icons/macro_water_regular.svg';
  static const String iconMacroWaterFill = 'assets/icons/macro_water_fill.svg';
}
