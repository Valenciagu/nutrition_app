import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// Type scale (Fase 1 - Fundamentos > 04). One family, six weights, tabular
/// figures for every nutritional number so digits don't jiggle on update.
///
/// These are pure metric styles (no color) — [AppTheme] assigns the
/// brightness-appropriate [AppColorTokens] color when building each
/// [TextTheme] slot. `numericXl`/`numericM` have no standard [TextTheme]
/// slot; call them directly for big metric displays (e.g. calories left).
abstract final class AppTypography {
  static const _tabularFigures = [FontFeature.tabularFigures()];

  static TextStyle _style({
    required double fontSize,
    required FontWeight weight,
    required double height,
    double letterSpacing = 0,
    List<FontFeature>? fontFeatures,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: fontFeatures,
    );
  }

  /// 40/44, 800, -3% — hero numbers, splash-level headlines.
  static TextStyle get display =>
      _style(fontSize: 40, weight: FontWeight.w800, height: 44 / 40, letterSpacing: -1.2);

  /// 30/36, 700, -2% — screen titles.
  static TextStyle get titleL =>
      _style(fontSize: 30, weight: FontWeight.w700, height: 36 / 30, letterSpacing: -0.6);

  /// 22/28, 700, -1% — section titles.
  static TextStyle get titleM =>
      _style(fontSize: 22, weight: FontWeight.w700, height: 28 / 22, letterSpacing: -0.22);

  /// 17/23, 600 — card titles.
  static TextStyle get titleS => _style(fontSize: 17, weight: FontWeight.w600, height: 23 / 17);

  /// 16/25, 400 — the app's default body text.
  static TextStyle get bodyL => _style(fontSize: 16, weight: FontWeight.w400, height: 25 / 16);

  /// 14/22, 400 — secondary text, descriptions.
  static TextStyle get bodyM => _style(fontSize: 14, weight: FontWeight.w400, height: 22 / 14);

  /// 15/18, 600 — button labels.
  static TextStyle get label => _style(fontSize: 15, weight: FontWeight.w600, height: 18 / 15);

  /// 11.5, 600, +8%, uppercase — section headers/overline. Apply
  /// `textTransform` (uppercase) at the call site.
  static TextStyle get overline =>
      _style(fontSize: 11.5, weight: FontWeight.w600, height: 1.3, letterSpacing: 0.92);

  /// 46, 800, tabular, -3% — the single main metric on a screen (e.g. kcal
  /// remaining). Never use twice on the same screen.
  static TextStyle get numericXl => _style(
        fontSize: 46,
        weight: FontWeight.w800,
        height: 1,
        letterSpacing: -1.38,
        fontFeatures: _tabularFigures,
      );

  /// 26, 700, tabular — secondary metrics (macros row).
  static TextStyle get numericM => _style(
        fontSize: 26,
        weight: FontWeight.w700,
        height: 1,
        fontFeatures: _tabularFigures,
      );
}
