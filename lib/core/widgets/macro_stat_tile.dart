import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';
import '../theme/app_typography.dart';
import 'motion/app_count_up_text.dart';

/// 05/10 de Fase 4 (`documentation/design_screens_plan.md`) — una cifra de
/// macro (kcal/proteína/carbos/grasas): número grande + label pequeño
/// debajo. Extraído de D3 (`RecipeDetailPage`) a `core/widgets/` al
/// necesitarlo también el análisis de foto (Épica 8) — mismo criterio que
/// `mapFirebaseFunctionsException`: se promueve a compartido en su segundo
/// consumidor real, no antes.
class MacroStatTile extends StatelessWidget {
  const MacroStatTile({super.key, required this.value, required this.label, required this.color});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Column(
        children: [
          // M08 (catálogo "Motion patterns"): la cifra cuenta hasta su valor.
          AppCountUpText(
            value: value,
            style: AppTypography.numericM.copyWith(fontSize: 19, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.bodyM.copyWith(fontSize: 11, color: colors.textSecondary)),
        ],
      ),
    );
  }
}
