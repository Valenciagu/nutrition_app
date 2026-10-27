import 'package:flutter/widgets.dart';

/// Motion tokens (Fase 1 - Fundamentos > 06). Nothing exceeds [slow] except
/// progress/AI animations. Every animation must be interruptible; respect
/// `MediaQuery.disableAnimations` (reduce motion) by swapping to a 140ms
/// fade instead of removing motion entirely.
///
/// Los valores debajo de las curvas son los del catálogo "Motion patterns"
/// (`documentation/design_system.md`, M01-M13) — cada patrón los usa a
/// través de su implementación compartida en `core/widgets/motion/`, nunca
/// copiados a mano en una pantalla.
abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);
  static const Duration progress = Duration(milliseconds: 600);

  static const Curve standard = Cubic(0.2, 0, 0, 1);
  static const Curve enter = Cubic(0, 0, 0, 1);
  static const Curve exit = Cubic(0.3, 0, 1, 1);

  /// M01 — escala mientras algo tocable está presionado.
  static const double pressScale = 0.97;

  /// M02/M11 — escala inicial de un check o confirmación que aparece.
  static const double popInScaleFrom = 0.6;

  /// M03 — cuánto sube (px) el contenido nuevo al reemplazar al anterior.
  static const double contentSwapOffset = 8;

  /// M05 (cambio de tab) — escala inicial de la tab entrante, la misma que
  /// usa el fade-through de Material motion.
  static const double tabEnterScaleFrom = 0.92;

  /// M04 — entrada escalonada de listas.
  static const double listEntranceOffset = 12;
  static const Duration listStagger = Duration(milliseconds: 40);
  static const int listMaxStaggered = 6;

  /// M13 — sacudida de error: desplazamiento máximo (px) y ciclos en `base`.
  static const double shakeOffset = 4;
  static const int shakeCycles = 3;

  /// Loops existentes, con nombre en vez de literales sueltos: el shimmer
  /// del skeleton (M09, Fichas > 10 · StateBlock), los puntos de "escribiendo"
  /// del chat (M10) y la coreografía de B8 (M10, Fase 2 · B8).
  static const Duration skeletonLoop = Duration(milliseconds: 1300);
  static const Duration typingDotsLoop = Duration(milliseconds: 900);
  static const Duration planGenerationLoop = Duration(milliseconds: 5600);

  /// `true` cuando el usuario pidió reducir el movimiento — cada patrón lo
  /// cambia por un fade de [fast], nunca lo elimina del todo.
  static bool reduced(BuildContext context) => MediaQuery.disableAnimationsOf(context);
}
