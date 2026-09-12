import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';
import '../theme/app_typography.dart';

/// QuickActionTile — uno de los dos componentes nuevos que propone Fase 3 ·
/// Home (el otro, `AISuggestionCard`, se difiere junto con `MealCard` y
/// `MacroBar` hasta que exista seguimiento real de plan/macros, Épica 6).
/// Fila: icono + título + subtítulo + chevron. El diseño también muestra una
/// variante en grid 2x2 sin subtítulo/chevron (Home · estado poblado) — no
/// se construye todavía porque no tiene un segundo consumidor real que
/// justifique la variante (ver `documentation/home.md`).
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconBackgroundColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color iconBackgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: iconBackgroundColor, borderRadius: BorderRadius.circular(11)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyM.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodyM.copyWith(fontSize: 12.5, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}
