import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';

/// Placeholder "rayado" para una foto que no existe todavía — nunca un
/// ícono genérico (diseño, ver `documentation/design_screens_plan.md`
/// "Estados"). Extraído de `MealCard` (que lo usaba de forma privada) al
/// necesitarlo también D3 (foto grande de receta) y D5 (foto de paso, modo
/// cocina) — mismo patrón visual, solo cambia el tamaño/radio.
class HatchedPlaceholder extends StatelessWidget {
  const HatchedPlaceholder({
    super.key,
    this.borderRadius = BorderRadius.zero,
    this.dimmed = false,
  });

  final BorderRadius borderRadius;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: borderRadius,
      child: Opacity(
        opacity: dimmed ? 0.6 : 1,
        child: CustomPaint(
          size: Size.infinite,
          painter: _HatchPainter(base: colors.border, stripe: colors.surface),
        ),
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  _HatchPainter({required this.base, required this.stripe});

  final Color base;
  final Color stripe;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);

    final linePaint = Paint()
      ..color = stripe
      ..strokeWidth = 7;
    const gap = 11.0;
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HatchPainter oldDelegate) => oldDelegate.base != base || oldDelegate.stripe != stripe;
}
