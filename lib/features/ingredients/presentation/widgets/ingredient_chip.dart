import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_typography.dart';

/// Chip de un ingrediente en F1 (Fase 6). No es `SelectableChip`: ese
/// alterna una selección, este tiene dos estados con acciones distintas.
/// - **Seguro**: borde verde 1.5, fondo verde claro, "✕" para quitarlo.
/// - **Dudoso**: borde PUNTEADO, texto "Nombre · ¿seguro?". Tocarlo lo
///   confirma (pasa a seguro). Lleva también "✕", que el canvas no
///   dibuja: sin él, la única forma de quitar uno dudoso sería confirmarlo
///   primero, y el propio canvas pide "confírmalos o quítalos".
///
/// La confianza se expresa con el borde, nunca con porcentajes (nota del
/// canvas); el texto "¿seguro?" la repite para no depender solo del estilo.
class IngredientChip extends StatelessWidget {
  const IngredientChip({
    super.key,
    required this.name,
    required this.confident,
    required this.onRemove,
    required this.onConfirm,
  });

  final String name;
  final bool confident;
  final VoidCallback onRemove;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final textColor = confident ? colors.onActionPrimarySurface : colors.textSecondary;

    final content = Padding(
      padding: const EdgeInsets.only(left: 15, right: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              confident ? name : l10n.ingredientsDoubtfulChip(name),
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
            ),
          ),
          Semantics(
            button: true,
            label: l10n.ingredientsRemoveSemantics(name),
            excludeSemantics: true,
            child: InkResponse(
              onTap: onRemove,
              radius: 18,
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Icon(AppIcons.close, size: 14, color: textColor.withValues(alpha: 0.6)),
              ),
            ),
          ),
        ],
      ),
    );

    if (confident) {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          color: colors.actionPrimarySurface,
          border: Border.all(color: colors.actionPrimary, width: 1.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: content,
      );
    }

    return Semantics(
      button: true,
      label: l10n.ingredientsConfirmSemantics(name),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onConfirm,
          customBorder: const StadiumBorder(),
          child: CustomPaint(
            painter: _DashedPillPainter(color: colors.textDisabled),
            child: SizedBox(height: 40, child: content),
          ),
        ),
      ),
    );
  }
}

/// Borde punteado de píldora — Flutter no trae `BorderStyle.dashed`.
class _DashedPillPainter extends CustomPainter {
  _DashedPillPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect.deflate(0.5), Radius.circular(size.height / 2)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dash = 4.0;
    const gap = 3.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPillPainter oldDelegate) => oldDelegate.color != color;
}
