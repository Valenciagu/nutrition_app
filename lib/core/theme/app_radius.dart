/// Corner radius scale (Fase 1 - Fundamentos > 05). Buttons/chips always use
/// [full]; cards use [lg]/[xl]; images inside a card use [md]. Never mix two
/// different radii on the same shared border.
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;

  /// Bottom sheets: rounded top corners only.
  static const double sheet = 28;

  static const double full = 999;
}
