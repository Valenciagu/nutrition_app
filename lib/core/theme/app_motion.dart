import 'package:flutter/animation.dart';

/// Motion tokens (Fase 1 - Fundamentos > 06). Nothing exceeds [slow] except
/// progress/AI animations. Every animation must be interruptible; respect
/// `MediaQuery.disableAnimations` (reduce motion) by swapping to a 140ms
/// fade instead of removing motion entirely.
abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);
  static const Duration progress = Duration(milliseconds: 600);

  static const Curve standard = Cubic(0.2, 0, 0, 1);
  static const Curve enter = Cubic(0, 0, 0, 1);
  static const Curve exit = Cubic(0.3, 0, 1, 1);
}
