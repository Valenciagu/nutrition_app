/// Spacing scale, base 4 (Fase 1 - Fundamentos > 05).
abstract final class AppSpacing {
  /// 2px.
  static const double space2 = 2;

  /// 4px — icon gap.
  static const double space4 = 4;

  /// 8px.
  static const double space8 = 8;

  /// 12px — intra-card gaps.
  static const double space12 = 12;

  /// 16px — card padding.
  static const double space16 = 16;

  /// 20px — screen margin.
  static const double space20 = 20;

  /// 24px — gap between blocks.
  static const double space24 = 24;

  /// 32px — gap between sections.
  static const double space32 = 32;

  /// 40px.
  static const double space40 = 40;

  /// 48px.
  static const double space48 = 48;

  /// 64px — hero / empty-state spacing.
  static const double space64 = 64;

  static const double screenHorizontalPadding = space20;

  // Component heights (Fase 1 - Fundamentos > 05 "Alturas de componente").
  static const double buttonHeightLg = 52;
  static const double buttonHeightMd = 44;
  static const double buttonHeightSm = 36;
  static const double fieldHeight = 56;
  static const double chipHeight = 36;
  static const double appBarHeight = 56;
  static const double bottomNavHeight = 64;
  static const double fabSize = 60;
  static const double listItemHeight = 64;
  static const double tabHeight = 44;

  /// Minimum touch target, regardless of a component's visual size.
  static const double touchTargetMin = 48;

  // Icon sizes + stroke width.
  static const List<double> iconSizes = [16, 20, 24, 28, 32];
  static const double iconStroke = 1.75;

  // Border widths.
  static const double borderHairline = 1;
  static const double borderSelected = 1.5;
  static const double borderFocus = 2;
}
