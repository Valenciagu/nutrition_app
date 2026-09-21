import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';
import '../theme/app_typography.dart';

/// Variante semántica de selección. `negative` es el único sitio del sistema
/// donde el rojo aparece por selección (no por error) — significa exclusión
/// (p. ej. un alérgeno marcado), ver B5 en `documentation/design_screens_onboarding.md`.
enum SelectableChipVariant { neutral, negative }

/// 03 · SelectableChip (Fichas de componentes). Chip tocable con estado
/// seleccionado/no seleccionado — la selección nunca depende solo del color:
/// siempre borde 1.5px + fondo + check cuando está seleccionado.
class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.variant = SelectableChipVariant.neutral,
    this.showCheckWhenSelected = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final SelectableChipVariant variant;
  final bool showCheckWhenSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isNegative = variant == SelectableChipVariant.negative;

    final Color borderColor;
    final Color? backgroundColor;
    final Color textColor;

    if (selected) {
      borderColor = isNegative ? colors.error : colors.actionPrimary;
      backgroundColor = isNegative ? colors.errorSurface : colors.actionPrimarySurface;
      textColor = isNegative ? colors.error : colors.onActionPrimarySurface;
    } else {
      borderColor = colors.border;
      backgroundColor = null;
      textColor = colors.textPrimary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.label.copyWith(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (selected && showCheckWhenSelected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check, size: 15, color: textColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
