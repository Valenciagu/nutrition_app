import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';
import '../theme/app_motion.dart';
import '../theme/app_typography.dart';
import 'motion/app_count_up_text.dart';

/// 05 · ProgressRing (Fichas de componentes). Anillo de progreso circular
/// con un valor y una etiqueta en el centro. Usado para las kcal del día en
/// Home; `dimmed` es el estado "vacío" (primer día, sin datos reales aún) —
/// borde uniforme en vez del arco de progreso, tal como especifica C3 del
/// diseño (Fase 3 · Home).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.centerValue,
    this.centerNumber,
    required this.centerLabel,
    this.size = 104,
    this.strokeWidth = 10,
    this.color,
    this.dimmed = false,
    this.animate = true,
  }) : assert((centerValue == null) != (centerNumber == null), 'Pass exactly one of centerValue / centerNumber');

  /// 0.0-1.0. Ignorado si [dimmed] es true.
  final double progress;

  /// Texto fijo del centro. Para una cifra, preferir [centerNumber]: cuenta
  /// en sincronía con el arco (M08).
  final String? centerValue;
  final int? centerNumber;
  final String centerLabel;

  /// M08 (catálogo "Motion patterns"): el arco se llena desde el valor
  /// anterior (o desde 0 la primera vez) en `progress`. `false` cuando quien
  /// lo usa ya mueve [progress] cuadro a cuadro (B8, su propia coreografía) —
  /// animarlo encima solo lo retrasaría.
  final bool animate;
  final double size;
  final double strokeWidth;
  final Color? color;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ringColor = color ?? colors.actionPrimary;

    final target = dimmed ? 0.0 : progress.clamp(0, 1).toDouble();
    final valueStyle = AppTypography.titleL.copyWith(
      fontSize: size * 0.22,
      color: dimmed ? colors.textDisabled : colors.textPrimary,
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // `RepaintBoundary`: mientras el arco anima, solo se repinta esta
          // capa, no el resto de la pantalla.
          RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: target),
              duration: animate && !AppMotion.reduced(context) ? AppMotion.progress : Duration.zero,
              curve: AppMotion.standard,
              builder: (context, animatedProgress, _) => CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  progress: animatedProgress,
                  color: dimmed ? colors.border : ringColor,
                  trackColor: colors.border,
                  strokeWidth: strokeWidth,
                  showTrack: !dimmed,
                  fullTrackOnly: dimmed,
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (centerNumber != null && animate)
                AppCountUpText(value: centerNumber!, style: valueStyle)
              else
                Text(centerValue ?? '$centerNumber', style: valueStyle),
              const SizedBox(height: 2),
              Text(
                centerLabel,
                textAlign: TextAlign.center,
                style: AppTypography.label.copyWith(
                  fontSize: size * 0.1,
                  color: dimmed ? colors.textDisabled : colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.showTrack,
    required this.fullTrackOnly,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final bool showTrack;
  final bool fullTrackOnly;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (fullTrackOnly) {
      canvas.drawCircle(center, radius, Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth);
      return;
    }

    if (showTrack) {
      canvas.drawCircle(center, radius, Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth);
    }

    canvas.drawArc(
      rect,
      -1.5707963267948966,
      6.283185307179586 * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
